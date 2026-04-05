//
//  StatisticsModels.m
//  footBall
//

#import "StatisticsModels.h"

@implementation PNStatisticsMostVisitedStadium
@end

@implementation PNStatisticsMostWatchedTeam
@end

@implementation PNStatisticsBasicStats
@end

@implementation PNLeagueStat
@end

@implementation PNStadiumRank
@end

@implementation PNRoleDist
@end

@implementation PNHolidayMatch
@end

@implementation PNHolidayStats
+ (NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass {
    return @{ @"holidays": PNHolidayMatch.class };
}
@end

@implementation PNStadiumCoordinate
@end

@implementation PNStatisticsTeamRecord
@end

@implementation PNStatistics
+ (NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass {
    return @{
        @"leagueStats": PNLeagueStat.class,
        @"stadiumRanking": PNStadiumRank.class,
        @"roleDistribution": PNRoleDist.class,
        @"monthlyFrequency": NSNumber.class,
        @"stadiumCoordinates": PNStadiumCoordinate.class,
    };
}
@end
