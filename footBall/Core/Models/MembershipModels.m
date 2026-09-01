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
+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    // YYModel 对 BOOL isXxx 默认按「去掉 is」去 JSON 里找 key（找 member），
    // 会导致服务端的 isMember 永远解成 NO，会员中心 banner 一直显示兑换码文案。
    return @{
        @"isMember": @[ @"isMember", @"member", @"active" ],
        @"nearExpiry": @[ @"nearExpiry", @"near_expiry" ],
        @"levelName": @[ @"levelName", @"level_name" ],
        @"expireTime": @[ @"expireTime", @"expire_time" ],
    };
}

- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    id rawMember = dic[@"isMember"] ?: dic[@"member"] ?: dic[@"active"];
    if ([rawMember isKindOfClass:NSNumber.class]) {
        self.isMember = [(NSNumber *)rawMember boolValue];
    } else if ([rawMember isKindOfClass:NSString.class]) {
        NSString *s = [(NSString *)rawMember lowercaseString];
        self.isMember = ([s isEqualToString:@"1"] || [s isEqualToString:@"true"] || [s isEqualToString:@"yes"]);
    }

    id rawNear = dic[@"nearExpiry"] ?: dic[@"near_expiry"];
    if ([rawNear isKindOfClass:NSNumber.class]) {
        self.nearExpiry = [(NSNumber *)rawNear boolValue];
    } else if ([rawNear isKindOfClass:NSString.class]) {
        NSString *s = [(NSString *)rawNear lowercaseString];
        self.nearExpiry = ([s isEqualToString:@"1"] || [s isEqualToString:@"true"] || [s isEqualToString:@"yes"]);
    }

    // LocalDateTime 可能是 ISO 字符串，也可能被序列成数组 [y,m,d,h,m,s]
    id rawExpire = dic[@"expireTime"] ?: dic[@"expire_time"];
    if ([rawExpire isKindOfClass:NSString.class]) {
        NSString *s = [(NSString *)rawExpire stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        // "2026-09-28T20:54:14" → 展示用前 10 位即可，保留完整串给模型
        self.expireTime = s;
    } else if ([rawExpire isKindOfClass:NSArray.class] && [(NSArray *)rawExpire count] >= 3) {
        NSArray *a = (NSArray *)rawExpire;
        self.expireTime = [NSString stringWithFormat:@"%04ld-%02ld-%02ld",
                           (long)[a[0] integerValue], (long)[a[1] integerValue], (long)[a[2] integerValue]];
    }
    return YES;
}
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

- (NSString *)normalizedDateTimeStringFromRaw:(id)raw {
    if ([raw isKindOfClass:NSString.class]) {
        return [(NSString *)raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    if ([raw isKindOfClass:NSArray.class] && [(NSArray *)raw count] >= 3) {
        NSArray *a = (NSArray *)raw;
        if ([(NSArray *)raw count] >= 6) {
            return [NSString stringWithFormat:@"%04ld-%02ld-%02ldT%02ld:%02ld:%02ld",
                    (long)[a[0] integerValue], (long)[a[1] integerValue], (long)[a[2] integerValue],
                    (long)[a[3] integerValue], (long)[a[4] integerValue], (long)[a[5] integerValue]];
        }
        return [NSString stringWithFormat:@"%04ld-%02ld-%02ld",
                (long)[a[0] integerValue], (long)[a[1] integerValue], (long)[a[2] integerValue]];
    }
    return nil;
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
    id rawOriginal = dic[@"originalPrice"] ?: dic[@"original_price"];
    if ([rawOriginal isKindOfClass:NSNumber.class]) {
        self.originalPrice = [NSString stringWithFormat:@"%g", [(NSNumber *)rawOriginal doubleValue]];
    }
    id rawDiscount = dic[@"discountPrice"] ?: dic[@"discount_price"];
    if ([rawDiscount isKindOfClass:NSNumber.class]) {
        self.discountPrice = [NSString stringWithFormat:@"%g", [(NSNumber *)rawDiscount doubleValue]];
    }
    NSString *activate = [self normalizedDateTimeStringFromRaw:(dic[@"activateTime"] ?: dic[@"activate_time"])];
    if (activate.length > 0) self.activateTime = activate;
    NSString *expire = [self normalizedDateTimeStringFromRaw:(dic[@"expireTime"] ?: dic[@"expire_time"])];
    if (expire.length > 0) self.expireTime = expire;
    // YYModel 对 BOOL 缺省可能是 NO；若后端未下发 needPayment，按 appleProductId 兜底
    id rawNeed = dic[@"needPayment"] ?: dic[@"need_payment"];
    if (rawNeed == nil) {
        self.needPayment = self.appleProductId.length > 0;
    } else if ([rawNeed isKindOfClass:NSNumber.class]) {
        self.needPayment = [(NSNumber *)rawNeed boolValue];
    } else if ([rawNeed isKindOfClass:NSString.class]) {
        NSString *s = [(NSString *)rawNeed lowercaseString];
        self.needPayment = ([s isEqualToString:@"1"] || [s isEqualToString:@"true"] || [s isEqualToString:@"yes"]);
    }
    return YES;
}
@end
