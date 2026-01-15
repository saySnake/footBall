//
//  APIError.m
//  footBall
//
//  Created on 2026/1/15.
//

#import "APIError.h"
#import <objc/runtime.h>

@implementation APIError

// 使用关联对象存储重试次数（因为NSError的userInfo是只读的）
static char kRetryCountKey;

- (NSInteger)retryCount {
    NSNumber *count = objc_getAssociatedObject(self, &kRetryCountKey);
    return count ? [count integerValue] : 0;
}

- (void)setRetryCount:(NSInteger)retryCount {
    objc_setAssociatedObject(self, &kRetryCountKey, @(retryCount), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)hasReachedMaxRetryCount {
    return self.retryCount >= self.maxRetryCount;
}

+ (instancetype)errorWithCode:(APIErrorCode)code
                       message:(nullable NSString *)message
               underlyingError:(nullable NSError *)underlyingError {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (message) {
        userInfo[NSLocalizedDescriptionKey] = message;
    }
    if (underlyingError) {
        userInfo[NSUnderlyingErrorKey] = underlyingError;
    }
    
    APIError *error = [[APIError alloc] initWithDomain:@"APIErrorDomain"
                                                  code:code
                                              userInfo:userInfo];
    error.underlyingError = underlyingError;
    error.handlingStrategy = [APIError defaultHandlingStrategyForCode:code];
    error.maxRetryCount = 3; // 默认最大重试3次
    error.retryInterval = 2.0; // 默认重试间隔2秒
    
    return error;
}

+ (instancetype)errorWithBusinessCode:(NSInteger)businessCode
                      businessMessage:(nullable NSString *)businessMessage
                       underlyingError:(nullable NSError *)underlyingError {
    APIErrorCode code = [APIError mapBusinessCodeToErrorCode:businessCode];
    APIError *error = [self errorWithCode:code
                                   message:businessMessage
                           underlyingError:underlyingError];
    error.businessCode = businessCode;
    error.businessMessage = businessMessage;
    
    return error;
}

+ (instancetype)errorFromNSError:(NSError *)error {
    if ([error isKindOfClass:[APIError class]]) {
        return (APIError *)error;
    }
    
    APIErrorCode code = [APIError mapNSErrorCodeToErrorCode:error.code];
    NSString *message = error.localizedDescription ?: @"网络请求失败";
    
    return [self errorWithCode:code message:message underlyingError:error];
}

+ (APIErrorHandlingStrategy)defaultHandlingStrategyForCode:(APIErrorCode)code {
    switch (code) {
        case APIErrorCodeNetworkUnavailable:
        case APIErrorCodeTimeout:
            return APIErrorHandlingStrategyRetry;
        case APIErrorCodeUnauthorized:
            return APIErrorHandlingStrategyShowAlert;
        case APIErrorCodeServerError:
            return APIErrorHandlingStrategyShowAlert;
        default:
            return APIErrorHandlingStrategySilent;
    }
}

+ (APIErrorCode)mapBusinessCodeToErrorCode:(NSInteger)businessCode {
    switch (businessCode) {
        case 401:
            return APIErrorCodeUnauthorized;
        case 403:
            return APIErrorCodeForbidden;
        case 404:
            return APIErrorCodeNotFound;
        case 400:
            return APIErrorCodeBadRequest;
        case 500:
        case 502:
        case 503:
        case 504:
            return APIErrorCodeServerError;
        default:
            return APIErrorCodeUnknown;
    }
}

+ (APIErrorCode)mapNSErrorCodeToErrorCode:(NSInteger)nsErrorCode {
    switch (nsErrorCode) {
        case NSURLErrorNotConnectedToInternet:
        case NSURLErrorNetworkConnectionLost:
        case NSURLErrorCannotConnectToHost:
            return APIErrorCodeNetworkUnavailable;
        case NSURLErrorTimedOut:
            return APIErrorCodeTimeout;
        case NSURLErrorCancelled:
            return APIErrorCodeCancelled;
        default:
            return APIErrorCodeUnknown;
    }
}

- (BOOL)canRetry {
    return self.handlingStrategy == APIErrorHandlingStrategyRetry ||
           (self.code == APIErrorCodeTimeout || self.code == APIErrorCodeNetworkUnavailable);
}

- (BOOL)isNetworkError {
    return self.code == APIErrorCodeNetworkUnavailable ||
           self.code == APIErrorCodeTimeout ||
           self.code == APIErrorCodeCancelled;
}

- (BOOL)isServerError {
    return self.code == APIErrorCodeServerError ||
           self.businessCode >= 500;
}

- (BOOL)isAuthenticationError {
    return self.code == APIErrorCodeUnauthorized ||
           self.businessCode == 401;
}

@end
