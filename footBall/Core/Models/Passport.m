//
//  Passport.m
//  footBall
//

#import "Passport.h"
#import "Team.h"

static NSInteger PNPassportIntFromJson(id v, NSInteger fallback) {
    if ([v isKindOfClass:NSNumber.class]) {
        return [(NSNumber *)v integerValue];
    }
    if ([v isKindOfClass:NSString.class]) {
        return [(NSString *)v integerValue];
    }
    return fallback;
}

static NSString * _Nullable PNPassportStringFromJson(id v) {
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

@implementation PNPassport

+ (NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass {
    return @{
        @"followedTeams": TeamIcon.class,
        @"recentStamps": PNStampShort.class,
        @"stampCategories": PNStampCategoryShort.class,
        @"countryHeatmap": PNCountryHeatmap.class,
        @"weeklyFrequency": NSNumber.class,
        @"locationDist": PNLocationDist.class,
        @"standDist": PNStandDist.class,
        @"identityDist": PNIdentityDist.class,
        @"emotionDist": PNEmotionDist.class,
        @"onlineMethodDist": PNOnlineMethodDist.class,
    };
}

+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{ @"userId": @[ @"userId", @"id" ] };
}

/// 与当前接口对齐：`yearTotalWatchTime` / `careerTotalWatchTime` 常为字符串；`yearSpending`、`seasonDays`、`awakeWatchPercent` 常为数字。
- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    id ytw = dic[@"yearTotalWatchTime"];
    if (ytw) {
        self.yearTotalWatchTime = PNPassportIntFromJson(ytw, self.yearTotalWatchTime);
    }
    id ctw = dic[@"careerTotalWatchTime"];
    if (ctw) {
        self.careerTotalWatchTime = PNPassportIntFromJson(ctw, self.careerTotalWatchTime);
    }
    id ys = dic[@"yearSpending"];
    if (ys) {
        self.yearSpending = PNPassportStringFromJson(ys);
    }
    id sd = dic[@"seasonDays"];
    if (sd) {
        self.seasonDays = PNPassportStringFromJson(sd);
    }
    id aw = dic[@"awakeWatchPercent"];
    if (aw) {
        self.awakeWatchPercent = PNPassportStringFromJson(aw);
    }
    return YES;
}

@end
