#import "StatisticsModels.h"

@implementation PNStatisticsBasicStats
@end

@implementation PNLeagueStat
@end

@implementation PNStadiumRank
@end

@implementation PNStatistics
+ (NSDictionary<NSString *,id> *)modelContainerPropertyGenericClass {
    return @{@"leagueStats": PNLeagueStat.class,
             @"stadiumRanking": PNStadiumRank.class};
}
@end
