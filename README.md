# QQTabBarController
自定义 Custom UITabBarController

QQTabBarController和系统UITabBarController使用方法类似，QQTabBar可以高度自定义，能更方便实现自己想要的效果。

<img width="480" height="auto" alt="Simulator Screenshot - iPhone 17 Pro - 2026-03-02 at 11 49 22" src="https://github.com/user-attachments/assets/01b38301-4a3f-4379-a6dd-15db47c82c76" />


# 1. 使用QQTabBarController（继承自系统 UITabBarController）时：

UIViewController *vc = [[UIViewController alloc] init];  <br>

vc.tabBarItem = nil;  <br>
vc.tabBarController.tabBar; <br>

替换成：  <br>

vc.qq_tabBarItem = nil;  <br>
vc.tabBarController.qq_tabBar; <br>

# 2. 使用YYTabBarController（完全自定义实现，继承自 UIViewController）时：

UIViewController *vc = [[UIViewController alloc] init];  <br>
vc.tabBarItem = nil;  <br>
vc.tabBarController.tabBar; <br>
vc.tabBarController;  <br>

替换成：  <br>

vc.qq_tabBarItem = nil;  <br>
vc.qq_tabBarController.qq_tabBar; <br>
vc.qq_tabBarController;  <br>


有什么Bug，需要添加的功能或者建议欢迎提出问题。
