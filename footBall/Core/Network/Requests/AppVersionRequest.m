//
//  AppVersionRequest.m
//  footBall
//

#import "AppVersionRequest.h"
#import "APIPathValues.h"
#import "PNAppVersionInfo.h"
#import "APIError.h"

@implementation AppVersionRequest

+ (instancetype)shared {
    static AppVersionRequest *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AppVersionRequest alloc] init];
    });
    return instance;
}

- (void)checkVersionSuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    NSBundle *bundle = NSBundle.mainBundle;
    NSString *version = bundle.infoDictionary[@"CFBundleShortVersionString"] ?: @"0";
    NSString *build = bundle.infoDictionary[@"CFBundleVersion"] ?: @"0";
    NSDictionary *params = @{
        @"platform": @"ios",
        @"version": version,
        @"build": build,
    };
    [[APIManager sharedManager] GET:APIPathValueAppVersionCheck
                         parameters:params
                            headers:nil
                            success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            PNAppVersionInfo *info = [PNAppVersionInfo yy_modelWithJSON:responseObject.data];
            responseObject.dataObject = info ?: responseObject.data;
            if (success) success(responseObject);
        } else {
            if (failure) failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

@end
