//
//  SocialRequest.m
//  footBall
//
//  好友/关注接口；写操作与扫码 payload 字段名需与后端 Swagger 对齐。
//

#import "SocialRequest.h"

@implementation SocialRequest
+ (instancetype)shared {
    static SocialRequest *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = SocialRequest.alloc.init;
    });
    return instance;
}

- (void)getFriendRequestsSuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    [[APIManager sharedManager] GET:APIPathValueFriendsRequests parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            PNFriendRequestPage *page = [PNFriendRequestPage yy_modelWithJSON:responseObject.data];
            responseObject.dataObject = page;
            success(responseObject);
        }
        else failure([APIError errorWithResponse:responseObject]);
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];
}

- (void)getFriendRequestsPendingCountSuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    [[APIManager sharedManager] GET:APIPathValueFriendsRequestsPendingCount parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            responseObject.dataObject = @([responseObject.data respondsToSelector:@selector(integerValue)] ? [responseObject.data integerValue] : 0);
            success(responseObject);
        }
        else failure([APIError errorWithResponse:responseObject]);
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];
}

- (void)processFriendRequest:(NSString *)requestId accept:(BOOL)accept success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (requestId.length == 0) {
        failure([NSError errorWithDomain:@"SocialRequestErrorDomain" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"requestId不能为空"}]);
        return;
    }
    NSDictionary *params = @{@"action": accept ? @"accept" : @"reject"};
    [[APIManager sharedManager] PUT:APIPathValueFriendsRequestProcess(requestId) parameters:params headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) success(responseObject);
        else failure([APIError errorWithResponse:responseObject]);
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];
}

- (void)getFriendsSuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    [[APIManager sharedManager] GET:APIPathValueFriendsList parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            PNFriendPage *page = [PNFriendPage yy_modelWithJSON:responseObject.data];
            responseObject.dataObject = page;
            success(responseObject);
        }
        else failure([APIError errorWithResponse:responseObject]);
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];
}

- (void)getFollowingSuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    [[APIManager sharedManager] GET:APIPathValueFollowsFollowing parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            PNUserPage *page = [PNUserPage yy_modelWithJSON:responseObject.data];
            responseObject.dataObject = page;
            success(responseObject);
        }
        else failure([APIError errorWithResponse:responseObject]);
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];
}

- (void)getFollowersSuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    [[APIManager sharedManager] GET:APIPathValueFollowsFollowers parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            PNUserPage *page = [PNUserPage yy_modelWithJSON:responseObject.data];
            responseObject.dataObject = page;
            success(responseObject);
        }
        else failure([APIError errorWithResponse:responseObject]);
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];
}

- (void)getRecommendFriendsSuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    [[APIManager sharedManager] GET:APIPathValueFriendsRecommend parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            NSArray *users = [NSArray yy_modelArrayWithClass:PNUser.class json:responseObject.data];
            responseObject.dataObject = users;
            success(responseObject);
        }
        else failure([APIError errorWithResponse:responseObject]);
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];
}

#pragma mark - 关注

- (void)followUser:(NSString *)userId success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (userId.length == 0) {
        if (failure) failure([NSError errorWithDomain:@"SocialRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"userId不能为空" }]);
        return;
    }
    [[APIManager sharedManager] POST:APIPathValueFollowsUser(userId) parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)unfollowUser:(NSString *)userId success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (userId.length == 0) {
        if (failure) failure([NSError errorWithDomain:@"SocialRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"userId不能为空" }]);
        return;
    }
    [[APIManager sharedManager] DELETE:APIPathValueFollowsUser(userId) parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)getFollowStatsSuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    [[APIManager sharedManager] GET:APIPathValueFollowsStats parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

#pragma mark - 好友写操作 / 统计

- (void)sendFriendRequestWithBody:(NSDictionary *)body success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (![body isKindOfClass:NSDictionary.class] || body.count == 0) {
        if (failure) failure([NSError errorWithDomain:@"SocialRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"请求体不能为空" }]);
        return;
    }
    [[APIManager sharedManager] POST:APIPathValueFriendsRequests parameters:body headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)deleteFriend:(NSString *)friendId success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (friendId.length == 0) {
        if (failure) failure([NSError errorWithDomain:@"SocialRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"friendId不能为空" }]);
        return;
    }
    [[APIManager sharedManager] DELETE:APIPathValueFriendsDelete(friendId) parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)scanAddFriendWithPayload:(NSDictionary *)payload success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (![payload isKindOfClass:NSDictionary.class]) {
        if (failure) failure([NSError errorWithDomain:@"SocialRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"请求体无效" }]);
        return;
    }
    [[APIManager sharedManager] POST:APIPathValueFriendsScan parameters:payload headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)getFriendStatsSuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    [[APIManager sharedManager] GET:APIPathValueFriendsStats parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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
