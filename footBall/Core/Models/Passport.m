//
//  Passport.m
//  footBall
//

#import "Passport.h"
#import "Team.h"

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

@end
