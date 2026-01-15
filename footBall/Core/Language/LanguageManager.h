//
//  LanguageManager.h
//  footBall
//
//  Created on 2026/1/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 语言类型
typedef NS_ENUM(NSInteger, AppLanguage) {
    AppLanguageSystem = 0,  // 跟随系统
    AppLanguageChinese,     // 简体中文
    AppLanguageEnglish,     // 英文
    AppLanguageTraditionalChinese  // 繁体中文
};

/// 语言变化通知
FOUNDATION_EXPORT NSString *const AppLanguageDidChangeNotification;

/// 语言管理器
@interface LanguageManager : NSObject

/// 单例
+ (instancetype)sharedManager;

/// 当前语言
@property (nonatomic, assign) AppLanguage currentLanguage;

/// 当前语言代码（如：zh-Hans, en）
@property (nonatomic, strong, readonly, nullable) NSString *currentLanguageCode;

/// 获取本地化字符串
/// @param key 键
/// @param comment 注释（可选）
+ (NSString *)localizedStringForKey:(NSString *)key comment:(nullable NSString *)comment;

/// 获取本地化字符串（带参数）
/// @param key 键
/// @param arguments 参数数组
+ (NSString *)localizedStringForKey:(NSString *)key arguments:(NSArray *)arguments;

/// 设置语言
/// @param language 语言类型
- (void)setLanguage:(AppLanguage)language;

/// 获取支持的语言列表
+ (NSArray<NSString *> *)supportedLanguages;

/// 获取语言显示名称
/// @param language 语言类型
+ (NSString *)displayNameForLanguage:(AppLanguage)language;

@end

NS_ASSUME_NONNULL_END

/// 便捷宏定义 - 获取本地化字符串
#define L(key) [LanguageManager localizedStringForKey:key comment:nil]

/// 便捷宏定义 - 获取带参数的本地化字符串
#define LFormat(key, ...) [LanguageManager localizedStringForKey:key arguments:@[__VA_ARGS__]]
