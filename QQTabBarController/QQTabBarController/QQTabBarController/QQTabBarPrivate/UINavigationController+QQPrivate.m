//
//  UINavigationController+QQPrivate.m
//  QQNavTabBarController
//
//  Created by apple on 2026/2/10.
//

#import "UINavigationController+QQPrivate.h"
#import "QQTabBarController.h"
#import <objc/runtime.h>

void _QQSwizzleMethod(Class class, SEL originalSelector, SEL swizzledSelector) {
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    BOOL const success = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    if (success) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

@interface UINavigationController ()

// UINavigationController扩展代理
@property (nonatomic, weak) id<UINavigationControllerExtensionDelegate> extensionDelegate;
// 是否嵌套在QQTabBarController中
@property (nonatomic, assign) BOOL nestedInQQTabBarController;
// 标志导航控制器Pop手势是否注册
@property (nonatomic, assign) BOOL interactivePopGestureRecognizerRegistered;

@end

@implementation UINavigationController (QQPrivate)

static char *qq_nestedInQQTabBarControllerKey;
static char *qq_interactivePopGestureRecognizerRegisteredKey;
static char *qq_navControllerExtensionDelegateKey;

#pragma mark Getters & Setters
- (id<UINavigationControllerExtensionDelegate>)extensionDelegate {
    return objc_getAssociatedObject(self, &qq_navControllerExtensionDelegateKey);
}

- (void)setExtensionDelegate:(id<UINavigationControllerExtensionDelegate>)extensionDelegate {
    objc_setAssociatedObject(self, &qq_navControllerExtensionDelegateKey, extensionDelegate, OBJC_ASSOCIATION_ASSIGN);
}

- (BOOL)nestedInQQTabBarController {
    return [(NSNumber *)objc_getAssociatedObject(self, &qq_nestedInQQTabBarControllerKey) boolValue];
}

- (void)setNestedInQQTabBarController:(BOOL)nestedInQQTabBarController {
    objc_setAssociatedObject(self, &qq_nestedInQQTabBarControllerKey, @(nestedInQQTabBarController), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)interactivePopGestureRecognizerRegistered {
    return [(NSNumber *)objc_getAssociatedObject(self, &qq_interactivePopGestureRecognizerRegisteredKey) boolValue];
}

- (void)setInteractivePopGestureRecognizerRegistered:(BOOL)interactivePopGestureRecognizerRegistered {
    objc_setAssociatedObject(self, &qq_interactivePopGestureRecognizerRegisteredKey, @(interactivePopGestureRecognizerRegistered), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - 主流程
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _QQSwizzleMethod([self class],
                         @selector(popViewControllerAnimated:),
                         @selector(qq_popViewControllerAnimated:));
        
        _QQSwizzleMethod([self class],
                         @selector(popToViewController:animated:),
                         @selector(qq_popToViewController:animated:));
        
        _QQSwizzleMethod([self class],
                         @selector(popToRootViewControllerAnimated:),
                         @selector(qq_popToRootViewControllerAnimated:));
        
        _QQSwizzleMethod([self class],
                         @selector(pushViewController:animated:),
                         @selector(qq_pushViewController:animated:));
        
        _QQSwizzleMethod([self class],
                         @selector(setViewControllers:animated:),
                         @selector(qq_setViewControllers:animated:));
        
        _QQSwizzleMethod([self class],
                         @selector(didMoveToParentViewController:),
                         @selector(qq_didMoveToParentViewController:));
        
        _QQSwizzleMethod([self class],
                         @selector(viewDidLayoutSubviews),
                         @selector(qq_viewDidLayoutSubviews));
    });
}

#pragma mark - Pop
- (UIViewController *)qq_popViewControllerAnimated:(BOOL)animated {
    UIViewController *previousViewController = [self qq_popViewControllerAnimated:animated];
    if (!self.nestedInQQTabBarController) {
        return previousViewController;
    }
    
    [previousViewController setValue:nil forKey:NSStringFromSelector(@selector(qq_tabBarController))];
    [self _popViewController:previousViewController toViewController:self.topViewController animated:animated];
    return previousViewController;
}

- (NSArray<__kindof UIViewController *> *)qq_popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    NSArray<__kindof UIViewController *> *viewControllers = [self qq_popToViewController:viewController animated:animated];
    if (!self.nestedInQQTabBarController) {
        return viewControllers;
    }
    UIViewController *previousViewController = self.topViewController;
    for (UIViewController *viewController in viewControllers) {
        [viewController setValue:nil forKey:NSStringFromSelector(@selector(qq_tabBarController))];
    }
    [self _popViewController:previousViewController toViewController:viewController animated:animated];
    return viewControllers;
}

