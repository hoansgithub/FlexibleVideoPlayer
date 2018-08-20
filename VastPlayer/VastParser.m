//
//  VastParser.m
//  FlexibleVideoPlayer
//
//  Created by Hoan Nguyen on 9/18/17.
//  Copyright © 2017 Hoan Nguyen. All rights reserved.
//

#import "VastParser.h"

#define TAG_LINEAR @"Linear"
#define TAG_MEDIAFILE @"MediaFile"
#define TAG_ATTR_SKIP_OFFSET @"skipoffset"
#define TAG_CLICKTHROUGH @"ClickThrough"
#define TAG_VAST @"VAST"

@interface VastParser ()<NSXMLParserDelegate>
@property (strong, nonatomic) NSURL *url;
@property (strong, nonatomic) void (^completionBlock)(VastEnt *vastEnt);
@property (strong, nonatomic) void (^errorBlock)(NSError *error);
@property (strong, nonatomic) VastEnt *latestVast;
@end

@implementation VastParser

- (instancetype)initWith:(NSURL *)url completed:(void (^)(VastEnt *))completionBlock error:(void (^)(NSError *))errorBlock {
    self = [super init];
    if (self != nil) {
        self.url = url;
        self.completionBlock = completionBlock;
        self.errorBlock = errorBlock;
    }
    return self;
}

- (void)parse {
    __weak VastParser *weakSelf = self;
    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithURL:self.url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!weakSelf) {
            return;
        }
        
        if (error) {
            weakSelf.errorBlock(error);
        }
        else {
            if (data) {
                NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:data];
                xmlParser.delegate = weakSelf;
                self.latestVast = nil;
                self.latestVast = [[VastEnt alloc] init];
                [xmlParser parse];
            }
            else {
                weakSelf.errorBlock([NSError errorWithDomain:NSURLErrorDomain code:-1 userInfo:nil]);
            }
        }
    }];
    [dataTask resume];
    
    
}

#pragma mark -NSXMLParserDelegate
NSString *elementValue;
NSDictionary<NSString *,NSString *> * attributes;
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
    attributes:(NSDictionary<NSString *,NSString *> *)attributeDict {
    elementValue = @"";
    attributes = attributeDict;
    if ([elementName isEqualToString:TAG_LINEAR]) {
        NSString *offset = [attributes objectForKey:TAG_ATTR_SKIP_OFFSET];
        if (offset) {
            self.latestVast.skipOffset = [self stringToTimeInterval:offset];
        }
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    elementValue = [elementValue stringByAppendingString:string];
}

- (void)parser:(NSXMLParser *)parser
 didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName {
    if ([elementName isEqualToString:TAG_MEDIAFILE]) {
        self.latestVast.mediaURL = [elementValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    else if ([elementName isEqualToString:TAG_CLICKTHROUGH]) {
        self.latestVast.clickURL = [elementValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    else if ([elementName isEqualToString:TAG_VAST]) {
     //end scanning
        self.completionBlock(self.latestVast);
    }
}

- (NSTimeInterval)stringToTimeInterval:(NSString *)string {
    NSTimeInterval res = 0.0;
    
    NSArray *components = [string componentsSeparatedByString:@":"];
    if (components.count >= 3) {
        NSTimeInterval hours = [components[0] doubleValue];
        NSTimeInterval minutes = [components[1] doubleValue];
        NSTimeInterval seconds = [components[2] doubleValue];
        res = hours * 3600 + minutes * 60 + seconds;
    }
    
    return res;
}

@end
