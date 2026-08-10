//
//  ThemeManager.h
//  footBall
//
//  Created on 2026/1/15.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 主题变化通知（userInfo: @{@"nightMode": @(BOOL)}）
FOUNDATION_EXPORT NSString *const AppThemeDidChangeNotification;

/// 主题管理器
///
/// 设计说明：App 内部维护一个独立的“夜间模式”开关，
/// 完全不跟随系统主题。系统主题的动态颜色（systemBackgroundColor 等）
/// 通过把 window 的 overrideUserInterfaceStyle 锁死为 Light 来禁用，
/// 这样全局只会出现一套（由本管理器控制的）黑/白夜间模式。
@interface ThemeManager : NSObject

/// 单例
+ (instancetype)sharedManager;

/// 夜间模式开关（默认 NO）
@property (nonatomic, assign, getter=isNightMode) BOOL nightMode;

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

/// 初始化主题配置（在 AppDelegate 启动时调用一次）
- (void)setupThemeConfiguration;

/// 把主题样式应用到指定 window（锁定系统动态颜色，应用当前主题）
- (void)applyAppearanceToWindow:(UIWindow *)window;

/// 切换夜间模式
/// @param nightMode 是否开启夜间模式
- (void)setNightMode:(BOOL)nightMode;

@end

NS_ASSUME_NONNULL_END
