//
//  VerifyCodeViewController.m
//  footBall
//

#import "VerifyCodeViewController.h"
#import "AuthManager.h"
#import "TeamSelectionViewController.h"
#import <Masonry/Masonry.h>
#import "MainTabBarController.h"
@interface VerifyCodeViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIView *codeContainerView;
@property (nonatomic, strong) NSArray<UILabel *> *codeLabels;
@property (nonatomic, strong) UITextField *codeTextField; // 隐藏输入框，用于捕获数字
@property (nonatomic, strong) UIButton *loginButton;
@property (nonatomic, strong) UIButton *resendButton;

@end

@implementation VerifyCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = NSLocalizedString(@"login_nav_title", nil);
    
    // 使用自定义返回按钮图片 "left"
    UIImage *backImage = [UIImage imageNamed:@"left"];
    if (backImage) {
        UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithImage:backImage
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(handleBack)];
        self.navigationItem.leftBarButtonItem = backItem;
        self.navigationItem.hidesBackButton = YES;
    }
    
    [self setupUI];
    [self updateButtonState];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 自动激活数字键盘
    [self.codeTextField becomeFirstResponder];
}

- (void)setupUI {
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = NSLocalizedString(@"verify_title", nil);
    self.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    
    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.font = [UIFont systemFontOfSize:14];
    self.subtitleLabel.textColor = [UIColor grayColor];
    self.subtitleLabel.numberOfLines = 0;
    NSString *phone = self.phoneNumber.length > 0 ? self.phoneNumber : @"";
    NSString *format = NSLocalizedString(@"verify_subtitle_format", nil);
    NSString *subtitleText = [NSString stringWithFormat:format, phone];
    NSMutableAttributedString *attrSubtitle = [[NSMutableAttributedString alloc] initWithString:subtitleText];
    if (phone.length > 0) {
        NSRange phoneRange = [subtitleText rangeOfString:phone];
        if (phoneRange.location != NSNotFound) {
            [attrSubtitle addAttribute:NSFontAttributeName
                                 value:[UIFont boldSystemFontOfSize:14]
                                 range:phoneRange];
            [attrSubtitle addAttribute:NSForegroundColorAttributeName
                                 value:[UIColor blackColor]
                                 range:phoneRange];
        }
    }
    self.subtitleLabel.attributedText = attrSubtitle;
    
    // 验证码 6 个输入框展示容器
    self.codeContainerView = [[UIView alloc] init];
    
    NSMutableArray<UILabel *> *labels = [NSMutableArray arrayWithCapacity:6];
    UIView *previous = nil;
    CGFloat boxWidth = 44.0;
    CGFloat boxSpacing = 12.0;
    for (NSInteger i = 0; i < 6; i++) {
        UILabel *label = [[UILabel alloc] init];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:24 weight:UIFontWeightMedium];
        label.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0];
        label.layer.cornerRadius = 8.0;
        label.layer.masksToBounds = YES;
        
        [self.codeContainerView addSubview:label];
        [labels addObject:label];
        
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(self.codeContainerView);
            make.width.mas_equalTo(boxWidth);
            if (previous) {
                make.left.equalTo(previous.mas_right).offset(boxSpacing);
            } else {
                make.left.equalTo(self.codeContainerView);
            }
            if (i == 5) {
                make.right.equalTo(self.codeContainerView);
            }
        }];
        
        previous = label;
    }
    self.codeLabels = labels;
    
    // 隐藏的真实输入框，只用来接收数字
    self.codeTextField = [[UITextField alloc] init];
    self.codeTextField.keyboardType = UIKeyboardTypeNumberPad;
    self.codeTextField.delegate = self;
    self.codeTextField.textAlignment = NSTextAlignmentCenter;
    self.codeTextField.tintColor = [UIColor clearColor];
    self.codeTextField.textColor = [UIColor clearColor];
    self.codeTextField.backgroundColor = [UIColor clearColor];
    self.codeTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.codeTextField.spellCheckingType = UITextSpellCheckingTypeNo;
    [self.codeTextField addTarget:self
                           action:@selector(textFieldDidChange:)
                 forControlEvents:UIControlEventEditingChanged];
    
    self.loginButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.loginButton setTitle:NSLocalizedString(@"verify_login_button", nil) forState:UIControlStateNormal];
    [self.loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.loginButton.backgroundColor = [ColorManager sharedManager].primaryColor;
    self.loginButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    self.loginButton.layer.cornerRadius = 27;
    self.loginButton.layer.masksToBounds = YES;
    [self.loginButton addTarget:self action:@selector(loginTapped) forControlEvents:UIControlEventTouchUpInside];
    
    self.resendButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.resendButton setTitle:NSLocalizedString(@"verify_resend_button", nil) forState:UIControlStateNormal];
    self.resendButton.titleLabel.font = [UIFont systemFontOfSize:14];
    self.resendButton.tintColor = [UIColor darkGrayColor];
    [self.resendButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    if (@available(iOS 13.0, *)) {
        UIImage *refreshImage = [UIImage systemImageNamed:@"arrow.clockwise"];
        [self.resendButton setImage:refreshImage forState:UIControlStateNormal];
        self.resendButton.imageEdgeInsets = UIEdgeInsetsMake(0, -4, 0, 4);
    }
    
    [self.view addSubview:self.titleLabel];
    [self.view addSubview:self.subtitleLabel];
    [self.view addSubview:self.codeContainerView];
    [self.view addSubview:self.codeTextField];
    [self.view addSubview:self.loginButton];
    [self.view addSubview:self.resendButton];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(40);
        make.leading.trailing.equalTo(self.view).inset(24);
    }];
    
    [self.subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(8);
        make.leading.trailing.equalTo(self.view).inset(24);
    }];
    
    [self.codeContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.subtitleLabel.mas_bottom).offset(32);
        make.centerX.equalTo(self.view);
        make.height.mas_equalTo(56);
    }];
    
    // 隐藏输入框放在屏幕外，不影响布局
    [self.codeTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.codeContainerView.mas_bottom);
        make.leading.equalTo(self.view.mas_leading);
        make.width.height.mas_equalTo(1.0);
    }];
    
    [self.resendButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.codeContainerView.mas_bottom).offset(16);
        make.right.mas_equalTo(-22);
        make.height.mas_offset(22);
    }];

    
    [self.loginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.resendButton.mas_bottom).offset(47);
        make.leading.trailing.equalTo(self.view).inset(24);
        make.height.mas_equalTo(54);
    }];
}

