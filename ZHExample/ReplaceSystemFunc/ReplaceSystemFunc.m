//
//  ReplaceSystemFunc.m
//  ZHExample
//
//  Created by EM on 2020/4/27.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ReplaceSystemFunc.h"
#import <UIKit/UIKit.h>
#import <fishhook/fishhook.h>

@implementation ReplaceSystemFunc

/** 替换系统Log方法  一下函数写在main.m中
 */

 static NSString *myLogFlag = @"JSLog👉";

 static int (*original_printf)(const char * __restrict, ...);
 int new_printf(const char * __restrict format, ...) {
     return 0;
 }

 static int (*original_fprintf)(const char * __restrict, ...);
 int new_fprintf(FILE * __restrict file, const char * __restrict format, ...) {
     return 0;
 }

 static int (*original_sprintf)(char * __restrict, const char * __restrict, ...);
 int new_sprintf(char * __restrict format1, const char * __restrict format2, ...) {
     return 0;
 }

 static int (*original_vfprintf)(FILE * __restrict, const char * __restrict, va_list);
 int new_vfprintf(FILE * __restrict file, const char * __restrict format, va_list args) {
     return 0;
 }

 static int (*original_vprintf)(const char * __restrict, va_list);
 int new_vprintf(const char * __restrict format, va_list args) {
     return 0;
 }
  
 static int (*original_vsprintf)(char * __restrict, const char * __restrict, va_list);
 int new_vsprintf(char * __restrict format1, const char * __restrict format2, va_list args) {
     return 0;
 }
  
 static int (*original_snprintf)(char * __restrict __str, size_t __size, const char * __restrict __format, ...);
 int new_snprintf(char * __restrict __str, size_t __size, const char * __restrict __format, ...) {
     return 0;
 }
  
 static int (*original_vsnprintf)(char * __restrict __str, size_t __size, const char * __restrict __format, va_list);
 int new_vsnprintf(char * __restrict __str, size_t __size, const char * __restrict __format, va_list args) {
     return 0;
 }
  
 static int (*original_dprintf)(int, const char * __restrict, ...);
 int new_dprintf(int format1, const char * __restrict __str, ...) {
     return 0;
 }
  
 static int (*original_vdprintf)(int, const char * __restrict, va_list);
 int new_vdprintf(int format1, const char * __restrict __str, va_list args) {
     return 0;
 }
  
 static int (*original_asprintf)(char ** __restrict, const char * __restrict, ...);
 int new_asprintf(char ** __restrict format1, const char * __restrict format2, ...) {
     return 0;
 }
  
 static int (*original_vasprintf)(char ** __restrict, const char * __restrict, va_list);
 int new_vasprintf(char ** __restrict format1, const char * __restrict format2, va_list args) {
     return 0;
 }
  
 static int (*original_fscanf)(FILE * __restrict, const char * __restrict, ...);
 int new_fscanf(FILE * __restrict file, const char * __restrict __str, ...) {
     return 0;
 }
  
 static int (*original_scanf)(const char * __restrict, ...);
 int new_scanf(const char * __restrict __str, ...) {
     return 0;
 }
  
 static int (*original_sscanf)(const char * __restrict, const char * __restrict, ...);
 int new_sscanf(const char * __restrict __str1, const char * __restrict __str2, ...) {
     return 0;
 }
  
 static int (*original_vfscanf)(FILE * __restrict __stream, const char * __restrict __format, va_list);
 int new_vfscanf(FILE * __restrict __stream, const char * __restrict __format, va_list args) {
     return 0;
 }
  
 static int (*original_vscanf)(const char * __restrict __format, va_list);
 int new_vscanf(const char * __restrict __format, va_list args) {
     return 0;
 }
  
 static int (*original_vsscanf)(const char * __restrict __str, const char * __restrict __format, va_list);
 int new_vsscanf(const char * __restrict __str, const char * __restrict __format, va_list args) {
     return 0;
 }
 /**
  
 static int (*original_<#func#>)<#params#>;
 int new_<#func#><#params#> {
     return 0;
 }
  */

 static void (*original_log)(NSString *format, ...);
 void new_log(NSString *format, ...) {
     if (!format || [format isEqual:[NSNull null]]) {
         return;
     }
     
     va_list args;
     
     //过滤
     BOOL isFilter = YES;
     if (isFilter) {
         va_start(args, format);
         NSString *pre = [[NSString alloc] initWithFormat:format arguments:args];
         if (!pre ||
             ![pre isKindOfClass:[NSString class]] ||
             pre.length == 0 ||
             ![pre hasPrefix:myLogFlag]) {
             va_end(args);
             return;
         }
 //        NSString __unsafe_unretained *first = va_arg(args, id);;
 //        if (!first ||
 //            ![first isKindOfClass:[NSString class]] ||
 //            first.length == 0 ||
 //            ![first isEqualToString:myLogFlag]) {
 //            va_end(args);
 //            return;
 //        }
     }
     
     va_start(args, format);
     NSLogv(format, args);
     va_end(args);
 }


 void config(const char *name, void *replacement, void **replaced){
     struct rebinding strlen_rebinding = { name, replacement, replaced};
     rebind_symbols((struct rebinding[1]){strlen_rebinding}, 1);
 }


/**

int main(int argc, char * argv[]) {
    @autoreleasepool {
//        printf("-----");
//        NSLog(@"-----");
        // config("<#func#>", new_<#func#>, (void *)&original_<#func#>);
//        config("printf", new_printf, (void *)&original_printf);
//        config("fprintf", new_fprintf, (void *)&original_fprintf);
//        config("sprintf", new_sprintf, (void *)&original_sprintf);
//        config("vfprintf", new_vfprintf, (void *)&original_vfprintf);
//        config("vprintf", new_vprintf, (void *)&original_vprintf);
//        config("vsprintf", new_vsprintf, (void *)&original_vsprintf);
//        config("snprintf", new_snprintf, (void *)&original_snprintf);
//        config("vsnprintf", new_vsnprintf, (void *)&original_vsnprintf);
//        config("dprintf", new_dprintf, (void *)&original_dprintf);
//        config("vdprintf", new_vdprintf, (void *)&original_vdprintf);
//        config("asprintf", new_asprintf, (void *)&original_asprintf);
//        config("vasprintf", new_vasprintf, (void *)&original_vasprintf);
        

//        config("fscanf", new_fscanf, (void *)&original_fscanf);
//        config("scanf", new_scanf, (void *)&original_scanf);
//        config("sscanf", new_sscanf, (void *)&original_sscanf);
//        config("vfscanf", new_vfscanf, (void *)&original_vfscanf);
//        config("vscanf", new_vscanf, (void *)&original_vscanf);
//        config("vsscanf", new_vsscanf, (void *)&original_vsscanf);
        
        
        config("NSLog", new_log, (void *)&original_log);
        
        
        
        NSLog(@"-----");
        NSLog(@"-----%@%@", [NSNull null], nil);
        NSLog(@"-----%@%@", nil, nil);
        NSLog(@"-----%@%@%@", nil, @"eeee", nil);
        NSLog(@"-----%@%@%@", nil, [NSNull null], nil);
        NSLog([NSNull null]);
        NSLog(nil);
        
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}

 */
@end
