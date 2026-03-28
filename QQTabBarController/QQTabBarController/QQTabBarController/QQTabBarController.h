//
//  QQTabBarController.h
//  QQTabBarController
//
//  Created by apple on 2026/2/6.
//

#import <UIKit/UIKit.h>
#import "QQTabBar.h"

NS_ASSUME_NONNULL_BEGIN

@class QQTabBarController;

@protocol QQTabBarControllerDelegate <NSObject>

@optional

// select viewController
- (BOOL)tabBarController:(QQTabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController;
- (void)tabBarController:(QQTabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController;

// tabBar show/hide
- (void)tabBarController:(QQTabBarController *)tabBarController willShowTabBar:(QQTabBar *)tabBar;
- (void)tabBarController:(QQTabBarController *)tabBarController didShowTabBar:(QQTabBar *)tabBar;
- (void)tabBarController:(QQTabBarController *)tabBarController willHideTabBar:(QQTabBar *)tabBar;
- (void)tabBarController:(QQTabBarController *)tabBarController didHideTabBar:(QQTabBar *)tabBar;

// transition
- (nullable id <UIViewControllerAnimatedTransitioning>)tabBarController:(QQTabBarController *)tabBarController
                     animationControllerForTransitionFromViewController:(UIViewController *)fromVC
                                                       toViewController:(UIViewController *)toVC;

@end

@interface QQTabBarController : UIViewController<QQTabBarDelegate>

@property (nonatomic, weak, nullable) id<QQTabBarControllerDelegate> delegate;

// 设置QQTabBar显示或隐藏，和qq_hidesBottomBarWhenPushed好像有点冲突（有问题再说吧）
@property (nonatomic, assign, getter=isTabBarHidden) BOOL tabBarHidden;
- (void)setTabBarHidden:(BOOL)hidden animated:(BOOL)animated;

@property (nullable, nonatomic, copy) NSArray<__kindof UIViewController *> *viewControllers;

@property (nullable, nonatomic, assign) __kindof UIViewController *selectedViewController;
@property (nonatomic) NSUInteger selectedIndex;

@property (nonatomic, readonly) QQTabBar *tabBar;

// tabBar内容高度，默认49.0，真实高度会加上view.safeAreaInsets.bottom安全区域
@property (nonatomic, assign) CGFloat tabBarHeight;

@end

@interface UIViewController (QQTabBarControllerItem)

// 如果未显式设置，则根据视图控制器的标题自动延迟创建
@property (null_resettable, nonatomic, strong) QQTabBarItem *qq_tabBarItem;

// 返回控制器的tabBarController，可能为nil
@property (nullable, nonatomic, readonly, strong) QQTabBarController *qq_tabBarController;

// 系统的逻辑就是，在 push N 个 vc 的过程中，只要其中出现任意一个 vc.hidesBottomBarWhenPushed = YES，则 tabBar 不会再出现（不管后续有没有 vc.hidesBottomBarWhenPushed = NO）
@property (nonatomic, assign) BOOL qq_hidesBottomBarWhenPushed;

@end

NS_ASSUME_NONNULL_END
