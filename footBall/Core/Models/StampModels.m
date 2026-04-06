//
//  StampModels.m
//  footBall
//

#import "StampModels.h"

@implementation PNStampAlbumItem
+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{ @"stampId": @[ @"stampId", @"id" ] };
}

 -(BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    // 后端 stampId 可能是 number，这里统一转成 string 便于路径拼接与 UI 展示。
    id v = dic[@"stampId"] ?: dic[@"id"];
    if ([v isKindOfClass:NSNumber.class]) {
        self.stampId = [(NSNumber *)v stringValue];
    } else if ([v isKindOfClass:NSString.class]) {
        self.stampId = (NSString *)v;
    }
    return YES;
}
@end

@implementation PNStampCategorySection
+ (NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass {
    return @{ @"stamps": PNStampAlbumItem.class };
}
+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{ @"categoryId": @[ @"categoryId", @"id" ] };
}

 -(BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    // categoryId 可能为 number，统一转为 string
    id v = dic[@"categoryId"] ?: dic[@"id"];
    if ([v isKindOfClass:NSNumber.class]) {
        self.categoryId = [(NSNumber *)v stringValue];
    } else if ([v isKindOfClass:NSString.class]) {
        self.categoryId = (NSString *)v;
    }
    return YES;
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

 -(BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    id v = dic[@"stampId"] ?: dic[@"id"];
    if ([v isKindOfClass:NSNumber.class]) {
        self.stampId = [(NSNumber *)v stringValue];
    } else if ([v isKindOfClass:NSString.class]) {
        self.stampId = (NSString *)v;
    }
    return YES;
}
@end

@implementation PNStampDetail
+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{ @"stampId": @[ @"stampId", @"id" ],
              @"stampDescription": @[ @"description", @"desc" ] };
}

 -(BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    id v = dic[@"stampId"] ?: dic[@"id"];
    if ([v isKindOfClass:NSNumber.class]) {
        self.stampId = [(NSNumber *)v stringValue];
    } else if ([v isKindOfClass:NSString.class]) {
        self.stampId = (NSString *)v;
    }
    return YES;
}
@end
