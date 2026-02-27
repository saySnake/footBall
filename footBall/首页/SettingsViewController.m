//
//  SettingsViewController.m
//  footBall
//
//  Created on 2026/1/15.
//

#import "SettingsViewController.h"
#import "PNCommonAlertViewController.h"
#import "AuthManager.h"
#import <Masonry/Masonry.h>

@interface SettingsViewController ()
@property (nonatomic, strong) UILabel *navTitle;
@property (nonatomic, strong) UIView *listCard;
@property (nonatomic, strong) UISwitch *noticeSwitch;
@property (nonatomic, strong) UILabel *versionValueLabel;
@property (nonatomic, strong) UILabel *cacheValueLabel;
@property (nonatomic, strong) UIButton *logoutBtn;
@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.shouldShowNavigationBar = NO;
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)setupUI {
    // Nav
    UIView *nav = [UIView new];
    nav.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:nav];
    [nav mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
        make.height.mas_equalTo(88);
    }];

    UIButton *back = [UIButton buttonWithType:UIButtonTypeSystem];
    if (@available(iOS 13.0, *)) [back setImage:[UIImage systemImageNamed:@"arrow.left"] forState:UIControlStateNormal];
    back.tintColor = [UIColor blackColor];
    [back addTarget:self action:@selector(onBack) forControlEvents:UIControlEventTouchUpInside];
    [nav addSubview:back];
    [back mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(nav).offset(12);
        make.bottom.equalTo(nav).offset(-10);
        make.size.mas_equalTo(CGSizeMake(36, 36));
    }];

    self.navTitle = [UILabel new];
    self.navTitle.font = [UIFont boldSystemFontOfSize:17];
    self.navTitle.textColor = [UIColor blackColor];
    [nav addSubview:self.navTitle];
    [self.navTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(nav);
        make.centerY.equalTo(back);
    }];

    // List card
    self.listCard = [UIView new];
    self.listCard.backgroundColor = [UIColor whiteColor];
    self.listCard.layer.cornerRadius = 12;
    self.listCard.clipsToBounds = YES;
    [self.view addSubview:self.listCard];
    [self.listCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(nav.mas_bottom).offset(10);
        make.leading.equalTo(self.view).offset(12);
        make.trailing.equalTo(self.view).offset(-12);
    }];

    UIView *row1 = [self addRowToCard:self.listCard top:nil icon:@"bell" titleKey:@"settings_notice" showChevron:NO];
    self.noticeSwitch = [UISwitch new];
    self.noticeSwitch.onTintColor = [UIColor colorWithRed:0.10 green:0.36 blue:0.28 alpha:1.0];
    self.noticeSwitch.on = YES;
    [row1 addSubview:self.noticeSwitch];
    [self.noticeSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(row1).offset(-16);
        make.centerY.equalTo(row1);
    }];

    UIView *row2 = [self addRowToCard:self.listCard top:row1 icon:@"shield" titleKey:@"settings_privacy" showChevron:YES];
    UIControl *privacyTap = (UIControl *)row2;
    [privacyTap addTarget:self action:@selector(onPrivacy) forControlEvents:UIControlEventTouchUpInside];

    UIControl *row3 = (UIControl *)[self addRowToCard:self.listCard top:row2 icon:@"checkmark.seal" titleKey:@"settings_test_version" showChevron:NO];
    self.versionValueLabel = [UILabel new];
    self.versionValueLabel.font = [UIFont systemFontOfSize:13];
    self.versionValueLabel.textColor = [UIColor grayColor];
    self.versionValueLabel.textAlignment = NSTextAlignmentRight;
    [row3 addSubview:self.versionValueLabel];
    [self.versionValueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(row3).offset(-16);
        make.centerY.equalTo(row3);
    }];

    UIControl *row4 = (UIControl *)[self addRowToCard:self.listCard top:row3 icon:@"trash" titleKey:@"settings_clear_data" showChevron:NO];
    [row4 addTarget:self action:@selector(onClearData) forControlEvents:UIControlEventTouchUpInside];
    self.cacheValueLabel = [UILabel new];
    self.cacheValueLabel.font = [UIFont systemFontOfSize:13];
    self.cacheValueLabel.textColor = [UIColor grayColor];
    self.cacheValueLabel.textAlignment = NSTextAlignmentRight;
    [row4 addSubview:self.cacheValueLabel];
    [self.cacheValueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(row4).offset(-16);
        make.centerY.equalTo(row4);
    }];

    [self.listCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(row4);
    }];

    // Logout button
    self.logoutBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    self.logoutBtn.backgroundColor = [UIColor colorWithRed:0.10 green:0.36 blue:0.28 alpha:1.0];
    self.logoutBtn.layer.cornerRadius = 24;
    self.logoutBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [self.logoutBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.logoutBtn addTarget:self action:@selector(onLogout) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.logoutBtn];
    [self.logoutBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.view).offset(24);
        make.trailing.equalTo(self.view).offset(-24);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-24);
        make.height.mas_equalTo(48);
    }];
}

