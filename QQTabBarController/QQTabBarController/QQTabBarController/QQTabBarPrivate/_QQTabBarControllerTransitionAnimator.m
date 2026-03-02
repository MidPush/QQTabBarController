//
//  _QQTabBarControllerTransitionAnimator.m
//  QQNavTabBarController
//
//  Created by apple on 2026/2/6.
//

#import "_QQTabBarControllerTransitionAnimator.h"

@implementation _QQTabBarControllerTransitionAnimator

#pragma mark - UIViewControllerAnimatedTransitioning

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *destinationViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    [transitionContext.containerView addSubview:destinationViewController.view];
    [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.0;
}

@end
