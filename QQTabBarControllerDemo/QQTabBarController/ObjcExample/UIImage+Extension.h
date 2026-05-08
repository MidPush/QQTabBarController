//
//  UIImage+Extension.h
//  QQTabBarController
//
//  Created by apple on 2026/3/2.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (Extension)

+ (UIImage *)qq_imageWithColor:(UIColor *)color size:(CGSize)size;
+ (UIImage *)qq_imageWithColor:(UIColor *)color size:(CGSize)size cornerRadius:(CGFloat)cornerRadius;

@end

NS_ASSUME_NONNULL_END
