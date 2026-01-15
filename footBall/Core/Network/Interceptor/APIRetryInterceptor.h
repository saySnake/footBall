//
//  APIRetryInterceptor.h
//  footBall
//
//  Created on 2026/1/15.
//

#import "APIRequestInterceptor.h"

NS_ASSUME_NONNULL_BEGIN

/// 重试拦截器 - 自动重试失败的请求
@interface APIRetryInterceptor : NSObject <APIRequestInterceptor>

/// 最大重试次数（默认：3次）
@property (nonatomic, assign) NSInteger maxRetryCount;

/// 重试间隔（默认：2秒）
@property (nonatomic, assign) NSTimeInterval retryInterval;

/// 是否启用重试（默认：YES）
@property (nonatomic, assign) BOOL enabled;

/// 重试回调（可选，用于记录重试日志）
@property (nonatomic, copy, nullable) void(^retryHandler)(NSInteger retryCount, NSError *error);

/// 初始化方法
/// @param maxRetryCount 最大重试次数
/// @param retryInterval 重试间隔（秒）
- (instancetype)initWithMaxRetryCount:(NSInteger)maxRetryCount
                         retryInterval:(NSTimeInterval)retryInterval;

@end

NS_ASSUME_NONNULL_END
