//
//  ViewController.m
//  CodeTeleportClient
//
//  Created by zhaolei.lzl on 2018/6/29.
//  Copyright © 2018年 zhaolei.lzl. All rights reserved.
//

#import "ViewController.h"
#import "TestOBJ.h"
#import "CodeTeleportLoader.h"
#import <objc/runtime.h>
#import "CodeTeleportUtils.h"

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

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

+ (void)test{
    NSLog(@"34567");
}

- (void)log
{
    Class class = [TestOBJ class];
    NSLog(@"555%p",class);
    NSLog(@"%p",objc_getClass("TestOBJ"));
    TestOBJ *obj1 = [[class.self alloc] init];
    
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
    [self.button setTitle:@"add vc" forState:UIControlStateNormal];
    [self.button addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
    self.button.frame = CGRectMake(100, 50, 100, 50);
    [self.view addSubview:self.button];
    
    
    // Do any additional setup after loading the view, typically from a nib.
//       5
    
//    [CodeTeleportLoader loadDylibWithPath:@"/private/tmp/CodeTeleport/BuildTask_552390664/codeTeleport_552390664.dylib"
//                     classNames:@[@"TestOBJ"]];
    
}

- (void)codeteleport_completed
{
    [self log];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)buttonClicked:(id)sender {
    //    [self log];
    [self.navigationController pushViewController:[ViewController new] animated:YES];
}

-(void)dealloc{
    NSLog(@"23113dd");
}

@end
