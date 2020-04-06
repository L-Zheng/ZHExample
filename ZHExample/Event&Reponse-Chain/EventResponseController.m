//
//  EventResponseController.m
//  ZHExample
//
//  Created by Zheng on 2020/4/4.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "EventResponseController.h"

@interface EventResponseViewA : UIView
@end
@implementation EventResponseViewA
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
    NSLog(@"%s",__func__);
    return [super hitTest:point withEvent:event];
}
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event{
    NSLog(@"%s",__func__);
    return [super pointInside:point withEvent:event];
}
@end


@interface EventResponseViewB : UIView
@end
@implementation EventResponseViewB
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
    NSLog(@"%s",__func__);
    return [super hitTest:point withEvent:event];
}
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event{
    NSLog(@"%s",__func__);
    return [super pointInside:point withEvent:event];
}
@end


@interface EventResponseControllerA : UIViewController
@end
@implementation EventResponseControllerA
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];
}
@end


@interface EventResponseController ()
@end

@implementation EventResponseController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    
    EventResponseViewA *viewA = [[EventResponseViewA alloc] initWithFrame:CGRectMake(0, 100, 100, 100)];
    viewA.backgroundColor = [UIColor orangeColor];
    [self.view addSubview:viewA];
    
    EventResponseViewB *viewB = [[EventResponseViewB alloc] initWithFrame:CGRectMake(0, 300, 100, 100)];
    viewB.backgroundColor = [UIColor cyanColor];
    [self.view addSubview:viewB];
    
    
    
    EventResponseControllerA *ctrlA = [[EventResponseControllerA alloc] init];
    ctrlA.view.frame = CGRectMake(100, 300, 100, 100);
    [self.view addSubview:ctrlA.view];
    NSLog(@"--------------------");
}

@end
