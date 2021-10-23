//
//  CTProcessor.m
//  CodeTeleport
//
//  Created by zhaolei.lzl on 2018/6/29.
//  Copyright © 2018年 zhaolei.lzl. All rights reserved.
//

#import "CodeTeleportProcessor.h"
#import "CodeTeleportUtils.h"
#import "CodeTeleportLoader.h"

@interface CodeTeleportProcessor(){
}

@end

@implementation CodeTeleportProcessor

- (void)processMessage:(NSString *)message
{
    if ([message hasPrefix:@"HELLO "]) {
        
        NSMutableString *stringBuilder = [[NSMutableString alloc] init];
        [stringBuilder appendString:[NSBundle mainBundle].privateFrameworksPath];
        [stringBuilder appendString:@"#"];
        [stringBuilder appendString:[NSBundle mainBundle].executablePath];
        [self writeResponse:@"CLIENTINFO " msg:stringBuilder];
    }else if ([message hasPrefix:@"TELEPORT "]) {
        NSString *dylibInfo = [message substringFromIndex:@"TELEPORT ".length];
        NSArray *dylibInfoArray = [dylibInfo componentsSeparatedByString:@"#"];
        NSString *dylibPath = [dylibInfoArray firstObject];
        
        if (dylibPath.length > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *error;
                // dispatch to main thread, because maybe class +load +initialize require;
                NSArray *classNames = [CodeTeleportLoader loadDylibWithPath:dylibPath
                                                                      error:&error];
                if(error == nil){
                    [[NSNotificationCenter defaultCenter] postNotificationName:kCodeTeleportCompletedNotification
                                                                        object:nil];
                    [self writeResponse:@"COMPLETE " msg:[classNames componentsJoinedByString:@"|"]];  
                }else{
                    CTLog(@"load Dylib failed : %@",error);
                    [self writeResponse:@"FAILED " msg:[error localizedDescription]];
                }
            });
        } else {
            [self writeResponse:@"FAILED " msg:[NSString stringWithFormat:@"dylibInfo invalid"]];
        }
        
    }else if([message hasPrefix:@"ERROR "]){
        NSString *errorInfo = [message substringFromIndex:@"ERROR ".length];
        CTLog(@"ServerError:%@",errorInfo);
        [self writeResponse:@"FAILED " msg:errorInfo?:@"Get Error."];
    }
    
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
