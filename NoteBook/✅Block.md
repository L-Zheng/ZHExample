##区别
**Delegate**
>1、delegate重量级回调，回调更多的面向过程，一对一传递，方法声明和实现分离，代码连贯性差。
2、一般以weak关键词以规避循环引用

**Block**
>1、block轻量级回调，代码块和实现的地方在一个位置，代码组织更连贯。有多个方法需要多次设置。
2、block 需要将数据从栈区拷贝到堆区，内存方面占用较高，容易发生循环引用。

##Block用法
```

- (void)defineBlock{
    //定义
    void(^block1)(void) = ^{
    };
    void(^block2)(NSInteger) = ^(NSInteger n){
    };
    NSString *(^block3)(void) = ^NSString *(){
        return @"";
    };
    NSString *(^block4)(NSInteger) = ^NSString *(NSInteger n){
        return @"";
    };
    
    /**作为属性
        typedef void(^ClickBlock)(NSInteger index);
        @property (nonatomic, copy) ClickBlock imageClickBlock;
        @property (nonatomic, copy) NSString * (^block) (NSInteger);
     */
    
    //作为函数参数
    [self defineBlockParmas:^NSString *(NSInteger num) {
        return [NSString stringWithFormat:@"ff--%ld", num];
    }];
    
    /**作为函数返回值
     - (NSString * (^) (NSString *))returnBlock{ }
     */
    
    //内联用法：声明之后立即调用
    ^(NSInteger n){
    }(99);
    
    /**递归调用
     1. 每调用一次自己，系统都会开辟一个栈桢记录临时变量和参数
     2. 递归次数过多，会出现栈溢出错误
     3. 移动开发中不建议使用递归算法，现在主线程栈区只有 512K
     */
    static int (^sumBlock)(int) = ^ (int num) {
        if (num == 0) {
            return num;
        }
        return num + sumBlock(num - 1);
    };
    NSLog(@"%d", sumBlock(1024 * 128));
//    上面的测试代码调用 NSLog(@"%d", sumBlock(1024 * 128)); 就会出现栈溢出错误
    
    //链式调用
    self.add(10).add(10);
}

- (void)defineBlockParmas:(NSString * (^) (NSInteger))callBack{
    NSString *res = callBack(10);
}

- (BlockM *(^)(CGFloat num))add{
    return ^BlockM *(CGFloat num){
        self.result += num;
        return self;
    };
}
```

##编译器如何处理Block代码
```
    NSInteger num = 3;
    NSInteger(^block)(NSInteger) = ^NSInteger(NSInteger n){
        return n*num;
    };
    block(2);
```
```
👇通过 clang -rewrite-objc xx.m   得到以下代码
```
```
//👇系统定义的block结构体【block内部有isa指针，所以说其本质也是OC对象】
struct __block_impl {
  void *isa; //👈指向所属类的指针，也就是block的类型
  int Flags;//👈标志变量，在实现block的内部操作时会用到
  int Reserved;//👈保留变量
  void *FuncPtr;//👈block执行时调用的函数指针
};
//👇将.m文件中的block生成结构体【类名(BlockM) + 方法名(myBlock1) + block定义名(block) + impl_0】，
//👇参数：block_func_0，block_desc_0，引用的外部变量[执行上下文所需的参数]
struct __BlockM__myBlock1_block_impl_0 {
  struct __block_impl impl;
  struct __BlockM__myBlock1_block_desc_0* Desc;
  NSInteger num;//👈 该num为堆区指针
  __BlockM__myBlock1_block_impl_0(void *fp, struct __BlockM__myBlock1_block_desc_0 *desc, NSInteger _num, int flags=0) : num(_num) {
    impl.isa = &_NSConcreteStackBlock;//👈 该block指向栈区地址
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};
//👇将block内部实现生成新的函数【类名(BlockM) + 方法名(myBlock1) + block定义名(block) + func_0】
//👇参数：block结构体本身【__BlockM__myBlock1_block_impl_0】、调用block传入的参数
static NSInteger __BlockM__myBlock1_block_func_0(struct __BlockM__myBlock1_block_impl_0 *__cself, NSInteger n) {
  NSInteger num = __cself->num; // bound by copy

        return n*num;
    }
//👇生成block描述结构体【类名(BlockM) + 方法名(myBlock1) + block定义名(block) + desc_0】
static struct __BlockM__myBlock1_block_desc_0 {
  size_t reserved;//👈保留字段
  size_t Block_size;//👈block大小(sizeof(struct __main_block_impl_0))
} __BlockM__myBlock1_block_desc_0_DATA = { 0, sizeof(struct __BlockM__myBlock1_block_impl_0)};

//👇.m文件的方法处理
static void _I_BlockM_myBlock1(BlockM * self, SEL _cmd) {
    NSInteger num = 3;
    //👇调用自定义的block结构体：传入参数：block内部实现的新函数、block描述结构体、引用的外部变量
    //👇调用的结果就是：把自定义的block结构体传入系统的block结构体__block_impl的FuncPtr指针，保存下来
    NSInteger(*block)(NSInteger) =
    (
     (NSInteger (*)(NSInteger)) &
     __BlockM__myBlock1_block_impl_0(
                                     (void*)__BlockM__myBlock1_block_func_0,
                                     &__BlockM__myBlock1_block_desc_0_DATA,
                                     num)
     );
    
    //👇执行block：取出__block_impl的FuncPtr指针函数运行
    ( (NSInteger (*)(__block_impl *, NSInteger))
      ((__block_impl *)block)->FuncPtr
    )
    ((__block_impl *)block, 2);
}
```

