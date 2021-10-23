//
//  ViewController.m
//  CodeTeleportClient
//
//  Created by zhaolei.lzl on 2018/6/29.
//  Copyright © 2018年 zhaolei.lzl. All rights reserved.
//

#import "ViewController.h"


@interface ViewController()

@property(nonatomic, strong) UIView *demoView;

@end

@implementation ViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                               selector:@selector(codeteleport_completed) name:@"kCodeTeleportCompletedNotification"
                                 object:nil];
    }
    return self;
}

- (void)dealloc
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self
                                  name:@"kCodeTeleportCompletedNotification"
                                object:nil];
}

- (void)codeteleport_completed
{
    for (UIView *subView in self.view.subviews) {
        [subView removeFromSuperview];
    }
    [self viewDidLoad];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.demoView = [[UIView alloc] initWithFrame:CGRectMake(50, 100, 100, 100)];
    self.demoView.backgroundColor = [UIColor yellowColor];
    
    [self.view addSubview:self.demoView];
}

@end
