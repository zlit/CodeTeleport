//
//  CTUtils.m
//  CodeTeleport
//
//  Created by zhaolei.lzl on 2018/6/29.
//  Copyright © 2018年 zhaolei.lzl. All rights reserved.
//

#import "CTUtils.h"
#include <ifaddrs.h>
#include <arpa/inet.h>

@implementation CTUtils

+ (NSString *)getIPAddress {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}

+ (BOOL)executeShellCommand:(NSString *)command
{
    CTLog( @"Running: %@", command);
    NSTask *task = [NSTask new];
    task.launchPath = @"/bin/bash";
    task.arguments = [NSArray arrayWithObjects: @"-c", command, nil];
    [task launch];
    [task waitUntilExit];
    BOOL result = [task terminationStatus] == EXIT_SUCCESS;
    CTLog(@"executeShellCommand result: %d",result);
    return result;
}

+ (NSString *)readLogWithPath:(NSString *)path
{
    NSError *readLogError;
    NSString *logInfo = [NSString stringWithContentsOfFile:path
                                                  encoding:NSUTF8StringEncoding
                                                     error:&readLogError];
    if(logInfo.length == 0){
        logInfo = [NSString stringWithFormat:@"read log failed, %@:",readLogError?:@""];
    }
    return logInfo;
}

@end
