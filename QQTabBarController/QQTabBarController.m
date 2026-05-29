//
//  QQTabBarController.m
//  QQTabBarController
//
//  Created by apple on 2026/2/6.
//

#import "QQTabBarController.h"
#import <objc/runtime.h>
#import "QQTabBarItem.h"
#import "UINavigationController+QQPrivate.h"
#import "_QQParallaxOverlayView.h"

CGFloat const QQTabBarControllerHideShowBarDuration = 0.2;

@interface QQHideTabBar : UITabBar
@end

@implementation QQHideTabBar
- (void)setHidden:(BOOL)hidden {
    hidden = YES;
    [super setHidden:hidden];
}
@end

@interface QQTabBarController ()<UINavigationControllerExtensionDelegate>

@property (nonatomic, assign, readonly) CGRect tabBarFrame;
@property (nonatomic, strong, readonly) NSMutableArray<QQTabBarItem *> *items;

@property (nonatomic, assign) BOOL qq_tabBarHidden;

@end

@implementation QQTabBarController {
    struct {
        unsigned willShowTabBar : 1;
        unsigned didShowTabBar : 1;
        unsigned willHideTabBar : 1;
        unsigned didHideTabBar : 1;
    } _delegateHas;
    
    BOOL _tabBarIsAnimating;
    // 用于记录快速设置tabBar显示和隐藏最后一次的状态
    BOOL _lastShowHideTabBar;
    BOOL _needsReloadItems;
    
    _QQParallaxOverlayView *_parallaxOverlayView;
}

@dynamic delegate;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 通过KVC 换成 QQHideTabBar，控制系统 UITabBar 永久隐藏
    QQHideTabBar *tabBar = [[QQHideTabBar alloc] init];
    @try {
        [self setValue:tabBar forKey:@"tabBar"];
    } @catch (NSException *exception) {
        NSLog(@"%@ KVC异常：%@", NSStringFromClass(self.class), exception.reason);
    }
    
    // 添加自定义的 QQTabBar
    _qq_tabBarHidden = NO;
    _tabBarHeight = 49.0;
    _qq_tabBar = [[QQTabBar alloc] initWithFrame:self.tabBarFrame];
    _qq_tabBar.delegate = self;
    [self.view addSubview:self.qq_tabBar];
    
    [self addObserver:self forKeyPath:@"qq_tabBar" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];

    [self setTabBarHidden:NO];
    [self _updateAdditionalSafeAreaInsetsWithAnimated:NO];
}

#pragma mark - Observe
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"qq_tabBar"]) {
        QQTabBar *oldTabBar = change[NSKeyValueChangeOldKey];
        [oldTabBar removeFromSuperview];
        
        QQTabBar *newTabBar = change[NSKeyValueChangeNewKey];
        newTabBar.delegate = self;
        newTabBar.items = oldTabBar.items;
        newTabBar.selectedItem = oldTabBar.selectedItem;
        _qq_tabBar = newTabBar;
        if (newTabBar) {
            [self.view addSubview:newTabBar];
            [self.view setNeedsLayout];
        }
    }
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"qq_tabBar"];
}

#pragma mark - Overrides
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (!_tabBarIsAnimating && !CGRectEqualToRect(self.qq_tabBar.frame, self.tabBarFrame) && self.qq_tabBar.superview == self.view) {
        self.qq_tabBar.frame = self.tabBarFrame;
    }
}

- (BOOL)isTabBarHidden {
    return _qq_tabBarHidden;
}

- (void)setTabBarHidden:(BOOL)tabBarHidden {
    [self setTabBarHidden:tabBarHidden animated:NO];
}

