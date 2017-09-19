//
//  ViewController.m
//  FlexibleVideoPlayer
//
//  Created by Hoan Nguyen on 8/23/17.
//  Copyright © 2017 Hoan Nguyen. All rights reserved.
//
#import "FlexibleVideoPlaybackController.h"
#import "ViewController.h"
@interface ViewController ()<UITableViewDelegate , UITableViewDataSource>
//@property (strong, nonatomic) FlexibleVideoPlayerViewController *playerVC;
@property (strong, nonatomic) FlexibleVideoPlaybackController *videoPlayerVC;
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSArray *dataStream;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView = [[UITableView alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"tablecell"];
    self.dataStream = @[@"item ht", @"item hjyt", @"item sdfe", @"item werh", @"item ewrfg",
                        @"item ar", @"item ytrfvbh",@"item trhywer",@"item hfghfd",@"item sfd",
                        @"item et",@"item agfs",@"item tyasd",@"item asd",@"item rgt",@"item ae",@"item n"];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.videoPlayerVC == nil) {
        self.videoPlayerVC = [[FlexibleVideoPlaybackController alloc] initWithNibName:@"FlexibleVideoPlaybackController" bundle:nil];
        
        [self.videoPlayerVC addToParent:self.navigationController withExtraContent:self.tableView];
    }
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)didTapVideo:(id)sender {
    NSString *videoURL = @"http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4";
    [self.videoPlayerVC loadVideo:videoURL];
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (self.videoPlayerVC != nil && !self.videoPlayerVC.view.hidden && self.videoPlayerVC.parentViewController == self) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }
    return UIInterfaceOrientationMaskPortrait;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.videoPlayerVC willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}


#pragma mark -TAble

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataStream.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"tablecell"];
    cell.textLabel.text = (NSString *)self.dataStream[indexPath.row];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *videoURL = @"http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WhatCarCanYouGetForAGrand.mp4";
    [self.videoPlayerVC loadVideo:videoURL];
}
@end
