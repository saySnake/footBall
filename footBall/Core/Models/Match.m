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
             @"verificationStatus": @[@"verificationStatus", @"verification_status", @"verifyStatus", @"verify_status", @"certificationStatus", @"authStatus", @"status"],
             @"certifiedMinutes": @[@"certifiedMinutes", @"certified_minutes", @"verifiedMinutes", @"verified_minutes"],
             @"recordId": @[@"recordId", @"record_id"],
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
    if (self.recordId.length == 0) {
        id r = dic[@"recordId"] ?: dic[@"record_id"];
        if ([r isKindOfClass:NSNumber.class]) {
            self.recordId = [(NSNumber *)r stringValue];
        } else if ([r isKindOfClass:NSString.class]) {
            self.recordId = (NSString *)r;
        }
    }
    // 兼容后端将 verifyCompleted 以字符串/数字/枚举返回的情况
    BOOL (^parseBoolLike)(id) = ^BOOL(id raw) {
        if ([raw isKindOfClass:NSNumber.class]) {
            return [(NSNumber *)raw boolValue];
        }
        if ([raw isKindOfClass:NSString.class]) {
            NSString *s = [(NSString *)raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].lowercaseString;
            if (s.length == 0) return NO;
            if ([s isEqualToString:@"1"] || [s isEqualToString:@"true"] || [s isEqualToString:@"yes"]) return YES;
            if ([s isEqualToString:@"0"] || [s isEqualToString:@"false"] || [s isEqualToString:@"no"]) return NO;
            if ([s isEqualToString:@"verified"] || [s isEqualToString:@"approved"] || [s isEqualToString:@"passed"] || [s isEqualToString:@"success"]) return YES;
        }
        return NO;
    };
    id verifyRaw = dic[@"verifyCompleted"] ?: dic[@"verify_completed"] ?: dic[@"ticketVerified"] ?: dic[@"ticket_verified"];
    if (verifyRaw) {
        self.verifyCompleted = parseBoolLike(verifyRaw);
    }
    // 若 verifyCompleted 未命中，但状态字段是已通过，也应视为已认证
    if (!self.verifyCompleted) {
        NSString *status = self.verificationStatus;
        if (![status isKindOfClass:NSString.class] || status.length == 0) {
            id st = dic[@"verificationStatus"] ?: dic[@"verification_status"] ?: dic[@"verifyStatus"] ?: dic[@"verify_status"] ?: dic[@"certificationStatus"] ?: dic[@"authStatus"] ?: dic[@"status"];
            if ([st isKindOfClass:NSString.class]) {
                status = (NSString *)st;
                self.verificationStatus = status;
            }
        }
        NSString *s = [[status stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
        if ([s isEqualToString:@"verified"] || [s isEqualToString:@"approved"] || [s isEqualToString:@"passed"] || [s isEqualToString:@"success"] || [s isEqualToString:@"已认证"]) {
            self.verifyCompleted = YES;
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
    NSInteger (^intFromId)(id) = ^NSInteger(id o) {
        if (o == nil || o == (id)kCFNull) { return 0; }
        if ([o isKindOfClass:NSNumber.class]) { return [(NSNumber *)o integerValue]; }
        if ([o isKindOfClass:NSString.class]) { return [(NSString *)o integerValue]; }
        return 0;
    };
    if (self.homeScore == 0 && self.awayScore == 0) {
        id ft = dic[@"fullTime"] ?: dic[@"ft"] ?: dic[@"full_time"] ?: dic[@"fulltime"] ?: dic[@"fullTimeScore"];
        if ([ft isKindOfClass:NSDictionary.class]) {
            NSDictionary *f = (NSDictionary *)ft;
            self.homeScore = intFromId(f[@"home"] ?: f[@"homeScore"] ?: f[@"homeTeamScore"] ?: f[@"h"] ?: f[@"goalsHome"]);
            self.awayScore = intFromId(f[@"away"] ?: f[@"awayScore"] ?: f[@"awayTeamScore"] ?: f[@"a"] ?: f[@"goalsAway"]);
        } else {
            id sc = dic[@"score"] ?: dic[@"result"] ?: dic[@"ftScore"] ?: dic[@"ft_score"];
            if ([sc isKindOfClass:NSString.class]) {
                NSString *s = [((NSString *)sc) stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                if (s.length > 0) {
                    NSCharacterSet *sep = [NSCharacterSet characterSetWithCharactersInString:@":-·"];
                    NSArray<NSString *> *parts = [s componentsSeparatedByCharactersInSet:sep];
                    if (parts.count >= 2) {
                        self.homeScore = (NSInteger)[parts[0] integerValue];
                        self.awayScore = (NSInteger)[parts[1] integerValue];
                    }
                }
            } else if ([sc isKindOfClass:NSDictionary.class]) {
                NSDictionary *f = (NSDictionary *)sc;
                self.homeScore = intFromId(f[@"home"] ?: f[@"h"] ?: f[@"left"]);
                self.awayScore = intFromId(f[@"away"] ?: f[@"a"] ?: f[@"right"]);
            }
        }
    }
    if (self.homeScore == 0 && self.awayScore == 0) {
        if ([homeObj isKindOfClass:NSDictionary.class]) {
            NSDictionary *h = (NSDictionary *)homeObj;
            self.homeScore = intFromId(h[@"goals"] ?: h[@"goal"] ?: h[@"score"]);
        }
        if ([awayObj isKindOfClass:NSDictionary.class]) {
            NSDictionary *a = (NSDictionary *)awayObj;
            self.awayScore = intFromId(a[@"goals"] ?: a[@"goal"] ?: a[@"score"]);
        }
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
