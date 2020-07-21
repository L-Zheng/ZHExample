//
//  NSObject+ZHKVO.h
//  ZHExample
//
//  Created by Zheng on 2020/4/12.
//  Copyright © 2020 Zheng. All rights reserved.
//


/** 实现自己的KVO */
#import <Foundation/Foundation.h>

//NS_ASSUME_NONNULL_BEGIN

typedef void(^ZHKVOBlock)(id object, NSString *key, id oldValue, id newValue);

@interface NSObject (ZHKVO)

/**
 ⚠️⚠️不能识别 首字母大写的属性，因为有setter方法转换成propertyName时 统一使用了转成了小写，待优化。
 当object添加了系统的KVO，不能再调用此方法 否则会crash
 */
- (void)zh_addObserver:(NSObject *)observer
                forKey:(NSString *)key
             withBlock:(ZHKVOBlock)block;

- (void)zh_removeObserver:(NSObject *)observer forKey:(NSString *)key;
@end

//NS_ASSUME_NONNULL_END
