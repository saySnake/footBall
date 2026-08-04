//
//  MembershipRequest.h
//  footBall
//
//  会员：方案、状态、权益、订阅记录、兑换（/api/v1/membership/*）。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MembershipRequest : NSObject

+ (instancetype)shared;

/// GET `/api/v1/membership/plans` — 会员方案列表
- (void)getMembershipPlansSuccess:(nullable APISuccessBlock)success
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

/// POST `/api/v1/membership/redeem` — 礼包码/兑换码/邀请码兑换；body 包含 code 字段
/// 成功 data 为 RedeemResultVO（含 needPayment、appleProductId、activateTime、expireTime 等）
- (void)redeemCodeWithBody:(NSDictionary *)body
                   success:(nullable APISuccessBlock)success
                   failure:(nullable APIFailureBlock)failure;

@end

NS_ASSUME_NONNULL_END
