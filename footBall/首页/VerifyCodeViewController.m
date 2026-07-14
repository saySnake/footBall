//
//  VerifyCodeViewController.m
//  footBall
//
//  Figma「手机号登录 / 验证码」r2NHY24zoL00k6JFuwivYz / 1:4044
//

#import "VerifyCodeViewController.h"
#import "AuthManager.h"
#import "TeamSelectionViewController.h"
#import <Masonry/Masonry.h>
#import "MainTabBarController.h"
#import <QMUIKit/QMUIKit.h>
#import <MBProgressHUD/MBProgressHUD.h>

/// 六位格子底 #f6f6f6、圆角 6
static UIColor *kVCBoxBG(void) {
    return [ColorManager colorWithHexString:@"#f6f6f6"];
}
/// 副文案 / 重发 #656565
static UIColor *kVCMutedText(void) {
    return [ColorManager colorWithHexString:@"#656565"];
}
/// 手机号强调 #1c1c1c
static UIColor *kVCPhoneText(void) {
    return [ColorManager colorWithHexString:@"#1c1c1c"];
}
/// 主按钮 #285d4b；阴影 0/2/4 @ 19%
static UIColor *kVCBrandGreen(void) {
    return [ColorManager colorWithHexString:@"#285d4b"];
}
/// 稿中待输入光标 #939393
static UIColor *kVCCaretGray(void) {
    return [ColorManager colorWithHexString:@"#939393"];
}

static const NSInteger kVCResendCountdownSeconds = 60;

@interface VerifyCodeViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UIView *customNavBar;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIStackView *codeStackView;
@property (nonatomic, strong) NSArray<UILabel *> *codeLabels;
@property (nonatomic, strong) UITextField *codeTextField;
@property (nonatomic, strong) UIButton *loginButton;
@property (nonatomic, strong) UIButton *resendButton;
@property (nonatomic, strong) UIView *caretView;
@property (nonatomic, strong) NSTimer *caretBlinkTimer;
@property (nonatomic, strong) NSTimer *resendCountdownTimer;
@property (nonatomic, assign) NSInteger resendCountdownRemaining;
@property (nonatomic, assign) BOOL resendRequesting;

@end

@implementation VerifyCodeViewController

- (BOOL)isDeactivateFlow {
    return self.purpose == VerifyCodePurposeDeactivateAccount;
}

- (void)applyPurposeCopy {
    if ([self isDeactivateFlow]) {
        self.titleLabel.text = NSLocalizedString(@"verify_deactivate_title", nil);
        [self.loginButton setTitle:NSLocalizedString(@"verify_deactivate_button", nil) forState:UIControlStateNormal];
    } else {
        self.titleLabel.text = NSLocalizedString(@"verify_title", nil);
        [self.loginButton setTitle:NSLocalizedString(@"verify_login_button", nil) forState:UIControlStateNormal];
    }
}

- (void)dealloc {
    [self stopCaretBlink];
    [self stopResendCountdown];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];

    [self setupUI];
    [self applyPurposeCopy];
    [self updateButtonState];
    [self updateCaretDisplay];
    // 上一页已发过验证码，进入本页即进入倒计时，避免连点重发
    [self startResendCountdown];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self updateCaretDisplay];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.codeTextField becomeFirstResponder];
    [self startCaretBlink];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopCaretBlink];
}

#pragma mark - Resend countdown

- (void)startResendCountdown {
    [self stopResendCountdown];
    self.resendCountdownRemaining = kVCResendCountdownSeconds;
    [self applyResendCountdownUI];
    __weak typeof(self) weakSelf = self;
    self.resendCountdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            [timer invalidate];
            return;
        }
        self.resendCountdownRemaining -= 1;
        if (self.resendCountdownRemaining <= 0) {
            [self stopResendCountdown];
            [self applyResendIdleUI];
            return;
        }
        [self applyResendCountdownUI];
    }];
    [[NSRunLoop mainRunLoop] addTimer:self.resendCountdownTimer forMode:NSRunLoopCommonModes];
}

- (void)stopResendCountdown {
    [self.resendCountdownTimer invalidate];
    self.resendCountdownTimer = nil;
    self.resendCountdownRemaining = 0;
}

