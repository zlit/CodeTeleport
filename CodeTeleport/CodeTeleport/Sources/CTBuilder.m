//
//  CTBuilder.m
//  CodeTeleport
//
//  Created by zhaolei.lzl on 2018/6/29.
//  Copyright © 2018年 zhaolei.lzl. All rights reserved.
//

#import "CTBuilder.h"
#import "CTUtils.h"

static int kThreadIndex = 1;

#define kTemplateKey @"-_-_-_template_-_-_-"

/**
 builder的很多属性可以通过奇技淫巧来获取.
 比如:
 1. repo有多个相同项目时,Derived路径是以执行项目的".xcworkspace"路径,进行28位MD5生成的.[XcodeHash hashStringForPath:projectFile]
 2. projectFile可以根据获取当前运行的Xcode对象属性来过滤
 
 这里采用buildTime时期,获得环境参数,以.app入参形式传入.
 代码更干净
 */
@interface CTBuilder(){
    dispatch_queue_t _teleportQueue;
    NSString * _compileCommandPath;
    NSString * _compileLogPath;
    NSString * _compileExecutablePath;
    NSString * _dylibPath;
    NSString * _linkLogPath;
}

@property(nonatomic,strong) NSMutableArray *waitingForTeleport;
@property(nonatomic,copy) NSString *scriptPath;
@property(nonatomic,copy) NSString *buildTaskPath;
@property(nonatomic,copy) NSString *timestamp;
@property(nonatomic,strong) NSMutableDictionary *compileCommandCache;
@property(nonatomic,strong) NSMutableDictionary *compileCommandTemplateCache;
@end

@implementation CTBuilder

- (void)dealloc
{
    [self saveCompileCommandCache];
}

- (NSString *)commandTemplateKey
{
    NSString *commandTemplateKey = [NSString stringWithFormat:@"%@_%@_commandTemplateKey",self.arch,self.projectPath];
    return commandTemplateKey;
}

- (NSString *)compileCommandCacheKey
{
    NSString *compileCommandCacheKey = [NSString stringWithFormat:@"%@_%@_compileCommandCacheKey",self.arch,self.projectPath];
    return compileCommandCacheKey;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.waitingForTeleport = [[NSMutableArray alloc] init];
        self.scriptPath = [[NSBundle mainBundle] pathForResource:@"find_compile_command"
                                                          ofType:@"py"];
        const char *label = [[NSString stringWithFormat:@"TeleportQueue_%d",kThreadIndex] cStringUsingEncoding:NSUTF8StringEncoding];
        _teleportQueue = dispatch_queue_create(label, DISPATCH_QUEUE_SERIAL);
        self.compileCommandCache = [[NSMutableDictionary alloc] init];
        self.compileCommandTemplateCache = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)saveCompileCommandCache
{
//    if ([[self.compileCommandTemplateCache allKeys] count] > 0) {
//        [[NSUserDefaults standardUserDefaults] setObject:self.compileCommandTemplateCache
//                                                  forKey:[self commandTemplateKey]];
//    }
//
//    if ([[self.compileCommandCache allKeys] count] > 0) {
//        [[NSUserDefaults standardUserDefaults] setObject:self.compileCommandCache
//                                                  forKey:[self compileCommandCacheKey]];
//    }
}

- (void)setArg:(NSString *)arg
    toProperty:(NSString *)property
   isDirectory:(BOOL)isDirectory
{
    if(isDirectory){
        BOOL checkIsDirectory;
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:arg
                                                               isDirectory:&checkIsDirectory];
        if(!fileExists
           || isDirectory != checkIsDirectory){
            CTLogAssertNO(@"set %@ to %@,file is not Exists or is not a isDirectory.",arg,property);
            return;
        }
    }
    [self setValue:arg forKey:property];
    CTLog(@"set %@ to %@",[self valueForKey:property],property);
}

- (void)setEviromentArgsComplete
{
    //load compileCommandTemplate and compileCommandCache
//    NSDictionary *loacTemplateDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:[self commandTemplateKey]];
//    if (loacTemplateDict != nil
//        && [[loacTemplateDict allKeys] count] > 0) {
//        [self.compileCommandTemplateCache addEntriesFromDictionary:loacTemplateDict];
//    }
//    
//    NSDictionary *loacCommandCacheDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:[self compileCommandCacheKey]];
//    if (loacCommandCacheDict != nil
//        && [[loacCommandCacheDict allKeys] count] > 0) {
//        [self.compileCommandCache addEntriesFromDictionary:loacCommandCacheDict];
//    }
}

