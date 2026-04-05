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

- (void)getMyPassportMatchRecordsWithPage:(NSInteger)page pageSize:(NSInteger)pageSize success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    NSDictionary *params = @{ @"pageNum": @(MAX(page, 1)), @"pageSize": @(MAX(pageSize, 1)) };
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
