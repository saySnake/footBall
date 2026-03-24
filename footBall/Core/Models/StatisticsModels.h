#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PNStatisticsBasicStats : NSObject <YYModel>
@property (nonatomic, assign) NSInteger totalMatches;
@end

@interface PNLeagueStat : NSObject <YYModel>
@property (nonatomic, copy) NSString *leagueName;
@property (nonatomic, assign) NSInteger matchCount;
@end

@interface PNStadiumRank : NSObject <YYModel>
@property (nonatomic, copy) NSString *stadiumName;
@property (nonatomic, assign) NSInteger visitCount;
@end

@interface PNStatistics : NSObject <YYModel>
@property (nonatomic, strong, nullable) PNStatisticsBasicStats *basicStats;
@property (nonatomic, assign) NSInteger cumulativeWatchTime;
@property (nonatomic, strong) NSArray<PNLeagueStat *> *leagueStats;
@property (nonatomic, strong) NSArray<PNStadiumRank *> *stadiumRanking;
@end

NS_ASSUME_NONNULL_END
