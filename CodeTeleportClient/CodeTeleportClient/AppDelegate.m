//
//  AppDelegate.m
//  CodeTeleportClient
//
//  Created by zhaolei.lzl on 2018/6/29.
//  Copyright © 2018年 zhaolei.lzl. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "TestOBJ.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions { 
    // Override point for customization after application launch.
    
    NSString *clientBundlePath = [[NSBundle mainBundle] pathForResource:@"CTClient" ofType:@"framework"];
    NSLog(@"%@",clientBundlePath);
    [[NSBundle bundleWithPath:clientBundlePath] load];
    
    CGFloat time = 0;
    
    for(int k=0;k<20;k++){
        CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
        for(int i=0;i<10000;i++){
            @autoreleasepool{
                TestOBJ *obj = [[TestOBJ alloc] init];
            }
        }
        CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
        time += (end - start);
        NSLog(@"------- %d : %f",k, (end - start));
    }
    NSLog(@"average time : %lf",time/20);
    ViewController *vc = [[ViewController alloc] init];
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:vc];
    self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];
    return YES;
}


- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL*)url
{
    // 接受传过来的参数
    NSString *text = [[url host] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"%@",text);
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    
//       7
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