- (void)textFieldDidChange:(UITextField *)textField {
    if (textField.text.length > 6) {
        textField.text = [textField.text substringToIndex:6];
    }
    
    // 同步更新 6 个验证码格子的展示
    NSString *code = textField.text ?: @"";
    for (NSInteger i = 0; i < self.codeLabels.count; i++) {
        UILabel *label = self.codeLabels[i];
        if (i < code.length) {
            unichar ch = [code characterAtIndex:i];
            label.text = [NSString stringWithCharacters:&ch length:1];
        } else {
            label.text = @"";
        }
    }
    
    [self updateButtonState];
}

- (void)updateButtonState {
    BOOL enabled = self.codeTextField.text.length == 6;
    self.loginButton.enabled = enabled;
    self.loginButton.alpha = enabled ? 1.0 : 0.5;
}

- (void)loginTapped {
    if (!self.loginButton.enabled) {
        return;
    }
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [AuthManager.sharedManager loginPhone:self.phoneNumber verify:self.codeTextField.text success:^(HTTPResponse * _Nonnull response) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        // 登录成功后进入选择球队界面
        if (AuthManager.sharedManager.user.onboardingCompleted) {
            [self goToHome];
        } else {
            TeamSelectionViewController *teamVC = [[TeamSelectionViewController alloc] init];
            [self.navigationController pushViewController:teamVC animated:YES];
        }

    } failure:^(NSError * _Nonnull error) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [QMUITips showError:error.localizedDescription];
    }];
}
- (void)goToHome {
    MainTabBarController *tabBar = [[MainTabBarController alloc] init];
    UIWindow *window = self.view.window ?: [UIApplication sharedApplication].windows.firstObject;
    if (window) {
        window.rootViewController = tabBar;
    } else {
        [self presentViewController:tabBar animated:YES completion:nil];
    }
}

- (void)handleBack {
    [self.navigationController popViewControllerAnimated:YES];
}

@end

