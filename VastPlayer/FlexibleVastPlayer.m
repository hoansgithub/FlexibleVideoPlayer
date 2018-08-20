//
//  FlexibleVastPlayer.m
//  FlexibleVideoPlayer
//
//  Created by Hoan Nguyen on 9/18/17.
//  Copyright © 2017 Hoan Nguyen. All rights reserved.
//

#import "FlexibleVastPlayer.h"
#import <AVFoundation/AVFoundation.h>

@interface FlexibleVastPlayer()
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) id periodicTimeObserverToken;
@property (strong, nonatomic) VastEnt * selectedVast;
@end

@implementation FlexibleVastPlayer

- (void)loadVastResource:(VastEnt *)vast {
    self.selectedVast = vast;
    if (self.player == nil) {
        [self initVastPlayer];
    }
    
    self.hidden = NO;
    
    [self removePlayerItemNotifications];
    
    NSURL *url = [NSURL URLWithString:vast.mediaURL];
    if (url) {
        AVAsset *asset = [AVAsset assetWithURL:url];
        __weak FlexibleVastPlayer* weakSelf = self;
        [asset loadValuesAsynchronouslyForKeys:@[@"playable"] completionHandler:^{
            if (!weakSelf) {
                return;
            }
            NSError *err;
            AVKeyValueStatus status = [asset statusOfValueForKey:@"playable" error:&err];
            switch (status) {
                case AVKeyValueStatusLoaded:
                {
                    AVPlayerItem *newItem = [[AVPlayerItem alloc] initWithAsset:asset];
                    [weakSelf.player replaceCurrentItemWithPlayerItem:newItem];
                    [weakSelf.player seekToTime:kCMTimeZero];
                    [weakSelf addPlayerItemNotifications];
                    [weakSelf.player play];
                    if (weakSelf.delegate) {
                        [weakSelf.delegate vastPlayerDidStartPlaying:weakSelf];
                    }
                }
                    break;
                case AVKeyValueStatusFailed:
                    //continue video
                    [self close:YES];
                    break;
                default:
                    [self close:YES];
                    break;
            }

        }];
        
    }
}

- (void)initVastPlayer {
    self.player = [[AVPlayer alloc] init];
    CALayer *superLayer = self.layer;
    [(AVPlayerLayer *)superLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [(AVPlayerLayer *)superLayer setPlayer:self.player];
    
    [self addPeriodicTimeObserver];
    
    //gesture
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didReceiveTap:)];
    gesture.numberOfTapsRequired = 1;
    [self addGestureRecognizer:gesture];
}

- (void)didReceiveTap:(UITapGestureRecognizer *)recoginzer {
    if (self.delegate && self.selectedVast) {
        NSURL *url = [NSURL URLWithString:self.selectedVast.clickURL];
        if (url) {
            [self.delegate vastPlayerDidReceiveTap:self toUrl:url];
        }
        
    }
}

- (void)addPeriodicTimeObserver {
    [self removePeriodicTimeObserver];
    CMTime time = CMTimeMakeWithSeconds(0.5, NSEC_PER_SEC);
    __weak FlexibleVastPlayer* weakSelf = self;
    self.periodicTimeObserverToken = [self.player addPeriodicTimeObserverForInterval:time queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        if (!weakSelf || !weakSelf.player.currentItem) {
            return;
        }
        //check skipoffset
        
        NSTimeInterval progressSecs = CMTimeGetSeconds(time);
        NSTimeInterval totalSecs = CMTimeGetSeconds(weakSelf.player.currentItem.duration);
        if (weakSelf.selectedVast.skipOffset <= progressSecs) {
            [weakSelf.delegate vastPlayerDidReachSkipOffset:weakSelf];
        }
        
        //trigger time change notification
        if (weakSelf.delegate) {
            [weakSelf.delegate vastPlayer:weakSelf didUpdatePeriodicTime:progressSecs inTotal:totalSecs];
        }
    }];
}

- (void)removePeriodicTimeObserver {
    if (self.periodicTimeObserverToken != nil) {
        [self.player removeTimeObserver:self.periodicTimeObserverToken];
        self.periodicTimeObserverToken = nil;
    }
}

- (void)dealloc {
    [self removePlayerItemNotifications];
    [self removePeriodicTimeObserver];
}

- (void)close:(BOOL)instancePlay {
    if (self.delegate && instancePlay) {
        [self.delegate vastPlayerWillEndPlaying:self];
    }
    self.hidden = YES;
    [self removePlayerItemNotifications];
}

#pragma mark -Notifications

- (void)addPlayerItemNotifications {
    if (self.player && self.player.currentItem) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidPlayToEndTime:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
    }
}

- (void)removePlayerItemNotifications {
    [self.player pause];
    [self.player replaceCurrentItemWithPlayerItem:nil];
    if (self.player && self.player.currentItem) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
    }
}

- (void)playerItemDidPlayToEndTime : (NSNotification*) notif {
    [self close:YES];
}


@end
