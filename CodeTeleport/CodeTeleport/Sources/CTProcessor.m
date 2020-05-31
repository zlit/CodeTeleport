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
        
        __weak CTProcessor *weakSelf = self;
        
        self.builder.buildCompletedBlock = ^(CTBuilder *builder, NSString *msg){
            [weakSelf writeResponse:@"TELEPORT " msg:msg];
        };
        
        self.builder.buildFailedBlock = ^(CTBuilder *builder, NSString *msg) {
            [appdelegate() showCompeledNotice:@"Error: please see the Xcode output log for detail."];
            [weakSelf writeResponse:@"ERROR " msg:msg];
        };
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receiveTriggerTeleportNotify)
                                                     name:@"ZLTriggerTeleport"
                                                   object:nil];
    }
    return self;
}

- (void)processMessage:(NSString *)message
{
    if ([message hasPrefix:@"CLIENTINFO "]) {
        NSString *clientInfo = [message substringFromIndex:@"CLIENTINFO ".length];
        NSArray *clientInfoList = [clientInfo componentsSeparatedByString:@"#"];

        BOOL success = [self setupBuilderProperty:clientInfoList];
        if(success){
            [self startWatcher];
        }
    }else if ([message hasPrefix:@"COMPLETE "]) {
        if(appdelegate().urlScheme.length > 0){
            NSString *udid = @"booted";
            if(self.builder.simulatorUDID.length > 0){
                udid = self.builder.simulatorUDID;
            }
            [CTUtils executeShellCommand:[NSString stringWithFormat:@"xcrun simctl openurl \'%@\' %@",udid,appdelegate().urlScheme]];
        }
        NSString *teleportClass = [message substringFromIndex:@"COMPLETE ".length];
        teleportClass = [teleportClass stringByReplacingOccurrencesOfString:@"|" withString:@"\n"];

        [appdelegate() showCompeledNotice:teleportClass];
        CTLog(@"client load dylib complete.");
    }else if ([message hasPrefix:@"FAILED "]) {
        NSString *errorInfo = [message substringFromIndex:@"FAILED ".length];
        CTLog(@"%@",errorInfo);
        [appdelegate() showCompeledNotice:errorInfo];
    }
}

- (BOOL)setupBuilderProperty:(NSArray *)clientInfoList
{
    if([clientInfoList count] >= 2){
        [self.builder setArg:[clientInfoList objectAtIndex:0]
                  toProperty:@"frameworksPath"
                 isDirectory:NO];
    }

    //set config from client
    NSError *readConfigsError;
    NSString *buildEnviromentConfigs = [NSString stringWithContentsOfFile:[kTmpPath stringByAppendingString:@"/build_enviroment.configs"]
                                                                 encoding:NSUTF8StringEncoding
                                                                    error:&readConfigsError];
    NSArray *args = [buildEnviromentConfigs componentsSeparatedByString:@"#"];
    CTLog(@"buildEnviromentConfigs:%@",args);
    
    if([args count] >=8){
        NSInteger argIndex = 0;

        NSString *customProjectPath = @"";
        if(appdelegate().monitorFilePath.length > 0){
            BOOL isDirectory = NO;
            BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:appdelegate().monitorFilePath
                                                                   isDirectory:&isDirectory];
            if(fileExists
               && isDirectory){
                customProjectPath = appdelegate().monitorFilePath;
            }
        }
        ///Users/zhaolei/Documents/demo/CodeTeleport_new/CodeTeleportClient
        if(customProjectPath.length > 0){
            [self.builder setArg:customProjectPath
                      toProperty:@"projectPath"
                     isDirectory:YES];
        }else{
            [self.builder setArg:[args objectAtIndex:argIndex]
                      toProperty:@"projectPath"
                     isDirectory:YES];
        }
        
        [self.builder setArg:[args objectAtIndex:++argIndex]
                  toProperty:@"xcodeDev"
                 isDirectory:YES];
        
        NSString *buildDir = [args objectAtIndex:++argIndex];
        NSString *derivedLogs = [[buildDir stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
        derivedLogs = [derivedLogs stringByAppendingString:@"/Logs/Build"];
        [self.builder setArg:derivedLogs
                  toProperty:@"derivedLogs"
                 isDirectory:YES];
        
        [self.builder setArg:[args objectAtIndex:++argIndex]
                  toProperty:@"xctoolchain"
                 isDirectory:YES];
        
        [self.builder setArg:[args objectAtIndex:++argIndex]
                  toProperty:@"sdkDir"
                 isDirectory:YES];
        
        [self.builder setArg:[args objectAtIndex:++argIndex]
                  toProperty:@"targetOSVersion"
                 isDirectory:NO];
        [self.builder setArg:[args objectAtIndex:++argIndex]
                  toProperty:@"arch"
                 isDirectory:NO];
        [self.builder setArg:[args objectAtIndex:++argIndex]
                  toProperty:@"simulatorUDID"
                 isDirectory:NO];
    }
    return [self.builder checkConfigValid];
}

- (void)startWatcher
{
    __weak CTProcessor *weakSelf = self;
    CTLog(@"start Watching : %@",self.builder.projectPath)
    _fileWatcher = [[FileWatcher alloc] initWithRoot:self.builder.projectPath
                                              plugin:^(NSArray *changed) {
                                                  if ([changed count] > 0) {
                                                      [weakSelf.builder addModifyFilePaths:changed];
                                                  }
                                              }];
}

- (void)receiveTriggerTeleportNotify
{
    CTLog(@"receiveTriggerTeleportNotify");
    [self.builder buildModifyFiles];
}

- (void)writeResponse:(NSString *)header
                  msg:(NSString *)msg
{
    if(self.processResponseBlock){
        NSString *errorMsg = [NSString stringWithFormat:@"%@%@",header,msg];
        self.processResponseBlock(self,errorMsg);
    }
}

@end
