//
//  PassportNestedModels.m
//  footBall
//

#import "PassportNestedModels.h"

static NSString * _Nullable PNPassportNestedStringFromJson(id v) {
    if (!v || v == (id)kCFNull) {
        return nil;
    }
    if ([v isKindOfClass:NSString.class]) {
        return (NSString *)v;
    }
    if ([v isKindOfClass:NSNumber.class]) {
        return [(NSNumber *)v stringValue];
    }
    return [v description];
}

@implementation PNCountryHeatmap
@end

@implementation PNDisciplineStats
@end

@implementation PNPassportTeamRecord
@end

@implementation PNLocationDist
@end

@implementation PNStandDist
@end

@implementation PNIdentityDist
- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    id p = dic[@"percentage"];
    if (p) {
        self.percentage = PNPassportNestedStringFromJson(p);
    }
    return YES;
}
@end

@implementation PNEmotionDist
@end

@implementation PNOnlineMethodDist
- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    id p = dic[@"percentage"];
    if (p) {
        self.percentage = PNPassportNestedStringFromJson(p);
    }
    return YES;
}
@end

@implementation PNStampShort
+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{ @"stampId": @[ @"stampId", @"id" ] };
}
@end

@implementation PNStampCategoryShort
+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{ @"categoryId": @[ @"categoryId", @"id" ] };
}
@end
