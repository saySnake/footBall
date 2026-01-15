//
//  APIPathConfig.h
//  footBall
//
//  Created on 2026/1/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// API路径配置模型
@interface APIPathConfig : NSObject

/// 路径名称（用于标识，如：@"user"、@"auth"）
@property (nonatomic, strong) NSString *name;

/// 路径值（如：@"/api/v1/user"、@"/api/v1/auth"）
@property (nonatomic, strong) NSString *path;

/// 路径描述（可选）
@property (nonatomic, strong, nullable) NSString *pathDescription;

/// 初始化方法
/// @param name 路径名称
/// @param path 路径值
+ (instancetype)configWithName:(NSString *)name path:(NSString *)path;

/// 初始化方法（带描述）
/// @param name 路径名称
/// @param path 路径值
/// @param description 路径描述
+ (instancetype)configWithName:(NSString *)name path:(NSString *)path description:(nullable NSString *)description;

@end

/// API路径配置管理器 - 统一管理所有API路径
@interface APIPathConfigManager : NSObject

/// 单例
+ (instancetype)sharedManager;

/// 获取指定路径名称的路径值
/// @param pathName 路径名称（如：@"user"）
- (NSString *)pathForPathName:(NSString *)pathName;

/// 获取所有路径配置
- (NSDictionary<NSString *, APIPathConfig *> *)allPathConfigs;

/// 注册路径配置
/// @param pathConfig 路径配置
- (void)registerPathConfig:(APIPathConfig *)pathConfig;

/// 注册路径配置（便捷方法）
/// @param name 路径名称
/// @param path 路径值
- (void)registerPathWithName:(NSString *)name path:(NSString *)path;

/// 注册路径配置（便捷方法，带描述）
/// @param name 路径名称
/// @param path 路径值
/// @param description 路径描述
- (void)registerPathWithName:(NSString *)name path:(NSString *)path description:(nullable NSString *)description;

/// 移除路径配置
/// @param pathName 路径名称
- (void)removePathConfigWithName:(NSString *)pathName;

/// 清空所有路径配置
- (void)clearAllPathConfigs;

@end

NS_ASSUME_NONNULL_END
