//
//  NNTabBar.m
//  QQNavTabBarController
//
//  Created by apple on 2026/2/12.
//

#import "NNTabBar.h"

@implementation NNTabBar

// 如果imageView超出TabBar范围，增加imageView响应区域
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.hidden || !self.userInteractionEnabled || self.alpha < 0.01) {
        return [super hitTest:point withEvent:event];
    }
    for (QQTabBarButton *button in self.tabBarButtons) {
        CGRect imageRect = [button.imageView convertRect:button.imageView.bounds toView:self];
        if (CGRectContainsPoint(button.frame, point) || CGRectContainsPoint(imageRect, point)) {
            return button;
        }
    }
    return [super hitTest:point withEvent:event];
}

@end
