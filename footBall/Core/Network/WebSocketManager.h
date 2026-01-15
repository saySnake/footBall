//
//  WebSocketManager.h
//  footBall
//
//  Created on 2026/1/15.
//

#import <Foundation/Foundation.h>
#import "APIServerConfig.h"

NS_ASSUME_NONNULL_BEGIN

/// WebSocket连接状态
typedef NS_ENUM(NSInteger, WebSocketStatus) {
    WebSocketStatusDisconnected = 0,  // 未连接
    WebSocketStatusConnecting,         // 连接中
    WebSocketStatusConnected,          // 已连接
    WebSocketStatusReconnecting        // 重连中
};

/// WebSocket消息回调
typedef void(^WebSocketMessageBlock)(id message);
/// WebSocket连接状态变化回调
typedef void(^WebSocketStatusBlock)(WebSocketStatus status);
/// WebSocket错误回调
typedef void(^WebSocketErrorBlock)(NSError *error);

/// WebSocket管理器 - 封装SocketRocket
@interface WebSocketManager : NSObject

/// 单例
+ (instancetype)sharedManager;

/// 当前连接状态
@property (nonatomic, assign, readonly) WebSocketStatus status;

/// 是否自动重连（默认YES）
@property (nonatomic, assign) BOOL autoReconnect;

/// 重连间隔（默认3秒）
@property (nonatomic, assign) NSTimeInterval reconnectInterval;

/// 最大重连次数（默认5次，0表示无限重连）
@property (nonatomic, assign) NSInteger maxReconnectCount;

/// 是否启用心跳（默认NO）
@property (nonatomic, assign) BOOL enableHeartbeat;

/// 心跳间隔（默认30秒）
@property (nonatomic, assign) NSTimeInterval heartbeatInterval;

/// 连接超时时间（默认30秒）
@property (nonatomic, assign) NSTimeInterval connectTimeout;

/// 是否在断开时缓存消息（默认NO）
@property (nonatomic, assign) BOOL cacheMessagesWhenDisconnected;

/// 最大缓存消息数（默认100条）
@property (nonatomic, assign) NSInteger maxCachedMessages;

/// 消息回调
@property (nonatomic, copy, nullable) WebSocketMessageBlock messageBlock;

/// 连接状态变化回调
@property (nonatomic, copy, nullable) WebSocketStatusBlock statusBlock;

/// 错误回调
@property (nonatomic, copy, nullable) WebSocketErrorBlock errorBlock;

/// 连接WebSocket
/// @param URLString WebSocket地址
/// @param protocols 子协议数组（可选）
- (void)connectWithURLString:(NSString *)URLString
                    protocols:(nullable NSArray<NSString *> *)protocols;

/// 连接WebSocket（带请求头）
/// @param URLString WebSocket地址
/// @param protocols 子协议数组（可选）
/// @param headers 请求头字典（可选）
- (void)connectWithURLString:(NSString *)URLString
                    protocols:(nullable NSArray<NSString *> *)protocols
                      headers:(nullable NSDictionary<NSString *, NSString *> *)headers;

/// 连接WebSocket（使用路径名称）
/// @param pathName 路径名称（如：@"chat"）
/// @param protocols 子协议数组（可选）
- (void)connectWithPathName:(NSString *)pathName
                   protocols:(nullable NSArray<NSString *> *)protocols;

/// 连接WebSocket（使用路径名称，带请求头）
/// @param pathName 路径名称（如：@"chat"）
/// @param protocols 子协议数组（可选）
/// @param headers 请求头字典（可选）
- (void)connectWithPathName:(NSString *)pathName
                   protocols:(nullable NSArray<NSString *> *)protocols
                     headers:(nullable NSDictionary<NSString *, NSString *> *)headers;

/// 连接WebSocket（使用路径名称和环境）
/// @param pathName 路径名称（如：@"chat"）
/// @param environment 环境类型（可选，nil时使用当前环境）
/// @param protocols 子协议数组（可选）
/// @param headers 请求头字典（可选）
- (void)connectWithPathName:(NSString *)pathName
                environment:(nullable NSNumber *)environment
                   protocols:(nullable NSArray<NSString *> *)protocols
                     headers:(nullable NSDictionary<NSString *, NSString *> *)headers;

/// 断开连接
- (void)disconnect;

/// 发送消息
/// @param message 消息内容（NSString或NSData）
/// @return 是否发送成功
- (BOOL)sendMessage:(id)message;

/// 发送JSON消息
/// @param jsonObject JSON对象（字典或数组）
/// @return 是否发送成功
- (BOOL)sendJSON:(id)jsonObject;

/// 发送Ping（心跳包）
- (void)sendPing;

/// 手动重连
- (void)reconnect;

/// 清空缓存的消息
- (void)clearCachedMessages;

/// 获取缓存的消息数量
- (NSInteger)cachedMessagesCount;

@end

NS_ASSUME_NONNULL_END
