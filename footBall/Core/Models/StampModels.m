//
//  StampModels.m
//  footBall
//

#import "StampModels.h"

@implementation PNStampAlbumItem
+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{
        @"stampId": @[ @"stampId", @"id" ],
        @"displayStatus": @[ @"displayStatus", @"display_status" ],
        @"acquiredTime": @[ @"acquiredTime", @"acquired_time" ],
        @"isNew": @[ @"isNew", @"is_new" ],
    };
}

- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    // 后端 stampId 可能是 number，统一转成 string
    id v = dic[@"stampId"] ?: dic[@"id"];
    if ([v isKindOfClass:NSNumber.class]) {
        self.stampId = [(NSNumber *)v stringValue];
    } else if ([v isKindOfClass:NSString.class]) {
        self.stampId = (NSString *)v;
    }
    if ([self.displayStatus isKindOfClass:NSString.class]) {
        self.displayStatus = [[self.displayStatus stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    }
    if ([self.source isKindOfClass:NSString.class]) {
        self.source = [[self.source stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    }
    return YES;
}

- (BOOL)isDisplayedOnHome {
    return [self.displayStatus isEqualToString:@"VISIBLE"];
}
@end

@implementation PNStampCategory
+ (NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass {
    return @{ @"stamps": PNStampAlbumItem.class };
}
+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{
        @"categoryId": @[ @"categoryId", @"id" ],
        @"categoryName": @[ @"categoryName", @"name" ],
        @"categoryIcon": @[ @"categoryIcon", @"icon" ],
        @"totalCount": @[ @"totalCount", @"total_count" ],
        @"collectedCount": @[ @"collectedCount", @"collected_count" ],
    };
}
- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    id v = dic[@"categoryId"] ?: dic[@"id"];
    if ([v isKindOfClass:NSNumber.class]) {
        self.categoryId = [(NSNumber *)v stringValue];
    } else if ([v isKindOfClass:NSString.class]) {
        self.categoryId = (NSString *)v;
    }
    return YES;
}
@end
