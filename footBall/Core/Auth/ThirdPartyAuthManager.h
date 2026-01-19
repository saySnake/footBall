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
    ThirdPartyAuthTypeApple = 1,    // 苹果登录
    ThirdPartyAuthTypeWeChat = 2    // 微信登录
};

/// 第三方登录成功回调
/// @param authType 登录类型
/// @param authInfo 认证信息（包含token、openid等）
typedef void(^ThirdPartyAuthSuccessBlock)(ThirdPartyAuthType authType, NSDictionary *authInfo);

/// 第三方登录失败回调
/// @param authType 登录类型
/// @param error 错误信息
typedef void(^ThirdPartyAuthFailureBlock)(ThirdPartyAuthType authType, NSError *error);

/// 第三方登录管理器 - 统一管理苹果登录和微信登录
@interface ThirdPartyAuthManager : NSObject

/// 单例
+ (instancetype)sharedManager;

/// 注册微信AppID（在AppDelegate中调用）
/// @param appId 微信AppID
/// @param universalLink 微信Universal Link
- (void)registerWeChatAppId:(NSString *)appId universalLink:(NSString *)universalLink;

/// 苹果登录
/// @param success 成功回调
/// @param failure 失败回调
- (void)loginWithAppleSuccess:(nullable ThirdPartyAuthSuccessBlock)success
                       failure:(nullable ThirdPartyAuthFailureBlock)failure;

/// 微信登录
/// @param success 成功回调
/// @param failure 失败回调
- (void)loginWithWeChatSuccess:(nullable ThirdPartyAuthSuccessBlock)success
                        failure:(nullable ThirdPartyAuthFailureBlock)failure;

/// 处理微信登录回调（在AppDelegate中调用）
/// @param url 回调URL
- (BOOL)handleWeChatOpenURL:(NSURL *)url;

/// 处理微信Universal Link回调（在AppDelegate中调用）
/// @param userActivity 用户活动
- (BOOL)handleWeChatUniversalLink:(NSUserActivity *)userActivity;

/// 检查微信是否已安装
- (BOOL)isWeChatInstalled;

/// 检查是否支持苹果登录（iOS 13.0+）
- (BOOL)isAppleSignInAvailable;

@end

NS_ASSUME_NONNULL_END
