//
//  CodeTeleportClient.m
//  CodeTeleport
//
//  Created by zhaolei.lzl on 2018/6/29.
//  Copyright © 2018年 zhaolei.lzl. All rights reserved.
//

#import "CodeTeleportClient.h"
#import "CodeTeleportUtils.h"
#import "GCDAsyncSocket.h"
#import "CodeTeleportProcessor.h"

#define kLocalHost @"127.0.0.1"
#define kServerPort 10000

static GCDAsyncSocket *_asyncSocket;

@interface CodeTeleportClient()<GCDAsyncSocketDelegate>{
    CodeTeleportProcessor *_processor;
}

@property(strong,nonatomic) CodeTeleportClient* strongSelf;

@end

@implementation CodeTeleportClient

+(void)load{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CTLog(@"CodeTeleportClient load. Avoid affecting startup performance,dispatch_after 5s.");
        [CodeTeleportClient connectToServer];
    });
}

+ (void)connectToServer
{
    _asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:[[CodeTeleportClient alloc] init] delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    
    NSError *socketError = nil;
    if ([_asyncSocket connectToHost:kLocalHost onPort:kServerPort error:&socketError])
    {
        CTLog(@"connected to server");
    }
    
    if (socketError) {
        CTLog(@"failed to connect to server: %@", socketError);
    }
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.strongSelf = self;
    }
    return self;
}

#pragma mark - AsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    _processor = [self buildNewProcessor];
    CTLog(@"didConnectToHost: %@, port: %d.",host,port);
    [_asyncSocket readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    CTLog(@"didWriteDataWithTag:%lu",tag);
    [_asyncSocket readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sender didReadData:(NSData *)data withTag:(long)tag
{
    NSString *readString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    CTLog(@"didReadData: %@", readString);
    [_processor processMessage:readString];
    [_asyncSocket readDataWithTimeout:-1 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    CTLog(@"disconnected: %@, %@", sock, err);
    self.strongSelf = nil;
}

- (CodeTeleportProcessor *)buildNewProcessor
{
    CodeTeleportProcessor *processor = [[CodeTeleportProcessor alloc] init];
    processor.processResponseBlock = ^(CodeTeleportProcessor *builder,NSString* msg){
        [_asyncSocket writeData:[msg dataUsingEncoding:NSUTF8StringEncoding]
                    withTimeout:-1
                            tag:0];
    };
    return processor;
}

-(void)dealloc{
    CTLog(@"dealloc.");
}
@end
