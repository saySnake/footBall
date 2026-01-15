//
//  APIRequestInterceptor.m
//  footBall
//
//  Created on 2026/1/15.
//

#import "APIRequestInterceptor.h"
#import "APIError.h"

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

- (nullable NSURLRequest *)interceptRequest:(NSURLRequest *)request {
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
    return [self initWithLogLevel:1];
}

- (instancetype)initWithLogLevel:(NSInteger)logLevel {
    self = [super init];
    if (self) {
        _enabled = YES;
        _logLevel = logLevel;
    }
    return self;
}

- (nullable NSURLRequest *)interceptRequest:(NSURLRequest *)request {
    if (!self.enabled || self.logLevel < 1) {
        return request;
    }
    
    NSLog(@"🌐 [API Request] %@ %@", request.HTTPMethod, request.URL.absoluteString);
    
    if (self.logLevel >= 2 && request.HTTPBody) {
        NSString *bodyString = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
        NSLog(@"📤 [Request Body] %@", bodyString);
    }
    
    if (self.logLevel >= 2 && request.allHTTPHeaderFields.count > 0) {
        NSLog(@"📋 [Request Headers] %@", request.allHTTPHeaderFields);
    }
    
    return request;
}

- (BOOL)interceptResponse:(NSURLResponse *)response
                     data:(nullable NSData *)data
                    error:(nullable NSError *)error {
    if (!self.enabled || self.logLevel < 1) {
        return YES;
    }
    
    if (error) {
        NSLog(@"❌ [API Error] %@", error.localizedDescription);
    } else {
        NSLog(@"✅ [API Response] %@", ((NSHTTPURLResponse *)response).statusCode);
        
        if (self.logLevel >= 2 && data) {
            NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"📥 [Response Body] %@", responseString);
        }
    }
    
    return YES;
}

@end

@implementation APIErrorHandlingInterceptor

- (instancetype)init {
    return [self initWithErrorHandler:nil];
}

- (instancetype)initWithErrorHandler:(nullable void(^)(NSError *error))errorHandler {
    self = [super init];
    if (self) {
        _errorHandler = errorHandler;
    }
    return self;
}

- (nullable NSError *)interceptError:(NSError *)error {
    // 转换为APIError
    APIError *apiError = [APIError errorFromNSError:error];
    
    // 调用错误处理回调
    if (self.errorHandler) {
        self.errorHandler(apiError);
    }
    
    // 根据错误处理策略决定是否继续传播错误
    if (apiError.handlingStrategy == APIErrorHandlingStrategySilent) {
        return nil; // 静默处理，不传播错误
    }
    
    return apiError;
}

@end
