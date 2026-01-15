//
//  AuthManager.m
//  footBall
//
//  Created on 2026/1/15.
//

#import "AuthManager.h"
#import "APIManager.h"
#import "APIEnvironmentManager.h"
#import "APIPathNames.h"

// Token存储Key
static NSString *const kTokenKey = @"AuthManager_Token";
static NSString *const kAuthorizationHeaderKey = @"AuthManager_AuthorizationHeader";

@interface AuthManager ()

@property (nonatomic, strong, nullable) NSString *token;
@property (nonatomic, strong, nullable) NSString *authorizationHeader;

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

- (void)loginWithUsername:(NSString *)username
                  password:(NSString *)password
                   success:(nullable AuthLoginSuccessBlock)success
                   failure:(nullable AuthLoginFailureBlock)failure {
    
    if (!username || username.length == 0) {
        if (failure) {
            NSError *error = [NSError errorWithDomain:@"AuthManagerErrorDomain"
                                                  code:-1
                                              userInfo:@{NSLocalizedDescriptionKey: @"用户名不能为空"}];
            failure(error);
        }
        return;
    }
    
    if (!password || password.length == 0) {
        if (failure) {
            NSError *error = [NSError errorWithDomain:@"AuthManagerErrorDomain"
                                                  code:-1
                                              userInfo:@{NSLocalizedDescriptionKey: @"密码不能为空"}];
            failure(error);
        }
        return;
    }
    
    // 构建登录参数
    NSDictionary *parameters = @{
        @"username": username,
        @"password": password
    };
    
    [self loginWithParameters:parameters success:success failure:failure];
}

- (void)loginWithParameters:(NSDictionary *)parameters
                    success:(nullable AuthLoginSuccessBlock)success
                    failure:(nullable AuthLoginFailureBlock)failure {
    
    if (!parameters || parameters.count == 0) {
        if (failure) {
            NSError *error = [NSError errorWithDomain:@"AuthManagerErrorDomain"
                                                  code:-1
                                              userInfo:@{NSLocalizedDescriptionKey: @"登录参数不能为空"}];
            failure(error);
        }
        return;
    }
    
    NSLog(@"🔐 开始登录...");
    
    // 使用路径名称发起登录请求
    [[APIManager sharedManager] POSTWithPathName:APIPathNameAuthLogin
                                         subPath:nil
                                      parameters:parameters
                                         headers:nil
                                         success:^(id responseObject) {
        NSLog(@"✅ 登录成功");
        
        // 解析响应数据，提取token
        NSDictionary *response = nil;
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            response = (NSDictionary *)responseObject;
        } else if ([responseObject isKindOfClass:[NSData class]]) {
            NSError *jsonError = nil;
            response = [NSJSONSerialization JSONObjectWithData:(NSData *)responseObject
                                                       options:NSJSONReadingMutableContainers
                                                         error:&jsonError];
            if (jsonError) {
                NSLog(@"⚠️ 解析响应数据失败: %@", jsonError.localizedDescription);
            }
        }
        
        // 提取token（支持多种可能的字段名）
        NSString *token = nil;
        NSString *authorization = nil;
        
        if (response) {
            // 尝试从不同字段获取token
            token = response[@"token"] ?: 
                   response[@"accessToken"] ?: 
                   response[@"access_token"] ?:
                   response[@"data"][@"token"] ?:
                   response[@"data"][@"accessToken"] ?:
                   response[@"data"][@"access_token"];
            
            // 尝试获取Authorization头
            authorization = response[@"authorization"] ?:
                           response[@"Authorization"] ?:
                           response[@"data"][@"authorization"] ?:
                           response[@"data"][@"Authorization"];
        }
        
        // 保存token或authorization
        if (token && token.length > 0) {
            [self saveToken:token];
            NSLog(@"✅ Token已保存");
        } else if (authorization && authorization.length > 0) {
            [self saveAuthorizationHeader:authorization];
            NSLog(@"✅ Authorization头已保存");
        } else {
            NSLog(@"⚠️ 响应中未找到token或authorization字段");
            // 即使没有token，也认为登录成功（可能服务器返回方式不同）
        }
        
        if (success) {
            success(response ?: @{});
        }
        
    } failure:^(NSError *error) {
        NSLog(@"❌ 登录失败: %@", error.localizedDescription);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)saveToken:(NSString *)token {
    if (!token || token.length == 0) {
        return;
    }
    
    _token = token;
    
    // 自动生成Authorization头
    _authorizationHeader = [NSString stringWithFormat:@"Bearer %@", token];
    
    // 保存到本地
    [[NSUserDefaults standardUserDefaults] setObject:token forKey:kTokenKey];
    [[NSUserDefaults standardUserDefaults] setObject:_authorizationHeader forKey:kAuthorizationHeaderKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSLog(@"💾 Token已保存到本地存储");
}

- (void)saveAuthorizationHeader:(NSString *)authorizationHeader {
    if (!authorizationHeader || authorizationHeader.length == 0) {
        return;
    }
    
    _authorizationHeader = authorizationHeader;
    
    // 尝试从Authorization头中提取token（格式：Bearer {token}）
    if ([authorizationHeader hasPrefix:@"Bearer "]) {
        _token = [authorizationHeader substringFromIndex:7]; // 跳过 "Bearer "
    } else {
        _token = authorizationHeader;
    }
    
    // 保存到本地
    [[NSUserDefaults standardUserDefaults] setObject:_token forKey:kTokenKey];
    [[NSUserDefaults standardUserDefaults] setObject:authorizationHeader forKey:kAuthorizationHeaderKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSLog(@"💾 Authorization头已保存到本地存储");
}

- (void)clearToken {
    _token = nil;
    _authorizationHeader = nil;
    
    // 清除本地存储
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kTokenKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kAuthorizationHeaderKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSLog(@"🗑️ Token已清除");
}

- (nullable NSString *)getToken {
    return self.token;
}

- (BOOL)isLoggedIn {
    return self.token != nil && self.token.length > 0;
}

#pragma mark - Private Methods

- (void)loadTokenFromStorage {
    // 从本地加载Token
    NSString *savedToken = [[NSUserDefaults standardUserDefaults] stringForKey:kTokenKey];
    NSString *savedAuthorization = [[NSUserDefaults standardUserDefaults] stringForKey:kAuthorizationHeaderKey];
    
    if (savedToken && savedToken.length > 0) {
        _token = savedToken;
        if (savedAuthorization && savedAuthorization.length > 0) {
            _authorizationHeader = savedAuthorization;
        } else {
            _authorizationHeader = [NSString stringWithFormat:@"Bearer %@", savedToken];
        }
        NSLog(@"📂 已从本地加载Token");
    }
}

@end
