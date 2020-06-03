//
//  PTPrivate.m
//  CodeTeleport
//
//  Created by zhaolei on 2020/5/31.
//  Copyright © 2020 zhaolei.lzl. All rights reserved.
//

#import "CTPTChannelPrivate.h"

@implementation CTPTChannelPrivate

+ (NSString *)parseTextFrameToNSString:(CTMessageTextFrame *)textFrame
{
    if (textFrame) {
        textFrame->length = ntohl(textFrame->length);
        NSString *msg = [[NSString alloc] initWithBytes:textFrame->text
                                                 length:textFrame->length
                                               encoding:NSUTF8StringEncoding];
        return msg;
    }else{
        return @"";
    }
}

+ (dispatch_data_t)parseNSStringToTextFrameData:(NSString *)msg
{
    const char *utfMsg = [msg cStringUsingEncoding:NSUTF8StringEncoding];
    size_t length = strlen(utfMsg);
    CTMessageTextFrame *textFrame = CFAllocatorAllocate(nil, sizeof(CTMessageTextFrame)+length, 0);
    memcpy(textFrame->text, utfMsg, length);
    textFrame->length =  htonl(length);
    return dispatch_data_create((const void *)textFrame, sizeof(CTMessageTextFrame)+length, nil, ^{
        CFAllocatorDeallocate(nil, textFrame);
    });
}

+ (dispatch_data_t)parseNSStringToDylibFrameData:(NSData *)data
{
    // Use a custom struct
    uint8_t data_bytes[data.length];
    [data getBytes:data_bytes length:data.length];
    size_t length = data.length;
    CTDylibDataFrame *dataFrame = CFAllocatorAllocate(nil, sizeof(CTDylibDataFrame) + length, 0);
    memcpy(dataFrame->data, data_bytes, length); // Copy bytes to utf8text array
    dataFrame->length = htonl(length); // Convert integer to network byte order

    // Wrap the textFrame in a dispatch data object
    return dispatch_data_create((const void*)dataFrame, sizeof(CTDylibDataFrame)+length, nil, ^{
        CFAllocatorDeallocate(nil, dataFrame);
    });
}



@end
