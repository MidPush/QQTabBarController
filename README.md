# QQTabBarController
自定义 Custom UITabBarController

QQTabBarController和系统UITabBarController使用方法类似，QQTabBar可以高度自定义，能更方便实现自己想要的效果。

<img width="1206" height="2622" alt="Simulator Screenshot - iPhone 17 Pro - 2026-03-02 at 11 49 22" src="https://github.com/user-attachments/assets/01b38301-4a3f-4379-a6dd-15db47c82c76" />


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
