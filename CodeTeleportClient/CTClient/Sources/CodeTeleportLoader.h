//
//  CodeTeleportLoader.h
//  CTClient
//
//  Created by zhaolei.lzl on 2018/7/3.
//  Copyright © 2018年 zhaolei.lzl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CodeTeleportLoader : NSObject

+ (void)loadDylibWithPath:(NSString *) path
               classNames:(NSArray *) classNames
                    error:(NSError **) error
    replaceOldClassMethod:(BOOL) replaceOldClassMethod
         replaceBlackList:(NSArray *) replaceBlackList;

+ (void)loadDylibWithPath:(NSString *) path
               classNames:(NSArray *) classNames
                    error:(NSError **) error;

@end
