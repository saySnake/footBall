//
//  WebSocketPathValues.h
//  footBall
//
//  Created on 2026/1/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// WebSocket路径值常量类 - 统一管理所有WebSocket路径值
@interface WebSocketPathValues : NSObject

#pragma mark - 聊天模块
/// 聊天WebSocket路径
FOUNDATION_EXPORT NSString * const WebSocketPathValueChat;
/// 聊天室WebSocket路径
FOUNDATION_EXPORT NSString * const WebSocketPathValueChatRoom;

#pragma mark - 通知模块
/// 通知WebSocket路径
FOUNDATION_EXPORT NSString * const WebSocketPathValueNotification;
/// 系统通知WebSocket路径
FOUNDATION_EXPORT NSString * const WebSocketPathValueNotificationSystem;

#pragma mark - 实时数据模块
/// 实时数据WebSocket路径
FOUNDATION_EXPORT NSString * const WebSocketPathValueRealtime;
/// 实时价格WebSocket路径
FOUNDATION_EXPORT NSString * const WebSocketPathValueRealtimePrice;

@end

NS_ASSUME_NONNULL_END
