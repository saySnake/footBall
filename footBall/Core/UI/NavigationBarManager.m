//
//  NavigationBarManager.m
//  footBall
//
//  Created on 2026/1/15.
//  导航栏管理器 - 统一管理导航栏样式和适配
//

#import "NavigationBarManager.h"
#import "ThemeManager.h"
#import "FontManager.h"

@implementation NavigationBarConfig

- (instancetype)init {
    self = [super init];
    if (self) {
        _isTranslucent = YES;
        _hideShadow = NO;
        _heightOffset = 0;
    }
    return self;
}

@end

@interface NavigationBarManager ()

@end

@implementation NavigationBarManager

+ (instancetype)sharedManager {
    static NavigationBarManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NavigationBarManager alloc] init];
    });
    return instance;
}

#pragma mark - 全局配置

- (void)applyDefaultStyleToNavigationBar:(UINavigationBar *)navigationBar {
    NavigationBarConfig *defaultConfig = [NavigationBarManager defaultConfig];
    [self applyStyle:defaultConfig toNavigationBar:navigationBar];
}

- (void)applyStyle:(NavigationBarConfig *)config toNavigationBar:(UINavigationBar *)navigationBar {
    if (!navigationBar || !config) {
        return;
    }
    
    ThemeManager *themeManager = [ThemeManager sharedManager];
    
    // iOS 15+ 使用 UINavigationBarAppearance
    if (@available(iOS 15.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        
        // 配置背景
        if (config.backgroundImage) {
            [appearance configureWithOpaqueBackground];
            appearance.backgroundImage = config.backgroundImage;
        } else if (config.backgroundColor) {
            [appearance configureWithOpaqueBackground];
            appearance.backgroundColor = config.backgroundColor;
        } else {
            if (config.isTranslucent) {
                [appearance configureWithDefaultBackground];
            } else {
                [appearance configureWithOpaqueBackground];
                appearance.backgroundColor = themeManager.backgroundColor;
            }
        }
        
        // 配置标题样式
        NSMutableDictionary *titleTextAttributes = [NSMutableDictionary dictionary];
        if (config.titleColor) {
            titleTextAttributes[NSForegroundColorAttributeName] = config.titleColor;
        } else {
            titleTextAttributes[NSForegroundColorAttributeName] = themeManager.textColor;
        }
        
        if (config.titleFont) {
            titleTextAttributes[NSFontAttributeName] = config.titleFont;
        } else {
            // 使用默认字体，根据设备类型调整
            CGFloat fontSize = [NavigationBarManager isIPad] ? 18 : 17;
            titleTextAttributes[NSFontAttributeName] = [FontManager fontOfSize:fontSize weight:UIFontWeightSemibold];
        }
        appearance.titleTextAttributes = titleTextAttributes;
        
        // 配置大标题样式（iOS 11+）
        if (@available(iOS 11.0, *)) {
            appearance.largeTitleTextAttributes = titleTextAttributes;
        }
        
        // 配置阴影
        if (config.hideShadow) {
            appearance.shadowColor = [UIColor clearColor];
        } else if (config.shadowColor) {
            appearance.shadowColor = config.shadowColor;
        } else {
            appearance.shadowColor = themeManager.separatorColor;
        }
        
        // 应用样式
        navigationBar.standardAppearance = appearance;
        navigationBar.scrollEdgeAppearance = appearance;
        
        // 适配 iPhone 横屏
        if (![NavigationBarManager isIPad]) {
            navigationBar.compactAppearance = appearance;
        }
    } else {
        // iOS 15 以下版本
        
        // 设置半透明
        navigationBar.translucent = config.isTranslucent;
        
        // 设置背景色
        if (config.backgroundImage) {
            [navigationBar setBackgroundImage:config.backgroundImage forBarMetrics:UIBarMetricsDefault];
        } else if (config.backgroundColor) {
            [navigationBar setBackgroundImage:[self imageWithColor:config.backgroundColor]
                                forBarMetrics:UIBarMetricsDefault];
        } else {
            [navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
            navigationBar.barTintColor = themeManager.backgroundColor;
        }
        
        // 设置标题样式
        NSMutableDictionary *titleTextAttributes = [NSMutableDictionary dictionary];
        if (config.titleColor) {
            titleTextAttributes[NSForegroundColorAttributeName] = config.titleColor;
        } else {
            titleTextAttributes[NSForegroundColorAttributeName] = themeManager.textColor;
        }
        
        if (config.titleFont) {
            titleTextAttributes[NSFontAttributeName] = config.titleFont;
        } else {
            CGFloat fontSize = [NavigationBarManager isIPad] ? 18 : 17;
            titleTextAttributes[NSFontAttributeName] = [FontManager fontOfSize:fontSize weight:UIFontWeightSemibold];
        }
        navigationBar.titleTextAttributes = titleTextAttributes;
        
        // 大标题样式（iOS 11+）
        if (@available(iOS 11.0, *)) {
            navigationBar.largeTitleTextAttributes = titleTextAttributes;
        }
        
        // 设置阴影
        if (config.hideShadow) {
            navigationBar.shadowImage = [UIImage new];
        } else if (config.shadowColor) {
            navigationBar.shadowImage = [self imageWithColor:config.shadowColor size:CGSizeMake(1, 0.5)];
        } else {
            navigationBar.shadowImage = nil;
        }
    }
    
    // 设置按钮颜色（适用于所有 iOS 版本）
    if (config.tintColor) {
        navigationBar.tintColor = config.tintColor;
    } else {
        navigationBar.tintColor = themeManager.primaryColor;
    }
}

- (void)resetNavigationBar:(UINavigationBar *)navigationBar {
    if (!navigationBar) {
        return;
    }
    
    // iOS 15+ 使用默认样式
    if (@available(iOS 15.0, *)) {
        navigationBar.standardAppearance = [UINavigationBarAppearance new];
        navigationBar.scrollEdgeAppearance = [UINavigationBarAppearance new];
        if (![NavigationBarManager isIPad]) {
            navigationBar.compactAppearance = [UINavigationBarAppearance new];
        }
    } else {
        // iOS 15 以下重置
        navigationBar.translucent = YES;
        [navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
        navigationBar.barTintColor = nil;
        navigationBar.titleTextAttributes = nil;
        navigationBar.shadowImage = nil;
        if (@available(iOS 11.0, *)) {
            navigationBar.largeTitleTextAttributes = nil;
        }
    }
    
    navigationBar.tintColor = nil;
}

#pragma mark - 便捷配置方法

- (void)setTitle:(NSString *)title
 forNavigationBar:(UINavigationBar *)navigationBar
        withFont:(UIFont *)font
           color:(UIColor *)color {
    if (!navigationBar) {
        return;
    }
    
    ThemeManager *themeManager = [ThemeManager sharedManager];
    UIColor *titleColor = color ?: themeManager.textColor;
    UIFont *titleFont = font ?: ([FontManager fontOfSize:([NavigationBarManager isIPad] ? 18 : 17)
                                                   weight:UIFontWeightSemibold]);
    
    NSDictionary *titleTextAttributes = @{
        NSForegroundColorAttributeName: titleColor,
        NSFontAttributeName: titleFont
    };
    
    if (@available(iOS 15.0, *)) {
        navigationBar.standardAppearance.titleTextAttributes = titleTextAttributes;
        navigationBar.scrollEdgeAppearance.titleTextAttributes = titleTextAttributes;
        if (@available(iOS 11.0, *)) {
            navigationBar.standardAppearance.largeTitleTextAttributes = titleTextAttributes;
            navigationBar.scrollEdgeAppearance.largeTitleTextAttributes = titleTextAttributes;
        }
        if (![NavigationBarManager isIPad]) {
            navigationBar.compactAppearance.titleTextAttributes = titleTextAttributes;
        }
    } else {
        navigationBar.titleTextAttributes = titleTextAttributes;
        if (@available(iOS 11.0, *)) {
            navigationBar.largeTitleTextAttributes = titleTextAttributes;
        }
    }
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
            backgroundImage:(UIImage *)backgroundImage
                 translucent:(BOOL)translucent
           forNavigationBar:(UINavigationBar *)navigationBar {
    if (!navigationBar) {
        return;
    }
    
    ThemeManager *themeManager = [ThemeManager sharedManager];
    UIColor *bgColor = backgroundColor ?: themeManager.backgroundColor;
    
    if (@available(iOS 15.0, *)) {
        UINavigationBarAppearance *appearance = navigationBar.standardAppearance ?: [[UINavigationBarAppearance alloc] init];
        
        if (backgroundImage) {
            [appearance configureWithOpaqueBackground];
            appearance.backgroundImage = backgroundImage;
        } else {
            if (translucent) {
                [appearance configureWithDefaultBackground];
            } else {
                [appearance configureWithOpaqueBackground];
                appearance.backgroundColor = bgColor;
            }
        }
        
        navigationBar.standardAppearance = appearance;
        navigationBar.scrollEdgeAppearance = appearance;
        if (![NavigationBarManager isIPad]) {
            navigationBar.compactAppearance = appearance;
        }
    } else {
        navigationBar.translucent = translucent;
        
        if (backgroundImage) {
            [navigationBar setBackgroundImage:backgroundImage forBarMetrics:UIBarMetricsDefault];
        } else {
            [navigationBar setBackgroundImage:[self imageWithColor:bgColor]
                                forBarMetrics:UIBarMetricsDefault];
        }
        
        if (!translucent) {
            navigationBar.barTintColor = bgColor;
        }
    }
}

- (void)setTintColor:(UIColor *)tintColor forNavigationBar:(UINavigationBar *)navigationBar {
    if (!navigationBar) {
        return;
    }
    
    ThemeManager *themeManager = [ThemeManager sharedManager];
    navigationBar.tintColor = tintColor ?: themeManager.primaryColor;
}

- (void)setShadowHidden:(BOOL)hideShadow
              shadowColor:(UIColor *)shadowColor
        forNavigationBar:(UINavigationBar *)navigationBar {
    if (!navigationBar) {
        return;
    }
    
    ThemeManager *themeManager = [ThemeManager sharedManager];
    UIColor *shadow = hideShadow ? [UIColor clearColor] : (shadowColor ?: themeManager.separatorColor);
    
    if (@available(iOS 15.0, *)) {
        UINavigationBarAppearance *appearance = navigationBar.standardAppearance ?: [[UINavigationBarAppearance alloc] init];
        appearance.shadowColor = shadow;
        navigationBar.standardAppearance = appearance;
        navigationBar.scrollEdgeAppearance = appearance;
        if (![NavigationBarManager isIPad]) {
            navigationBar.compactAppearance = appearance;
        }
    } else {
        if (hideShadow) {
            navigationBar.shadowImage = [UIImage new];
        } else {
            navigationBar.shadowImage = [self imageWithColor:shadow size:CGSizeMake(1, 0.5)];
        }
    }
}

#pragma mark - 适配方法

+ (CGFloat)adaptiveNavigationBarHeightForNavigationController:(UINavigationController *)navigationController {
    if (!navigationController) {
        return [self defaultNavigationBarHeight];
    }
    
    CGFloat baseHeight = [self defaultNavigationBarHeight];
    CGFloat statusBarHeight = [self statusBarHeight];
    
    // 横屏时高度可能不同
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    BOOL isLandscape = UIInterfaceOrientationIsLandscape(orientation);
    
    if (isLandscape && ![self isIPad]) {
        // iPhone 横屏时导航栏高度为 32pt（iOS 13+）
        if (@available(iOS 13.0, *)) {
            return 32;
        } else {
            return 32;
        }
    }
    
    return baseHeight;
}

+ (CGFloat)statusBarHeight {
    if (@available(iOS 13.0, *)) {
        UIWindowScene *windowScene = nil;
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                windowScene = scene;
                break;
            }
        }
        return windowScene.statusBarManager.statusBarFrame.size.height;
    } else {
        return [UIApplication sharedApplication].statusBarFrame.size.height;
    }
}

+ (CGFloat)safeAreaTopHeightForNavigationController:(UINavigationController *)navigationController {
    CGFloat navigationBarHeight = [self adaptiveNavigationBarHeightForNavigationController:navigationController];
    CGFloat statusBarHeight = [self statusBarHeight];
    return navigationBarHeight + statusBarHeight;
}

+ (BOOL)isIPad {
    return [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
}

+ (BOOL)isIPhoneXSeries {
    if (@available(iOS 11.0, *)) {
        UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
        if (window) {
            return window.safeAreaInsets.top > 20;
        }
    }
    return NO;
}

+ (BOOL)isLandscapeForViewController:(UIViewController *)viewController {
    if (!viewController) {
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        return UIInterfaceOrientationIsLandscape(orientation);
    }
    
    if (@available(iOS 13.0, *)) {
        return UIInterfaceOrientationIsLandscape(viewController.view.window.windowScene.interfaceOrientation);
    } else {
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        return UIInterfaceOrientationIsLandscape(orientation);
    }
}

+ (CGFloat)defaultNavigationBarHeight {
    // 标准导航栏高度：44pt
    return 44.0;
}

#pragma mark - 创建配置对象

+ (NavigationBarConfig *)defaultConfig {
    NavigationBarConfig *config = [[NavigationBarConfig alloc] init];
    ThemeManager *themeManager = [ThemeManager sharedManager];
    
    config.backgroundColor = themeManager.backgroundColor;
    config.titleColor = themeManager.textColor;
    config.tintColor = themeManager.primaryColor;
    config.isTranslucent = YES;
    config.hideShadow = NO;
    
    CGFloat fontSize = [self isIPad] ? 18 : 17;
    config.titleFont = [FontManager fontOfSize:fontSize weight:UIFontWeightSemibold];
    
    return config;
}

+ (NavigationBarConfig *)transparentConfig {
    NavigationBarConfig *config = [[NavigationBarConfig alloc] init];
    ThemeManager *themeManager = [ThemeManager sharedManager];
    
    config.backgroundColor = [UIColor clearColor];
    config.titleColor = themeManager.textColor;
    config.tintColor = themeManager.primaryColor;
    config.isTranslucent = YES;
    config.hideShadow = YES;
    
    CGFloat fontSize = [self isIPad] ? 18 : 17;
    config.titleFont = [FontManager fontOfSize:fontSize weight:UIFontWeightSemibold];
    
    return config;
}

+ (NavigationBarConfig *)configWithBackgroundColor:(UIColor *)backgroundColor
                                        titleColor:(UIColor *)titleColor {
    NavigationBarConfig *config = [[NavigationBarConfig alloc] init];
    ThemeManager *themeManager = [ThemeManager sharedManager];
    
    config.backgroundColor = backgroundColor;
    config.titleColor = titleColor;
    config.tintColor = themeManager.primaryColor;
    config.isTranslucent = NO;
    config.hideShadow = NO;
    
    CGFloat fontSize = [self isIPad] ? 18 : 17;
    config.titleFont = [FontManager fontOfSize:fontSize weight:UIFontWeightSemibold];
    
    return config;
}

#pragma mark - 辅助方法

- (UIImage *)imageWithColor:(UIColor *)color {
    return [self imageWithColor:color size:CGSizeMake(1, 1)];
}

- (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size {
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
