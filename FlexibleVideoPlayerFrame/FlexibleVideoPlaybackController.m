//
//  FlexibleVideoPlaybackController.m
//  FlexibleVideoPlayer
//
//  Created by Hoan Nguyen on 8/25/17.
//  Copyright © 2017 Hoan Nguyen. All rights reserved.
//

#import "FlexibleVideoPlaybackController.h"
#import <AVFoundation/AVFoundation.h>
#import "FlexiblePlayerLayerView.h"
#import "VastParser.h"
#import "FlexibleVastPlayer.h"

#define SCR_BOUNDS  [[UIScreen mainScreen] bounds]
#define SCR_WIDTH  SCR_BOUNDS.size.width
#define SCR_HEIGHT  SCR_BOUNDS.size.height

#define CTRL_HEIGHT  MIN(SCR_WIDTH, SCR_HEIGHT) * 0.5625f
#define EXTRAS_HEIGHT MAX(SCR_WIDTH, SCR_HEIGHT) - CTRL_HEIGHT

#define CTRL_MINIMIZED_WIDTH SCR_WIDTH * 0.6
#define CTRL_MINIMIZED_HEIGHT CTRL_MINIMIZED_WIDTH * 0.5625f
#define CTRL_MINIMIZED_TOP  (SCR_HEIGHT * 0.7)

typedef enum PanDirection : int {
    PanDirectionLeftRight,
    PanDirectionRightLeft,
    PanDirectionTopRightBottom,
    PanDirectionTopLeftBottom,
    PanDirectionBottomRightTop,
    PanDirectionBottomLeftTop,
    PanDirectionNone
} PanDirection;

@interface FlexibleVideoPlaybackController ()<UIGestureRecognizerDelegate, FlexibleVastPlayerDelegate>
@property (strong, nonatomic)  NSLayoutConstraint *csPlayerAreaHeight;
//@property (weak, nonatomic)  NSLayoutConstraint *csContentHeight;
@property (strong, nonatomic)  NSLayoutConstraint *csPlayerAreaLeft;
@property (strong, nonatomic)  NSLayoutConstraint *csPlayerAreaTop;
@property (strong, nonatomic)  NSLayoutConstraint *csPlayerAreaRight;
@property UIInterfaceOrientation currentOrientation;
@property (strong, nonatomic) NSMutableArray *constraints;
@property (weak, nonatomic) UIViewController *parent;

//extra content
@property (strong, nonatomic) UIView *viewExtras;
@property (strong, nonatomic) NSLayoutConstraint *csViewExtrasTop;
@property (strong, nonatomic) NSLayoutConstraint *csViewExtrasLeft;
@property (strong, nonatomic) NSLayoutConstraint *csViewExtrasRight;
@property (strong, nonatomic) NSLayoutConstraint *csViewExtrasHeight;
@property (weak, nonatomic) UIView *extraContent;
@property (strong, nonatomic) NSLayoutConstraint *csExtraContentTop;
@property (strong, nonatomic) NSLayoutConstraint *csExtraContentLeft;
@property (strong, nonatomic) NSLayoutConstraint *csExtraContentRight;
@property (strong, nonatomic) NSLayoutConstraint *csExtraContentBottom;

//player
@property (strong, nonatomic) AVPlayer *player;
@property (weak, nonatomic) IBOutlet FlexiblePlayerLayerView *playerLayerContainer;

//ads

@property (weak, nonatomic) IBOutlet FlexibleVastPlayer *vastPlayerView;
@property (weak, nonatomic) IBOutlet UIButton *btnSkipAds;
@property (weak, nonatomic) IBOutlet UILabel *lblAdDuration;

@end

@implementation FlexibleVideoPlaybackController
BOOL maximized = NO;
- (void)viewDidLoad {
    [super viewDidLoad];
    self.currentOrientation = UIInterfaceOrientationPortrait;
    [self addPanGesture];
    [self addTapGesture];
    [self initVideoPlayer];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    self.vastPlayerView.delegate = self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationWillEnterForeground {
    
}

- (void)applicationDidEnterBackground {
    if (self.player && self.player.currentItem) {
        [self.player pause];
    }
}


#pragma mark -IBActions

- (IBAction)didTapBtnLandscape:(id)sender {
    [self forceLanscape];
}

- (IBAction)didTapBtnBack:(id)sender {
    //    [self dismiss];
    [self forcePortrait];
}

#pragma mark -Controller gestures

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)addTapGesture {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetected:)];
    tapGesture.delegate = self;
    [self.view addGestureRecognizer:tapGesture];
}

