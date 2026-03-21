//
//  AuthManager.m
//  footBall
//
//  Created on 2026/1/15.
//

#import "AuthManager.h"
#import "APIManager.h"
#import "APIEnvironmentManager.h"

// Token存储Key
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
    }
    return self;
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

    [[APIManager sharedManager] POST:APIPathValueAuthLoginPhone parameters:@{@"phone":phone,@"code":verify} headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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
    [[APIManager sharedManager] POST:APIPathValueAuthRefresh parameters:@{@"refreshToken":refreshToken} headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            NSDictionary *data = responseObject.data;
            NSString *accessToken = data[@"accessToken"];
            NSString *refreshToken = data[@"refreshToken"];
            NSInteger expiresIn = [data[@"expiresIn"] integerValue];
            self.user.accessToken = accessToken;
            self.user.refreshToken = refreshToken;
            self.user.expiresIn = expiresIn;
            [self saveUser];
            success(responseObject);
        } else {
            failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];
}
- (void)logoutSuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    [[APIManager sharedManager] POST:APIPathValueAuthLogout parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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
- (BOOL)isLoggedIn {
    return self.user && self.user.userId.length>0 && self.user.accessToken.length>0;
}
- (void)saveUser {
    NSString *userJson = [self.user yy_modelToJSONString];
    [[NSUserDefaults standardUserDefaults] setObject:userJson forKey:kCurrentUserKey];
}
-(void)removeUser {
    _user = nil;
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCurrentUserKey];
}
#pragma mark - Private Methods

- (void)loadTokenFromStorage {
    // 从本地加载Token
    NSString *user = [[NSUserDefaults standardUserDefaults] stringForKey:kCurrentUserKey];
    if (user && user.length > 0) {
        _user = [User yy_modelWithJSON:user];
        NSLog(@"📂 已从本地加载User");
    }
}

@end
