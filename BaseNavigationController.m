//
//  BaseNavigationController.m
//  FlexibleVideoPlayer
//
//  Created by Hoan Nguyen on 8/23/17.
//  Copyright © 2017 Hoan Nguyen. All rights reserved.
//

#import "BaseNavigationController.h"
@interface BaseNavigationController ()

@end

@implementation BaseNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setNavigationBarHidden:true];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return [self.topViewController supportedInterfaceOrientations];
}



@end
