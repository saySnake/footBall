//
//  ThemeManager.m
//  footBall
//
//  Created on 2026/1/15.
//

#import "ThemeManager.h"

NSString *const AppThemeDidChangeNotification = @"AppThemeDidChangeNotification";

static NSString *const kUserDefaultsThemeKey = @"AppCurrentTheme";

@interface ThemeManager ()

// 注意：currentTheme 和 followSystem 已在主接口中声明，这里不需要重复声明

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
        // 从UserDefaults读取保存的主题设置
        NSInteger savedTheme = [[NSUserDefaults standardUserDefaults] integerForKey:kUserDefaultsThemeKey];
        if (savedTheme >= 0 && savedTheme <= 2) {
            _currentTheme = (AppTheme)savedTheme;
        } else {
            _currentTheme = AppThemeAuto;
        }
        
        _followSystem = YES;
        
        // 监听系统主题变化
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleSystemThemeChange:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setTheme:(AppTheme)theme {
    if (_currentTheme == theme) {
        return;
    }
    
    _currentTheme = theme;
    
    // 保存到UserDefaults
    [[NSUserDefaults standardUserDefaults] setInteger:theme forKey:kUserDefaultsThemeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // 更新主题配置
    [self updateThemeConfiguration];
    
    // 发送通知
    [[NSNotificationCenter defaultCenter] postNotificationName:AppThemeDidChangeNotification object:nil];
}

- (AppTheme)actualTheme {
    if (self.currentTheme == AppThemeAuto) {
        // 跟随系统
        if (@available(iOS 13.0, *)) {
            // 优先使用 keyWindow 的 traitCollection，这样能获取到最新的主题状态
            UIWindow *keyWindow = nil;
            for (UIWindow *window in [UIApplication sharedApplication].windows) {
                if (window.isKeyWindow) {
                    keyWindow = window;
                    break;
                }
            }
            // 如果没有 keyWindow，使用第一个 window
            if (!keyWindow && [UIApplication sharedApplication].windows.count > 0) {
                keyWindow = [UIApplication sharedApplication].windows.firstObject;
            }
            
            UITraitCollection *traitCollection = keyWindow ? keyWindow.traitCollection : [UITraitCollection currentTraitCollection];
            UIUserInterfaceStyle style = traitCollection.userInterfaceStyle;
            return (style == UIUserInterfaceStyleDark) ? AppThemeDark : AppThemeLight;
        } else {
            return AppThemeLight;
        }
    }
    return self.currentTheme;
}

- (UIColor *)primaryColor {
    return [UIColor systemBlueColor];
}

- (UIColor *)backgroundColor {
    AppTheme actualTheme = [self actualTheme];
    if (actualTheme == AppThemeDark) {
        return [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
    } else {
        return [UIColor systemBackgroundColor];
    }
}

- (UIColor *)textColor {
    AppTheme actualTheme = [self actualTheme];
    if (actualTheme == AppThemeDark) {
        return [UIColor whiteColor];
    } else {
        return [UIColor redColor];
    }
}

- (UIColor *)secondaryTextColor {
    AppTheme actualTheme = [self actualTheme];
    if (actualTheme == AppThemeDark) {
        return [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0];
    } else {
        return [UIColor secondaryLabelColor];
    }
}

- (UIColor *)separatorColor {
    AppTheme actualTheme = [self actualTheme];
    if (actualTheme == AppThemeDark) {
        return [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    } else {
        return [UIColor separatorColor];
    }
}

- (void)setupThemeConfiguration {
    [self updateThemeConfiguration];
}

- (void)updateThemeConfiguration {
    // 使用原生方式配置主题
    // 主要通过通知机制让各个视图控制器自行更新
    AppTheme actualTheme = [self actualTheme];
    
    // 配置导航栏和状态栏样式
    if (@available(iOS 13.0, *)) {
        if (actualTheme == AppThemeDark) {
            // 深色主题
            [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
        } else {
            // 浅色主题
            [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDarkContent;
        }
    }
}

- (void)handleSystemThemeChange {
    if (self.currentTheme == AppThemeAuto) {
        // 直接更新主题配置并发送通知
        // 因为 traitCollectionDidChange 只有在主题真正变化时才会被调用
        [self updateThemeConfiguration];
        
        // 发送主题变化通知
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:AppThemeDidChangeNotification object:nil];
        });
    }
}

- (void)handleSystemThemeChange:(NSNotification *)notification {
    [self handleSystemThemeChange];
}

@end