- (BOOL)checkConfigValid
{
    return YES;
}

- (void)addModifyFilePaths:(NSArray *) filePaths
{
    __weak CTBuilder *weakSelf = self;
    dispatch_async(_teleportQueue, ^{
        for (NSString *filePath in filePaths) {
            if (![weakSelf.waitingForTeleport containsObject:filePath]) {
                [weakSelf.waitingForTeleport addObject:filePath];
            }
        }
    });
}

- (void)buildModifyFiles
{
    __weak CTBuilder *weakSelf = self;
    dispatch_async(_teleportQueue, ^{
        if ([weakSelf.waitingForTeleport count] == 0) {
            CTLog(@"no file waiting for Teleport.");
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [appdelegate() showCompeledNotice:@"no file waiting for Teleport."];
            });
            
            return;
        }
        
        weakSelf.timestamp = [NSString stringWithFormat:@"%.0f",[NSDate timeIntervalSinceReferenceDate]];
        weakSelf.buildTaskPath = [NSString stringWithFormat:@"%@_%@/",kBuildTaskPathPre,weakSelf.timestamp];
        
        if([[NSFileManager defaultManager] fileExistsAtPath:weakSelf.buildTaskPath] == NO){
            NSError *error;
            [[NSFileManager defaultManager] createDirectoryAtPath:weakSelf.buildTaskPath
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:&error];
            if(error){
                CTLog(@"create %@ failed,error:%@.",weakSelf.buildTaskPath,error);
            }
        }
        
        CTLog(@"start buildModifyFiles,path :%@",weakSelf.buildTaskPath);
        CTLog(@"_waitingForTeleport : %@",weakSelf.waitingForTeleport);
        [weakSelf compileModifyFiles];
    });
}

- (void)compileModifyFiles
{
    NSMutableArray *compileFileList = [[NSMutableArray alloc] init];
    NSMutableArray *compileFileNameList = [[NSMutableArray alloc] init];
    
    for (NSString *modifyFile in self.waitingForTeleport) {
        CTLog(@"begin compile %@",modifyFile);
        
        NSString *fileName = [[[modifyFile lastPathComponent] componentsSeparatedByString:@".m"] firstObject];
        [compileFileNameList addObject:fileName];
        _compileCommandPath =  [self.buildTaskPath stringByAppendingFormat:@"%@.compile",fileName];
        _compileLogPath = [self.buildTaskPath stringByAppendingFormat:@"%@.log",fileName];
        _compileExecutablePath = [self.buildTaskPath stringByAppendingFormat:@"%@.o",fileName];
        
        //1. compileCommand from cache
        NSString * compileCommand = [self.compileCommandCache objectForKey:modifyFile];
        
        if(compileCommand.length == 0){
            NSError *error;
            //2. compileCommand from compileLog
            compileCommand = [self findCompileCommand:modifyFile
                                                error:&error];
            
            //3. compileCommand from commandTemplate, file's configuration is difference , maybe some mistake.
            if (compileCommand.length == 0
                && [[self.compileCommandTemplateCache allKeys] count] > 0) {
                
                NSString *compileCommandTemplate = [self.compileCommandTemplateCache objectForKey:self.arch];
                if (compileCommandTemplate.length > 0) {
                    compileCommand = [compileCommandTemplate stringByReplacingOccurrencesOfString:kTemplateKey
                                                                                       withString:modifyFile];
                }
            }
            
            if(compileCommand.length == 0
               && error != nil){
                if(self.buildFailedBlock){
                    self.buildFailedBlock(self,[error description]);
                }
                return;
            }
        }
        
        NSString *executeCommand = [NSString stringWithFormat:@"time(%@ -o %@ > %@  2>&1)",compileCommand,_compileExecutablePath,_compileLogPath];
        
        BOOL result = [CTUtils executeShellCommand:executeCommand];
        if(result){
            //if compileCommand work, create a template
            NSString *compileCommandTemplate = [compileCommand stringByReplacingOccurrencesOfString:modifyFile
                                                                                         withString:kTemplateKey];
            [self.compileCommandTemplateCache setObject:compileCommandTemplate
                                                 forKey:self.arch];
            
            //if compileCommand work, save to cache
            [self.compileCommandCache setObject:compileCommand
                                         forKey:modifyFile];
            
            [compileFileList addObject:_compileExecutablePath];
        }else{
            [self.compileCommandCache removeObjectForKey:modifyFile];
            NSString *errorMsg = [@"compile fialed. for details : " stringByAppendingString:_compileLogPath];
            if(self.buildFailedBlock){
                self.buildFailedBlock(self,errorMsg);
            }
            return;
        }
    }
    
    _dylibPath = [self.buildTaskPath stringByAppendingFormat:@"codeTeleport_%@.dylib",_timestamp];
    _linkLogPath = [self.buildTaskPath stringByAppendingString:@"linkLog.txt"];
    CTLog(@"begin link:%@",compileFileList);
    
    BOOL result = [CTUtils executeShellCommand:[self archDylibCommand:compileFileList]];
    if(result == NO){
        NSString *errorMsg = [@"link fialed. \n " stringByAppendingString:[CTUtils readLogWithPath:_linkLogPath]];
        if(self.buildFailedBlock){
            self.buildFailedBlock(self,errorMsg);
        }
        return;
    }
    
    result = [CTUtils executeShellCommand:[self codeSignCommandWithDylibPath:_dylibPath]];
    if(result == NO){
        NSString *errorMsg = [@"code sign fialed. \n " stringByAppendingString:[CTUtils readLogWithPath:_linkLogPath]];
        if(self.buildFailedBlock){
            self.buildFailedBlock(self,errorMsg);
        }
        return;
    }
    
    if(self.buildCompletedBlock){
        [self saveCompileCommandCache];
        self.buildCompletedBlock(self,_dylibPath);
        [self.waitingForTeleport removeAllObjects];
        CTLog(@"buildCompleted,clean waitingForTeleport files");
    }
}

