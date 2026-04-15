//
//  Passport.m
//  footBall
//
//  对应后端轻量版 PassportVO（仅含 userId + 邮票分类展示）。
//

#import "Passport.h"

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
    return @{ @"categoryId": @[ @"categoryId", @"id" ] };
}
@end

@implementation PNPassport
+ (NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass {
    return @{ @"categories": PNPassportCategoryStamps.class };
}
+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{ @"userId": @[ @"userId", @"id" ] };
}
@end
