//
//  Passport.h
//  footBall
//
//  PNPassport 对应后端 PassportVO（/api/v1/passport/me 与 /{userId}）。
//
//  ⚠️ 后端 PassportVO 已重构为轻量版：
//    - 仅返回 userId + 邮票分类展示数据（categories）
//    - 原护照统计字段（yearTotalMatches、teamRecord 等）已迁移至 StatisticsVO
//    - 统计数据请调用 /api/v1/statistics/me → PNStatistics
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// PassportVO.StampItem — 护照邮票展示单枚
@interface PNPassportStampItem : NSObject <YYModel>
/// 邮票 ID
@property (nonatomic, copy) NSString *stampId;
/// 邮票名称
@property (nonatomic, copy, nullable) NSString *name;
/// 邮票图片 URL
@property (nonatomic, copy, nullable) NSString *image;
/// 展示位置（后端自定义字段）
@property (nonatomic, copy, nullable) NSString *position;
@end

/// PassportVO.CategoryStamps — 护照邮票分类块
@interface PNPassportCategoryStamps : NSObject <YYModel>
/// 分类 ID
@property (nonatomic, copy) NSString *categoryId;
/// 分类名称
@property (nonatomic, copy, nullable) NSString *categoryName;
/// 该分类下展示的邮票列表
@property (nonatomic, strong) NSArray<PNPassportStampItem *> *stamps;
@end

/// PassportVO — 护照主体（轻量版，仅含邮票展示）
/// 统计数据（场次、战绩、时长等）请使用 PNStatistics（/api/v1/statistics/me）
@interface PNPassport : NSObject <YYModel>
/// 用户 ID
@property (nonatomic, copy) NSString *userId;
/// 邮票分类展示列表
@property (nonatomic, strong) NSArray<PNPassportCategoryStamps *> *categories;
@end

NS_ASSUME_NONNULL_END
