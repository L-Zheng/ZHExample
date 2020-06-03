>一种设计模式，一对一传递。

![image.png](https://upload-images.jianshu.io/upload_images/4115164-8697f13e019ff8e2.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

**delegate修饰**
>weak：规避循环引用，弱引用的对象释放时，自动置空。【如何自动置空的？？？】
strong：导致循环引用。
assign：assign是指针赋值，不对引用计数操作，可以规避循环引用，但引用的对象释放时，不会自动置空，导致野指针错误。
