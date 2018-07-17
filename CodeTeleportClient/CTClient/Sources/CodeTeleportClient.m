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

// weak define GCDAsyncSocket

//class
asm(".weak_definition _OBJC_CLASS_$_GCDAsyncSocketPreBuffer");
asm(".weak_definition _OBJC_METACLASS_$_GCDAsyncSocketPreBuffer");
asm(".weak_definition _OBJC_CLASS_$_GCDAsyncSpecialPacket");
asm(".weak_definition _OBJC_METACLASS_$_GCDAsyncSpecialPacket");
asm(".weak_definition _OBJC_CLASS_$_GCDAsyncWritePacket");
asm(".weak_definition _OBJC_METACLASS_$_GCDAsyncWritePacket");
asm(".weak_definition _OBJC_CLASS_$_GCDAsyncReadPacket");
asm(".weak_definition _OBJC_METACLASS_$_GCDAsyncReadPacket");

//global symbol
asm(".weak_definition _GCDAsyncSocketErrorDomain");
asm(".weak_definition _GCDAsyncSocketException");
asm(".weak_definition _GCDAsyncSocketQueueName");
asm(".weak_definition _GCDAsyncSocketSSLCipherSuites");
asm(".weak_definition _GCDAsyncSocketSSLProtocolVersionMax");
asm(".weak_definition _GCDAsyncSocketSSLProtocolVersionMin");
asm(".weak_definition _GCDAsyncSocketThreadName");

//var symbol
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncReadPacket.buffer");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncReadPacket.bufferOwner");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncReadPacket.bytesDone");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncReadPacket.maxLength");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncReadPacket.originalBufferLength");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncReadPacket.readLength");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncReadPacket.startOffset");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncReadPacket.tag");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncReadPacket.term");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncReadPacket.timeout");

asm(".weak_definition _OBJC_IVAR_$_GCDAsyncSocketPreBuffer.preBuffer");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncSocketPreBuffer.preBufferSize");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncSocketPreBuffer.readPointer");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncSocketPreBuffer.writePointer");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncSpecialPacket.tlsSettings");

asm(".weak_definition _OBJC_IVAR_$_GCDAsyncWritePacket.buffer");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncWritePacket.bytesDone");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncWritePacket.tag");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncWritePacket.timeout");

asm(".weak_definition _OBJC_CLASS_$_GCDAsyncSocket");
asm(".weak_definition _OBJC_METACLASS_$_GCDAsyncSocket");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncSocket.streamContext");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncSocket.flags");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncSocket.connectTimer");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncSocket.writeTimer");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncSocket.readTimer");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncSocket.writeStream");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncSocket.readStream");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncSocket.config");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncSocket.socketQueue ");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncSocket.writeQueue");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncSocket.delegateQueue");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncSocket.readQueue");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncSocket.currentWrite");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncSocket.delegate");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncSocket.socketFDBytesAvailable");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncSocket.writeSource");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncSocket.accept6Source");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncSocket.accept4Source");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncSocket.currentRead");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncSocket.userData");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncSocket.socket6FD");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncSocket.socket4FD");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncSocket.connectInterface6");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncSocket.connectInterface4");
asm(".weak_definition _OBJC_IVAR_$_GCDAsyncSocket.readSource");

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
