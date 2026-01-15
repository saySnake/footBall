//
//  ColorManager.m
//  footBall
//
//  Created on 2026/1/15.
//

#import "ColorManager.h"
#import "ThemeManager.h"

@interface ColorManager ()

// 自定义主题颜色配置
@property (nonatomic, strong, nullable) UIColor *customPrimaryColorLight;
@property (nonatomic, strong, nullable) UIColor *customPrimaryColorDark;
@property (nonatomic, strong, nullable) UIColor *customPrimaryLightColorLight;
@property (nonatomic, strong, nullable) UIColor *customPrimaryLightColorDark;
@property (nonatomic, strong, nullable) UIColor *customPrimaryDarkColorLight;
@property (nonatomic, strong, nullable) UIColor *customPrimaryDarkColorDark;

@end

@implementation ColorManager

+ (instancetype)sharedManager {
    static ColorManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ColorManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 监听主题变化
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleThemeChange:)
                                                     name:AppThemeDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupColorConfiguration {
    // 可以在这里设置默认的自定义颜色
    // 例如：
    // [self setPrimaryColorLight:[UIColor colorWithHexString:@"#007AFF"] 
    //                       dark:[UIColor colorWithHexString:@"#0A84FF"]];
}

- (void)handleThemeChange:(NSNotification *)notification {
    // 主题变化时，可以执行一些操作
    // 由于颜色是动态计算的，这里不需要特别处理
}

#pragma mark - 主题颜色配置

- (void)setPrimaryColorForLightMode:(UIColor *)color {
    self.customPrimaryColorLight = color;
}

- (void)setPrimaryColorForDarkMode:(UIColor *)color {
    self.customPrimaryColorDark = color;
}

- (void)setPrimaryColorLight:(UIColor *)lightColor dark:(UIColor *)darkColor {
    self.customPrimaryColorLight = lightColor;
    self.customPrimaryColorDark = darkColor;
}

- (UIColor *)primaryColorForDarkMode:(BOOL)isDarkMode {
    if (isDarkMode) {
        return self.customPrimaryColorDark ?: [UIColor colorWithRed:0.2 green:0.5 blue:1.0 alpha:1.0];
    } else {
        return self.customPrimaryColorLight ?: [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0];
    }
}

#pragma mark - Helper Methods

- (BOOL)isDarkMode {
    ThemeManager *themeManager = [ThemeManager sharedManager];
    return [themeManager actualTheme] == AppThemeDark;
}

#pragma mark - 主色调

- (UIColor *)primaryColor {
    // 根据当前主题返回不同的主色
    BOOL isDark = [self isDarkMode];
    
    if (isDark) {
        // 夜间模式：使用更亮的蓝色，提高对比度
        return self.customPrimaryColorDark ?: [UIColor colorWithRed:0.2 green:0.5 blue:1.0 alpha:1.0];
    } else {
        // 白天模式：使用标准蓝色
        return self.customPrimaryColorLight ?: [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0];
    }
}

- (UIColor *)primaryLightColor {
    BOOL isDark = [self isDarkMode];
    
    if (isDark) {
        // 夜间模式：浅色主色（更亮）
        return self.customPrimaryLightColorDark ?: [UIColor colorWithRed:0.4 green:0.7 blue:1.0 alpha:1.0];
    } else {
        // 白天模式：浅色主色
        return self.customPrimaryLightColorLight ?: [UIColor colorWithRed:0.4 green:0.6 blue:1.0 alpha:1.0];
    }
}

- (UIColor *)primaryDarkColor {
    BOOL isDark = [self isDarkMode];
    
    if (isDark) {
        // 夜间模式：深色主色（更深）
        return self.customPrimaryDarkColorDark ?: [UIColor colorWithRed:0.1 green:0.3 blue:0.8 alpha:1.0];
    } else {
        // 白天模式：深色主色
        return self.customPrimaryDarkColorLight ?: [UIColor colorWithRed:0.0 green:0.3 blue:0.8 alpha:1.0];
    }
}

#pragma mark - 辅助色

- (UIColor *)successColor {
    // 成功色在夜间模式下稍微调亮
    BOOL isDark = [self isDarkMode];
    if (isDark) {
        return [UIColor colorWithRed:0.2 green:0.8 blue:0.3 alpha:1.0];
    } else {
        return [UIColor systemGreenColor];
    }
}

