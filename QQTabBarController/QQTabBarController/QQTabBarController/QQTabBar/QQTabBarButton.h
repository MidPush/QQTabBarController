//
//  QQTabBarButton.h
//  QQNavTabBarController
//
//  Created by apple on 2026/2/6.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class QQTabBarItem;

@interface QQTabBarButton : UIControl

- (instancetype)initWithTabBarItem:(QQTabBarItem *)tabBarItem;
@property (nonatomic, strong) QQTabBarItem *tabBarItem;
@property (nonatomic, strong, readonly) UIImageView *imageView;
@property (nonatomic, strong, readonly) UILabel *titleLabel;

@end

NS_ASSUME_NONNULL_END