##Block变量截获【编译器处理的】
> 没有__block修饰，在block内部，也会把栈区指针拷贝到堆区**【为什么一定会拷贝到堆区：因为栈区的指针是由系统分配的，不知道什么时候释放，block调用的时可能已经释放，所以拷贝到堆区】**，但原来的栈区指针保留。
**block结构体中含有isa指针，本质上属于OC对象，存放于堆区。**
**__block的作用：(ARC)**只是把局部变量的栈区指针，替换成block内部的堆区指针，原来的栈区指针丢弃。如果要在block内部修改外部变量指针**【即：在堆区修改栈区的指针，做不到，因为栈区的指针是由系统分配的】**，必须指定__block**【替换成堆区的指针】**，否则编译器报错。
**__block的作用：(MRC)**：消除循环引用。
#####局部变量【通过堆区指针取值】
```
    //👇在栈区生成指针num，在常量区生成常量【3】，num指针指向常量【3】。
    NSInteger num = 3;
    NSLog(@"栈区指针地址%p",&num);
    NSInteger(^block)(NSInteger) = ^NSInteger(NSInteger n){
        NSLog(@"堆区指针地址%p",&num);
        return n*num;
    };
/**👆block结构体中含有isa指针，本质上属于OC对象，存放于堆区。
经过此段block代码  即使block没有执行。
没有__block修饰【NSInteger num = 3;】
    block会在堆区创建新的指针，指向常量区【3】，block内部实现使用的变量地址都是堆区的指针。
    这样就有两个指针同时指向常量区【3】。
有__block修饰【__block NSInteger num = 3;】
    block会在堆区创建新的指针，指向常量区【3】，block内部实现使用的变量地址都是堆区的指针。
    会把原来栈区的num指针丢弃，换而使用新生成的堆区指针。
    这样只有一个指针指向常量区【3】，那就是堆区指针。
    之后 num = 1; 会在block内生效
*/
/**👇
没有__block修饰【NSInteger num = 3;】
    在常量区生成常量【1】，栈区num指针不在指向常量【3】，转而指向常量【1】。
    这样堆区的num指针没有变化，所以输出6
有__block修饰【__block NSInteger num = 3;】
    在常量区生成常量【1】，因为有__block，经过block代码，指针已经被替换成堆区num指针。
    这样 num = 1; 就是把堆区num指针指向常量【1】，block再次访问该指针时，内容变成了【1】，输出2
*/
    NSLog(@"【有__block修饰 ？ 打印则为堆区 ：打印则为栈区】指针地址%p", &num);
    num = 1;
    NSLog(@"%zd",block(2)); //👈输出 6 
```
```
👉同理分析：输出1，2，3，  如果有__block修饰，输出 nil
//👇在栈区生成指针arr，在堆区生成数组['1', '2']，arr指针指向堆区数组。
NSMutableArray * arr = [NSMutableArray arrayWithObjects:@"1",@"2", nil];
    void(^block)(void) = ^{
        NSLog(@"%@",arr);//局部变量
        [arr addObject:@"4"];
    };
//👇操作指针指向的堆区数组内容。
    [arr addObject:@"3"];
//👇将指针指为空地址，并不是将指针指向的堆区内容清空，原来的堆区数组还在。
    arr = nil;
    block();
```

