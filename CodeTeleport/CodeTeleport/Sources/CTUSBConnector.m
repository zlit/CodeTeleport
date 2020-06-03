//
//  CTUSBConnector.m
//  CodeTeleport
//
//  Created by zhaolei on 2020/5/31.
//  Copyright © 2020 zhaolei.lzl. All rights reserved.
//

#import "CTUSBServer.h"
#import "CTUtils.h"
#import "PTUSBHub.h"
#import "PTChannel.h"
#import "PTProtocol.h"
#import "CTPTChannelPrivate.h"
#import "CTProcessor.h"

static CTUSBServer *connector;

@interface CTUSBServer()<PTChannelDelegate>
{
    NSOperationQueue *_mOperationQueue;
    NSThread *_mThread;
    NSTimer *_mTimer;
    NSNumber *_connectingDeviceID;
    NSNumber *_connectedDeviceID;
    PTChannel *_connectedChannel;
    CTProcessor *_processor;
}

@end

@implementation CTUSBServer

+ (void)load
{
    CTLog(@"CTUSBConnector load");
    connector = [[CTUSBServer alloc] init];
    [connector startListeningDevice];
}

+ (CTUSBServer *)connector
{
    return connector;
}

- (void)startListeningDevice
{
    _mThread = [[NSThread alloc] initWithTarget:self
                                       selector:@selector(runThread)
                                         object:nil];
    [_mThread start];
    
    [self performSelector:@selector(startTimer)
                 onThread:_mThread
               withObject:nil
            waitUntilDone:NO];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:PTUSBDeviceDidAttachNotification
                                                      object:PTUSBHub.sharedHub
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        
        [self performSelector:@selector(deviceDidAttachNotification:)
                     onThread:self->_mThread
                   withObject:note
                waitUntilDone:NO];

    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:PTUSBDeviceDidDetachNotification
                                                      object:PTUSBHub.sharedHub
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        
        [self performSelector:@selector(deviceDidDetachNotification:)
                     onThread:self->_mThread
                   withObject:note
                waitUntilDone:NO];
    }];
    

}

- (void)deviceDidAttachNotification:(NSNotification *) note
{
    NSNumber *deviceID = [note.userInfo objectForKey:@"DeviceID"];

    [self->_connectedChannel close];
    self->_connectedChannel = nil;

    self->_connectingDeviceID = deviceID;

    CTLog(@"PTUSBDeviceDidAttachNotification deviceID : %@",deviceID);
}

- (void)deviceDidDetachNotification:(NSNotification *) note
{
    NSNumber *deviceID = [note.userInfo objectForKey:@"DeviceID"];

    if ([deviceID isEqualToNumber:self->_connectingDeviceID]) {
        self->_connectingDeviceID = nil;
    }

    if ([deviceID isEqualToNumber:self->_connectedDeviceID]) {
        [self->_connectedChannel close];
        self->_connectedChannel = nil;
        self->_connectedDeviceID = nil;
    }

    CTLog(@"PTUSBDeviceDidDetachNotification deviceID : %@",deviceID);
}

- (void)runThread
{
    [[NSThread currentThread] setName:@"USBConnector timer"];
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
    [runLoop run];
}

- (void)startTimer
{
    _mTimer = [NSTimer scheduledTimerWithTimeInterval:5
                                               target:self
                                             selector:@selector(tryToConnectUSBDevice)
                                             userInfo:nil
                                              repeats:YES];
}

- (void)tryToConnectUSBDevice
{

    if (_connectedChannel == nil
        && _connectedDeviceID == nil
        && _connectingDeviceID != nil) {
        
        CTLog(@"tryToConnectUSBDevice : %@",self->_connectingDeviceID);
        
        PTChannel *channel = [PTChannel channelWithDelegate:self];
        [channel connectToPort:19999
                    overUSBHub:PTUSBHub.sharedHub
                      deviceID:_connectingDeviceID
                      callback:^(NSError *error) {
            if (error) {
//                CTLog(@"failed to connect to device : %@, error : %@",channel.userInfo,error);
            } else {
                self->_connectedDeviceID = self->_connectingDeviceID;
                self->_connectedChannel = channel;
                _processor = [self buildNewProcessor];
                [self sendChannelTextMsg:@"HELLO "];
            }
        }];
    }
}

#pragma mark PTChannelDelegate

- (void)ioFrameChannel:(PTChannel *)channel
       didEndWithError:(NSError *)error
{
    [self->_connectedChannel close];
    self->_connectedChannel = nil;
    self->_connectedDeviceID = nil;
}

- (void)ioFrameChannel:(PTChannel *)channel
 didReceiveFrameOfType:(uint32_t)type
                   tag:(uint32_t)tag
               payload:(PTData *)payload
{
    if (type == CTPeerTalkTypeText) {
        NSString *msg = [CTPTChannelPrivate parseTextFrameToNSString:(CTMessageTextFrame *)payload.data];
        CTLog(@"receive text msg : %@", msg);
        [_processor processMessage:msg];
    }
}

- (void)sendChannelTextMsg:(NSString *)msg
{
    if (self->_connectedChannel) {
        dispatch_data_t paylaod = [CTPTChannelPrivate parseNSStringToTextFrameData:msg];
        [self->_connectedChannel sendFrameOfType:CTPeerTalkTypeText
                                             tag:PTFrameNoTag
                                     withPayload:paylaod
                                        callback:^(NSError *error) {
            if (error) {
                CTLog(@"failed to send msg : %@",msg);
            }else{
                CTLog(@"success to send msg : %@",msg);
            }
        }];
    }
}

- (void)sendChannelDylib:(NSData *)data
{
//    if (self->_connectedChannel) {
//        dispatch_data_t paylaod = [CTPTChannelPrivate parseNSStringToTextFrameData:msg];
//        [self->_connectedChannel sendFrameOfType:CTPeerTalkTypeText
//                                             tag:PTFrameNoTag
//                                     withPayload:paylaod
//                                        callback:^(NSError *error) {
//            if (error) {
//                CTLog(@"failed to send msg : %@",msg);
//            }else{
//                CTLog(@"success to send msg : %@",msg);
//            }
//        }];
//    }
}

- (CTProcessor *)buildNewProcessor
{
    CTProcessor *processor = [[CTProcessor alloc] init];
    __weak CTUSBServer *weakSelf = self;
    processor.processResponseBlock = ^(CTProcessor *builder, CTDataType dataType, NSData* data){
        __strong CTUSBServer *strongSelf = weakSelf;
        
        if (dataType == CTDataTypeText) {
            NSString *textMsg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            [strongSelf sendChannelTextMsg:textMsg];
        }else if (dataType == CTDataTypeText) {
            [strongSelf sendChannelDylib:data];
        }
        
    };
    return processor;
}

@end
