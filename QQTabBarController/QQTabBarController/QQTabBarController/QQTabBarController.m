//
//  QQTabBarController.m
//  QQNavTabBarController
//
//  Created by apple on 2026/2/6.
//

#import "QQTabBarController.h"
#import "QQTabBarItem.h"
#import <objc/runtime.h>
#import "_QQTabBarControllerTransitionAnimator.h"
#import "_QQTabBarControllerTransitionContext.h"
#import "UINavigationController+QQPrivate.h"
#import "_QQParallaxOverlayView.h"

CGFloat const QQTabBarControllerHideShowBarDuration = 0.25;

@interface QQTabBarController ()<UINavigationControllerExtensionDelegate>

@property (nonatomic, strong) UIView *containerView;

@property (nonatomic, assign, readonly) CGRect tabBarFrame;
@property (nonatomic, strong, readonly) NSMutableArray<QQTabBarItem *> *items;

@end

@implementation QQTabBarController {
    struct {
        unsigned shouldSelectViewController : 1;
        unsigned didSelectViewController : 1;
        unsigned animationControllerForTransition : 1;
    } _delegateHas;
    
    __weak UINavigationController *_nestedNavigationController;
    BOOL _tabBarIsAnimating;
    
    _QQParallaxOverlayView *_parallaxOverlayView;
}

- (instancetype)init {
    if (self = [super init]) {
        _tabBarHidden = NO;
        _tabBarHeight = 49;
        _selectedIndex = NSNotFound;
        _tabBar = [[QQTabBar alloc] init];
        [self addObserver:self forKeyPath:@"tabBar" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)loadView {
    [super loadView];
    self.containerView.frame = self.view.bounds;
    [self.view addSubview:self.containerView];

    self.tabBar.frame = self.tabBarFrame;
    [self.view addSubview:self.tabBar];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
}

#pragma mark - Observe
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"tabBar"]) {
        QQTabBar *oldTabBar = change[NSKeyValueChangeOldKey];
        [oldTabBar removeFromSuperview];
        
        QQTabBar *newTabBar = change[NSKeyValueChangeNewKey];
        _tabBar = newTabBar;
        if (newTabBar) {
            [self.view addSubview:newTabBar];
            [self.view setNeedsLayout];
        }
    }
}

- (void)dealloc { 
    [self removeObserver:self forKeyPath:@"tabBar"];
}

#pragma mark Overrides
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (!_tabBarIsAnimating && !CGRectEqualToRect(self.tabBar.frame, self.tabBarFrame) && self.tabBar.superview == self.view) {
        self.tabBar.frame = self.tabBarFrame;
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
    return [[self _visibleViewController] preferredStatusBarUpdateAnimation];
}

/// HomeIndicator
- (UIViewController *)childViewControllerForHomeIndicatorAutoHidden {
    return [self _visibleViewController];
}

/// 控制器支持方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return [self _visibleViewController].supportedInterfaceOrientations;
}

#pragma mark UIContentContainer
- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
}

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
- (void)setDelegate:(id<QQTabBarControllerDelegate>)delegate {
    _delegate = delegate;
    _delegateHas.shouldSelectViewController = [_delegate respondsToSelector:@selector(tabBarController:shouldSelectViewController:)];
    _delegateHas.didSelectViewController = [_delegate respondsToSelector:@selector(tabBarController:didSelectViewController:)];
    _delegateHas.animationControllerForTransition = [_delegate respondsToSelector:@selector(tabBarController:animationControllerForTransitionFromViewController:toViewController:)];
}

