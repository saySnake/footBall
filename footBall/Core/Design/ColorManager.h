//
//  ColorManager.h
//  footBall
//
//  Created on 2026/1/15.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 颜色管理器 - 统一管理应用颜色规范，支持白天/夜间模式
@interface ColorManager : NSObject

/// 单例
+ (instancetype)sharedManager;

/// 初始化颜色配置（在 AppDelegate 中调用）
- (void)setupColorConfiguration;

#pragma mark - 主色调

/// 主色（品牌色）
@property (nonatomic, strong, readonly) UIColor *primaryColor;

/// 主色 - 浅色
@property (nonatomic, strong, readonly) UIColor *primaryLightColor;

/// 主色 - 深色
@property (nonatomic, strong, readonly) UIColor *primaryDarkColor;

#pragma mark - 辅助色

/// 成功色（绿色）
@property (nonatomic, strong, readonly) UIColor *successColor;

/// 警告色（橙色）
@property (nonatomic, strong, readonly) UIColor *warningColor;

/// 错误色（红色）
@property (nonatomic, strong, readonly) UIColor *errorColor;

/// 信息色（蓝色）
@property (nonatomic, strong, readonly) UIColor *infoColor;

#pragma mark - 中性色

/// 背景色 - 主背景
@property (nonatomic, strong, readonly) UIColor *backgroundColor;

/// 背景色 - 次要背景
@property (nonatomic, strong, readonly) UIColor *secondaryBackgroundColor;

/// 背景色 - 三级背景
@property (nonatomic, strong, readonly) UIColor *tertiaryBackgroundColor;

#pragma mark - 文本颜色

/// 文本色 - 主要文本
@property (nonatomic, strong, readonly) UIColor *textColor;

/// 文本色 - 次要文本
@property (nonatomic, strong, readonly) UIColor *secondaryTextColor;

/// 文本色 - 三级文本
@property (nonatomic, strong, readonly) UIColor *tertiaryTextColor;

/// 文本色 - 占位符文本
@property (nonatomic, strong, readonly) UIColor *placeholderTextColor;

/// 文本色 - 禁用文本
@property (nonatomic, strong, readonly) UIColor *disabledTextColor;

#pragma mark - 边框和分割线

/// 分割线颜色
@property (nonatomic, strong, readonly) UIColor *separatorColor;

/// 边框颜色
@property (nonatomic, strong, readonly) UIColor *borderColor;

#pragma mark - 遮罩和覆盖层

/// 遮罩颜色
@property (nonatomic, strong, readonly) UIColor *maskColor;

/// 覆盖层颜色
@property (nonatomic, strong, readonly) UIColor *overlayColor;

#pragma mark - 主题颜色配置

/// 设置主色（白天模式）
/// @param color 颜色
- (void)setPrimaryColorForLightMode:(UIColor *)color;

/// 设置主色（夜间模式）
/// @param color 颜色
- (void)setPrimaryColorForDarkMode:(UIColor *)color;

/// 设置主色（同时设置白天和夜间模式）
/// @param lightColor 白天模式颜色
/// @param darkColor 夜间模式颜色
- (void)setPrimaryColorLight:(UIColor *)lightColor dark:(UIColor *)darkColor;

/// 获取主色（指定主题）
/// @param isDarkMode 是否为夜间模式
- (UIColor *)primaryColorForDarkMode:(BOOL)isDarkMode;

#pragma mark - 便捷方法

/// 从十六进制字符串创建颜色
/// @param hexString 十六进制字符串（支持 #RRGGBB 或 RRGGBB 格式）
+ (UIColor *)colorWithHexString:(NSString *)hexString;

/// 从十六进制字符串创建颜色（带透明度）
/// @param hexString 十六进制字符串
/// @param alpha 透明度（0.0 - 1.0）
+ (UIColor *)colorWithHexString:(NSString *)hexString alpha:(CGFloat)alpha;

/// 从RGB值创建颜色
/// @param red 红色分量（0-255）
/// @param green 绿色分量（0-255）
/// @param blue 蓝色分量（0-255）
+ (UIColor *)colorWithR:(NSInteger)red G:(NSInteger)green B:(NSInteger)blue;

/// 从RGB值创建颜色（带透明度）
/// @param red 红色分量（0-255）
/// @param green 绿色分量（0-255）
/// @param blue 蓝色分量（0-255）
/// @param alpha 透明度（0.0 - 1.0）
+ (UIColor *)colorWithR:(NSInteger)red G:(NSInteger)green B:(NSInteger)blue alpha:(CGFloat)alpha;

@end

NS_ASSUME_NONNULL_END
