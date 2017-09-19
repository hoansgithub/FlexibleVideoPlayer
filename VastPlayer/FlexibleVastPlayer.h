//
//  FlexibleVastPlayer.h
//  FlexibleVideoPlayer
//
//  Created by Hoan Nguyen on 9/18/17.
//  Copyright © 2017 Hoan Nguyen. All rights reserved.
//

#import "FlexiblePlayerLayerView.h"
#import "VastEnt.h"

@class FlexibleVastPlayer;
@protocol FlexibleVastPlayerDelegate<NSObject>
- (void)vastPlayer:(FlexibleVastPlayer *)vastPlayer didUpdatePeriodicTime:(NSTimeInterval)currentTime inTotal:(NSTimeInterval)total;
- (void)vastPlayerDidStartPlaying:(FlexibleVastPlayer*)vastPlayer;
- (void)vastPlayerWillEndPlaying:(FlexibleVastPlayer*)vastPlayer;
- (void)vastPlayerDidReachSkipOffset:(FlexibleVastPlayer*)vastPlayer;
- (void)vastPlayerDidReceiveTap:(FlexibleVastPlayer*)vastPlayer toUrl:(NSURL *)tapUrl;
@end
@interface FlexibleVastPlayer : FlexiblePlayerLayerView
- (void)loadVastResource:(VastEnt *)vast;
- (void)close;
@property (weak, nonatomic) id<FlexibleVastPlayerDelegate> delegate;
@end
