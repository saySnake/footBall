//
//  MatchRequest.m
//  footBall
//
//  Created by LWJ on 2026/3/22.
//

#import "MatchRequest.h"

@implementation MatchRequest
+(instancetype)shared {
    static MatchRequest *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = MatchRequest.alloc.init;
    });
    return instance;
}

- (void)getFeaturesMatchsSuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    [[APIManager sharedManager] GET:APIPathValueMatchFeatured parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            NSArray *teams = [NSArray yy_modelArrayWithClass:Match.class json:responseObject.data];
            responseObject.dataObject = teams;
            success(responseObject);
        } else {
            failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];
}

- (void)getMatchScheduleWithDate:(NSString *)date
                       myTeamOnly:(BOOL)myTeamOnly
                             page:(NSInteger)page
                         pageSize:(NSInteger)pageSize
                          success:(APISuccessBlock)success
                          failure:(APIFailureBlock)failure {
    NSMutableDictionary *params = NSMutableDictionary.dictionary;
    if (date.length > 0) {
        params[@"date"] = date;
    }
    params[@"myTeamOnly"] = @(myTeamOnly);
    params[@"pageNum"] = @(MAX(page, 1));
    params[@"pageSize"] = @(MAX(pageSize, 1));
    [[APIManager sharedManager] GET:APIPathValueMatchSchedule parameters:params headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            NSArray *list = responseObject.data[@"list"];
            if (![list isKindOfClass:NSArray.class]) {
                list = [responseObject.data isKindOfClass:NSArray.class] ? responseObject.data : @[];
            }
            NSArray *matches = [NSArray yy_modelArrayWithClass:Match.class json:list];
            responseObject.dataObject = matches;
            success(responseObject);
        } else {
            failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];
}

- (void)getMyTeamMatchesWithPage:(NSInteger)page pageSize:(NSInteger)pageSize success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    NSDictionary *params = @{@"pageNum": @(MAX(page, 1)),
                             @"pageSize": @(MAX(pageSize, 1))};
    [[APIManager sharedManager] GET:APIPathValueMatchMyTeams parameters:params headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            NSArray *list = responseObject.data[@"list"];
            if (![list isKindOfClass:NSArray.class]) {
                list = [responseObject.data isKindOfClass:NSArray.class] ? responseObject.data : @[];
            }
            NSArray *matches = [NSArray yy_modelArrayWithClass:Match.class json:list];
            responseObject.dataObject = matches;
            success(responseObject);
        } else {
            failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];
}

- (void)getFavoriteMatchesWithPage:(NSInteger)page pageSize:(NSInteger)pageSize success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    NSDictionary *params = @{@"pageNum": @(MAX(page, 1)),
                             @"pageSize": @(MAX(pageSize, 1))};
    [[APIManager sharedManager] GET:APIPathValueMatchGetFavorites parameters:params headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            NSArray *list = responseObject.data[@"list"];
            if (![list isKindOfClass:NSArray.class]) {
                list = [responseObject.data isKindOfClass:NSArray.class] ? responseObject.data : @[];
            }
            NSArray *matches = [NSArray yy_modelArrayWithClass:Match.class json:list];
            responseObject.dataObject = matches;
            success(responseObject);
        } else {
            failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];
}

- (void)getMatchDetail:(NSString *)matchId success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (matchId.length == 0) {
        if (failure) {
            failure([NSError errorWithDomain:@"MatchRequestErrorDomain" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"比赛ID不能为空"}]);
        }
        return;
    }
    [[APIManager sharedManager] GET:APIPathValueMatchDetail(matchId) parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            MatchDetail *match = [MatchDetail yy_modelWithJSON:responseObject.data];
            responseObject.dataObject = match;
            success(responseObject);
        } else {
            failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];
}
@end
