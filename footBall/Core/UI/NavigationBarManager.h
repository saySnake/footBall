//
//  NavigationBarManager.h
//  footBall
//
//  Created on 2026/1/15.
//  导航栏管理器 - 统一管理导航栏样式和适配
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 导航栏样式配置
@interface NavigationBarConfig : NSObject

/// 导航栏背景颜色（nil 表示使用默认）
@property (nonatomic, strong, nullable) UIColor *backgroundColor;

/// 导航栏标题颜色（nil 表示使用默认）
@property (nonatomic, strong, nullable) UIColor *titleColor;

/// 导航栏标题字体（nil 表示使用默认）
@property (nonatomic, strong, nullable) UIFont *titleFont;

/// 导航栏按钮颜色（返回按钮等，nil 表示使用默认）
@property (nonatomic, strong, nullable) UIColor *tintColor;

/// 导航栏是否半透明（默认 YES，iOS 15+ 使用 UINavigationBarAppearance）
@property (nonatomic, assign) BOOL isTranslucent;

/// 导航栏是否隐藏底部阴影线（默认 NO）
@property (nonatomic, assign) BOOL hideShadow;

/// 导航栏阴影颜色（iOS 15+ 使用 UINavigationBarAppearance）
@property (nonatomic, strong, nullable) UIColor *shadowColor;

/// 背景图片（优先级高于 backgroundColor）
@property (nonatomic, strong, nullable) UIImage *backgroundImage;

/// 导航栏高度偏移（用于适配不同设备）
@property (nonatomic, assign) CGFloat heightOffset;

@end

/// 导航栏管理器
@interface NavigationBarManager : NSObject

/// 单例
+ (instancetype)sharedManager;

#pragma mark - 全局配置

/// 应用默认导航栏样式（应用到所有导航栏）
- (void)applyDefaultStyleToNavigationBar:(UINavigationBar *)navigationBar;

/// 应用自定义样式到导航栏
/// @param navigationBar 目标导航栏
/// @param config 样式配置
- (void)applyStyle:(NavigationBarConfig *)config toNavigationBar:(UINavigationBar *)navigationBar;

/// 重置导航栏为默认样式
/// @param navigationBar 目标导航栏
- (void)resetNavigationBar:(UINavigationBar *)navigationBar;

#pragma mark - 便捷配置方法

/// 设置导航栏标题样式
/// @param navigationBar 目标导航栏
/// @param title 标题文字
/// @param font 标题字体（nil 使用默认）
/// @param color 标题颜色（nil 使用主题颜色）
- (void)setTitle:(NSString *)title
         forNavigationBar:(UINavigationBar *)navigationBar
                withFont:(nullable UIFont *)font
                   color:(nullable UIColor *)color;

/// 设置导航栏背景样式
/// @param navigationBar 目标导航栏
/// @param backgroundColor 背景颜色（nil 使用主题背景色）
/// @param backgroundImage 背景图片（优先级高于 backgroundColor）
/// @param translucent 是否半透明
- (void)setBackgroundColor:(nullable UIColor *)backgroundColor
                backgroundImage:(nullable UIImage *)backgroundImage
                   translucent:(BOOL)translucent
             forNavigationBar:(UINavigationBar *)navigationBar;

/// 设置导航栏按钮颜色
/// @param navigationBar 目标导航栏
/// @param tintColor 按钮颜色（nil 使用主题主色）
- (void)setTintColor:(nullable UIColor *)tintColor forNavigationBar:(UINavigationBar *)navigationBar;

/// 设置导航栏阴影
/// @param navigationBar 目标导航栏
/// @param hideShadow 是否隐藏阴影
/// @param shadowColor 阴影颜色（nil 使用默认）
- (void)setShadowHidden:(BOOL)hideShadow
              shadowColor:(nullable UIColor *)shadowColor
        forNavigationBar:(UINavigationBar *)navigationBar;

#pragma mark - 适配方法

/// 获取适配后的导航栏高度
/// @param navigationController 导航控制器
+ (CGFloat)adaptiveNavigationBarHeightForNavigationController:(UINavigationController *)navigationController;

/// 获取状态栏高度（适配刘海屏等）
+ (CGFloat)statusBarHeight;

/// 获取安全区域顶部高度（状态栏 + 导航栏）
/// @param navigationController 导航控制器
+ (CGFloat)safeAreaTopHeightForNavigationController:(UINavigationController *)navigationController;

/// 是否为 iPad
+ (BOOL)isIPad;

/// 是否为 iPhone X 系列及以上（有刘海）
+ (BOOL)isIPhoneXSeries;

/// 当前是否为横屏
/// @param viewController 视图控制器
+ (BOOL)isLandscapeForViewController:(UIViewController *)viewController;

#pragma mark - 创建配置对象

/// 创建默认配置
+ (NavigationBarConfig *)defaultConfig;

/// 创建透明导航栏配置
+ (NavigationBarConfig *)transparentConfig;

/// 创建自定义颜色配置
/// @param backgroundColor 背景颜色
/// @param titleColor 标题颜色
+ (NavigationBarConfig *)configWithBackgroundColor:(UIColor *)backgroundColor
                                        titleColor:(UIColor *)titleColor;

@end

NS_ASSUME_NONNULL_END
