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
    error.maxRetryCount = 0; // 默认最大重试3次
    error.retryInterval = 2.0; // 默认重试间隔2秒
    
    return error;
}

+ (instancetype)errorWithBusinessCode:(NSString *)businessCode
                      businessMessage:(nullable NSString *)businessMessage
                       underlyingError:(nullable NSError *)underlyingError {
    APIErrorCode code = [APIError mapBusinessCodeToErrorCode:businessCode.integerValue];
    APIError *error = [self errorWithCode:code
                                   message:businessMessage
                           underlyingError:underlyingError];
    error.businessCode = businessCode;
    error.businessMessage = businessMessage;
    if (businessMessage.length > 0) {
        error.handlingStrategy = APIErrorHandlingStrategyShowAlert;
    }
    
    return error;
}
+ (instancetype)errorWithResponse:(HTTPResponse *)response {
    APIError *error = [self errorWithBusinessCode:response.errorCode businessMessage:response.errorMessage underlyingError:nil];
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
        case NSURLErrorBadServerResponse:
            // 常见于 4xx/5xx（例如网关 502/503）且响应体无法按 JSON 解析时，
            // AFNetworking 会走 failure 并给出 -1011。这里统一按服务器错误处理，
            // 避免被默认 Silent 策略吞掉，导致上层 failure 不回调、loading 卡住。
            return APIErrorCodeServerError;
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

+ (NSString *)normalizedBusinessCode:(NSString *)businessCode {
    if (![businessCode isKindOfClass:NSString.class] || businessCode.length == 0) {
        return @"";
    }
    NSString *trimmed = [[businessCode stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    // 文档示例可能写成 70022 / 070022，后端实际为 140022
    if ([trimmed hasPrefix:@"0"] && trimmed.length > 1) {
        // 保留完整前导零版本用于查表；同时返回去掉前导零的变体在查表侧覆盖
    }
    return trimmed;
}

+ (nullable NSString *)localizedMessageForBusinessCode:(nullable NSString *)businessCode
                                             fallback:(nullable NSString *)fallback {
    NSString *code = [self normalizedBusinessCode:businessCode];
    if (code.length == 0) {
        return fallback;
    }
    // 去掉前导零后再匹配一次（70022 ↔ 070022）
    NSString *stripped = [code stringByReplacingOccurrencesOfString:@"^0+" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, code.length)];

    static NSDictionary<NSString *, NSString *> *kInviteCodeMessages;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 以后端 fc-mono ErrorCode 1400xx 为准；同时兼容文档中的 0700xx / 70022 写法
        kInviteCodeMessages = @{
            @"140022": @"该邀请码已被禁用",
            @"140023": @"该邀请码已过期",
            @"140024": @"该邀请码使用次数已达上限",
            @"140025": @"该邀请码配置异常，请联系客服",
            @"140026": @"该邀请码仅限测试用户使用",
            @"070022": @"该邀请码已被禁用",
            @"070023": @"该邀请码已过期",
            @"070024": @"该邀请码使用次数已达上限",
            @"070025": @"该邀请码配置异常，请联系客服",
            @"070026": @"该邀请码仅限测试用户使用",
            @"70022": @"该邀请码已被禁用",
            @"70023": @"该邀请码已过期",
            @"70024": @"该邀请码使用次数已达上限",
            @"70025": @"该邀请码配置异常，请联系客服",
            @"70026": @"该邀请码仅限测试用户使用",
            @"050001": @"邮票不存在",
            @"050002": @"你尚未持有该邮票",
            @"050010": @"主页展示位已满",
            @"50001": @"邮票不存在",
            @"50002": @"你尚未持有该邮票",
            @"50010": @"主页展示位已满",
        };
    });

    NSString *mapped = kInviteCodeMessages[code] ?: kInviteCodeMessages[stripped];
    return mapped.length > 0 ? mapped : fallback;
}

- (NSString *)displayMessageWithFallback:(nullable NSString *)fallback {
    NSString *mapped = [APIError localizedMessageForBusinessCode:self.businessCode fallback:nil];
    if (mapped.length > 0) {
        return mapped;
    }
    if (self.businessMessage.length > 0) {
        return self.businessMessage;
    }
    if (self.localizedDescription.length > 0) {
        return self.localizedDescription;
    }
    return fallback ?: @"请求失败";
}

@end
