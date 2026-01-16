//
//  UINavigationController+NavigationBar.h
//  footBall
//
//  Created on 2026/1/15.
//  UINavigationController 导航栏扩展 - 提供便捷的导航栏配置方法
//

#import <UIKit/UIKit.h>
#import "NavigationBarManager.h"

NS_ASSUME_NONNULL_BEGIN

/// UINavigationController 导航栏扩展
@interface UINavigationController (NavigationBar)

#pragma mark - 便捷配置方法

/// 应用默认导航栏样式
- (void)applyDefaultNavigationBarStyle;

/// 应用自定义导航栏样式
/// @param config 样式配置
- (void)applyNavigationBarStyle:(NavigationBarConfig *)config;

/// 设置导航栏标题样式
/// @param title 标题文字
/// @param font 标题字体（nil 使用默认）
/// @param color 标题颜色（nil 使用主题颜色）
- (void)setNavigationBarTitle:(NSString *)title
                     withFont:(nullable UIFont *)font
                        color:(nullable UIColor *)color;

/// 设置导航栏背景样式
/// @param backgroundColor 背景颜色（nil 使用主题背景色）
/// @param backgroundImage 背景图片（优先级高于 backgroundColor）
/// @param translucent 是否半透明
- (void)setNavigationBarBackgroundColor:(nullable UIColor *)backgroundColor
                         backgroundImage:(nullable UIImage *)backgroundImage
                             translucent:(BOOL)translucent;

/// 设置导航栏按钮颜色
/// @param tintColor 按钮颜色（nil 使用主题主色）
- (void)setNavigationBarTintColor:(nullable UIColor *)tintColor;

/// 设置导航栏阴影
/// @param hideShadow 是否隐藏阴影
/// @param shadowColor 阴影颜色（nil 使用默认）
- (void)setNavigationBarShadowHidden:(BOOL)hideShadow
                           shadowColor:(nullable UIColor *)shadowColor;

/// 重置导航栏为默认样式
- (void)resetNavigationBarStyle;

#pragma mark - 适配信息

/// 获取适配后的导航栏高度
- (CGFloat)adaptiveNavigationBarHeight;

/// 获取安全区域顶部高度（状态栏 + 导航栏）
- (CGFloat)safeAreaTopHeight;

/// 当前是否为横屏
- (BOOL)isLandscape;

@end

NS_ASSUME_NONNULL_END
