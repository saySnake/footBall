#import "LeaderboardModels.h"
#import "Team.h"

@implementation PNLeaderboardEntry
+ (NSDictionary<NSString *,id> *)modelContainerPropertyGenericClass {
    return @{@"followedTeams": TeamIcon.class};
}
+ (NSDictionary<NSString *,id> *)modelCustomPropertyMapper {
    return @{@"userId": @[@"userId", @"id"]};
}
@end

@implementation PNLeaderboard
+ (NSDictionary<NSString *,id> *)modelContainerPropertyGenericClass {
    return @{@"list": PNLeaderboardEntry.class};
}
@end
