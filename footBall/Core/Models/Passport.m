#import "Passport.h"
#import "Team.h"

@implementation PNPassport
+ (NSDictionary<NSString *,id> *)modelContainerPropertyGenericClass {
    return @{@"followedTeams": TeamIcon.class};
}
+ (NSDictionary<NSString *,id> *)modelCustomPropertyMapper {
    return @{@"userId": @[@"userId", @"id"]};
}
@end