- (void)addPanGesture {
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panDetected:)];
    [panGesture setMaximumNumberOfTouches:1];
    panGesture.delegate = self;
    [self.view addGestureRecognizer:panGesture];
}

-(void)tapDetected:(UITapGestureRecognizer*)sender {
    if (!maximized) {
        [self maximize:YES];
    }
}

-(void)panDetected:(UIPanGestureRecognizer*)sender {
    CGPoint translatedPoint = [sender locationInView:self.parent.view];
    UIView *view = sender.view;
    
    NSLog(@"now : %f : %f", translatedPoint.x, translatedPoint.y);
    static CGPoint lastPoint;
    static CGPoint startPoint;
    static PanDirection panDirection = PanDirectionNone;
    static CGFloat panVerticalPadding = 0.0;
    static CGFloat panHorizontalPadding = 0.0;
    CGFloat const velocity = 250 ;

    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            startPoint = translatedPoint;
            panVerticalPadding = startPoint.y - self.csPlayerAreaTop.constant;
            panHorizontalPadding = startPoint.x - self.csPlayerAreaLeft.constant;
            break;
        case UIGestureRecognizerStateChanged:
            if (panDirection == PanDirectionNone &&
                ( startPoint.x != translatedPoint.x || startPoint.y != translatedPoint.y)) {
                //detect current pan direction
                //orientation detection
                BOOL verticalPan = NO;
                CGFloat xDistance = startPoint.x - translatedPoint.x;
                xDistance = xDistance < 0 ? xDistance * -1 : xDistance;
                CGFloat yDistance = startPoint.y - translatedPoint.y;
                yDistance = yDistance < 0 ? yDistance * -1 : yDistance;
                if (xDistance < yDistance) {
                    verticalPan = YES;
                }
                
                if (verticalPan) {
                    //up or down
                    if (startPoint.y > translatedPoint.y) {
                        // up
                        if (startPoint.x < view.bounds.size.width / 2) {
                            // up left
                            panDirection = PanDirectionBottomLeftTop;
                        }
                        else {
                            // up right
                            panDirection = PanDirectionBottomRightTop;
                        }
                    }
                    else {
                        //down
                        if (startPoint.x < view.bounds.size.width / 2) {
                            // down left
                            panDirection = PanDirectionTopLeftBottom;
                        }
                        else {
                            // down right
                            panDirection = PanDirectionTopRightBottom;
                        }
                    }
                }
                else {
                    //left or right
                    if (startPoint.x > translatedPoint.x) {
                        //left
                        panDirection = PanDirectionRightLeft;
                    }
                    else {
                        //right
                        panDirection = PanDirectionLeftRight;
                    }
                }
                
                
            }
            
            //operation
            
            if (UIInterfaceOrientationIsLandscape(self.currentOrientation)) {
                switch (panDirection) {
                    case PanDirectionTopRightBottom:
                        //volume down
                        break;
                    case PanDirectionTopLeftBottom:
                        //brightness down
                        break;
                    case PanDirectionBottomRightTop:
                        //volume up
                        break;
                    case PanDirectionBottomLeftTop:
                        //brightness up
                        break;
                    default:
                        break;
                }
            }
            else {
                switch (panDirection) {
                    case PanDirectionBottomLeftTop:
                    case PanDirectionBottomRightTop:
                    case PanDirectionTopLeftBottom:
                    case PanDirectionTopRightBottom:
                    {
                        CGFloat targetY = translatedPoint.y - panVerticalPadding;
                        CGFloat moveDistance = translatedPoint.y - lastPoint.y;
                        //s = v*t => t = s/v
                        NSTimeInterval time = moveDistance / velocity;
                        
                        if (targetY < 0) {
                            targetY = 0;
                        }
                        if (targetY > CTRL_MINIMIZED_TOP) {
                            targetY = CTRL_MINIMIZED_TOP;
                        }
                        
                        self.csPlayerAreaTop.constant = targetY;
                        self.csPlayerAreaRight.constant = -8.0;
                        CGFloat distanceBasedRate = (targetY) / CTRL_MINIMIZED_TOP;
                        CGFloat maxLeft = SCR_WIDTH - CTRL_MINIMIZED_WIDTH - 8;
                        self.csPlayerAreaLeft.constant = (maxLeft * distanceBasedRate);
                        self.csPlayerAreaHeight.constant = self.view.frame.size.width * 0.5625f;
                        self.viewExtras.alpha = 1 - distanceBasedRate;
                        
                        [UIView animateWithDuration:time animations:^{
                            [self.parent.view layoutIfNeeded];
                        }];
                        
                        break;
                    }
                        
                    case PanDirectionLeftRight:
                    case PanDirectionRightLeft:
                        if (!maximized) {
                            CGFloat targetX = translatedPoint.x - panHorizontalPadding;
                            CGFloat moveDistance = translatedPoint.x - lastPoint.x;
                            moveDistance = moveDistance < 0 ? moveDistance * -1: moveDistance;
                            NSTimeInterval time = moveDistance / velocity;
                            self.csPlayerAreaLeft.constant = targetX;
                            self.csPlayerAreaRight.constant =  -(SCR_WIDTH - 8.0 - CTRL_MINIMIZED_WIDTH - targetX);
                            [UIView animateWithDuration:time animations:^{
                                [self.parent.view layoutIfNeeded];
                            }];
                        }
                        break;
                        
                    default:
                        break;
                }
            }
            
            break;
        default:
            
            if (UIInterfaceOrientationIsLandscape(self.currentOrientation)) {
            
            }
            else {
                switch (panDirection) {
                    case PanDirectionBottomLeftTop:
                    case PanDirectionBottomRightTop:
                    case PanDirectionTopLeftBottom:
                    case PanDirectionTopRightBottom:
                    {
                        //minimize/maximize player based on last position
                        if (self.csPlayerAreaTop.constant < CTRL_MINIMIZED_TOP / 2) {
                            [self maximize:YES];
                        }
                        else {
                            [self minimize:YES];
                        }
                        
                        break;
                    }
                        
                    case PanDirectionLeftRight:
                    case PanDirectionRightLeft:
                    {
                        if (!maximized) {
                            //minimize/maximize player based on last position
                            if (self.csPlayerAreaLeft.constant <= 0 || self.csPlayerAreaLeft.constant >= SCR_WIDTH - CTRL_MINIMIZED_WIDTH / 2) {
                                self.csPlayerAreaLeft.constant = (panDirection == PanDirectionRightLeft) ? -CTRL_MINIMIZED_WIDTH - 8 : SCR_WIDTH;
                                self.csPlayerAreaRight.constant =  -(SCR_WIDTH - 8.0 - CTRL_MINIMIZED_WIDTH - self.csPlayerAreaLeft.constant);
                                [UIView animateWithDuration:0.3 animations:^{
                                    [self.parent.view layoutIfNeeded];
                                } completion:^(BOOL finished) {
                                    if (finished) {
                                        [self removeFromParent];
                                    }
                                }];
                            }
                            else {
                                [self minimize:YES];
                            }
                        }
                    }
                        
                    default:
                        break;
                }
            }
            
            //ended, canceled or wev
            panDirection = PanDirectionNone;
            panVerticalPadding = 0.0;
            panHorizontalPadding = 0.0;
            //NSLog(@"end : %f : %f", translatedPoint.x, translatedPoint.y);
            break;
    }
    
    
    lastPoint = translatedPoint;
    [sender setTranslation:CGPointZero inView:self.view];
}

