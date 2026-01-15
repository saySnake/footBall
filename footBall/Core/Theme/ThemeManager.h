//
//  ThemeManager.h
//  footBall
//
//  Created on 2026/1/15.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 主题类型
typedef NS_ENUM(NSInteger, AppTheme) {
    AppThemeLight = 0,  // 浅色主题
    AppThemeDark,       // 深色主题
    AppThemeAuto        // 跟随系统
};

/// 主题变化通知
FOUNDATION_EXPORT NSString *const AppThemeDidChangeNotification;

/// 主题管理器
@interface ThemeManager : NSObject

/// 单例
+ (instancetype)sharedManager;

/// 当前主题
@property (nonatomic, assign) AppTheme currentTheme;

/// 是否跟随系统（当currentTheme为AppThemeAuto时有效）
@property (nonatomic, assign) BOOL followSystem;

/// 主色调
@property (nonatomic, strong, readonly) UIColor *primaryColor;

/// 背景色
@property (nonatomic, strong, readonly) UIColor *backgroundColor;

/// 文本颜色
@property (nonatomic, strong, readonly) UIColor *textColor;

/// 次要文本颜色
@property (nonatomic, strong, readonly) UIColor *secondaryTextColor;

/// 分割线颜色
@property (nonatomic, strong, readonly) UIColor *separatorColor;

/// 设置主题
/// @param theme 主题类型
- (void)setTheme:(AppTheme)theme;

/// 初始化主题配置
- (void)setupThemeConfiguration;

/// 获取当前实际主题（如果设置为Auto，会返回系统当前主题）
- (AppTheme)actualTheme;

/// 处理系统主题变化（当检测到系统主题变化时调用，仅在AppThemeAuto模式下有效）
- (void)handleSystemThemeChange;

@end

NS_ASSUME_NONNULL_END
