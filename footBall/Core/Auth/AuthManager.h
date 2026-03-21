//
//  AuthManager.h
//  footBall
//
//  Created on 2026/1/15.
//

#import <Foundation/Foundation.h>
#import "User.h"
NS_ASSUME_NONNULL_BEGIN


/// 认证管理器 - 统一管理用户认证和Token
@interface AuthManager : NSObject

/// 单例
+ (instancetype)sharedManager;

/// 当前Token（Bearer Token）
@property (nonatomic, strong, nullable, readonly) User *user;

/// 是否已登录
@property (nonatomic, assign, readonly) BOOL isLoggedIn;
/// 发送验证码
- (void)sendVerifyCode:(NSString *)phone
               success:(nullable APISuccessBlock)success
               failure:(nullable APIFailureBlock)failure;
/// 登录
- (void)loginPhone:(NSString *)phone verify:(NSString *)verify
               success:(nullable APISuccessBlock)success
               failure:(nullable APIFailureBlock)failure;
/// 刷新Token
- (void)refreshTokenSuccess:(nullable APISuccessBlock)success failure:(nullable APIFailureBlock)failure;
/// 登出
- (void)logoutSuccess:(nullable APISuccessBlock)success failure:(nullable APIFailureBlock)failure;

- (void)saveUser;
- (void)removeUser;
@end

NS_ASSUME_NONNULL_END