- (NSString *)findCompileCommand:(NSString *)modifyFile
                           error:(NSError **)error
{
    NSString *compileCommand = @"";
   
    BOOL result = [CTUtils executeShellCommand:[self runScriptCommand:modifyFile]];
    
    if(result){
        compileCommand = [NSString stringWithContentsOfFile:_compileCommandPath
                                                   encoding:NSUTF8StringEncoding
                                                      error:error];
        if(compileCommand.length == 0
           || *error != nil){
            NSString *errorMsg = [NSString stringWithFormat:@"read compileCommand fialed.readContent is %@,error:%@.",compileCommand,*error];
            *error = CTError(errorMsg);
        }
    }else{
        NSString *errorMsg = [@"findCompileCommand fialed. \n " stringByAppendingString:[CTUtils readLogWithPath:_compileLogPath]];
        *error = CTError(errorMsg);
    }
    
    return compileCommand;
}

- (NSString *)runScriptCommand:(NSString *)modifyFile
{
    return [NSString stringWithFormat:@"time(python %@ %@ \"%@\" %@ %@ %@)",self.scriptPath,self.derivedLogs,modifyFile,self.projectPath,_compileCommandPath,_arch];
}

- (NSString *)archDylibCommand:(NSMutableArray *) compileFileList
{
    return [NSString stringWithFormat:@"time(\
            %@/usr/bin/clang -arch %@\
            -dynamiclib\
            -ObjC\
            -isysroot\
            %@\
            -undefined\
            dynamic_lookup\
            -dead_strip \
            -Xlinker -objc_abi_version -Xlinker 2 \
            -fobjc-arc \
            %@ \
            -L \"%@\"\
            -F \"%@\"\
            -rpath \"%@\"\
            -o %@\
            > %@  2>&1)",self.xctoolchain,self.arch,self.sdkDir,[compileFileList componentsJoinedByString:@" "],self.frameworksPath,self.frameworksPath,self.frameworksPath,_dylibPath,_linkLogPath];
}

- (NSString *)codeSignCommandWithDylibPath:(NSString *) dylibPath
{
    NSString *command = [NSString stringWithFormat:@"\
                         export CODESIGN_ALLOCATE=%@/Toolchains/XcodeDefault.xctoolchain/usr/bin/codesign_allocate; \
                         export PATH=\"%@/Platforms/iPhoneOS.platform/Developer/usr/bin:%@/usr/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin\"; \
                         /usr/bin/codesign --verbose --force --sign %@ %@",self.xcodeDev,self.xcodeDev,self.xcodeDev,self.codeSignIdentity,dylibPath];
    return command;
}

@end