- (NSArray<__kindof UIViewController *> *)qq_popToRootViewControllerAnimated:(BOOL)animated {
    NSArray<__kindof UIViewController *> *viewControllers = [self qq_popToRootViewControllerAnimated:animated];
    if (!self.nestedInQQTabBarController) {
        return viewControllers;
    }
    UIViewController *previousViewController = self.topViewController;
    for (UIViewController *viewController in viewControllers) {
        [viewController setValue:nil forKey:NSStringFromSelector(@selector(qq_tabBarController))];
    }
    [self _popViewController:previousViewController toViewController:self.topViewController animated:animated];
    return viewControllers;
}

#pragma mark - Push
- (void)qq_pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (!self.nestedInQQTabBarController) {
        [self qq_pushViewController:viewController animated:animated];
        return;
    }
    
    UIViewController *previousViewController = self.topViewController;
    [viewController setValue:previousViewController.qq_tabBarController forKey:NSStringFromSelector(@selector(qq_tabBarController))];
    [self qq_pushViewController:viewController animated:animated];
    
    if (@available(iOS 26.0, *)) {
        if (self.interactivePopGestureRecognizerRegistered == NO && self.interactiveContentPopGestureRecognizer != nil) {
            [self _registerPopGestureRecognizer:self.interactiveContentPopGestureRecognizer];
        }
    } else {
        if (self.interactivePopGestureRecognizerRegistered == NO && self.interactivePopGestureRecognizer != nil) {
            [self _registerPopGestureRecognizer:self.interactivePopGestureRecognizer];
        }
    }
    
    [self _pushViewController:previousViewController toViewController:viewController animated:animated];
}

- (void)qq_setViewControllers:(NSArray<UIViewController *> *)viewControllers animated:(BOOL)animated {
    if (!self.nestedInQQTabBarController) {
        [self qq_setViewControllers:viewControllers animated:animated];
        return;
    }
    
    UIViewController *previousViewController = self.topViewController;
    UIViewController *toViewController = viewControllers.lastObject;
    
    // TODO: 这里判断是Push还是Pop不知道准不准确
    BOOL isPush = NO;
    if (![self.viewControllers containsObject:toViewController]) {
        isPush = YES;
    }
    
    for (UIViewController *viewController in viewControllers) {
        [viewController setValue:previousViewController.qq_tabBarController forKey:NSStringFromSelector(@selector(qq_tabBarController))];
    }
    
    if (isPush) {
        [self _pushViewController:previousViewController toViewController:viewControllers.lastObject animated:animated];
    } else {
        [self _popViewController:previousViewController toViewController:viewControllers.lastObject animated:animated];
    }
    [self qq_setViewControllers:viewControllers animated:animated];
}

- (void)qq_didMoveToParentViewController:(nullable UIViewController *)parent {
    [self qq_didMoveToParentViewController:parent];
    
    if (parent == nil && self.nestedInQQTabBarController) {
        if (@available(iOS 26.0, *)) {
            [self.interactiveContentPopGestureRecognizer removeTarget:self action:@selector(_popGestureRecognizerHandler:)];
        } else {
            [self.interactivePopGestureRecognizer removeTarget:self action:@selector(_popGestureRecognizerHandler:)];
        }
        self.nestedInQQTabBarController = NO;
        self.extensionDelegate = nil;
        self.interactivePopGestureRecognizerRegistered = NO;
    } else if ([parent isKindOfClass:[QQTabBarController class]]) {
        self.extensionDelegate = (id<UINavigationControllerExtensionDelegate>)parent;
        self.nestedInQQTabBarController = YES;
        [self _updateNavigationBarHeight];
    }
}

- (void)qq_viewDidLayoutSubviews {
    [self qq_viewDidLayoutSubviews];
    if (self.nestedInQQTabBarController) {
        [self _updateNavigationBarHeight];
    }
}

#pragma mark - Gestures
- (void)_registerPopGestureRecognizer:(__kindof UIGestureRecognizer *)popGestureRecognizer {
    if (popGestureRecognizer) {
        [popGestureRecognizer addTarget:self action:@selector(_popGestureRecognizerHandler:)];
        self.interactivePopGestureRecognizerRegistered = YES;
    }
}

- (void)_popGestureRecognizerHandler:(UIPanGestureRecognizer *)popGestureRecognizer {
    if (popGestureRecognizer.state == UIGestureRecognizerStateEnded) return;
    CGFloat const translation = [popGestureRecognizer translationInView:self.view].x;
    if (translation == 0.0) return;
    CGFloat const completed = MAX(0.0, MIN(1.0, translation / CGRectGetWidth(self.view.bounds)));
    [self.extensionDelegate qq_navigationController:self
                           didUpdateInteractiveFrom:[self.transitionCoordinator viewControllerForKey:UITransitionContextFromViewControllerKey]
                                                 to:self.topViewController
                                    percentComplete:completed];
}

