//
//  BlockM.m
//  ZHExample
//
//  Created by Zheng on 2020/4/5.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "BlockM.h"
#import <UIKit/UIKit.h>

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
/**
 @weakify(self);
 [footerView setClickFooterBlock:^{
         @strongify(self);
         [self handleClickFooterActionWithSectionTag:section];
 }];
 */

@interface BlockM ()
@property (nonatomic, assign) CGFloat result;
@end

@implementation BlockM

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

- (instancetype)init{
    self = [super init];
    if (self) {
//        [self testBlockForHeap0];
    }
    return self;
}

#pragma mark - block定义方式

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
#pragma mark - 栈区、堆区、全局block

NSInteger globalBlockVar = 3000;
//全局block
NSInteger(^blockqqqq)(void) = ^NSInteger{
    NSLog(@"Global Block");
    return 2 * globalBlockVar;
};
- (void)testGlobalBlock{
    void(^block)(NSInteger) = ^(NSInteger n){
        NSLog(@"--------------------");
    };
    //全局block
    NSLog(@"%@",[block class]);
}

- (void)testMallocBlock{
    NSInteger num = 3;
    NSInteger(^block)(NSInteger) = ^NSInteger(NSInteger n){
        return n*num;
    };
    NSLog(@"%@",[block class]);
}

- (void)testStackBlock1{
    NSInteger num = 10;
    NSLog(@"%@",[^{
        NSLog(@"%zd",num);
    } class]);
}
- (void)testStackBlock2{
    NSInteger num = 10;
    [self testStackBlock2Params:^{
        NSLog(@"%zd",num);
    }];
}
- (void)testStackBlock2Params:(void (^) (void))block{
    block();
    NSLog(@"%@",[block class]);
}

#pragma mark - 值捕获

//局部变量
- (void)testBlockLocalVariable_Integer{
//    __block作用将栈区的指针拷贝至堆区  并且该变量指针转移至堆区
    __block NSInteger num = 3;
    NSLog(@"栈区 地址 %p",&num);
    NSInteger(^block)(NSInteger) = ^NSInteger(NSInteger n){
        NSLog(@"堆区 地址1 %p",&num);
        return n*num;
    };
    NSLog(@"【有__block修饰 ？ 打印则为堆区 ：打印则为栈区】 地址 %p",&num);
    num = 1;
    NSLog(@"%zd",block(2));
}
- (void)testBlockLocalVariable_Array{
    __block NSMutableArray *arr = [NSMutableArray arrayWithObjects:@"1",@"2", nil];
    NSLog(@"栈区 地址 %p",&arr);
    
    void(^block)(void) = ^{
        NSLog(@"堆区 地址 %p",&arr);
        NSLog(@"%@",arr);//局部变量
        [arr addObject:@"4"];
    };
    NSLog(@"【有__block修饰 ？ 打印则为堆区 ：打印则为栈区】 地址 %p",&arr);
    [arr addObject:@"3"];
    arr = nil;
    
    block();
}

//局部静态变量
- (void)testBlockLocalStaticVariable_Integer{
    static  NSInteger num = 3;
    NSLog(@"全局[静态]区 地址 %p",&num);
    
    NSInteger(^block)(NSInteger) = ^NSInteger(NSInteger n){
        NSLog(@"全局[静态]区 地址 %p",&num);
        num = 4;
        return n*num;
    };
    NSLog(@"全局[静态]区 地址 %p",&num);
    num = 1;
    NSLog(@"%zd",block(2));
}

@end
