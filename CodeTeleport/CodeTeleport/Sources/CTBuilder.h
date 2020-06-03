//
//  CTBuilder.h
//  CodeTeleport
//
//  Created by zhaolei.lzl on 2018/6/29.
//  Copyright © 2018年 zhaolei.lzl. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kTmpPath @"/tmp/com.zhaolei.CodeTeleport"
#define kBuildTaskPathPre @"/tmp/com.zhaolei.CodeTeleport/BuildTask"

@class CTBuilder;

typedef void(^BuildCompletedBlock)(CTBuilder *builder,NSString* dylibPath);
typedef void(^BuildFailedBlock)(CTBuilder *builder,NSString* msg);

@interface CTBuilder : NSObject

@property(nonatomic,copy) NSString* frameworksPath;
@property(nonatomic,copy) NSString* arch;
@property(nonatomic,copy) NSString* projectPath;
@property(nonatomic,copy) NSString* xcodeDev;
@property(nonatomic,copy) NSString* derivedLogs;
@property(nonatomic,copy) NSString* xctoolchain;
@property(nonatomic,copy) NSString* sdkDir;
@property(nonatomic,copy) NSString* targetOSVersion;
@property(nonatomic,copy) NSString* simulatorUDID;
@property(nonatomic,copy) NSString* codeSignIdentity;
@property(nonatomic,copy) NSString* codeSignFolderPath;
@property(nonatomic,copy) NSString* frameworkFloderPath;
@property(nonatomic,copy) NSString* excutablePath;
@property(nonatomic,copy) NSString* productName;

@property(nonatomic,copy) BuildCompletedBlock buildCompletedBlock;
@property(nonatomic,copy) BuildFailedBlock buildFailedBlock;

- (void)setArg:(NSString *)arg
    toProperty:(NSString *)property
   isDirectory:(BOOL)isDirectory;

- (BOOL)checkConfigValid;


- (void)addModifyFilePaths:(NSArray *) filePaths;

- (void)buildModifyFiles;

@end
