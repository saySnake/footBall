//
//  Match.m
//  footBall
//
//  Created by LWJ on 2026/3/24.
//

#import "Match.h"

@implementation Match
+(NSDictionary<NSString *,id> *)modelCustomPropertyMapper {
    return @{@"matchId": @"id",
             @"homeTeamId": @"homeTeamId",
             @"awayTeamId": @"awayTeamId",
             @"homeTeamLogo": @"homeTeamLogo",
             @"awayTeamLogo": @"awayTeamLogo",
             @"infoCompleted": @[@"infoCompleted", @"info_completed", @"inputCompleted", @"input_completed"],
             @"verifyCompleted": @[@"verifyCompleted", @"verify_completed", @"ticketVerified", @"ticket_verified"],
             @"certifiedMinutes": @[@"certifiedMinutes", @"certified_minutes", @"verifiedMinutes", @"verified_minutes"],
             @"favorited": @[@"favorited", @"favorite"],
             @"liked": @[@"liked", @"like"]};
}
@end

@implementation MatchDetail
@end

@implementation PNMatchPage
+ (NSDictionary<NSString *,id> *)modelContainerPropertyGenericClass {
    return @{@"list": Match.class};
}
@end
