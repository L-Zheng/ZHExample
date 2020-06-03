##介绍
>跨层传递消息，用来降低耦合度。
一对多发送。

##NSNotification类定义
```
@interface NSNotification : NSObject <NSCopying, NSCoding>

@property (readonly, copy) NSNotificationName name;
@property (nullable, readonly, retain) id object;
@property (nullable, readonly, copy) NSDictionary *userInfo;
```

##NSNotificationCenter

#####添加观察者、发送通知
```
👇aName、anObject参数可以为空
/**
observer：谁接受通知
aSelector：接受通知响应observer的哪个方法
aName：接受的通知name
anObject：接受发给哪个对象的通知
*/
- (void)addObserver:(id)observer selector:(SEL)aSelector name:(nullable NSNotificationName)aName object:(nullable id)anObject;
👇queue如果为nil，那么block执行线程就是通知所在的线程
👇返回值就是observer[__NSObserver对象]， 之后可以移除removeObserver：（👇该方法返回值）
- (id <NSObject>)addObserverForName:(nullable NSNotificationName)name object:(nullable id)obj queue:(nullable NSOperationQueue *)queue usingBlock:(void (^)(NSNotification *note))block;

- (void)postNotification:(NSNotification *)notification;
- (void)postNotificationName:(NSNotificationName)aName object:(nullable id)anObject;
- (void)postNotificationName:(NSNotificationName)aName object:(nullable id)anObject userInfo:(nullable NSDictionary *)aUserInfo;
```
>注册规则
name为空、object为空：可接受到所有发送的通知。
name不为空、object为空：可接受到name相同的通知。
name为空、object不为空：可接受到object相同的通知。
name不为空、object不为空：可接受到name&&object相同的通知。

>发送规则：**name不能为空：name为空，系统不会调度该通知，不会被发送**
object为空：匹配name相同的通知。
object不为空：匹配name&&object相同的通知。

#####移除观察者
```
- (void)removeObserver:(id)observer;
- (void)removeObserver:(id)observer name:(nullable NSNotificationName)aName object:(nullable id)anObject;
```
>iOS9以前需要在dealloc方法中移除观察者，否则野指针错误。
iOS9以上系统会自动移除。**原理：系统的通知调度表应该是采用了NSMapTable弱引用指针observer的方式**。
使用addObserverForName:object:queue:usingBlock:方法还是需要手动释放。因为NSNotificationCenter依旧对它们强引用

##NSNotificationQueue
- 通知队列，用来管理多个通知的调用。NSNotificationQueue就像一个缓冲池把一个个通知放进池子中，使用特定方式通过NSNotificationCenter发送到相应的观察者
- 通过合并通知可以保证相同的通知只被发送一次。
```
typedef NS_ENUM(NSUInteger, NSPostingStyle) {
//👇空闲发送通知 当运行循环处于等待或空闲状态时，发送通知，对于不重要的通知可以使用。
    NSPostWhenIdle = 1,
//👇尽快发送通知 当前运行循环迭代完成时，通知将会被发送，有点类似没有延迟的定时器。
    NSPostASAP = 2,
//👇同步发送通知 如果不使用合并通知 和postNotification:一样是同步通知。
    NSPostNow = 3
};
typedef NS_OPTIONS(NSUInteger, NSNotificationCoalescing) {
//👇不合并通知。
    NSNotificationNoCoalescing = 0,
//👇合并相同名称的通知
    NSNotificationCoalescingOnName = 1,
//👇合并相同通知和同一对象的通知。
    NSNotificationCoalescingOnSender = 2
};
//👇有单例
@property (class, readonly, strong) NSNotificationQueue *defaultQueue;
//👇创建通知队列方法:
- (instancetype)initWithNotificationCenter:(NSNotificationCenter *)notificationCenter NS_DESIGNATED_INITIALIZER;

//👇往队列加入通知方法:
- (void)enqueueNotification:(NSNotification *)notification postingStyle:(NSPostingStyle)postingStyle;
//👇可以指定NSRunLoopMode，发送通知与runloop机制相关联
- (void)enqueueNotification:(NSNotification *)notification postingStyle:(NSPostingStyle)postingStyle coalesceMask:(NSNotificationCoalescing)coalesceMask forModes:(nullable NSArray<NSRunLoopMode> *)modes;
//👇移除队列中的通知方法:
- (void)dequeueNotificationsMatching:(NSNotification *)notification coalesceMask:(NSUInteger)coalesceMask;
```

