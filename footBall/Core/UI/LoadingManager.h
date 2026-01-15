//
//  LoadingManager.h
//  footBall
//
//  Created on 2026/1/15.
//  加载提示管理器 - 封装 MBProgressHUD，提供统一的加载提示 API
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 加载提示管理器 - 封装 MBProgressHUD
@interface LoadingManager : NSObject

/// 单例
+ (instancetype)sharedManager;

#pragma mark - 加载提示

/// 显示加载提示（默认消息）
/// @param view 要显示到的视图
- (void)showLoadingInView:(UIView *)view;

/// 显示加载提示（自定义消息）
/// @param message 提示消息
/// @param view 要显示到的视图
- (void)showLoadingWithMessage:(NSString *)message inView:(UIView *)view;

/// 隐藏加载提示
/// @param view 视图
- (void)hideLoadingInView:(UIView *)view;

/// 隐藏所有加载提示
- (void)hideAllLoading;

#pragma mark - 文本提示（Toast）

/// 显示成功提示
/// @param message 提示消息
/// @param view 要显示到的视图
- (void)showSuccess:(NSString *)message inView:(UIView *)view;

/// 显示错误提示
/// @param message 提示消息
/// @param view 要显示到的视图
- (void)showError:(NSString *)message inView:(UIView *)view;

/// 显示信息提示
/// @param message 提示消息
/// @param view 要显示到的视图
- (void)showInfo:(NSString *)message inView:(UIView *)view;

/// 显示文本提示（无图标）
/// @param message 提示消息
/// @param view 要显示到的视图
- (void)showText:(NSString *)message inView:(UIView *)view;

/// 显示文本提示（自定义显示时长）
/// @param message 提示消息
/// @param view 要显示到的视图
/// @param duration 显示时长（秒）
- (void)showText:(NSString *)message inView:(UIView *)view duration:(NSTimeInterval)duration;

#pragma mark - 便捷方法（使用 keyWindow）

/// 显示加载提示（默认消息，显示在 keyWindow）
- (void)showLoading;

/// 显示加载提示（自定义消息，显示在 keyWindow）
/// @param message 提示消息
- (void)showLoadingWithMessage:(NSString *)message;

/// 隐藏加载提示（从 keyWindow）
- (void)hideLoading;

/// 显示成功提示（显示在 keyWindow）
/// @param message 提示消息
- (void)showSuccess:(NSString *)message;

/// 显示错误提示（显示在 keyWindow）
/// @param message 提示消息
- (void)showError:(NSString *)message;

/// 显示信息提示（显示在 keyWindow）
/// @param message 提示消息
- (void)showInfo:(NSString *)message;

/// 显示文本提示（显示在 keyWindow）
/// @param message 提示消息
- (void)showText:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
