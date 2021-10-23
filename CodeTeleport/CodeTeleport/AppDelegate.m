//
//  AppDelegate.m
//  CodeTeleport
//
//  Created by zhaolei.lzl on 2018/6/29.
//  Copyright © 2018年 zhaolei.lzl. All rights reserved.
//

#import "AppDelegate.h"
#import "DDHotKeyCenter.h"
#import <AppKit/NSEvent.h>
#import "DDHotKeyCenter.h"
#import "CTUtils.h"
#import <Carbon/Carbon.h>

#define kUrlScheme @"urlScheme"
#define kUrlSchemeSwitch @"urlSchemeSwitch"

#define kReplaceOldClassSwitch @"kReplaceOldClassSwitch"
#define kReplaceOldClassBlackList @"kReplaceOldClassBlackList"

#define kMonitorPath @"monitorPath"
#define kMonitorPathSwitch @"monitorPathSwitch"

typedef enum : NSUInteger {
    kActiveStateIdle,
    kActiveStateByUSB,
    kActiveStateByNetwork
} kActiveState;

@interface AppDelegate () <NSTextFieldDelegate>
- (IBAction)trigger:(id)sender;
- (IBAction)completedAction:(id)sender;
- (IBAction)quit:(id)sender;
@property (weak) IBOutlet NSTextField *noticeText;
@property (weak) IBOutlet NSPanel *completedNotice;
@property (weak) IBOutlet NSMenu *menu;
@property (weak) IBOutlet NSWindow *window;
@property (strong, nonatomic) NSStatusItem *statusItem;
@property (weak) IBOutlet NSWindow *actionWindow;
@property (weak) IBOutlet NSButton *urlCheckBox;
@property (weak) IBOutlet NSTextField *urlInput;
@property (weak) IBOutlet NSButton *monitorPathCheckBox;
@property (weak) IBOutlet NSTextField *monitorPathInput;
@property(nonatomic, assign) kActiveState activeState;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    [self initSstatusItem];
    [self registerHandle];
    
    //urlCheckBox
    [self.urlCheckBox setAction:@selector(urlCheckBoxAction:)];
    self.urlCheckBox.state = [[NSUserDefaults standardUserDefaults] boolForKey:kUrlSchemeSwitch];
    
    //urlInput
    self.urlInput.stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:kUrlScheme];
    self.urlScheme = self.urlInput.stringValue;
    [self.urlInput setDelegate:self];
    
    //monitorPathCheckBox
    [self.monitorPathCheckBox setAction:@selector(monitorPathCheckBoxAction:)];
    self.monitorPathCheckBox.state = [[NSUserDefaults standardUserDefaults] boolForKey:kMonitorPathSwitch];
    
    //monitorPathInput
    if([[NSUserDefaults standardUserDefaults] stringForKey:kMonitorPath].length > 0){
        self.monitorPathInput.stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:kMonitorPath];
        self.monitorFilePath = self.monitorPathInput.stringValue;
    }
    [self.monitorPathInput setDelegate:self];
    
    //completedNotice
    self.completedNotice.animationBehavior = NSWindowAnimationBehaviorAlertPanel;
}

- (void)initSstatusItem
{
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.highlightMode = YES;
    self.statusItem.menu = self.menu;
    self.statusItem.enabled = TRUE;
    [self setStatusIcon:StatusIconTypeIdle formServer:kFormIdle];
    self.statusItem.alternateImage = self.statusItem.image;
}

- (void)registerHandle
{
    [[DDHotKeyCenter sharedHotKeyCenter] registerHotKeyWithKeyCode:kVK_ANSI_4
                                                     modifierFlags:NSEventModifierFlagCommand
                                                            target:self action:@selector(triggerTeleport) object:nil];
    
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
                                                       andSelector:@selector(handleURLEvent:withReplyEvent:)
                                                     forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (void)controlTextDidEndEditing:(NSNotification *)notification {
    NSTextField *textField = [notification object];
    if(self.urlInput == textField){
        self.urlCheckBox.state = NO;
        [[NSUserDefaults standardUserDefaults] setObject:textField.stringValue forKey:kUrlScheme];
        self.urlScheme = textField.stringValue;
    }else if(self.monitorPathInput == textField){
        self.monitorPathCheckBox.state = NO;
        [[NSUserDefaults standardUserDefaults] setObject:textField.stringValue forKey:kMonitorPath];
        self.monitorFilePath = textField.stringValue;
    }
}

-(void)monitorPathCheckBoxAction:(NSButton *)sender
{
    if(sender.state == YES){
        if(self.monitorPathInput.stringValue.length == 0){
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"Please enter Monitor Path first."];
            [alert runModal];
            sender.state = NO;
            return;
        }else{
            self.monitorFilePath = self.monitorPathInput.stringValue;
        }
    }else{
        self.monitorFilePath = @"";
    }
    [[NSUserDefaults standardUserDefaults] setObject:self.monitorFilePath forKey:kMonitorPath];
    [[NSUserDefaults standardUserDefaults] setBool:sender.state forKey:kMonitorPathSwitch];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Monitor Path changed, app will restart."];
    [alert runModal];
    [self quit:nil];
}

-(void)urlCheckBoxAction:(NSButton *)sender
{
    if(sender.state == YES){
        if(self.urlInput.stringValue.length == 0){
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"Please enter Url Scheme first."];
            [alert runModal];
            sender.state = NO;
        }else{
            self.urlScheme = self.urlInput.stringValue;
        }
    }else{
        self.urlScheme = @"";
    }
    [[NSUserDefaults standardUserDefaults] setBool:sender.state forKey:kUrlSchemeSwitch];
    [[NSUserDefaults standardUserDefaults] setObject:self.urlInput.stringValue forKey:kUrlScheme];
}

- (void)handleURLEvent:(NSAppleEventDescriptor*)theEvent withReplyEvent:(NSAppleEventDescriptor*)replyEvent
{
    NSString* schemeUrl = [[theEvent paramDescriptorForKeyword:keyDirectObject] stringValue];
    CTLog(@"----------scheme url :%@",schemeUrl);
    NSURLComponents *components = [NSURLComponents componentsWithString:schemeUrl];
    NSArray *queryItems = components.queryItems;
    CTLog(@"queryItems:%@",queryItems);
}

- (void)setStatusIcon:(StatusIconType) state  formServer:(kFormServer)formServer;
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.activeState == kActiveStateByNetwork
            && formServer != kFormNetwork) {
            return;
        } else if (self.activeState == kActiveStateByUSB
                   && formServer != kFormUSB) {
            return;
        }
        
        if(state == StatusIconTypeIdle) {
            self.statusItem. image = [NSImage imageNamed:@"icon_idle"];
            self.activeState = kActiveStateIdle;
        } else {
            self.statusItem.image =[NSImage imageNamed:@"icon_active"];
            if (formServer == kFormNetwork) {
                self.activeState = kActiveStateByNetwork;
            } else {
                self.activeState = kActiveStateByUSB;
            }
        }
    });
}

- (void)triggerTeleport
{
    CTLog(@"AppDelegate:triggerTeleport,postNotification.");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ZLTriggerTeleport"
                                                        object:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


- (IBAction)trigger:(id)sender {
    [self triggerTeleport];
}

- (IBAction)completedAction:(id)sender {
    [self.actionWindow setIsVisible:YES];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)quit:(id)sender {
    exit(0);
}

- (void)showCompeledNotice:(NSString *)notice
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.noticeText.stringValue = notice;
        [self.completedNotice setIsVisible:YES];
        [NSApp activateIgnoringOtherApps:YES];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.completedNotice setIsVisible:NO];
        });
    });
}

@end
