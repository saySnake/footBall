//
//  PhoneInputViewController.m
//  footBall
//

#import "PhoneInputViewController.h"
#import <Masonry/Masonry.h>

@interface PhoneInputViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UIImageView *logoImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIView *phoneContainer;
@property (nonatomic, strong) UILabel *countryCodeLabel;
@property (nonatomic, strong) UIView *phoneSeparatorView;
@property (nonatomic, strong) UITextField *phoneTextField;
@property (nonatomic, strong) UIButton *getCodeButton;
@property (nonatomic, strong) UIButton *agreeCheckButton;
@property (nonatomic, strong) UIButton *agreementButton;
@property (nonatomic, strong) UILabel *otherLoginLabel;
@property (nonatomic, strong) UIView *otherLoginLeftLine;
@property (nonatomic, strong) UIView *otherLoginRightLine;
@property (nonatomic, strong) UIButton *appleLoginButton;
@property (nonatomic, strong) UIButton *wechatLoginButton;

@end

@implementation PhoneInputViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = NSLocalizedString(@"login_nav_title", nil);
    
    // 使用自定义返回按钮图片 "left"，并统一为黑色
    UIImage *backImage = [UIImage imageNamed:@"left"];
    if (backImage) {
        UIImage *tintedImage = [backImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithImage:tintedImage
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(handleBack)];
        backItem.tintColor = [UIColor blackColor];
        self.navigationItem.leftBarButtonItem = backItem;
        self.navigationItem.hidesBackButton = YES;
        
        // 确保整个导航栏上的返回按钮颜色为黑色
        self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    }
    
    [self setupUI];
    [self updateButtonState];
}

