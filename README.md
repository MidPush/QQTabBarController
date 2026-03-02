# QQTabBarController
自定义 Custom UITabBarController

QQTabBarController和系统UITabBarController使用方法类似，QQTabBar可以高度自定义，能更方便实现自己想要的效果。
![ezgif-1425f158295fd9b0](https://github.com/user-attachments/assets/90768d58-8a75-4654-8608-a1bcd3dd5baa)


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
