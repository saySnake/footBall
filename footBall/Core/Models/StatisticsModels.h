//
//  StatisticsModels.h
//  footBall
//
//  对应 StatisticsVO 及其内部静态类（fc-mono pass-nomad）。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PNStatisticsMostVisitedStadium : NSObject <YYModel>
@property (nonatomic, copy, nullable) NSString *name;
@property (nonatomic, copy, nullable) NSString *city;
/// 到访次数
@property (nonatomic, assign) NSInteger visitCount;
@end

@interface PNStatisticsMostWatchedTeam : NSObject <YYModel>
@property (nonatomic, copy, nullable) NSString *name;
@property (nonatomic, copy, nullable) NSString *logo;
/// 观赛次数
@property (nonatomic, assign) NSInteger watchCount;
@end

/// 基础汇总：总场次、最常去球场、最常看球队、连续观赛天数等
@interface PNStatisticsBasicStats : NSObject <YYModel>
/// 总观赛场次
@property (nonatomic, assign) NSInteger totalMatches;
@property (nonatomic, strong, nullable) PNStatisticsMostVisitedStadium *mostVisitedStadium;
@property (nonatomic, strong, nullable) PNStatisticsMostWatchedTeam *mostWatchedTeam;
/// 最长连续有记录观赛天数
@property (nonatomic, assign) NSInteger maxConsecutiveDays;
@end

/// 按联赛的观赛场次与球场数
@interface PNLeagueStat : NSObject <YYModel>
@property (nonatomic, copy) NSString *leagueName;
@property (nonatomic, assign) NSInteger matchCount;
/// 该联赛下去过的不同球场数
@property (nonatomic, assign) NSInteger stadiumCount;
/// 占全部观赛比例（字符串百分比）
@property (nonatomic, copy, nullable) NSString *percentage;
@end

/// 球场到访排行
@interface PNStadiumRank : NSObject <YYModel>
@property (nonatomic, copy) NSString *stadiumName;
@property (nonatomic, assign) NSInteger visitCount;
@property (nonatomic, copy, nullable) NSString *city;
@end

/// 观赛角色分布（主场球迷/客场等）
@interface PNRoleDist : NSObject <YYModel>
@property (nonatomic, copy) NSString *role;
@property (nonatomic, assign) NSInteger count;
@property (nonatomic, copy, nullable) NSString *percentage;
@end

/// 节假日名称与对应观赛场次
@interface PNHolidayMatch : NSObject <YYModel>
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger matchCount;
@end

/// 节假日观赛汇总
@interface PNHolidayStats : NSObject <YYModel>
@property (nonatomic, assign) NSInteger totalHolidayMatches;
@property (nonatomic, strong) NSArray<PNHolidayMatch *> *holidays;
@end

/// 球场坐标与到访次数（地图散点）
@interface PNStadiumCoordinate : NSObject <YYModel>
@property (nonatomic, copy) NSString *stadiumName;
@property (nonatomic, copy, nullable) NSString *latitude;
@property (nonatomic, copy, nullable) NSString *longitude;
@property (nonatomic, assign) NSInteger visitCount;
@end

/// 对应 TeamRecordVO（统计页主队战绩，与护照内结构一致可复用 PNPassportTeamRecord，此处为 StatisticsVO.teamRecord）
@interface PNStatisticsTeamRecord : NSObject <YYModel>
@property (nonatomic, assign) NSInteger wins;
@property (nonatomic, assign) NSInteger draws;
@property (nonatomic, assign) NSInteger losses;
@property (nonatomic, copy, nullable) NSString *winRate;
/// 被淘汰场次
@property (nonatomic, assign) NSInteger eliminated;
/// 晋级场次
@property (nonatomic, assign) NSInteger qualified;
@end

/// StatisticsVO — 护照/统计页完整数据
@interface PNStatistics : NSObject <YYModel>
@property (nonatomic, strong, nullable) PNStatisticsBasicStats *basicStats;
@property (nonatomic, strong) NSArray<PNLeagueStat *> *leagueStats;
/// 累计观赛时长（分钟或小时，以后端单位为准）
@property (nonatomic, assign) NSInteger cumulativeWatchTime;
@property (nonatomic, strong) NSArray<PNStadiumRank *> *stadiumRanking;
@property (nonatomic, copy, nullable) NSString *homeAwayRatio;
@property (nonatomic, strong) NSArray<PNRoleDist *> *roleDistribution;
@property (nonatomic, strong, nullable) PNStatisticsTeamRecord *teamRecord;
/// 月度频次（12 个月等，顺序以后端为准）
@property (nonatomic, strong) NSArray<NSNumber *> *monthlyFrequency;
@property (nonatomic, strong, nullable) PNHolidayStats *holidayStats;
@property (nonatomic, copy, nullable) NSString *certificationRate;
@property (nonatomic, assign) NSInteger recentTrend7Days;
@property (nonatomic, assign) NSInteger recentTrend30Days;
@property (nonatomic, strong) NSArray<PNStadiumCoordinate *> *stadiumCoordinates;
@end

NS_ASSUME_NONNULL_END
