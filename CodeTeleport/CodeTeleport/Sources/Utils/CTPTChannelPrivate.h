//
//  PTPrivate.h
//  CodeTeleport
//
//  Created by zhaolei on 2020/5/31.
//  Copyright © 2020 zhaolei.lzl. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define kUSBListenPort 19999

typedef struct CTMessageTextFrame {
    uint32_t length;
    uint8_t text[0];
} CTMessageTextFrame;

typedef struct CTDylibDataFrame {
    uint32_t length;
    uint8_t data[0];
} CTDylibDataFrame;

typedef enum : NSUInteger {
    CTDataTypeText = 1001,
    CTDataTypeDylib = 1002
} CTDataType;

@interface CTPTChannelPrivate : NSObject

+ (NSString *)parseTextFrameToNSString:(CTMessageTextFrame *)textFrame;

+ (dispatch_data_t)parseNSStringToTextFrameData:(NSString *)msg;

+ (dispatch_data_t)parseNSStringToDylibFrameData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
