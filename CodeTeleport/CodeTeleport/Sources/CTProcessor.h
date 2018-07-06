//
//  CTProcessor.h
//  CodeTeleport
//
//  Created by zhaolei.lzl on 2018/6/29.
//  Copyright © 2018年 zhaolei.lzl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTBuilder.h"

@class CTProcessor;

typedef void(^ProcessResponseBlock)(CTProcessor *builder,NSString* msg);

@interface CTProcessor : NSObject

@property(nonatomic,copy) ProcessResponseBlock processResponseBlock;
@property(nonatomic,strong) CTBuilder *builder;

- (void)processMessage:(NSString *)message;

@end
