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
            
            [CodeTeleportLoader patchInitForClass:class];
            
            //class->对象的类,class也是对象(类对象),class类对象的对应的类就是metaclass.
            // object_getClass 实现是 return isa; class.isa,指向的类,就是metaclass
            //所以类方法的数据结构其实是在metaclass的,即object_getClass(class.self)
            //这里有一点不明白的地方是,class.self和class有什么区别.
            //这里传入class,获取不到method,只有class.self可以.两者对应的指针是相同的.
            [CodeTeleportLoader replaceMethodFrom:[class class]
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
    // get class orginalInit imp and  self codeteleport_add_init imp
    SEL initSelector = @selector(init);
    Method initMethod = class_getInstanceMethod(class, initSelector);
    Method addInitMethod = class_getInstanceMethod([self class], @selector(codeteleport_add_init));
    IMP addIMP = method_getImplementation(addInitMethod);
    
    // try to add init method
    BOOL addInit = class_addMethod(class, initSelector, addIMP, method_getTypeEncoding(initMethod));
    if (addInit == YES) {
        CTLog(@"patched by addInit: %@", [self dumpClass:class]);
        return;
    }
    
    // otherwise add patchInitMethod method
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
    
    SEL patchInitSelector = @selector(codeteleport_patch_init);
    Method patchInitMethod = class_getInstanceMethod([self class], patchInitSelector);
    BOOL addPatchInit = class_addMethod(class, patchInitSelector, patchInitIMP, method_getTypeEncoding(patchInitMethod));
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
    NSString *classSymbolName = [NSString stringWithFormat:@"OBJC_CLASS_$_%@", [self class]];
    Class dylibClass = (__bridge Class)dlsym(dylibHandle, classSymbolName.UTF8String);
    Class currentClass = [self class];
    if (dylibClass && dylibClass != currentClass) {
        object_setClass(self, dylibClass);
    }
    
    // because this is an added init, just call [super init];
    return [super init];
}

- (id)codeteleport_patch_init
{
    CTLog(@"This method can not be called, maybe something wrong.");
    return nil;
}

@end
