//
//  SplashViewController.m
//  footBall
//

#import "SplashViewController.h"
#import "HomeViewController.h"
#import "AuthManager.h"
#import <Masonry/Masonry.h>

@interface SplashViewController ()

@property (nonatomic, strong) UIImageView *logoImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, assign) BOOL didNavigate;

@end

@implementation SplashViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupUI];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.didNavigate) {
        return;
    }
    self.didNavigate = YES;
    
    // 启动页停留 1.2 秒后根据登录状态跳转
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self navigateNext];
    });
}

- (void)setupUI {
    self.logoImageView = [[UIImageView alloc] init];
    // 这里使用占位图名称，需在 Assets 中配置同名资源
    self.logoImageView.image = [UIImage imageNamed:@"1"];
    self.logoImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = @"Pass Nomad";
    self.titleLabel.font = [UIFont boldSystemFontOfSize:28.0];
    self.titleLabel.textColor = [UIColor blackColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    [self.view addSubview:self.logoImageView];
    [self.view addSubview:self.titleLabel];
    
    [self.logoImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.centerY.equalTo(self.view).offset(-40);
        make.width.height.mas_equalTo(160);
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.logoImageView.mas_bottom).offset(24);
        make.centerX.equalTo(self.view);
        make.leading.trailing.equalTo(self.view).inset(24);
    }];
}

- (void)navigateNext {
    UINavigationController *nav = (UINavigationController *)self.navigationController;
    if (!nav) {
        return;
    }
    
    if ([AuthManager sharedManager].isLoggedIn) {
        // 已登录，直接进入首页
        HomeViewController *homeVC = [[HomeViewController alloc] init];
        [nav setViewControllers:@[homeVC] animated:YES];
    } else {
        // 未登录，进入登录流程的第一个页面
        UIViewController *loginEntryVC = [NSClassFromString(@"LoginChoiceViewController") new];
        if (loginEntryVC) {
            [nav setViewControllers:@[loginEntryVC] animated:YES];
        }
    }
}

@end

