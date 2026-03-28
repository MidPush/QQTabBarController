//
//  ModalViewController.m
//  QQTabBarController
//
//  Created by apple on 2026/2/12.
//

#import "ModalViewController.h"
#import "QQTabBarController.h"

@interface ModalViewController ()
@property (nonatomic, strong) UIButton *button;
@end

@implementation ModalViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    _button = [[UIButton alloc] init];
    [_button setTitle:@"关闭" forState:UIControlStateNormal];
    [_button setTitleColor:UIColor.redColor forState:UIControlStateNormal];
    [_button addTarget:self action:@selector(onButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_button];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    _button.frame = CGRectMake((self.view.frame.size.width - 100) / 2, 200, 100, 40);
}

- (void)onButtonClicked {
    [self dismissViewControllerAnimated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
