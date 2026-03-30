//
//  APIManager.m
//  footBall
//
//  Created on 2026/1/15.
//

#import "APIManager.h"
#import "APIEnvironmentManager.h"
#import "APIRequestInterceptor.h"
#import "APIError.h"
#import <YYModel/YYModel.h>
NSString * const TokenExpiredNotification = @"TokenExpiredNotification";
@interface APIManager ()

@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;
@property (nonatomic, strong) NSMutableArray<NSURLSessionTask *> *tasks;
@property (nonatomic, strong) NSMutableArray<id<APIRequestInterceptor>> *mutableInterceptors;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *retryCountMap; // 请求重试次数映射

@end

@implementation APIManager

+ (instancetype)sharedManager {
    static APIManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[APIManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // baseURL 已废弃，统一使用 APIEnvironmentManager 管理环境配置
        _baseURL = @"";
        _timeoutInterval = 15.0;
        _maxRetryCount = 0; // 默认最大重试3次
        _retryInterval = 2.0; // 默认重试间隔2秒
        _commonHeaders = @{};
        _tasks = [NSMutableArray array];
        _mutableInterceptors = [NSMutableArray array];
        _retryCountMap = [NSMutableDictionary dictionary];
        
        // 初始化AFHTTPSessionManager
        _sessionManager = [[AFHTTPSessionManager alloc] init];
        _sessionManager.securityPolicy.allowInvalidCertificates = YES;
        _sessionManager.securityPolicy.validatesDomainName = NO;
        _sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
        AFJSONResponseSerializer *responseSerializer = [AFJSONResponseSerializer serializer];
        responseSerializer.removesKeysWithNullValues = YES;
        _sessionManager.responseSerializer = responseSerializer;
        _sessionManager.requestSerializer.timeoutInterval = _timeoutInterval;
        
        // 设置可接受的响应类型
        _sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:
                                                                     @"application/json",
                                                                     @"text/json",
                                                                     @"text/javascript",
                                                                     @"text/html",
                                                                     @"text/plain",
                                                                     nil];
    }
    return self;
}

- (NSArray<id<APIRequestInterceptor>> *)interceptors {
    return [self.mutableInterceptors copy];
}

- (void)addInterceptor:(id<APIRequestInterceptor>)interceptor {
    if (interceptor && ![self.mutableInterceptors containsObject:interceptor]) {
        [self.mutableInterceptors addObject:interceptor];
    }
}

- (void)removeInterceptor:(id<APIRequestInterceptor>)interceptor {
    [self.mutableInterceptors removeObject:interceptor];
}

- (void)setRequestSerializer:(AFHTTPRequestSerializer *)serializer {
    self.sessionManager.requestSerializer = serializer;
}

