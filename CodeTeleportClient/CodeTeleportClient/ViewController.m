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

static int testStaticVar = 0;

void test(){
    
    NSLog(@"000");
}

@interface ViewController (){
    int testVar;
}

@property (strong, nonatomic) UIButton *button;

@end

@implementation ViewController

- (void)addText{
    
}

- (instancetype)init
{
    self = [super init];
    if (self) {
             
    }
    return self;
}

+ (void)logStatic
{
    NSLog(@" logStatic self : %p",self);
}

- (void)log
{
    NSLog(@"self class : %p,image:%s",[self class],class_getImageName([self class]));
//    [ViewController printMethodAddress:[self class]];
//    [ViewController printIvarAddress:[self class]];
//
////    NSLog(@"objc_getClass %p",objc_getClass("ViewController"));
//    NSLog(@"NSClassFromString %p,image:%s",NSClassFromString(@"ViewController"),class_getImageName(NSClassFromString(@"ViewController")));
//
//    NSLog(@"ViewController class : %p,image:%s",[ViewController class],class_getImageName([ViewController class]));
//    [ViewController printMethodAddress:[ViewController class]];
//    [ViewController printIvarAddress:[ViewController class]];

    [ViewController logStatic];
    NSLog(@"test point :%p",test);
    
    [self.button setTitle:@"add testVC0" forState:UIControlStateNormal];
     
//    Class class = [TestOBJ class];
//    NSLog(@"555%p",class);
//    NSLog(@"%p",objc_getClass("TestOBJ"));
//    TestOBJ *obj1 = [[class.self alloc] init];
    
//    self.obj2 = [[TestOBJ alloc] init];
//    self.obj3 = [[TestOBJ alloc] init];
//    self.obj4 = [[TestOBJ alloc] init];
    
//    [self.obj1 log];
//    [self.obj2 log];
//    [self.obj3 log];
//    [self.obj4 log];
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
    // Do any additional setup after loading the view, typically from a nib.
//       5
    
//    [CodeTeleportLoader loadDylibWithPath:@"/private/tmp/CodeTeleport/BuildTask_552390664/codeTeleport_552390664.dylib"
//                     classNames:@[@"TestOBJ"]];
    
}

- (void)codeteleport_completed
{
    [self log]; 
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