- (void)applyResendCountdownUI {
    self.resendButton.enabled = NO;
    self.resendButton.alpha = 0.55;
    [self.resendButton setImage:nil forState:UIControlStateNormal];
    NSString *format = NSLocalizedString(@"verify_resend_countdown", @"%lds 后重新获取");
    [self.resendButton setTitle:[NSString stringWithFormat:format, (long)self.resendCountdownRemaining]
                       forState:UIControlStateNormal];
    [self.resendButton setTitleColor:kVCMutedText() forState:UIControlStateNormal];
    self.resendButton.tintColor = kVCMutedText();
}

- (void)applyResendIdleUI {
    self.resendButton.enabled = YES;
    self.resendButton.alpha = 1.0;
    UIImage *resetIcon = [[UIImage imageNamed:@"reset_msg"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.resendButton setImage:resetIcon forState:UIControlStateNormal];
    [self.resendButton setTitle:NSLocalizedString(@"verify_resend_button", nil) forState:UIControlStateNormal];
    [self.resendButton setTitleColor:kVCMutedText() forState:UIControlStateNormal];
    self.resendButton.tintColor = kVCMutedText();
}

- (NSString *)formattedDisplayPhone:(NSString *)raw {
    if (raw.length == 0) {
        return @"";
    }
    NSCharacterSet *nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSString *d = [[raw componentsSeparatedByCharactersInSet:nonDigits] componentsJoinedByString:@""];
    if (d.length == 11) {
        return [NSString stringWithFormat:@"%@ %@ %@", [d substringToIndex:3], [d substringWithRange:NSMakeRange(3, 4)], [d substringFromIndex:7]];
    }
    return raw;
}

- (NSAttributedString *)buildSubtitleAttributedString {
    NSString *phone = self.phoneNumber.length > 0 ? self.phoneNumber : @"";
    NSString *display = [self formattedDisplayPhone:phone];
    NSString *format = NSLocalizedString(@"verify_subtitle_format", nil);
    NSString *full = [NSString stringWithFormat:format, display.length ? display : @"—"];

    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:full];
    [attr addAttribute:NSForegroundColorAttributeName value:kVCMutedText() range:NSMakeRange(0, full.length)];
    [attr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:14 weight:UIFontWeightRegular] range:NSMakeRange(0, full.length)];

    NSMutableParagraphStyle *para = [[NSMutableParagraphStyle alloc] init];
    para.lineSpacing = 5;
    para.alignment = NSTextAlignmentLeft;
    [attr addAttribute:NSParagraphStyleAttributeName value:para range:NSMakeRange(0, full.length)];

    if (display.length > 0) {
        NSRange phoneRange = [full rangeOfString:display];
        if (phoneRange.location != NSNotFound) {
            [attr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:14 weight:UIFontWeightSemibold] range:phoneRange];
            [attr addAttribute:NSForegroundColorAttributeName value:kVCPhoneText() range:phoneRange];
        }
    }
    return attr;
}

