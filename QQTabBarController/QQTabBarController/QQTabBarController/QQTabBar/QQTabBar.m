//
//  QQTabBar.m
//  QQNavTabBarController
//
//  Created by apple on 2026/2/6.
//

#import "QQTabBar.h"
#import "QQTabBarItem.h"
#import "QQTabBarController.h"

@interface QQTabBar ()

// _UIBackground
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIVisualEffectView *backgroundEffectView;
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIImageView *shadowImageView;

@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, weak, readonly) QQTabBarController *tabBarController;

@end

@implementation QQTabBar {
    NSInteger _selectedItemIndex;
    NSMutableArray *_buttons;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_tabBarItemDidChange:) name:QQTabBarItemDidChange object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_tabBarItemDidChange:(NSNotification *)note {
    if (_items == nil || _items.count == 0) return;
    QQTabBarItem *changedItem = [note object];
    NSInteger itemIndex = [_items indexOfObject:changedItem];
    if (itemIndex != NSNotFound) {
        QQTabBarButton *tabBarButton = _buttons[itemIndex];
        tabBarButton.tabBarItem = changedItem;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self _updateLayout];
}

- (void)commonInit {
    _selectedItemIndex = -1;
    _buttons = [NSMutableArray array];
    
    _backgroundView = [[UIView alloc] init];
    [self addSubview:_backgroundView];
    
    _backgroundImageView = [[UIImageView alloc] init];
    [_backgroundView addSubview:_backgroundImageView];
    
    _contentView = [[UIView alloc] init];
    [self addSubview:_contentView];
    
    self.barTintColor = [UIColor clearColor];
    self.tintColor = [UIColor systemBlueColor];
    _useLayoutSafeAreaInsets = YES;
}

#pragma mark - Setter & Getter

- (NSArray<QQTabBarButton *> *)tabBarButtons {
    return [_buttons copy];
}

- (void)setItems:(NSArray<QQTabBarItem *> *)items {
    if (![_items isEqualToArray:items]) {
        if (self.selectedItem && ![items containsObject:self.selectedItem]) {
            _selectedItemIndex = -1;
        }
        _items = [items copy];
        [self _reloadItems];
    }
}

- (void)setSelectedItem:(QQTabBarItem *)selectedItem {
    if (!selectedItem) return;
    NSInteger index = [self.items indexOfObject:selectedItem];
    if (index != NSNotFound && _selectedItemIndex != index) {
        [self _setSelectedIndex:index];
    }
}

- (QQTabBarItem *)selectedItem {
    if (_selectedItemIndex >= 0) {
        return [_items objectAtIndex:_selectedItemIndex];
    }
    return nil;
}

- (void)setTintColor:(UIColor *)tintColor {
    if (_tintColor != tintColor) {
        _tintColor = tintColor;
        for (QQTabBarButton *button in _buttons) {
            button.tintColor = tintColor;
        }
    }
}

- (void)setBarTintColor:(UIColor *)barTintColor {
    if (_barTintColor != barTintColor) {
        _barTintColor = barTintColor;
        _backgroundImageView.backgroundColor = barTintColor;
        if (!_backgroundImage && barTintColor) {
            if (!_backgroundEffectView) {
                UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleProminent];
                _backgroundEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            }
            [_backgroundView insertSubview:_backgroundEffectView atIndex:0];
        } else {
            if (_backgroundEffectView) {
                [_backgroundEffectView removeFromSuperview];
                _backgroundEffectView = nil;
            }
        }
        [self setNeedsLayout];
    }
}

- (void)setBackgroundImage:(UIImage *)backgroundImage {
    if (_backgroundImage != backgroundImage) {
        _backgroundImage = backgroundImage;
        _backgroundImageView.image = backgroundImage;
        if (backgroundImage) {
            if (_backgroundEffectView) {
                [_backgroundEffectView removeFromSuperview];
                _backgroundEffectView = nil;
            }
            [self setNeedsLayout];
        } else {
            self.barTintColor = self.barTintColor;
        }
    }
}

- (void)setShadowImage:(UIImage *)shadowImage {
    if (_shadowImage != shadowImage) {
        _shadowImage = shadowImage;
        if (shadowImage) {
            if (!_shadowImageView) {
                _shadowImageView = [[UIImageView alloc] init];
            }
            _shadowImageView.image = shadowImage;
            [_backgroundView addSubview:_shadowImageView];
        } else {
            if (_shadowImageView) {
                [_shadowImageView removeFromSuperview];
                _shadowImageView = nil;
            }
        }
        [self setNeedsLayout];
    }
}

- (void)setUseLayoutSafeAreaInsets:(BOOL)useLayoutSafeAreaInsets {
    if (_useLayoutSafeAreaInsets != useLayoutSafeAreaInsets) {
        _useLayoutSafeAreaInsets = useLayoutSafeAreaInsets;
        [self setNeedsLayout];
    }
}

#pragma mark - Private

