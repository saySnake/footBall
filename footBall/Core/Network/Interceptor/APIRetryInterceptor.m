//
//  APIRetryInterceptor.m
//  footBall
//
//  Created on 2026/1/15.
//

#import "APIRetryInterceptor.h"
#import "APIError.h"
#import <objc/runtime.h>

// 使用关联对象存储请求信息，用于重试
static char kRequestInfoKey;

@interface APIRetryRequestInfo : NSObject
@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, copy) void(^retryBlock)(void);
@property (nonatomic, assign) NSInteger retryCount;
@end

@implementation APIRetryRequestInfo
@end

@implementation APIRetryInterceptor

- (instancetype)init {
    return [self initWithMaxRetryCount:3 retryInterval:2.0];
}

- (instancetype)initWithMaxRetryCount:(NSInteger)maxRetryCount
                         retryInterval:(NSTimeInterval)retryInterval {
    self = [super init];
    if (self) {
        _maxRetryCount = maxRetryCount;
        _retryInterval = retryInterval;
        _enabled = YES;
    }
    return self;
}

- (nullable NSURLRequest *)interceptRequest:(NSURLRequest *)request {
    if (!self.enabled) {
        return request;
    }
    
    // 存储请求信息，用于重试
    APIRetryRequestInfo *requestInfo = [[APIRetryRequestInfo alloc] init];
    requestInfo.request = request;
    requestInfo.retryCount = 0;
    objc_setAssociatedObject(request, &kRequestInfoKey, requestInfo, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    return request;
}

- (nullable NSError *)interceptError:(NSError *)error {
    if (!self.enabled) {
        return error;
    }
    
    // 转换为APIError
    APIError *apiError = [APIError errorFromNSError:error];
    
    // 检查是否可以重试
    if (!apiError.canRetry) {
        return apiError;
    }
    
    // 检查是否已达到最大重试次数
    if (apiError.hasReachedMaxRetryCount) {
        NSLog(@"⚠️ 已达到最大重试次数 %ld，停止重试", (long)apiError.maxRetryCount);
        return apiError;
    }
    
    // 检查是否超过配置的最大重试次数
    if (apiError.retryCount >= self.maxRetryCount) {
        NSLog(@"⚠️ 已达到配置的最大重试次数 %ld，停止重试", (long)self.maxRetryCount);
        return apiError;
    }
    
    // 增加重试次数
    apiError.retryCount = apiError.retryCount + 1;
    apiError.maxRetryCount = self.maxRetryCount;
    apiError.retryInterval = self.retryInterval;
    
    // 调用重试回调
    if (self.retryHandler) {
        self.retryHandler(apiError.retryCount, apiError);
    }
    
    NSLog(@"🔄 准备第 %ld 次重试（最大 %ld 次），间隔 %.1f 秒", 
          (long)apiError.retryCount, 
          (long)self.maxRetryCount, 
          self.retryInterval);
    
    // 返回错误，但不阻止错误传播
    // 重试逻辑应该在APIManager中实现
    return apiError;
}

@end
