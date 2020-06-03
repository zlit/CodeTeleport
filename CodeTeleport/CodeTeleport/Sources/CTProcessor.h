//
//  CTProcessor.h
//  CodeTeleport
//
//  Created by zhaolei.lzl on 2018/6/29.
//  Copyright © 2018年 zhaolei.lzl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTBuilder.h"
#import "CTPTChannelPrivate.h"

@class CTProcessor;

typedef void(^ProcessResponseBlock)(CTProcessor *builder, CTDataType dataType, NSData* data);

typedef enum : NSUInteger {
    CTCommunicationChannelLocalHost = 1001,
    CTCommunicationChannelUSB = 1002
} CTCommunicationChannel;

@interface CTProcessor : NSObject

@property(nonatomic,assign) CTCommunicationChannel communicationChannel;
@property(nonatomic,copy) ProcessResponseBlock processResponseBlock;
@property(nonatomic,strong) CTBuilder *builder;

- (void)processMessage:(NSString *)message;

@end