#####局部静态变量&&全局变量&&全局静态变量【通过全局[静态]区指针取值】
> **为什么不会拷贝到堆区：因为全局[静态]区的指针是不会释放的，不需要考虑block调用时已释放的问题**
**局部静态变量&&全局变量&&全局静态变量 不需要指定__block，指定了编译器会报错。**
因为 局部静态变量&&全局变量&&全局静态变量 存放在**全局[静态]区**，位于堆区的block可以修改**全局[静态]区**的指针。
```
👇以下代码输出 2
static  NSInteger num = 3;
    NSLog(@"全局[静态]区 地址 %p",&num);
    
    NSInteger(^block)(NSInteger) = ^NSInteger(NSInteger n){
        NSLog(@"全局[静态]区 地址 %p",&num);
        return n*num;
    };
    NSLog(@"全局[静态]区 地址 %p",&num);
    num = 1;
    NSLog(@"%zd",block(2));
```
##编译器如何处理Block引用的外部变量
```
static NSInteger num3 = 300;
NSInteger num4 = 3000;
- (void)blockTest{
    NSInteger num = 30;
    static NSInteger num2 = 3;
    __block NSInteger num5 = 30000;

    void(^block)(void) = ^{
        NSLog(@"%zd",num);//局部变量
        NSLog(@"%zd",num2);//局部静态变量
        NSLog(@"%zd",num3);//全局静态变量
        NSLog(@"%zd",num4);//全局变量
        NSLog(@"%zd",num5);//__block修饰变量
    };
    block();
}
```
编译以上代码
```
//👇全局【静态】变量 保持原来的样子，在任何函数可以直接获取
static NSInteger num3 = 300;
NSInteger num4 = 3000;
//👇局部变量有 __block 修饰 生成新的结构体
struct __Block_byref_num5_0 {
  void *__isa;
__Block_byref_num5_0 *__forwarding;//👈传入自身：指针指向自身，从而换掉原来的栈区指针
 int __flags;
 int __size;
 NSInteger num5;//👈传入值，创建堆区的指针指向该值，通过该堆区指针获取value
};
struct __BlockM__blockTest_block_impl_0 {
  struct __block_impl impl;
  struct __BlockM__blockTest_block_desc_0* Desc;
  NSInteger num;//👈局部变量没有 __block 修饰：传入值，创建堆区的指针指向该值，通过该堆区指针获取value
  NSInteger *num2;//👈局部静态变量没有：传入静态区的变量指针，通过该指针获取value
  __Block_byref_num5_0 *num5; //👈局部变量有 __block 修饰：传入结构体
  __BlockM__blockTest_block_impl_0(void *fp, struct __BlockM__blockTest_block_desc_0 *desc, NSInteger _num, NSInteger *_num2, __Block_byref_num5_0 *_num5, int flags=0) : num(_num), num2(_num2), num5(_num5->__forwarding) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};

static void __BlockM__blockTest_block_func_0(struct __BlockM__blockTest_block_impl_0 *__cself) {
  __Block_byref_num5_0 *num5 = __cself->num5; // bound by ref
  NSInteger num = __cself->num; // bound by copy
  NSInteger *num2 = __cself->num2; // bound by copy

        NSLog((NSString *)&__NSConstantStringImpl__var_folders_r7_f6d_j39n1sqcpcqn9yp633540000gn_T_BlockM_a58480_mi_0,num);
        NSLog((NSString *)&__NSConstantStringImpl__var_folders_r7_f6d_j39n1sqcpcqn9yp633540000gn_T_BlockM_a58480_mi_1,(*num2));
        NSLog((NSString *)&__NSConstantStringImpl__var_folders_r7_f6d_j39n1sqcpcqn9yp633540000gn_T_BlockM_a58480_mi_2,num3);
        NSLog((NSString *)&__NSConstantStringImpl__var_folders_r7_f6d_j39n1sqcpcqn9yp633540000gn_T_BlockM_a58480_mi_3,num4);
        NSLog((NSString *)&__NSConstantStringImpl__var_folders_r7_f6d_j39n1sqcpcqn9yp633540000gn_T_BlockM_a58480_mi_4,(num5->__forwarding->num5));
    }
static void __BlockM__blockTest_block_copy_0(struct __BlockM__blockTest_block_impl_0*dst, struct __BlockM__blockTest_block_impl_0*src) {_Block_object_assign((void*)&dst->num5, (void*)src->num5, 8/*BLOCK_FIELD_IS_BYREF*/);}

static void __BlockM__blockTest_block_dispose_0(struct __BlockM__blockTest_block_impl_0*src) {_Block_object_dispose((void*)src->num5, 8/*BLOCK_FIELD_IS_BYREF*/);}

static struct __BlockM__blockTest_block_desc_0 {
  size_t reserved;
  size_t Block_size;
  void (*copy)(struct __BlockM__blockTest_block_impl_0*, struct __BlockM__blockTest_block_impl_0*);
  void (*dispose)(struct __BlockM__blockTest_block_impl_0*);
} __BlockM__blockTest_block_desc_0_DATA = { 0, sizeof(struct __BlockM__blockTest_block_impl_0), __BlockM__blockTest_block_copy_0, __BlockM__blockTest_block_dispose_0};

static void _I_BlockM_blockTest(BlockM * self, SEL _cmd) {
    NSInteger num = 30;
    static NSInteger num2 = 3;
    //👇构造结构体 __block修饰的变量
    __attribute__((__blocks__(byref))) __Block_byref_num5_0 num5 = {
        (void*)0,
        (__Block_byref_num5_0 *)&num5,
        0,
        sizeof(__Block_byref_num5_0),
        30000
    };

    void(*block)(void) = (
                          (void (*)()) &
                          __BlockM__blockTest_block_impl_0(
                                                           (void *)__BlockM__blockTest_block_func_0,
                                                           &__BlockM__blockTest_block_desc_0_DATA,
                                                           num,
                                                           &num2,
                                                           (__Block_byref_num5_0 *)&num5,
                                                           570425344
                                                           )
                          );
    
    ( (void (*)(__block_impl *))
      ((__block_impl *)block)->FuncPtr
    )
    ((__block_impl *)block);
}
```

