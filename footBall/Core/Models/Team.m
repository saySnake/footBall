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
- (BOOL)modelCustomTransformFromDictionary:(__unused NSDictionary *)dic {
    id t = self.teamId;
    if (t && ![t isKindOfClass:NSString.class]) {
        if ([t isKindOfClass:NSNumber.class]) {
            self.teamId = [(NSNumber *)t stringValue];
        } else {
            self.teamId = [t description] ?: @"";
        }
    }
    return YES;
}
@end
@implementation Team
@end
@implementation TeamDetail
@end
