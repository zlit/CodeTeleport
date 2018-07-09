//
//  CodeTeleportSwizzle.m
//  CTClient
//
//  Created by zhaolei.lzl on 2018/7/5.
//  Copyright © 2018年 zhaolei.lzl. All rights reserved.
//

#import "CodeTeleportSwizzle.h"
#import <objc/runtime.h>
#import "CodeTeleportUtils.h"

@implementation CodeTeleportSwizzle

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

+ (void)load{
    [CodeTeleportSwizzle exchangeMethod:NSClassFromString(@"UIViewController")
                               selector:@selector(init)
                             toSelector:@selector(codeteleport_init)];
    [CodeTeleportSwizzle exchangeMethod:NSClassFromString(@"UIViewController")
                               selector:NSSelectorFromString(@"dealloc")
                             toSelector:@selector(codeteleport_dealloc)];
}

+ (void)exchangeMethod:(Class)class selector:(SEL)originalSelector toSelector:(SEL)swizzledSelector
{
    Method swizzledMethod = class_getInstanceMethod([self class], swizzledSelector);
    IMP swizzledIMP = method_getImplementation(swizzledMethod);
    if (class_getInstanceMethod(class, swizzledSelector) == NULL) {
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        if (class_addMethod(class, originalSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))) {
        }
        
        class_addMethod(class, swizzledSelector, swizzledIMP, method_getTypeEncoding(swizzledMethod));
        Method origMethod = class_getInstanceMethod(class, originalSelector);
        Method origSwizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        method_exchangeImplementations(origMethod, origSwizzledMethod);
    }
}

- (id)codeteleport_init
{
    id instance = [self codeteleport_init];
    if([instance respondsToSelector:@selector(codeteleport_completed)]){
        [[NSNotificationCenter defaultCenter] addObserver:instance selector:@selector(codeteleport_completed) name:kCodeTeleportCompletedNotification object:nil];
    }
    return instance;
}

- (void)codeteleport_dealloc
{
    if([self respondsToSelector:@selector(codeteleport_completed)]){
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kCodeTeleportCompletedNotification object:nil];
    }
    [self codeteleport_dealloc];
}

#pragma clang diagnostic pop

@end