- (void)setupUI {
    UIView *navBar = [[UIView alloc] init];
    navBar.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:navBar];
    self.customNavBar = navBar;
    [navBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(44);
    }];

    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *backImage = [UIImage imageNamed:@"left"];
    if (!backImage && @available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightSemibold];
        backImage = [UIImage systemImageNamed:@"chevron.left" withConfiguration:cfg];
    }
    [backBtn setImage:[backImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    backBtn.tintColor = [UIColor blackColor];
    backBtn.backgroundColor = [UIColor clearColor];
    backBtn.adjustsImageWhenHighlighted = NO;
    [backBtn addTarget:self action:@selector(handleBack) forControlEvents:UIControlEventTouchUpInside];
    [navBar addSubview:backBtn];
    [backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(navBar).offset(16);
        make.bottom.equalTo(navBar).offset(-10);
        make.width.height.mas_equalTo(24);
    }];

    UILabel *navTitle = [[UILabel alloc] init];
    NSString *navTitleText = NSLocalizedString(@"login_nav_title", nil);
    navTitle.text = navTitleText.length > 0 ? navTitleText : @"登录注册";
    navTitle.font = [UIFont boldSystemFontOfSize:17];
    navTitle.textColor = [UIColor blackColor];
    [navBar addSubview:navTitle];
    [navTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(navBar);
        make.centerY.equalTo(backBtn);
    }];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = NSLocalizedString(@"verify_title", nil);
    self.titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    self.titleLabel.textColor = [UIColor blackColor];
    self.titleLabel.numberOfLines = 1;

    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.numberOfLines = 0;
    self.subtitleLabel.attributedText = [self buildSubtitleAttributedString];

    NSMutableArray<UILabel *> *labels = [NSMutableArray arrayWithCapacity:6];
    self.codeStackView = [[UIStackView alloc] init];
    self.codeStackView.axis = UILayoutConstraintAxisHorizontal;
    self.codeStackView.spacing = 8.0;
    self.codeStackView.distribution = UIStackViewDistributionFillEqually;
    self.codeStackView.alignment = UIStackViewAlignmentFill;

    UIFont *digitFont = [UIFont fontWithName:@"BebasNeue-Regular" size:26];
    if (!digitFont) {
        digitFont = [UIFont monospacedDigitSystemFontOfSize:26 weight:UIFontWeightSemibold];
    }

    for (NSInteger i = 0; i < 6; i++) {
        UILabel *label = [[UILabel alloc] init];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = digitFont;
        label.textColor = [UIColor blackColor];
        label.backgroundColor = kVCBoxBG();
        label.layer.cornerRadius = 6.0;
        label.layer.masksToBounds = YES;
        // 光标与格子同属 stackView 时，需保证数字始终压在光标之上，否则看起来像「码被挡住」
        label.layer.zPosition = 1;
        [self.codeStackView addArrangedSubview:label];
        [labels addObject:label];
    }
    self.codeLabels = [labels copy];

    self.caretView = [[UIView alloc] init];
    self.caretView.backgroundColor = kVCCaretGray();
    self.caretView.layer.cornerRadius = 1.0;
    self.caretView.hidden = YES;
    self.caretView.layer.zPosition = 0;
    [self.codeStackView addSubview:self.caretView];

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

    self.loginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.loginButton setTitle:NSLocalizedString(@"verify_login_button", nil) forState:UIControlStateNormal];
    [self.loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.loginButton.backgroundColor = kVCBrandGreen();
    self.loginButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.loginButton.layer.cornerRadius = 27.0;
    self.loginButton.layer.masksToBounds = NO;
    self.loginButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.loginButton.layer.shadowOpacity = 0.19f;
    self.loginButton.layer.shadowOffset = CGSizeMake(0, 2);
    self.loginButton.layer.shadowRadius = 4.0;
    [self.loginButton addTarget:self action:@selector(loginTapped) forControlEvents:UIControlEventTouchUpInside];

    self.resendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.resendButton setTitle:NSLocalizedString(@"verify_resend_button", nil) forState:UIControlStateNormal];
    self.resendButton.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    [self.resendButton setTitleColor:kVCMutedText() forState:UIControlStateNormal];
    self.resendButton.tintColor = kVCMutedText();
    UIImage *resetIcon = [[UIImage imageNamed:@"reset_msg"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.resendButton setImage:resetIcon forState:UIControlStateNormal];
    self.resendButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.resendButton.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
    self.resendButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    self.resendButton.titleEdgeInsets = UIEdgeInsetsMake(0, 6, 0, 0);
    self.resendButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.resendButton.titleLabel.numberOfLines = 1;
    self.resendButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.resendButton.titleLabel.minimumScaleFactor = 0.82f;
    [self.resendButton setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self.resendButton setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self.resendButton addTarget:self action:@selector(resendTapped) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:self.titleLabel];
    [self.view addSubview:self.subtitleLabel];
    [self.view addSubview:self.codeStackView];
    [self.view addSubview:self.codeTextField];
    [self.view addSubview:self.resendButton];
    [self.view addSubview:self.loginButton];

    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(navBar.mas_bottom).offset(48);
        make.leading.equalTo(self.view).offset(24);
        make.trailing.lessThanOrEqualTo(self.view).offset(-24);
    }];

    [self.subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(16);
        make.leading.trailing.equalTo(self.view).inset(24);
    }];

    [self.codeStackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.subtitleLabel.mas_bottom).offset(28);
        make.leading.trailing.equalTo(self.view).inset(24);
        make.height.mas_equalTo(58);
    }];

    [self.codeTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.codeStackView.mas_bottom);
        make.leading.equalTo(self.view.mas_leading);
        make.width.height.mas_equalTo(1.0);
    }];

    [self.resendButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.codeStackView.mas_bottom).offset(18);
        make.leading.greaterThanOrEqualTo(self.view).offset(24);
        make.trailing.equalTo(self.view).offset(-24);
    }];

    [self.loginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.resendButton.mas_bottom).offset(36);
        make.leading.trailing.equalTo(self.view).inset(24);
        make.height.mas_equalTo(54);
    }];
}

