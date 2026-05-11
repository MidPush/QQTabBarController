//
//  YYTabBarController.m
//  YYTabBarController
//
//  Created by apple on 2026/4/24.
//

#import "YYTabBarController.h"
#import <objc/runtime.h>
#import "QQTabBarItem.h"
#import "UINavigationController+QQPrivate.h"
#import "_QQTabBarControllerTransitionAnimator.h"
#import "_QQTabBarControllerTransitionContext.h"
#import "_QQParallaxOverlayView.h"

CGFloat const YYTabBarControllerHideShowBarDuration = 0.2;

@interface YYTabBarController ()<UINavigationControllerExtensionDelegate>

@property (nonatomic, strong) UIView *containerView;

@property (nonatomic, assign, readonly) CGRect tabBarFrame;
@property (nonatomic, strong, readonly) NSMutableArray<QQTabBarItem *> *items;

@end

@implementation YYTabBarController {
    struct {
        unsigned shouldSelectViewController : 1;
        unsigned didSelectViewController : 1;
        unsigned animationControllerForTransition : 1;
        unsigned willShowTabBar : 1;
        unsigned didShowTabBar : 1;
        unsigned willHideTabBar : 1;
        unsigned didHideTabBar : 1;
    } _delegateHas;

    __weak UINavigationController *_nestedNavigationController;
    BOOL _tabBarIsAnimating;
    // 用于记录快速设置tabBar显示和隐藏最后一次的状态
    BOOL _lastShowHideTabBar;
    
    _QQParallaxOverlayView *_parallaxOverlayView;
}

- (instancetype)init {
    if (self = [super init]) {
        // 系统 UITabBarController init 之后就会 loadView，这里和系统保持一致
        [self loadViewIfNeeded];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _tabBarHidden = NO;
    _tabBarHeight = 49.0;
    _selectedIndex = NSNotFound;

    self.containerView.frame = self.view.bounds;
    [self.view addSubview:self.containerView];
    
    _qq_tabBar = [[QQTabBar alloc] initWithFrame:self.tabBarFrame];
    _qq_tabBar.delegate = self;
    [self.view addSubview:self.qq_tabBar];
    
    [self addObserver:self forKeyPath:@"qq_tabBar" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
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

/// 状态栏
- (UIViewController *)childViewControllerForStatusBarStyle {
    return [self _visibleViewController];
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    return [self _visibleViewController];
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return [self _visibleViewController].preferredStatusBarUpdateAnimation;
}

/// HomeIndicator
- (UIViewController *)childViewControllerForHomeIndicatorAutoHidden {
    return [self _visibleViewController];
}

/// 控制器支持方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return [self _visibleViewController].supportedInterfaceOrientations;
}

#pragma mark - UIContentContainer
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    if (!CGSizeEqualToSize(self.view.bounds.size, size)) {
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            [self _updateAdditionalSafeAreaInsets:YES animated:NO];
        } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            
        }];
    }
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

#pragma mark - Getter
- (UIView *)containerView {
    if (!_containerView) {
        _containerView = [[UIView alloc] initWithFrame:self.view.bounds];
        _containerView.backgroundColor = [UIColor clearColor];
        _containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    }
    return _containerView;
}

#pragma mark - Setter
- (void)setDelegate:(id<YYTabBarControllerDelegate>)delegate {
    _delegate = delegate;
    _delegateHas.shouldSelectViewController = [_delegate respondsToSelector:@selector(tabBarController:shouldSelectViewController:)];
    _delegateHas.didSelectViewController = [_delegate respondsToSelector:@selector(tabBarController:didSelectViewController:)];
    _delegateHas.animationControllerForTransition = [_delegate respondsToSelector:@selector(tabBarController:animationControllerForTransitionFromViewController:toViewController:)];
    _delegateHas.willShowTabBar = [_delegate respondsToSelector:@selector(tabBarController:willShowTabBar:)];
    _delegateHas.didShowTabBar = [_delegate respondsToSelector:@selector(tabBarController:didShowTabBar:)];
    _delegateHas.willHideTabBar = [_delegate respondsToSelector:@selector(tabBarController:willHideTabBar:)];
    _delegateHas.didHideTabBar = [_delegate respondsToSelector:@selector(tabBarController:didHideTabBar:)];
}

