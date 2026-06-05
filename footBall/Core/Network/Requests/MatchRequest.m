//
//  MatchRequest.m
//  footBall
//
//  实现见 MatchRequest.h；列表类接口在成功时尽量解析为 Match / MatchDetail，
//  Nami 与观赛记录等无统一 Model 时 `dataObject` 等同 `data`。
//

#import "MatchRequest.h"
#import "MatchRecordModels.h"

/// 与 Expense 等接口一致：`data` 可能是 `{ list }`、嵌套 `data`、或直接数组
static NSArray *PNMatchJSONArrayFromPageData(id data) {
    if ([data isKindOfClass:NSArray.class]) {
        return (NSArray *)data;
    }
    if (![data isKindOfClass:NSDictionary.class]) {
        return nil;
    }
    NSDictionary *d = (NSDictionary *)data;
    id list = d[@"list"] ?: d[@"records"] ?: d[@"rows"] ?: d[@"matches"] ?: d[@"items"] ?: d[@"featuredMatches"];
    if ([list isKindOfClass:NSArray.class]) {
        return list;
    }
    id inner = d[@"data"];
    if ([inner isKindOfClass:NSArray.class]) {
        return (NSArray *)inner;
    }
    if ([inner isKindOfClass:NSDictionary.class]) {
        NSDictionary *idict = (NSDictionary *)inner;
        id l2 = idict[@"list"] ?: idict[@"records"] ?: idict[@"matches"] ?: idict[@"items"] ?: idict[@"featuredMatches"];
        if ([l2 isKindOfClass:NSArray.class]) {
            return l2;
        }
    }
    return nil;
}

/// /matches/my-team 可能返回 list，或拆分为 upcoming/finished 两段，统一拍平成数组。
static NSArray *PNMatchJSONArrayFromMyTeamData(id data) {
    NSArray *list = PNMatchJSONArrayFromPageData(data);
    if (list) return list;
    if (![data isKindOfClass:NSDictionary.class]) return nil;
    NSDictionary *d = (NSDictionary *)data;
    NSMutableArray *merged = [NSMutableArray array];
    NSArray<NSString *> *keys = @[
        @"upcoming", @"upcomingMatches", @"futureMatches", @"notStartedMatches",
        @"finished", @"finishedMatches", @"pastMatches", @"endedMatches"
    ];
    for (NSString *k in keys) {
        id arr = d[k];
        if ([arr isKindOfClass:NSArray.class]) {
            [merged addObjectsFromArray:(NSArray *)arr];
        } else if ([arr isKindOfClass:NSDictionary.class]) {
            NSArray *inner = PNMatchJSONArrayFromPageData(arr);
            if (inner.count > 0) [merged addObjectsFromArray:inner];
        }
    }
    return merged.count > 0 ? merged : nil;
}

/// upcoming / finished 独立接口：`data` 与分页列表一致，按 `list` 等键解析（不做 upcoming+finished 合并）
static void PNMatchRequestGETMyTeamSegment(NSString *path, NSInteger page, NSInteger pageSize, BOOL bypassCache, APISuccessBlock success, APIFailureBlock failure) {
    NSMutableDictionary *params = [@{ @"pageNum": @(MAX(page, 1)), @"pageSize": @(MAX(pageSize, 1)) } mutableCopy];
    if (bypassCache) {
        params[@"_refresh"] = @((long long)([NSDate date].timeIntervalSince1970 * 1000));
    }
    [[APIManager sharedManager] GET:path parameters:params headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            NSArray *list = PNMatchJSONArrayFromPageData(responseObject.data);
            if (!list) {
                list = @[];
            }
#if DEBUG
            // 打印第一条原始 JSON，确认 verifyCompleted / certifiedMinutes 字段值
            if (list.count > 0) {
                id firstRaw = list[0];
                if ([firstRaw isKindOfClass:NSDictionary.class]) {
                    NSDictionary *d = (NSDictionary *)firstRaw;
                    NSLog(@"[MatchDebug] %@ raw[0] ALL KEYS => %@", path, d.allKeys);
                    NSLog(@"[MatchDebug] %@ raw[0] => verifyCompleted=%@ (%@), certifiedMinutes=%@, verificationStatus=%@, recordId=%@ (%@), matchId=%@",
                          path,
                          d[@"verifyCompleted"], NSStringFromClass([d[@"verifyCompleted"] class]),
                          d[@"certifiedMinutes"],
                          d[@"verificationStatus"],
                          d[@"recordId"], NSStringFromClass([d[@"recordId"] class]),
                          d[@"matchId"]);
                }
            }
#endif
            NSArray *matches = [NSArray yy_modelArrayWithClass:Match.class json:list];
            responseObject.dataObject = matches;
            if (success) {
                success(responseObject);
            }
        } else {
            if (failure) {
                failure([APIError errorWithResponse:responseObject]);
            }
        }
    } failure:^(NSError * _Nonnull error) {
        if (failure) {
            failure(error);
        }
    }];
}

