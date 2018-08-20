//
//  VastEnt.h
//  FlexibleVideoPlayer
//
//  Created by Hoan Nguyen on 9/18/17.
//  Copyright © 2017 Hoan Nguyen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VastEnt : NSObject
@property NSTimeInterval skipOffset;
@property (strong, nonatomic) NSString *mediaURL;
@property (strong, nonatomic) NSString *clickURL;
- (instancetype)init;
@end
