//
//  APIError.h
//  footBall
//
//  Created on 2026/1/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// API错误码
typedef NS_ENUM(NSInteger, APIErrorCode) {
    APIErrorCodeUnknown = -1,              // 未知错误
    APIErrorCodeNetworkUnavailable = -1000, // 网络不可用
    APIErrorCodeTimeout = -1001,           // 请求超时
    APIErrorCodeCancelled = -1002,         // 请求取消
    APIErrorCodeServerError = 500,         // 服务器错误
    APIErrorCodeUnauthorized = 401,        // 未授权
    APIErrorCodeForbidden = 403,           // 禁止访问
    APIErrorCodeNotFound = 404,             // 资源不存在
    APIErrorCodeBadRequest = 400           // 请求错误
};

/// 错误处理策略
typedef NS_ENUM(NSInteger, APIErrorHandlingStrategy) {
    APIErrorHandlingStrategyRetry,      // 重试
    APIErrorHandlingStrategyShowAlert,  // 显示提示
    APIErrorHandlingStrategySilent,     // 静默处理
    APIErrorHandlingStrategyCustom      // 自定义处理
};

/// API错误模型 - 统一错误处理
@interface APIError : NSError

/// 业务错误码（服务器返回的错误码）
@property (nonatomic, assign) NSInteger businessCode;

/// 业务错误消息（服务器返回的错误消息）
@property (nonatomic, strong, nullable) NSString *businessMessage;

/// 原始错误（底层网络错误）
@property (nonatomic, strong, nullable) NSError *underlyingError;

/// 请求路径
@property (nonatomic, strong, nullable) NSString *requestPath;

/// 错误处理策略
@property (nonatomic, assign) APIErrorHandlingStrategy handlingStrategy;

/// 是否可重试
@property (nonatomic, assign, readonly) BOOL canRetry;

/// 当前重试次数
@property (nonatomic, assign) NSInteger retryCount;

/// 最大重试次数（默认：3次）
@property (nonatomic, assign) NSInteger maxRetryCount;

/// 重试间隔（默认：2秒）
@property (nonatomic, assign) NSTimeInterval retryInterval;

/// 是否已达到最大重试次数
@property (nonatomic, assign, readonly) BOOL hasReachedMaxRetryCount;

/// 初始化方法
/// @param code 错误码
/// @param message 错误消息
/// @param underlyingError 底层错误
+ (instancetype)errorWithCode:(APIErrorCode)code
                       message:(nullable NSString *)message
               underlyingError:(nullable NSError *)underlyingError;

/// 初始化方法（带业务错误码）
/// @param businessCode 业务错误码
/// @param businessMessage 业务错误消息
/// @param underlyingError 底层错误
+ (instancetype)errorWithBusinessCode:(NSInteger)businessCode
                      businessMessage:(nullable NSString *)businessMessage
                       underlyingError:(nullable NSError *)underlyingError;

/// 从NSError创建APIError
/// @param error 原始错误
+ (instancetype)errorFromNSError:(NSError *)error;

/// 判断是否为网络错误
- (BOOL)isNetworkError;

/// 判断是否为服务器错误
- (BOOL)isServerError;

/// 判断是否为认证错误
- (BOOL)isAuthenticationError;

@end

NS_ASSUME_NONNULL_END
