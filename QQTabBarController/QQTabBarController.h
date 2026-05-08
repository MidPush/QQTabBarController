//
//  QQTabBarController.h
//  QQTabBarController
//
//  Created by apple on 2026/2/6.
//

#import <UIKit/UIKit.h>
#import "QQTabBar.h"

NS_ASSUME_NONNULL_BEGIN

/**
 继承自 UITabBarController
 永久隐藏系统的 UITabBar，使用 QQTabBar
 优点：支持系统 UITabBarController 大部分属性
 */

@class QQTabBarController;

@protocol QQTabBarControllerDelegate <UITabBarControllerDelegate>

@optional

// tabBar show/hide
- (void)tabBarController:(QQTabBarController *)tabBarController willShowTabBar:(QQTabBar *)tabBar;
- (void)tabBarController:(QQTabBarController *)tabBarController didShowTabBar:(QQTabBar *)tabBar;
- (void)tabBarController:(QQTabBarController *)tabBarController willHideTabBar:(QQTabBar *)tabBar;
- (void)tabBarController:(QQTabBarController *)tabBarController didHideTabBar:(QQTabBar *)tabBar;

@end

@interface QQTabBarController : UITabBarController<QQTabBarDelegate>

// 代理
@property (nonatomic, weak, nullable) id<QQTabBarControllerDelegate> delegate;

// 设置QQTabBar显示或隐藏
@property (nonatomic, assign, getter=isTabBarHidden) BOOL tabBarHidden;
- (void)setTabBarHidden:(BOOL)hidden animated:(BOOL)animated;

@property (nonatomic, readonly) QQTabBar *qq_tabBar;

// tabBar内容高度，默认49.0，真实高度会加上view.safeAreaInsets.bottom安全区域
@property (nonatomic, assign) CGFloat tabBarHeight;

@end

@interface UIViewController (QQTabBarControllerItem)

// 如果未显式设置，则根据视图控制器的标题自动延迟创建
@property (null_resettable, nonatomic, strong) QQTabBarItem *qq_tabBarItem;

@end

NS_ASSUME_NONNULL_END