- (void)setTabBarHidden:(BOOL)hidden animated:(BOOL)animated {
    // 隐藏系统 tabBar
    if (@available(iOS 18.0, *)) {
        [super setTabBarHidden:YES animated:animated];
    } else {
        self.tabBar.hidden = YES;
    }
    
    if (_tabBarIsAnimating) {
        _lastShowHideTabBar = hidden;
        return;
    }
    if (self.qq_tabBar.superview != self.view) return;
    if (_qq_tabBarHidden != hidden) {
        
        _qq_tabBarHidden = hidden;
        _lastShowHideTabBar = hidden;
        
        if (self.qq_tabBar.hidden == hidden) {
            return;
        }

        BOOL canShowsBottomBar = [self _checkHidesBottomBarWhenPushed];
        if (!canShowsBottomBar) {
            // 让 hidesBottomBarWhenPushed 优先级更高
            return;
        }
        
        if (animated) {
            _tabBarIsAnimating = YES;

            if (hidden) {
                if (_delegateHas.willHideTabBar) {
                    [self.delegate tabBarController:self willHideTabBar:self.qq_tabBar];
                }
            } else {
                if (_delegateHas.willShowTabBar) {
                    [self.delegate tabBarController:self willShowTabBar:self.qq_tabBar];
                }
            }
            
            CGAffineTransform startTransform = hidden? CGAffineTransformIdentity : CGAffineTransformMakeTranslation(0, _qq_tabBar.frame.size.height);
            CGAffineTransform endTransform = hidden? CGAffineTransformMakeTranslation(0, _qq_tabBar.frame.size.height) : CGAffineTransformIdentity;
            _qq_tabBar.transform = startTransform;
            _qq_tabBar.hidden = NO;
            
            [UIView animateWithDuration:QQTabBarControllerHideShowBarDuration animations:^{
                self.qq_tabBar.transform = endTransform;
            } completion:^(BOOL finished) {
                self.qq_tabBar.transform = CGAffineTransformIdentity;
                self.qq_tabBar.hidden = hidden;
                [self _updateAdditionalSafeAreaInsetsWithAnimated:animated];
                self->_tabBarIsAnimating = NO;
                
                if (hidden) {
                    if (self->_delegateHas.didHideTabBar) {
                        [self.delegate tabBarController:self didHideTabBar:self.qq_tabBar];
                    }
                } else {
                    if (self->_delegateHas.didShowTabBar) {
                        [self.delegate tabBarController:self didShowTabBar:self.qq_tabBar];
                    }
                }
                
                if (self->_lastShowHideTabBar != hidden) {
                    // 动画结束，如果和最后一次设置显隐状态不一致，使其显示正确的状态，主要解决快速设置bug（两次设置时间间隔<0.2s）
                    [self setTabBarHidden:self->_lastShowHideTabBar animated:animated];
                }
            }];
        } else {
            if (hidden) {
                if (_delegateHas.willHideTabBar) {
                    [self.delegate tabBarController:self willHideTabBar:self.qq_tabBar];
                }
            } else {
                if (_delegateHas.willShowTabBar) {
                    [self.delegate tabBarController:self willShowTabBar:self.qq_tabBar];
                }
            }
            
            _qq_tabBar.hidden = hidden;
            [self _updateAdditionalSafeAreaInsetsWithAnimated:animated];
            
            if (hidden) {
                if (_delegateHas.didHideTabBar) {
                    [self.delegate tabBarController:self didHideTabBar:self.qq_tabBar];
                }
            } else {
                if (_delegateHas.didShowTabBar) {
                    [self.delegate tabBarController:self didShowTabBar:self.qq_tabBar];
                }
            }
        }
    }
}

- (void)setDelegate:(id<QQTabBarControllerDelegate>)delegate {
    [super setDelegate:delegate];
    _delegateHas.willShowTabBar = [delegate respondsToSelector:@selector(tabBarController:willShowTabBar:)];
    _delegateHas.didShowTabBar = [delegate respondsToSelector:@selector(tabBarController:didShowTabBar:)];
    _delegateHas.willHideTabBar = [delegate respondsToSelector:@selector(tabBarController:willHideTabBar:)];
    _delegateHas.didHideTabBar = [delegate respondsToSelector:@selector(tabBarController:didHideTabBar:)];
}

