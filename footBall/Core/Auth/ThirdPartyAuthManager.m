//
//  ThirdPartyAuthManager.m
//  footBall
//
//  Created on 2026/1/15.
//

#import "ThirdPartyAuthManager.h"
#import <AuthenticationServices/AuthenticationServices.h>
#import <WechatOpenSDK/WXApi.h>

@interface ThirdPartyAuthManager () <ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding, WXApiDelegate>

@property (nonatomic, strong, nullable) ThirdPartyAuthSuccessBlock appleSuccessBlock;
@property (nonatomic, strong, nullable) ThirdPartyAuthFailureBlock appleFailureBlock;
@property (nonatomic, strong, nullable) ThirdPartyAuthSuccessBlock weChatSuccessBlock;
@property (nonatomic, strong, nullable) ThirdPartyAuthFailureBlock weChatFailureBlock;
@property (nonatomic, copy, nullable) NSString *weChatAppId;
@property (nonatomic, copy, nullable) NSString *weChatUniversalLink;

@end

@implementation ThirdPartyAuthManager

+ (instancetype)sharedManager {
    static ThirdPartyAuthManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ThirdPartyAuthManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 初始化
    }
    return self;
}

#pragma mark - Public Methods

- (void)registerWeChatAppId:(NSString *)appId universalLink:(NSString *)universalLink {
    self.weChatAppId = appId;
    self.weChatUniversalLink = universalLink;
    
    // 注册微信SDK
    BOOL success = [WXApi registerApp:appId universalLink:universalLink];
    if (success) {
        NSLog(@"✅ 微信SDK注册成功 - AppID: %@", appId);
    } else {
        NSLog(@"❌ 微信SDK注册失败 - AppID: %@", appId);
    }
}

- (void)loginWithAppleSuccess:(ThirdPartyAuthSuccessBlock)success
                       failure:(ThirdPartyAuthFailureBlock)failure {
    
    if (![self isAppleSignInAvailable]) {
        if (failure) {
            NSError *error = [NSError errorWithDomain:@"ThirdPartyAuthErrorDomain"
                                                  code:-1
                                              userInfo:@{NSLocalizedDescriptionKey: @"当前系统版本不支持苹果登录（需要iOS 13.0+）"}];
            failure(ThirdPartyAuthTypeApple, error);
        }
        return;
    }
    
    // 保存回调
    self.appleSuccessBlock = success;
    self.appleFailureBlock = failure;
    
    // 创建苹果登录请求
    ASAuthorizationAppleIDProvider *provider = [[ASAuthorizationAppleIDProvider alloc] init];
    ASAuthorizationAppleIDRequest *request = [provider createRequest];
    request.requestedScopes = @[ASAuthorizationScopeFullName, ASAuthorizationScopeEmail];
    
    // 创建授权控制器
    ASAuthorizationController *controller = [[ASAuthorizationController alloc] initWithAuthorizationRequests:@[request]];
    controller.delegate = self;
    controller.presentationContextProvider = self;
    
    // 发起授权请求
    [controller performRequests];
    
    NSLog(@"🍎 发起苹果登录请求");
}

- (void)loginWithWeChatSuccess:(ThirdPartyAuthSuccessBlock)success
                        failure:(ThirdPartyAuthFailureBlock)failure {
    
    if (![self isWeChatInstalled]) {
        if (failure) {
            NSError *error = [NSError errorWithDomain:@"ThirdPartyAuthErrorDomain"
                                                  code:-1
                                              userInfo:@{NSLocalizedDescriptionKey: @"未安装微信，请先安装微信"}];
            failure(ThirdPartyAuthTypeWeChat, error);
        }
        return;
    }
    
    if (!self.weChatAppId || self.weChatAppId.length == 0) {
        if (failure) {
            NSError *error = [NSError errorWithDomain:@"ThirdPartyAuthErrorDomain"
                                                  code:-1
                                              userInfo:@{NSLocalizedDescriptionKey: @"微信AppID未配置，请先调用registerWeChatAppId:universalLink:"}];
            failure(ThirdPartyAuthTypeWeChat, error);
        }
        return;
    }
    
    // 保存回调
    self.weChatSuccessBlock = success;
    self.weChatFailureBlock = failure;
    
    // 创建微信登录请求
    SendAuthReq *req = [[SendAuthReq alloc] init];
    req.scope = @"snsapi_userinfo";
    req.state = @"wechat_login_state";
    
    // 发起微信登录
    BOOL success_send = [WXApi sendReq:req completion:^(BOOL success) {
        if (success) {
            NSLog(@"✅ 微信登录请求已发送");
        } else {
            NSLog(@"❌ 微信登录请求发送失败");
            if (failure) {
                NSError *error = [NSError errorWithDomain:@"ThirdPartyAuthErrorDomain"
                                                      code:-1
                                                  userInfo:@{NSLocalizedDescriptionKey: @"微信登录请求发送失败"}];
                failure(ThirdPartyAuthTypeWeChat, error);
            }
        }
    }];
    
    if (!success_send) {
        if (failure) {
            NSError *error = [NSError errorWithDomain:@"ThirdPartyAuthErrorDomain"
                                                  code:-1
                                              userInfo:@{NSLocalizedDescriptionKey: @"微信登录请求发送失败"}];
            failure(ThirdPartyAuthTypeWeChat, error);
        }
    }
}

- (BOOL)handleWeChatOpenURL:(NSURL *)url {
    return [WXApi handleOpenURL:url delegate:self];
}

- (BOOL)handleWeChatUniversalLink:(NSUserActivity *)userActivity {
    return [WXApi handleOpenUniversalLink:userActivity delegate:self];
}

- (BOOL)isWeChatInstalled {
    return [WXApi isWXAppInstalled];
}

