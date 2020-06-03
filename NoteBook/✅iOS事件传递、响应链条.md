
>UIApplication管理事件为什么是队列而不是栈？队列：先进先出，先产生的事件先处理。

>发生触摸事件  ---> UIKit创建UIEvent对象，该对象包含事件处理的相关信息【CGPoint、UIEvent】 ---> 放入当前活动App的Application事件队列 ---> Application依次取出事件 ---> UIWindow开始处理 ---> 事件传递

##事件传递
```
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
    // 1.👉判断下窗口能否接收事件【如果不能接受返回nil，不再调用pointInside方法】
    if (self.userInteractionEnabled == NO || self.hidden == YES ||  self.alpha <= 0.01) return nil;
    // 2.👉判断下点在不在当前UIView上
    if ([self pointInside:point withEvent:event] == NO) return nil;
    // 3.👉从后往前遍历子控件数组【为什么倒叙遍历：因为后添加的SubView层级较高，会覆盖先前的SubView，应该优先响应事件】
    int count = (int)self.subviews.count;
    for (int i = count - 1; i >= 0; i--)     {
        // 获取子控件
        UIView *childView = self.subviews[i];
        // 👉坐标系的转换,把窗口上的点转换为子控件上的点
        //👉 把自己控件上的点转换成子控件上的点
        CGPoint childP = [self convertPoint:point toView:childView];
        UIView *fitView = [childView hitTest:childP withEvent:event];
        if (fitView) {
            // 👉如果能找到最合适的view
            return fitView;
        }
    }
    // 4.👉没有找到更合适的view，也就是没有比自己更合适的view
    return self;
}
// 作用:判断下传入过来的点在不在方法调用者的坐标系上
// point:是方法调用者坐标系上的点
//- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
//{
// return NO;
//}
```
![image.png](https://upload-images.jianshu.io/upload_images/4115164-d6b8be89cb3a446c.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

##响应者链
>fitView能否处理事件  ---> fitView.superView ||  fitView.controller ||  fitView.controller.view.superView  ---> ...  ---> Window  ---> Application如果不能处理则丢弃。

>如何判断能否处理事件，继承了UIResponder才能够接收并处理事件。如果响应者链中的某个控件实现了touches...方法，则这个事件将由该控件来接受，如果调用了[super touches….];顺着响应者链条往上传递。
```
UIResponder内部提供了以下方法来处理事件触摸事件
// 一根或者多根手指开始触摸view，系统会自动调用view的下面方法
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
// 一根或者多根手指在view上移动，系统会自动调用view的下面方法（随着手指的移动，会持续调用该方法）
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
// 一根或者多根手指离开view，系统会自动调用view的下面方法
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
// 触摸结束前，某个系统事件(例如电话呼入)会打断触摸过程，系统会自动调用view的下面方法
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
加速计事件
- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event;
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event;
- (void)motionCancelled:(UIEventSubtype)motion withEvent:(UIEvent *)event;
远程控制事件
- (void)remoteControlReceivedWithEvent:(UIEvent *)event;
```


![image.png](https://upload-images.jianshu.io/upload_images/4115164-04f601e4b97e9a53.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

##参考文章
https://www.jianshu.com/p/2c5678c659d5
https://www.jianshu.com/p/09ea3fff3ffd
https://www.jianshu.com/p/6a85894b4c05
