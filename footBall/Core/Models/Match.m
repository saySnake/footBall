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
             @"awayTeamLogo": @"awayTeamLogo"};
}
@end

@implementation MatchDetail
@end
