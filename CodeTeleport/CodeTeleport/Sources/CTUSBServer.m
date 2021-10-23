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
    [connector startListeningUSBDevice];
}

+ (CTUSBServer *)connector
{
    return connector;
}

- (void)startListeningUSBDevice
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

    if (self->_connectingDeviceID &&
        [deviceID isEqualToNumber:self->_connectingDeviceID]) {
        self->_connectingDeviceID = nil;
    }

    if (self->_connectedDeviceID &&
        [deviceID isEqualToNumber:self->_connectedDeviceID]) {
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
        
//        CTLog(@"tryToConnectUSBDevice : %@",self->_connectingDeviceID);
        
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
                self->_processor = [self buildNewProcessor];
                [self sendChannelTextMsg:@"HELLO "];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [appdelegate() setStatusIcon:StatusIconTypeActive formServer:kFormUSB];
                });
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
    
    self->_processor = nil;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [appdelegate() setStatusIcon:StatusIconTypeIdle formServer:kFormUSB];
    });
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
    }
}

- (void)sendChannelTextMsg:(NSString *)msg
{
    if (self->_connectedChannel) {
        dispatch_data_t paylaod = [CTPTChannelPrivate parseNSStringToTextFrameData:msg];
        [self->_connectedChannel sendFrameOfType:CTDataTypeText
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
    if (self->_connectedChannel) {
        dispatch_data_t paylaod = [CTPTChannelPrivate parseNSStringToDylibFrameData:data];
        [self->_connectedChannel sendFrameOfType:CTDataTypeDylib
                                             tag:PTFrameNoTag
                                     withPayload:paylaod
                                        callback:^(NSError *error) {
            if (error) {
                CTLog(@"failed to send data length : %lu",(unsigned long)[data length]);
            }else{
                CTLog(@"success to send data length : %lu",(unsigned long)[data length]);
            }
        }];
    }
}

- (CTProcessor *)buildNewProcessor
{
    CTProcessor *processor = [[CTProcessor alloc] init];
    processor.communicationChannel = CTCommunicationChannelUSB;
    __weak CTUSBServer *weakSelf = self;
    processor.processResponseBlock = ^(CTProcessor *builder, CTDataType dataType, NSData* data){
        __strong CTUSBServer *strongSelf = weakSelf;
        
        if (dataType == CTDataTypeText) {
            NSString *textMsg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            [strongSelf sendChannelTextMsg:textMsg];
        }else if (dataType == CTDataTypeDylib
                  ) {
            [strongSelf sendChannelDylib:data];
        }
        
    };
    return processor;
}

@end
