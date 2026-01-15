//
//  APIRequestInterceptor.h
//  footBall
//
//  Created on 2026/1/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class NSURLRequest;
@class NSURLResponse;

/// 请求拦截器协议 - 用于统一处理请求和响应
@protocol APIRequestInterceptor <NSObject>

@optional

/// 拦截请求（在发送前调用）
/// @param request 原始请求
/// @return 修改后的请求，返回nil表示取消请求
- (nullable NSURLRequest *)interceptRequest:(NSURLRequest *)request;

/// 拦截响应（在收到响应后调用）
/// @param response 响应对象
/// @param data 响应数据
/// @param error 错误信息（如果有）
/// @return 是否继续处理响应，返回NO表示拦截器已处理完成
- (BOOL)interceptResponse:(NSURLResponse *)response
                     data:(nullable NSData *)data
                    error:(nullable NSError *)error;

/// 拦截错误（在请求失败时调用）
/// @param error 错误信息
/// @return 处理后的错误，返回nil表示错误已处理
- (nullable NSError *)interceptError:(NSError *)error;

@end

/// 认证拦截器 - 自动添加Token等认证信息
@interface APIAuthenticationInterceptor : NSObject <APIRequestInterceptor>

/// Token获取回调
@property (nonatomic, copy, nullable) NSString *(^tokenProvider)(void);

/// Token刷新回调
@property (nonatomic, copy, nullable) void(^tokenRefreshHandler)(void(^completion)(BOOL success));

/// 初始化方法
/// @param tokenProvider Token提供者
- (instancetype)initWithTokenProvider:(nullable NSString *(^)(void))tokenProvider;

@end

/// 日志拦截器 - 记录请求和响应日志
@interface APILoggingInterceptor : NSObject <APIRequestInterceptor>

/// 是否启用日志（默认：YES）
@property (nonatomic, assign) BOOL enabled;

/// 日志级别（0=无，1=基础，2=详细）
@property (nonatomic, assign) NSInteger logLevel;

/// 初始化方法
/// @param logLevel 日志级别
- (instancetype)initWithLogLevel:(NSInteger)logLevel;

@end

/// 错误处理拦截器 - 统一错误处理
@interface APIErrorHandlingInterceptor : NSObject <APIRequestInterceptor>

/// 错误处理回调
@property (nonatomic, copy, nullable) void(^errorHandler)(NSError *error);

/// 初始化方法
/// @param errorHandler 错误处理回调
- (instancetype)initWithErrorHandler:(nullable void(^)(NSError *error))errorHandler;

@end

NS_ASSUME_NONNULL_END
