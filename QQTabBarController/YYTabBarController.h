//
//  YYTabBarController.h
//  QQTabBarController
//
//  Created by apple on 2026/4/24.
//

#import <UIKit/UIKit.h>
#import "QQTabBar.h"

NS_ASSUME_NONNULL_BEGIN

/**
 继承自 UIViewController
 完全自定义实现的 UITabBarController
 优点：更加灵活，能实现更多自定义内容
 
 不支持 moreNavigationController，系统 UITabBarController 超过5个子控制器会显示 moreNavigationController
 如果超过5个子控制器，但不想显示 moreNavigationController，可以使用 YYTabBarController
 */

@class YYTabBarController;

@protocol YYTabBarControllerDelegate <NSObject>

@optional

// select viewController
- (BOOL)tabBarController:(YYTabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController;
- (void)tabBarController:(YYTabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController;

// tabBar show/hide
- (void)tabBarController:(YYTabBarController *)tabBarController willShowTabBar:(QQTabBar *)tabBar;
- (void)tabBarController:(YYTabBarController *)tabBarController didShowTabBar:(QQTabBar *)tabBar;
- (void)tabBarController:(YYTabBarController *)tabBarController willHideTabBar:(QQTabBar *)tabBar;
- (void)tabBarController:(YYTabBarController *)tabBarController didHideTabBar:(QQTabBar *)tabBar;

// transition
- (nullable id <UIViewControllerAnimatedTransitioning>)tabBarController:(YYTabBarController *)tabBarController
                     animationControllerForTransitionFromViewController:(UIViewController *)fromVC
                                                       toViewController:(UIViewController *)toVC;

@end

@interface YYTabBarController : UIViewController<QQTabBarDelegate>

// 代理
@property (nonatomic, weak, nullable) id<YYTabBarControllerDelegate> delegate;

/**
 设置QQTabBar显示或隐藏
 如果设置了 hidesBottomBarWhenPushed，则 hidesBottomBarWhenPushed 优先级更高
 系统的 tabBarHidden 和 hidesBottomBarWhenPushed 也是乱七八糟，不知道什么原理
 */
@property (nonatomic, assign, getter=isTabBarHidden) BOOL tabBarHidden;
- (void)setTabBarHidden:(BOOL)hidden animated:(BOOL)animated;

@property (nullable, nonatomic, copy) NSArray<__kindof UIViewController *> *viewControllers;

@property (nullable, nonatomic, assign) __kindof UIViewController *selectedViewController;
@property (nonatomic) NSUInteger selectedIndex;

@property (nonatomic, readonly) QQTabBar *qq_tabBar;

// tabBar内容高度，默认49.0，真实高度会加上view.safeAreaInsets.bottom安全区域
@property (nonatomic, assign) CGFloat tabBarHeight;

@end

@interface UIViewController (YYTabBarControllerItem)

// 如果未显式设置，则根据视图控制器的标题自动延迟创建
@property (null_resettable, nonatomic, strong) QQTabBarItem *qq_tabBarItem;

// 返回控制器的tabBarController，可能为nil
@property (nullable, nonatomic, readonly, strong) YYTabBarController *qq_tabBarController;

@end

NS_ASSUME_NONNULL_END
