//
//  APIManager.h
//  footBall
//
//  Created on 2026/1/15.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import "APIRequestInterceptor.h"
#import "APIError.h"

NS_ASSUME_NONNULL_BEGIN

/// 网络请求方法类型
typedef NS_ENUM(NSInteger, HTTPMethod) {
    HTTPMethodGET = 0,
    HTTPMethodPOST,
    HTTPMethodPUT,
    HTTPMethodDELETE,
    HTTPMethodPATCH
};

/// 网络请求成功回调
typedef void(^APISuccessBlock)(id _Nullable responseObject);
/// 网络请求失败回调
typedef void(^APIFailureBlock)(NSError *error);
/// 网络请求进度回调
typedef void(^APIProgressBlock)(NSProgress *progress);

/// API管理器 - 封装AFNetworking
@interface APIManager : NSObject

/// 单例
+ (instancetype)sharedManager;

/// 基础URL（已废弃，使用APIEnvironmentManager管理）
@property (nonatomic, strong) NSString *baseURL DEPRECATED_MSG_ATTRIBUTE("使用 APIEnvironmentManager 管理环境配置");

/// 请求超时时间（默认30秒）
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

/// 最大重试次数（默认：3次，0表示不重试）
@property (nonatomic, assign) NSInteger maxRetryCount;

/// 重试间隔（默认：2秒）
@property (nonatomic, assign) NSTimeInterval retryInterval;

/// 公共请求头
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *commonHeaders;

/// 请求拦截器数组（按顺序执行）
@property (nonatomic, strong) NSArray<id<APIRequestInterceptor>> *interceptors;

/// 统一错误处理回调
@property (nonatomic, copy, nullable) void(^errorHandler)(APIError *error);

/// 添加拦截器
/// @param interceptor 拦截器
- (void)addInterceptor:(id<APIRequestInterceptor>)interceptor;

/// 移除拦截器
/// @param interceptor 拦截器
- (void)removeInterceptor:(id<APIRequestInterceptor>)interceptor;

/// 设置请求序列化器
- (void)setRequestSerializer:(AFHTTPRequestSerializer *)serializer;

/// 设置响应序列化器
- (void)setResponseSerializer:(AFJSONResponseSerializer *)serializer;

/// 通用请求方法
/// @param method 请求方法
/// @param URLString 请求路径（相对或绝对）
/// @param parameters 请求参数
/// @param headers 请求头（会与公共请求头合并）
/// @param success 成功回调
/// @param failure 失败回调
- (NSURLSessionDataTask *)requestWithMethod:(HTTPMethod)method
                                   URLString:(NSString *)URLString
                                  parameters:(nullable id)parameters
                                     headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                                     success:(nullable APISuccessBlock)success
                                     failure:(nullable APIFailureBlock)failure;

/// GET请求
- (NSURLSessionDataTask *)GET:(NSString *)URLString
                    parameters:(nullable id)parameters
                       headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                       success:(nullable APISuccessBlock)success
                       failure:(nullable APIFailureBlock)failure;

/// POST请求
- (NSURLSessionDataTask *)POST:(NSString *)URLString
                     parameters:(nullable id)parameters
                        headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                        success:(nullable APISuccessBlock)success
                        failure:(nullable APIFailureBlock)failure;

/// PUT请求
- (NSURLSessionDataTask *)PUT:(NSString *)URLString
                    parameters:(nullable id)parameters
                       headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                       success:(nullable APISuccessBlock)success
                       failure:(nullable APIFailureBlock)failure;

/// DELETE请求
- (NSURLSessionDataTask *)DELETE:(NSString *)URLString
                       parameters:(nullable id)parameters
                          headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                          success:(nullable APISuccessBlock)success
                          failure:(nullable APIFailureBlock)failure;

/// 使用路径名称发起GET请求（推荐使用）
/// @param pathName 路径名称（如：@"user"）
/// @param subPath 子路径（可选，如：@"/profile"）
/// @param parameters 请求参数
/// @param headers 请求头
/// @param success 成功回调
/// @param failure 失败回调
- (NSURLSessionDataTask *)GETWithPathName:(NSString *)pathName
                                   subPath:(nullable NSString *)subPath
                                parameters:(nullable id)parameters
                                   headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                                   success:(nullable APISuccessBlock)success
                                   failure:(nullable APIFailureBlock)failure;

/// 使用路径名称发起POST请求（推荐使用）
/// @param pathName 路径名称（如：@"user"）
/// @param subPath 子路径（可选，如：@"/login"）
/// @param parameters 请求参数
/// @param headers 请求头
/// @param success 成功回调
/// @param failure 失败回调
- (NSURLSessionDataTask *)POSTWithPathName:(NSString *)pathName
                                    subPath:(nullable NSString *)subPath
                                 parameters:(nullable id)parameters
                                    headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                                    success:(nullable APISuccessBlock)success
                                    failure:(nullable APIFailureBlock)failure;

/// 上传文件
/// @param URLString 请求路径
/// @param parameters 请求参数
/// @param fileData 文件数据
/// @param name 文件字段名
/// @param fileName 文件名
/// @param mimeType MIME类型
/// @param headers 请求头
/// @param progress 进度回调
/// @param success 成功回调
/// @param failure 失败回调
- (NSURLSessionDataTask *)uploadFile:(NSString *)URLString
                           parameters:(nullable id)parameters
                             fileData:(NSData *)fileData
                                 name:(NSString *)name
                             fileName:(NSString *)fileName
                             mimeType:(NSString *)mimeType
                              headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                             progress:(nullable APIProgressBlock)progress
                              success:(nullable APISuccessBlock)success
                              failure:(nullable APIFailureBlock)failure;

/// 下载文件
/// @param URLString 下载路径
/// @param parameters 请求参数
/// @param headers 请求头
/// @param destinationPath 保存路径
/// @param progress 进度回调
/// @param success 成功回调
/// @param failure 失败回调
- (NSURLSessionDownloadTask *)downloadFile:(NSString *)URLString
                                 parameters:(nullable id)parameters
                                    headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                            destinationPath:(NSString *)destinationPath
                                   progress:(nullable APIProgressBlock)progress
                                    success:(nullable void(^)(NSURL *filePath))success
                                    failure:(nullable APIFailureBlock)failure;

/// 取消所有请求
- (void)cancelAllRequests;

/// 取消指定请求
- (void)cancelTask:(NSURLSessionTask *)task;

@end

NS_ASSUME_NONNULL_END
