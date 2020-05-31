//
//  CTProcessor.m
//  CodeTeleport
//
//  Created by zhaolei.lzl on 2018/6/29.
//  Copyright © 2018年 zhaolei.lzl. All rights reserved.
//

#import "CTProcessor.h"
#import "CTUtils.h"
#import "FileWatcher.h"
#import "Xcode.h"
#import "XcodeHash.h"
#import <sys/stat.h>



@interface CTProcessor(){
    FileWatcher *_fileWatcher;
}

@end

@implementation CTProcessor

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.builder = [[CTBuilder alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receiveTriggerInjectNotify)
                                                     name:@"ZLTriggerInject"
                                                   object:nil];
    }
    return self;
}

- (void)processMessage:(NSString *)message
{
    if ([message hasPrefix:@"CLIENTINFO "]) {
        NSString *clientInfo = [message substringFromIndex:@"CLIENTINFO ".length];
        NSArray *clientInfoList = [clientInfo componentsSeparatedByString:@"|"];
        BOOL success = [self setupBuilderProperty:clientInfoList];
        if(success){
            [self startWatcher];
        }
    }
}

- (BOOL)setupBuilderProperty:(NSArray *)clientInfoList
{
    //set config from client
    if([clientInfoList count] >= 3){
        [self.builder setArg:[clientInfoList objectAtIndex:0]
                  toProperty:@"frameworksPath"
                 isDirectory:YES];
        
        self.builder.arch = [clientInfoList objectAtIndex:1];
        
        [self.builder setArg:[clientInfoList objectAtIndex:2]
                  toProperty:@"executablePath"
                 isDirectory:NO];
    }
    
    //set config from process.arguments
    NSArray *args = [[NSProcessInfo processInfo] arguments];
    CTLog(@"processInfo arguments:%@",args);
    if ([args count] >=4) {
        [self.builder setArg:[args objectAtIndex:1]
                  toProperty:@"projectFile"
                 isDirectory:YES];
        
        [self.builder setArg:[args objectAtIndex:2]
                  toProperty:@"xcodeDev"
                 isDirectory:YES];
        
        NSString *buildDir = [args objectAtIndex:3];
        NSString *derivedLogs = [[buildDir stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
        derivedLogs = [derivedLogs stringByAppendingString:@"/Logs/Build"];
        [self.builder setArg:derivedLogs
                  toProperty:@"derivedLogs"
                 isDirectory:YES];
    }
    return [self.builder checkConfigValid];
}

- (void)startWatcher
{
    __weak CTProcessor *weakSelf = self;
    _fileWatcher = [[FileWatcher alloc] initWithRoot:self.builder.projectFile.stringByDeletingLastPathComponent
                                              plugin:^(NSArray *changed) {
                                                  if ([changed count] > 0) {
                                                      [weakSelf.builder addModifyFilePaths:changed];
                                                  }
                                              }];
}

- (void)receiveTriggerInjectNotify
{
    CTLog(@"receiveTriggerInjectNotify");
    
//        [self builder ]
    
}

@end
