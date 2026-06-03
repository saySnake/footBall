//
//  TeamsRequest.m
//  footBall
//
//  Created by LWJ on 2026/3/21.
//

#import "TeamsRequest.h"
#import "Team.h"

NSString * const PNTeamFollowDidUpdateNotification = @"PNTeamFollowDidUpdateNotification";

static void PNPostTeamFollowDidUpdateNotification(void) {
    [[NSNotificationCenter defaultCenter] postNotificationName:PNTeamFollowDidUpdateNotification object:nil];
}

@implementation TeamsRequest
+(instancetype)shared {
    static TeamsRequest *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = TeamsRequest.alloc.init;
    });
    return instance;
}

-(void)searchTeams:(NSString *)searckKey leagueId:(NSString *)leagueId page:(NSInteger)page pageSize:(NSInteger)pageSize success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"keyword"] = (searckKey.length > 0) ? searckKey : @"";
    if (leagueId.length > 0) dict[@"leagueId"] = leagueId;
    dict[@"pageNum"] = @(page);
    dict[@"pageSize"] = @(pageSize);

    [[APIManager sharedManager] GET:APIPathValueTeamsSearch parameters:dict headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            id raw = responseObject.data;
            id jsonList = nil;
            if ([raw isKindOfClass:NSArray.class]) {
                jsonList = raw;
            } else if ([raw isKindOfClass:NSDictionary.class]) {
                NSDictionary *d = (NSDictionary *)raw;
                jsonList = d[@"list"] ?: d[@"teams"] ?: d[@"data"];
            }
            NSArray *teams = [jsonList isKindOfClass:NSArray.class]
                ? [NSArray yy_modelArrayWithClass:Team.class json:jsonList]
                : nil;
            responseObject.dataObject = teams ?: @[];
            success(responseObject);
        } else {
            failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];

}
- (void)getTeamsDetail:(NSString *)teamsId success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (!teamsId || teamsId.length == 0) {
        if (failure) {
            NSError *error = [NSError errorWithDomain:@"AuthManagerErrorDomain"
                                                  code:-1
                                              userInfo:@{NSLocalizedDescriptionKey: @"球队ID不能为空"}];
            failure(error);
        }
        return;
    }
    [[APIManager sharedManager] GET:APIPathValueTeams(teamsId) parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            success(responseObject);
        } else {
            failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];
}
- (void)onboardingFollows:(NSArray<NSString *> *)teamIds success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (!teamIds || teamIds.count == 0) {
        if (failure) {
            NSError *error = [NSError errorWithDomain:@"AuthManagerErrorDomain"
                                                  code:-1
                                              userInfo:@{NSLocalizedDescriptionKey: @"球队ID不能为空"}];
            failure(error);
        }
        return;
    }
    [[APIManager sharedManager] POST:APIPathValueOnboardingBatchFollow parameters:@{@"teamIds":teamIds} headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            PNPostTeamFollowDidUpdateNotification();
            success(responseObject);
        } else {
            failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];

}
- (void)followTeams:(NSArray<NSString *> *)teamIds success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (!teamIds || teamIds.count == 0) {
        if (failure) {
            NSError *error = [NSError errorWithDomain:@"AuthManagerErrorDomain"
                                                  code:-1
                                              userInfo:@{NSLocalizedDescriptionKey: @"球队ID不能为空"}];
            failure(error);
        }
        return;
    }
    [[APIManager sharedManager] POST:APIPathValueTeamsBatchFollow parameters:@{@"teamIds":teamIds} headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            PNPostTeamFollowDidUpdateNotification();
            success(responseObject);
        } else {
            failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];

}
- (void)followTeam:(NSString *)teamId success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (!teamId || teamId.length == 0) {
        if (failure) {
            NSError *error = [NSError errorWithDomain:@"AuthManagerErrorDomain"
                                                  code:-1
                                              userInfo:@{NSLocalizedDescriptionKey: @"球队ID不能为空"}];
            failure(error);
        }
        return;
    }
    [[APIManager sharedManager] POST:APIPathValueTeamsFollow(teamId) parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            PNPostTeamFollowDidUpdateNotification();
            success(responseObject);
        } else {
            failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];

}
- (void)cancelFollowTeam:(NSString *)teamId success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (!teamId || teamId.length == 0) {
        if (failure) {
            NSError *error = [NSError errorWithDomain:@"AuthManagerErrorDomain"
                                                  code:-1
                                              userInfo:@{NSLocalizedDescriptionKey: @"球队ID不能为空"}];
            failure(error);
        }
        return;
    }
    [[APIManager sharedManager] DELETE:APIPathValueTeamsFollow(teamId) parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            PNPostTeamFollowDidUpdateNotification();
            success(responseObject);
        } else {
            failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];

}
- (void)getFollowTeamsSuccess:(nullable APISuccessBlock)success failure:(nullable APIFailureBlock)failure {
    if (!AuthManager.sharedManager.isLoggedIn) {
        if (failure) {
            NSError *error = [NSError errorWithDomain:@"AuthManagerErrorDomain"
                                                  code:-1
                                              userInfo:@{NSLocalizedDescriptionKey: @"用户未登录"}];
            failure(error);
        }
        return;
    }

    [[APIManager sharedManager] GET:APIPathValueTeamsMyFollow parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            id raw = responseObject.data;
            id jsonArr = raw;
            if ([raw isKindOfClass:NSDictionary.class]) {
                NSDictionary *d = (NSDictionary *)raw;
                jsonArr = d[@"list"] ?: d[@"teams"] ?: d[@"data"];
            }
            NSArray *teams = [jsonArr isKindOfClass:NSArray.class]
                ? [NSArray yy_modelArrayWithClass:Team.class json:jsonArr]
                : nil;
            responseObject.dataObject = teams ?: @[];
            success(responseObject);
        } else {
            failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];
}
- (void)getFollowTeamIconsSuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (!AuthManager.sharedManager.isLoggedIn) {
        if (failure) {
            NSError *error = [NSError errorWithDomain:@"AuthManagerErrorDomain"
                                                  code:-1
                                              userInfo:@{NSLocalizedDescriptionKey: @"用户未登录"}];
            failure(error);
        }
        return;
    }

    [[APIManager sharedManager] GET:APIPathValueMyTeamIcons parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            NSArray *teams = [NSArray yy_modelArrayWithClass:Team.class json:responseObject.data];
            responseObject.dataObject = teams;
            success(responseObject);
        } else {
            failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];
}
@end