- (void)setViewControllers:(NSArray<__kindof UIViewController *> *)viewControllers {
    _needsReloadItems = YES;
    [super setViewControllers:viewControllers];
    if (_needsReloadItems) {
        [self _captureItems];
        [self.qq_tabBar setItems:_items];
        _needsReloadItems = NO;
    }
    self.qq_tabBar.selectedItem = self.selectedViewController.qq_tabBarItem;
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex {
    if (self.selectedIndex != selectedIndex) {
        [super setSelectedIndex:selectedIndex];
        if (selectedIndex < 0 || selectedIndex >= self.viewControllers.count) return;
        if (_needsReloadItems) {
            [self _captureItems];
            [self.qq_tabBar setItems:_items];
            _needsReloadItems = NO;
        }
        if ([self _showsMoreNavigationController]) {
            NSInteger moreIndex = [self.tabBar.items indexOfObject:self.moreNavigationController.tabBarItem];
            if (selectedIndex >= moreIndex) {
                self.qq_tabBar.selectedItem = self.moreNavigationController.qq_tabBarItem;
            } else {
                self.qq_tabBar.selectedItem = self.selectedViewController.qq_tabBarItem;
            }
        } else {
            self.qq_tabBar.selectedItem = self.selectedViewController.qq_tabBarItem;
        }
        [self _updateBottomBarShowHideIfNeeded];
    }
}

- (void)setSelectedViewController:(__kindof UIViewController *)selectedViewController {
    if (self.selectedViewController != selectedViewController) {
        [super setSelectedViewController:selectedViewController];
        NSInteger selectedIndex = [self.viewControllers indexOfObject:selectedViewController];
        if ([self _showsMoreNavigationController]) {
            NSInteger moreIndex = [self.tabBar.items indexOfObject:self.moreNavigationController.tabBarItem];
            if (selectedIndex >= moreIndex) {
                self.qq_tabBar.selectedItem = self.moreNavigationController.qq_tabBarItem;
            } else {
                self.qq_tabBar.selectedItem = selectedViewController.qq_tabBarItem;
            }
        } else {
            self.qq_tabBar.selectedItem = selectedViewController.qq_tabBarItem;
        }
        [self _updateBottomBarShowHideIfNeeded];
    }
}

/// 状态栏
- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.selectedViewController;
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    return self.selectedViewController;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return self.selectedViewController.preferredStatusBarUpdateAnimation;
}

/// HomeIndicator
- (UIViewController *)childViewControllerForHomeIndicatorAutoHidden {
    return self.selectedViewController;
}

/// 控制器支持方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return self.selectedViewController.supportedInterfaceOrientations;
}

#pragma mark - UIContentContainer
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    if (!CGSizeEqualToSize(self.view.bounds.size, size)) {
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            [self _updateAdditionalSafeAreaInsetsWithAnimated:NO];
            [self.selectedViewController.view setNeedsLayout];
            [self.selectedViewController.view layoutIfNeeded];
        } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            
        }];
    }
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

#pragma mark - Setter
- (void)setTabBarHeight:(CGFloat)tabBarHeight {
    if (_tabBarHeight != tabBarHeight) {
        _tabBarHeight = tabBarHeight;
        [self _updateAdditionalSafeAreaInsetsWithAnimated:NO];
        [self.view setNeedsLayout];
    }
}

#pragma mark - TabBarItem Action

- (void)_qqtabBarItemClicked:(QQTabBarItem *)tabBarItem {
    NSInteger index = [self.qq_tabBar.items indexOfObject:tabBarItem];
    if ([self.delegate respondsToSelector:@selector(tabBarController:shouldSelectViewController:)]) {
        BOOL sholudSelect = [self.delegate tabBarController:self shouldSelectViewController:self.viewControllers[index]];
        if (!sholudSelect) {
            return;
        }
    }
    
    self.selectedIndex = index;
    
    if ([self.delegate respondsToSelector:@selector(tabBarController:didSelectViewController:)]) {
        [self.delegate tabBarController:self didSelectViewController:self.viewControllers[index]];
    }
}

