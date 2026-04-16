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

/// StampCollectionVO — 邮票夹主页
@interface PNStampCollection : NSObject <YYModel>
/// 按分类组织的列表
@property (nonatomic, strong) NSArray<PNStampCategorySection *> *categories;
/// 是否会员（非会员限制显示5个邮票）
@property (nonatomic, assign) BOOL isMember;
@end

/// StampCategoryVO — 动态分类列表单项
@interface PNStampCategory : NSObject <YYModel>
/// 分类 ID
@property (nonatomic, copy) NSString *categoryId;
/// 分类名称
@property (nonatomic, copy) NSString *name;
/// 图标 URL
@property (nonatomic, copy, nullable) NSString *icon;
/// 排序序号
@property (nonatomic, assign) NSInteger sortOrder;
@end

/// StampVO — 某分类下全部邮票（网格）
@interface PNStampGridItem : NSObject <YYModel>
/// 邮票 ID
@property (nonatomic, copy) NSString *stampId;
/// 名称
@property (nonatomic, copy) NSString *name;
/// 图片 URL
@property (nonatomic, copy, nullable) NSString *image;
/// 描述（映射后端 description）
@property (nonatomic, copy, nullable) NSString *stampDescription;
/// 稀有度
@property (nonatomic, copy, nullable) NSString *rarity;
/// 解锁条件
@property (nonatomic, copy, nullable) NSString *unlockCondition;
/// 是否已解锁
@property (nonatomic, assign) BOOL unlocked;
/// 是否新获得
@property (nonatomic, assign) BOOL isNew;
/// 获取时间
@property (nonatomic, copy, nullable) NSString *acquiredTime;
/// 排序序号
@property (nonatomic, assign) NSInteger sortOrder;
@end

/// StampDetailVO — 邮票详情
@interface PNStampDetail : NSObject <YYModel>
/// 邮票 ID
@property (nonatomic, copy) NSString *stampId;
/// 名称
@property (nonatomic, copy) NSString *name;
/// 描述（映射后端 description）
@property (nonatomic, copy, nullable) NSString *stampDescription;
/// 图片 URL
@property (nonatomic, copy, nullable) NSString *image;
/// 稀有度：COMMON / RARE / EPIC / LEGENDARY
@property (nonatomic, copy, nullable) NSString *rarity;
@property (nonatomic, copy, nullable) NSString *unlockCondition;
/// 所属分类名称
@property (nonatomic, copy, nullable) NSString *categoryName;
/// 所属分类 ID
@property (nonatomic, copy, nullable) NSString *categoryId;
/// 是否已解锁
@property (nonatomic, assign) BOOL unlocked;
/// 是否新获得
@property (nonatomic, assign) BOOL isNew;
/// 获取时间
@property (nonatomic, copy, nullable) NSString *acquiredTime;
/// 展示排序
@property (nonatomic, assign) NSInteger displayOrder;
@end

NS_ASSUME_NONNULL_END
