//
//  StampModels.h
//  footBall
//
//  对应 StampCollectionVO、StampCategoryVO、StampVO、StampDetailVO。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// StampCollectionVO.StampItemVO — 邮票夹分类下的单枚展示
@interface PNStampAlbumItem : NSObject <YYModel>
/// 邮票 ID
@property (nonatomic, copy) NSString *stampId;
/// 名称
@property (nonatomic, copy) NSString *name;
/// 图片 URL
@property (nonatomic, copy, nullable) NSString *image;
/// 稀有度：COMMON / RARE / EPIC / LEGENDARY
@property (nonatomic, copy, nullable) NSString *rarity;
/// 是否已解锁
@property (nonatomic, assign) BOOL unlocked;
/// 是否新获得
@property (nonatomic, assign) BOOL isNew;
/// 解锁条件说明
@property (nonatomic, copy, nullable) NSString *unlockCondition;
/// 获取时间
@property (nonatomic, copy, nullable) NSString *acquiredTime;
/// 在主页的坐标 e.g "1,5"，让后端新增
@property (nonatomic, copy) NSString *position;
@end

/// StampCollectionVO.StampCategoryItemVO — 带邮票列表的分类块
@interface PNStampCategorySection : NSObject <YYModel>
/// 分类 ID
@property (nonatomic, copy) NSString *categoryId;
/// 分类名称
@property (nonatomic, copy) NSString *name;
/// 分类图标 URL
@property (nonatomic, copy, nullable) NSString *icon;
/// 该分类邮票总数
@property (nonatomic, assign) NSInteger totalCount;
/// 已收集数
@property (nonatomic, assign) NSInteger collectedCount;
/// 该分类下邮票（每分类最多 10 个等，以后端为准）
@property (nonatomic, strong) NSArray<PNStampAlbumItem *> *stamps;
@end

NS_ASSUME_NONNULL_END
