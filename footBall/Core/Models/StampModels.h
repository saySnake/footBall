//
//  StampModels.h
//  footBall
//
//  对应 StampCollectionVO、StampCategoryVO、StampVO、StampDetailVO。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 仓库/主页邮票项（含 displayStatus / source / isNew）
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
/// 展示状态：VISIBLE / HIDDEN
@property (nonatomic, copy, nullable) NSString *displayStatus;
/// 来源：AUTO_ISSUE_MATCH_VERIFIED / AUTO_ISSUE_MILESTONE_MATCH_COUNT / AUTO_ISSUE_MILESTONE_STADIUM_COUNT / MANUAL_SELECT
@property (nonatomic, copy, nullable) NSString *source;
/// 是否新获得（查看详情后变 false）
@property (nonatomic, assign) BOOL isNew;

/// YES 当 displayStatus 为 VISIBLE
- (BOOL)isDisplayedOnHome;
@end

/// 邮票分类（仓库/已认证列表共用）
@interface PNStampCategory : NSObject <YYModel>
@property (nonatomic, copy) NSString *categoryId;
@property (nonatomic, copy, nullable) NSString *categoryName;
@property (nonatomic, copy, nullable) NSString *categoryIcon;
@property (nonatomic, assign) NSInteger totalCount;
/// 已收集数（部分接口返回）
@property (nonatomic, assign) NSInteger collectedCount;
@property (nonatomic, copy) NSArray<PNStampAlbumItem *> *stamps;
@end

NS_ASSUME_NONNULL_END
