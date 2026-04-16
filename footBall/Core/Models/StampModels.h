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

NS_ASSUME_NONNULL_END
