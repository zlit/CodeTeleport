//
//  CodeTeleportLoader.m
//  CTClient
//
//  Created by zhaolei.lzl on 2018/7/3.
//  Copyright © 2018年 zhaolei.lzl. All rights reserved.
//

#import "CodeTeleportLoader.h"
#import <dlfcn.h>
#import <objc/runtime.h>
#import "CodeTeleportUtils.h"

static void *dylibHandle;

@implementation CodeTeleportLoader

+ (void)loadDylibWithPath:(NSString *) path
               classNames:(NSArray *) classNames
                    error:(NSError **) error
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:path] == NO) {
        *error = CTError(@"%@ is not exist.",path);
        return;
    }
    
    // dispatch to main thread, because maybe class +load +initialize require;
    const char *dylibCString = [path cStringUsingEncoding:NSUTF8StringEncoding];

    dylibHandle = dlopen(dylibCString, RTLD_NOW);
    
    if (dylibHandle == NULL) {
        *error = CTError(@"open dylib error: %s.", dlerror());
        return;
    }
    
    CTLog(@"image opened");
    
    // 开始遍历 image 得到 imageHeader
    for (NSUInteger class_index=0; class_index < [classNames count]; class_index++) {
        // load symbol
        NSString *className = [classNames objectAtIndex:class_index];
        char class_symbol_name[256];
        sprintf(class_symbol_name, "OBJC_CLASS_$_%s", [className cStringUsingEncoding:NSUTF8StringEncoding]);
        
        CTLog(@"class_symbol_name:%s,index:%lu",class_symbol_name,class_index);
        Class class = (__bridge Class)(dlsym(dylibHandle, class_symbol_name));
        if (class) {
            Class oldClass = NSClassFromString(className);
            //patch init to set newClass when new a object
            [CodeTeleportLoader patchInitForClass:class];
            //replace  oldClass method with new method,make oldObj can invoke them.
            [CodeTeleportLoader replaceMethodFrom:class.self
                                toClass:oldClass];
            [CodeTeleportLoader replaceMethodFrom:object_getClass(class.self)
                                toClass:object_getClass(oldClass)];
        }
    }
}

+ (void)replaceMethodFrom:(Class) class toClass:(Class) toClass
{
    unsigned int methodCount;
    Method *methods = class_copyMethodList(class, &methodCount);
//    CTLog("dylib class %@ methodCount: %u",class,methodCount);
    for (int index=0; index < methodCount; index++) {
//        CTLog("exchange method: %@",NSStringFromSelector(method_getName(methods[index])));
         IMP oldMethod = class_replaceMethod(toClass, method_getName(methods[index]),
                                             method_getImplementation(methods[index]),
                                             method_getTypeEncoding(methods[index]));
        if (oldMethod == NULL) {
            NSLog(@"change2 : %p",method_getImplementation(methods[index]));
        }
    }
}

#pragma mark ----- test

+(void)patchInitForClass:(Class)class
{
    // get class orginalInit imp
    SEL initSelector = @selector(init);
    Method initMethod = class_getInstanceMethod(class, initSelector);
    // if class implement initSelector, orginalInitIMP is [class init]
    // Otherwise orginalInitIMP is [super init]
    IMP orginalInitIMP = method_getImplementation(initMethod);
    
    // using block implemetation can hold origin init implementation, for later use
    IMP patchInitIMP = imp_implementationWithBlock(^id(id SELF, SEL selector){
        NSString *classSymbolName = [NSString stringWithFormat:@"OBJC_CLASS_$_%@", [SELF class]];
        Class dylibClass = (__bridge Class)dlsym(dylibHandle, classSymbolName.UTF8String);
        Class currentClass = [SELF class];
        if (dylibClass && dylibClass != currentClass) {
            object_setClass(SELF, dylibClass);
        }
        return ((id(*)(id, SEL))orginalInitIMP)(SELF, selector);
    });
    
    // try to add init method
    // if class implement initSelector, addPatchInit = NO
    // Otherwise addPatchInit = YES
    BOOL addPatchInit = class_addMethod(class, initSelector, patchInitIMP, method_getTypeEncoding(initMethod));
    if (addPatchInit == YES) {
        CTLog(@"patched by addInit: %@", [self dumpClass:class]);
        return;
    }
    
    // otherwise add patchInitMethod method
    SEL patchInitSelector = @selector(codeteleport_patch_init);
    Method patchInitMethod = class_getInstanceMethod([self class], patchInitSelector);
    addPatchInit = class_addMethod(class, patchInitSelector, patchInitIMP, method_getTypeEncoding(patchInitMethod));
    if (addPatchInit == NO) {
        CTLog(@"[WARNING] patch failed for class: %@", [self dumpClass:class]);
        return;
    }
    
    // exchange realtineInit to init
    Method newPathMethod = class_getInstanceMethod(class, patchInitSelector);
    method_exchangeImplementations(initMethod, newPathMethod);
    CTLog(@"patched by exchange method: %@", [self dumpClass:class]);
}

+(NSString *)dumpClass:(Class)class
{
    return [NSString stringWithFormat:@"%@(0x%08x)", class, (unsigned int)class];
}

- (id)codeteleport_add_init
{
    CTLogAssertNO(@"This method can not be called, maybe something wrong.");
    return nil;
}

- (id)codeteleport_patch_init
{
    CTLogAssertNO(@"This method can not be called, maybe something wrong.");
    return nil;
}

@end
