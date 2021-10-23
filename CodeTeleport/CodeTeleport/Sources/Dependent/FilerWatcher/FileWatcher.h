//
//  FileWatcher.h
//  
//
//  Created by John Holdsworth on 08/03/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//

#import <Foundation/Foundation.h>

//#define INJECTABLE_PATTERN @"[^~]\\.(mm?|swift|strings)$"
#define INJECTABLE_PATTERN @"[^~]\\.(mm?)$"
typedef void (^TeleportCallback)(NSArray *filesChanged);

@interface FileWatcher : NSObject

@property(copy) TeleportCallback callback;

- (instancetype)initWithRoot:(NSString *)projectRoot
                      plugin:(TeleportCallback)callback;

- (instancetype)initWithRoots:(NSArray *)projectRoots
                       plugin:(TeleportCallback)callback;

@end
