//
//  ProfileRequest.m
//  footBall
//
//  护照/统计/排行榜；他人护照与观赛记录列表暂透传 data，便于后续接专用 Model。
//

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
    [self getMyPassportWithYear:year bypassCache:NO success:success failure:failure];
}

- (void)getMyPassportWithYear:(NSString *)year bypassCache:(BOOL)bypassCache success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    NSMutableDictionary *params = NSMutableDictionary.dictionary;
    if (year.length > 0) {
        params[@"year"] = year;
    }
    if (bypassCache) {
        params[@"_refresh"] = @((long long)([NSDate date].timeIntervalSince1970 * 1000));
    }
    [[APIManager sharedManager] GET:APIPathValuePassportMe parameters:params headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            // PassportVO 已重构为轻量版（userId + categories），统计数据在 StatisticsVO
            PNPassport *passport = [PNPassport yy_modelWithJSON:responseObject.data];
            responseObject.dataObject = passport ?: responseObject.data;
            success(responseObject);
        } else {
            failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];
}

- (void)getPassportForUserId:(NSString *)userId year:(NSString *)year success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (userId.length == 0) {
        if (failure) failure([NSError errorWithDomain:@"ProfileRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"用户ID不能为空" }]);
        return;
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (year.length > 0) {
        params[@"year"] = year;
    }
    [[APIManager sharedManager] GET:APIPathValuePassportUser(userId) parameters:params headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            // PassportVO 已重构为轻量版（userId + categories）
            PNPassport *passport = [PNPassport yy_modelWithJSON:responseObject.data];
            responseObject.dataObject = passport ?: responseObject.data;
            if (success) success(responseObject);
        } else {
            if (failure) failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

- (void)getMyPassportMatchRecordsWithYear:(nullable NSString *)year
                                      tab:(nullable NSString *)tab
                                   status:(nullable NSString *)status
                                     page:(NSInteger)page
                                 pageSize:(NSInteger)pageSize
                                  success:(APISuccessBlock)success
                                  failure:(APIFailureBlock)failure {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (year.length > 0) {
        params[@"year"] = year;
    }
    if (tab.length > 0) {
        params[@"tab"] = tab;
    }
    if (status.length > 0) {
        params[@"status"] = status;
    }
    params[@"pageNum"] = @(MAX(page, 1));
    params[@"pageSize"] = @(MAX(pageSize, 1));
    [[APIManager sharedManager] GET:APIPathValuePassportMeRecords parameters:params headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            responseObject.dataObject = responseObject.data;
            if (success) success(responseObject);
        } else {
            if (failure) failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

- (void)getMyStatisticsWithPeriod:(NSString *)period success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    [self getMyStatisticsWithPeriod:period bypassCache:NO success:success failure:failure];
}

- (void)getMyStatisticsWithPeriod:(NSString *)period bypassCache:(BOOL)bypassCache success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    NSString *safePeriod = period.length > 0 ? period : @"all";
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:safePeriod forKey:@"period"];
    if (bypassCache) {
        params[@"_refresh"] = @((long long)([NSDate date].timeIntervalSince1970 * 1000));
    }
    [[APIManager sharedManager] GET:APIPathValueStatisticsMe parameters:params headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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