- (void)setResponseSerializer:(AFJSONResponseSerializer *)serializer {
    self.sessionManager.responseSerializer = serializer;
}
- (void)clearAuthorizationHeader {
    [self.sessionManager.requestSerializer clearAuthorizationHeader];
}
- (NSURLSessionDataTask *)requestWithMethod:(HTTPMethod)method
                                   URLString:(NSString *)URLString
                                  parameters:(nullable id)parameters
                                     headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                                     success:(nullable void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
                                    failure:(nullable void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure {
    
    // 构建完整URL
    NSString *fullURL = URLString;
    // 统一使用 APIEnvironmentManager 管理环境配置（baseURL 已废弃）
    if (![URLString hasPrefix:@"http"]) {
        // 使用环境管理器的Base URL
        NSString *baseURL = [APIEnvironmentManager sharedManager].currentBaseURL;
        if (baseURL.length > 0) {
            // 确保baseURL不以/结尾，URLString以/开头
            if ([baseURL hasSuffix:@"/"]) {
                baseURL = [baseURL substringToIndex:baseURL.length - 1];
            }
            if (![URLString hasPrefix:@"/"]) {
                URLString = [NSString stringWithFormat:@"/%@", URLString];
            }
            fullURL = [NSString stringWithFormat:@"%@%@", baseURL, URLString];
        }
    }
    
    // 创建请求对象
    NSMutableURLRequest *request = [self.sessionManager.requestSerializer requestWithMethod:[self HTTPMethodString:method]
                                                                                   URLString:fullURL
                                                                                  parameters:parameters
                                                                                       error:nil];
    
    // 合并请求头
    NSMutableDictionary *allHeaders = [NSMutableDictionary dictionaryWithDictionary:self.commonHeaders];
    if (headers) {
        [allHeaders addEntriesFromDictionary:headers];
    }
    
    // 设置请求头
    for (NSString *key in allHeaders.allKeys) {
        [request setValue:allHeaders[key] forHTTPHeaderField:key];
    }
    
    // 执行请求拦截器
    NSURLRequest *interceptedRequest = request;
    for (id<APIRequestInterceptor> interceptor in self.interceptors) {
        if ([interceptor respondsToSelector:@selector(interceptRequest:)]) {
            interceptedRequest = [interceptor interceptRequest:interceptedRequest];
            if (!interceptedRequest) {
                // 请求被取消
                if (failure) {
                    APIError *error = [APIError errorWithCode:APIErrorCodeCancelled
                                                       message:@"请求被拦截器取消"
                                               underlyingError:nil];
                    failure(nil,error);
                }
                return nil;
            }
        }
    }
    
    // 设置请求头到sessionManager（用于AFNetworking）
    for (NSString *key in interceptedRequest.allHTTPHeaderFields.allKeys) {
        [self.sessionManager.requestSerializer setValue:interceptedRequest.allHTTPHeaderFields[key] 
                                     forHTTPHeaderField:key];
    }
    // 包装成功和失败回调，执行响应拦截器
    __weak typeof(self) weakSelf = self;
     void (^wrappedSuccess)(id,id) = ^(NSURLSessionDataTask * task,id responseObject) {
        // 执行响应拦截器
        BOOL shouldContinue = YES;
        for (id<APIRequestInterceptor> interceptor in weakSelf.interceptors) {
            if ([interceptor respondsToSelector:@selector(interceptResponse:task:)]) {
                shouldContinue = [interceptor interceptResponse:responseObject task:task];
                if (!shouldContinue) {
                    break;
                }
            }
        }
        if (shouldContinue && success) {
            success(task,responseObject);
        }
    };
    
    // 生成请求唯一标识（用于跟踪重试次数）
    NSString *requestKey = [NSString stringWithFormat:@"%@_%ld_%p", fullURL, (long)method, parameters];
    __block void (^wrappedFailure)(id,id) = nil;
    __weak typeof(wrappedFailure) weakWrappedFailure = wrappedFailure;
    wrappedFailure = ^(NSURLSessionDataTask * task,NSError *error) {

        // 转换为APIError
        APIError *apiError = [APIError errorFromNSError:error];
        apiError.requestPath = fullURL;
        apiError.maxRetryCount = weakSelf.maxRetryCount;
        apiError.retryInterval = weakSelf.retryInterval;
        
        // 获取当前重试次数
        NSNumber *currentRetryCount = weakSelf.retryCountMap[requestKey];
        apiError.retryCount = currentRetryCount ? [currentRetryCount integerValue] : 0;
        
        // 执行错误拦截器
        NSError *finalError = apiError;
        for (id<APIRequestInterceptor> interceptor in weakSelf.interceptors) {
            if ([interceptor respondsToSelector:@selector(interceptError:task:tokenRefreshed:)]) {
                NSError *interceptedError = [interceptor interceptError:finalError task:task tokenRefreshed:^(BOOL succ){
                    // 重新发起请求
                    if (succ == false) {
                        if (failure) {
                            failure(task,finalError);
                        }
                    } else {
                        NSLog(@"✅ [API Request] token刷新成功，即将重新发起请求");
                        [weakSelf requestWithMethod:method
                                          URLString:URLString
                                         parameters:parameters
                                            headers:headers
                                            success:^(NSURLSessionDataTask * task,id responseObject) {
                            // 重试成功，清理重试计数
                            [weakSelf.retryCountMap removeObjectForKey:requestKey];
                            if (success) {
                                success(task,responseObject);
                            }
                        } failure:weakWrappedFailure]; // 使用相同的wrappedFailure，继续重试逻辑
                    }
                }];
                if (!interceptedError) {
                    // 错误已被处理，不继续传播
                    [weakSelf.retryCountMap removeObjectForKey:requestKey]; // 清理重试计数
                    return;
                }
                finalError = interceptedError;
            } else if ([interceptor respondsToSelector:@selector(interceptError:task:)]) {
                NSError *interceptedError = [interceptor interceptError:finalError task:task];
                if (!interceptedError) {
                    // 错误已被处理，不继续传播
                    [weakSelf.retryCountMap removeObjectForKey:requestKey]; // 清理重试计数
                    return;
                }
                finalError = interceptedError;
            }
        }
        
        // 检查是否需要重试
        APIError *finalAPIError = (APIError *)finalError;
        if (finalAPIError.canRetry && 
            weakSelf.maxRetryCount > 0 &&
            finalAPIError.retryCount < weakSelf.maxRetryCount) {
            // 增加重试次数
            finalAPIError.retryCount = finalAPIError.retryCount + 1;
            weakSelf.retryCountMap[requestKey] = @(finalAPIError.retryCount);
            
            NSLog(@"🔄 准备第 %ld 次重试（最大 %ld 次），间隔 %.1f 秒", 
                  (long)finalAPIError.retryCount, 
                  (long)weakSelf.maxRetryCount, 
                  finalAPIError.retryInterval);
            
            // 延迟重试
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(finalAPIError.retryInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                // 重新发起请求
                [weakSelf requestWithMethod:method
                                  URLString:URLString
                                 parameters:parameters
                                    headers:headers
                                    success:^(NSURLSessionDataTask * task,id responseObject) {
                    // 重试成功，清理重试计数
                    [weakSelf.retryCountMap removeObjectForKey:requestKey];
                    if (success) {
                        success(task,responseObject);
                    }
                } failure:weakWrappedFailure]; // 使用相同的wrappedFailure，继续重试逻辑
            });
            return; // 重试中，不调用失败回调
        }
        
        // 清理重试计数
        [weakSelf.retryCountMap removeObjectForKey:requestKey];
        
        // 统一错误处理回调
        if (weakSelf.errorHandler) {
            weakSelf.errorHandler(finalAPIError);
        }
        
        if (failure) {
            failure(task,finalError);
        }
    };
    
    // 根据方法类型发起请求
    NSURLSessionDataTask *task = nil;
    
    switch (method) {
        case HTTPMethodGET: {
            task = [self.sessionManager GET:fullURL
                                  parameters:parameters
                                     headers:nil
                                    progress:nil
                                     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [weakSelf.tasks removeObject:task];
                wrappedSuccess(task,responseObject);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [weakSelf.tasks removeObject:task];
                wrappedFailure(task,error);
            }];
            break;
        }
            
        case HTTPMethodPOST: {
            task = [self.sessionManager POST:fullURL
                                   parameters:parameters
                                      headers:nil
                                     progress:nil
                                      success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [weakSelf.tasks removeObject:task];
                wrappedSuccess(task,responseObject);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [weakSelf.tasks removeObject:task];
                wrappedFailure(task,error);
            }];
            break;
        }
            
        case HTTPMethodPUT: {
            task = [self.sessionManager PUT:fullURL
                                 parameters:parameters
                                    headers:nil
                                    success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [weakSelf.tasks removeObject:task];
                wrappedSuccess(task,responseObject);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [weakSelf.tasks removeObject:task];
                wrappedFailure(task,error);
            }];
            break;
        }
            
        case HTTPMethodDELETE: {
            task = [self.sessionManager DELETE:fullURL
                                    parameters:parameters
                                       headers:nil
                                       success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [weakSelf.tasks removeObject:task];
                wrappedSuccess(task,responseObject);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [weakSelf.tasks removeObject:task];
                wrappedFailure(task,error);
            }];
            break;
        }
            
        case HTTPMethodPATCH: {
            task = [self.sessionManager PATCH:fullURL
                                   parameters:parameters
                                      headers:nil
                                      success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [weakSelf.tasks removeObject:task];
                wrappedSuccess(task,responseObject);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [weakSelf.tasks removeObject:task];
                wrappedFailure(task,error);
            }];
            break;
        }
    }
    
    if (task) {
        [self.tasks addObject:task];
    }
    
    return task;
}
- (nullable void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))successBlock:(APISuccessBlock)block {
    void (^taskBlock)(NSURLSessionDataTask *,id) = ^(NSURLSessionDataTask * task,id response) {
        if (block) {
            HTTPResponse *resp = [HTTPResponse yy_modelWithJSON:response];
            block(resp);
        }
    };
    return taskBlock;
}
- (nullable void (^)(NSURLSessionDataTask * _Nonnull, NSError * _Nullable))errorBlock:(APIFailureBlock)block {
    void (^taskBlock)(NSURLSessionDataTask *,NSError *) = ^(NSURLSessionDataTask * task,NSError *error) {
        if (block) {
            block(error);
        }
    };
    return taskBlock;
}

