//
//  KVOModel.m
//  ZHExample
//
//  Created by Zheng on 2020/4/12.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "KVOModel.h"
#import "NSObject+ZHKVO.h"

@interface KVOPerson : NSObject{
//    NSString *name;
}
@property (nonatomic,copy) NSString *name;
@end

@implementation KVOPerson
@end



@interface KVOModel ()
@property (nonatomic,strong) KVOPerson *person;
@end
@implementation KVOModel

- (instancetype)init{
    self = [super init];
    if (self) {
        [self test];
    }
    return self;
}

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
    [self.person addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:@"Person Name"];
    
    
//    [self.person zh_addObserver:self forKey:@"name" withBlock:^(id object, NSString *key, id oldValue, id newValue) {
//        NSLog(@"--------------------");
//    }];
    
//    [self.person setValue:@"cc" forKey:@"name"];
    self.person.name = @"cc";
    NSLog(@"--------------------");
    NSLog(@"%@",self.person.name);
    NSLog(@"--------------------");
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
    [self.person removeObserver:self forKeyPath:@"name"];
//    [self.person removeObserver:self forKeyPath:@"name" context:@"Person Name"];
}
@end
