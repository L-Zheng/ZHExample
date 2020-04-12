//
//  ZHBaseController.m
//  ZHExample
//
//  Created by Zheng on 2020/4/11.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHBaseController.h"

@interface ZHBaseController ()

@end

@implementation ZHBaseController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
}
- (void)dealloc{
    NSLog(@"--------%s------------", __func__);
}

@end
