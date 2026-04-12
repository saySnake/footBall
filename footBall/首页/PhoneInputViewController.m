//
//  PhoneInputViewController.m
//  footBall
//
//  Figma「手机号登录」r2NHY24zoL00k6JFuwivYz / 1:3989
//

#import "PhoneInputViewController.h"
#import <Masonry/Masonry.h>
#import "ColorManager.h"
#import "VerifyCodeViewController.h"

/// Figma 稿：主按钮 / 勾选 #285d4b；手机号输入条：浅底 #F5F5F5、圆角 12；次级字 #656565；说明 #a1a1a1；链接 #3021ff
static UIColor *PNFigmaGreen(void) {
    return [ColorManager colorWithHexString:@"#285d4b"];
}
static UIColor *PNFigmaInputBG(void) {
    return [ColorManager colorWithHexString:@"#F5F5F5"];
}
static UIColor *PNFigmaMutedText(void) {
    return [ColorManager colorWithHexString:@"#656565"];
}
static UIColor *PNFigmaHintText(void) {
    return [ColorManager colorWithHexString:@"#a1a1a1"];
}
static UIColor *PNFigmaLinkBlue(void) {
    return [ColorManager colorWithHexString:@"#3021ff"];
}
static UIColor *PNFigmaSocialCircleBG(void) {
    return [ColorManager colorWithHexString:@"#E8E8E8"];
}

@interface PhoneInputViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UIView *logoCardView;
@property (nonatomic, strong) UIImageView *logoImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIView *phoneContainer;
@property (nonatomic, strong) UILabel *countryCodeLabel;
@property (nonatomic, strong) UIView *phoneSeparatorView;
@property (nonatomic, strong) UITextField *phoneTextField;
@property (nonatomic, strong) UIButton *getCodeButton;
@property (nonatomic, strong) UIStackView *agreementStack;
@property (nonatomic, strong) UIButton *agreeCheckButton;
@property (nonatomic, strong) UILabel *agreementPrefixLabel;
@property (nonatomic, strong) UIButton *agreementLinkButton;
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
        self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    }
    
    [self setupUI];
    [self updateButtonState];
}

