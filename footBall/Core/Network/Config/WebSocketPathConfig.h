//
//  WebSocketPathConfig.h
//  footBall
//
//  Created on 2026/1/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// WebSocket路径配置模型
@interface WebSocketPathConfig : NSObject

/// 路径名称（用于标识，如：@"chat"、@"notification"）
@property (nonatomic, strong) NSString *name;

/// 路径值（如：@"/ws/chat"、@"/ws/notification"）
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

/// WebSocket路径配置管理器 - 统一管理所有WebSocket路径
/// 
/// 使用说明：
/// 1. 【推荐】直接使用路径字符串，无需预注册：
///    - 使用完整路径：@"/ws/chat"
///    - 使用约定路径：@"chat" 会自动转换为 {defaultPathPrefix}/chat（默认 @"/ws/chat"）
///
/// 2. 【可选】修改WebSocket路径前缀（当路径结构变化时）：
///    [WebSocketPathConfigManager sharedManager].defaultPathPrefix = @"/websocket/v2";
///    之后 @"chat" 会自动转换为 @"/websocket/v2/chat"
///
/// 3. 【可选】按需注册特殊路径（仅当路径不符合约定时）：
///    [[WebSocketPathConfigManager sharedManager] registerPathWithName:@"custom" path:@"/custom/ws/path"];
///
/// 4. 【已废弃】不再需要预加载所有路径配置，避免维护大量接口的注册代码
@interface WebSocketPathConfigManager : NSObject

/// 单例
+ (instancetype)sharedManager;

/// WebSocket路径前缀（用于自动转换路径名称）
/// 默认值：@"/ws"
/// 
/// 示例：
/// - 设置 prefix 为 @"/websocket/v2" 时，@"chat" 会转换为 @"/websocket/v2/chat"
/// - 设置 prefix 为 @"/socket" 时，@"chat" 会转换为 @"/socket/chat"
/// 
/// 注意：会自动处理前缀格式（确保以 / 开头，不以 / 结尾）
@property (nonatomic, strong) NSString *defaultPathPrefix;

/// 获取指定路径名称的路径值（智能解析）
/// @param pathName 路径名称或路径字符串
/// @return 解析后的路径
/// 
/// 解析规则：
/// 1. 如果 pathName 已注册，返回注册的路径
/// 2. 如果 pathName 以 / 开头，直接作为路径使用
/// 3. 否则，按照约定转换为路径：{defaultPathPrefix}/pathName
///    （默认：@"chat" -> @"/ws/chat"，可通过 defaultPathPrefix 修改）
- (NSString *)pathForPathName:(NSString *)pathName;

/// 获取所有路径配置
- (NSDictionary<NSString *, WebSocketPathConfig *> *)allPathConfigs;

/// 注册路径配置
/// @param pathConfig 路径配置
- (void)registerPathConfig:(WebSocketPathConfig *)pathConfig;

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