- (void)startCaretBlink {
    [self stopCaretBlink];
    self.caretBlinkTimer = [NSTimer scheduledTimerWithTimeInterval:0.53 target:self selector:@selector(caretBlinkTick) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.caretBlinkTimer forMode:NSRunLoopCommonModes];
}

- (void)caretBlinkTick {
    self.caretView.alpha = self.caretView.alpha < 0.5 ? 1.0 : 0.15;
}

- (void)stopCaretBlink {
    [self.caretBlinkTimer invalidate];
    self.caretBlinkTimer = nil;
    self.caretView.alpha = 1.0;
}

- (void)updateCaretDisplay {
    NSString *code = self.codeTextField.text ?: @"";
    NSUInteger n = code.length;
    if (n >= 6) {
        self.caretView.hidden = YES;
        return;
    }
    UILabel *cell = self.codeLabels[n];
    self.caretView.hidden = NO;
    [self.caretView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(cell);
        make.centerY.equalTo(cell);
        make.width.mas_equalTo(2);
        make.height.mas_equalTo(26);
    }];
    // 勿 bringSubviewToFront 光标，否则会盖住已输入数字（格子与光标同父 view 时后加的子视图在上层）
    [self.codeStackView layoutIfNeeded];
}

- (void)textFieldDidChange:(UITextField *)textField {
    if (textField.text.length > 6) {
        textField.text = [textField.text substringToIndex:6];
    }

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

    [self updateCaretDisplay];
    [self updateButtonState];
}

- (void)updateButtonState {
    BOOL enabled = self.codeTextField.text.length == 6;
    self.loginButton.enabled = enabled;
    self.loginButton.alpha = enabled ? 1.0 : 0.55;
}

- (void)resendTapped {
    if (self.resendCountdownRemaining > 0 || self.resendRequesting || !self.resendButton.enabled) {
        return;
    }
    NSString *phone = self.phoneNumber ?: @"";
    if (phone.length == 0) {
        return;
    }
    self.resendRequesting = YES;
    self.resendButton.enabled = NO;
    __weak typeof(self) weakSelf = self;
    [AuthManager.sharedManager sendVerifyCode:phone success:^(HTTPResponse * _Nonnull response) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        self.resendRequesting = NO;
        [QMUITips showSucceed:NSLocalizedString(@"verify_code_sent", nil) inView:self.view hideAfterDelay:1.5];
        [self startResendCountdown];
    } failure:^(NSError * _Nonnull error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        self.resendRequesting = NO;
        [self applyResendIdleUI];
        [QMUITips showError:error.localizedDescription];
    }];
}

- (void)loginTapped {
    if (!self.loginButton.enabled) {
        return;
    }

    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    if ([self isDeactivateFlow]) {
        [AuthManager.sharedManager deactivateAccountWithCode:self.codeTextField.text success:^(HTTPResponse * _Nonnull response) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            [self routeToLoginAfterDeactivate];
        } failure:^(NSError * _Nonnull error) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            [QMUITips showError:error.localizedDescription inView:self.view hideAfterDelay:2.0];
        }];
        return;
    }

    [AuthManager.sharedManager loginPhone:self.phoneNumber verify:self.codeTextField.text success:^(HTTPResponse * _Nonnull response) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
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

- (void)routeToLoginAfterDeactivate {
    UIWindow *window = self.view.window;
    if (!window) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (![scene isKindOfClass:[UIWindowScene class]]) continue;
            UIWindowScene *ws = (UIWindowScene *)scene;
            for (UIWindow *w in ws.windows) {
                if (w.isKeyWindow) { window = w; break; }
            }
            if (window) break;
        }
    }
    if (!window) return;

    Class loginClass = NSClassFromString(@"LoginChoiceViewController");
    UIViewController *loginVC = loginClass ? [loginClass new] : [UIViewController new];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginVC];
    [UIView transitionWithView:window duration:0.25 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        window.rootViewController = nav;
    } completion:nil];
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
