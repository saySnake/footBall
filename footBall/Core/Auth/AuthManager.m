//
//  AuthManager.m
//  footBall
//
//  Created on 2026/1/15.
//

#import "AuthManager.h"
#import "APIManager.h"
#import "APIEnvironmentManager.h"
#import "PNKeychainStore.h"

// Token / 用户资料存储 Key（Keychain；旧版曾明文写在 UserDefaults）
static NSString *const kCurrentUserKey = @"AuthManager_CurrentUser";

@interface AuthManager ()

@property (nonatomic, strong, nullable) User *user;

@end

@implementation AuthManager

+ (instancetype)sharedManager {
    static AuthManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AuthManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 从本地加载保存的Token
        [self loadTokenFromStorage];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenExpiredNotification) name:TokenExpiredNotification object:nil];
    }
    return self;
}
- (void)tokenExpiredNotification {
    self.user = nil;
    [self removeUser];
}
#pragma mark - Public Methods

- (void)sendVerifyCode:(NSString *)phone success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (!phone || phone.length == 0) {
        if (failure) {
            NSError *error = [NSError errorWithDomain:@"AuthManagerErrorDomain"
                                                  code:-1
                                              userInfo:@{NSLocalizedDescriptionKey: @"手机号码不能为空"}];
            failure(error);
        }
        return;
    }
    [[APIManager sharedManager] POST:APIPathValueSendCode parameters:@{@"phone":phone} headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            success(responseObject);
        } else {
            failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];
    
}
- (void)loginPhone:(NSString *)phone verify:(NSString *)verify success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (!phone || phone.length == 0) {
        if (failure) {
            NSError *error = [NSError errorWithDomain:@"AuthManagerErrorDomain"
                                                  code:-1
                                              userInfo:@{NSLocalizedDescriptionKey: @"手机号码不能为空"}];
            failure(error);
        }
        return;
    }
    if (!verify || verify.length == 0) {
        if (failure) {
            NSError *error = [NSError errorWithDomain:@"AuthManagerErrorDomain"
                                                  code:-2
                                              userInfo:@{NSLocalizedDescriptionKey: @"验证码不能为空"}];
            failure(error);
        }
        return;
    }

    [[APIManager sharedManager] POST:APIPathValueLoginPhone parameters:@{@"phone":phone,@"code":verify} headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            NSDictionary *data = responseObject.data;
            User *user = [User yy_modelWithJSON:data];
            self.user = user;
            [self saveUser];
            success(responseObject);
        } else {
            failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];

}
- (void)refreshTokenSuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    NSString *refreshToken = self.user.refreshToken;
    if (!refreshToken || refreshToken.length == 0) {
        if (failure) {
            NSError *error = [NSError errorWithDomain:@"AuthManagerErrorDomain"
                                                  code:-1
                                              userInfo:@{NSLocalizedDescriptionKey: @"Token不能为空"}];
            failure(error);
        }
        return;
    }
#if DEBUG
    NSLog(@"[Auth] refreshToken 请求前: %@", refreshToken.length ? @"有" : @"(空)");
#endif
    [[APIManager sharedManager] POST:APIPathValueRefreshToken parameters:@{@"refreshToken":refreshToken} headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            NSDictionary *data = responseObject.data;
            NSString *accessToken = data[@"accessToken"];
            NSString *refreshToken = data[@"refreshToken"];
            NSInteger expiresIn = [data[@"expiresIn"] integerValue];
            self.user.accessToken = accessToken;
            self.user.refreshToken = refreshToken;
            self.user.expiresIn = expiresIn;
            [self saveUser];
#if DEBUG
            NSLog(@"[Auth] refreshToken 刷新后: %@", self.user.refreshToken.length ? @"有" : @"(空)");
#endif
            success(responseObject);
        } else {
            failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];
}
- (void)logoutSuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    [[APIManager sharedManager] POST:APIPathValueLogout parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            self.user = nil;
            [self removeUser];
            success(responseObject);
        } else {
            failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];

}

- (void)deactivateAccountWithCode:(NSString *)code success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (!self.isLoggedIn) {
        if (failure) {
            failure([NSError errorWithDomain:@"AuthManagerErrorDomain" code:-1
                                     userInfo:@{NSLocalizedDescriptionKey: @"用户未登录"}]);
        }
        return;
    }
    NSString *trimmed = [code stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length != 6) {
        if (failure) {
            failure([NSError errorWithDomain:@"AuthManagerErrorDomain" code:-2
                                     userInfo:@{NSLocalizedDescriptionKey: @"验证码格式错误"}]);
        }
        return;
    }
    [[APIManager sharedManager] POST:APIPathValueDeactivateAccount
                          parameters:@{@"code": trimmed}
                             headers:nil
                             success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            self.user = nil;
            [self removeUser];
            if (success) success(responseObject);
        } else if (failure) {
            failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}
- (BOOL)isLoggedIn {
    return self.user && self.user.userId.length>0 && self.user.accessToken.length>0;
}
- (void)saveUser {
    NSString *userJson = [self.user yy_modelToJSONString];
    if (userJson.length > 0) {
        [PNKeychainStore setString:userJson forKey:kCurrentUserKey];
    } else {
        [PNKeychainStore removeItemForKey:kCurrentUserKey];
    }
    // 清除旧版明文缓存，避免敏感数据残留在 UserDefaults / plist
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCurrentUserKey];
}

- (void)removeUser {
    _user = nil;
    [PNKeychainStore removeItemForKey:kCurrentUserKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCurrentUserKey];
}

#pragma mark - Private Methods

- (void)loadTokenFromStorage {
    NSString *user = [PNKeychainStore stringForKey:kCurrentUserKey];
    if (!user.length) {
        // 兼容升级：从 UserDefaults 明文迁移到 Keychain
        user = [[NSUserDefaults standardUserDefaults] stringForKey:kCurrentUserKey];
        if (user.length > 0) {
            [PNKeychainStore setString:user forKey:kCurrentUserKey];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCurrentUserKey];
        }
    }
    if (user.length > 0) {
        _user = [User yy_modelWithJSON:user];
#if DEBUG
        NSLog(@"📂 已从 Keychain 加载 User（refreshToken %@）",
              _user.refreshToken.length > 0 ? @"有" : @"空");
#endif
    }
}

@end