- (BOOL)isAppleSignInAvailable {
    if (@available(iOS 13.0, *)) {
        return YES;
    }
    return NO;
}

#pragma mark - ASAuthorizationControllerDelegate

- (void)authorizationController:(ASAuthorizationController *)controller
   didCompleteWithAuthorization:(ASAuthorization *)authorization API_AVAILABLE(ios(13.0)) {
    
    if ([authorization.credential isKindOfClass:[ASAuthorizationAppleIDCredential class]]) {
        ASAuthorizationAppleIDCredential *credential = (ASAuthorizationAppleIDCredential *)authorization.credential;
        
        // 获取用户信息
        NSString *userID = credential.user;
        NSString *identityToken = [[NSString alloc] initWithData:credential.identityToken encoding:NSUTF8StringEncoding];
        NSString *authorizationCode = [[NSString alloc] initWithData:credential.authorizationCode encoding:NSUTF8StringEncoding];
        
        NSString *email = credential.email;
        NSPersonNameComponents *fullName = credential.fullName;
        NSString *displayName = nil;
        if (fullName) {
            NSMutableString *nameString = [NSMutableString string];
            if (fullName.givenName) {
                [nameString appendString:fullName.givenName];
            }
            if (fullName.familyName) {
                [nameString appendString:fullName.familyName];
            }
            displayName = nameString.length > 0 ? nameString : nil;
        }
        
        // 构建认证信息
        NSMutableDictionary *authInfo = [NSMutableDictionary dictionary];
        if (userID) authInfo[@"userID"] = userID;
        if (identityToken) authInfo[@"identityToken"] = identityToken;
        if (authorizationCode) authInfo[@"authorizationCode"] = authorizationCode;
        if (email) authInfo[@"email"] = email;
        if (displayName) authInfo[@"displayName"] = displayName;
        authInfo[@"authType"] = @(ThirdPartyAuthTypeApple);
        
        NSLog(@"✅ 苹果登录成功 - UserID: %@", userID);
        
        if (self.appleSuccessBlock) {
            self.appleSuccessBlock(ThirdPartyAuthTypeApple, authInfo);
        }
        
        // 清除回调
        self.appleSuccessBlock = nil;
        self.appleFailureBlock = nil;
    }
}

- (void)authorizationController:(ASAuthorizationController *)controller
           didCompleteWithError:(NSError *)error API_AVAILABLE(ios(13.0)) {
    
    NSLog(@"❌ 苹果登录失败: %@", error.localizedDescription);
    
    if (self.appleFailureBlock) {
        self.appleFailureBlock(ThirdPartyAuthTypeApple, error);
    }
    
    // 清除回调
    self.appleSuccessBlock = nil;
    self.appleFailureBlock = nil;
}

#pragma mark - ASAuthorizationControllerPresentationContextProviding

- (ASPresentationAnchor)presentationAnchorForAuthorizationController:(ASAuthorizationController *)controller API_AVAILABLE(ios(13.0)) {
    // 返回当前窗口
    UIWindow *window = nil;
    if (@available(iOS 13.0, *)) {
        NSArray<UIWindowScene *> *windowScenes = [UIApplication sharedApplication].connectedScenes.allObjects;
        for (UIWindowScene *scene in windowScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                for (UIWindow *w in scene.windows) {
                    if (w.isKeyWindow) {
                        window = w;
                        break;
                    }
                }
                if (window) break;
                if (scene.windows.count > 0) {
                    window = scene.windows.firstObject;
                    break;
                }
            }
        }
    } else {
        window = [UIApplication sharedApplication].keyWindow;
    }
    return window;
}

#pragma mark - WXApiDelegate

- (void)onResp:(BaseResp *)resp {
    if ([resp isKindOfClass:[SendAuthResp class]]) {
        SendAuthResp *authResp = (SendAuthResp *)resp;
        
        if (resp.errCode == WXSuccess) {
            // 微信登录成功，获取code
            NSString *code = authResp.code;
            NSString *state = authResp.state;
            
            NSLog(@"✅ 微信登录授权成功 - Code: %@", code);
            
            // 构建认证信息
            NSMutableDictionary *authInfo = [NSMutableDictionary dictionary];
            if (code) authInfo[@"code"] = code;
            if (state) authInfo[@"state"] = state;
            authInfo[@"authType"] = @(ThirdPartyAuthTypeWeChat);
            
            if (self.weChatSuccessBlock) {
                self.weChatSuccessBlock(ThirdPartyAuthTypeWeChat, authInfo);
            }
        } else {
            // 微信登录失败
            NSString *errorMsg = @"微信登录失败";
            if (resp.errCode == WXErrCodeUserCancel) {
                errorMsg = @"用户取消微信登录";
            } else if (resp.errCode == WXErrCodeAuthDeny) {
                errorMsg = @"用户拒绝微信登录";
            } else if (resp.errCode == WXErrCodeUnsupport) {
                errorMsg = @"微信不支持该操作";
            }
            
            NSLog(@"❌ 微信登录失败 - Code: %d, Msg: %@", resp.errCode, errorMsg);
            
            if (self.weChatFailureBlock) {
                NSError *error = [NSError errorWithDomain:@"ThirdPartyAuthErrorDomain"
                                                      code:resp.errCode
                                                  userInfo:@{NSLocalizedDescriptionKey: errorMsg}];
                self.weChatFailureBlock(ThirdPartyAuthTypeWeChat, error);
            }
        }
        
        // 清除回调
        self.weChatSuccessBlock = nil;
        self.weChatFailureBlock = nil;
    }
}

- (void)onReq:(BaseReq *)req {
    // 微信请求回调（登录不需要处理）
}

@end
