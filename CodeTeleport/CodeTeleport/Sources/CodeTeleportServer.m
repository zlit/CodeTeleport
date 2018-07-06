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

#define kListenPort 10000

static GCDAsyncSocket *asyncSocket;
static CodeTeleportServer *server;

@interface CodeTeleportServer()<GCDAsyncSocketDelegate>{
    GCDAsyncSocket *_newSocket;
    CTProcessor *_processor;
}

@end

@implementation CodeTeleportServer

+(void)load{
    CTLog(@"CodeTeleportServer load.");
    [CodeTeleportServer startServer];
}

+ (void)startServer
{
    server = [[CodeTeleportServer alloc] init];
    asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:server delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    [asyncSocket setAutoDisconnectOnClosedReadStream:NO];
    
    NSError *socketError = nil;
    if ([asyncSocket acceptOnPort:kListenPort error:&socketError])
    {
        UInt16 realPort = [asyncSocket localPort];
        CTLog(@"accept on %@:%d", [CTUtils getIPAddress], realPort);
    }

    if (socketError) {
        CTLog(@"start faild: %@", socketError);
    }
}

#pragma mark - AsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sender didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    NSString *remoteHost = [newSocket connectedHost];
    UInt16    remotePort = [newSocket connectedPort];
    CTLog(@"accepted new client %@:%hu", remoteHost, remotePort);
    [self closeCurrentSocket];
    
    _newSocket = newSocket;
    _processor = [self buildNewProcessor];
    
    [_newSocket writeData:[@"HELLO " dataUsingEncoding:NSUTF8StringEncoding]
              withTimeout:-1
                      tag:0];
    [appdelegate() setStatusIcon:StatusIconTypeActive];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    CTLog(@"didWriteDataWithTag:%lu",tag);
    [_newSocket readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sender didReadData:(NSData *)data withTag:(long)tag
{
    NSString *readString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    CTLog(@" didReadData: %@, tag: %lu", readString,tag);
    [_processor processMessage:readString];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    CTLog(@"disconnected: %@, %@", sock, err);
    [appdelegate() setStatusIcon:StatusIconTypeIdle];
    [self closeCurrentSocket];
}

- (void)closeCurrentSocket{
    if(_newSocket){
        if([_newSocket isConnected]){
            CTLog(@"close old client %@:%hu", [_newSocket connectedHost], [_newSocket connectedPort]);
            [_newSocket disconnect];
        }
        _newSocket = nil;
    }
}

- (CTProcessor *)buildNewProcessor
{
    CTProcessor *processor = [[CTProcessor alloc] init];
    __weak CodeTeleportServer *weakSelf = self;
    processor.processResponseBlock = ^(CTProcessor *builder,NSString* msg){
        __strong CodeTeleportServer *strongSelf = weakSelf;
        [strongSelf->_newSocket writeData:[msg dataUsingEncoding:NSUTF8StringEncoding]
                              withTimeout:-1
                                      tag:0];
    };
    return processor;
}

-(void)dealloc{
    CTLog(@"dealloc.");
}

@end
