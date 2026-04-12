//
//  APICurlLogInterceptor.h
//  footBall
//
//  curl 日志拦截器 - 每次网络请求自动打印等效 curl 命令
//  支持运行时开关，方便调试
//

#import <Foundation/Foundation.h>
#import "APIRequestInterceptor.h"

NS_ASSUME_NONNULL_BEGIN

@interface APICurlLogInterceptor : NSObject <APIRequestInterceptor>

/// 是否启用 curl 日志（默认 DEBUG 下开启）
@property (nonatomic, assign) BOOL enabled;

/// 是否打印响应体摘要（默认 NO，开启后会在响应拦截中追加打印前 500 字符）
@property (nonatomic, assign) BOOL logResponseBody;

+ (instancetype)shared;

@end

NS_ASSUME_NONNULL_END