##NSNotificatinonCenter实现原理
***猜想：**系统应该有一张类似NSMapTable的通知调度表。保存name与ObserverLists的对应关系。
>**注册通知时**，将name作为key，value为Observer【SEL】保存在表里。
**发送通知时**，系统会创建NSNotificatinon对象，根据name找到Observer，运行Observer的SEL方法，并将NSNotificatinon作为参数传递。

>对于使用block方式注册的通知
**注册通知时**：系统会创建一个__NSObserver对象，作为该方法的返回值。【猜想：__NSObserver对象充当了Observer的角色，持有了block函数】。
**发送通知时**，根据name找到Observer，运行Observer的block方法。
```
@{
@"NSNotificatinonName": @[Observer1,Observer2]
}
```

##系统用到通知的地方
>UITextField：UITextFieldTextDidChangeNotification
键盘：UIKeyboardWillShowNotification

##注意事项
>相同的通知如果被注册多次，那么当发送通知时，会接受到多次通知

##编译器如何处理
运行`clang -rewrite-objc xx.m`
```
- (void)test{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(aaaa:) name:@"xxxxxx" object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"xxxxxx" object:self userInfo:@{}];
}
- (void)aaaa:(NSNotification *)note{
}
```
```
static void _I_NotificationModel_test(NotificationModel * self, SEL _cmd) {
    /**
     id:    defaultCenter
     SEL:   addObserver:selector:name:object:
     id:   Observer
     SEL:   Observer中的SEL
     name:   NSNotificationName
     object:   接受谁的通知
     
     objc_msgSend：对defaultCenter发送消息，后面是传的参数。
     */
    (
     (void (*)(id, SEL, id _Nonnull, SEL _Nonnull, NSNotificationName _Nullable, id _Nullable))
     (void *)objc_msgSend
    )(
      (id)( (NSNotificationCenter * _Nonnull (*)(id, SEL)) (void *)objc_msgSend )
      ((id)objc_getClass("NSNotificationCenter"), sel_registerName("defaultCenter")),
      
      sel_registerName("addObserver:selector:name:object:"),
      (id _Nonnull)self,
      sel_registerName("aaaa:"),
      (NSString *)&__NSConstantStringImpl__var_folders_r7_f6d_j39n1sqcpcqn9yp633540000gn_T_NotificationModel_dc2454_mi_0,
      (id _Nullable)__null
    );

    //👇发送通知
    (
     (void (*)(id, SEL, NSNotificationName _Nonnull, id _Nullable, NSDictionary * _Nullable))
     (void *)objc_msgSend
    )(
      (id)((NSNotificationCenter * _Nonnull (*)(id, SEL))(void *)objc_msgSend)
      ((id)objc_getClass("NSNotificationCenter"), sel_registerName("defaultCenter")),
      
      sel_registerName("postNotificationName:object:userInfo:"),
      (NSString *)&__NSConstantStringImpl__var_folders_r7_f6d_j39n1sqcpcqn9yp633540000gn_T_NotificationModel_dc2454_mi_1,
      (id _Nullable)__null,
      
      //👇构造字典 @{}
      ((NSDictionary *(*)(Class, SEL, ObjectType  _Nonnull const *, const id *, NSUInteger))(void *)objc_msgSend)
      (objc_getClass("NSDictionary"),
       sel_registerName("dictionaryWithObjects:forKeys:count:"),
       (const id *)__NSContainer_literal(0U).arr,
       (const id *)__NSContainer_literal(0U).arr,
       0U)
      );
}
static void _I_NotificationModel_aaaa_(NotificationModel * self, SEL _cmd, NSNotification *note) {

}
```
