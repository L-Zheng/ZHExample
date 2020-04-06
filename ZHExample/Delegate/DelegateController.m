//
//  DelegateController.m
//  ZHExample
//
//  Created by Zheng on 2020/4/7.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "DelegateController.h"
#import "DelegateM.h"

@interface DelegateController ()<ZHDelegate>
@property (nonatomic,strong) DelegateM *model;
@end

@implementation DelegateController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.model = [[DelegateM alloc] init];
    self.model.delegate = self;
    
    
}

- (void)delegateMDidClick:(DelegateM *)delegateM{
    
}
- (void)delegateMDidClick1:(DelegateM *)delegateM{
    
}


@end
