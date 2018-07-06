//
//  CTUtils.h
//  CodeTeleport
//
//  Created by zhaolei.lzl on 2018/6/29.
//  Copyright © 2018年 zhaolei.lzl. All rights reserved.
//

#import <Foundation/Foundation.h>

#define CTLog(fmt, ...) \
NSLog((@"[CodeTeleportClient] " fmt), ##__VA_ARGS__); \

#define kCodeTeleportCompletedNotification @"kCodeTeleportCompletedNotification"

#define CTError(fmt, ...)\
[NSError errorWithDomain:@"CodeTeleportClientError" code:-1 \
userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:fmt,##__VA_ARGS__]}];\

@interface CodeTeleportUtils : NSObject

+ (NSString *)getSeparatedFromStr:(NSString *) str
                         bySymbol:(NSString *) symbol
                            index:(NSUInteger) index;

@end
