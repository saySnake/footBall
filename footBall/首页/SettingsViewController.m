//
//  SettingsViewController.m
//  footBall
//
//  Created on 2026/1/15.
//

#import "SettingsViewController.h"
#import "PNCommonAlertViewController.h"
#import "AuthManager.h"
#import "SDImageManager.h"
#import <Masonry/Masonry.h>
#import "ColorManager.h"
#import "PrivacyAgreementViewController.h"
static UIColor * SettingsPageBackgroundColor(void) {
    return [UIColor colorWithRed:0.969 green:0.969 blue:0.969 alpha:1.0];
}

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
    self.view.backgroundColor = SettingsPageBackgroundColor();
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

    /// Figma 1:5503：返回 24×24、x=16；图标优先 nav_back
    UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *backImg = [UIImage imageNamed:@"nav_back"];
    if (!backImg) backImg = [UIImage imageNamed:@"ad_left"];
    if (!backImg && @available(iOS 13.0, *)) {
        backImg = [UIImage systemImageNamed:@"arrow.left"];
    }
    if (backImg) {
        [back setImage:[backImg imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        back.tintColor = [UIColor blackColor];
    }
    back.imageView.contentMode = UIViewContentModeScaleAspectFit;
    back.adjustsImageWhenHighlighted = NO;
    [back addTarget:self action:@selector(onBack) forControlEvents:UIControlEventTouchUpInside];
    [nav addSubview:back];
    [back mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(nav).offset(16);
        make.bottom.equalTo(nav).offset(-10);
        make.size.mas_equalTo(CGSizeMake(24, 24));
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
        make.top.equalTo(nav.mas_bottom).offset(12);
        make.leading.equalTo(self.view).offset(16);
        make.trailing.equalTo(self.view).offset(-16);
    }];

    UIView *row1 = [self addRowToCard:self.listCard top:nil icon:@"setting_noti" titleKey:@"settings_notice" showChevron:NO];
    self.noticeSwitch = [UISwitch new];
    self.noticeSwitch.onTintColor = [ColorManager sharedManager].primaryLightColor;
    // 持久化通知开关状态：默认开启（首次安装），用户切换后记忆选择
    BOOL noticeOn = [[NSUserDefaults standardUserDefaults] objectForKey:@"settings_notice_enabled"] == nil
                    ? YES
                    : [[NSUserDefaults standardUserDefaults] boolForKey:@"settings_notice_enabled"];
    self.noticeSwitch.on = noticeOn;
    [row1 addSubview:self.noticeSwitch];
    [self.noticeSwitch addTarget:self action:@selector(onNoticeSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    [self.noticeSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(row1).offset(-16);
        make.centerY.equalTo(row1);
    }];

    UIView *row2 = [self addRowToCard:self.listCard top:row1 icon:@"setting_privacy" titleKey:@"settings_privacy" showChevron:YES];
    UIControl *privacyTap = (UIControl *)row2;
    [privacyTap addTarget:self action:@selector(onPrivacy) forControlEvents:UIControlEventTouchUpInside];

    UIControl *row3 = (UIControl *)[self addRowToCard:self.listCard top:row2 icon:@"setting_version" titleKey:@"settings_test_version" showChevron:NO];
    self.versionValueLabel = [UILabel new];
    self.versionValueLabel.font = [UIFont systemFontOfSize:13];
    self.versionValueLabel.textColor = [UIColor grayColor];
    self.versionValueLabel.textAlignment = NSTextAlignmentRight;
    [row3 addSubview:self.versionValueLabel];
    [self.versionValueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(row3).offset(-16);
        make.centerY.equalTo(row3);
    }];

    UIControl *row4 = (UIControl *)[self addRowToCard:self.listCard top:row3 icon:@"setting_clean" titleKey:@"settings_clear_data" showChevron:NO];
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
    self.logoutBtn.backgroundColor = [ColorManager sharedManager].primaryColor;
    self.logoutBtn.layer.cornerRadius = 26;
    self.logoutBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [self.logoutBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.logoutBtn addTarget:self action:@selector(onLogout) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.logoutBtn];
    [self.logoutBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.view).offset(24);
        make.trailing.equalTo(self.view).offset(-24);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-24);
        make.height.mas_equalTo(52);
    }];
}

- (void)updateLocalizedStrings {
    [super updateLocalizedStrings];
    self.navTitle.text = NSLocalizedString(@"settings_title", nil);
    [self.logoutBtn setTitle:NSLocalizedString(@"settings_logout", nil) forState:UIControlStateNormal];
    self.versionValueLabel.text = NSLocalizedString(@"settings_test_version_value", nil);
    [self refreshCacheSizeLabel];
}

