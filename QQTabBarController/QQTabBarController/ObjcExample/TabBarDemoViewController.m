//
//  TabBarDemoViewController.m
//  QQNavTabBarController
//
//  Created by apple on 2026/2/6.
//

#import "TabBarDemoViewController.h"
#import "QQTabBar.h"
#import "TableViewController.h"
#import "QQTabBarController.h"
#import "UIImage+Extension.h"

@interface TabBarDemoViewController ()<UITableViewDelegate, UITableViewDataSource, QQTabBarDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *datas;

@property (nonatomic, strong) QQTabBar *tabBar;
@property (nonatomic, strong) UITabBar *uitabBar;

@end

@implementation TabBarDemoViewController

- (NSArray<NSString *> *)datas {
    if (!_datas) {
        _datas = @[
            @"设置 barTintColor",
            @"设置 backgroundImage",
            @"设置 shadowImage",
            @"设置 tintColor",
            @"设置 items",
            @"设置 清空",
        ];
    }
    return _datas;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    [self initSubviews];
}

- (void)initSubviews {
    
    NSArray *titles = @[@"主页", @"同城", @"消息"];
    NSArray *images = @[@"home_normal", @"fishpond_normal", @"message_normal"];
    NSArray *selectedImages = @[@"home_highlight", @"fishpond_highlight", @"message_highlight"];
    NSMutableArray *items = [NSMutableArray array];
    for (NSInteger i = 0; i < titles.count; i++) {
        UIImage *selectedImage = [UIImage imageNamed:selectedImages[i]];
        UITabBarItem *item = [[UITabBarItem alloc] initWithTitle:titles[i] image:[UIImage imageNamed:images[i]] selectedImage:selectedImage];
        [items addObject:item];
    }
    
    _tabBar = [[QQTabBar alloc] init];
    _tabBar.delegate = self;
    _tabBar.items = items;
    [self.view addSubview:_tabBar];
    
    _uitabBar = [[UITabBar alloc] init];
    _uitabBar.items = items;
    [self.view addSubview:_uitabBar];
    
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.rowHeight = 50;
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    [self.view insertSubview:_tableView atIndex:0];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    _tabBar.frame = CGRectMake(0, CGRectGetMaxY(self.navigationController.navigationBar.frame) + 20, self.view.frame.size.width, 49);
    
    CGFloat uitabBarHeight = _tabBar.frame.size.height;
    if (@available(iOS 26.0, *)) {
        uitabBarHeight = 91;
    }
    _uitabBar.frame = CGRectMake(0, CGRectGetMaxY(_tabBar.frame) + 10, self.view.frame.size.width, uitabBarHeight);
    _tableView.frame = CGRectMake(0, CGRectGetMaxY(_uitabBar.frame), self.view.frame.size.width, self.view.frame.size.height - (CGRectGetMaxY(_uitabBar.frame)+ 10));
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.datas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        cell.textLabel.font = [UIFont systemFontOfSize:14];
    }
    cell.textLabel.text = self.datas[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {    
    if (indexPath.row == 0) {
        _tabBar.barTintColor = [self.qq_randomColor colorWithAlphaComponent:0.5];
        _uitabBar.barTintColor = _tabBar.barTintColor;
    } else if (indexPath.row == 1) {
        _tabBar.backgroundImage = [UIImage qq_imageWithColor:self.qq_randomColor size:CGSizeMake(4, 4)];
        _uitabBar.backgroundImage = _tabBar.backgroundImage;
    } else if (indexPath.row == 2) {
        _tabBar.shadowImage = [UIImage qq_imageWithColor:self.qq_randomColor size:CGSizeMake(4, 1)];
        _uitabBar.shadowImage = _tabBar.shadowImage;
    } else if (indexPath.row == 3) {
        _tabBar.tintColor = self.qq_randomColor;
        _uitabBar.tintColor = _tabBar.tintColor;
    } else if (indexPath.row == 4) {
        NSMutableArray *items = [_tabBar.items mutableCopy];
        [items removeLastObject];
        _tabBar.items = items;
        _uitabBar.items = items;
    } else if (indexPath.row == 5) {
        _tabBar.backgroundImage = nil;
        _tabBar.shadowImage = nil;
        _tabBar.tintColor = nil;
        _tabBar.barTintColor = nil;
        _tabBar.items = nil;
        
        _uitabBar.backgroundImage = nil;
        _uitabBar.shadowImage = nil;
        _uitabBar.tintColor = nil;
        _uitabBar.barTintColor = nil;
        _uitabBar.items = nil;
    }
}

- (void)tabBar:(QQTabBar *)tabBar didSelectItem:(QQTabBarItem *)item {
    if (self.qq_tabBarController.isTabBarHidden) {
        [self.qq_tabBarController setTabBarHidden:NO animated:YES];
    } else {
        [self.qq_tabBarController setTabBarHidden:YES animated:YES];
    }
    
    if (@available(iOS 18.0, *)) {
        if (self.tabBarController.isTabBarHidden) {
            [self.tabBarController setTabBarHidden:NO animated:YES];
        } else {
            [self.tabBarController setTabBarHidden:YES animated:YES];
        }
    }
}

#pragma mark - Helps
- (UIColor *)qq_randomColor {
    CGFloat red = ( arc4random() % 255 / 255.0 );
    CGFloat green = ( arc4random() % 255 / 255.0 );
    CGFloat blue = ( arc4random() % 255 / 255.0 );
    return [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
}

@end
