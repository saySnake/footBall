//
//  StampModels.h
//  footBall
//
//  对应 StampCollectionVO、StampCategoryVO、StampVO、StampDetailVO。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// UserStampVO / SelectableStampsVO.StampItem — 邮票（选择页/主页展示共用）
@interface PNStampAlbumItem : NSObject <YYModel>
/// 邮票 ID
@property (nonatomic, copy) NSString *stampId;
/// 名称
@property (nonatomic, copy, nullable) NSString *name;
/// 图片 URL
@property (nonatomic, copy, nullable) NSString *image;
/// 稀有度：COMMON / RARE / EPIC / LEGENDARY
@property (nonatomic, copy, nullable) NSString *rarity;
/// 获取时间
@property (nonatomic, copy, nullable) NSString *acquiredTime;
/// 在主页的坐标 e.g "1,5"
@property (nonatomic, copy, nullable) NSString *position;
/// 选择页：是否已被选择（已占用位置）
@property (nonatomic, assign) BOOL selected;
/// 是否已认证
@property (nonatomic, assign) BOOL verified;

@end

/// 邮票分类（选择页/已认证列表共用）
@interface PNStampCategory : NSObject <YYModel>
@property (nonatomic, copy) NSString *categoryId;
@property (nonatomic, copy, nullable) NSString *categoryName;
@property (nonatomic, copy, nullable) NSString *categoryIcon;
@property (nonatomic, assign) NSInteger totalCount;
/// 已收集数（部分接口返回）
@property (nonatomic, assign) NSInteger collectedCount;
/// 已选择数（选择页返回）
@property (nonatomic, assign) NSInteger selectedCount;
@property (nonatomic, copy) NSArray<PNStampAlbumItem *> *stamps;
@end

/// StampQuotaVO — 邮票配额（会员状态、免费额度、最大可选数）
@interface PNStampQuota : NSObject <YYModel>
/// 已认证比赛场次数
@property (nonatomic, assign) NSInteger verifiedMatchCount;
/// 已选择邮票数
@property (nonatomic, assign) NSInteger selectedStampCount;
/// 最大可选邮票数
@property (nonatomic, assign) NSInteger maxStampCount;
/// 是否可继续添加
@property (nonatomic, assign) BOOL canAddStamp;
/// 是否会员
@property (nonatomic, assign) BOOL isMember;
/// 非会员免费额度（后端默认 5）
@property (nonatomic, assign) NSInteger freeQuota;
/// 不可添加时的原因
@property (nonatomic, copy, nullable) NSString *reason;
@end

NS_ASSUME_NONNULL_END