- (void)setViewControllers:(NSArray<__kindof UIViewController *> *)viewControllers {
    if (viewControllers != nil && viewControllers.count > 0) {
        _viewControllers = [viewControllers copy];
    } else {
        _viewControllers = nil;
        [self _clearHierarchy];
    }
    
    [self _captureItems];
    [self.qq_tabBar setItems:_items];
    
    if (self.selectedIndex == NSNotFound) {
        self.selectedIndex = 0;
    } else {
        self.selectedIndex = MIN(MAX(0, self.selectedIndex), _viewControllers.count - 1);
        if (!_selectedViewController) {
            [self _moveToViewControllerAtIndex:self.selectedIndex];
            _qq_tabBar.selectedItem = _selectedViewController.qq_tabBarItem;
        }
    }
}

- (void)setSelectedViewController:(__kindof UIViewController *)selectedViewController {
    if (!selectedViewController) return;
    if ([self.viewControllers containsObject:selectedViewController]) {
        if (_selectedViewController != selectedViewController) {
            _selectedViewController = selectedViewController;
            NSInteger selectedIndex = [self.viewControllers indexOfObject:selectedViewController];
            self.selectedIndex = selectedIndex;
        }
    } else {
        NSLog(@"-[YYTabBarController setSelectedViewController:] only a view controller in the tab bar controller's list of view controllers can be selected.");
    }
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex {
    if (_selectedIndex != selectedIndex) {
        _selectedIndex = selectedIndex;
        [self _moveToViewControllerAtIndex:selectedIndex];
        _qq_tabBar.selectedItem = _selectedViewController.qq_tabBarItem;
    }
}

- (void)setTabBarHidden:(BOOL)tabBarHidden {
    [self setTabBarHidden:tabBarHidden animated:NO];
}

- (void)setTabBarHidden:(BOOL)hidden animated:(BOOL)animated {
    if (_tabBarIsAnimating) {
        _lastShowHideTabBar = hidden;
        return;
    }
    if (self.qq_tabBar.superview != self.view) return;
    if (_tabBarHidden != hidden) {
        
        _tabBarHidden = hidden;
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
            
            [UIView animateWithDuration:YYTabBarControllerHideShowBarDuration animations:^{
                self.qq_tabBar.transform = endTransform;
            } completion:^(BOOL finished) {
                self.qq_tabBar.transform = CGAffineTransformIdentity;
                self.qq_tabBar.hidden = hidden;
                [self _updateAdditionalSafeAreaInsets:NO animated:animated];
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
            [self _updateAdditionalSafeAreaInsets:NO animated:animated];
            
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

- (void)setTabBarHeight:(CGFloat)tabBarHeight {
    if (_tabBarHeight != tabBarHeight) {
        _tabBarHeight = tabBarHeight;
        [self _updateAdditionalSafeAreaInsets:NO animated:NO];
        [self.view setNeedsLayout];
    }
}

#pragma mark - TabBarItem Action

- (void)_tabBarItemClicked:(QQTabBarItem *)tabBarItem {
    NSInteger index = [self.qq_tabBar.items indexOfObject:tabBarItem];
    if (_delegateHas.shouldSelectViewController) {
        BOOL sholudSelect = [self.delegate tabBarController:self shouldSelectViewController:self.viewControllers[index]];
        if (!sholudSelect) {
            return;
        }
    }
    
    self.selectedIndex = index;
    
    if (_delegateHas.didSelectViewController) {
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
    [self _updateAdditionalSafeAreaInsets:NO animated:NO];
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

- (void)_captureItems {
    NSMutableArray *items = [NSMutableArray array];
    for (UIViewController *viewController in self.viewControllers) {
        [items addObject:viewController.qq_tabBarItem];
    }
    _items = items;
}

- (void)_captureNestedNavigationControllerIfExists {
    UIViewController *viewController = _selectedViewController;
    do {
        if ([viewController isKindOfClass:[UINavigationController class]]) {
            _nestedNavigationController = (UINavigationController *)viewController;
            break;
        }
    } while ((viewController = viewController.childViewControllers.firstObject));
    UIEdgeInsets additionalSafeAreaInsets = viewController.additionalSafeAreaInsets;
    additionalSafeAreaInsets.bottom = self.tabBarHeight;
    viewController.additionalSafeAreaInsets = additionalSafeAreaInsets;
}

- (__kindof UIViewController *_Nullable)_visibleViewController {
    return self.selectedViewController;
}

- (void)_updateAdditionalSafeAreaInsets:(BOOL)shouldLayoutManually animated:(BOOL)animated {
    UIViewController *selectedViewController = self.selectedViewController;
    UIEdgeInsets additionalSafeAreaInsets = selectedViewController.additionalSafeAreaInsets;
    additionalSafeAreaInsets.bottom = self.qq_tabBar.hidden ? 0 : self.tabBarHeight;
    NSTimeInterval duration = animated ? 0.2 : 0;
    [UIView animateWithDuration:duration animations:^{
        selectedViewController.additionalSafeAreaInsets = additionalSafeAreaInsets;
    }];
    if (shouldLayoutManually) {
        [selectedViewController.view setNeedsLayout];
        [selectedViewController.view layoutIfNeeded];
    }
}

- (void)_moveToViewControllerAtIndex:(NSInteger)index {
    NSArray<UIViewController *> *viewControllers = self.viewControllers;
    if (index == NSNotFound || viewControllers.count <= index || !self.isViewLoaded) {
        return;
    }
    
    __kindof UIViewController *sourceViewController = _selectedViewController;
    __kindof UIViewController *destinationViewController = viewControllers[index];
    
    if ([sourceViewController isEqual:destinationViewController]) {
        return;
    }
    
    _selectedViewController = destinationViewController;
    
    [self _captureNestedNavigationControllerIfExists];
    
    [self _updateBottomBarShowHideIfNeeded];
    
    [self _cycleFromSourceViewController:sourceViewController
             toDestinationViewController:destinationViewController
                         completionBlock:nil];
}

- (void)_clearHierarchy {
    __kindof UIViewController *sourceViewController = _selectedViewController;
    if (sourceViewController == nil || !self.isViewLoaded) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [self _cycleFromSourceViewController:sourceViewController toDestinationViewController:nil completionBlock:^{
        if (weakSelf == nil) return;
        typeof(self) strongSelf = weakSelf;
        strongSelf->_selectedViewController = nil;
        strongSelf->_nestedNavigationController = nil;
    }];
}

- (void)_cycleFromSourceViewController:(nullable UIViewController *)sourceViewController
           toDestinationViewController:(nullable UIViewController *)destinationViewController
                       completionBlock:(nullable void(^)(void))completionBlock {
    [sourceViewController willMoveToParentViewController:nil];
    
    if (destinationViewController) {
        destinationViewController.view.frame = self.containerView.bounds;
        [self addChildViewController:destinationViewController];
    }
    
    __weak typeof(self) weakSelf = self;
    
    id<UIViewControllerAnimatedTransitioning> animator;
    
    if (_delegateHas.animationControllerForTransition) {
        animator = [self.delegate tabBarController:self animationControllerForTransitionFromViewController:sourceViewController toViewController:destinationViewController];
    }
    if (!animator) {
        animator = [[_QQTabBarControllerTransitionAnimator alloc] init];
    }
    
    _QQTabBarControllerTransitionContext *transitionContext = [[_QQTabBarControllerTransitionContext alloc] initWithSourceViewController:sourceViewController destinationViewController:destinationViewController containerView:self.containerView];
    transitionContext.animated = YES;
    transitionContext.interactive = NO;
    transitionContext.completionBlock = ^(BOOL didComplete) {
        weakSelf.view.userInteractionEnabled = YES;
        [sourceViewController.view removeFromSuperview];
        [sourceViewController removeFromParentViewController];
        [destinationViewController didMoveToParentViewController:weakSelf];
        [weakSelf setNeedsStatusBarAppearanceUpdate];
        
        if ([animator respondsToSelector:@selector(animationEnded:)]) {
            [animator animationEnded:didComplete];
        }
        
        if (completionBlock) {
            completionBlock();
        }
    };
    
    [animator animateTransition:transitionContext];
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

@implementation UIViewController (YYTabBarControllerItem)

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
    [self.qq_tabBarController _changeItem:oldItem toItem:tabBarItem];

    objc_setAssociatedObject(self, &_qqtabBarItemPropertyKey, tabBarItem, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (YYTabBarController *)qq_tabBarController {
    return [self qq_nearestParentViewControllerThatIsKindOf:[YYTabBarController class]];
}

- (YYTabBarController *)qq_nearestParentViewControllerThatIsKindOf:(Class)c {
    UIViewController *controller = self.parentViewController;
    while (controller && ![controller isKindOfClass:c]) {
        controller = controller.parentViewController;
    }
    if (controller && [controller isKindOfClass:c]) {
        return (YYTabBarController *)controller;
    }
    return nil;
}

@end
