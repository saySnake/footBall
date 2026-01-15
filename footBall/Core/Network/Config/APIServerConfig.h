//
//  APIServerConfig.h
//  footBall
//
//  Created on 2026/1/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// API环境类型
typedef NS_ENUM(NSInteger, APIEnvironment) {
    APIEnvironmentTest = 0,      // 测试环境
    APIEnvironmentUAT,            // UAT环境
    APIEnvironmentAppStore        // 生产环境（AppStore）
};

/// 服务器配置模型
@interface APIServerConfig : NSObject

/// 环境类型
@property (nonatomic, assign) APIEnvironment environment;

/// 服务器地址（Base URL，如：https://api.example.com）
@property (nonatomic, strong) NSString *serverURL;

/// 显示名称（如：Test、UAT、AppStore）
@property (nonatomic, strong) NSString *displayName;

/// 初始化方法
/// @param environment 环境类型
/// @param serverURL 服务器地址
/// @param displayName 显示名称
+ (instancetype)configWithEnvironment:(APIEnvironment)environment
                            serverURL:(NSString *)serverURL
                          displayName:(NSString *)displayName;

@end

/// 服务器地址配置管理器 - 管理不同环境的服务器地址
@interface APIServerConfigManager : NSObject

/// 单例
+ (instancetype)sharedManager;

/// 获取指定环境的服务器地址
/// @param environment 环境类型
- (NSString *)serverURLForEnvironment:(APIEnvironment)environment;

/// 获取所有服务器配置
- (NSArray<APIServerConfig *> *)allServerConfigs;

/// 设置服务器地址（动态更新）
/// @param serverURL 服务器地址
/// @param environment 环境类型
- (void)setServerURL:(NSString *)serverURL forEnvironment:(APIEnvironment)environment;

#ifdef DEBUG
/// 从 BVAPPEnvironmentHostManager 同步服务器地址（仅Debug模式）
- (void)syncServerURLsFromEnvironmentHostManager;
#endif

@end

NS_ASSUME_NONNULL_END
