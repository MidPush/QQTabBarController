//
//  TableViewController.m
//  QQNavTabBarController
//
//  Created by apple on 2026/2/6.
//

#import "TableViewController.h"
#import "TabBarDemoViewController.h"
#import "NNTabBarController.h"
#import "SystemTabBarController.h"

@interface TableViewController ()

@property (nonatomic, copy) NSString *itemTitle;

@end

@implementation TableViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.qq_tabBarController setTabBarHidden:NO animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
        cell.textLabel.font = [UIFont systemFontOfSize:12];
    }

    cell.accessoryType = UITableViewCellAccessoryNone;
    NSString *title = [NSString stringWithFormat:@"Cell at index: %ld", indexPath.row];
    if (indexPath.row == 0) {
        title = @"Show / hide QQTabBar";
    } else if (indexPath.row == 1) {
        title = @"Change QQTabBarItem 不居中显示（系统效果）";
    } else if (indexPath.row == 2) {
        title = @"Change QQTabBarItem 居中显示";
    } else if (indexPath.row == 3) {
        title = @"设置 QQTabBarItem 背景色";
    } else if (indexPath.row == 4) {
        title = @"改变 QQTabBar 高度";
    } else if (indexPath.row == 5) {
        title = @"和系统 UITabBar 比较";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if (indexPath.row == 6) {
        title = @"Push To 系统 UITabBarController";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    cell.textLabel.text = title;
    return cell;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    
    if (indexPath.row == 0) {
        if (self.qq_tabBarController.isTabBarHidden) {
            [self.qq_tabBarController setTabBarHidden:NO animated:YES];
        } else {
            [self.qq_tabBarController setTabBarHidden:YES animated:YES];
        }
        
        // 系统
        if (@available(iOS 18.0, *)) {
            if (self.tabBarController.isTabBarHidden) {
                [self.tabBarController setTabBarHidden:NO animated:YES];
            } else {
                [self.tabBarController setTabBarHidden:YES animated:YES];
            }
        }
    } else if (indexPath.row == 1) {
        self.navigationController.qq_tabBarItem.layoutCentered = NO;
        if (self.navigationController.qq_tabBarItem.title) {
            _itemTitle = self.navigationController.qq_tabBarItem.title;
            self.navigationController.qq_tabBarItem.title = nil;
        } else {
            self.navigationController.qq_tabBarItem.title = _itemTitle;
        }
    } else if (indexPath.row == 2) {
        self.navigationController.qq_tabBarItem.layoutCentered = YES;
        if (self.navigationController.qq_tabBarItem.title) {
            _itemTitle = self.navigationController.qq_tabBarItem.title;
            self.navigationController.qq_tabBarItem.title = nil;
        } else {
            self.navigationController.qq_tabBarItem.title = _itemTitle;
        }
    } else if (indexPath.row == 3) {
        for (UIViewController *vc in self.qq_tabBarController.viewControllers) {
            UIColor *backgroundColor = vc.qq_tabBarItem.backgroundColor;
            UIColor *selectedBackgroundColor = vc.qq_tabBarItem.selectedBackgroundColor;
            if (backgroundColor == nil) {
                backgroundColor = [UIColor colorWithRed:0.18 green:0.18 blue:0.18 alpha:1.0];
                selectedBackgroundColor = [UIColor blackColor];
            } else {
                backgroundColor = nil;
                selectedBackgroundColor = nil;
            }
            vc.qq_tabBarItem.backgroundColor = backgroundColor;
            vc.qq_tabBarItem.selectedBackgroundColor = selectedBackgroundColor;
        }
    } else if (indexPath.row == 4) {
        self.qq_tabBarController.tabBarHeight += 10;
        if (self.qq_tabBarController.tabBarHeight >= 100) {
            self.qq_tabBarController.tabBarHeight = 49;
        }
    } else if (indexPath.row == 5) {
        TabBarDemoViewController *vc = [[TabBarDemoViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    } else if (indexPath.row == 6) {
        SystemTabBarController *vc = [[SystemTabBarController alloc] init];
        vc.qq_hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        UIViewController *vc = [[UIViewController alloc] init];
        vc.qq_hidesBottomBarWhenPushed = YES;
        vc.view.backgroundColor = UIColor.systemBackgroundColor;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

@end
