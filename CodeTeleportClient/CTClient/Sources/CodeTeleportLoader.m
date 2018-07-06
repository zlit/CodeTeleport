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

    void *dylibHandle = dlopen(dylibCString, RTLD_NOW);
    
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
            [CodeTeleportLoader replaceMethodFrom:class.self
                                toClass:oldClass];
            //class->对象的类,class也是对象(类对象),class类对象的对应的类就是metaclass.
            // object_getClass 实现是 return isa; class.isa,指向的类,就是metaclass
            //所以类方法的数据结构其实是在metaclass的,即object_getClass(class.self)
            //这里有一点不明白的地方是,class.self和class有什么区别.
            //这里传入class,获取不到method,只有class.self可以.两者对应的指针是相同的.
            //为什么替换class的时候,要把上个dylib释放?
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
        class_replaceMethod(toClass, method_getName(methods[index]),
                            method_getImplementation(methods[index]),
                            method_getTypeEncoding(methods[index]));
    }
}
@end
