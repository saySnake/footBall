//
//  ThemeManager.m
//  footBall
//
//  Created on 2026/1/15.
//

#import "ThemeManager.h"

NSString *const AppThemeDidChangeNotification = @"AppThemeDidChangeNotification";

static NSString *const kUserDefaultsNightModeKey = @"AppNightMode";

@interface ThemeManager ()

@end

@implementation ThemeManager

+ (instancetype)sharedManager {
    static ThemeManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ThemeManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 读取持久化的夜间模式开关（首次安装默认为 NO）
        _nightMode = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultsNightModeKey];
    }
    return self;
}

#pragma mark - Night Mode

- (void)setNightMode:(BOOL)nightMode {
    [self setNightMode:nightMode notify:YES];
}

- (void)setNightMode:(BOOL)nightMode notify:(BOOL)notify {
    if (_nightMode == nightMode) {
        return;
    }

    _nightMode = nightMode;

    // 持久化
    [[NSUserDefaults standardUserDefaults] setBool:nightMode forKey:kUserDefaultsNightModeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    if (notify) {
        // 把当前 window 的 overrideUserInterfaceStyle 同步到新的主题状态
        [self applyAppearanceToActiveWindow];

        // 发送通知，让各视图控制器/视图刷新
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:AppThemeDidChangeNotification
                                                                object:nil
                                                              userInfo:@{@"nightMode": @(nightMode)}];
        });
    }
}

#pragma mark - Setup

- (void)setupThemeConfiguration {
    [self applyAppearanceToActiveWindow];
}

#pragma mark - Appearance

- (void)applyAppearanceToWindow:(UIWindow *)window {
    if (!window) {
        return;
    }
    if (@available(iOS 13.0, *)) {
        // 锁定系统的动态颜色路径：把 window 固定成 Light/Dark，
        // systemBackgroundColor 这类动态色就不会再跟着系统主题跑了。
        window.overrideUserInterfaceStyle = self.nightMode
            ? UIUserInterfaceStyleDark
            : UIUserInterfaceStyleLight;
    }
}

- (void)applyAppearanceToActiveWindow {
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        [self applyAppearanceToWindow:window];
    }

    // 状态栏样式
    if (@available(iOS 13.0, *)) {
        [UIApplication sharedApplication].statusBarStyle =
            self.nightMode ? UIStatusBarStyleLightContent : UIStatusBarStyleDarkContent;
    }
}

#pragma mark - Colors

- (UIColor *)primaryColor {
    // 主品牌色 #1A5B47
    return [UIColor colorWithRed:0x1A/255.0 green:0x5B/255.0 blue:0x47/255.0 alpha:1.0];
}

- (UIColor *)backgroundColor {
    return self.nightMode
        ? [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0]
        : [UIColor colorWithRed:0.051 green:0.129 blue:0.133 alpha:1.0];
}

- (UIColor *)textColor {
    return self.nightMode ? [UIColor whiteColor] : [UIColor blackColor];
}

- (UIColor *)secondaryTextColor {
    return self.nightMode
        ? [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0]
        : [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0];
}

- (UIColor *)separatorColor {
    return self.nightMode
        ? [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0]
        : [UIColor colorWithRed:0.78 green:0.78 blue:0.8 alpha:1.0];
}

@end
