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
//static NSMutableDictionary *dylibClassDic;
//
//IMP dylibHandleClassInitIMP(){
//    return imp_implementationWithBlock(^id(id SELF, SEL selector){
//            //dylibClass must be newest dylibClass,and have been patched
//            Class dylibClass = [dylibClassDic objectForKey:NSStringFromClass([SELF class])];
//            Class currentClass = [SELF class];
//            if (dylibClass && dylibClass != currentClass) {
//                object_setClass(SELF, dylibClass);
//            }
//
//            IMP initIMP;
//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Wundeclared-selector"
//            SEL patchInitSelector = @selector(codeteleport_patch_init);
//#pragma clang diagnostic pop
//            Method patchInitMethod = class_getInstanceMethod([SELF class], patchInitSelector);
//            // if SELF has patchInitMethod, class patched with exchangeImplementations
//            // patchInitMethod point to oringal initIMP
//            if(patchInitMethod){
//                initIMP = method_getImplementation(patchInitMethod);
//            }else{
//                // else, class patched with addInit
//                // there is no oringal initIMP,call [super init]
//                SEL initSelector = @selector(init);
//                Method initMethod = class_getInstanceMethod([SELF superclass], initSelector);
//                initIMP = method_getImplementation(initMethod);
//            }
//
//            return ((id(*)(id, SEL))initIMP)(SELF, selector);
//        });
//}

@implementation CodeTeleportLoader

+ (void)loadDylibWithPath:(NSString *) path
               classNames:(NSArray *) classNames
                    error:(NSError **) error
    replaceOldClassMethod:(BOOL) replaceOldClassMethod
         replaceBlackList:(NSArray *) replaceBlackList
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:path] == NO) {
        *error = CTError(@"%@ is not exist.",path);
        return;
    }
    
//    if (dylibClassDic == nil) {
//        dylibClassDic = [[NSMutableDictionary alloc] init];
//    }
    
    // dispatch to main thread, because maybe class +load +initialize require;
    const char *dylibCString = [path cStringUsingEncoding:NSUTF8StringEncoding];
    
    dylibHandle = dlopen(dylibCString, RTLD_NOW | RTLD_GLOBAL);
    
    if (dylibHandle == NULL) {
        *error = CTError(@"open dylib error: %s.", dlerror());
        return;
    }
    
    CTLog(@"image opened");
    
    for (NSUInteger class_index=0; class_index < [classNames count]; class_index++) {
        // load symbol
        NSString *className = [classNames objectAtIndex:class_index];
        
        Class class = [CodeTeleportLoader getClassWithDylib:dylibHandle
                                                  className:className];
        
        if (class) {
//            //patch init to set newClass when new a object
//            [CodeTeleportLoader patchInitForClass:class];
//            [dylibClassDic setObject:class forKey:className];
            
            Class oldClass = NSClassFromString(className);
//            if(oldClass){
//                [CodeTeleportLoader patchInitForClass:oldClass];
//            }
            
            if(replaceOldClassMethod && oldClass){
                [CodeTeleportLoader replaceMethodFrom:object_getClass(class)
                                              toClass:object_getClass(oldClass)
                                     replaceBlackList:replaceBlackList];

                [CodeTeleportLoader replaceMethodFrom:class
                                              toClass:oldClass
                                     replaceBlackList:replaceBlackList];
            }
        }
    }
}

