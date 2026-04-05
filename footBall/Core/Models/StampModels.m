//
//  StampModels.m
//  footBall
//

#import "StampModels.h"

@implementation PNStampAlbumItem
+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{ @"stampId": @[ @"stampId", @"id" ] };
}
@end

@implementation PNStampCategorySection
+ (NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass {
    return @{ @"stamps": PNStampAlbumItem.class };
}
+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{ @"categoryId": @[ @"categoryId", @"id" ] };
}
@end

@implementation PNStampCollection
+ (NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass {
    return @{ @"categories": PNStampCategorySection.class };
}
@end

@implementation PNStampCategory
+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{ @"categoryId": @[ @"categoryId", @"id" ] };
}
@end

@implementation PNStampGridItem
+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{ @"stampId": @[ @"stampId", @"id" ],
              @"stampDescription": @[ @"description", @"desc" ] };
}
@end

@implementation PNStampDetail
+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{ @"stampId": @[ @"stampId", @"id" ],
              @"stampDescription": @[ @"description", @"desc" ] };
}
@end
