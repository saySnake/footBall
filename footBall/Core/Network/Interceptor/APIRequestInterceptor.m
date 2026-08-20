//
//  APIRequestInterceptor.m
//  footBall
//
//  Created on 2026/1/15.
//

#import "APIRequestInterceptor.h"
#import "APIError.h"
#import "PNAppVersionManager.h"
#import "PNAppVersionInfo.h"

@implementation APIAuthenticationInterceptor

- (instancetype)init {
    return [self initWithTokenProvider:nil];
}

- (instancetype)initWithTokenProvider:(nullable NSString *(^)(void))tokenProvider {
    self = [super init];
    if (self) {
        _tokenProvider = tokenProvider;
    }
    return self;
}

- (nullable NSURLRequest *)interceptRequest:(NSURLRequest *)request{
    if (!self.tokenProvider) {
        return request;
    }
    
    NSString *token = self.tokenProvider();
    if (!token || token.length == 0) {
        return request;
    }
    
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    [mutableRequest setValue:[NSString stringWithFormat:@"Bearer %@", token] 
          forHTTPHeaderField:@"Authorization"];
    
    return mutableRequest;
}

@end

@implementation APILoggingInterceptor

- (instancetype)init {
    return [self initWithLogLevel:2];
}

- (instancetype)initWithLogLevel:(NSInteger)logLevel {
    self = [super init];
    if (self) {
        _enabled = YES;
        _logLevel = logLevel;
    }
    return self;
}

- (nullable NSURLRequest *)interceptRequest:(NSURLRequest *)request{
    if (!self.enabled || self.logLevel < 1) {
        return request;
    }
    
//    NSLog(@"🌐 [API Request] %@ %@", request.HTTPMethod, request.URL.absoluteString);
//    
//    if (self.logLevel >= 2 && request.HTTPBody) {
//        NSString *bodyString = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
//        NSLog(@"📤 [Request Body] %@", bodyString);
//    }
//    
//    if (self.logLevel >= 2 && request.allHTTPHeaderFields.count > 0) {
//        NSLog(@"📋 [Request Headers] %@", request.allHTTPHeaderFields);
//    }
    
    return request;
}

- (BOOL)interceptResponse:(id)response task:(NSURLSessionDataTask *)task{
    if (!self.enabled || self.logLevel < 1) {
        return YES;
    }
    NSURLRequest *request = task.originalRequest;
    NSLog(@"🌐 [HTTP Request] %@ %@", request.HTTPMethod, request.URL.absoluteString);
    
    if (self.logLevel >= 2 && request.HTTPBody) {
        NSString *bodyString = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
        NSLog(@"📤 [HTTP Body] %@", bodyString);
    }
    
    if (self.logLevel >= 2 && request.allHTTPHeaderFields.count > 0) {
        NSLog(@"📋 [HTTP Headers] %@", request.allHTTPHeaderFields);
    }
    NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)task.response;
    if (self.logLevel >= 2 && response) {
        NSLog(@"✅ [HTTP Response] %ld ***************** \n%@\n✅ [HTTP Response]***************** ",httpResp.statusCode,response);
    }
    
    return YES;
}
- (NSError *)interceptError:(NSError *)error task:(NSURLSessionDataTask *)task{
    
    NSURLRequest *request = task.originalRequest;
    NSLog(@"🌐 [HTTP Request] %@ %@", request.HTTPMethod, request.URL.absoluteString);
    
    if (self.logLevel >= 2 && request.HTTPBody) {
        NSString *bodyString = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
        NSLog(@"📤 [HTTP Body] %@", bodyString);
    }
    
    if (self.logLevel >= 2 && request.allHTTPHeaderFields.count > 0) {
        NSLog(@"📋 [HTTP Headers] %@", request.allHTTPHeaderFields);
    }
    NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)task.response;
    NSLog(@"❌ [HTTP Response] %ld\n❌ [HTTP ERROR]***************** \n%@\n❌ [HTTP ERROR]*****************",httpResp.statusCode,error);
    return error;
}
@end

@implementation APIErrorHandlingInterceptor

/// 判断 refresh 失败是否为「服务端明确判定 token 失效」。
/// 只有确定失效才登出；网络超时/断网/取消等临时错误返回 NO，保持登录态等下次重试。
+ (BOOL)isTokenDefinitelyInvalidError:(NSError *)error {
    if (![error isKindOfClass:APIError.class]) {
        // 非 APIError 视为网络层错误，保守起见不登出
        return NO;
    }
    APIError *apiError = (APIError *)error;
    // 网络类临时错误（断网/超时/取消）：不是 token 失效
    if ([apiError isNetworkError]) {
        return NO;
    }
    // 服务端 5xx：token 状态未知，不登出（等恢复后重试）
    if ([apiError isServerError]) {
        return NO;
    }
    // 明确的 401/认证错误，或服务端返回了业务错误码（如 token 无效/过期）：确定失效
    return [apiError isAuthenticationError] || apiError.businessCode.length > 0;
}

