//
//  AppDelegate.h
//  CodeTeleport
//
//  Created by zhaolei.lzl on 2018/6/29.
//  Copyright © 2018年 zhaolei.lzl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum : NSUInteger {
    StatusIconTypeIdle,
    StatusIconTypeActive
} StatusIconType;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property(nonatomic,copy) NSString *urlScheme;

- (void)setStatusIcon:(StatusIconType) state;

- (void)showCompeledNotice:(NSString *)notice;

@end

