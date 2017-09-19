//
//  FlexibleVideoPlaybackController.h
//  FlexibleVideoPlayer
//
//  Created by Hoan Nguyen on 8/25/17.
//  Copyright © 2017 Hoan Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FlexibleVideoPlaybackController : UIViewController
- (void)minimize:(BOOL)animated;
- (void)maximize:(BOOL)animated;
- (void)loadVideo:(NSString *)urlString;
- (void)addToParent:(UIViewController *)parent withExtraContent: (UIView *)extraContent;
- (void)removeFromParent;

@end
