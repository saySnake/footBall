//
//  ThemeImageManager.h
//  footBall
//
//  Created on 2026/1/15.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 主题图片管理器 - 根据当前主题自动加载对应的图片
/// 支持图片命名规则：
/// - 白天模式：image.png
/// - 夜间模式：image_night.png
@interface ThemeImageManager : NSObject

/// 单例
+ (instancetype)sharedManager;

/// 根据图片名称加载图片（自动根据当前主题选择）
/// @param imageName 图片名称（不含 _night 后缀）
/// @return 图片对象，如果未找到则返回 nil
- (nullable UIImage *)imageNamed:(NSString *)imageName;

/// 根据图片名称加载图片（指定主题）
/// @param imageName 图片名称（不含 _night 后缀）
/// @param isDarkMode 是否为夜间模式
/// @return 图片对象，如果未找到则返回 nil
- (nullable UIImage *)imageNamed:(NSString *)imageName darkMode:(BOOL)isDarkMode;

/// 根据图片名称加载图片（指定主题，带 Bundle）
/// @param imageName 图片名称（不含 _night 后缀）
/// @param bundle Bundle 对象（可选，nil 表示使用 mainBundle）
/// @param isDarkMode 是否为夜间模式
/// @return 图片对象，如果未找到则返回 nil
- (nullable UIImage *)imageNamed:(NSString *)imageName
                           bundle:(nullable NSBundle *)bundle
                        darkMode:(BOOL)isDarkMode;

/// 获取图片名称（根据主题自动添加后缀）
/// @param imageName 基础图片名称
/// @param isDarkMode 是否为夜间模式
/// @return 完整的图片名称（如：image_night.png）
+ (NSString *)imageNameForTheme:(NSString *)imageName darkMode:(BOOL)isDarkMode;

/// 检查图片是否存在（根据当前主题）
/// @param imageName 图片名称（不含 _night 后缀）
/// @return 是否存在
- (BOOL)imageExists:(NSString *)imageName;

/// 检查图片是否存在（指定主题）
/// @param imageName 图片名称（不含 _night 后缀）
/// @param isDarkMode 是否为夜间模式
/// @return 是否存在
- (BOOL)imageExists:(NSString *)imageName darkMode:(BOOL)isDarkMode;

@end

#pragma mark - UIImage 扩展

/// UIImage 扩展 - 支持主题图片加载
@interface UIImage (Theme)

/// 根据图片名称加载图片（自动根据当前主题选择）
/// @param imageName 图片名称（不含 _night 后缀）
/// @return 图片对象，如果未找到则返回 nil
+ (nullable UIImage *)themeImageNamed:(NSString *)imageName;

/// 根据图片名称加载图片（指定主题）
/// @param imageName 图片名称（不含 _night 后缀）
/// @param isDarkMode 是否为夜间模式
/// @return 图片对象，如果未找到则返回 nil
+ (nullable UIImage *)themeImageNamed:(NSString *)imageName darkMode:(BOOL)isDarkMode;

@end

NS_ASSUME_NONNULL_END
