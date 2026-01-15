//
//  FontManager.h
//  footBall
//
//  Created on 2026/1/15.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 字体管理器 - 统一管理应用字体规范
@interface FontManager : NSObject

/// 单例
+ (instancetype)sharedManager;

#pragma mark - 字体属性（按大小命名）

/// 34pt 粗体（超大标题）
@property (nonatomic, strong, readonly) UIFont *font34Bold;

/// 28pt 粗体（大标题）
@property (nonatomic, strong, readonly) UIFont *font28Bold;

/// 22pt 半粗体（中标题）
@property (nonatomic, strong, readonly) UIFont *font22Semibold;

/// 18pt 半粗体（大按钮）
@property (nonatomic, strong, readonly) UIFont *font18Semibold;

/// 17pt 常规（正文）
@property (nonatomic, strong, readonly) UIFont *font17Regular;

/// 17pt 中等（正文中等）
@property (nonatomic, strong, readonly) UIFont *font17Medium;

/// 17pt 半粗体（小标题）
@property (nonatomic, strong, readonly) UIFont *font17Semibold;

/// 17pt 粗体（正文加粗）
@property (nonatomic, strong, readonly) UIFont *font17Bold;

/// 16pt 中等（常规按钮）
@property (nonatomic, strong, readonly) UIFont *font16Medium;

/// 15pt 常规（说明文字）
@property (nonatomic, strong, readonly) UIFont *font15Regular;

/// 14pt 中等（小按钮）
@property (nonatomic, strong, readonly) UIFont *font14Medium;

/// 13pt 常规（小号说明文字）
@property (nonatomic, strong, readonly) UIFont *font13Regular;

/// 12pt 常规（脚注）
@property (nonatomic, strong, readonly) UIFont *font12Regular;

#pragma mark - 便捷方法

/// 获取指定大小的字体
/// @param size 字体大小
+ (UIFont *)fontOfSize:(CGFloat)size;

/// 获取指定大小和字重的字体
/// @param size 字体大小
/// @param weight 字重
+ (UIFont *)fontOfSize:(CGFloat)size weight:(UIFontWeight)weight;

/// 获取指定大小的粗体字体
/// @param size 字体大小
+ (UIFont *)boldFontOfSize:(CGFloat)size;

/// 获取指定大小的中等字重字体
/// @param size 字体大小
+ (UIFont *)mediumFontOfSize:(CGFloat)size;

@end

NS_ASSUME_NONNULL_END