##Block的几种形式
> 全局区block：NSGlobalBlock，存储于.data段。
栈区block：NSStackBlock，超出变量作用域，栈上的Block以及 __block变量都被销毁。
堆区block：NSMallocBlock，在变量作用域结束时不受影响。

**ARC 开启，只有 NSConcreteGlobalBlock 、NSConcreteMallocBlock【ARC下默认为Malloc】**

#####全局区block【ARC、MRC都是这样】
- 在全局变量的地方定义的block，**无论有没有copy操作，有没有引用外部变量**。
- 局部block没有引用外部变量。
- **虽然clang的rewrite-objc转化后的代码中仍显示_NSConcretStackBlock，但实际上是在全局区**。
```
👇全局区block
NSInteger num6 = 3000;
NSInteger(^blockqqqq)(void) = ^NSInteger{ NSLog(@"Global Block"); return 2 * num6;};
👇全局区block
- (void)testGlobalBlock{
    void(^block)(NSInteger) = ^(NSInteger n){
        NSLog(@"--------------------");
    };
    NSLog(@"%@",[block class]);
}
```

#####栈区block
栈block：它执行完毕之后就出栈，出栈了就会被释放掉。
- **ARC：**局部block引用外部变量并且没有copy操作。**函数传参没有copy操作**。
- **MRC：**局部block引用外部变量。【不管有没有copy操作】
```
👇栈区block
    NSInteger num = 10;
    NSLog(@"%@",[^{
        NSLog(@"%zd",num);
    } class]);

👇函数传参为栈区block
- (void)testStackBlock{
    NSInteger num = 10;
    [self testStackBlock11:^{
        NSLog(@"%zd",num);
    }];
}
- (void)testStackBlock11:(void (^) (void))block{
    block();
    NSLog(@"%@",[block class]);//👈栈区block
}
```

