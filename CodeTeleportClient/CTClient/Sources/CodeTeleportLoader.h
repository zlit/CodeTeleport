//
//  CodeTeleportLoader.h
//  CTClient
//
//  Created by zhaolei.lzl on 2018/7/3.
//  Copyright © 2018年 zhaolei.lzl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CodeTeleportLoader : NSObject

//https://www.cnblogs.com/oc-bowen/p/6000139.html
//read className from image
+ (void)loadDylibWithPath:(NSString *) path
               classNames:(NSArray *) classNames
                    error:(NSError **) error;

+ (NSArray *)loadDylibWithPath:(NSString *) path
                         error:(NSError **) error;

@end
