//
//  PNAppVersionInfo.m
//  footBall
//

#import "PNAppVersionInfo.h"

NSString * const PNAppVersionOutdatedErrorCode = @"000007";
NSString * const PNAppVersionForceUpdateRequiredNotification = @"PNAppVersionForceUpdateRequiredNotification";

@implementation PNAppVersionInfo

+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"forceUpdate": @[@"forceUpdate", @"force_update"],
        @"clientVersion": @[@"clientVersion", @"client_version"],
        @"clientBuild": @[@"clientBuild", @"client_build"],
        @"minVersion": @[@"minVersion", @"min_version"],
        @"latestVersion": @[@"latestVersion", @"latest_version"],
        @"updateTitle": @[@"updateTitle", @"update_title"],
        @"updateMessage": @[@"updateMessage", @"update_message"],
        @"storeUrl": @[@"storeUrl", @"store_url"],
    };
}

@end
