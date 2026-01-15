//
//  QMBaseViewController.h
//  footBall
//
//  Created on 2026/1/15.
//

#import <UIKit/UIKit.h>
#import <QMUIKit/QMUIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 基础视图控制器 - 集成QMUI、多语言和主题支持
/// 所有自定义的 ViewController 都应继承此类
@interface QMBaseViewController : QMUICommonViewController

/// 是否显示导航栏（默认YES）
@property (nonatomic, assign) BOOL shouldShowNavigationBar;

/// 导航栏标题（支持多语言）
@property (nonatomic, copy, nullable) NSString *navigationTitle;

/// 导航栏标题的本地化key（用于语言切换时重新本地化）
@property (nonatomic, copy, nullable) NSString *navigationTitleKey;

/// 是否启用空状态视图（默认NO）
@property (nonatomic, assign) BOOL enableEmptyView;

/// 设置导航栏标题（自动本地化）
/// @param titleKey 本地化字符串的key
- (void)setNavigationTitleKey:(NSString *)titleKey;

/// 显示加载提示
- (void)showLoading;

/// 隐藏加载提示
- (void)hideLoading;

/// 显示错误提示
/// @param message 错误信息
- (void)showError:(NSString *)message;

/// 显示成功提示
/// @param message 成功信息
- (void)showSuccess:(NSString *)message;

/// 显示空状态视图
/// @param image 空状态图片（可选）
/// @param title 空状态标题
/// @param detailText 空状态描述（可选）
/// @param buttonTitle 按钮标题（可选）
/// @param buttonAction 按钮点击事件（可选）
- (void)showEmptyViewWithImage:(nullable UIImage *)image
                          title:(NSString *)title
                     detailText:(nullable NSString *)detailText
                    buttonTitle:(nullable NSString *)buttonTitle
                    buttonAction:(nullable SEL)buttonAction;

/// 隐藏空状态视图
- (void)hideEmptyView;

/// 设置UI（子类重写）
- (void)setupUI;

/// 更新本地化字符串（子类重写）
- (void)updateLocalizedStrings;

/// 更新主题（子类重写）
- (void)updateTheme;

@end

NS_ASSUME_NONNULL_END
