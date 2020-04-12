//
//  KVOController.m
//  ZHExample
//
//  Created by Zheng on 2020/4/7.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "KVOController.h"
#import "KVOModel.h"

@interface KVOController ()
@property (nonatomic, strong) KVOModel *kvo;
@end

@implementation KVOController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[KVOModel alloc] init];
}

- (void)dealloc{
    NSLog(@"--------%s------------", __func__);
}
@end
