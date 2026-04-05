//
//  VerificationRequest.h
//  footBall
//

#import <Foundation/Foundation.h>
#import "HTTPResponse.h"

NS_ASSUME_NONNULL_BEGIN

/// 身份认证相关接口（/api/v1/verification/*）
@interface VerificationRequest : NSObject

+ (instancetype)shared;

/// GET /api/v1/verification/status
- (void)fetchStatusSuccess:(nullable APISuccessBlock)success failure:(nullable APIFailureBlock)failure;

/// POST /api/v1/verification/realname（身份证正反面 OSS URL）
- (void)submitRealnameWithFrontUrl:(NSString *)frontUrl backUrl:(NSString *)backUrl
                           success:(nullable APISuccessBlock)success failure:(nullable APIFailureBlock)failure;

/// POST /api/v1/verification/professional（职业证明材料 OSS URL 列表）
- (void)submitProfessionalWithImageUrls:(NSArray<NSString *> *)urls
                                success:(nullable APISuccessBlock)success failure:(nullable APIFailureBlock)failure;

/// 将 status 接口返回的 data 解析后同步到 AuthStateStore（字段名因后端而异，见 .m 内解析逻辑）
+ (void)applyVerificationStatusData:(nullable id)data;

@end

NS_ASSUME_NONNULL_END
