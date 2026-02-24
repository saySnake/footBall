//
//  ThirdPartyAuthManager.h
//  footBall
//
//  Created on 2026/1/15.
//

#import <Foundation/Foundation.h>
#import <AuthenticationServices/AuthenticationServices.h>

NS_ASSUME_NONNULL_BEGIN

/// 第三方登录类型
typedef NS_ENUM(NSInteger, ThirdPartyAuthType) {
    ThirdPartyAuthTypeApple = 1    // 苹果登录
};

/// 第三方登录成功回调
/// @param authType 登录类型
/// @param authInfo 认证信息（包含token、openid等）
typedef void(^ThirdPartyAuthSuccessBlock)(ThirdPartyAuthType authType, NSDictionary *authInfo);

/// 第三方登录失败回调
/// @param authType 登录类型
/// @param error 错误信息
typedef void(^ThirdPartyAuthFailureBlock)(ThirdPartyAuthType authType, NSError *error);

/// 第三方登录管理器 - 管理苹果登录
@interface ThirdPartyAuthManager : NSObject

/// 单例
+ (instancetype)sharedManager;

/// 苹果登录
/// @param success 成功回调
/// @param failure 失败回调
- (void)loginWithAppleSuccess:(nullable ThirdPartyAuthSuccessBlock)success
                       failure:(nullable ThirdPartyAuthFailureBlock)failure;

/// 检查是否支持苹果登录（iOS 13.0+）
- (BOOL)isAppleSignInAvailable;

@end

NS_ASSUME_NONNULL_END