- (void)setupUI {
    self.logoCardView = [[UIView alloc] init];
    self.logoCardView.backgroundColor = [UIColor whiteColor];
    self.logoCardView.layer.cornerRadius = 16;
    self.logoCardView.layer.masksToBounds = YES;
    
    self.logoImageView = [[UIImageView alloc] init];
    self.logoImageView.image = [UIImage imageNamed:@"1"];
    self.logoImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = NSLocalizedString(@"login_welcome_title", nil);
    self.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    self.titleLabel.textColor = [UIColor blackColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.text = NSLocalizedString(@"phone_subtitle_auto_create", nil);
    self.subtitleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    self.subtitleLabel.textColor = PNFigmaHintText();
    self.subtitleLabel.textAlignment = NSTextAlignmentLeft;
    
    self.phoneContainer = [[UIView alloc] init];
    self.phoneContainer.backgroundColor = PNFigmaInputBG();
    self.phoneContainer.layer.cornerRadius = 12;
    self.phoneContainer.layer.masksToBounds = YES;
    
    self.countryCodeLabel = [[UILabel alloc] init];
    self.countryCodeLabel.text = NSLocalizedString(@"phone_country_code_default", nil);
    self.countryCodeLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    self.countryCodeLabel.textColor = PNFigmaMutedText();
    
    self.phoneSeparatorView = [[UIView alloc] init];
    self.phoneSeparatorView.backgroundColor = [ColorManager colorWithHexString:@"#E5E5E5"];
    
    self.phoneTextField = [[UITextField alloc] init];
    self.phoneTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"phone_input_placeholder", nil)
                                                                                attributes:@{
        NSFontAttributeName: [UIFont systemFontOfSize:14 weight:UIFontWeightMedium],
        NSForegroundColorAttributeName: PNFigmaMutedText(),
    }];
    self.phoneTextField.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    self.phoneTextField.textColor = [UIColor blackColor];
    self.phoneTextField.keyboardType = UIKeyboardTypeNumberPad;
    self.phoneTextField.textAlignment = NSTextAlignmentLeft;
    self.phoneTextField.delegate = self;
    self.phoneTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.phoneTextField.spellCheckingType = UITextSpellCheckingTypeNo;
    if (@available(iOS 11.0, *)) {
        self.phoneTextField.smartDashesType = UITextSmartDashesTypeNo;
        self.phoneTextField.smartQuotesType = UITextSmartQuotesTypeNo;
        self.phoneTextField.smartInsertDeleteType = UITextSmartInsertDeleteTypeNo;
        self.phoneTextField.textContentType = UITextContentTypeTelephoneNumber;
    }
    [self.phoneTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    self.getCodeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.getCodeButton setTitle:NSLocalizedString(@"phone_get_code_button", nil) forState:UIControlStateNormal];
    [self.getCodeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.getCodeButton.backgroundColor = PNFigmaGreen();
    self.getCodeButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.getCodeButton.layer.cornerRadius = 27;
    self.getCodeButton.layer.masksToBounds = NO;
    self.getCodeButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.getCodeButton.layer.shadowOffset = CGSizeMake(0, 2);
    self.getCodeButton.layer.shadowRadius = 2;
    self.getCodeButton.layer.shadowOpacity = 0.19;
    [self.getCodeButton addTarget:self action:@selector(getCodeTapped) forControlEvents:UIControlEventTouchUpInside];
    
    self.agreeCheckButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *checkOn = nil;
    UIImage *checkOff = nil;
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightRegular];
        checkOn = [[UIImage systemImageNamed:@"checkmark.circle.fill" withConfiguration:cfg] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        checkOff = [[UIImage systemImageNamed:@"circle" withConfiguration:cfg] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    [self.agreeCheckButton setImage:checkOn forState:UIControlStateSelected];
    [self.agreeCheckButton setImage:checkOff forState:UIControlStateNormal];
    self.agreeCheckButton.tintColor = PNFigmaGreen();
    self.agreeCheckButton.selected = YES;
    [self.agreeCheckButton addTarget:self action:@selector(toggleAgree) forControlEvents:UIControlEventTouchUpInside];
    
    self.agreementPrefixLabel = [[UILabel alloc] init];
    self.agreementPrefixLabel.text = NSLocalizedString(@"phone_agreement_prefix", nil);
    self.agreementPrefixLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    self.agreementPrefixLabel.textColor = [UIColor blackColor];
    
    self.agreementLinkButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.agreementLinkButton setTitle:NSLocalizedString(@"phone_agreement_link", nil) forState:UIControlStateNormal];
    [self.agreementLinkButton setTitleColor:PNFigmaLinkBlue() forState:UIControlStateNormal];
    self.agreementLinkButton.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    self.agreementLinkButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    
    self.agreementStack = [[UIStackView alloc] initWithArrangedSubviews:@[
        self.agreeCheckButton,
        self.agreementPrefixLabel,
        self.agreementLinkButton,
    ]];
    self.agreementStack.axis = UILayoutConstraintAxisHorizontal;
    self.agreementStack.alignment = UIStackViewAlignmentCenter;
    self.agreementStack.spacing = 4;
    
    self.otherLoginLabel = [[UILabel alloc] init];
    self.otherLoginLabel.text = NSLocalizedString(@"login_other_methods_title", nil);
    self.otherLoginLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    self.otherLoginLabel.textColor = PNFigmaMutedText();
    self.otherLoginLabel.textAlignment = NSTextAlignmentCenter;
    
    self.otherLoginLeftLine = [[UIView alloc] init];
    self.otherLoginLeftLine.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    
    self.otherLoginRightLine = [[UIView alloc] init];
    self.otherLoginRightLine.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    
    self.appleLoginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *appleImg = [UIImage imageNamed:@"apple_icon"];
    if (appleImg) {
        [self.appleLoginButton setImage:[appleImg imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    } else if (@available(iOS 13.0, *)) {
        [self.appleLoginButton setImage:[UIImage systemImageNamed:@"applelogo"] forState:UIControlStateNormal];
        self.appleLoginButton.tintColor = [UIColor blackColor];
    }
    self.appleLoginButton.backgroundColor = PNFigmaSocialCircleBG();
    self.appleLoginButton.layer.cornerRadius = 25;
    self.appleLoginButton.layer.masksToBounds = YES;
    self.appleLoginButton.accessibilityLabel = NSLocalizedString(@"login_method_apple", nil);
    
    self.wechatLoginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *wechatImg = [UIImage imageNamed:@"wechat_icon_black"];
    if (wechatImg) {
        [self.wechatLoginButton setImage:[wechatImg imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    } else if (@available(iOS 13.0, *)) {
        [self.wechatLoginButton setImage:[UIImage systemImageNamed:@"message.fill"] forState:UIControlStateNormal];
        self.wechatLoginButton.tintColor = [UIColor blackColor];
    }
    self.wechatLoginButton.backgroundColor = PNFigmaSocialCircleBG();
    self.wechatLoginButton.layer.cornerRadius = 25;
    self.wechatLoginButton.layer.masksToBounds = YES;
    self.wechatLoginButton.accessibilityLabel = NSLocalizedString(@"login_method_wechat", nil);
    
    [self.view addSubview:self.logoCardView];
    [self.logoCardView addSubview:self.logoImageView];
    [self.view addSubview:self.titleLabel];
    [self.view addSubview:self.subtitleLabel];
    [self.view addSubview:self.phoneContainer];
    [self.view addSubview:self.getCodeButton];
    [self.view addSubview:self.agreementStack];
    [self.view addSubview:self.otherLoginLabel];
    [self.view addSubview:self.otherLoginLeftLine];
    [self.view addSubview:self.otherLoginRightLine];
    [self.view addSubview:self.appleLoginButton];
    [self.view addSubview:self.wechatLoginButton];
    
    [self.phoneContainer addSubview:self.countryCodeLabel];
    [self.phoneContainer addSubview:self.phoneSeparatorView];
    [self.phoneContainer addSubview:self.phoneTextField];
    
    [self.agreeCheckButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(24);
    }];
    
    [self.logoCardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(16);
        make.centerX.equalTo(self.view);
        make.width.height.mas_equalTo(160);
    }];
    
    [self.logoImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.logoCardView);
        make.width.height.mas_equalTo(130);
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.logoCardView.mas_bottom).offset(24);
        make.leading.trailing.equalTo(self.view).inset(24);
    }];
    
    [self.phoneContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(24);
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
        make.leading.equalTo(self.countryCodeLabel.mas_trailing).offset(16);
        make.centerY.equalTo(self.phoneContainer);
        make.width.mas_equalTo(1.0);
        make.top.equalTo(self.phoneContainer).offset(12);
        make.bottom.equalTo(self.phoneContainer).offset(-12);
    }];
    
    [self.phoneTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.phoneSeparatorView.mas_trailing).offset(12);
        make.trailing.equalTo(self.phoneContainer).offset(-16);
        make.centerY.equalTo(self.phoneContainer);
    }];
    
    [self.getCodeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.subtitleLabel.mas_bottom).offset(32);
        make.leading.trailing.equalTo(self.view).inset(24);
        make.height.mas_equalTo(54);
    }];
    
    [self.agreementStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.getCodeButton.mas_bottom).offset(16);
        make.centerX.equalTo(self.view);
    }];
    
    [self.otherLoginLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.agreementStack.mas_bottom).offset(36);
        make.centerX.equalTo(self.view);
    }];
    
    [self.otherLoginLeftLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.otherLoginLabel);
        make.leading.equalTo(self.view).offset(24);
        make.trailing.equalTo(self.otherLoginLabel.mas_leading).offset(-12);
        make.height.mas_equalTo(1.0);
    }];
    
    [self.otherLoginRightLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.otherLoginLabel);
        make.leading.equalTo(self.otherLoginLabel.mas_trailing).offset(12);
        make.trailing.equalTo(self.view).offset(-24);
        make.height.mas_equalTo(1.0);
    }];
    
    [self.appleLoginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.otherLoginLabel.mas_bottom).offset(24);
        make.centerX.equalTo(self.view).offset(-40);
        make.width.height.mas_equalTo(50);
    }];
    
    [self.wechatLoginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.otherLoginLabel.mas_bottom).offset(24);
        make.centerX.equalTo(self.view).offset(40);
        make.width.height.mas_equalTo(50);
    }];
}