- (NSURLSessionDataTask *)GET:(NSString *)URLString
                    parameters:(nullable id)parameters
                       headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                       success:(nullable APISuccessBlock)success
                       failure:(nullable APIFailureBlock)failure {
    return [self requestWithMethod:HTTPMethodGET
                          URLString:URLString
                         parameters:parameters
                            headers:headers
                           success:[self successBlock:success]
                            failure:[self errorBlock:failure]];
}

- (NSURLSessionDataTask *)POST:(NSString *)URLString
                     parameters:(nullable id)parameters
                        headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                        success:(nullable APISuccessBlock)success
                        failure:(nullable APIFailureBlock)failure {
    return [self requestWithMethod:HTTPMethodPOST
                          URLString:URLString
                         parameters:parameters
                            headers:headers
                            success:[self successBlock:success]
                            failure:[self errorBlock:failure]];
}

- (NSURLSessionDataTask *)PUT:(NSString *)URLString
                    parameters:(nullable id)parameters
                       headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                       success:(nullable APISuccessBlock)success
                       failure:(nullable APIFailureBlock)failure {
    return [self requestWithMethod:HTTPMethodPUT
                          URLString:URLString
                         parameters:parameters
                            headers:headers
                            success:[self successBlock:success]
                            failure:[self errorBlock:failure]];
}

