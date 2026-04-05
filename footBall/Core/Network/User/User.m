//
//  User.m
//  footBall
//
//  Created by LWJ on 2026/3/15.
//

#import "User.h"

@implementation User

- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    if (self.phone.length == 0) {
        id v = dic[@"mobile"] ?: dic[@"phoneNumber"] ?: dic[@"tel"];
        if ([v isKindOfClass:[NSString class]] && [(NSString *)v length] > 0) {
            self.phone = v;
        } else if ([v isKindOfClass:[NSNumber class]]) {
            self.phone = [(NSNumber *)v stringValue];
        }
    }
    return YES;
}

@end
@implementation UserProfile

- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    if (self.phone.length == 0) {
        NSArray<NSString *> *keys = @[ @"phone", @"mobile", @"phoneNumber", @"tel", @"userPhone", @"maskedMobile", @"maskedPhone", @"bindPhone" ];
        for (NSString *k in keys) {
            id v = dic[k];
            if ([v isKindOfClass:[NSString class]] && [(NSString *)v length] > 0) {
                self.phone = v;
                break;
            }
            if ([v isKindOfClass:[NSNumber class]]) {
                self.phone = [(NSNumber *)v stringValue];
                break;
            }
        }
    }
    return YES;
}

@end
