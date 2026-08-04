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
    if (self.code == APIErrorCodeServerError) {
        return YES;
    }
    if ([self.businessCode isKindOfClass:NSString.class] && self.businessCode.length > 0) {
        NSInteger code = self.businessCode.integerValue;
        return code >= 500 && code < 600;
    }
    return NO;
}

- (BOOL)isAuthenticationError {
    if (self.code == APIErrorCodeUnauthorized) {
        return YES;
    }
    if ([self.businessCode isKindOfClass:NSString.class] && self.businessCode.length > 0) {
        return self.businessCode.integerValue == 401;
    }
    return NO;
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
        // 会员 / 兑换相关错误码（前缀 06xxxx，与 fc-mono ErrorCode 一致）
        kInviteCodeMessages = @{
            // ===== 会员 / 兑换错误（06xxxx）=====
            @"060001": @"购买验证失败，请稍后重试或联系客服",
            @"060002": @"该交易已处理，请勿重复提交",
            @"060003": @"会员方案不存在或已下架",
            @"060004": @"请先勾选并同意会员服务协议",
            @"060005": @"兑换码不存在或已失效",
            @"060006": @"兑换码已过期",
            @"060007": @"该兑换码已达到使用次数上限",
            @"060008": @"兑换码使用名额已满",
            @"060009": @"兑换码已失效",
            // ===== 邀请码错误（兼容旧文档 07xxxx 与正式 14xxxx）=====
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
            // ===== 邮票相关（05xxxx）=====
            @"050001": @"邮票不存在",
            @"050002": @"你尚未持有该邮票",
            @"050009": @"该功能仅限会员使用",
            @"050010": @"主页展示位已满",
            @"50001": @"邮票不存在",
            @"50002": @"你尚未持有该邮票",
            @"50009": @"该功能仅限会员使用",
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
