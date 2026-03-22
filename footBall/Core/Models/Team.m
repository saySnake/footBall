//
//  Team.m
//  footBall
//
//  Created by LWJ on 2026/3/22.
//

#import "Team.h"

@implementation Team
+ (NSDictionary<NSString *,id> *)modelCustomPropertyMapper {
    return @{@"teamId":@"id"};
}
@end
