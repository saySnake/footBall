//
//  MembershipRequest.h
//  footBall
//
//  会员：方案、购买验证、状态、权益、订阅记录（/api/v1/membership/*）。
//  说明：Apple S2S 回调为服务端接口，路径为 APIPathValueMembershipAppleCallback，客户端不应调用。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MembershipRequest : NSObject

+ (instancetype)shared;

/// GET `/api/v1/membership/plans` — 会员方案列表
- (void)getMembershipPlansSuccess:(nullable APISuccessBlock)success
                          failure:(nullable APIFailureBlock)failure;

/// POST `/api/v1/membership/purchase` — IAP 收据验证等；body 字段以后端为准（如 receipt、productId）
- (void)verifyPurchaseWithBody:(NSDictionary *)body
                       success:(nullable APISuccessBlock)success
                       failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/membership/status` — 当前用户会员状态
- (void)getMembershipStatusSuccess:(nullable APISuccessBlock)success
                             failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/membership/benefits` — 会员权益列表
- (void)getMembershipBenefitsSuccess:(nullable APISuccessBlock)success
                             failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/membership/records` — 订阅/购买记录分页
- (void)getMembershipRecordsWithPage:(NSInteger)page
                             pageSize:(NSInteger)pageSize
                              success:(nullable APISuccessBlock)success
                              failure:(nullable APIFailureBlock)failure;

@end

NS_ASSUME_NONNULL_END
