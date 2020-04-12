//
//  NSObject+ZHKVO.m
//  ZHExample
//
//  Created by Zheng on 2020/4/12.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "NSObject+ZHKVO.h"
#import <objc/runtime.h>
#import <objc/message.h>

//生成的自定义派生类前缀
NSString *const ZHKVOClassPrefix = @"ZHKVONotifying_";
//保留注册的observer信息
NSString *const ZHKVOAssociatedObserversKey = @"ZHKVOAssociatedObserversKey";

@interface ZHKVOObserverInfo : NSObject
@property (nonatomic, weak) NSObject *observer;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) ZHKVOBlock block;
@end
@implementation ZHKVOObserverInfo
- (instancetype)initWithObserver:(NSObject *)observer key:(NSString *)key block:(ZHKVOBlock)block{
    self = [super init];
    if (self) {
        self.observer = observer;
        self.key = key;
        self.block = [block copy];
    }
    return self;
}
@end


@implementation NSObject (ZHKVO)

- (void)zh_addObserver:(NSObject *)observer
                forKey:(NSString *)key
             withBlock:(ZHKVOBlock)block{
    //生成setter方法
    NSString *propertyName = key;
    if (propertyName.length <= 0) {
        return;
    }
    NSString *setFuncName = [NSString stringWithFormat:@"set%@%@:",
                             [[propertyName substringToIndex:1] uppercaseString],
                             [propertyName substringFromIndex:1]];
    
    //检查该类有没有setter方法
    SEL setterSel = NSSelectorFromString(setFuncName);
    Method setterMethod = class_getInstanceMethod([self class], setterSel);
    if (!setterMethod) {
//        NSString *reason = [NSString stringWithFormat:@"Object %@ does not have a setter for key %@", self, key];
//        @throw [NSException exceptionWithName:NSInvalidArgumentException
//                                       reason:reason
//                                     userInfo:nil];
        return;
    }
    
    /** 获取当前类
     不能用[self class]，该方法不能获取实际isa指针指向的类 。
     [self class] == KVOPerson
     object_getClass(self) == NSKVONotifying_KVOPerson
     */
    Class originClass = object_getClass(self);
    NSString *originClassName = NSStringFromClass(originClass);
    
    Class kvoClass = originClass;
    //对象 isa 指向的类是不是一个 KVO 类
    if (![originClassName hasPrefix:ZHKVOClassPrefix]) {
        //生成派生类名
        NSString *kvoClassName = [ZHKVOClassPrefix stringByAppendingString:originClassName];
        //检查准备创建的派生类名是否存在
        kvoClass = NSClassFromString(kvoClassName);
        if (!kvoClass) {
            //创建派生类
            kvoClass = objc_allocateClassPair(originClass, kvoClassName.UTF8String, 0);
            //重写class方法，隐藏生成的派生类
            const char *types = method_getTypeEncoding(class_getInstanceMethod(originClass, @selector(class)));
            class_addMethod(kvoClass, @selector(class), (IMP)ZH_KVO_Fetch_Class, types);
            //注册派生类：告诉 Runtime 这个类的存在
            objc_registerClassPair(kvoClass);
        }
        //修改isa指针指向派生类
        object_setClass(self, kvoClass);
    }
    
//    👇下面代码的self指针已经指向了派生类
    //重写setter方法
    if (![self zh_kvo_hasSelector:setterSel]) {
        const char *types = method_getTypeEncoding(setterMethod);
        class_addMethod(kvoClass, setterSel, (IMP)ZH_KVO_Override_Setter, types);
    }

    //保留注册信息
    ZHKVOObserverInfo *info = [[ZHKVOObserverInfo alloc] initWithObserver:observer key:key block:block];
    NSMutableArray *observers = objc_getAssociatedObject(self, (__bridge const void *)(ZHKVOAssociatedObserversKey));
    if (!observers) {
        observers = [NSMutableArray array];
        objc_setAssociatedObject(self, (__bridge const void *)(ZHKVOAssociatedObserversKey), observers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [observers addObject:info];
}
- (void)zh_removeObserver:(NSObject *)observer forKey:(NSString *)key{
    NSMutableArray* observers = objc_getAssociatedObject(self, (__bridge const void *)(ZHKVOAssociatedObserversKey));
    ZHKVOObserverInfo *removeObserver;
    for (ZHKVOObserverInfo *info in observers) {
        if (info.observer == observer && [info.key isEqual:key]) {
            removeObserver = info;
            break;
        }
    }
    [observers removeObject:removeObserver];
}

//重写setter实现
static void ZH_KVO_Override_Setter(id self, SEL _cmd, id newValue){
    NSString *setterName = NSStringFromSelector(_cmd);
    
    //获取属性名
    NSString *propertyName = nil;
    if (setterName.length <=0 ||
        ![setterName hasPrefix:@"set"] ||
        ![setterName hasSuffix:@":"]) {
    }else{
        NSRange range = NSMakeRange(3, setterName.length - 4);
        NSString *key = [setterName substringWithRange:range];
        
        NSString *firstLetter = [[key substringToIndex:1] lowercaseString];
        propertyName = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:firstLetter];
    }
    
    //没有该属性 抛出异常
    if (!propertyName) {
        NSString *reason = [NSString stringWithFormat:@"Object %@ does not have setter %@", self, setterName];
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:reason
                                     userInfo:nil];
        return;
    }
    
    //获取旧值
    id oldValue = [self valueForKey:propertyName];
    
    //创建父类
    struct objc_super superClass = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
    
    //给父类发送setter方法
    void (*objc_msgSendSuperCasted)(void *, SEL, id) = (void *)objc_msgSendSuper;
    objc_msgSendSuperCasted(&superClass, _cmd, newValue);
    
    // look up observers and call the blocks
    NSMutableArray *observers = objc_getAssociatedObject(self, (__bridge const void *)(ZHKVOAssociatedObserversKey));
    for (ZHKVOObserverInfo *observer in observers) {
        if ([observer.key isEqualToString:propertyName]) {
//            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (observer.block) {
                observer.block(self, propertyName, oldValue, newValue);
            }
//            });
        }
    }
}
//隐藏动态生成的类
static Class ZH_KVO_Fetch_Class(id self, SEL _cmd){
    return class_getSuperclass(object_getClass(self));
}
- (BOOL)zh_kvo_hasSelector:(SEL)selector{
    Class class = object_getClass(self);
    unsigned int methodCount = 0;
    Method* methodList = class_copyMethodList(class, &methodCount);
    for (unsigned int i = 0; i < methodCount; i++) {
        SEL thisSelector = method_getName(methodList[i]);
        if (thisSelector == selector) {
            free(methodList);
            return YES;
        }
    }
    free(methodList);
    return NO;
}
@end
