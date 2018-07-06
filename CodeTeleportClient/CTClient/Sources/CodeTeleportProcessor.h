//
//  CTProcessor.h
//  CodeTeleport
//
//  Created by zhaolei.lzl on 2018/6/29.
//  Copyright © 2018年 zhaolei.lzl. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CodeTeleportProcessor;

typedef void(^ProcessResponseBlock)(CodeTeleportProcessor *builder,NSString* msg);

@interface CodeTeleportProcessor : NSObject

@property(nonatomic,copy) ProcessResponseBlock processResponseBlock;

- (void)processMessage:(NSString *)message;

@end
