#import "LeaderboardModels.h"
#import "Team.h"

@implementation PNLeaderboardEntry
+ (NSDictionary<NSString *,id> *)modelContainerPropertyGenericClass {
    return @{@"followedTeams": TeamIcon.class};
}
+ (NSDictionary<NSString *,id> *)modelCustomPropertyMapper {
    return @{
        @"userId": @[@"userId", @"id"],
        @"nickname": @[@"nickname", @"nickName", @"name"],
        @"teamName": @[@"teamName", @"team_name", @"favoriteTeamName"],
        @"matchCount": @[@"matchCount", @"match_count", @"games"],
    };
}
@end

@implementation PNLeaderboard
+ (NSDictionary<NSString *,id> *)modelContainerPropertyGenericClass {
    return @{@"list": PNLeaderboardEntry.class};
}
+ (NSDictionary<NSString *,id> *)modelCustomPropertyMapper {
    return @{@"list": @[@"list", @"records", @"items"]};
}
@end