#pragma mark - UINavigationControllerExtensionDelegate
- (void)qq_navigationController:(UINavigationController *)navigationController
   navigationBarDidChangeHeight:(CGFloat)height {
    
}

- (void)qq_navigationController:(UINavigationController *)navigationController
         didBeginTransitionFrom:(UIViewController *)fromVC
                             to:(UIViewController *)toVC
                      operation:(UINavigationControllerOperation)operation {
    // 转场或pop手势返回时禁止用户交互
    self.view.userInteractionEnabled = NO;
    UIEdgeInsets additionalSafeAreaInsets = self.selectedViewController.additionalSafeAreaInsets;
    additionalSafeAreaInsets.bottom = self.tabBarHeight;
    [UIView performWithoutAnimation:^{
        self.selectedViewController.additionalSafeAreaInsets = additionalSafeAreaInsets;
        if ([self _showsMoreNavigationController] && self.moreNavigationController != self.selectedViewController) {
            self.moreNavigationController.additionalSafeAreaInsets = additionalSafeAreaInsets;
        }
    }];
}

- (void)qq_navigationController:(UINavigationController *)navigationController
       didUpdateInteractiveFrom:(UIViewController *)fromVC
                             to:(UIViewController *)toVC
                percentComplete:(CGFloat)percentComplete {
//     NSLog(@"pop手势返回：%.2f", percentComplete);
}


- (void)qq_navigationController:(UINavigationController *)navigationController
       didUpdateInteractiveFrom:(UIViewController *)fromVC
                             to:(UIViewController *)toVC
           popGestureRecognizer:(UIGestureRecognizer *)popGestureRecognizer {
    
}

- (void)qq_navigationController:(UINavigationController *)navigationController
          willEndTransitionFrom:(UIViewController *)fromVC
                             to:(UIViewController *)toVC
                      operation:(UINavigationControllerOperation)operation
                      cancelled:(BOOL)cancelled {
    BOOL showsTabBar = [self _shouldShowsBottomBar];
    if (operation == UINavigationControllerOperationPush) {
        if (!showsTabBar && !self.qq_tabBar.hidden) {
            [self _addParallaxOverlayViewToViewController:fromVC];
        }
    } else {
        if (showsTabBar && self.qq_tabBar.hidden) {
            [self _addParallaxOverlayViewToViewController:toVC];
        }
    }
    
    UIEdgeInsets additionalSafeAreaInsets = self.selectedViewController.additionalSafeAreaInsets;
    additionalSafeAreaInsets.bottom = showsTabBar ? self.tabBarHeight : 0;
    [UIView performWithoutAnimation:^{
        self.selectedViewController.additionalSafeAreaInsets = additionalSafeAreaInsets;
        if ([self _showsMoreNavigationController] && self.moreNavigationController != self.selectedViewController) {
            self.moreNavigationController.additionalSafeAreaInsets = additionalSafeAreaInsets;
        }
    }];
}

- (void)qq_navigationController:(UINavigationController *)navigationController
           didEndTransitionFrom:(UIViewController *)fromVC
                             to:(UIViewController *)toVC
                      operation:(UINavigationControllerOperation)operation
                      cancelled:(BOOL)cancelled {
    self.view.userInteractionEnabled = YES;
    if (_parallaxOverlayView) {
        [_parallaxOverlayView removeFromSuperview];
        _parallaxOverlayView = nil;
    }
    
    if (self.qq_tabBar.superview != self.view) {
        self.qq_tabBar.frame = self.tabBarFrame;
        [self.view addSubview:self.qq_tabBar];
    }
    
    [self _updateBottomBarShowHideIfNeeded];
}

