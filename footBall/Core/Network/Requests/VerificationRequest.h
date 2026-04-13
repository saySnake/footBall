//
//  VerificationRequest.h
//  footBall
//

#import <Foundation/Foundation.h>
#import "HTTPResponse.h"

NS_ASSUME_NONNULL_BEGIN

@class PNVerificationStatus;
@class PNRealnameInfo;
@class PNVerificationHistory;

/// 身份认证相关接口（/api/v1/verification/*）
@interface VerificationRequest : NSObject

+ (instancetype)shared;

/// 最近一次 `GET /api/v1/verification/status` 解析结果（供身份认证页展示）
@property (nonatomic, strong, nullable) PNVerificationStatus *cachedVerificationStatus;
/// 最近一次 `GET /api/v1/verification/realname/info` 解析结果
@property (nonatomic, strong, nullable) PNRealnameInfo *cachedRealnameInfo;
/// 最近一次 `GET /api/v1/verification/history` 解析结果（按后端返回顺序）
@property (nonatomic, strong) NSArray<PNVerificationHistory *> *cachedHistory;
/// 最近一次从服务端解析到的实名认证正反面图片地址
@property (nonatomic, copy, nullable) NSString *cachedRealnameFrontUrl;
@property (nonatomic, copy, nullable) NSString *cachedRealnameBackUrl;
/// 最近一次从服务端解析到的职业认证材料地址列表
@property (nonatomic, strong) NSArray<NSString *> *cachedProfessionalImageUrls;

/// GET /api/v1/verification/status
- (void)fetchStatusSuccess:(nullable APISuccessBlock)success failure:(nullable APIFailureBlock)failure;

/// POST /api/v1/verification/realname（身份证正反面 OSS URL）
- (void)submitRealnameWithFrontUrl:(NSString *)frontUrl backUrl:(NSString *)backUrl
                           success:(nullable APISuccessBlock)success failure:(nullable APIFailureBlock)failure;

/// POST /api/v1/verification/professional（职业证明材料 OSS URL 列表）
- (void)submitProfessionalWithImageUrls:(NSArray<NSString *> *)urls
                                success:(nullable APISuccessBlock)success failure:(nullable APIFailureBlock)failure;

/// GET /api/v1/verification/realname/info
- (void)fetchRealnameInfoSuccess:(nullable APISuccessBlock)success failure:(nullable APIFailureBlock)failure;

/// GET /api/v1/verification/history
- (void)fetchHistorySuccess:(nullable APISuccessBlock)success failure:(nullable APIFailureBlock)failure;

/// 将 status 接口返回的 data 解析后同步到 AuthStateStore（字段名因后端而异，见 .m 内解析逻辑）
+ (void)applyVerificationStatusData:(nullable id)data;

@end

NS_ASSUME_NONNULL_END
