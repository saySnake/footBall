//
//  MembershipModels.m
//  footBall
//

#import "MembershipModels.h"

@implementation PNMemberPlan
+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{
        @"planId": @[ @"id", @"planId", @"plan_id" ],
        @"durationDays": @[ @"durationDays", @"duration_days" ],
        @"dailyPriceDesc": @[ @"dailyPriceDesc", @"daily_price_desc", @"dailyPrice" ],
        @"appleProductId": @[ @"appleProductId", @"apple_product_id", @"productId", @"product_id", @"sku", @"iapProductId", @"iosProductId" ]
    };
}

- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    if ([self.planId isKindOfClass:NSString.class]) {
        self.planId = [self.planId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    if ([self.appleProductId isKindOfClass:NSString.class]) {
        self.appleProductId = [self.appleProductId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    if ([self.status isKindOfClass:NSString.class]) {
        self.status = [[self.status stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    }
    return YES;
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