#pragma mark - Private
- (CGRect)tabBarFrame {
    CGFloat tabBarHeight = _tabBarHeight + self.view.safeAreaInsets.bottom;
    return CGRectMake(0, CGRectGetHeight(self.view.bounds) - tabBarHeight, CGRectGetWidth(self.view.bounds), tabBarHeight);
}

- (BOOL)_showsMoreNavigationController {
    // 用 self.viewControllers.count > 5 判断行不行？
    return [self.tabBar.items containsObject:self.moreNavigationController.tabBarItem];
}

- (void)_captureItems {
    BOOL hasMoreItem = [self _showsMoreNavigationController];
    NSMutableArray *items = [NSMutableArray array];
    if (hasMoreItem) {
        for (NSInteger i = 0; i < self.tabBar.items.count - 1; i++) {
            UIViewController *viewController = self.viewControllers[i];
            [items addObject:viewController.qq_tabBarItem];
        }
        QQTabBarItem *moreItem = self.moreNavigationController.qq_tabBarItem;
        UITabBarItem *systemMoreItem = self.moreNavigationController.tabBarItem;
        if (moreItem.title.length == 0 && systemMoreItem.title.length < 0) {
            moreItem.title = systemMoreItem.title;
        }
        if (!moreItem.image && systemMoreItem.image) {
            moreItem.image = systemMoreItem.image;
        }
        if (!moreItem.selectedImage && systemMoreItem.selectedImage) {
            moreItem.selectedImage = systemMoreItem.selectedImage;
        }
        [items addObject:moreItem];
    } else {
        for (UIViewController *viewController in self.viewControllers) {
            [items addObject:viewController.qq_tabBarItem];
        }
    }
    [self _syncSystemItems];
    _items = items;
}

- (void)_syncSystemItems {
    for (UIViewController *viewController in self.viewControllers) {
        viewController.tabBarItem.title = viewController.qq_tabBarItem.title;
        viewController.tabBarItem.image = viewController.qq_tabBarItem.image;
        viewController.tabBarItem.badgeValue = viewController.qq_tabBarItem.badgeValue;
        viewController.tabBarItem.badgeColor = viewController.qq_tabBarItem.badgeColor;
        viewController.tabBarItem.titlePositionAdjustment = viewController.qq_tabBarItem.titlePositionAdjustment;
        [viewController.tabBarItem setTitleTextAttributes:[viewController.qq_tabBarItem titleTextAttributesForState:UIControlStateNormal] forState:UIControlStateNormal];
        [viewController.tabBarItem setTitleTextAttributes:[viewController.qq_tabBarItem titleTextAttributesForState:UIControlStateSelected] forState:UIControlStateSelected];
    }
}

- (BOOL)_shouldShowsBottomBar {
    BOOL showsTabBar = YES;
    if (self.isTabBarHidden) {
        showsTabBar = NO;
    } else {
        showsTabBar = [self _checkHidesBottomBarWhenPushed];
    }
    return showsTabBar;
}

- (BOOL)_checkHidesBottomBarWhenPushed {
    BOOL showsTabBar = YES;
    UIViewController *selectedViewController = self.selectedViewController;
    if ([self _showsMoreNavigationController]) {
        NSInteger moreIndex = [self.tabBar.items indexOfObject:self.moreNavigationController.tabBarItem];
        if (self.selectedIndex >= moreIndex || self.selectedIndex == NSNotFound) {
            selectedViewController = self.moreNavigationController;
        }
    }
    if ([selectedViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)selectedViewController;
        NSInteger currentIndex = [navigationController.viewControllers indexOfObject:navigationController.topViewController];
        NSInteger showsBottomBarIndex = -1;
        for (NSInteger index = 0; index < navigationController.viewControllers.count; index++) {
            UIViewController *viewController = navigationController.viewControllers[index];
            if (viewController.hidesBottomBarWhenPushed) {
                showsBottomBarIndex = index - 1;
                break;
            } else {
                showsBottomBarIndex = index;
            }
        }
        if (currentIndex <= showsBottomBarIndex) {
            showsTabBar = YES;
        } else {
            showsTabBar = NO;
        }
    } else if ([selectedViewController isKindOfClass:[UIViewController class]]) {
        showsTabBar = !selectedViewController.hidesBottomBarWhenPushed;
    }
    return showsTabBar;
}