- (NSURLSessionDataTask *)DELETE:(NSString *)URLString
                       parameters:(nullable id)parameters
                          headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                          success:(nullable APISuccessBlock)success
                          failure:(nullable APIFailureBlock)failure {
    return [self requestWithMethod:HTTPMethodDELETE
                          URLString:URLString
                         parameters:parameters
                            headers:headers
                            success:[self successBlock:success]
                            failure:[self errorBlock:failure]];
}

- (NSURLSessionDataTask *)uploadFile:(NSString *)URLString
                           parameters:(nullable id)parameters
                             fileData:(NSData *)fileData
                                 name:(NSString *)name
                             fileName:(NSString *)fileName
                             mimeType:(NSString *)mimeType
                              headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                             progress:(nullable APIProgressBlock)progress
                              success:(nullable APISuccessBlock)success
                              failure:(nullable APIFailureBlock)failure {
    
    // 统一使用 APIEnvironmentManager 管理环境配置（baseURL 已废弃）
    NSString *fullURL = URLString;
    if (![URLString hasPrefix:@"http"]) {
        NSString *baseURL = [APIEnvironmentManager sharedManager].currentBaseURL;
        if (baseURL.length > 0) {
            // 确保baseURL不以/结尾，URLString以/开头
            if ([baseURL hasSuffix:@"/"]) {
                baseURL = [baseURL substringToIndex:baseURL.length - 1];
            }
            if (![URLString hasPrefix:@"/"]) {
                URLString = [NSString stringWithFormat:@"/%@", URLString];
            }
            fullURL = [NSString stringWithFormat:@"%@%@", baseURL, URLString];
        }
    }
    
    // 合并请求头
    NSMutableDictionary *allHeaders = [NSMutableDictionary dictionaryWithDictionary:self.commonHeaders];
    if (headers) {
        [allHeaders addEntriesFromDictionary:headers];
    }
    
    for (NSString *key in allHeaders.allKeys) {
        [self.sessionManager.requestSerializer setValue:allHeaders[key] forHTTPHeaderField:key];
    }
    
    NSURLSessionDataTask *task = [self.sessionManager POST:fullURL
                                                 parameters:parameters
                                                    headers:nil
                                  constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        [formData appendPartWithFileData:fileData
                                    name:name
                                fileName:fileName
                                mimeType:mimeType];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        if (progress) {
            progress(uploadProgress);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self.tasks removeObject:task];
        if (success) {
            success(responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.tasks removeObject:task];
        if (failure) {
            failure(error);
        }
    }];
    
    if (task) {
        [self.tasks addObject:task];
    }
    
    return task;
}

