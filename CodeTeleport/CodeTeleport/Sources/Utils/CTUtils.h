//
//  CTUtils.h
//  CodeTeleport
//
//  Created by zhaolei.lzl on 2018/6/29.
//  Copyright © 2018年 zhaolei.lzl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"

#define CTLog(fmt, ...) \
NSLog((@"[CodeTeleportServer] " fmt), ##__VA_ARGS__); \

#define CTLogAssertNO(fmt, ...) \
CTLog(fmt, ##__VA_ARGS__); \
NSAssert(NO, fmt, ##__VA_ARGS__);\

//#define INLog( _fmt... ) \
//printf( "> Teleport: %s\n", [NSString stringWithFormat:_fmt].UTF8String )

#define NSStringMultiline(...) [[NSString alloc] initWithCString:#__VA_ARGS__ encoding:NSUTF8StringEncoding]

#define CTError(errorMsg)\
[NSError errorWithDomain:@"CodeTeleportBuildError" code:-1 \
userInfo:@{NSLocalizedDescriptionKey:errorMsg}];\

static NSString *XcodeBundleID = @"com.apple.dt.Xcode";

NS_INLINE AppDelegate *appdelegate(){
    return (AppDelegate *)[NSApplication sharedApplication].delegate;
}

@interface CTUtils : NSObject

+ (NSString *)getIPAddress;

+ (BOOL)executeShellCommand:(NSString *)command;

+ (NSString *)readLogWithPath:(NSString *)path;

@end