- (void)textFieldDidChange:(UITextField *)textField {
    [self updateButtonState];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField != self.phoneTextField) return YES;

    NSString *current = textField.text ?: @"";
    NSString *next = [current stringByReplacingCharactersInRange:range withString:(string ?: @"")];
    NSCharacterSet *nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    next = [[next componentsSeparatedByCharactersInSet:nonDigits] componentsJoinedByString:@""];

    static NSInteger const kMaxLen = 11;
    if (next.length > kMaxLen) {
        next = [next substringToIndex:kMaxLen];
        textField.text = next;
        [self updateButtonState];
        return NO;
    }

    BOOL validPhone = (next.length == kMaxLen);
    BOOL enabled = validPhone && self.agreeCheckButton.selected;
    self.getCodeButton.enabled = enabled;
    self.getCodeButton.alpha = enabled ? 1.0 : 0.5;

    return YES;
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
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [AuthManager.sharedManager sendVerifyCode:self.phoneTextField.text success:^(HTTPResponse *response) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        VerifyCodeViewController *vc = VerifyCodeViewController.alloc.init;
        vc.phoneNumber = self.phoneTextField.text;
        [self.navigationController pushViewController:vc animated:YES];
    } failure:^(NSError * _Nonnull error) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [QMUITips showError:error.localizedDescription];
    }];
}

@end
