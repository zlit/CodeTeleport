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
#import "PTUSBHub.h"
#import "PTChannel.h"
#import "PTProtocol.h"
#import "CTPTChannelPrivate.h"
#import <UIKit/UIKit.h>

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
#define kServerPort 18888

static CodeTeleportClient *server;

@interface CodeTeleportClient()<GCDAsyncSocketDelegate,PTChannelDelegate>{
    CodeTeleportProcessor *_processor;

    PTChannel *_serverChannel;
    PTChannel *_peerChannel;
    
    GCDAsyncSocket *_asyncSocket;
    GCDAsyncSocket *_newSocket;
}

@property(strong,nonatomic) CodeTeleportClient* strongSelf;

@end

@implementation CodeTeleportClient

+(void)load{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)),
                   dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CTLog(@"CodeTeleportClient load. Avoid affecting startup performance,dispatch_after 3s.");
        
        if (TARGET_IPHONE_SIMULATOR) {
            [CodeTeleportClient startListeningNetConnect];
        } else {
            [CodeTeleportClient startListeningUSBConnect];
        }
    });
}

+ (void)startListeningUSBConnect
{
    CodeTeleportClient *strongClient = [[CodeTeleportClient alloc] init];
    strongClient->_serverChannel = [PTChannel channelWithDelegate:strongClient];
    [strongClient->_serverChannel listenOnPort:kUSBListenPort
                                   IPv4Address:INADDR_LOOPBACK
                                      callback:^(NSError *error) {
        if (error) {
            CTLog(@"channel connect failed : %@", error);
        }else{
            CTLog(@"channel connect success");
        }
    }];
}

+ (void)startListeningNetConnect
{
    server = [[CodeTeleportClient alloc] init];
    server->_asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:server
                                                     delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    [server->_asyncSocket setAutoDisconnectOnClosedReadStream:NO];
    
    NSError *socketError = nil;
    if ([server->_asyncSocket acceptOnInterface:kLocalHost
                                           port:kServerPort
                                          error:&socketError]) {
        CTLog(@"accept on %@:%d",kLocalHost, kServerPort);
    }

    if (socketError) {
        CTLog(@"accept faild: %@", socketError);
    }
}

#pragma mark - AsyncSocketDelegate

- (CodeTeleportProcessor *)buildNewProcessorForSocket
{
    CodeTeleportProcessor *processor = [[CodeTeleportProcessor alloc] init];
    processor.processResponseBlock = ^(CodeTeleportProcessor *builder,NSString* msg){
        [self->_newSocket writeData:[msg dataUsingEncoding:NSUTF8StringEncoding]
                        withTimeout:-1
                                tag:0];
    };
    return processor;
}

- (void)socket:(GCDAsyncSocket *)sender didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    NSString *remoteHost = [newSocket connectedHost];
    UInt16    remotePort = [newSocket connectedPort];
    CTLog(@"accepted new client %@:%hu", remoteHost, remotePort);
    [self closeCurrentSocket];
    
    _newSocket = newSocket;
    _processor = [self buildNewProcessorForSocket];
    
    [_newSocket writeData:[@"HELLO " dataUsingEncoding:NSUTF8StringEncoding]
              withTimeout:-1
                      tag:0];
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
    [self closeCurrentSocket];
}

- (void)closeCurrentSocket{
    if (_newSocket) {
        CTLog(@"close old client %@:%hu", [_newSocket connectedHost], [_newSocket connectedPort]);
        [_newSocket disconnect];
        _newSocket = nil;
    }
}

#pragma mark - PTChannelDelegate

- (CodeTeleportProcessor *)buildNewProcessorForUSB
{
    CodeTeleportProcessor *processor = [[CodeTeleportProcessor alloc] init];
    processor.processResponseBlock = ^(CodeTeleportProcessor *builder,NSString* msg){
        [self sendChannelTextMsg:msg];
    };
    return processor;
}

- (void)sendChannelTextMsg:(NSString *)msg
{
    if (self->_peerChannel) {
        dispatch_data_t paylaod = [CTPTChannelPrivate parseNSStringToTextFrameData:msg];
        [self->_peerChannel sendFrameOfType:CTDataTypeText
                                        tag:PTFrameNoTag
                                withPayload:paylaod
                                   callback:^(NSError *error) {
            if (error) {
                CTLog(@"failed to send msg : %@",msg);
            }
        }];
    }
}

- (void)ioFrameChannel:(PTChannel *)channel
   didAcceptConnection:(PTChannel *)otherChannel
           fromAddress:(PTAddress *)address
{
    if (self->_peerChannel) {
        [self->_peerChannel cancel];
        self->_peerChannel = nil;
    }
    self->_peerChannel = otherChannel;
    self->_peerChannel.userInfo = address;
    CTLog(@"didAcceptUSBConnection : %@", address);
    _processor = [self buildNewProcessorForUSB];
    
    NSString *helloMsg = [NSString stringWithFormat:@"HELLO#This message is from device:[%@ %@ %@]"
                          ,[UIDevice currentDevice].name
                          ,[UIDevice currentDevice].model
                          ,[UIDevice currentDevice].systemVersion];
    
    [self sendChannelTextMsg:helloMsg];
}

- (void)ioFrameChannel:(PTChannel *)channel
       didEndWithError:(NSError *)error
{
    CTLog(@"channel didEndWithError : %@", error);
}

- (void)ioFrameChannel:(PTChannel *)channel
 didReceiveFrameOfType:(uint32_t)type
                   tag:(uint32_t)tag
               payload:(PTData *)payload
{
    if (type == CTDataTypeText) {
        NSString *msg = [CTPTChannelPrivate parseTextFrameToNSString:(CTMessageTextFrame *)payload.data];
        CTLog(@"receive text msg : %@", msg);
        [_processor processMessage:msg];
    } else if (type == CTDataTypeDylib) {
        CTDylibDataFrame *dylibFrame = (CTDylibDataFrame*)payload.data;
        dylibFrame->length = ntohl(dylibFrame->length);

        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];

        NSString *dylibTempPath = [documentsDirectory stringByAppendingString:@"/CodeTeleport"];
        // 清理之前的缓存
        [[NSFileManager defaultManager] removeItemAtPath:dylibTempPath error:nil];
        [[NSFileManager defaultManager] createDirectoryAtPath:dylibTempPath withIntermediateDirectories:YES attributes:nil error:nil];

        dylibTempPath = [dylibTempPath stringByAppendingFormat:@"/%.0f.dylib", [[NSDate date] timeIntervalSince1970]];
        NSData *dylibData = [NSData dataWithBytes:dylibFrame->data
                                           length:dylibFrame->length];
        [dylibData writeToFile:dylibTempPath
                    atomically:YES];
        
        NSString *loadDylibMsg = [NSString stringWithFormat:@"TELEPORT %@",dylibTempPath];
        [_processor processMessage:loadDylibMsg];
    }
}

-(void)dealloc{
    CTLog(@"dealloc.");
}
@end