#####堆区block
- 对栈block进行copy操作，就是堆block。
- 对堆block进行copy操作，还是堆block，引用计数器加1。
```
- (void)testMallocBlock{
    NSInteger num = 3;
    //👇赋值即是copy操作
    NSInteger(^block)(NSInteger) = ^NSInteger(NSInteger n){
        return n*num;
    };
    NSLog(@"%@",[block class]);
}
```
- ARC下：栈区Block被复制到堆区的情况：
>**block 被赋值给了某个变量【调用Block的copy实例方法时】
Block作为函数返回值返回
将Block赋值给附有__strong修饰符的id类型或Block类型成员变量时
将方法名中含有usingBlock的Cocoa框架方法或GCD的API中传递Block时**

##Block属性修饰
>**为什么用copy修饰**：没有copy的block，是栈block，他的生命周期会随着函数的结束而结束，copy之后会放在堆里面，延长block的生命周期。
**strong在修饰block的时候就相当于copy，retain修饰栈block的时候就相当于assign，这样block会出现提前被释放掉的危险。**

##Block循环引用
>是否会造成循环引用：**要看是不是相互持有强引用**
- **ARC：**iOS5之前使用__unsafe_unretained **缺点：指针释放后自己不会置空**，之后使用__weak。
- **MRC：**__block可以消除循环引用。
```
__weak __typeof(self) weakSelf = self; 
self.testBlock =  ^{
//👉block 内部处理 ：block内部会对__weak修饰的变量进行弱引用，即对weakSelf进行弱引用
       [weakSelf test]; 
});
//👆使用__weak，不会造成循环引用，但是不知道 self 什么时候会被释放，为了保证在block内不会被释放，我们添加__strong。这样外部对象既能在 block 内部保持住，又能避免循环引用的问题
__weak __typeof(self) weakSelf = self; 
self.testBlock =  ^{
       __strong __typeof(weakSelf) strongSelf = weakSelf;
       [strongSelf test]; 
});
```

#####block宏
```
//----------------------强弱引用----------------------------
#ifndef weakify
#if DEBUG
#if __has_feature(objc_arc)
#define weakify(object) autoreleasepool{} __weak __typeof__(object) weak##_##object = object;
#else
#define weakify(object) autoreleasepool{} __block __typeof__(object) block##_##object = object;
#endif
#else
#if __has_feature(objc_arc)
#define weakify(object) try{} @finally{} {} __weak __typeof__(object) weak##_##object = object;
#else
#define weakify(object) try{} @finally{} {} __block __typeof__(object) block##_##object = object;
#endif
#endif
#endif

#ifndef strongify
#if DEBUG
#if __has_feature(objc_arc)
#define strongify(object) autoreleasepool{} __typeof__(object) object = weak##_##object;
#else
#define strongify(object) autoreleasepool{} __typeof__(object) object = block##_##object;
#endif
#else
#if __has_feature(objc_arc)
#define strongify(object) try{} @finally{} __typeof__(object) object = weak##_##object;
#else
#define strongify(object) try{} @finally{} __typeof__(object) object = block##_##object;
#endif
#endif
#endif

 @weakify(self);
 [footerView setClickFooterBlock:^{
         @strongify(self);
         [self handleClickFooterActionWithSectionTag:section];
 }];
```
#####不会造成循环引用的block
```
👇这个block存在于静态方法中，虽然block对self强引用着，但是self却不持有这个静态方法，不会造成循环引用。
[UIView animateWithDuration:0.5 animations:^{
        NSLog(@"%@", self);
    }];
```

##Block特例
```
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self testBlockForHeap0];
}

#pragma mark - testBlockForHeap0 - crash
-(NSArray *)getBlockArray0{
    int val =10;
    return [NSArray arrayWithObjects:
            ^{NSLog(@"blk0:%d",val);},
            ^{NSLog(@"blk1:%d",val);},nil];
//👆上面代码👇要换成以下代码
    return [NSArray arrayWithObjects:
            [^{NSLog(@"blk0:%d",val);} copy],
            [^{NSLog(@"blk1:%d",val);} copy],nil];
}


-(void)testBlockForHeap0{
    
    NSArray *tempArr = [self getBlockArray0];
    NSMutableArray *obj = [tempArr mutableCopy];
    typedef void (^blk_t)(void);
    blk_t block = (blk_t){[obj objectAtIndex:0]};
    block();
}
```
>这段代码在最后一行blk()会异常，因为数组中的block是栈上的。因为val是栈上的。解决办法就是调用copy方法。这种场景，ARC也不会为你添加copy，因为ARC不确定，采取了保守的措施：不添加copy。所以ARC下也是会异常退出。







































