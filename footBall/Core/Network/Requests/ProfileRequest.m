#import "ProfileRequest.h"

@implementation ProfileRequest
+ (instancetype)shared {
    static ProfileRequest *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = ProfileRequest.alloc.init;
    });
    return instance;
}

- (void)getMyPassportWithYear:(NSString *)year success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    NSMutableDictionary *params = NSMutableDictionary.dictionary;
    if (year.length > 0) {
        params[@"year"] = year;
    }
    [[APIManager sharedManager] GET:APIPathValuePassportMe parameters:params headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            PNPassport *passport = [PNPassport yy_modelWithJSON:responseObject.data];
            responseObject.dataObject = passport;
            success(responseObject);
        } else {
            failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];
}

- (void)getMyStatisticsWithPeriod:(NSString *)period success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    NSString *safePeriod = period.length > 0 ? period : @"all";
    [[APIManager sharedManager] GET:APIPathValueStatisticsMe parameters:@{@"period": safePeriod} headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            PNStatistics *statistics = [PNStatistics yy_modelWithJSON:responseObject.data];
            responseObject.dataObject = statistics;
            success(responseObject);
        } else {
            failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];
}

- (void)getLeaderboardWithPeriod:(NSString *)period page:(NSInteger)page pageSize:(NSInteger)pageSize success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    NSString *safePeriod = period.length > 0 ? period : @"week";
    NSDictionary *params = @{@"period": safePeriod,
                             @"pageNum": @(MAX(page, 1)),
                             @"pageSize": @(MAX(pageSize, 1))};
    [[APIManager sharedManager] GET:APIPathValueLeaderboard parameters:params headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            PNLeaderboard *leaderboard = [PNLeaderboard yy_modelWithJSON:responseObject.data];
            responseObject.dataObject = leaderboard;
            success(responseObject);
        } else {
            failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];
}
@end
