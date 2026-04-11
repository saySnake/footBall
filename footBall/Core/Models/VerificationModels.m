//
//  VerificationModels.m
//  footBall
//

#import "VerificationModels.h"
#import <YYModel/YYModel.h>

@implementation PNVerificationStatus

+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{
        @"professionalStatus": @[ @"professionalStatus", @"professional_status", @"professionalCertStatus" ],
        @"realnameStatus": @[ @"realnameStatus", @"real_name_status", @"realNameStatus", @"idCardStatus" ],
        @"professionalNearExpiry": @[ @"professionalNearExpiry", @"professional_near_expiry" ],
        @"realnameNearExpiry": @[ @"realnameNearExpiry", @"realname_near_expiry" ],
    };
}

- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    if (self.professionalStatus.length == 0) {
        NSDictionary *p = dic[@"professional"];
        if (![p isKindOfClass:NSDictionary.class]) {
            p = dic[@"professionalCert"];
        }
        if ([p isKindOfClass:NSDictionary.class]) {
            NSString *st = p[@"status"] ?: p[@"state"];
            if (st.length) {
                self.professionalStatus = st;
            }
        }
    }
    if (self.realnameStatus.length == 0) {
        NSDictionary *r = dic[@"realName"] ?: dic[@"realname"] ?: dic[@"idCard"];
        if ([r isKindOfClass:NSDictionary.class]) {
            NSString *st = r[@"status"] ?: r[@"state"];
            if (st.length) {
                self.realnameStatus = st;
            }
        }
    }
    return YES;
}

@end

@implementation PNRealnameInfo
@end

@implementation PNVerificationHistory
+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{ @"historyId": @[ @"id", @"historyId" ] };
}
@end
