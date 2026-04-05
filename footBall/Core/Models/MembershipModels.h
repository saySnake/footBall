//
//  MembershipModels.h
//  footBall
//
//  对应 MemberPlanVO、MembershipVO、MembershipStatusVO、MemberBenefitVO、MemberRecordVO。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// MemberPlanVO — 会员方案（月卡/季卡等）
@interface PNMemberPlan : NSObject <YYModel>
@property (nonatomic, copy) NSString *planId;
@property (nonatomic, copy) NSString *name;
/// 时长（天）
@property (nonatomic, assign) NSInteger durationDays;
/// 价格（字符串）
@property (nonatomic, copy, nullable) NSString *price;
/// 每日均价文案
@property (nonatomic, copy, nullable) NSString *dailyPriceDesc;
/// Apple IAP 产品 ID
@property (nonatomic, copy, nullable) NSString *appleProductId;
/// 状态：ACTIVE / INACTIVE
@property (nonatomic, copy, nullable) NSString *status;
@end

/// MembershipVO — 购买激活后返回的会员信息
@interface PNMembership : NSObject <YYModel>
@property (nonatomic, copy, nullable) NSString *levelName;
@property (nonatomic, copy, nullable) NSString *activateTime;
@property (nonatomic, copy, nullable) NSString *expireTime;
@property (nonatomic, copy, nullable) NSString *appleTransactionId;
@end

/// MembershipStatusVO — 当前会员状态
@interface PNMembershipStatus : NSObject <YYModel>
@property (nonatomic, assign) BOOL isMember;
@property (nonatomic, copy, nullable) NSString *levelName;
@property (nonatomic, copy, nullable) NSString *expireTime;
/// 是否即将过期（如距到期 ≤3 天）
@property (nonatomic, assign) BOOL nearExpiry;
@end

@interface PNMemberBenefit : NSObject <YYModel>
@property (nonatomic, copy) NSString *name;
/// 对应后端 description（避免与 NSObject `-description` 冲突）
@property (nonatomic, copy, nullable) NSString *benefitDescription;
@property (nonatomic, copy, nullable) NSString *icon;
@end

/// MemberRecordVO — 订阅/交易一条记录
@interface PNMemberRecord : NSObject <YYModel>
@property (nonatomic, copy) NSString *recordId;
@property (nonatomic, copy, nullable) NSString *planName;
/// 交易类型：PURCHASE / RENEW / CANCEL / REFUND
@property (nonatomic, copy, nullable) NSString *transactionType;
@property (nonatomic, copy, nullable) NSString *appleTransactionId;
@property (nonatomic, copy, nullable) NSString *activateTime;
@property (nonatomic, copy, nullable) NSString *expireTime;
@property (nonatomic, copy, nullable) NSString *createTime;
@end

/// PageResult<MemberRecordVO>
@interface PNMemberRecordPage : NSObject <YYModel>
@property (nonatomic, strong) NSArray<PNMemberRecord *> *list;
@property (nonatomic, assign) NSInteger total;
@property (nonatomic, assign) NSInteger pageNum;
@property (nonatomic, assign) NSInteger pageSize;
@end

NS_ASSUME_NONNULL_END
