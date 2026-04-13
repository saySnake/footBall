//
//  Match.m
//  footBall
//
//  Created by LWJ on 2026/3/24.
//

#import "Match.h"

@implementation Match
+(NSDictionary<NSString *,id> *)modelCustomPropertyMapper {
    return @{@"matchId": @[@"matchId", @"id", @"match_id", @"gameId", @"fixtureId"],
             @"matchDate": @[@"matchDate", @"matchTime", @"startTime", @"kickoffTime", @"gameTime", @"beginTime", @"match_date", @"match_time", @"start_time"],
             @"matchStatus": @[@"matchStatus", @"status", @"match_status", @"state", @"gameStatus"],
             @"homeTeamId": @[@"homeTeamId", @"home_team_id"],
             @"awayTeamId": @[@"awayTeamId", @"away_team_id"],
             @"homeTeamName": @[@"homeTeamName", @"home_team_name", @"homeName"],
             @"awayTeamName": @[@"awayTeamName", @"away_team_name", @"awayName"],
             @"homeTeamLogo": @[@"homeTeamLogo", @"home_team_logo"],
             @"awayTeamLogo": @[@"awayTeamLogo", @"away_team_logo"],
             @"homeScore": @[@"homeScore", @"home_score", @"homeGoals"],
             @"awayScore": @[@"awayScore", @"away_score", @"awayGoals"],
             @"infoCompleted": @[@"infoCompleted", @"info_completed", @"inputCompleted", @"input_completed"],
             @"verifyCompleted": @[@"verifyCompleted", @"verify_completed", @"ticketVerified", @"ticket_verified"],
             @"certifiedMinutes": @[@"certifiedMinutes", @"certified_minutes", @"verifiedMinutes", @"verified_minutes"],
             @"favorited": @[@"favorited", @"favorite", @"isFavorited", @"is_favorite"],
             @"liked": @[@"liked", @"like"]};
}

/// 日程 / 关注球队比赛：id 与队名可能在嵌套对象里
- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    if (self.matchId.length == 0) {
        id v = dic[@"matchId"] ?: dic[@"id"] ?: dic[@"match_id"] ?: dic[@"gameId"] ?: dic[@"fixtureId"];
        if ([v isKindOfClass:NSNumber.class]) {
            self.matchId = [(NSNumber *)v stringValue];
        } else if ([v isKindOfClass:NSString.class]) {
            self.matchId = (NSString *)v;
        }
    }
    void (^fillTeam)(NSDictionary *, BOOL) = ^(NSDictionary *team, BOOL home) {
        if (![team isKindOfClass:NSDictionary.class]) {
            return;
        }
        NSString * (^nameFrom)(void) = ^{
            id n = team[@"name"] ?: team[@"teamName"] ?: team[@"shortName"] ?: team[@"title"] ?: team[@"displayName"];
            if ([n isKindOfClass:NSString.class]) {
                return (NSString *)n;
            }
            if ([n isKindOfClass:NSNumber.class]) {
                return [(NSNumber *)n stringValue];
            }
            return (NSString *)nil;
        };
        NSString * (^logoFrom)(void) = ^{
            id u = team[@"logo"] ?: team[@"logoUrl"] ?: team[@"logoURL"] ?: team[@"emblemUrl"] ?: team[@"crest"];
            if ([u isKindOfClass:NSString.class]) {
                return (NSString *)u;
            }
            return (NSString *)nil;
        };
        NSString * (^idFrom)(void) = ^{
            id tid = team[@"id"] ?: team[@"teamId"];
            if ([tid isKindOfClass:NSNumber.class]) {
                return [(NSNumber *)tid stringValue];
            }
            if ([tid isKindOfClass:NSString.class]) {
                return (NSString *)tid;
            }
            return (NSString *)nil;
        };
        if (home) {
            if (self.homeTeamName.length == 0) {
                self.homeTeamName = nameFrom() ?: @"";
            }
            if (self.homeTeamLogo.length == 0) {
                self.homeTeamLogo = logoFrom() ?: @"";
            }
            if (self.homeTeamId.length == 0) {
                self.homeTeamId = idFrom() ?: @"";
            }
        } else {
            if (self.awayTeamName.length == 0) {
                self.awayTeamName = nameFrom() ?: @"";
            }
            if (self.awayTeamLogo.length == 0) {
                self.awayTeamLogo = logoFrom() ?: @"";
            }
            if (self.awayTeamId.length == 0) {
                self.awayTeamId = idFrom() ?: @"";
            }
        }
    };
    id homeObj = dic[@"homeTeam"] ?: dic[@"home_team"] ?: dic[@"home"];
    if ([homeObj isKindOfClass:NSDictionary.class]) {
        fillTeam((NSDictionary *)homeObj, YES);
    }
    id awayObj = dic[@"awayTeam"] ?: dic[@"away_team"] ?: dic[@"away"];
    if ([awayObj isKindOfClass:NSDictionary.class]) {
        fillTeam((NSDictionary *)awayObj, NO);
    }
    return YES;
}
@end

@implementation MatchDetail
@end

@implementation PNMatchPage
+ (NSDictionary<NSString *,id> *)modelContainerPropertyGenericClass {
    return @{@"list": Match.class};
}
@end