- (instancetype)init {
    return [self initWithErrorHandler:nil];
}

- (instancetype)initWithErrorHandler:(nullable void(^)(NSError *error))errorHandler {
    self = [super init];
    if (self) {
        _errorHandler = errorHandler;
        _callbacks = [NSMutableArray array];
    }
    return self;
}

- (nullable NSError *)interceptError:(NSError *)error task:(NSURLSessionDataTask *)task tokenRefreshed:(nonnull void (^)(BOOL))tokenRefreshed{
    NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)task.response;
    if (httpResp.statusCode == 401 && AuthManager.sharedManager.isLoggedIn && ![task.currentRequest.URL.path containsString:APIPathValueRefreshToken]) {
        @synchronized (self) {
            [self.callbacks addObject:tokenRefreshed];
        }
        if (!self.refreshingToken) {
            self.refreshingToken = YES;
            NSLog(@"✅ [API Request] token过期，开始刷新token");
            [AuthManager.sharedManager refreshTokenSuccess:^(HTTPResponse * _Nonnull response) {
                if (response.success) {
                    NSLog(@"✅ [API Request] token刷新成功，开始重启%ld个请求",self.callbacks.count);
                    [self _callback:YES];
                } else {
                    NSLog(@"✅ [API Request] token刷新失败（业务错误），退出重新登录");
                    [self _callback:NO];
                    [APIManager.sharedManager clearAuthorizationHeader];
                    [NSNotificationCenter.defaultCenter postNotificationName:TokenExpiredNotification object:nil];
                }
                self.refreshingToken = NO;
            } failure:^(NSError * _Nonnull error) {
                // 只有服务端明确判定 token 失效才登出。
                // 网络超时/断网/请求取消等临时错误一律保持登录态，
                // 否则弱网下刷新失败会把用户强制登出（表现为「隔几小时自动登出」）。
                BOOL tokenReallyInvalid = [APIErrorHandlingInterceptor isTokenDefinitelyInvalidError:error];
                self.refreshingToken = NO;
                if (!tokenReallyInvalid) {
                    NSLog(@"⚠️ [API Request] token刷新遇到网络错误，保持登录态，等待下次请求重试");
                    [self _callback:NO];
                    return;
                }
                NSLog(@"✅ [API Request] token刷新失败，退出重新登录");
                [self _callback:NO];
                [APIManager.sharedManager clearAuthorizationHeader];
                [NSNotificationCenter.defaultCenter postNotificationName:TokenExpiredNotification object:nil];
                // 调用错误处理回调
                if (self.errorHandler) {
                    self.errorHandler(error);
                }
            }];
        } else {
            NSLog(@"✅ [API Request] token重复刷新，等待刷新完成");
        }
        return nil;
    } else
    {
        // 若上游已构造好业务错误，直接透传，避免丢失 businessCode / businessMessage。
        APIError *apiError = [error isKindOfClass:APIError.class] ? (APIError *)error : [APIError errorFromNSError:error];
        
        // 调用错误处理回调
        if (self.errorHandler) {
            self.errorHandler(apiError);
        }
        if (apiError.businessMessage.length > 0) {
            NSLog(@"❌ [API Business Error] code=%@ message=%@", apiError.businessCode ?: @"", apiError.businessMessage);
        }

        if ([apiError.businessCode isEqualToString:PNAppVersionOutdatedErrorCode]) {
            [[PNAppVersionManager shared] handleAPIErrorIfNeeded:apiError];
            return nil;
        }
        
        // 根据错误处理策略决定是否继续传播错误
        if (apiError.handlingStrategy == APIErrorHandlingStrategySilent) {
            return nil; // 静默处理，不传播错误
        }
        
        return apiError;
    }
}
- (void)_callback:(BOOL)success {
    NSArray<void (^)(BOOL)> *pendingCallbacks = nil;
    @synchronized (self) {
        pendingCallbacks = [self.callbacks copy];
        [self.callbacks removeAllObjects];
    }
    [pendingCallbacks enumerateObjectsUsingBlock:^(void (^callback)(BOOL), NSUInteger idx, BOOL * _Nonnull stop) {
        callback(success);
    }];
}
@end
