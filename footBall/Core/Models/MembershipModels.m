//
//  MembershipModels.m
//  footBall
//

#import "MembershipModels.h"

@implementation PNMemberPlan
+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{ @"planId": @[ @"id", @"planId" ] };
}
@end

@implementation PNMembership
@end

@implementation PNMembershipStatus
@end

@implementation PNMemberBenefit
+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{ @"benefitDescription": @[ @"description", @"desc" ] };
}
@end

@implementation PNMemberRecord
+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{ @"recordId": @[ @"id", @"recordId" ] };
}
@end

@implementation PNMemberRecordPage
+ (NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass {
    return @{ @"list": PNMemberRecord.class };
}
@end
