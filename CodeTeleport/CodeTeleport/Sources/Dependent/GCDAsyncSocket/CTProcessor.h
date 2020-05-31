//
//  CTProcessor.h
//  CodeTeleport
//
//  Created by zhaolei.lzl on 2018/6/29.
//  Copyright © 2018年 zhaolei.lzl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTBuilder.h"

@interface CTProcessor : NSObject

@property(nonatomic,strong) CTBuilder *builder;

- (void)processMessage:(NSString *)message;

@end
