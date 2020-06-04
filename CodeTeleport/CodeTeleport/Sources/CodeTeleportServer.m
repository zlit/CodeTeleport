//
//  CodeTeleportServer.m
//  CodeTeleport
//
//  Created by zhaolei.lzl on 2018/6/29.
//  Copyright © 2018年 zhaolei.lzl. All rights reserved.
//

#import "CodeTeleportServer.h"
#import "CTUtils.h"
#import "GCDAsyncSocket.h"
#import "CTBuilder.h"
#import "CTProcessor.h"
#import "AppDelegate.h"

#define kLocalHost @"127.0.0.1"
#define kServerPort 18888

static CodeTeleportServer *localConnector;

@interface CodeTeleportServer()<GCDAsyncSocketDelegate>{
    GCDAsyncSocket *_asyncSocket;
    CTProcessor *_processor;
    NSThread *_mThread;
    NSTimer *_mTimer;
}

@end

@implementation CodeTeleportServer

+(void)load{
    CTLog(@"CodeTeleportServer load.");
    localConnector = [[CodeTeleportServer alloc] init];
    [localConnector connectToSocketServer];
}

- (void)connectToSocketServer
{
    _mThread = [[NSThread alloc] initWithTarget:self
                                       selector:@selector(runThread)
                                         object:nil];
    [_mThread start];
    
    [self performSelector:@selector(startTimer)
                 onThread:_mThread
               withObject:nil
            waitUntilDone:NO];
}

- (void)runThread
{
    [[NSThread currentThread] setName:@"CodeTeleportServer timer"];
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
    [runLoop run];
}

- (void)startTimer
{
    _mTimer = [NSTimer scheduledTimerWithTimeInterval:5
                                               target:self
                                             selector:@selector(tryToConnectLocalServer)
                                             userInfo:nil
                                              repeats:YES];
}

- (void)tryToConnectLocalServer
{
    if (_asyncSocket == nil) {
        _asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self
                                                        delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
        
        NSError *socketError = nil;
        if ([_asyncSocket connectToHost:kLocalHost
                                 onPort:kServerPort
                                  error:&socketError])
        {
            CTLog(@"connected to server");
        }
        
        if (socketError) {
            CTLog(@"failed to connect to server: %@", socketError);
            _asyncSocket = nil;
        }
    }
}

#pragma mark - AsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    _processor = [self buildNewProcessor];
    CTLog(@"didConnectToHost: %@, port: %d.",host,port);
    
    [_asyncSocket writeData:[@"HELLO " dataUsingEncoding:NSUTF8StringEncoding]
                withTimeout:-1
                        tag:0];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [appdelegate() setStatusIcon:StatusIconTypeActive];
    });
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
    _asyncSocket = nil;
    _processor = nil;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [appdelegate() setStatusIcon:StatusIconTypeIdle];
    });
}

- (CTProcessor *)buildNewProcessor
{
    CTProcessor *processor = [[CTProcessor alloc] init];
    processor.communicationChannel = CTCommunicationChannelLocalHost;
    __weak CodeTeleportServer *weakSelf = self;
    processor.processResponseBlock = ^(CTProcessor *builder, CTDataType dataType, NSData* data){
        __strong CodeTeleportServer *strongSelf = weakSelf;
        [strongSelf->_asyncSocket writeData:data
                                withTimeout:-1
                                        tag:dataType];
    };
    return processor;
}

-(void)dealloc{
    CTLog(@"dealloc.");
}

@end
