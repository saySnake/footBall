//
//  UserRequest.m
//  footBall
//
//  Created by LWJ on 2026/3/22.
//

#import "UserRequest.h"

@implementation UserRequest
+(instancetype)shared {
    static UserRequest *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = UserRequest.alloc.init;
    });
    return instance;
}

- (void)completeNewUserOnboardingSuccess:(nullable APISuccessBlock)success failure:(nullable APIFailureBlock)failure {
    [[APIManager sharedManager] POST:APIPathValueOnboardingComplete parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            AuthManager.sharedManager.user.onboardingCompleted = YES;
            AuthManager.sharedManager.user.profile.onboardingCompleted = YES;
            [AuthManager.sharedManager saveUser];
            if (success)success(responseObject);
        } else {
            if(failure)failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        if(failure)failure(error);
    }];
}

- (void)getLoginUserInfoSuccess:(nullable APISuccessBlock)success failure:(nullable APIFailureBlock)failure {
    if (!AuthManager.sharedManager.isLoggedIn) {
        if (failure) {
            NSError *error = [NSError errorWithDomain:@"AuthManagerErrorDomain"
                                                  code:-1
                                              userInfo:@{NSLocalizedDescriptionKey: @"用户未登录"}];
            failure(error);
        }
        return;
    }

    [[APIManager sharedManager] GET:APIPathValueUser parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            id raw = responseObject.data;
            /// 常见嵌套：data 为 { user: {...} } / { profile: {...} }
            if ([raw isKindOfClass:[NSDictionary class]]) {
                NSDictionary *d = raw;
                id inner = d[@"user"] ?: d[@"profile"] ?: d[@"userInfo"] ?: d[@"userProfile"];
                if ([inner isKindOfClass:[NSDictionary class]]) {
                    raw = inner;
                }
            }
            UserProfile *user = [UserProfile yy_modelWithJSON:raw];
            responseObject.dataObject = user;
            AuthManager.sharedManager.user.profile = user;
            [AuthManager.sharedManager saveUser];
            success(responseObject);
        } else {
            failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];

}
- (void)updateUserInfo:(nonnull UserProfile *)user success:(nullable APISuccessBlock)success failure:(nullable APIFailureBlock)failure {
    if (!AuthManager.sharedManager.isLoggedIn) {
        if (failure) {
            NSError *error = [NSError errorWithDomain:@"AuthManagerErrorDomain"
                                                  code:-1
                                              userInfo:@{NSLocalizedDescriptionKey: @"用户未登录"}];
            failure(error);
        }
        return;
    }
    if (!user) {
        if (failure) {
            NSError *error = [NSError errorWithDomain:@"AuthManagerErrorDomain"
                                                  code:-1
                                              userInfo:@{NSLocalizedDescriptionKey: @"用户为空"}];
            failure(error);
        }
        return;
    }
    NSMutableDictionary *dict = NSMutableDictionary.dictionary;
    dict[@"nickname"] = user.nickname;
    // avatar 可能是签名 URL（含 ?OSSAccessKeyId=... 等参数），需要去掉查询参数只保留路径部分
    // 否则服务端 toObjectKey 会把查询参数也存进数据库，导致下次签名出错
    NSString *avatarToSend = user.avatar;
    if (avatarToSend.length > 0) {
        NSURL *avatarURL = [NSURL URLWithString:avatarToSend];
        if (avatarURL && avatarURL.query.length > 0) {
            // 是带签名参数的完整 URL，去掉 query 只保留 scheme+host+path
            NSURLComponents *components = [NSURLComponents componentsWithURL:avatarURL resolvingAgainstBaseURL:NO];
            components.query = nil;
            components.fragment = nil;
            avatarToSend = components.URL.absoluteString ?: avatarToSend;
        }
    }
    dict[@"avatar"] = avatarToSend;
    if (user.phone.length > 0) dict[@"phone"] = user.phone;
    dict[@"gender"] = @(user.gender);
    dict[@"birthDate"] = user.birthDate;
    dict[@"bio"] = user.bio;
    dict[@"city"] = user.city;
    dict[@"passportCode"] = user.passportCode;
    dict[@"preferenceTags"] = user.preferenceTags;
    dict[@"firstWatchYear"] = user.firstWatchYear;
    dict[@"primaryTeamId"] = user.primaryTeamId;
    dict[@"nationalTeamId"] = user.nationalTeamId;
    [[APIManager sharedManager] PUT:APIPathValueUser parameters:dict headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            success(responseObject);
        } else {
            failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];
}
- (void)getUserQRCodeSuccess:(nullable APISuccessBlock)success failure:(nullable APIFailureBlock)failure {
    if (!AuthManager.sharedManager.isLoggedIn) {
        if (failure) {
            NSError *error = [NSError errorWithDomain:@"AuthManagerErrorDomain"
                                                  code:-1
                                              userInfo:@{NSLocalizedDescriptionKey: @"用户未登录"}];
            failure(error);
        }
        return;
    }

    [[APIManager sharedManager] GET:APIPathValueUserQRCode parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            AuthManager.sharedManager.user.profile.qrCode = responseObject.data;
            [AuthManager.sharedManager saveUser];
            success(responseObject);
        } else {
            failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];

}

- (void)getUserInfo:(nonnull NSString *)userId success:(nullable APISuccessBlock)success failure:(nullable APIFailureBlock)failure {
    if (!userId || userId.length == 0) {
        if (failure) {
            NSError *error = [NSError errorWithDomain:@"AuthManagerErrorDomain"
                                                  code:-1
                                              userInfo:@{NSLocalizedDescriptionKey: @"用户ID为空"}];
            failure(error);
        }
        return;
    }

    [[APIManager sharedManager] GET:APIPathValueGetUser(userId) parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            success(responseObject);
        } else {
            failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];

}

- (void)searchUser:(nonnull NSString *)keyword success:(nullable APISuccessBlock)success failure:(nullable APIFailureBlock)failure {
    NSString *trimmed = [keyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) {
        if (failure) {
            NSError *error = [NSError errorWithDomain:@"AuthManagerErrorDomain"
                                                  code:-1
                                              userInfo:@{NSLocalizedDescriptionKey: @"搜索内容不能为空"}];
            failure(error);
        }
        return;
    }
    if (!AuthManager.sharedManager.isLoggedIn) {
        if (failure) {
            NSError *error = [NSError errorWithDomain:@"AuthManagerErrorDomain"
                                                  code:-1
                                              userInfo:@{NSLocalizedDescriptionKey: @"用户未登录"}];
            failure(error);
        }
        return;
    }

    /// GET `/api/v1/users/search`：同时传 keyword（昵称/关键词）与 userId（与 keyword 相同，兼容仅识别 userId 的旧后端）
    NSDictionary *params = @{
        @"keyword": trimmed,
        @"userId": trimmed,
    };
    [[APIManager sharedManager] GET:APIPathValueSearchUser parameters:params headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            success(responseObject);
        } else {
            failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];

}

@end
