
[UIView _createLayerWithFrame]
[Layer setBounds:bounds]
[UIView setFrame：Frame]
[Layer setFrame:frame]
[Layer setPosition:position]
[Layer setBounds:bounds]
    UIView继承UIResponder 可以响应事件
    CALayer继承NSObject
    Layer的位置有archorPoint position bounds决定的
    UIView是layer的代理  layer绘制完成后调用View的DrawRwct方法显绘制的内容
    UIView主要是对显示内容的管理而 CALayer 主要侧重显示内容的绘制。
    Layer做动画时默认有隐式动画 View中禁止了动画
    当layer的属性改变时 layer 通过向它的 delegate 发送 actionForLayer:forKey: 消息来询问提供一个对应属性变化的 action。delegate 可以通过返回以下三者之一来进行响应：
    它可以返回一个动作对象，这种情况下 layer 将使用这个动作。
    它可以返回一个 nil， 这样 layer 就会到其他地方继续寻找。
    它可以返回一个 NSNull 对象，告诉 layer 这里不需要执行一个动作，搜索也会就此停止。
    layer 内部维护着三分 layer tree,分别是 presentLayer Tree(动画树),modeLayer Tree(模型树), Render Tree (渲染树),在做 iOS动画的时候，我们修改动画的属性，在动画的其实是 Layer 的 presentLayer的属性值,而最终展示在界面上的其实是提供 View的modelLayer

可以通过动画事务(CATransaction)关闭默认的隐式动画效果

 [CATransaction begin];
 [CATransaction setDisableActions:YES];
 self.myview.layer.position = CGPointMake(10, 10);
 [CATransaction commit];


https://www.jianshu.com/p/079e5cf0f014
