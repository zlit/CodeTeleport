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

- (instancetype)init
{
    self = [super init];
    if (self) { 
        
    }
    return self;
}

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
        NSArray *classNames = [[dylibInfoArray objectAtIndex:1] componentsSeparatedByString:@"|"];
        
        if(dylibPath.length > 0
           && [classNames count] > 0){
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *error;

                [CodeTeleportLoader loadDylibWithPath:dylibPath
                                           classNames:classNames
                                                error:&error];
                
                if(error == nil){
                    [[NSNotificationCenter defaultCenter] postNotificationName:kCodeTeleportCompletedNotification
                                                                        object:nil];
                    [self writeResponse:@"COMPLETE " msg:[classNames componentsJoinedByString:@"|"]];  
                }else{
                    CTLog(@"load Dylib failed : %@",error);
                    [self writeResponse:@"FAILED " msg:[error description]];
                }
            });
        }else{
            [self writeResponse:@"FAILED " msg:[NSString stringWithFormat:@"dylibInfo invalid"]];
        }
        
    }else if([message hasPrefix:@"ERROR "]){
        NSString *errorInfo = [message substringFromIndex:@"ERROR ".length];
        CTLog(@"ServerError:%@",errorInfo);
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
