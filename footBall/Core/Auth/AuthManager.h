//
//  AuthManager.h
//  footBall
//
//  Created on 2026/1/15.
//

#import <Foundation/Foundation.h>
#import "User.h"
NS_ASSUME_NONNULL_BEGIN

/// 登录成功回调
typedef void(^AuthLoginSuccessBlock)(HTTPResponse *response);
/// 登录失败回调
typedef void(^AuthLoginFailureBlock)(NSError *error);

/// 认证管理器 - 统一管理用户认证和Token
@interface AuthManager : NSObject

/// 单例
+ (instancetype)sharedManager;

/// 当前Token（Bearer Token）
@property (nonatomic, strong, nullable, readonly) User *user;

/// 是否已登录
@property (nonatomic, assign, readonly) BOOL isLoggedIn;

- (void)sendVerifyCode:(NSString *)phone
               success:(nullable AuthLoginSuccessBlock)success
               failure:(nullable AuthLoginFailureBlock)failure;

- (void)loginPhone:(NSString *)phone verify:(NSString *)verify
               success:(nullable AuthLoginSuccessBlock)success
               failure:(nullable AuthLoginFailureBlock)failure;

- (void)saveUser;
- (void)removeUser;
@end

NS_ASSUME_NONNULL_END
