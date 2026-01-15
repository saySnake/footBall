//
//  WebSocketPathNames.h
//  footBall
//
//  Created on 2026/1/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// WebSocket路径名称常量类 - 统一管理所有WebSocket路径名称
@interface WebSocketPathNames : NSObject

#pragma mark - 聊天模块
/// 聊天WebSocket
FOUNDATION_EXPORT NSString * const WebSocketPathNameChat;
/// 聊天室WebSocket
FOUNDATION_EXPORT NSString * const WebSocketPathNameChatRoom;

#pragma mark - 通知模块
/// 通知WebSocket
FOUNDATION_EXPORT NSString * const WebSocketPathNameNotification;
/// 系统通知WebSocket
FOUNDATION_EXPORT NSString * const WebSocketPathNameNotificationSystem;

#pragma mark - 实时数据模块
/// 实时数据WebSocket
FOUNDATION_EXPORT NSString * const WebSocketPathNameRealtime;
/// 实时价格WebSocket
FOUNDATION_EXPORT NSString * const WebSocketPathNameRealtimePrice;

@end

NS_ASSUME_NONNULL_END
