//
//  VerificationModels.h
//  footBall
//
//  对应 VerificationStatusVO、RealnameInfoVO、VerificationHistoryVO。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// VerificationStatusVO — 当前用户认证状态摘要
@interface PNVerificationStatus : NSObject <YYModel>
/// 职业认证状态：PENDING / APPROVED / REJECTED / EXPIRED
@property (nonatomic, copy, nullable) NSString *professionalStatus;
/// 职业认证是否即将过期（如 ≤30 天）
@property (nonatomic, assign) BOOL professionalNearExpiry;
/// 实名认证状态：PENDING / APPROVED / REJECTED
@property (nonatomic, copy, nullable) NSString *realnameStatus;
@property (nonatomic, assign) BOOL realnameNearExpiry;
@end

/// RealnameInfoVO — 实名信息（脱敏）
@interface PNRealnameInfo : NSObject <YYModel>
@property (nonatomic, copy, nullable) NSString *realName;
@property (nonatomic, copy, nullable) NSString *gender;
@property (nonatomic, copy, nullable) NSString *ethnicity;
@property (nonatomic, copy, nullable) NSString *birthDate;
@property (nonatomic, copy, nullable) NSString *address;
@property (nonatomic, copy, nullable) NSString *idCardNumber;
@end

/// VerificationHistoryVO — 单条认证历史
@interface PNVerificationHistory : NSObject <YYModel>
/// 记录 ID
@property (nonatomic, copy) NSString *historyId;
/// 类型：PROFESSIONAL / REALNAME
@property (nonatomic, copy, nullable) NSString *type;
/// 状态：PENDING / APPROVED / REJECTED / EXPIRED
@property (nonatomic, copy, nullable) NSString *status;
@property (nonatomic, copy, nullable) NSString *rejectReason;
/// 过期时间（职业认证续期）
@property (nonatomic, copy, nullable) NSString *expireTime;
@property (nonatomic, copy, nullable) NSString *createTime;
@property (nonatomic, copy, nullable) NSString *reviewTime;
@end

NS_ASSUME_NONNULL_END