- (void)updateLocalizedStrings {
    [super updateLocalizedStrings];
    self.navTitle.text = NSLocalizedString(@"settings_title", nil);
    [self.logoutBtn setTitle:NSLocalizedString(@"settings_logout", nil) forState:UIControlStateNormal];
    self.versionValueLabel.text = NSLocalizedString(@"settings_test_version_value", nil);
    self.cacheValueLabel.text = NSLocalizedString(@"settings_clear_data_value", nil);
}

- (UIControl *)addRowToCard:(UIView *)card top:(UIView * _Nullable)top icon:(NSString *)icon titleKey:(NSString *)titleKey showChevron:(BOOL)showChevron {
    UIControl *row = [UIControl new];
    row.backgroundColor = [UIColor whiteColor];
    [card addSubview:row];
    [row mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(card);
        make.height.mas_equalTo(52);
        if (top) make.top.equalTo(top.mas_bottom);
        else make.top.equalTo(card);
    }];
    if (top) {
        UIView *line = [UIView new];
        line.backgroundColor = [UIColor colorWithWhite:0.90 alpha:1.0];
        [card addSubview:line];
        [line mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(row);
            make.leading.equalTo(card).offset(16);
            make.trailing.equalTo(card);
            make.height.mas_equalTo(0.5);
        }];
    }

    UIImageView *ic = [UIImageView new];
    if (@available(iOS 13.0, *)) {
        ic.image = [UIImage systemImageNamed:icon];
        ic.tintColor = [UIColor blackColor];
    }
    ic.contentMode = UIViewContentModeScaleAspectFit;
    [row addSubview:ic];
    [ic mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(row).offset(16);
        make.centerY.equalTo(row);
        make.size.mas_equalTo(CGSizeMake(18, 18));
    }];

    UILabel *lbl = [UILabel new];
    lbl.font = [UIFont systemFontOfSize:15];
    lbl.textColor = [UIColor blackColor];
    lbl.text = NSLocalizedString(titleKey, nil);
    [row addSubview:lbl];
    [lbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(ic.mas_trailing).offset(10);
        make.centerY.equalTo(row);
    }];

    if (showChevron) {
        UIImageView *arr = [UIImageView new];
        if (@available(iOS 13.0, *)) {
            arr.image = [UIImage systemImageNamed:@"chevron.right"];
            arr.tintColor = [UIColor colorWithWhite:0.65 alpha:1.0];
        }
        [row addSubview:arr];
        [arr mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(row).offset(-16);
            make.centerY.equalTo(row);
            make.size.mas_equalTo(CGSizeMake(14, 14));
        }];
    }
    return row;
}

- (void)onBack { [self.navigationController popViewControllerAnimated:YES]; }

- (void)onPrivacy {
    // 原型仅跳转入口，这里先做占位
}

- (void)onClearData {
    // 原型仅展示入口，这里先做占位
}

- (void)onLogout {
    PNCommonAlertViewController *alert = [PNCommonAlertViewController new];
    alert.alertTitle = NSLocalizedString(@"settings_alert_title", nil);
    alert.message = NSLocalizedString(@"settings_logout_confirm", nil);
    alert.cancelTitle = NSLocalizedString(@"cancel", nil);
    alert.confirmTitle = NSLocalizedString(@"confirm", nil);
    __weak typeof(self) weakSelf = self;
    alert.onConfirm = ^{
        [weakSelf performLogoutAndGoLogin];
    };
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)performLogoutAndGoLogin {
    [[AuthManager sharedManager] clearToken];

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

@end
