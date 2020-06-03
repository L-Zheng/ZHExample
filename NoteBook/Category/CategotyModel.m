//
//  CategotyModel.m
//  ZHExample
//
//  Created by Zheng on 2020/4/5.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "CategotyModel.h"

#import <objc/runtime.h>

@implementation CategotyModel
@end



@interface CategotyModel (__ZH)
//@property (nonatomic,copy) NSString *sex;
@end
@implementation CategotyModel (ZH)
- (void)zh_testLog{
    NSLog(@"zhtestlogzh");
}

/** _cmd 代表该方法 */
-(NSString *)zh_name{
    return objc_getAssociatedObject(self, _cmd);
}
/** @selector 中的方法表示 该属性的get方法 */
-(void)setZh_name:(NSString *)zh_name{
    objc_setAssociatedObject(self, @selector(zh_name), zh_name, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

-(void (^)(BOOL))block{
    return objc_getAssociatedObject(self, _cmd);
}
-(void)setBlock:(void (^)(BOOL))block{
    objc_setAssociatedObject(self, @selector(block), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
@end
