//
//  MultiParamsFunc.m
//  ZHExample
//
//  Created by EM on 2020/4/8.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "MultiParamsFunc.h"

@implementation MultiParamsFunc

- (instancetype)init{
    self = [super init];
    if (self) {
        [self test];
        [self print:@"a", @"b", @"c", nil];
    }
    return self;
}

/**
 va_list：用来保存宏 va_start 、va_arg 和 va_end 所需信息的一种类型。为了访问变长参数列表中的参数，必须声明 va_list 类型的一个对象。

 va_start：访问变长参数列表中的参数之前使用的宏，它初始化用va_list声明的对象，初始化结果供宏va_arg和va_end使用；

 va_arg：展开成一个表达式的宏，该表达式具有变长参数列表中下一个参数的值和类型。每次调用 va_arg 都会修改，用 va_list 声明的对象从而使该对象指向参数列表中的下一个参数。

 va_end：该宏使程序能够从变长参数列表用宏 va_start 引用的函数中正常返回。

 NS_REQUIRES_NIL_TERMINATION ：是一个宏，用于编译时非nil结尾的检查
 */
- (void)print:(NSString *)firstArg, ... NS_REQUIRES_NIL_TERMINATION{
    if (firstArg) {
        // 取出第一个参数
        NSLog(@"%@", firstArg);
        // 定义一个指向个数可变的参数列表指针；
        va_list args;
        // 用于存放取出的参数
        id arg;
        // 初始化变量刚定义的va_list变量，这个宏的第二个参数是第一个可变参数的前一个参数，是一个固定的参数
        va_start(args, firstArg);
        // 遍历全部参数 va_arg返回可变的参数(a_arg的第二个参数是你要返回的参数的类型)
        while ((arg = va_arg(args, id))) {
            NSLog(@"%@", arg);
        }
        // 清空参数列表，并置参数指针args无效
        va_end(args);
    }
}
- (void)test{
    [self testBlock:^(NSString *a1, ...) {
        NSLog(@"%@", a1);
        va_list args;
        id arg;
        va_start(args, a1);
        while ((arg = va_arg(args, id))) {
            NSLog(@"%@", arg);
        }
        va_end(args);
    }];
}
- (void)testBlock:(void (^) (NSString *a1, ...))block{
    block(@"sfd", @{}, @[], nil);
}

@end
