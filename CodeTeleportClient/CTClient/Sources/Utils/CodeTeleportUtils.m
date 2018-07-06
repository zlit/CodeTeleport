//
//  CTUtils.m
//  CodeTeleport
//
//  Created by zhaolei.lzl on 2018/6/29.
//  Copyright © 2018年 zhaolei.lzl. All rights reserved.
//

#import "CodeTeleportUtils.h"

@implementation CodeTeleportUtils

+ (NSString *)getSeparatedFromStr:(NSString *) str
                         bySymbol:(NSString *) symbol
                            index:(NSUInteger) index
{
    NSArray *seproArray = [str componentsSeparatedByString:symbol];
    if([seproArray count] > 1
       && [seproArray count] > index){
        return [seproArray objectAtIndex:index];
    }
    return  @"";
}

@end