#pragma mark -Controller functions

- (void)loadVideo:(NSString *)urlString {
    [self.player pause];
    NSURL *url = [NSURL URLWithString:urlString];
    if (url) {
        [self maximize:YES];
        AVAsset *asset = [AVAsset assetWithURL:url];
        __weak FlexibleVideoPlaybackController* weakSelf = self;
        [asset loadValuesAsynchronouslyForKeys:@[@"duration"] completionHandler:^{
            if (!weakSelf) {
                return;
            }
            AVPlayerItem *newItem = [[AVPlayerItem alloc] initWithAsset:asset];
            [weakSelf.player replaceCurrentItemWithPlayerItem:newItem];
            [weakSelf.player seekToTime:kCMTimeZero];

            NSString * kPrerollTag =
            @"http://123.30.134.153:8406/xmlgen?type=mp4&size=854x400&media_src=http%3A//s71.stream.nixcdn.com/tvc/heineken_161.mp4&delivery=progressive&duration=00:00:15&track_impression=&track_click=&lk=c2yhfWBW1bf8n2d7JHgh8HfU63ZYk035&click_url=http%3A%2F%2F123.30.134.153%3A8406%2Fclick%3Fd%3D7b2274696d65223a2231353035373230373330363432222c226c6b223a226332796866574257316266386e3264374a4867683848665536335a596b303335222c22746172676574223a226874747025334125324625324662732e73657276696e672d7379732e636f6d2532464275727374696e675069706525324661645365727665722e6273253346636e25334474662532366325334432302532366d63253344636c69636b253236706c692533443139393536323631253236506c754944253344302532366f7264253344253235356274696d657374616d70227d";
            NSURL *vastURL = [NSURL URLWithString:kPrerollTag];
            VastParser *vastParser = [[VastParser alloc] initWith:vastURL completed:^(VastEnt *vast) {
                if (!weakSelf) {
                    return;
                }
                //load vast
                dispatch_async (dispatch_get_main_queue(), ^{
                    [weakSelf.vastPlayerView loadVastResource:vast];
                });
            } error:^(NSError *error) {
                if (weakSelf) {
                    [weakSelf.player play];
                }
            }];
            [vastParser parse];
        }];
        
    }
}
- (void)initVideoPlayer {
    self.player = [[AVPlayer alloc] init];
    CALayer *superLayer = self.playerLayerContainer.layer;
    [(AVPlayerLayer *)superLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [(AVPlayerLayer *)superLayer setPlayer:self.player];
    
}

- (void)addToParent:(UIViewController *)parent  withExtraContent:(UIView *)extraContent {
    
    if (self.view.superview != nil) {
        [self removeFromParent];
    }
    self.extraContent = extraContent;
    self.parent = parent;
    [self.parent addChildViewController:self];
    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.view.hidden = YES;
    [self.parent.view addSubview:self.view];
    [self.parent.view bringSubviewToFront:self.view];
    
    //add constraints
    self.csPlayerAreaHeight = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:CTRL_HEIGHT];
    self.csPlayerAreaTop = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.parent.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
    self.csPlayerAreaLeft = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.parent.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
    self.csPlayerAreaRight = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.parent.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];

    [self didMoveToParentViewController:parent];
    
    
    //view extras
    if (self.viewExtras == nil) {
        self.viewExtras = [[UIView alloc] init];
        self.viewExtras.backgroundColor = [UIColor whiteColor];
        self.viewExtras.translatesAutoresizingMaskIntoConstraints = NO;
    }
    //self.viewExtras.hidden = YES;
    [self.parent.view addSubview:self.viewExtras];
    [self.parent.view bringSubviewToFront:self.viewExtras];
    //view extras constraints
    self.csViewExtrasTop = [NSLayoutConstraint constraintWithItem:self.viewExtras attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    self.csViewExtrasLeft = [NSLayoutConstraint constraintWithItem:self.viewExtras attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.parent.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
    self.csViewExtrasRight = [NSLayoutConstraint constraintWithItem:self.viewExtras attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.parent.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
    self.csViewExtrasHeight = [NSLayoutConstraint constraintWithItem:self.viewExtras attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:EXTRAS_HEIGHT];

    self.constraints = [NSMutableArray arrayWithObjects:self.csPlayerAreaHeight, self.csPlayerAreaRight, self.csPlayerAreaLeft, self.csPlayerAreaTop, self.csViewExtrasTop, self.csViewExtrasLeft, self.csViewExtrasRight, self.csViewExtrasHeight, nil];
    
    //extra content
    if (self.extraContent != nil) {
        self.extraContent.translatesAutoresizingMaskIntoConstraints = NO;
        [self.extraContent removeFromSuperview];
        [self.viewExtras addSubview:self.extraContent];
        self.csExtraContentBottom = [NSLayoutConstraint constraintWithItem:self.extraContent attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.viewExtras attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
        self.csExtraContentTop = [NSLayoutConstraint constraintWithItem:self.extraContent attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.viewExtras attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
        self.csExtraContentLeft = [NSLayoutConstraint constraintWithItem:self.extraContent attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.viewExtras attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
        self.csExtraContentRight = [NSLayoutConstraint constraintWithItem:self.extraContent attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.viewExtras attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
        
        [self.constraints addObjectsFromArray:@[self.csExtraContentLeft, self.csExtraContentTop, self.csExtraContentBottom, self.csExtraContentRight]];
    }
    
    
    
    
    
    [self.parent.view addConstraints:self.constraints];
    [self minimize:NO];
    self.view.hidden = YES;
    
    
    
}


- (void)removeFromParent {
    [self.player pause];
    [self.parent.view removeConstraints:self.constraints];
    [self.view removeFromSuperview];
    [self.viewExtras removeFromSuperview];
    [self removeFromParentViewController];
    //remove ads
    [self.vastPlayerView close];
}

- (void)maximize:(BOOL)animated {
    
    if (self.parent != nil && self.view.superview == nil) {
        [self addToParent:self.parent withExtraContent:self.extraContent];
    }
    
    maximized = YES;
    if (!UIInterfaceOrientationIsLandscape(self.currentOrientation)) {
        [self.parent.view.layer removeAllAnimations];
        self.csPlayerAreaHeight.constant = CTRL_HEIGHT;
        self.csPlayerAreaTop.constant = 0;
        self.csPlayerAreaLeft.constant = 0;
        self.csPlayerAreaRight.constant = 0;
        if (!animated) {
            self.viewExtras.alpha = 1.0;
            self.view.alpha = 1.0;
            self.view.hidden = NO;
            [self.parent.view layoutIfNeeded];
            return;
        }
        
        if (self.view.hidden == YES) {
            self.view.alpha = 0;
            self.view.hidden = NO;
        }
        
        if (self.viewExtras.hidden == YES) {
            self.viewExtras.alpha = 0;
            self.viewExtras.hidden = NO;
        }
        
        [UIView animateWithDuration:0.3 animations:^{
            self.view.alpha = 1.0;
            self.viewExtras.alpha = 1.0;
            [self.parent.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            
        }];
    }
}

- (void)minimize:(BOOL)animated {
    maximized = NO;
    if (!UIInterfaceOrientationIsLandscape(self.currentOrientation)) {
        [self.parent.view.layer removeAllAnimations];
        self.csPlayerAreaHeight.constant = CTRL_MINIMIZED_HEIGHT;
        self.csPlayerAreaTop.constant = CTRL_MINIMIZED_TOP;
        self.view.alpha = 1.0;
        self.view.hidden = NO;
        //self.viewExtras.alpha = 1.0;
        self.viewExtras.hidden = NO;
        self.csPlayerAreaRight.constant = -8;
        self.csPlayerAreaLeft.constant = SCR_WIDTH - CTRL_MINIMIZED_WIDTH - 8;
        if (!animated) {
            [self.parent.view layoutIfNeeded];
            self.viewExtras.alpha = 0.0;
            return;
        }
        [UIView animateWithDuration:0.3 animations:^{
            self.viewExtras.alpha = 0.0;
            [self.parent.view layoutIfNeeded];
        }];
    }
}

- (void)forceLanscape {
    if (!UIInterfaceOrientationIsLandscape(self.currentOrientation)) {
        [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationLandscapeRight) forKey:@"orientation"];
    }
}

- (void)forcePortrait {
    if (UIInterfaceOrientationIsLandscape(self.currentOrientation)) {
        [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationPortrait) forKey:@"orientation"];
    }
}

#pragma mark -Orientations

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    if (self.view.hidden)
    {
        return UIInterfaceOrientationMaskPortrait;
    }
    return UIInterfaceOrientationMaskAllButUpsideDown;
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        self.csPlayerAreaHeight.constant = MIN(SCR_WIDTH, SCR_HEIGHT);
        self.csPlayerAreaTop.constant = 0;
        self.csPlayerAreaLeft.constant = 0;
        self.csPlayerAreaRight.constant = 0;
        
    }else{
        self.csPlayerAreaHeight.constant = CTRL_HEIGHT;
    }
    [self maximize:YES];
    self.currentOrientation = toInterfaceOrientation;
}

#pragma mark -FlexibleVastPlayerDelegate

- (void)vastPlayer:(FlexibleVastPlayer *)vastPlayer didUpdatePeriodicTime:(NSTimeInterval)currentTime inTotal:(NSTimeInterval)total {
    NSTimeInterval currentProgress = total - currentTime;
    if (!isnan(currentProgress)) {
    self.lblAdDuration.text = [NSString stringWithFormat:@"%.0f",currentProgress];
    }
}

- (void)vastPlayerDidReachSkipOffset:(FlexibleVastPlayer *)vastPlayer {
    //show skip btn
    self.btnSkipAds.hidden = NO;
}

- (void)vastPlayerWillEndPlaying:(FlexibleVastPlayer *)vastPlayer {
    if (self.player.currentItem) {
        [self.player play];
    }
    self.btnSkipAds.hidden = YES;
}

- (void)vastPlayerDidStartPlaying:(FlexibleVastPlayer *)vastPlayer {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.btnSkipAds.hidden = YES;
    });
}

- (void)vastPlayerDidReceiveTap:(FlexibleVastPlayer *)vastPlayer toUrl:(NSURL *)tapUrl {
    [self.vastPlayerView close];
    if (![[UIApplication sharedApplication] openURL:tapUrl]) {
        NSLog(@"%@%@",@"Failed to open url:",[tapUrl description]);
    }
}

- (IBAction)didTapBtnSkipAd:(UIButton *)sender {
    [self.vastPlayerView close];
}

@end
