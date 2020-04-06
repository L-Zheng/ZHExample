//
//  BlockM.m
//  ZHExample
//
//  Created by Zheng on 2020/4/5.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "BlockM.h"

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
//        [self testBlockLocalStaticVariable_Integer];
    }
    return self;
}

- (void)myBlock1{
    NSInteger num = 3;
    NSInteger(^block)(NSInteger) = ^NSInteger(NSInteger n){
        return n*num;
    };
    block(2);
}

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
    __block NSMutableArray * arr = [NSMutableArray arrayWithObjects:@"1",@"2", nil];
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