NSString * const PNMatchFavoriteDidUpdateNotification = @"PNMatchFavoriteDidUpdateNotification";

static void PNPostMatchFavoriteDidUpdateNotification(NSString *matchId) {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (matchId.length > 0) {
        userInfo[@"matchId"] = matchId;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:PNMatchFavoriteDidUpdateNotification
                                                        object:nil
                                                      userInfo:userInfo.count > 0 ? [userInfo copy] : nil];
}

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

- (void)getFeaturesMatchsWithTeamId:(NSString *)teamId success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (teamId.length > 0) {
        params[@"teamId"] = teamId;
    }
    [[APIManager sharedManager] GET:APIPathValueMatchFeatured parameters:params.count > 0 ? params : nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            NSArray *list = PNMatchJSONArrayFromPageData(responseObject.data);
            if (!list) {
                list = @[];
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
            NSArray *list = PNMatchJSONArrayFromPageData(responseObject.data);
            if (!list) {
                list = @[];
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

- (void)getMonthUpcomingScheduleWithStartTime:(NSString *)startTime
                                   myTeamOnly:(BOOL)myTeamOnly
                                       teamId:(NSString *)teamId
                                         page:(NSInteger)page
                                     pageSize:(NSInteger)pageSize
                                      success:(APISuccessBlock)success
                                      failure:(APIFailureBlock)failure {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (startTime.length > 0) {
        params[@"startTime"] = startTime;
    }
    params[@"myTeamOnly"] = @(myTeamOnly);
    if (teamId.length > 0) {
        params[@"teamId"] = teamId;
    }
    params[@"pageNum"] = @(MAX(page, 1));
    params[@"pageSize"] = @(MAX(pageSize, 1));
    [[APIManager sharedManager] GET:APIPathValueMatchScheduleMonthUpcoming parameters:params headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            NSArray *list = PNMatchJSONArrayFromPageData(responseObject.data);
            if (!list) {
                list = @[];
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
            NSArray *list = PNMatchJSONArrayFromMyTeamData(responseObject.data);
            if (!list) {
                list = @[];
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

- (void)getMyTeamUpcomingMatchesWithPage:(NSInteger)page pageSize:(NSInteger)pageSize success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    [self getMyTeamUpcomingMatchesWithPage:page pageSize:pageSize bypassCache:NO success:success failure:failure];
}

- (void)getMyTeamUpcomingMatchesWithPage:(NSInteger)page pageSize:(NSInteger)pageSize bypassCache:(BOOL)bypassCache success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    PNMatchRequestGETMyTeamSegment(APIPathValueMatchMyTeamUpcoming, page, pageSize, bypassCache, success, failure);
}

- (void)getMyTeamFinishedMatchesWithPage:(NSInteger)page pageSize:(NSInteger)pageSize success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    [self getMyTeamFinishedMatchesWithPage:page pageSize:pageSize bypassCache:NO success:success failure:failure];
}

- (void)getMyTeamFinishedMatchesWithPage:(NSInteger)page pageSize:(NSInteger)pageSize bypassCache:(BOOL)bypassCache success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    PNMatchRequestGETMyTeamSegment(APIPathValueMatchMyTeamFinished, page, pageSize, bypassCache, success, failure);
}

- (void)favoriteMatch:(NSString *)matchId success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (matchId.length == 0) {
        if (failure) failure([NSError errorWithDomain:@"MatchRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"比赛ID不能为空" }]);
        return;
    }
    // 部分服务端要求 JSON body 非空，传 {} 与 application/json 一致
    [[APIManager sharedManager] POST:APIPathValueMatchFavorite(matchId) parameters:@{} headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            responseObject.dataObject = responseObject.data;
            PNPostMatchFavoriteDidUpdateNotification(matchId);
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
            PNPostMatchFavoriteDidUpdateNotification(matchId);
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
            PNMatchRecordDetail *detail = [PNMatchRecordDetail yy_modelWithJSON:responseObject.data];
            responseObject.dataObject = detail ?: responseObject.data;
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
    [[APIManager sharedManager] POST:APIPathValueMatchVerify(recordId) parameters:params headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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