//+(void)patchInitForClass:(Class)class
//{
//    if ([CodeTeleportLoader checkPatchStub:class]) {
//        CTLog(@"%@ checkPatchStub YES, already patched.", [self dumpClass:class]);
//        return;
//    }
//
//    // get class orginal initImp
//    // if class does't implement initSelector, orginalInitIMP is [super init]
//    // otherwise orginalInitIMP is [class init]
//    SEL initSelector = @selector(init);
//    Method initMethod = class_getInstanceMethod(class, initSelector);
//
//    // get patchInitImp
//    SEL patchInitSelector = @selector(codeteleport_patch_init);
//    Method patchInitMethod = class_getInstanceMethod([self class], patchInitSelector);
//    // using block implemetation can set newest Class, for later use
//    IMP patchInitIMP = dylibHandleClassInitIMP();
//
//    // try to add init method
//    // if class does't implement initSelector, addPatchInit = YES
//    // initSelector point to patchInitIMP
//    BOOL addPatchInit = class_addMethod(class, initSelector, patchInitIMP, method_getTypeEncoding(initMethod));
//    if (addPatchInit == YES) {
//        [CodeTeleportLoader addPatchStub:class];
//        CTLog(@"patched by addInit: %@", [self dumpClass:class]);
//        return;
//    }
//
//    // otherwise add patchInitMethod method
//    addPatchInit = class_addMethod(class, patchInitSelector, patchInitIMP, method_getTypeEncoding(patchInitMethod));
//    if (addPatchInit == NO) {
//        CTLog(@"[WARNING] patch failed for class: %@", [self dumpClass:class]);
//        return;
//    }
//
//    // exchange realtineInit to init
//    Method newPatchMethod = class_getInstanceMethod(class, patchInitSelector);
//    method_exchangeImplementations(initMethod, newPatchMethod);
//    [CodeTeleportLoader addPatchStub:class];
//    CTLog(@"patched by exchange method: %@", [self dumpClass:class]);
//}

+ (Class)getClassWithDylib:(void *) dylib
                 className:(NSString *) className
{
    char class_symbol_name[256];
    sprintf(class_symbol_name, "OBJC_CLASS_$_%s", [className cStringUsingEncoding:NSUTF8StringEncoding]);
    
    dlerror();
    
    Class class = (__bridge Class)(dlsym(dylib, class_symbol_name));
    
    
    char *err;
    if ((err = dlerror()) != NULL)
    {
        CTLog(@"dlsym error:%s",err);
    }
    
    CTLog(@"class_symbol_name:%s,address: %p",class_symbol_name,class);
    return class;
}

//+ (BOOL)checkPatchStub:(Class) class
//{
//    SEL stubSelector = @selector(codeteleport_patch_stub);
//    Method stubMethod = class_getInstanceMethod(class, stubSelector);
//    if (stubMethod != NULL) {
//        return YES;
//    }else{
//        return NO;
//    }
//}
//
//+ (void)addPatchStub:(Class) class
//{
//    SEL stubSelector = @selector(codeteleport_patch_stub);
//    Method stubMethod = class_getInstanceMethod([self class], stubSelector);
//    BOOL addStub = class_addMethod(class, stubSelector, method_getImplementation(stubMethod), method_getTypeEncoding(stubMethod));
//    if (addStub == NO) {
//        CTLogAssertNO(@"add stub method failed!");
//    }
//}
//
//+(NSString *)dumpClass:(Class)class
//{
//    return [NSString stringWithFormat:@"%@(0x%08x)", class, (unsigned int)class];
//}
//
//- (id)codeteleport_patch_init
//{
//    CTLogAssertNO(@"This method can not be called, maybe something wrong.");
//    return nil;
//}
//
//- (id)codeteleport_patch_stub
//{
//    CTLogAssertNO(@"This method can not be called, maybe something wrong.");
//    return nil;
//}

+ (void)replaceMethodFrom:(Class) class
                  toClass:(Class) toClass
         replaceBlackList:(NSArray *) replaceBlackList
{
    unsigned int methodCount;
    Method *methods = class_copyMethodList(class, &methodCount);
    CTLog("dylib class %@ methodCount: %u",class,methodCount);
    for (int index=0; index < methodCount; index++) {
        NSString *methodName = NSStringFromSelector(method_getName(methods[index]));
        
        BOOL isBlackList = NO;
        for (NSString *blackListMethod in replaceBlackList) {
            if([methodName hasPrefix:blackListMethod]){
                isBlackList = YES;
                break;
            }
        }
        
        if(isBlackList){
            CTLog("method: %@ , in blackList.",methodName);
            continue;
        }
        
        CTLog("replace method: %@",methodName);
        
        class_replaceMethod(toClass, method_getName(methods[index]),
                            method_getImplementation(methods[index]),
                            method_getTypeEncoding(methods[index]));
    }
}

@end
