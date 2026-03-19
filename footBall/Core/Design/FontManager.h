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

/// 14pt 粗体（标题）
@property (nonatomic, strong, readonly) UIFont *font14Bold;

/// 16pt 粗体（标题）
@property (nonatomic, strong, readonly) UIFont *font16Bold;

/// 18pt 粗体（标题）
@property (nonatomic, strong, readonly) UIFont *font18Bold;

/// 20pt 粗体（标题）
@property (nonatomic, strong, readonly) UIFont *font20Bold;

/// 22pt 粗体（标题）
@property (nonatomic, strong, readonly) UIFont *font22Bold;

/// 24pt 粗体（标题）
@property (nonatomic, strong, readonly) UIFont *font24Bold;

/// 26pt 粗体（标题）
@property (nonatomic, strong, readonly) UIFont *font26Bold;

/// 28pt 粗体（标题）
@property (nonatomic, strong, readonly) UIFont *font28Bold;

/// 30pt 粗体（标题）
@property (nonatomic, strong, readonly) UIFont *font30Bold;

/// 32pt 粗体（标题）
@property (nonatomic, strong, readonly) UIFont *font32Bold;

/// 34pt 粗体（标题）
@property (nonatomic, strong, readonly) UIFont *font34Bold;

/// 36pt 粗体（标题）
@property (nonatomic, strong, readonly) UIFont *font36Bold;

/// 38pt 粗体（标题）
@property (nonatomic, strong, readonly) UIFont *font38Bold;

/// 36pt （数字）
@property (nonatomic, strong, readonly) UIFont *font36Regular;

/// 34pt （数字）
@property (nonatomic, strong, readonly) UIFont *font34Regular;

/// 32pt （数字）
@property (nonatomic, strong, readonly) UIFont *font32Regular;

/// 30pt （数字）
@property (nonatomic, strong, readonly) UIFont *font30Regular;

/// 28pt （数字）
@property (nonatomic, strong, readonly) UIFont *font28Regular;

/// 26pt （数字）
@property (nonatomic, strong, readonly) UIFont *font26Regular;

/// 24pt （数字）
@property (nonatomic, strong, readonly) UIFont *font24Regular;

/// 22pt （数字）
@property (nonatomic, strong, readonly) UIFont *font22Regular;

/// 20pt （数字）
@property (nonatomic, strong, readonly) UIFont *font20Regular;

/// 18pt （数字）
@property (nonatomic, strong, readonly) UIFont *font18Regular;

/// 16pt （数字）
@property (nonatomic, strong, readonly) UIFont *font16Regular;

/// 14pt （数字）
@property (nonatomic, strong, readonly) UIFont *font14Regular;

/// 12pt （数字）
@property (nonatomic, strong, readonly) UIFont *font12Regular;

/// 10pt （数字）
@property (nonatomic, strong, readonly) UIFont *font10Regular;

/// 30pt （汉字）
@property (nonatomic, strong, readonly) UIFont *font30;

/// 28pt （汉字）
@property (nonatomic, strong, readonly) UIFont *font28;

/// 26pt （汉字）
@property (nonatomic, strong, readonly) UIFont *font26;

/// 24pt （汉字）
@property (nonatomic, strong, readonly) UIFont *font24;

/// 22pt （汉字）
@property (nonatomic, strong, readonly) UIFont *font22;

/// 20pt （汉字）
@property (nonatomic, strong, readonly) UIFont *font20;

/// 18pt （汉字）
@property (nonatomic, strong, readonly) UIFont *font18;

/// 16pt （汉字）
@property (nonatomic, strong, readonly) UIFont *font16;

/// 14pt （汉字）
@property (nonatomic, strong, readonly) UIFont *font14;

/// 12pt （汉字）
@property (nonatomic, strong, readonly) UIFont *font12;

/// 10pt （汉字）
@property (nonatomic, strong, readonly) UIFont *font10;

//
///// 22pt 半粗体（中标题）
//@property (nonatomic, strong, readonly) UIFont *font22Semibold;
//
///// 18pt 半粗体（大按钮）
//@property (nonatomic, strong, readonly) UIFont *font18Semibold;
//
///// 17pt 常规（正文）
//@property (nonatomic, strong, readonly) UIFont *font17Regular;
//
///// 17pt 中等（正文中等）
//@property (nonatomic, strong, readonly) UIFont *font17Medium;
//
///// 17pt 半粗体（小标题）
//@property (nonatomic, strong, readonly) UIFont *font17Semibold;
//
///// 17pt 粗体（正文加粗）
//@property (nonatomic, strong, readonly) UIFont *font17Bold;
//
///// 16pt 中等（常规按钮）
//@property (nonatomic, strong, readonly) UIFont *font16Medium;
//
///// 15pt 常规（说明文字）
//@property (nonatomic, strong, readonly) UIFont *font15Regular;
//
///// 14pt 中等（小按钮）
//@property (nonatomic, strong, readonly) UIFont *font14Medium;
//
///// 13pt 常规（小号说明文字）
//@property (nonatomic, strong, readonly) UIFont *font13Regular;
//
///// 12pt 常规（脚注）
//@property (nonatomic, strong, readonly) UIFont *font12Regular;

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
