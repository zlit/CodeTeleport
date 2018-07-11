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

@interface AppDelegate () <NSTextFieldDelegate>
- (IBAction)trigger:(id)sender;
- (IBAction)completedAction:(id)sender;
- (IBAction)quit:(id)sender;
- (IBAction)blackListInputAction:(id)sender;
@property (weak) IBOutlet NSTextField *noticeText;
@property (weak) IBOutlet NSPanel *completedNotice;
@property (weak) IBOutlet NSMenu *menu;
@property (weak) IBOutlet NSWindow *window;
@property (strong, nonatomic) NSStatusItem *statusItem;
@property (weak) IBOutlet NSWindow *actionWindow;
@property (weak) IBOutlet NSButton *notificationCheckBox;
@property (weak) IBOutlet NSButton *urlCheckBox;
@property (weak) IBOutlet NSTextField *notificationInput;
@property (weak) IBOutlet NSTextField *urlInput;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    CTLog(@"----------aNotification:%@",aNotification);
    CTLog(@"----------processInfo:%@",[[NSProcessInfo processInfo] arguments]);
    
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.highlightMode = YES;
    self.statusItem.menu = self.menu;
    self.statusItem.enabled = TRUE;
    [self setStatusIcon:StatusIconTypeIdle];
    self.statusItem.alternateImage = self.statusItem.image;
    
    [self.notificationCheckBox setAction:@selector(notificationCheckBoxAction:)];
    [self.urlCheckBox setAction:@selector(urlCheckBoxAction:)];
    
    [[DDHotKeyCenter sharedHotKeyCenter] registerHotKeyWithKeyCode:kVK_ANSI_4
                                                     modifierFlags:NSEventModifierFlagCommand
                                                            target:self action:@selector(triggerTeleport) object:nil];
    
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
                                                       andSelector:@selector(handleURLEvent:withReplyEvent:)
                                                     forEventClass:kInternetEventClass andEventID:kAEGetURL];
    self.urlInput.stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:kUrlScheme];
    self.urlCheckBox.state = [[NSUserDefaults standardUserDefaults] boolForKey:kUrlSchemeSwitch];
    self.urlScheme = self.urlInput.stringValue;
    [self.urlInput setDelegate:self];
    
    self.notificationInput.stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:kReplaceOldClassBlackList];
    self.notificationCheckBox.state = [[NSUserDefaults standardUserDefaults] boolForKey:kReplaceOldClassSwitch];
    [self.notificationInput setDelegate:self];
    
    self.replaceBlackList = self.notificationInput.stringValue;
    self.replaceOldClassSwitch = self.notificationCheckBox.state;
    self.completedNotice.animationBehavior = NSWindowAnimationBehaviorAlertPanel;
}

- (void)controlTextDidEndEditing:(NSNotification *)notification {
    NSTextField *textField = [notification object];
    if(self.urlInput == textField){
        [[NSUserDefaults standardUserDefaults] setObject:self.urlInput.stringValue forKey:kUrlScheme];
        if(self.urlCheckBox.state == YES){
            self.urlScheme = self.urlInput.stringValue;
        }
    }else{
        [[NSUserDefaults standardUserDefaults] setObject:self.replaceBlackList forKey:kReplaceOldClassBlackList];
        self.replaceBlackList = textField.stringValue;
    }
}

-(void)notificationCheckBoxAction:(NSButton *)sender
{
    self.replaceOldClassSwitch = sender.state;
    self.notificationInput.editable = sender.state;
    self.replaceBlackList = self.notificationInput.stringValue;
    [[NSUserDefaults standardUserDefaults] setBool:sender.state forKey:kReplaceOldClassSwitch];
    [[NSUserDefaults standardUserDefaults] setObject:self.replaceBlackList forKey:kReplaceOldClassBlackList];
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

- (void)setStatusIcon:(StatusIconType) state
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if(state == StatusIconTypeIdle){
            self.statusItem.image = [NSImage imageNamed:@"icon_idle"];
        }else{
            self.statusItem.image = [NSImage imageNamed:@"icon_active"];
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
//    [self.actionWindow makeKeyAndOrderFront:nil];
//    [self.actionWindow setLevel:NSStatusWindowLevel];
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
