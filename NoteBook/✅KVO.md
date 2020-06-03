##KVO【Key-Value Observing】用法
```
- (void)test{
    self.person = [[KVOPerson alloc] init];
    /**
    1. self.person：要监听的对象【要监听谁】
    2. 参数
        1> 观察者，负责处理监听事件的对象【谁监听】
        2> 要监听的属性
        3> 观察的选项（观察新、旧值，也可以都观察）
        4> 上下文，用于传递数据，可以利用上下文区分不同的监听
    */
    [self.person addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:@"Person Name"];
}
/**
*   @param keyPath 监听的属性名
*   @param object   属性所属的对象
*   @param change   属性的修改情况（属性原来的值、属性最新的值）
*   @param context 传递的上下文数据，与监听的时候传递的一致，可以利用上下文区分不同的监听
*/
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    /**
     NSKeyValueChangeKindKey：change中永远会包含的键值对，是个NSNumber对象，具体的数值有NSKeyValueChangeSetting、NSKeyValueChangeInsertion、NSKeyValueChangeRemoval、NSKeyValueChangeReplacement这几个，其中后三个是针对于to-many relationship的。
     NSKeyValueChangeNewKey：addObserver时optional参数加入NSKeyValueObservingOptionNew，这个键值对才会被change参数包含；它表示这个property改变后的新值。
     NSKeyValueChangeNewOld：addObserver时optional参数加入NSKeyValueObservingOptionOld，这个键值对才会被change参数包含；它表示这个property改变前的值。
     NSKeyValueChangeIndexesKey：当被观察的property是一个ordered to-many relationship时，这个键值对才会被change参数包含；它的值是一个NSIndexSet对象。
     NSKeyValueChangeNotificationIsPriorKey：addObserver时optional参数加入NSKeyValueObservingOptionPrior，这个键值对才会被change参数包含；它的值是@YES。
     */
//    [change[NSKeyValueChangeNewKey] stringValue]
    NSLog(@"%@对象的%@属性改变了：%@", object, keyPath, change);
}
- (void)dealloc{
    [self.person removeObserver:self forKeyPath:@"name"];
//    [self.person removeObserver:self forKeyPath:@"name" context:@"Person Name"];
}
```
>**`如果[self.person addObserver:self forKeyPath:@"name"]方法调用两次，当监听到name变化时observeValueForKeyPath会回调两次，removeObserver:时也应该调用两次，否则crash。`**

##KVO实现原理
**`运行期决议，基于 runtime 机制实现的`**
```
👇Apple 中的 API 文档
     Automatic key-value observing is implemented using a technique called 
isa-swizzling… When an observer is registered for an attribute of an object the 
isa pointer of the observed object is modified, pointing to an intermediate class 
rather than at the true class …
```
>当类【Person】的属性或者成员变量第一次被观察时，
1、系统在运行期动态的创建一个派生类【NSKVONotifying_Person：继承Person】。**`如果我们自己创建了NSKVONotifying_Person类，代码运行到addObserver:时崩溃 `**
2、在派生类中重写父类中被观察属性的 setter 方法，如果父类【Person】没有实现setter方法，派生类会自动实现。**`运行时实现的，不是编译器实现`**
3、把类【Person】的isa指针指向派生类【NSKVONotifying_Person】。这样外界赋值时【.name = @"xx"】，就会调用派生类的setter方法。
4、重写class方法，指向当前类【Person】，从而隐藏生成的派生类。
```
-(void)setName:(NSString *)newName{
    [self willChangeValueForKey:@"name"];    //KVO 在调用存取方法之前调用
    [super setValue:newName forKey:@"name"]; //调用父类的存取方法
    [self didChangeValueForKey:@"name"];     //KVO 在调用存取方法之后调用
//👆继而observeValueForKey:ofObject:change:context: 方法会被调用
}
```

![image.png](https://upload-images.jianshu.io/upload_images/4115164-18b0178ba025e64a.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

##KVO触发条件
> self.name = ...     或者 KVC 的方式赋值才会触发KVO  （这种方式会调用setter方法）
 直接修改成员_name = @"newName"  不会触发KVO  这也是缺点

##KVO缺陷
>只能通过重写 `-observeValueForKeyPath:ofObject:change:context:` 方法来获得通知。不支持SEL，Block。
无法防止：同一个对象的同一个属性被监听多次。

##自己实现KVO
>**出现的问题及解决方案：**
不能识别 首字母大写的属性，因为有setter方法转换成propertyName时 统一使用了转成了小写，待优化。
 当object添加了系统的KVO，不能再调用此方法 否则会crash

>**遇到的难题：**给父类发消息模块 怎么重写父类的setter 方法 IMP的方法实现怎么有三个参数
```
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
```


##参考文章
https://nshipster.cn/key-value-observing/
http://tech.glowing.com/cn/implement-kvo/
https://www.jianshu.com/p/e036e53d240e【❌未总结】



