//
//  ReplaceSystemFunc.m
//  ZHExample
//
//  Created by EM on 2020/4/27.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ReplaceSystemFunc.h"
#import <UIKit/UIKit.h>
#import "fishhook.h"

@implementation ReplaceSystemFunc

/** 替换系统Log方法  一下函数写在main.m中
 */
static NSString *myLogFlag = @"jslog";

static int (*original_printf)(const char * __restrict, ...);
int new_printf(const char * __restrict format, ...) {
    return 0;
    va_list args;
    va_start(args, format);
    int res = vprintf(format, args);
    va_end(args);
    return res;
}
static void (*original_log)(NSString *format, ...);
void new_log(NSString *format, ...) {
    va_list args;
    
    //过滤
    BOOL isFilter = YES;
    if (isFilter) {
        va_start(args, format);
        NSString *first = va_arg(args, id);
        if (![first isKindOfClass:[NSString class]] ||
            first.length == 0 ||
            ![first isEqualToString:myLogFlag]) {
            va_end(args);
            return;
        }
    }
    
    va_start(args, format);
    NSLogv(format, args);
    va_end(args);
}

/**
int main(int argc, char * argv[]) {
    NSString * appDelegateClassName;
    @autoreleasepool {
        struct rebinding strlen_rebinding1 = { "printf", new_printf, (void *)&original_printf};
        rebind_symbols((struct rebinding[1]){strlen_rebinding1}, 1);
        
        struct rebinding strlen_rebinding2 = { "NSLog", new_log, (void *)&original_log};
        rebind_symbols((struct rebinding[1]){strlen_rebinding2}, 1);
        
        
        
        NSLog(@"--------------------");
        NSString *dd = nil;
        NSLog(@"%@%@%@", @{@"ddd": @[@"444", @"111"]},@"sss", @"rrr");
        NSLog(@"%@%@%@%@", @"jslog", @{@"ddd": @[@"444", @"111"]},@"sss", nil);
        printf("%s%s", "sss", "rrr");
        printf("%s%s", "jslog", "sss");
        
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}    
 */
@end
