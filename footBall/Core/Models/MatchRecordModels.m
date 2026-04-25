//
//  MatchRecordModels.m
//  footBall
//

#import "MatchRecordModels.h"

@implementation PNMatchRecord
+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{ @"recordId": @[ @"id", @"recordId" ] };
}
@end

@implementation PNMatchRecordDetail
+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{
        @"recordId": @[ @"id", @"recordId", @"record_id" ],
        @"matchId": @[ @"matchId", @"match_id", @"gameId", @"fixtureId" ],
        @"matchDate": @[ @"matchDate", @"match_date", @"kickoffTime", @"kickoff_time", @"startTime", @"start_time", @"gameTime", @"beginTime" ],
        @"matchDateTime": @[ @"matchDateTime", @"match_date_time", @"watchDateTime", @"watch_date_time", @"datetime" ],
        @"homeTeamName": @[ @"homeTeamName", @"home_team_name", @"homeName" ],
        @"awayTeamName": @[ @"awayTeamName", @"away_team_name", @"awayName" ],
        @"ticketPrice": @[ @"ticketPrice", @"ticket_price", @"price" ],
    };
}

- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    id p = dic[@"ticketPrice"];
    if ([p isKindOfClass:NSNumber.class]) {
        self.ticketPrice = [p stringValue];
    }
    return YES;
}
@end

@implementation PNMatchRecordPage
+ (NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass {
    return @{ @"list": PNMatchRecord.class };
}
@end
