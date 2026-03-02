# QQTabBarController
自定义 Custom UITabBarController

QQTabBarController和系统UITabBarController使用方法类似，QQTabBar可以高度自定义，能更方便实现自己想要的效果。

<img width="748" height="1616" alt="49669577-e8a3-4da7-8909-251fefc62114" src="https://github.com/user-attachments/assets/01b570df-45dc-4744-9c7c-c59e004d14ce" />

使用QQTabBarController时：

UIViewController *vc = [[UIViewController alloc] init];
vc.tabBarItem = nil;
vc.hidesBottomBarWhenPushed = YES;
vc.tabBarController;

替换成：

vc.qq_tabBarItem = nil;
vc.qq_hidesBottomBarWhenPushed = YES;
vc.qq_tabBarController;


有什么Bug，需要添加的功能或者建议欢迎提出问题。
