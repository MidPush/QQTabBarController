//
//  NNTabBarController.m
//  QQTabBarController
//
//  Created by apple on 2026/2/6.
//

#import "NNTabBarController.h"
#import "TableViewController.h"
#import "NNTabBar.h"
#import "ModalViewController.h"
#import "UIImage+Extension.h"

@interface NNTabBarController ()<QQTabBarControllerDelegate, QQTabBarDelegate>


@end

@implementation NNTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    // 可以通过KVC自定义QQTabBar
    NNTabBar *tabBar = [[NNTabBar alloc] init];
    [self setValue:tabBar forKey:@"tabBar"];
    
    self.delegate = self;
    self.tabBar.delegate = self;
    self.tabBar.barTintColor = [UIColor whiteColor];
    self.tabBar.shadowImage = [UIImage qq_imageWithColor:[UIColor.separatorColor colorWithAlphaComponent:0.5] size:CGSizeMake(1, 1)];
    
    NSMutableArray<UIViewController *> *viewControllers = [NSMutableArray array];
    NSArray *titles = @[@"首页", @"同城", @"发布", @"消息", @"我的"];
    NSArray *images = @[@"home_normal", @"fishpond_normal", @"post_highlight", @"message_normal" ,@"account_normal"];
    NSArray *selectedImages = @[@"home_highlight", @"fishpond_highlight", @"post_highlight", @"message_highlight", @"account_highlight"];
    for (NSInteger i = 0; i < titles.count; i++) {
        TableViewController *vc = [[TableViewController alloc] init];
        vc.title = titles[i];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self setupChildViewController:nav title:titles[i] imageName:images[i] selectedImageName:selectedImages[i]];
        if (i == 0) {
            nav.qq_tabBarItem.badgeValue = @"1";
        } else if (i == 1) {
            nav.qq_tabBarItem.badgeValue = @"11";
            nav.qq_tabBarItem.badgeColor = UIColor.systemBlueColor;
        } else if (i == 2) {
            nav.qq_tabBarItem.imagePositionAdjustment = UIOffsetMake(0, -12);
        } else if (i == 3) {
            nav.qq_tabBarItem.badgeValue = @"新消息";
            [nav.qq_tabBarItem setBadgeTextAttributes:@{NSForegroundColorAttributeName:UIColor.greenColor} forState:UIControlStateNormal];
        } else if (i == 4) {
            // 设置badgeSize不为CGSizeZero、badgeValue为nil，就变成一个点了
            nav.qq_tabBarItem.badgeValue = nil;
            nav.qq_tabBarItem.badgeSize = CGSizeMake(10, 10);
            nav.qq_tabBarItem.badgeColor = UIColor.systemRedColor;
        }
        [viewControllers addObject:nav];
    }
    self.viewControllers = viewControllers;
}

- (void)setupChildViewController:(UIViewController *)childVC title:(NSString *)title imageName:(NSString *)imageName selectedImageName:(NSString *)selectedImageName {
    childVC.qq_tabBarItem.title = title;
    childVC.qq_tabBarItem.image = [UIImage imageNamed:imageName];
    childVC.qq_tabBarItem.selectedImage = [UIImage imageNamed:selectedImageName];
    [childVC.qq_tabBarItem setTitleTextAttributes:@{NSForegroundColorAttributeName:UIColor.systemYellowColor} forState:UIControlStateSelected];
}

#pragma mark - QQTabBarControllerDelegate
- (BOOL)tabBarController:(QQTabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    NSInteger index = [tabBarController.viewControllers indexOfObject:viewController];
    [self springAnimationForView:self.tabBar.tabBarButtons[index].imageView];
    if (index == 2) {
        return NO;
    }
    return YES;
}

- (void)tabBarController:(QQTabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    // 选择了 viewController
}

- (nullable id <UIViewControllerAnimatedTransitioning>)tabBarController:(QQTabBarController *)tabBarController
                     animationControllerForTransitionFromViewController:(UIViewController *)fromVC
                                                       toViewController:(UIViewController *)toVC {
    // 这里可以自定义转场动画
    return nil;
}

#pragma mark - QQTabBarDelegate
- (void)tabBar:(QQTabBar *)tabBar didSelectItem:(nonnull QQTabBarItem *)item {
    NSInteger index = [tabBar.items indexOfObject:item];
    if (index == 2) {
        ModalViewController *vc = [[ModalViewController alloc] init];
        [self presentViewController:vc animated:YES completion:nil];
        return;
    }
    BOOL isBlackTheme = (index == 4);
    NSDictionary *titleTextAttributes = isBlackTheme ? @{NSForegroundColorAttributeName:UIColor.whiteColor} : @{NSForegroundColorAttributeName:UIColor.grayColor};
    UIColor *barTintColor = isBlackTheme ? UIColor.blackColor : UIColor.whiteColor;
    self.tabBar.barTintColor = barTintColor;
    for (UIViewController *viewController in self.viewControllers) {
        [viewController.qq_tabBarItem setTitleTextAttributes:titleTextAttributes forState:UIControlStateNormal];
    }
}
 
#pragma mark - Spring Animation
static NSString *const QQSpringAnimationKey = @"QQSpringAnimationKey";
- (void)springAnimationForView:(UIView *)view {
    if (!view || ![view isKindOfClass:[UIView class]]) return;
    [self removeSpringAnimationForView:view];
    NSTimeInterval duration = 0.6;
    CAKeyframeAnimation *springAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    springAnimation.values = @[@.85, @1.15, @.9, @1.0,];
    springAnimation.keyTimes = @[@(0.0 / duration), @(0.15 / duration) , @(0.3 / duration), @(0.45 / duration),];
    springAnimation.duration = duration;
    [view.layer addAnimation:springAnimation forKey:QQSpringAnimationKey];
}

- (void)removeSpringAnimationForView:(UIView *)view {
    if (!view || ![view isKindOfClass:[UIView class]]) return;
    [view.layer removeAnimationForKey:QQSpringAnimationKey];
}

@end
