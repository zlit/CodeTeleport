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

+ (NSArray *)loadDylibWithPath:(NSString *) path
                         error:(NSError **) error
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:path] == NO) {
        *error = CTError(@"%@ is not exist.",path);
        return nil;
    }

    const char *dylibCString = [path cStringUsingEncoding:NSUTF8StringEncoding];

    dylibHandle = dlopen(dylibCString, RTLD_NOW | RTLD_GLOBAL);

    if (dylibHandle == NULL) {
       *error = CTError(@"open dylib error: %s.", dlerror());
       return nil;
    }

    CTLog(@"image opened");
    
    unsigned classCount = 0;
    const char **classes;
    
    classes = objc_copyClassNamesForImage(dylibCString
                                          , &classCount);
    
    if (classCount == 0) {
        //device must prefix '/private'
        const char *privatePathUTF8String = [[NSString stringWithFormat:@"/private%@",path] UTF8String];
        classes = objc_copyClassNamesForImage(privatePathUTF8String, &classCount);
    }
    
    if (classCount == 0) {
        *error = CTError(@"objc_copyClassNamesForImage failed");
        return nil;
    }
    
    NSMutableArray *classNames = [NSMutableArray array];
    
    for (int i=0; i<classCount; i++) {
        NSString *className = [NSString stringWithCString:classes[i] encoding:NSUTF8StringEncoding];
//        NSString *className = @"ViewController";
        [classNames addObject:className];
        CTLog(@"load class : %@ from image",className);
        
        
        Class class = [CodeTeleportLoader getClassWithDylib:dylibHandle
                                                  className:className];
        Class oldClass = NSClassFromString(className);
        if (class && oldClass) {
          
            [CodeTeleportLoader replaceMethodFrom:object_getClass(class)
                                          toClass:object_getClass(oldClass)];
            
            [CodeTeleportLoader replaceMethodFrom:class
                                          toClass:oldClass];
        }
    }
    return classNames;
}

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
        Class oldClass = NSClassFromString(className);
        if (class && oldClass) {
          
            [CodeTeleportLoader replaceMethodFrom:object_getClass(class)
                                          toClass:object_getClass(oldClass)];
            
            [CodeTeleportLoader replaceMethodFrom:class
                                          toClass:oldClass];
        }
    }
}

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
    
//    CTLog(@"class_symbol_name:%s,address: %p",class_symbol_name,class);
    return class;
}

+ (void)replaceMethodFrom:(Class) class
                  toClass:(Class) toClass
{
    unsigned int methodCount;
    Method *methods = class_copyMethodList(class, &methodCount);
//    CTLog("dylib class %@ methodCount: %u",class,methodCount);
    for (int index=0; index < methodCount; index++) {
        
//        NSString *methodName = NSStringFromSelector(method_getName(methods[index]));
//        CTLog("replace method: %@",methodName);
        
        class_replaceMethod(toClass, method_getName(methods[index]),
                            method_getImplementation(methods[index]),
                            method_getTypeEncoding(methods[index]));
    }
}

@end
