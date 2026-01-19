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

/// 服务器配置模型 - 统一管理HTTP和WebSocket服务器地址
@interface APIServerConfig : NSObject

/// 环境类型
@property (nonatomic, assign) APIEnvironment environment;

/// HTTP服务器地址（Base URL，如：https://api.example.com）
@property (nonatomic, strong) NSString *serverURL;

/// WebSocket服务器地址（Base URL，如：wss://ws.example.com）
/// 如果未设置，将自动从 serverURL 转换（https:// -> wss://, http:// -> ws://）
@property (nonatomic, strong, nullable) NSString *webSocketURL;

/// 显示名称（如：Test、UAT、AppStore）
@property (nonatomic, strong) NSString *displayName;

/// 初始化方法（仅HTTP地址）
/// @param environment 环境类型
/// @param serverURL HTTP服务器地址
/// @param displayName 显示名称
+ (instancetype)configWithEnvironment:(APIEnvironment)environment
                            serverURL:(NSString *)serverURL
                          displayName:(NSString *)displayName;

/// 初始化方法（HTTP和WebSocket地址）
/// @param environment 环境类型
/// @param serverURL HTTP服务器地址
/// @param webSocketURL WebSocket服务器地址（可选，nil时自动从serverURL转换）
/// @param displayName 显示名称
+ (instancetype)configWithEnvironment:(APIEnvironment)environment
                            serverURL:(NSString *)serverURL
                         webSocketURL:(nullable NSString *)webSocketURL
                          displayName:(NSString *)displayName;

@end

/// 服务器地址配置管理器 - 统一管理不同环境的HTTP和WebSocket服务器地址
@interface APIServerConfigManager : NSObject

/// 单例
+ (instancetype)sharedManager;

/// 获取指定环境的HTTP服务器地址
/// @param environment 环境类型
- (NSString *)serverURLForEnvironment:(APIEnvironment)environment;

/// 获取指定环境的WebSocket服务器地址
/// @param environment 环境类型
/// @return WebSocket服务器地址，如果未配置则自动从HTTP地址转换
- (NSString *)webSocketURLForEnvironment:(APIEnvironment)environment;

/// 获取所有服务器配置
- (NSArray<APIServerConfig *> *)allServerConfigs;

/// 设置HTTP服务器地址（动态更新）
/// @param serverURL HTTP服务器地址
/// @param environment 环境类型
- (void)setServerURL:(NSString *)serverURL forEnvironment:(APIEnvironment)environment;

/// 设置WebSocket服务器地址（动态更新）
/// @param webSocketURL WebSocket服务器地址
/// @param environment 环境类型
- (void)setWebSocketURL:(NSString *)webSocketURL forEnvironment:(APIEnvironment)environment;

/// 同时设置HTTP和WebSocket服务器地址（动态更新）
/// @param serverURL HTTP服务器地址
/// @param webSocketURL WebSocket服务器地址（可选，nil时自动从serverURL转换）
/// @param environment 环境类型
- (void)setServerURL:(NSString *)serverURL
        webSocketURL:(nullable NSString *)webSocketURL
       forEnvironment:(APIEnvironment)environment;

#ifdef DEBUG
/// 从 BVAPPEnvironmentHostManager 同步服务器地址（仅Debug模式）
/// 同时同步HTTP和WebSocket地址
- (void)syncServerURLsFromEnvironmentHostManager;
#endif

@end

NS_ASSUME_NONNULL_END
