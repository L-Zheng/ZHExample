//
//  NotificationModel.m
//  ZHExample
//
//  Created by Zheng on 2020/4/11.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "NotificationModel.h"

@implementation NotificationModel

- (instancetype)init{
    self = [super init];
    if (self) {
        [self test];
    }
    return self;
}

- (void)test{
    
//    id observe = [[NSNotificationCenter defaultCenter] addObserverForName:@"xxxxxx" object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
//        NSNotificationQueue
//    }];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(aaaa:) name:@"xxxxxx" object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"xxxxxx" object:self userInfo:@{}];
}

- (void)aaaa:(NSNotification *)note{
    NSLog(@"-------%s-------------", __func__);
}

@end
