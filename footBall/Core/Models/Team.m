//
//  Team.m
//  footBall
//
//  Created by LWJ on 2026/3/22.
//

#import "Team.h"
@implementation TeamIcon
+ (NSDictionary<NSString *,id> *)modelCustomPropertyMapper {
    return @{ @"teamId": @[ @"id", @"teamId" ] };
}
@end
@implementation Team
@end
@implementation TeamDetail
@end
