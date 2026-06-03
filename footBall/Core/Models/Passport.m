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

@implementation PNPassportStampItem
+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{ @"stampId": @[ @"stampId", @"id" ] };
}
@end

@implementation PNPassportCategoryStamps
+ (NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass {
    return @{ @"stamps": PNPassportStampItem.class };
}
+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{ @"categoryId": @[ @"categoryId", @"id" ],
              @"categoryName": @[ @"categoryName", @"name" ] };
}
@end

@implementation PNPassport

+ (NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass {
    return @{
        @"followedTeams": TeamIcon.class,
        @"recentStamps": PNStampShort.class,
        @"stampCategories": PNStampCategoryShort.class,
        @"categories": PNPassportCategoryStamps.class,
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
    return @{
        @"userId": @[ @"userId", @"id" ],
        @"yearTotalWatchTime": @[ @"yearTotalWatchTime", @"year_total_watch_time" ],
        @"careerTotalWatchTime": @[ @"careerTotalWatchTime", @"career_total_watch_time" ],
    };
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
    id af = dic[@"averageFloor"];
    if (af) {
        self.averageFloor = PNPassportStringFromJson(af);
    }
    return YES;
}

@end