- (void)setupUI {
    self.logoImageView = [[UIImageView alloc] init];
    // 登录页 Logo 使用 Assets 中的登录图标
    self.logoImageView.image = [UIImage imageNamed:@"1"];
    self.logoImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = NSLocalizedString(@"login_welcome_title", nil);
    self.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.text = NSLocalizedString(@"phone_subtitle_auto_create", nil);
    self.subtitleLabel.font = [UIFont systemFontOfSize:12];
    self.subtitleLabel.textColor = [UIColor grayColor];
    self.subtitleLabel.textAlignment = NSTextAlignmentCenter;
    
    self.phoneContainer = [[UIView alloc] init];
    self.phoneContainer.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0];
    self.phoneContainer.layer.cornerRadius = 8;
    
    self.countryCodeLabel = [[UILabel alloc] init];
    self.countryCodeLabel.text = NSLocalizedString(@"phone_country_code_default", nil);
    self.countryCodeLabel.font = [UIFont systemFontOfSize:16];
    
    self.phoneSeparatorView = [[UIView alloc] init];
    self.phoneSeparatorView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    
    self.phoneTextField = [[UITextField alloc] init];
    self.phoneTextField.placeholder = NSLocalizedString(@"phone_input_placeholder", nil);
    self.phoneTextField.keyboardType = UIKeyboardTypeNumberPad;
    self.phoneTextField.textAlignment = NSTextAlignmentLeft;
    self.phoneTextField.delegate = self;
    [self.phoneTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    self.getCodeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.getCodeButton setTitle:NSLocalizedString(@"phone_get_code_button", nil) forState:UIControlStateNormal];
    [self.getCodeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.getCodeButton.backgroundColor = [UIColor colorWithRed:0.10 green:0.36 blue:0.28 alpha:1.0];
    self.getCodeButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    self.getCodeButton.layer.cornerRadius = 28;
    self.getCodeButton.layer.masksToBounds = YES;
    [self.getCodeButton addTarget:self action:@selector(getCodeTapped) forControlEvents:UIControlEventTouchUpInside];
    
    self.agreeCheckButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.agreeCheckButton setImage:[UIImage systemImageNamed:@"checkmark.circle.fill"] forState:UIControlStateSelected];
    [self.agreeCheckButton setImage:[UIImage systemImageNamed:@"circle"] forState:UIControlStateNormal];
    self.agreeCheckButton.tintColor = [UIColor colorWithRed:0.10 green:0.36 blue:0.28 alpha:1.0];
    self.agreeCheckButton.selected = YES;
    [self.agreeCheckButton addTarget:self action:@selector(toggleAgree) forControlEvents:UIControlEventTouchUpInside];
    
    self.agreementButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.agreementButton setTitle:NSLocalizedString(@"phone_agreement_text", nil) forState:UIControlStateNormal];
    self.agreementButton.titleLabel.font = [UIFont systemFontOfSize:12];
    
    self.otherLoginLabel = [[UILabel alloc] init];
    self.otherLoginLabel.text = NSLocalizedString(@"login_other_methods_title", nil);
    self.otherLoginLabel.font = [UIFont systemFontOfSize:12];
    self.otherLoginLabel.textColor = [UIColor lightGrayColor];
    self.otherLoginLabel.textAlignment = NSTextAlignmentCenter;
    
    self.otherLoginLeftLine = [[UIView alloc] init];
    self.otherLoginLeftLine.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    
    self.otherLoginRightLine = [[UIView alloc] init];
    self.otherLoginRightLine.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    
    self.appleLoginButton = [UIButton buttonWithType:UIButtonTypeSystem];
    if (@available(iOS 13.0, *)) {
        UIImage *appleImage = [UIImage systemImageNamed:@"applelogo"];
        [self.appleLoginButton setImage:appleImage forState:UIControlStateNormal];
    }
    self.appleLoginButton.tintColor = [UIColor blackColor];
    self.appleLoginButton.backgroundColor = [UIColor whiteColor];
    self.appleLoginButton.layer.cornerRadius = 28;
    self.appleLoginButton.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.1].CGColor;
    self.appleLoginButton.layer.shadowOpacity = 1.0;
    self.appleLoginButton.layer.shadowRadius = 8;
    self.appleLoginButton.layer.shadowOffset = CGSizeMake(0, 4);
    self.appleLoginButton.accessibilityLabel = NSLocalizedString(@"login_method_apple", nil);
    
    self.wechatLoginButton = [UIButton buttonWithType:UIButtonTypeSystem];
    if (@available(iOS 13.0, *)) {
        UIImage *wechatImage = [UIImage systemImageNamed:@"message.fill"];
        [self.wechatLoginButton setImage:wechatImage forState:UIControlStateNormal];
    }
    self.wechatLoginButton.tintColor = [UIColor blackColor];
    self.wechatLoginButton.backgroundColor = [UIColor whiteColor];
    self.wechatLoginButton.layer.cornerRadius = 28;
    self.wechatLoginButton.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.1].CGColor;
    self.wechatLoginButton.layer.shadowOpacity = 1.0;
    self.wechatLoginButton.layer.shadowRadius = 8;
    self.wechatLoginButton.layer.shadowOffset = CGSizeMake(0, 4);
    self.wechatLoginButton.accessibilityLabel = NSLocalizedString(@"login_method_wechat", nil);
    
    [self.view addSubview:self.logoImageView];
    [self.view addSubview:self.titleLabel];
    [self.view addSubview:self.subtitleLabel];
    [self.view addSubview:self.phoneContainer];
    [self.view addSubview:self.getCodeButton];
    [self.view addSubview:self.agreeCheckButton];
    [self.view addSubview:self.agreementButton];
    [self.view addSubview:self.otherLoginLabel];
    [self.view addSubview:self.otherLoginLeftLine];
    [self.view addSubview:self.otherLoginRightLine];
    [self.view addSubview:self.appleLoginButton];
    [self.view addSubview:self.wechatLoginButton];
    
    [self.phoneContainer addSubview:self.countryCodeLabel];
    [self.phoneContainer addSubview:self.phoneSeparatorView];
    [self.phoneContainer addSubview:self.phoneTextField];
    
    [self.logoImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(40);
        make.centerX.equalTo(self.view);
        make.width.height.mas_equalTo(120);
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.logoImageView.mas_bottom).offset(24);
        make.leading.trailing.equalTo(self.view).inset(24);
    }];
    
    
    [self.phoneContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(30);
        make.leading.trailing.equalTo(self.view).inset(24);
        make.height.mas_equalTo(52);
    }];
    
    [self.subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.phoneContainer.mas_bottom).offset(10);
        make.leading.trailing.equalTo(self.view).inset(24);
    }];

    
    [self.countryCodeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.phoneContainer).offset(16);
        make.centerY.equalTo(self.phoneContainer);
        make.width.mas_equalTo(30);
    }];
    
    [self.phoneSeparatorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.countryCodeLabel.mas_trailing).offset(12);
        make.centerY.equalTo(self.phoneContainer);
        make.width.mas_equalTo(1.0);
        make.top.equalTo(self.phoneContainer).offset(10);
        make.bottom.equalTo(self.phoneContainer).offset(-10);
    }];
    
    [self.phoneTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.phoneSeparatorView.mas_trailing).offset(12);
        make.trailing.equalTo(self.phoneContainer).offset(-16);
        make.centerY.equalTo(self.phoneContainer);
    }];
    
    [self.getCodeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.subtitleLabel.mas_bottom).offset(41);
        make.leading.trailing.equalTo(self.view).inset(24);
        make.height.mas_equalTo(54);
    }];
    
    [self.agreeCheckButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.getCodeButton.mas_bottom).offset(16);
        make.leading.equalTo(self.getCodeButton);
        make.width.height.mas_equalTo(20);
    }];
    
    [self.agreementButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.agreeCheckButton);
        make.leading.equalTo(self.agreeCheckButton.mas_trailing).offset(6);
    }];
    
    [self.otherLoginLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.agreementButton.mas_bottom).offset(40);
        make.centerX.equalTo(self.view);
    }];
    
    [self.otherLoginLeftLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.otherLoginLabel);
        make.leading.equalTo(self.view).offset(40);
        make.trailing.equalTo(self.otherLoginLabel.mas_leading).offset(-12);
        make.height.mas_equalTo(1.0);
    }];
    
    [self.otherLoginRightLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.otherLoginLabel);
        make.leading.equalTo(self.otherLoginLabel.mas_trailing).offset(12);
        make.trailing.equalTo(self.view).offset(-40);
        make.height.mas_equalTo(1.0);
    }];
    
    [self.appleLoginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.otherLoginLabel.mas_bottom).offset(24);
        make.centerX.equalTo(self.view).offset(-40);
        make.width.height.mas_equalTo(56);
    }];
    
    [self.wechatLoginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.otherLoginLabel.mas_bottom).offset(24);
        make.centerX.equalTo(self.view).offset(40);
        make.width.height.mas_equalTo(56);
    }];
}

- (void)textFieldDidChange:(UITextField *)textField {
    // 限制为 11 位手机号
    if (textField.text.length > 11) {
        textField.text = [textField.text substringToIndex:11];
    }
    [self updateButtonState];
}

- (void)handleBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)toggleAgree {
    self.agreeCheckButton.selected = !self.agreeCheckButton.selected;
    [self updateButtonState];
}

- (void)updateButtonState {
    BOOL validPhone = self.phoneTextField.text.length == 11;
    BOOL enabled = validPhone && self.agreeCheckButton.selected;
    self.getCodeButton.enabled = enabled;
    self.getCodeButton.alpha = enabled ? 1.0 : 0.5;
}

- (void)getCodeTapped {
    if (!self.getCodeButton.enabled) {
        return;
    }
    Class verifyClass = NSClassFromString(@"VerifyCodeViewController");
    if (!verifyClass) {
        return;
    }
    UIViewController *vc = [verifyClass new];
    [vc setValue:self.phoneTextField.text forKey:@"phoneNumber"];
    [self.navigationController pushViewController:vc animated:YES];
}

@end

