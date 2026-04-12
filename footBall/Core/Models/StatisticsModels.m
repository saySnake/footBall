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
+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{ @"totalMatches": @[@"totalMatches", @"total_matches"] };
}
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
+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{
        @"wins": @[@"wins", @"win"],
        @"draws": @[@"draws", @"draw"],
        @"losses": @[@"losses", @"loss"],
        @"eliminated": @[@"eliminated", @"eliminate"],
        @"qualified": @[@"qualified", @"qualify"],
        @"winRate": @[@"winRate", @"win_rate"],
    };
}
@end

@implementation PNStatistics
+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{
        @"basicStats": @[@"basicStats", @"basic_stats"],
        @"leagueStats": @[@"leagueStats", @"league_stats"],
        @"stadiumRanking": @[@"stadiumRanking", @"stadium_ranking"],
        @"roleDistribution": @[@"roleDistribution", @"role_distribution"],
        @"teamRecord": @[@"teamRecord", @"team_record"],
        @"monthlyFrequency": @[@"monthlyFrequency", @"monthly_frequency"],
        @"holidayStats": @[@"holidayStats", @"holiday_stats"],
        @"certificationRate": @[@"certificationRate", @"certification_rate"],
        @"recentTrend7Days": @[@"recentTrend7Days", @"recent_trend_7_days"],
        @"recentTrend30Days": @[@"recentTrend30Days", @"recent_trend_30_days"],
        @"stadiumCoordinates": @[@"stadiumCoordinates", @"stadium_coordinates"],
        @"cumulativeWatchTime": @[@"cumulativeWatchTime", @"cumulative_watch_time", @"totalWatchMinutes", @"total_watch_minutes"],
        @"countryCount": @[@"countryCount", @"country_count", @"nationCount", @"nation_count"],
    };
}
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
