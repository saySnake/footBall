//
//  APIAppMetadataInterceptor.h
//  footBall
//

#import <Foundation/Foundation.h>
#import "APIRequestInterceptor.h"

NS_ASSUME_NONNULL_BEGIN

/// 为所有请求附加客户端平台、版本号、build（供服务端强制更新校验）
@interface APIAppMetadataInterceptor : NSObject <APIRequestInterceptor>

@end

NS_ASSUME_NONNULL_END
