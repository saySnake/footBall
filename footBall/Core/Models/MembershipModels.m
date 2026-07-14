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

@implementation PNRedeemResult
+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{
        @"redeemDescription": @[ @"description", @"desc", @"redeemDescription" ],
        @"activateTime": @[ @"activateTime", @"activate_time" ],
        @"expireTime": @[ @"expireTime", @"expire_time" ],
        @"discountPrice": @[ @"discountPrice", @"discount_price" ],
        @"originalPrice": @[ @"originalPrice", @"original_price" ],
        @"appleProductId": @[ @"appleProductId", @"apple_product_id", @"productId" ],
        @"planId": @[ @"planId", @"plan_id" ],
        @"durationDays": @[ @"durationDays", @"duration_days" ],
        @"needPayment": @[ @"needPayment", @"need_payment" ],
        @"codeType": @[ @"codeType", @"code_type" ],
        @"planType": @[ @"planType", @"plan_type" ],
    };
}

- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    if ([self.codeType isKindOfClass:NSString.class]) {
        self.codeType = [[self.codeType stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    }
    if ([self.appleProductId isKindOfClass:NSString.class]) {
        self.appleProductId = [self.appleProductId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    id rawPlanId = dic[@"planId"] ?: dic[@"plan_id"];
    if ([rawPlanId isKindOfClass:NSNumber.class]) {
        self.planId = [(NSNumber *)rawPlanId stringValue];
    } else if ([rawPlanId isKindOfClass:NSString.class]) {
        self.planId = [rawPlanId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    // YYModel 对 BOOL 缺省可能是 NO；若后端未下发 needPayment，按 appleProductId 兜底
    id rawNeed = dic[@"needPayment"] ?: dic[@"need_payment"];
    if (rawNeed == nil) {
        self.needPayment = self.appleProductId.length > 0;
    }
    return YES;
}
@end
