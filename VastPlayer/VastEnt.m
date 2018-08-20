//
//  VastEnt.m
//  FlexibleVideoPlayer
//
//  Created by Hoan Nguyen on 9/18/17.
//  Copyright © 2017 Hoan Nguyen. All rights reserved.
//

#import "VastEnt.h"

@implementation VastEnt
- (instancetype)init {
    self = [super init];
    if (self != nil) {
        self.mediaURL = @"";
        self.clickURL = @"";
        self.skipOffset = 0.0;
    }
    return self;
}
@end