#pragma mark - Helpers
- (void)_pushViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC animated:(BOOL)animated {
    
    id<UIViewControllerTransitionCoordinator> transitionCoordinator = self.transitionCoordinator;
    
    [self.extensionDelegate qq_navigationController:self
                             didBeginTransitionFrom:fromVC
                                                 to:toVC
                                          operation:UINavigationControllerOperationPush];
    if (transitionCoordinator) {
        __weak typeof(self) weakSelf = self;
        [transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            if (weakSelf == nil) return;
            typeof(self) strongSelf = weakSelf;
            [strongSelf.extensionDelegate qq_navigationController:strongSelf
                                            willEndTransitionFrom:fromVC
                                                               to:toVC
                                                        operation:UINavigationControllerOperationPush
                                                        cancelled:context.isCancelled];
        } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            if (weakSelf == nil) return;
            typeof(self) strongSelf = weakSelf;
            [strongSelf.extensionDelegate qq_navigationController:strongSelf
                                             didEndTransitionFrom:fromVC
                                                               to:toVC
                                                        operation:UINavigationControllerOperationPush
                                                        cancelled:context.isCancelled];
        }];
    } else {
        if (animated) {
            [UIView animateWithDuration:0.35 delay:0.0 options:7 << 16 animations:^{
                [self.extensionDelegate qq_navigationController:self
                                          willEndTransitionFrom:fromVC
                                                             to:toVC
                                                      operation:UINavigationControllerOperationPush
                                                      cancelled:NO];
            } completion:^(BOOL finished) {
                [self.extensionDelegate qq_navigationController:self
                                           didEndTransitionFrom:fromVC
                                                             to:toVC
                                                      operation:UINavigationControllerOperationPush
                                                      cancelled:NO];
            }];
        } else {
            [self.extensionDelegate qq_navigationController:self
                                      willEndTransitionFrom:fromVC
                                                         to:toVC
                                                  operation:UINavigationControllerOperationPush
                                                  cancelled:NO];
            [self.extensionDelegate qq_navigationController:self
                                       didEndTransitionFrom:fromVC
                                                         to:toVC
                                                  operation:UINavigationControllerOperationPush
                                                  cancelled:NO];
        }
    }
}

- (void)_popViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC animated:(BOOL)animated {
    id<UIViewControllerTransitionCoordinator> transitionCoordinator = self.transitionCoordinator;
    
    [self.extensionDelegate qq_navigationController:self
                             didBeginTransitionFrom:fromVC
                                                 to:toVC
                                          operation:UINavigationControllerOperationPop];
    if (transitionCoordinator) {
        __weak typeof(self) weakSelf = self;
        [transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            if (weakSelf == nil) return;
            typeof(self) strongSelf = weakSelf;
            [strongSelf.extensionDelegate qq_navigationController:strongSelf
                                            willEndTransitionFrom:fromVC
                                                               to:toVC
                                                        operation:UINavigationControllerOperationPop
                                                        cancelled:context.isCancelled];
            
        } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            if (weakSelf == nil) return;
            typeof(self) strongSelf = weakSelf;
            [strongSelf.extensionDelegate qq_navigationController:strongSelf
                                             didEndTransitionFrom:fromVC
                                                               to:toVC
                                                        operation:UINavigationControllerOperationPop
                                                        cancelled:context.isCancelled];
            if (context.isCancelled) {
                [fromVC setValue:toVC.qq_tabBarController forKey:NSStringFromSelector(@selector(qq_tabBarController))];
            }
        }];
    } else {
        if (animated) {
            [UIView animateWithDuration:0.35 delay:0.0 usingSpringWithDamping:1.0 initialSpringVelocity:1.0 options:7 << 16 animations:^{
                [self.extensionDelegate qq_navigationController:self
                                          willEndTransitionFrom:fromVC
                                                             to:toVC
                                                      operation:UINavigationControllerOperationPop
                                                      cancelled:NO];
            } completion:^(BOOL finished) {
                [self.extensionDelegate qq_navigationController:self
                                           didEndTransitionFrom:fromVC
                                                             to:toVC
                                                      operation:UINavigationControllerOperationPop
                                                      cancelled:NO];
            }];
        } else {
            [self.extensionDelegate qq_navigationController:self
                                      willEndTransitionFrom:fromVC
                                                         to:toVC
                                                  operation:UINavigationControllerOperationPop
                                                  cancelled:NO];
            [self.extensionDelegate qq_navigationController:self
                                       didEndTransitionFrom:fromVC
                                                         to:toVC
                                                  operation:UINavigationControllerOperationPop
                                                  cancelled:NO];
        }
    }
}

- (void)_updateNavigationBarHeight {
    CGFloat value = 0.0;
    for (UIView *subview in self.navigationBar.subviews) {
        if ([NSStringFromClass([subview class]) containsString:@"ContentView"]) {
            value = CGRectGetMaxY(subview.frame);
            break;
        }
    }
    [self.extensionDelegate qq_navigationController:self navigationBarDidChangeHeight:value + self.view.safeAreaInsets.top];
}

@end
