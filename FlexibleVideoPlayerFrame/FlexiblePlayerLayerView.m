//
//  FlexiblePlayerLayerView.m
//  FlexibleVideoPlayer
//
//  Created by Hoan Nguyen on 8/29/17.
//  Copyright © 2017 Hoan Nguyen. All rights reserved.
//

#import "FlexiblePlayerLayerView.h"
#import <AVFoundation/AVFoundation.h>
@implementation FlexiblePlayerLayerView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

@end
