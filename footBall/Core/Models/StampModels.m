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

@implementation PNStampCategory
+ (NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass {
    return @{ @"stamps": PNStampAlbumItem.class };
}
+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{
        @"categoryId": @[ @"categoryId", @"id" ],
        @"categoryName": @[ @"categoryName", @"categoryName", @"name" ],
        @"categoryIcon": @[ @"categoryIcon", @"categoryIcon", @"icon" ],
    };
}
-(BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    id v = dic[@"categoryId"] ?: dic[@"id"];
    if ([v isKindOfClass:NSNumber.class]) {
        self.categoryId = [(NSNumber *)v stringValue];
    } else if ([v isKindOfClass:NSString.class]) {
        self.categoryId = (NSString *)v;
    }
    return YES;
}
@end

@implementation PNStampQuota
@end