- (void)_updateBottomBarShowHideIfNeeded {
    BOOL showsTabBar = [self _shouldShowsBottomBar];
    if (!_tabBarIsAnimating) {
        self.qq_tabBar.hidden = !showsTabBar;
    }
    [self _updateAdditionalSafeAreaInsetsWithAnimated:NO];
}

- (void)_addParallaxOverlayViewToViewController:(UIViewController *)viewController {
    // create overlayView
    UIView *superview = viewController.view;
    if (!_parallaxOverlayView) {
        _parallaxOverlayView = [[_QQParallaxOverlayView alloc] initWithFrame:superview.bounds];
    }
    [superview addSubview:_parallaxOverlayView];
    [superview bringSubviewToFront:_parallaxOverlayView];
    
    if (self.qq_tabBar.superview != _parallaxOverlayView) {
        if (!_tabBarIsAnimating) {
            self.qq_tabBar.frame = self.tabBarFrame;
        }
        self.qq_tabBar.hidden = NO;
        [_parallaxOverlayView addSubview:self.qq_tabBar];
    }
}

- (void)_updateAdditionalSafeAreaInsetsWithAnimated:(BOOL)animated {
    UIViewController *selectedViewController = self.selectedViewController;
    UIEdgeInsets additionalSafeAreaInsets = selectedViewController.additionalSafeAreaInsets;
    additionalSafeAreaInsets.bottom = self.qq_tabBar.hidden ? 0 : self.tabBarHeight;
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            selectedViewController.additionalSafeAreaInsets = additionalSafeAreaInsets;
            if ([self _showsMoreNavigationController] && self.moreNavigationController != selectedViewController) {
                self.moreNavigationController.additionalSafeAreaInsets = additionalSafeAreaInsets;
            }
        }];
    } else {
        selectedViewController.additionalSafeAreaInsets = additionalSafeAreaInsets;
        if ([self _showsMoreNavigationController] && self.moreNavigationController != selectedViewController) {
            self.moreNavigationController.additionalSafeAreaInsets = additionalSafeAreaInsets;
        }
    }
}

- (void)_changeItem:(QQTabBarItem *)item toItem:(QQTabBarItem *)toItem {
    NSInteger index = [_items indexOfObject:item];
    if (index == NSNotFound) {
        return;
    }
    [_items replaceObjectAtIndex:index withObject:toItem];
    [self.qq_tabBar setItems:_items];
}

@end

@implementation UIViewController (QQTabBarControllerItem)

static char *_qqtabBarItemPropertyKey;

- (QQTabBarItem *)qq_tabBarItem {
    QQTabBarItem *item = objc_getAssociatedObject(self, &_qqtabBarItemPropertyKey);
    if (!item) {
        NSString *title = item.title ?: self.title;
        item = [[QQTabBarItem alloc] initWithTitle:title image:item.image selectedImage:item.selectedImage];
        objc_setAssociatedObject(self, &_qqtabBarItemPropertyKey, item, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return item;
}

- (void)setQq_tabBarItem:(QQTabBarItem *)tabBarItem {
    if (tabBarItem == nil) {
        tabBarItem = [[QQTabBarItem alloc] initWithTitle:self.title image:nil];
    }
    
    QQTabBarItem *oldItem = self.qq_tabBarItem;
    
    if ([self.tabBarController isKindOfClass:[QQTabBarController class]]) {
        QQTabBarController *tabBarController = (QQTabBarController *)self.tabBarController;
        [tabBarController _changeItem:oldItem toItem:tabBarItem];
    }
    
    objc_setAssociatedObject(self, &_qqtabBarItemPropertyKey, tabBarItem, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


