//
//  MatchRequest.m
//  footBall
//
//  实现见 MatchRequest.h；列表类接口在成功时尽量解析为 Match / MatchDetail，
//  Nami 与观赛记录等无统一 Model 时 `dataObject` 等同 `data`。
//

#import "MatchRequest.h"

@implementation MatchRequest

+ (instancetype)shared {
    static MatchRequest *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[MatchRequest alloc] init];
    });
    return instance;
}

#pragma mark - 首页 / 日程

- (void)getFeaturesMatchsSuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    [[APIManager sharedManager] GET:APIPathValueMatchFeatured parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            NSArray *teams = [NSArray yy_modelArrayWithClass:Match.class json:responseObject.data];
            responseObject.dataObject = teams;
            if (success) success(responseObject);
        } else {
            if (failure) failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

- (void)getMatchScheduleWithDate:(NSString *)date
                       myTeamOnly:(BOOL)myTeamOnly
                             page:(NSInteger)page
                         pageSize:(NSInteger)pageSize
                          success:(APISuccessBlock)success
                          failure:(APIFailureBlock)failure {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
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
            if (success) success(responseObject);
        } else {
            if (failure) failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

- (void)getMatchScheduleDatesWithMonth:(NSString *)month success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (month.length > 0) {
        params[@"month"] = month;
    }
    [[APIManager sharedManager] GET:APIPathValueMatchScheduleDates parameters:params headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

#pragma mark - 比赛检索 / 详情 / 收藏

- (void)searchMatchesWithKeyword:(NSString *)keyword
                        leagueId:(NSString *)leagueId
                            page:(NSInteger)page
                        pageSize:(NSInteger)pageSize
                         success:(APISuccessBlock)success
                         failure:(APIFailureBlock)failure {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"keyword"] = keyword.length > 0 ? keyword : @"";
    if (leagueId.length > 0) {
        params[@"leagueId"] = leagueId;
    }
    params[@"pageNum"] = @(MAX(page, 1));
    params[@"pageSize"] = @(MAX(pageSize, 1));
    [[APIManager sharedManager] GET:APIPathValueMatchSearch parameters:params headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            id raw = responseObject.data;
            id jsonList = nil;
            if ([raw isKindOfClass:NSArray.class]) {
                jsonList = raw;
            } else if ([raw isKindOfClass:NSDictionary.class]) {
                NSDictionary *d = (NSDictionary *)raw;
                jsonList = d[@"list"] ?: d[@"matches"] ?: d[@"data"];
            }
            NSArray *matches = [jsonList isKindOfClass:NSArray.class]
                ? [NSArray yy_modelArrayWithClass:Match.class json:jsonList]
                : @[];
            responseObject.dataObject = matches;
            if (success) success(responseObject);
        } else {
            if (failure) failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

- (void)getMatchCalendarWithYear:(NSInteger)year month:(NSInteger)month success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    NSDictionary *params = @{ @"year": @(year), @"month": @(MAX(1, MIN(12, month))) };
    [[APIManager sharedManager] GET:APIPathValueMatchCalendar parameters:params headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)getMatchDetail:(NSString *)matchId success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (matchId.length == 0) {
        if (failure) {
            failure([NSError errorWithDomain:@"MatchRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"比赛ID不能为空" }]);
        }
        return;
    }
    [[APIManager sharedManager] GET:APIPathValueMatchDetail(matchId) parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            MatchDetail *match = [MatchDetail yy_modelWithJSON:responseObject.data];
            responseObject.dataObject = match;
            if (success) success(responseObject);
        } else {
            if (failure) failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

- (void)getMyTeamMatchesWithPage:(NSInteger)page pageSize:(NSInteger)pageSize success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    NSDictionary *params = @{ @"pageNum": @(MAX(page, 1)), @"pageSize": @(MAX(pageSize, 1)) };
    [[APIManager sharedManager] GET:APIPathValueMatchMyTeams parameters:params headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            NSArray *list = responseObject.data[@"list"];
            if (![list isKindOfClass:NSArray.class]) {
                list = [responseObject.data isKindOfClass:NSArray.class] ? responseObject.data : @[];
            }
            NSArray *matches = [NSArray yy_modelArrayWithClass:Match.class json:list];
            responseObject.dataObject = matches;
            if (success) success(responseObject);
        } else {
            if (failure) failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

- (void)favoriteMatch:(NSString *)matchId success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (matchId.length == 0) {
        if (failure) failure([NSError errorWithDomain:@"MatchRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"比赛ID不能为空" }]);
        return;
    }
    [[APIManager sharedManager] POST:APIPathValueMatchFavorite(matchId) parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)unfavoriteMatch:(NSString *)matchId success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (matchId.length == 0) {
        if (failure) failure([NSError errorWithDomain:@"MatchRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"比赛ID不能为空" }]);
        return;
    }
    [[APIManager sharedManager] DELETE:APIPathValueMatchFavorite(matchId) parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)getFavoriteMatchesWithPage:(NSInteger)page pageSize:(NSInteger)pageSize success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    NSDictionary *params = @{ @"pageNum": @(MAX(page, 1)), @"pageSize": @(MAX(pageSize, 1)) };
    [[APIManager sharedManager] GET:APIPathValueMatchGetFavorites parameters:params headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            NSArray *list = responseObject.data[@"list"];
            if (![list isKindOfClass:NSArray.class]) {
                list = [responseObject.data isKindOfClass:NSArray.class] ? responseObject.data : @[];
            }
            NSArray *matches = [NSArray yy_modelArrayWithClass:Match.class json:list];
            responseObject.dataObject = matches;
            if (success) success(responseObject);
        } else {
            if (failure) failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

#pragma mark - Nami

- (void)getNamiScheduleWithDate:(NSString *)date page:(NSInteger)page pageSize:(NSInteger)pageSize success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (date.length > 0) {
        params[@"date"] = date;
    }
    params[@"pageNum"] = @(MAX(page, 1));
    params[@"pageSize"] = @(MAX(pageSize, 1));
    [[APIManager sharedManager] GET:APIPathValueMatchNamiSchedule parameters:params headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)getNamiLiveMatchesSuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    [[APIManager sharedManager] GET:APIPathValueMatchNamiLive parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)getNamiMatchDetail:(NSString *)matchId success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (matchId.length == 0) {
        if (failure) failure([NSError errorWithDomain:@"MatchRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"比赛ID不能为空" }]);
        return;
    }
    [[APIManager sharedManager] GET:APIPathValueMatchNamiDetail(matchId) parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)getNamiMatchLiveData:(NSString *)matchId success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (matchId.length == 0) {
        if (failure) failure([NSError errorWithDomain:@"MatchRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"比赛ID不能为空" }]);
        return;
    }
    [[APIManager sharedManager] GET:APIPathValueMatchNamiLiveDetail(matchId) parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)getNamiMatchTrend:(NSString *)matchId success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (matchId.length == 0) {
        if (failure) failure([NSError errorWithDomain:@"MatchRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"比赛ID不能为空" }]);
        return;
    }
    [[APIManager sharedManager] GET:APIPathValueMatchNamiTrend(matchId) parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)getNamiMatchLineup:(NSString *)matchId success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (matchId.length == 0) {
        if (failure) failure([NSError errorWithDomain:@"MatchRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"比赛ID不能为空" }]);
        return;
    }
    [[APIManager sharedManager] GET:APIPathValueMatchNamiLineup(matchId) parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)getNamiMatchPlayerStats:(NSString *)matchId success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (matchId.length == 0) {
        if (failure) failure([NSError errorWithDomain:@"MatchRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"比赛ID不能为空" }]);
        return;
    }
    [[APIManager sharedManager] GET:APIPathValueMatchNamiPlayerStats(matchId) parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)getNamiMatchStreamWithMatchId:(NSString *)matchId success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (matchId.length == 0) {
        if (failure) failure([NSError errorWithDomain:@"MatchRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"比赛ID不能为空" }]);
        return;
    }
    [[APIManager sharedManager] GET:APIPathValueMatchNamiStream(matchId) parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)getNamiMatchVideosWithMatchId:(NSString *)matchId success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (matchId.length == 0) {
        if (failure) failure([NSError errorWithDomain:@"MatchRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"比赛ID不能为空" }]);
        return;
    }
    [[APIManager sharedManager] GET:APIPathValueMatchNamiVideos(matchId) parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

#pragma mark - 观赛记录

- (void)createMatchRecordWithBody:(NSDictionary *)body success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (![body isKindOfClass:NSDictionary.class] || body.count == 0) {
        if (failure) failure([NSError errorWithDomain:@"MatchRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"请求体不能为空" }]);
        return;
    }
    [[APIManager sharedManager] POST:APIPathValueMatchRecordsCreate parameters:body headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)updateMatchRecord:(NSString *)recordId body:(NSDictionary *)body success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (recordId.length == 0) {
        if (failure) failure([NSError errorWithDomain:@"MatchRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"recordId不能为空" }]);
        return;
    }
    if (![body isKindOfClass:NSDictionary.class]) {
        if (failure) failure([NSError errorWithDomain:@"MatchRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"请求体无效" }]);
        return;
    }
    [[APIManager sharedManager] PUT:APIPathValueMatchRecordsUpdate(recordId) parameters:body headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)getMatchRecordDetail:(NSString *)recordId success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (recordId.length == 0) {
        if (failure) failure([NSError errorWithDomain:@"MatchRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"recordId不能为空" }]);
        return;
    }
    [[APIManager sharedManager] GET:APIPathValueMatchRecordDetail(recordId) parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

#pragma mark - 比赛互动

- (void)likeMatch:(NSString *)matchId success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (matchId.length == 0) {
        if (failure) failure([NSError errorWithDomain:@"MatchRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"比赛ID不能为空" }]);
        return;
    }
    [[APIManager sharedManager] POST:APIPathValueMatchInteractionsLike(matchId) parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)unlikeMatch:(NSString *)matchId success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (matchId.length == 0) {
        if (failure) failure([NSError errorWithDomain:@"MatchRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"比赛ID不能为空" }]);
        return;
    }
    [[APIManager sharedManager] DELETE:APIPathValueMatchInteractionsLike(matchId) parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)recordMatchView:(NSString *)matchId success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (matchId.length == 0) {
        if (failure) failure([NSError errorWithDomain:@"MatchRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"比赛ID不能为空" }]);
        return;
    }
    [[APIManager sharedManager] POST:APIPathValueMatchInteractionsView(matchId) parameters:@{} headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

#pragma mark - 比赛认证

- (void)verifyMatchRecord:(NSString *)recordId body:(NSDictionary *)body success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (recordId.length == 0) {
        if (failure) failure([NSError errorWithDomain:@"MatchRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"recordId不能为空" }]);
        return;
    }
    id params = body ?: @{};
    [[APIManager sharedManager] POST:APIPathValueMatchRecordVerify(recordId) parameters:params headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

@end
