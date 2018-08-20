//
//  VastParser.h
//  FlexibleVideoPlayer
//
//  Created by Hoan Nguyen on 9/18/17.
//  Copyright © 2017 Hoan Nguyen. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "VastEnt.h"
@interface VastParser : NSObject
- (instancetype)initWith : (NSURL *)url completed:(void (^)(VastEnt*))completionBlock error:(void (^)(NSError*))errorBlock;
- (void)parse;
@end
