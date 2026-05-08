//
//  QQTabBarButton.h
//  QQTabBarController
//
//  Created by apple on 2026/2/6.
//

#import <UIKit/UIKit.h>
#import "QQTabBarItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface QQTabBarButton : UIControl

- (instancetype)initWithTabBarItem:(QQTabBarItem *)tabBarItem;
@property (nonatomic, strong) QQTabBarItem *tabBarItem;
@property (nonatomic, strong, readonly) UIImageView *imageView;
@property (nonatomic, strong, readonly) UILabel *titleLabel;

@end

NS_ASSUME_NONNULL_END
