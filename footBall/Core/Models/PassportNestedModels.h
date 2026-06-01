//
//  PassportNestedModels.h
//  footBall
//
//  对应后端 PassportVO 内嵌的子结构（fc-mono pass-nomad dal.vo）。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// CountryHeatmapVO — 国家热力图
@interface PNCountryHeatmap : NSObject <YYModel>
/// 国家名称
@property (nonatomic, copy) NSString *country;
/// 观赛场次
@property (nonatomic, assign) NSInteger matchCount;
/// 热力等级：0 未点亮，1 [1,5)，2 [5,10)，3 [10,20)，4 为 20+
@property (nonatomic, assign) NSInteger level;
@end

/// DisciplineStatsVO — 红黄牌/干净场
@interface PNDisciplineStats : NSObject <YYModel>
/// 红牌总数
@property (nonatomic, assign) NSInteger redCards;
/// 黄牌总数
@property (nonatomic, assign) NSInteger yellowCards;
/// 干净场次（无红黄牌）
@property (nonatomic, assign) NSInteger cleanMatches;
@end

/// TeamRecordVO — 护照内主队战绩
@interface PNPassportTeamRecord : NSObject <YYModel>
/// 胜场
@property (nonatomic, assign) NSInteger wins;
/// 平场
@property (nonatomic, assign) NSInteger draws;
/// 负场
@property (nonatomic, assign) NSInteger losses;
/// 胜率
@property (nonatomic, assign) float winRate;
/// 淘汰次数
@property (nonatomic, assign) NSInteger eliminated;
/// 出线次数
@property (nonatomic, assign) NSInteger qualified;
@end

/// LocationDistVO — 观赛地点分布
@interface PNLocationDist : NSObject <YYModel>
/// 地点类型：AT_SCENE / AT_BAR / AT_HOME 等
@property (nonatomic, copy) NSString *location;
/// 出现次数
@property (nonatomic, assign) NSInteger count;
/// 是否高亮（频次最高）
@property (nonatomic, assign) BOOL highlight;
@end

/// StandDistVO — 看台类型分布
@interface PNStandDist : NSObject <YYModel>
/// 看台类型：内场 / 1层 / 2层 等
@property (nonatomic, copy) NSString *standType;
/// 出现次数
@property (nonatomic, assign) NSInteger count;
@end

/// IdentityDistVO — 观赛身份饼图
@interface PNIdentityDist : NSObject <YYModel>
/// 身份类型：MEDIA_REPORTER / FAN 等
@property (nonatomic, copy) NSString *identity;
/// 出现次数
@property (nonatomic, assign) NSInteger count;
/// 占比百分比（后端可能为数字或字符串）
@property (nonatomic, copy, nullable) NSString *percentage;
@end

/// EmotionDistVO — 赛后情绪分布
@interface PNEmotionDist : NSObject <YYModel>
/// 情绪类型（emoji，如 🤩 / 🥳）
@property (nonatomic, copy) NSString *emotion;
/// 出现次数
@property (nonatomic, assign) NSInteger count;
/// 是否高亮（频次最高）
@property (nonatomic, assign) BOOL highlight;
@end

/// OnlineMethodDistVO — 线上观赛方式饼图
@interface PNOnlineMethodDist : NSObject <YYModel>
/// 线上方式：LIVE_STREAM / FULL_90MIN 等
@property (nonatomic, copy) NSString *method;
/// 出现次数
@property (nonatomic, assign) NSInteger count;
/// 占比百分比（后端可能为数字或字符串）
@property (nonatomic, copy, nullable) NSString *percentage;
@end

/// StampShortVO — 最近获得的邮票摘要
@interface PNStampShort : NSObject <YYModel>
/// 邮票 ID
@property (nonatomic, copy) NSString *stampId;
/// 名称
@property (nonatomic, copy) NSString *name;
/// 图片 URL
@property (nonatomic, copy) NSString *image;
/// 稀有度：COMMON / RARE / EPIC / LEGENDARY
@property (nonatomic, copy, nullable) NSString *rarity;
/// 获取时间
@property (nonatomic, copy, nullable) NSString *acquiredTime;
@end

/// StampCategoryShortVO — 邮票分类快捷入口
@interface PNStampCategoryShort : NSObject <YYModel>
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
@end

NS_ASSUME_NONNULL_END
