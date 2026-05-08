//
//  _QQParallaxOverlayView.m
//  QQTabBarController
//
//  Created by apple on 2026/2/10.
//

#import "_QQParallaxOverlayView.h"
#import "QQTabBarController.h"
#import "YYTabBarController.h"

@implementation _QQParallaxOverlayView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    }
    return self;
}

- (UIEdgeInsets)safeAreaInsets {
    UIViewController *currentViewController = [self qq_parallaxCurrentViewController];
    YYTabBarController *customTabBarController = currentViewController.qq_tabBarController;
    if (customTabBarController) {
        return customTabBarController.view.safeAreaInsets;
    }
    UITabBarController *tabBarController = currentViewController.tabBarController;
    if (tabBarController) {
        return tabBarController.view.safeAreaInsets;
    }
    return [super safeAreaInsets];
}

- (UIViewController *)qq_parallaxCurrentViewController {
    UIResponder *next = self.nextResponder;
    do {
        if ([next isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)next;
        }
        next = next.nextResponder;
    } while (next != nil);
    return nil;
}

@end
