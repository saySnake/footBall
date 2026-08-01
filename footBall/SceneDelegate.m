//
//  SceneDelegate.m
//  footBall
//
//  Created on 2026/1/15.
//

#import "SceneDelegate.h"
#import "MainTabBarController.h"
#import "AuthManager.h"
#import "ThemeObserverView.h"
#ifdef DEBUG
#import <DoraemonKit/DoraemonManager.h>
#import "BVAPPDebugTool.h"
#import "BVAPPEnvironmentHostManager.h"
#endif
#import "LoginChoiceViewController.h"
#import "TeamSelectionViewController.h"
#import "PNAppVersionManager.h"
#import "PNAppVersionInfo.h"
#import "PNIAPObserver.h"

@interface SceneDelegate ()

@property (nonatomic, strong) ThemeObserverView *themeObserverView;
@property (nonatomic, assign) BOOL didInstallRootAfterVersionCheck;

@end

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) {
        return;
    }
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    self.window.rootViewController = [[UIViewController alloc] init];
    self.window.rootViewController.view.backgroundColor = [UIColor colorWithRed:0.051 green:0.129 blue:0.133 alpha:1.0];
    [self.window makeKeyAndVisible];

    [self setupThemeObserver];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenExpiredNotification) name:TokenExpiredNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onForceUpdateRequired:)
                                                 name:PNAppVersionForceUpdateRequiredNotification
                                               object:nil];

    __weak typeof(self) weakSelf = self;
    [[PNAppVersionManager shared] checkForceUpdateWithCompletion:^(BOOL needsForceUpdate, PNAppVersionInfo * _Nullable info, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            if (needsForceUpdate && info) {
                [[PNAppVersionManager shared] presentForceUpdateOnWindow:self.window info:info];
                return;
            }
            [self installRootViewControllerIfNeeded];
        });
    }];

#ifdef DEBUG
#endif
}

- (void)installRootViewControllerIfNeeded {
    if (self.didInstallRootAfterVersionCheck) {
        return;
    }
    self.didInstallRootAfterVersionCheck = YES;
    if ([AuthManager sharedManager].isLoggedIn) {
        self.window.rootViewController = [[MainTabBarController alloc] init];
        // 已登录：启动 IAP 全局观察者，处理上次被杀进程时遗留的未 finish 事务（掉单恢复）
        [[PNIAPObserver shared] start];
        // 主动扫描队列中残留事务，触发 verifyPurchase 兜底上报
        [[PNIAPObserver shared] resumePendingTransactions];
    } else {
        LoginChoiceViewController *loginVC = [LoginChoiceViewController new];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginVC];
        self.window.rootViewController = nav;
    }
}

- (void)onForceUpdateRequired:(NSNotification *)notification {
    PNAppVersionInfo *info = notification.userInfo[@"info"];
    if ([info isKindOfClass:PNAppVersionInfo.class] && self.window) {
        [[PNAppVersionManager shared] presentForceUpdateOnWindow:self.window info:info];
    }
}

- (void)tokenExpiredNotification {
    if ([PNAppVersionManager shared].forceUpdateWindow) {
        return;
    }
    LoginChoiceViewController *rootVC = [LoginChoiceViewController new];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:rootVC];
    self.window.rootViewController = nav;
    // Token 过期强制退出登录：与 SettingsViewController.routeToLoginAfterLogout 一致，
    // 停止 IAP 观察者避免换账号后跨账号激活会员。
    [[PNIAPObserver shared] stop];
}

- (void)sceneDidDisconnect:(UIScene *)scene {
}

- (void)sceneDidBecomeActive:(UIScene *)scene {
    if ([PNAppVersionManager shared].forceUpdateWindow) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [[PNAppVersionManager shared] checkForceUpdateWithCompletion:^(BOOL needsForceUpdate, PNAppVersionInfo * _Nullable info, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (needsForceUpdate && info) {
                UIWindow *window = weakSelf.window ?: [[PNAppVersionManager shared] keyWindow];
                if (window) {
                    [[PNAppVersionManager shared] presentForceUpdateOnWindow:window info:info];
                }
            }
        });
    }];
}

- (void)sceneWillResignActive:(UIScene *)scene {
}

- (void)sceneWillEnterForeground:(UIScene *)scene {
}

- (void)sceneDidEnterBackground:(UIScene *)scene {
}

#pragma mark - Theme Observer

- (void)setupThemeObserver {
    self.themeObserverView = [[ThemeObserverView alloc] initWithFrame:self.window.bounds];
    self.themeObserverView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.window addSubview:self.themeObserverView];
    [self.window sendSubviewToBack:self.themeObserverView];
}

@end
