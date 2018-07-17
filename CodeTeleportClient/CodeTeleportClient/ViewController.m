//
//  ViewController.m
//  CodeTeleportClient
//
//  Created by zhaolei.lzl on 2018/6/29.
//  Copyright © 2018年 zhaolei.lzl. All rights reserved.
//

#import "ViewController.h"
#import "TestOBJ.h"
//#import "CodeTeleportLoader.h"
#import <objc/runtime.h>
//#import "CodeTeleportUtils.h"

void test(){
    
    NSLog(@"000");
}

@interface ViewController (){
    int testVar;
}

@property (strong, nonatomic) UIButton *button;

@end

@implementation ViewController

#ifdef DEBUG
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

#endif

- (void)log
{
    NSLog(@"logloglogloglog:6");
    [self.button setTitle:@"add testVC9" forState:UIControlStateNormal];
}

- (void)aui_isKindOfClass:(id) sender
{
//    NSLog(@"aui_isKindOfClass:8");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.frame = [UIScreen mainScreen].bounds;
    self.button = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.button addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
    self.button.frame = CGRectMake(100, 50, 100, 50);
    [self.view addSubview:self.button];
    testVar = 5; 
    [self log];
    [self aui_isKindOfClass:nil];
    // Do any additional setup after loading the view, typically from a nib.
//       5
//    [CodeTeleportLoader loadDylibWithPath:@"/private/tmp/com.zhaolei.CodeTeleport/BuildTask_552390664/codeTeleport_552390664.dylib"
//                     classNames:@[@"TestOBJ"]];
    
}

- (void)buttonClicked:(id)sender { 
    //    [self log]; 
    [self.navigationController pushViewController:[objc_getClass("ViewController") new] animated:YES];
//    [self.navigationController pushViewController:[ViewController new] animated:YES];
}

//+ (void)printMethodAddress:(Class) class
//{
//    unsigned int methodCount;
//    Method *methods = class_copyMethodList(class, &methodCount);
//    //    CTLog("dylib class %@ methodCount: %u",class,methodCount);
//    for (int index=0; index < methodCount; index++) {
//        //        CTLog("exchange method: %@",NSStringFromSelector(method_getName(methods[index])));
//        NSLog(@"method: %@,IMP: %p",NSStringFromSelector(method_getName(methods[index])),method_getImplementation(methods[index]));
//    }
//}
//
//+ (void)printIvarAddress:(Class) class
//{
//    unsigned int methodCount;
//    Ivar * ivars = class_copyIvarList(class, &methodCount);
//    //    CTLog("dylib class %@ methodCount: %u",class,methodCount);
//    for (int index=0; index < methodCount; index++) {
//        //        CTLog("exchange method: %s",NSStringFromSelector(method_getName(methods[index])));
//        NSLog(@"ivar: %p",ivars[index]);
//    }
//}


@end
