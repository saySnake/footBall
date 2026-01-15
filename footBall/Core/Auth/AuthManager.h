//
//  AuthManager.h
//  footBall
//
//  Created on 2026/1/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 登录成功回调
typedef void(^AuthLoginSuccessBlock)(NSDictionary *response);
/// 登录失败回调
typedef void(^AuthLoginFailureBlock)(NSError *error);

/// 认证管理器 - 统一管理用户认证和Token
@interface AuthManager : NSObject

/// 单例
+ (instancetype)sharedManager;

/// 当前Token（Bearer Token）
@property (nonatomic, strong, nullable, readonly) NSString *token;

/// 当前Authorization头（格式：Bearer {token}）
@property (nonatomic, strong, nullable, readonly) NSString *authorizationHeader;

/// 是否已登录
@property (nonatomic, assign, readonly) BOOL isLoggedIn;

/// 登录方法
/// @param username 用户名
/// @param password 密码
/// @param success 成功回调（返回响应数据，包含token）
/// @param failure 失败回调
- (void)loginWithUsername:(NSString *)username
                  password:(NSString *)password
                   success:(nullable AuthLoginSuccessBlock)success
                   failure:(nullable AuthLoginFailureBlock)failure;

/// 登录方法（使用自定义参数）
/// @param parameters 登录参数（如：@{@"username": @"xxx", @"password": @"xxx"}）
/// @param success 成功回调（返回响应数据，包含token）
/// @param failure 失败回调
- (void)loginWithParameters:(NSDictionary *)parameters
                    success:(nullable AuthLoginSuccessBlock)success
                    failure:(nullable AuthLoginFailureBlock)failure;

/// 保存Token
/// @param token Token字符串
- (void)saveToken:(NSString *)token;

/// 保存Authorization头（如果服务器返回的是完整的Authorization头）
/// @param authorizationHeader Authorization头（如：@"Bearer xxxxx"）
- (void)saveAuthorizationHeader:(NSString *)authorizationHeader;

/// 清除Token（登出时调用）
- (void)clearToken;

/// 获取Token（用于拦截器）
- (nullable NSString *)getToken;

@end

NS_ASSUME_NONNULL_END
