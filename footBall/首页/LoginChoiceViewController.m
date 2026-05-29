//
//  LoginChoiceViewController.m
//  footBall
//

#import "LoginChoiceViewController.h"
#import <Masonry/Masonry.h>
#import "UINavigationController+NavigationBar.h"
#import "NavigationBarManager.h"

@interface LoginChoiceViewController ()

@property (nonatomic, strong) UIImageView *logoImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *phoneLoginButton;

@end

@implementation LoginChoiceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (@available(iOS 13.0, *)) {
        // 登录页为固定浅色稿，避免夜间深色模式下导航栏标题变白
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = NSLocalizedString(@"login_nav_title", nil);
    
    [self setupUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self applyLoginNavigationBarStyle];
}

- (void)applyLoginNavigationBarStyle {
    if (!self.navigationController) {
        return;
    }
    NavigationBarConfig *config = [NavigationBarManager configWithBackgroundColor:[UIColor whiteColor]
                                                                        titleColor:[UIColor colorWithHexString:@"#000000"]];
    config.hideShadow = YES;
    config.tintColor = [ColorManager sharedManager].primaryColor;
    [self.navigationController applyNavigationBarStyle:config];
}

- (void)setupUI {
    self.logoImageView = [[UIImageView alloc] init];
    self.logoImageView.image = [UIImage imageNamed:@"1"];
    self.logoImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = NSLocalizedString(@"login_welcome_title", nil);
    self.titleLabel.font = [UIFont boldSystemFontOfSize:20.0];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.textColor = [UIColor colorWithHexString:@"#000000"];
    
    self.phoneLoginButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.phoneLoginButton setTitle:NSLocalizedString(@"login_with_phone_button", nil) forState:UIControlStateNormal];
    self.phoneLoginButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    [self.phoneLoginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.phoneLoginButton.backgroundColor = [ColorManager sharedManager].primaryColor; // 深绿色（跟随主题）
    self.phoneLoginButton.layer.cornerRadius = 26;
    self.phoneLoginButton.layer.masksToBounds = YES;
    [self.phoneLoginButton addTarget:self action:@selector(phoneLoginTapped) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.logoImageView];
    [self.view addSubview:self.titleLabel];
    [self.view addSubview:self.phoneLoginButton];
    
    [self.logoImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(80);
        make.width.height.mas_equalTo(140);
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.logoImageView.mas_bottom).offset(24);
        make.centerX.equalTo(self.view);
        make.leading.trailing.equalTo(self.view).inset(24);
    }];
    
    [self.phoneLoginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(80);
        make.leading.trailing.equalTo(self.view).inset(40);
        make.height.mas_equalTo(52);
    }];
}

- (void)phoneLoginTapped {
    UIViewController *vc = [NSClassFromString(@"PhoneInputViewController") new];
    if (vc) {
        [self.navigationController pushViewController:vc animated:YES];
    }
}

@end

