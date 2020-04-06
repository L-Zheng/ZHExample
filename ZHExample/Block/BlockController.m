//
//  BlockController.m
//  ZHExample
//
//  Created by Zheng on 2020/4/6.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "BlockController.h"
#import "BlockM.h"

@interface BlockController ()

@end

@implementation BlockController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    BlockM *b = [[BlockM alloc] init];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