- (UIColor *)warningColor {
    // 警告色在夜间模式下稍微调亮
    BOOL isDark = [self isDarkMode];
    if (isDark) {
        return [UIColor colorWithRed:1.0 green:0.6 blue:0.2 alpha:1.0];
    } else {
        return [UIColor systemOrangeColor];
    }
}

- (UIColor *)errorColor {
    // 错误色在夜间模式下稍微调亮
    BOOL isDark = [self isDarkMode];
    if (isDark) {
        return [UIColor colorWithRed:1.0 green:0.3 blue:0.3 alpha:1.0];
    } else {
        return [UIColor systemRedColor];
    }
}

- (UIColor *)infoColor {
    // 信息色跟随主色
    return [self primaryColor];
}

#pragma mark - 中性色

- (UIColor *)backgroundColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor systemBackgroundColor];
    } else {
        return [UIColor whiteColor];
    }
}

- (UIColor *)secondaryBackgroundColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor secondarySystemBackgroundColor];
    } else {
        return [UIColor colorWithRed:0.95 green:0.95 blue:0.97 alpha:1.0];
    }
}

- (UIColor *)tertiaryBackgroundColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor tertiarySystemBackgroundColor];
    } else {
        return [UIColor colorWithRed:0.9 green:0.9 blue:0.92 alpha:1.0];
    }
}

#pragma mark - 文本颜色

- (UIColor *)textColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor labelColor];
    } else {
        return [UIColor blackColor];
    }
}

- (UIColor *)secondaryTextColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor secondaryLabelColor];
    } else {
        return [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0];
    }
}

- (UIColor *)tertiaryTextColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor tertiaryLabelColor];
    } else {
        return [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0];
    }
}

- (UIColor *)placeholderTextColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor placeholderTextColor];
    } else {
        return [UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:1.0];
    }
}

- (UIColor *)disabledTextColor {
    return [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
}

#pragma mark - 边框和分割线

- (UIColor *)separatorColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor separatorColor];
    } else {
        return [UIColor colorWithRed:0.78 green:0.78 blue:0.8 alpha:1.0];
    }
}

- (UIColor *)borderColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor separatorColor];
    } else {
        return [UIColor colorWithRed:0.78 green:0.78 blue:0.8 alpha:1.0];
    }
}

#pragma mark - 遮罩和覆盖层

- (UIColor *)maskColor {
    return [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5];
}

- (UIColor *)overlayColor {
    return [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.3];
}

#pragma mark - 便捷方法

+ (UIColor *)colorWithHexString:(NSString *)hexString {
    return [self colorWithHexString:hexString alpha:1.0];
}

+ (UIColor *)colorWithHexString:(NSString *)hexString alpha:(CGFloat)alpha {
    if (!hexString || hexString.length == 0) {
        return [UIColor clearColor];
    }
    
    // 移除 # 符号
    NSString *cleanHex = [hexString stringByReplacingOccurrencesOfString:@"#" withString:@""];
    
    // 验证长度
    if (cleanHex.length != 6) {
        NSLog(@"⚠️ 无效的十六进制颜色字符串: %@", hexString);
        return [UIColor clearColor];
    }
    
    // 解析 RGB 值
    unsigned int rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:cleanHex];
    [scanner scanHexInt:&rgbValue];
    
    CGFloat red = ((rgbValue & 0xFF0000) >> 16) / 255.0;
    CGFloat green = ((rgbValue & 0x00FF00) >> 8) / 255.0;
    CGFloat blue = (rgbValue & 0x0000FF) / 255.0;
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

+ (UIColor *)colorWithR:(NSInteger)red G:(NSInteger)green B:(NSInteger)blue {
    return [self colorWithR:red G:green B:blue alpha:1.0];
}

+ (UIColor *)colorWithR:(NSInteger)red G:(NSInteger)green B:(NSInteger)blue alpha:(CGFloat)alpha {
    return [UIColor colorWithRed:red / 255.0
                            green:green / 255.0
                             blue:blue / 255.0
                            alpha:alpha];
}

@end
