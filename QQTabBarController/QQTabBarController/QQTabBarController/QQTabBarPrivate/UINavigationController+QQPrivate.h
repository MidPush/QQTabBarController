//
//  UINavigationController+QQPrivate.h
//  QQTabBarController
//
//  Created by apple on 2026/2/10.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol UINavigationControllerExtensionDelegate <NSObject>

@required
- (void)qq_navigationController:(UINavigationController *)navigationController
   navigationBarDidChangeHeight:(CGFloat)height;

- (void)qq_navigationController:(UINavigationController *)navigationController
         didBeginTransitionFrom:(UIViewController *)fromVC
                             to:(UIViewController *)toVC
                      operation:(UINavigationControllerOperation)operation;

- (void)qq_navigationController:(UINavigationController *)navigationController
       didUpdateInteractiveFrom:(UIViewController *)fromVC
                             to:(UIViewController *)toVC
                percentComplete:(CGFloat)percentComplete;

- (void)qq_navigationController:(UINavigationController *)navigationController
       didUpdateInteractiveFrom:(UIViewController *)fromVC
                             to:(UIViewController *)toVC
           popGestureRecognizer:(UIGestureRecognizer *)popGestureRecognizer;

- (void)qq_navigationController:(UINavigationController *)navigationController
          willEndTransitionFrom:(UIViewController *)fromVC
                             to:(UIViewController *)toVC
                      operation:(UINavigationControllerOperation)operation
                      cancelled:(BOOL)cancelled;

- (void)qq_navigationController:(UINavigationController *)navigationController
           didEndTransitionFrom:(UIViewController *)fromVC
                             to:(UIViewController *)toVC
                      operation:(UINavigationControllerOperation)operation
                      cancelled:(BOOL)cancelled;

@end

@interface UINavigationController (QQPrivate)

/**
 当有自定义全屏返回手势时，需要设置该值（比如一些第三方实现的全屏返回手势）
 用系统自带pop返回手势，则不用管
 */
@property (nonatomic, strong, nullable) UIGestureRecognizer *qq_customPopGestureRecognizer;

@end

NS_ASSUME_NONNULL_END
