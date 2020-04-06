//
//  ViewController.m
//  ZHExample
//
//  Created by Zheng on 2020/4/4.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ViewController.h"
#import "EventResponseController.h"
#import "BlockController.h"

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,retain) NSArray *dataArray;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0];
    self.navigationController.navigationBar.translucent = NO;
    self.title = @"😁";
    [self.view addSubview:self.tableView];
//    if (@available(iOS 11.0, *)) {
//        self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
//    } else {
//        self.automaticallyAdjustsScrollViewInsets = NO;
//    }
}

- (NSArray *)configData{
    return @[
        @{
            @"title" : @"事件传递、响应链条",
            @"block" : ^UIViewController *{
                return [[EventResponseController alloc] init];
            }
        },
        @{
            @"title" : @"Block",
            @"block" : ^UIViewController *{
                return [[BlockController alloc] init];
            }
        }
    ];
}

#pragma mark - getter

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor clearColor];
        
        _tableView.delegate = self;
        _tableView.dataSource = self;
        
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        _tableView.tableFooterView = [UIView new];
        
        _tableView.allowsSelectionDuringEditing = YES;
    }
    return _tableView;
}

- (NSArray *)dataArray{
    if (!_dataArray) {
        _dataArray = [self configData];
    }
    return _dataArray;
}

#pragma mark - UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellID = @"cellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    cell.textLabel.text = [self.dataArray[indexPath.row] valueForKey:@"title"];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *dic = self.dataArray[indexPath.row];
    UIViewController * (^block) (void) = [dic valueForKey:@"block"];
    NSString *title = [dic valueForKey:@"title"];
    if (block) {
        UIViewController *vc = block();
        vc.title = title;
        [self.navigationController pushViewController:vc animated:YES];
    }
}


@end