- (void)_tabBarDidSelectButton:(QQTabBarButton *)tabBarButton {
    NSInteger selectedIndex = [_buttons indexOfObject:tabBarButton];
    QQTabBarItem *item = self.items[selectedIndex];
    if (!item.isEnabled) return;
    
    NSInteger prevSelectedIndex = _selectedItemIndex;
    [self _setSelectedIndex:selectedIndex];
    
    if ([self.delegate respondsToSelector:@selector(tabBar:didSelectItem:)]) {
        [self.delegate tabBar:self didSelectItem:item];
    }
    
    if (self.tabBarController) {
        if ([self.tabBarController.delegate respondsToSelector:@selector(tabBarController:shouldSelectViewController:)]) {
            BOOL sholudSelect = [self.tabBarController.delegate tabBarController:self.tabBarController shouldSelectViewController:self.tabBarController.viewControllers[selectedIndex]];
            if (!sholudSelect) {
                [self _setSelectedIndex:prevSelectedIndex];
                return;
            }
        }
        self.tabBarController.selectedIndex = selectedIndex;
        if ([self.tabBarController.delegate respondsToSelector:@selector(tabBarController:didSelectViewController:)]) {
            [self.tabBarController.delegate tabBarController:self.tabBarController didSelectViewController:self.tabBarController.viewControllers[selectedIndex]];
        }
    }
}

- (QQTabBarController *)tabBarController {
    if (self.superview) {
        UIResponder *responder = self.superview.nextResponder;
        if ([responder isKindOfClass:[QQTabBarController class]]) {
            QQTabBarController *tabBarController = (QQTabBarController *)responder;
            return tabBarController;
        }
    }
    return nil;
}

- (void)_reloadItems {
    // remove old
    for (QQTabBarButton *button in _buttons) {
        [button removeFromSuperview];
    }
    [_buttons removeAllObjects];
    
    // add tabBarButton
    for (NSInteger index = 0; index < self.items.count; index++) {
        QQTabBarItem *item = self.items[index];
        QQTabBarButton *button = [[QQTabBarButton alloc] initWithTabBarItem:item];
        button.tintColor = self.tintColor;
        button.selected = (item == self.selectedItem);
        [button addTarget:self action:@selector(_tabBarDidSelectButton:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView insertSubview:button atIndex:0];
        [_buttons addObject:button];
    }
    
    [self setNeedsLayout];
}

- (void)_setSelectedIndex:(NSInteger)selectedIndex {
    if (_selectedItemIndex != selectedIndex) {
        NSInteger prevSelectedIndex = _selectedItemIndex;
        NSInteger newSelectedIndex = selectedIndex;
        _selectedItemIndex = selectedIndex;
        if (prevSelectedIndex >= 0) {
            QQTabBarButton *prevButton = _buttons[prevSelectedIndex];
            prevButton.selected = NO;
        }
        if (newSelectedIndex >= 0) {
            QQTabBarButton *nextButton = _buttons[newSelectedIndex];
            nextButton.selected = YES;
        }
    }
}

- (void)_updateLayout {
    if (CGRectIsEmpty(self.bounds)) {
        return;
    }
    
    // background
    _backgroundView.frame = self.bounds;
    
    _backgroundImageView.frame = _backgroundView.bounds;
    if (_backgroundEffectView) {
        _backgroundEffectView.frame = _backgroundView.bounds;
    }
    
    if (_shadowImageView) {
        CGFloat shadowImageHeight = 1.0 / UIScreen.mainScreen.scale;
        _shadowImageView.frame = CGRectMake(0, -shadowImageHeight, CGRectGetWidth(_backgroundView.frame), shadowImageHeight);
    }
    
    // 放在UITabBarController里
    CGFloat contentHeight = CGRectGetHeight(self.bounds) - self.safeAreaInsets.bottom;
    self.contentView.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), contentHeight);
    
    NSInteger itemCount = self.items.count;
    if (itemCount == 0) return;
    if (_buttons.count != itemCount) return;
    
//    系统间距
//    CGFloat margin = 2.0;
//    CGFloat buttonSpace = 4.0;
//    CGFloat buttonY = 1.0;
    
    CGFloat contentWidth = CGRectGetWidth(self.contentView.frame);
    if (self.useLayoutSafeAreaInsets) {
        contentWidth -= (self.safeAreaInsets.left + self.safeAreaInsets.right);
    }
    
    CGFloat margin = 0.0;
    CGFloat buttonSpace = 0.0;
    CGFloat buttonY = 0.0;
    CGFloat buttonWidth = 0;
    if (itemCount == 1) {
        buttonWidth = contentWidth - margin * 2;
    } else {
        buttonWidth = (contentWidth - margin * 2 - (itemCount - 1) * buttonSpace) / itemCount;
    }
    CGFloat buttonHeight = CGRectGetHeight(self.contentView.frame) - buttonY;

    for (NSInteger i = 0; i < self.items.count; i++) {
        QQTabBarButton *button = _buttons[i];
        CGFloat buttonX = margin + i * (buttonWidth + buttonSpace);
        if (self.useLayoutSafeAreaInsets) {
            buttonX += self.safeAreaInsets.left;
        }
        button.frame = CGRectMake(buttonX, buttonY, buttonWidth, buttonHeight);
    }
}

@end
