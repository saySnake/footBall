//
//  PassportNestedModels.m
//  footBall
//

#import "PassportNestedModels.h"

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
@end

@implementation PNEmotionDist
@end

@implementation PNOnlineMethodDist
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