- (NSURLSessionDownloadTask *)downloadFile:(NSString *)URLString
                                 parameters:(nullable id)parameters
                                    headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                            destinationPath:(NSString *)destinationPath
                                   progress:(nullable APIProgressBlock)progress
                                    success:(nullable void(^)(NSURL *filePath))success
                                    failure:(nullable APIFailureBlock)failure {
    
    // 统一使用 APIEnvironmentManager 管理环境配置（baseURL 已废弃）
    NSString *fullURL = URLString;
    if (![URLString hasPrefix:@"http"]) {
        NSString *baseURL = [APIEnvironmentManager sharedManager].currentBaseURL;
        if (baseURL.length > 0) {
            // 确保baseURL不以/结尾，URLString以/开头
            if ([baseURL hasSuffix:@"/"]) {
                baseURL = [baseURL substringToIndex:baseURL.length - 1];
            }
            if (![URLString hasPrefix:@"/"]) {
                URLString = [NSString stringWithFormat:@"/%@", URLString];
            }
            fullURL = [NSString stringWithFormat:@"%@%@", baseURL, URLString];
        }
    }
    
    NSURLRequest *request = [self.sessionManager.requestSerializer requestWithMethod:@"GET"
                                                                             URLString:fullURL
                                                                            parameters:parameters
                                                                                 error:nil];
    
    NSURLSessionDownloadTask *task = [self.sessionManager downloadTaskWithRequest:request
                                                                          progress:^(NSProgress * _Nonnull downloadProgress) {
        if (progress) {
            progress(downloadProgress);
        }
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return [NSURL fileURLWithPath:destinationPath];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        if (error) {
            if (failure) {
                failure(error);
            }
        } else {
            if (success) {
                success(filePath);
            }
        }
    }];
    
    [task resume];
    return task;
}

- (void)cancelAllRequests {
    for (NSURLSessionTask *task in self.tasks) {
        [task cancel];
    }
    [self.tasks removeAllObjects];
}

- (void)cancelTask:(NSURLSessionTask *)task {
    [task cancel];
    [self.tasks removeObject:task];
}

- (NSString *)HTTPMethodString:(HTTPMethod)method {
    switch (method) {
        case HTTPMethodGET:
            return @"GET";
        case HTTPMethodPOST:
            return @"POST";
        case HTTPMethodPUT:
            return @"PUT";
        case HTTPMethodDELETE:
            return @"DELETE";
        case HTTPMethodPATCH:
            return @"PATCH";
    }
}

@end
