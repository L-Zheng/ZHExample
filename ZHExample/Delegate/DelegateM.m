//
//  DelegateM.m
//  ZHExample
//
//  Created by Zheng on 2020/4/7.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "DelegateM.h"

@implementation DelegateM

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}
- (void)test{
    if ([self.delegate respondsToSelector:@selector(delegateMDidClick:)]) {
        [self.delegate delegateMDidClick:self];
    }
    if ([self.delegate respondsToSelector:@selector(delegateMDidClick1:)]) {
        [self.delegate delegateMDidClick1:self];
    }
}

@end