- (void)setViewControllers:(NSArray<__kindof UIViewController *> *)viewControllers {
    if (_viewControllers != nil && _viewControllers.count > 0) {
        [self _processViewControllersWithValue:nil];
    }
    
    if (viewControllers != nil && viewControllers.count > 0) {
        _viewControllers = [viewControllers copy];
        [self _captureItems];
        [self _processViewControllersWithValue:self];
    } else {
        _viewControllers = nil;
        [self _clearHierarchy];
    }
    
    [self.tabBar setItems:_items];
    
    if (self.selectedIndex == NSNotFound) {
        self.selectedIndex = 0;
    } else {
        self.selectedIndex = MIN(MAX(0, self.selectedIndex), _viewControllers.count - 1);
        if (!_selectedViewController) {
            [self _moveToViewControllerAtIndex:self.selectedIndex];
            _tabBar.selectedItem = _selectedViewController.qq_tabBarItem;
        }
    }
}

- (void)setSelectedViewController:(__kindof UIViewController *)selectedViewController {
    if (!selectedViewController) return;
    if ([self.viewControllers containsObject:selectedViewController]) {
        _selectedViewController = selectedViewController;
        NSInteger selectedIndex = [self.viewControllers indexOfObject:selectedViewController];
        self.selectedIndex = selectedIndex;
    } else {
        NSLog(@"-[QQTabBarController setSelectedViewController:] only a view controller in the tab bar controller's list of view controllers can be selected.");
    }
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex {
    if (_selectedIndex != selectedIndex) {
        _selectedIndex = selectedIndex;
        [self _moveToViewControllerAtIndex:selectedIndex];
        _tabBar.selectedItem = _selectedViewController.qq_tabBarItem;
    }
}

- (void)setTabBarHidden:(BOOL)tabBarHidden {
    [self setTabBarHidden:tabBarHidden animated:NO];
}

- (void)setTabBarHidden:(BOOL)hide animated:(BOOL)animated {
    if (_tabBarIsAnimating) return;
    if (_tabBarHidden != hide) {
        _tabBarHidden = hide;
        
        if ([_selectedViewController isKindOfClass:[UINavigationController class]]) {
            UIViewController *topViewController = [(UINavigationController *)_selectedViewController topViewController];
            BOOL canShowTabBar = (topViewController == [self _shouldShowsBottomBarViewController:(UINavigationController *)_selectedViewController] && !topViewController.qq_hidesBottomBarWhenPushed);
            if (!canShowTabBar) {
                hide = YES;
                animated = NO;
            }
        }
        
        if (animated) {
            _tabBarIsAnimating = YES;
            CGAffineTransform startTransform = hide? CGAffineTransformIdentity : CGAffineTransformMakeTranslation(0, _tabBar.frame.size.height);
            CGAffineTransform endTransform = hide? CGAffineTransformMakeTranslation(0, _tabBar.frame.size.height) : CGAffineTransformIdentity;

            _tabBar.transform = startTransform;
            _tabBar.hidden = NO;
        
            [UIView animateWithDuration:QQTabBarControllerHideShowBarDuration animations:^{
                self.tabBar.transform = endTransform;
            } completion:^(BOOL finished) {
                self.tabBar.transform = CGAffineTransformIdentity;
                self.tabBar.hidden = hide;
                [self _updateAdditionalSafeAreaInsets:NO animated:animated];
                self->_tabBarIsAnimating = NO;
            }];
        } else {
            _tabBar.hidden = hide;
            [self _updateAdditionalSafeAreaInsets:NO animated:animated];
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

#pragma mark - UINavigationControllerExtensionDelegate
- (void)qq_navigationController:(UINavigationController *)navigationController
   navigationBarDidChangeHeight:(CGFloat)height {
    
}

- (void)qq_navigationController:(UINavigationController *)navigationController
         didBeginTransitionFrom:(UIViewController *)fromVC
                             to:(UIViewController *)toVC
                      operation:(UINavigationControllerOperation)operation {
    UIEdgeInsets additionalSafeAreaInsets = UIEdgeInsetsMake(0.0, 0.0, self.tabBarHeight, 0.0);
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
          willEndTransitionFrom:(UIViewController *)fromVC
                             to:(UIViewController *)toVC
                      operation:(UINavigationControllerOperation)operation
                      cancelled:(BOOL)cancelled {
    
    BOOL tabBarWillHidden = NO;
    if (self.isTabBarHidden) {
        tabBarWillHidden = YES;
    } else {
        if (operation == UINavigationControllerOperationPop) {
            // Pop
            if (toVC == [self _shouldShowsBottomBarViewController:navigationController]) {
                if (!toVC.qq_hidesBottomBarWhenPushed && fromVC.qq_hidesBottomBarWhenPushed && self.tabBar.hidden) {
                    [self _addParallaxOverlayViewToViewController:toVC];
                }
            }
        } else {
            // Push
            if (fromVC == [self _shouldShowsBottomBarViewController:navigationController]) {
                if (toVC.qq_hidesBottomBarWhenPushed && !fromVC.qq_hidesBottomBarWhenPushed) {
                    [self _addParallaxOverlayViewToViewController:fromVC];
                }
            }
        }
        
        if (cancelled) {
            if (!fromVC.qq_hidesBottomBarWhenPushed && fromVC == [self _shouldShowsBottomBarViewController:navigationController]) {
                tabBarWillHidden = NO;
            } else {
                tabBarWillHidden = YES;
            }
        } else {
            if (!toVC.qq_hidesBottomBarWhenPushed && toVC == [self _shouldShowsBottomBarViewController:navigationController]) {
                tabBarWillHidden = NO;
            } else {
                tabBarWillHidden = YES;
            }
        }
    }
    
    UIEdgeInsets additionalSafeAreaInsets = UIEdgeInsetsZero;
    if (!tabBarWillHidden) {
        additionalSafeAreaInsets = UIEdgeInsetsMake(0.0, 0.0, self.tabBarHeight, 0.0);
    }
    if (navigationController.transitionCoordinator) {
        [UIView performWithoutAnimation:^{
            self.selectedViewController.additionalSafeAreaInsets = additionalSafeAreaInsets;
        }];
    } else {
        self.selectedViewController.additionalSafeAreaInsets = additionalSafeAreaInsets;
    }
}

- (void)qq_navigationController:(UINavigationController *)navigationController
           didEndTransitionFrom:(UIViewController *)fromVC
                             to:(UIViewController *)toVC
                      operation:(UINavigationControllerOperation)operation
                      cancelled:(BOOL)cancelled {
    if (_parallaxOverlayView) {
        [_parallaxOverlayView removeFromSuperview];
        _parallaxOverlayView = nil;
    }
    
    if (self.tabBar.superview != self.view) {
        self.tabBar.frame = self.tabBarFrame;
        [self.view addSubview:self.tabBar];
    }
    
    if (self.isTabBarHidden) {
        self.tabBar.hidden = YES;
        [self _updateAdditionalSafeAreaInsets:NO animated:NO];
        return;
    }
    if (cancelled) {
        if (!fromVC.qq_hidesBottomBarWhenPushed && fromVC == [self _shouldShowsBottomBarViewController:navigationController]) {
            self.tabBar.hidden = NO;
        } else {
            self.tabBar.hidden = YES;
        }
    } else {
        if (!toVC.qq_hidesBottomBarWhenPushed && toVC == [self _shouldShowsBottomBarViewController:navigationController]) {
            self.tabBar.hidden = NO;
        } else {
            self.tabBar.hidden = YES;
        }
    }
    [self _updateAdditionalSafeAreaInsets:NO animated:NO];
}

#pragma mark - Private

- (CGRect)tabBarFrame {
    CGFloat tabBarHeight = _tabBarHeight + self.view.safeAreaInsets.bottom;
    return CGRectMake(0, CGRectGetHeight(self.view.bounds) - tabBarHeight, CGRectGetWidth(self.view.bounds), tabBarHeight);
}

- (UIViewController *)_shouldShowsBottomBarViewController:(UINavigationController *)navigationController {
    NSInteger showsBottomBarIndex = -1;
    for (NSInteger index = 0; index < navigationController.viewControllers.count; index++) {
        UIViewController *viewController = navigationController.viewControllers[index];
        if (viewController.qq_hidesBottomBarWhenPushed) {
            showsBottomBarIndex = index - 1;
            break;
        } else {
            showsBottomBarIndex = index;
        }
    }
    UIViewController *showsBottomBarViewController = nil;
    if (showsBottomBarIndex >= 0) {
        showsBottomBarViewController = navigationController.viewControllers[showsBottomBarIndex];
    }
    return showsBottomBarViewController;
}

- (void)_addParallaxOverlayViewToViewController:(UIViewController *)viewController {
    // create overlayView
    UIView *superview = viewController.view.superview;
    if (!superview) {
        superview = viewController.view;
    }
    
    if (!_parallaxOverlayView) {
        _parallaxOverlayView = [[_QQParallaxOverlayView alloc] initWithFrame:superview.bounds];
    }
    [superview addSubview:_parallaxOverlayView];
    [superview bringSubviewToFront:_parallaxOverlayView];
    
    if (self.tabBar.superview != _parallaxOverlayView) {
        self.tabBar.frame = self.tabBarFrame;
        self.tabBar.hidden = NO;
        [_parallaxOverlayView addSubview:self.tabBar];
    }
}

- (void)_processViewControllersWithValue:(id)value {
    for (UIViewController *viewController in self.viewControllers) {
        [self _processViewControllerChildren:viewController withValue:value];
    }
}

- (void)_processViewControllerChildren:(__kindof UIViewController *)viewController
                             withValue:(id)value {
    for (UIViewController *childViewController in viewController.childViewControllers) {
        [self _processViewControllerChildren:childViewController withValue:value];
    }

    [viewController setValue:value forKey:NSStringFromSelector(@selector(qq_tabBarController))];
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
    
    _nestedNavigationController.additionalSafeAreaInsets = UIEdgeInsetsMake(0.0, 0.0, self.tabBarHeight, 0.0);
}

- (__kindof UIViewController *_Nullable)_visibleViewController {
    return _nestedNavigationController != nil ? _nestedNavigationController.visibleViewController : self.selectedViewController;
}

- (void)_updateAdditionalSafeAreaInsets:(BOOL)shouldLayoutManually animated:(BOOL)animated {
    UIViewController *selectedViewController = self.selectedViewController;
    UIEdgeInsets additionalSafeAreaInsets = UIEdgeInsetsZero;
    if (!self.tabBar.hidden) {
        additionalSafeAreaInsets = UIEdgeInsetsMake(0.0, 0.0, self.tabBarHeight, 0.0);
    }
    NSTimeInterval duration = animated ? 0.25 : 0;
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
    [self.tabBar setItems:_items];
}

@end

@implementation UIViewController (QQTabBarControllerItem)

static char *_qqtabBarItemPropertyKey;
static char *_qqtabBarControllerPropertyKey;
static char *_qqtabBarControllerCategoryHidesTabBarWhenPushedKey;

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

    objc_setAssociatedObject(self,
                             &_qqtabBarItemPropertyKey,
                             tabBarItem,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (QQTabBarController *)qq_tabBarController {
    return objc_getAssociatedObject(self, &_qqtabBarControllerPropertyKey);
}

- (void)setQq_tabBarController:(QQTabBarController * _Nullable)qq_tabBarController {
    objc_setAssociatedObject(self, &_qqtabBarControllerPropertyKey, qq_tabBarController, OBJC_ASSOCIATION_ASSIGN);
}

- (BOOL)qq_hidesBottomBarWhenPushed {
    return [(NSNumber *)objc_getAssociatedObject(self, &_qqtabBarControllerCategoryHidesTabBarWhenPushedKey) boolValue];
}

- (void)setQq_hidesBottomBarWhenPushed:(BOOL)qq_hidesBottomBarWhenPushed {
    objc_setAssociatedObject(self, &_qqtabBarControllerCategoryHidesTabBarWhenPushedKey, @(qq_hidesBottomBarWhenPushed), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
