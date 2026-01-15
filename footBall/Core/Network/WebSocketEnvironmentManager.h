//
//  WebSocketEnvironmentManager.h
//  footBall
//
//  Created on 2026/1/15.
//

#import <Foundation/Foundation.h>
#import "APIServerConfig.h"
#import "WebSocketPathConfig.h"

NS_ASSUME_NONNULL_BEGIN

/// WebSocket环境管理器 - 协调服务器地址和路径，提供完整的WebSocket URL
/// 分层设计：
/// 1. APIServerConfigManager - 服务器地址层（复用HTTP的服务器地址配置）
/// 2. WebSocketPathConfigManager - WebSocket路径配置层（管理所有WebSocket路径）
/// 3. WebSocketEnvironmentManager - WebSocket环境管理层（协调服务器地址和路径）
/// 4. WebSocketManager - WebSocket连接层（执行实际的WebSocket连接）
@interface WebSocketEnvironmentManager : NSObject

/// 单例
+ (instancetype)sharedManager;

/// 当前环境（默认：Test）
@property (nonatomic, assign) APIEnvironment currentEnvironment;

/// 当前环境的基础URL（Base URL）- 从 APIServerConfigManager 获取
@property (nonatomic, strong, readonly) NSString *currentBaseURL;

/// 获取指定环境的Base URL（从 APIServerConfigManager 获取）
/// @param environment 环境类型
- (NSString *)baseURLForEnvironment:(APIEnvironment)environment;

/// 获取指定路径名称的完整WebSocket URL（服务器地址 + 路径）
/// @param pathName 路径名称（如：@"chat"）
- (NSString *)fullWebSocketURLForPathName:(NSString *)pathName;

/// 获取指定路径名称的路径值（从 WebSocketPathConfigManager 获取）
/// @param pathName 路径名称
- (NSString *)pathForPathName:(NSString *)pathName;

/// 切换环境
/// @param environment 目标环境
- (void)switchToEnvironment:(APIEnvironment)environment;

/// 获取环境显示名称
/// @param environment 环境类型
+ (NSString *)displayNameForEnvironment:(APIEnvironment)environment;

@end

NS_ASSUME_NONNULL_END