- (UIControl *)addRowToCard:(UIView *)card top:(UIView * _Nullable)top icon:(NSString *)icon titleKey:(NSString *)titleKey showChevron:(BOOL)showChevron {
    UIControl *row = [UIControl new];
    row.backgroundColor = [UIColor whiteColor];
    [card addSubview:row];
    [row mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(card);
        make.height.mas_equalTo(50);
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
    ic.contentMode = UIViewContentModeScaleAspectFit;
    UIImage *asset = [UIImage imageNamed:icon];
    if (asset) {
        ic.image = asset;
    } else if (@available(iOS 13.0, *)) {
        ic.image = [UIImage systemImageNamed:icon];
        ic.tintColor = [UIColor blackColor];
    }
    [row addSubview:ic];
    [ic mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(row).offset(16);
        make.centerY.equalTo(row);
        make.size.mas_equalTo(CGSizeMake(24, 24));
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
        arr.contentMode = UIViewContentModeScaleAspectFit;
        arr.image = [UIImage imageNamed:@"setting_right"];
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
    PrivacyAgreementViewController *vc = [PrivacyAgreementViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onNoticeSwitchChanged:(UISwitch *)sender {
    // 持久化用户选择，下次进入页面恢复
    [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:@"settings_notice_enabled"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    // 真正注册/注销远程通知需对接后端推送系统，这里先持久化状态；
    // 后续接入 push 系统时，根据 sender.on 调用 UIApplication registerForRemoteNotifications / unregister
    NSString *tip = sender.on ? @"通知已开启" : @"通知已关闭";
    [QMUITips showInfo:tip inView:self.view hideAfterDelay:1.2];
}

#pragma mark - Cache

- (void)refreshCacheSizeLabel {
    self.cacheValueLabel.text = NSLocalizedString(@"settings_calculating", @"计算中...");
    __weak typeof(self) weakSelf = self;
    [self calculateTotalCacheSizeWithCompletion:^(NSUInteger totalBytes) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.cacheValueLabel.text = [weakSelf formattedCacheSize:totalBytes];
        });
    }];
}

- (void)calculateTotalCacheSizeWithCompletion:(void(^)(NSUInteger totalBytes))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 之前这里还单独算了 sdCacheSize / urlCacheSize，但下方 cachesDirSize 已经把
        // Caches 目录整体遍历（SDWebImage 磁盘缓存、NSURLCache 磁盘缓存都在该目录下），
        // 重复计算会让用户看到的缓存数字虚高，故移除。

        NSUInteger tmpSize = [self folderSizeAtPath:NSTemporaryDirectory()];

        NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSUInteger cachesDirSize = 0;
        if (cachePaths.count > 0) {
            cachesDirSize = [self folderSizeAtPath:cachePaths.firstObject];
        }

        NSUInteger total = cachesDirSize + tmpSize;
        if (completion) completion(total);
    });
}

- (NSUInteger)folderSizeAtPath:(NSString *)path {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSUInteger size = 0;
    NSDirectoryEnumerator *enumerator = [fm enumeratorAtPath:path];
    for (NSString *fileName in enumerator) {
        NSString *fullPath = [path stringByAppendingPathComponent:fileName];
        NSDictionary *attrs = [fm attributesOfItemAtPath:fullPath error:nil];
        if (attrs[NSFileSize]) {
            size += [attrs[NSFileSize] unsignedIntegerValue];
        }
    }
    return size;
}

- (NSString *)formattedCacheSize:(NSUInteger)bytes {
    if (bytes >= 1024 * 1024 * 1024) {
        return [NSString stringWithFormat:@"%.1f GB", bytes / (1024.0 * 1024.0 * 1024.0)];
    } else if (bytes >= 1024 * 1024) {
        return [NSString stringWithFormat:@"%.1f MB", bytes / (1024.0 * 1024.0)];
    } else if (bytes >= 1024) {
        return [NSString stringWithFormat:@"%.1f KB", bytes / 1024.0];
    }
    return @"0 KB";
}

- (void)onClearData {
    PNCommonAlertViewController *alert = [PNCommonAlertViewController new];
    alert.alertTitle = NSLocalizedString(@"settings_alert_title", @"提示");
    alert.message = NSLocalizedString(@"settings_clear_data_confirm", @"确认清除后将立即\n清除缓存");
    alert.cancelTitle = NSLocalizedString(@"cancel", nil);
    alert.confirmTitle = NSLocalizedString(@"confirm", nil);
    __weak typeof(self) weakSelf = self;
    alert.onConfirm = ^{
        [weakSelf performClearData];
    };
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)performClearData {
    self.cacheValueLabel.text = NSLocalizedString(@"settings_clearing", @"清除中...");
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 1. SDWebImage 缓存
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        [[SDImageManager sharedManager] clearAllCacheWithCompletion:^{
            dispatch_semaphore_signal(sema);
        }];
        dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC));

        // 2. NSURLCache
        [[NSURLCache sharedURLCache] removeAllCachedResponses];

        // 3. tmp 目录
        NSFileManager *fm = [NSFileManager defaultManager];
        NSString *tmpDir = NSTemporaryDirectory();
        NSArray *tmpFiles = [fm contentsOfDirectoryAtPath:tmpDir error:nil];
        for (NSString *file in tmpFiles) {
            [fm removeItemAtPath:[tmpDir stringByAppendingPathComponent:file] error:nil];
        }

        // 4. Caches 目录下非必要文件（保留 Snapshots 等系统目录）
        NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        if (cachePaths.count > 0) {
            NSString *cachesDir = cachePaths.firstObject;
            NSArray *cacheFiles = [fm contentsOfDirectoryAtPath:cachesDir error:nil];
            NSSet *keepDirs = [NSSet setWithArray:@[
                @"Snapshots",                    // 截图回放系统目录
                @"com.apple.nsurlsessiond",      // NSURLSession 系统缓存
                @"CloudKit",                     // CloudKit 容器
                @"CoreSimulator",                // 模拟器容器（开发期）
                @"UIKitBadge",                   // 系统角标缓存
                @"com.apple.assetsd",            // 系统资源服务
            ]];
            for (NSString *file in cacheFiles) {
                if ([keepDirs containsObject:file]) continue;
                [fm removeItemAtPath:[cachesDir stringByAppendingPathComponent:file] error:nil];
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf refreshCacheSizeLabel];
        });
    });
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
    __weak typeof(self) weakSelf = self;
    [[AuthManager sharedManager] logoutSuccess:^(HTTPResponse * _Nullable responseObject) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [self routeToLoginAfterLogout];
    } failure:^(NSError * _Nonnull error) {
        // 服务端退出失败时，仍执行本地清理，避免用户无法退出
        [[AuthManager sharedManager] removeUser];
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [self routeToLoginAfterLogout];
    }];
}

- (void)routeToLoginAfterLogout {
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
