# 第三方登录使用示例

## 配置说明

### 1. 微信登录配置

#### 在 AppDelegate.m 中配置微信 AppID 和 Universal Link

```objective-c
// 在 didFinishLaunchingWithOptions 方法中
NSString *weChatAppId = @"你的微信AppID";
NSString *weChatUniversalLink = @"https://your-domain.com/wechat/";
[[ThirdPartyAuthManager sharedManager] registerWeChatAppId:weChatAppId universalLink:weChatUniversalLink];
```

#### 在 Info.plist 中配置 URL Scheme

将 `wxYOUR_WECHAT_APPID` 替换为你的微信 AppID（格式：wx + AppID）

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>wx你的微信AppID</string>
        </array>
    </dict>
</array>
```

### 2. 苹果登录配置

苹果登录无需额外配置，系统会自动处理。但需要注意：
- 需要 iOS 13.0 及以上版本
- 需要在 Xcode 中开启 Sign in with Apple 能力（Capabilities）

## 使用方法

### 方式一：使用 AuthManager（推荐）

```objective-c
#import "AuthManager.h"

// 苹果登录
[[AuthManager sharedManager] loginWithAppleSuccess:^(NSDictionary *response) {
    NSLog(@"登录成功: %@", response);
    // 处理登录成功逻辑
} failure:^(NSError *error) {
    NSLog(@"登录失败: %@", error.localizedDescription);
    // 处理登录失败逻辑
}];

// 微信登录
[[AuthManager sharedManager] loginWithWeChatSuccess:^(NSDictionary *response) {
    NSLog(@"登录成功: %@", response);
    // 处理登录成功逻辑
} failure:^(NSError *error) {
    NSLog(@"登录失败: %@", error.localizedDescription);
    // 处理登录失败逻辑
}];
```

### 方式二：直接使用 ThirdPartyAuthManager

```objective-c
#import "ThirdPartyAuthManager.h"

// 苹果登录
[[ThirdPartyAuthManager sharedManager] loginWithAppleSuccess:^(ThirdPartyAuthType authType, NSDictionary *authInfo) {
    // authInfo 包含：
    // - userID: 苹果用户ID
    // - identityToken: 身份令牌
    // - authorizationCode: 授权码
    // - email: 邮箱（首次登录时才有）
    // - displayName: 显示名称（首次登录时才有）
    NSLog(@"苹果登录成功: %@", authInfo);
} failure:^(ThirdPartyAuthType authType, NSError *error) {
    NSLog(@"苹果登录失败: %@", error.localizedDescription);
}];

// 微信登录
[[ThirdPartyAuthManager sharedManager] loginWithWeChatSuccess:^(ThirdPartyAuthType authType, NSDictionary *authInfo) {
    // authInfo 包含：
    // - code: 微信授权码
    // - state: 状态码
    NSLog(@"微信登录成功: %@", authInfo);
} failure:^(ThirdPartyAuthType authType, NSError *error) {
    NSLog(@"微信登录失败: %@", error.localizedDescription);
}];
```

## 后端接口对接

第三方登录成功后，需要将获取到的信息发送到后端进行验证：

### 苹果登录
后端需要接收以下参数：
- `authType`: 登录类型（1 = 苹果登录）
- `identityToken`: 身份令牌（JWT格式）
- `authorizationCode`: 授权码
- `userID`: 苹果用户ID

### 微信登录
后端需要接收以下参数：
- `authType`: 登录类型（2 = 微信登录）
- `code`: 微信授权码
- `state`: 状态码

后端验证成功后，返回标准的 token，AuthManager 会自动保存。

## 注意事项

1. **微信登录**：
   - 需要用户安装微信客户端
   - 需要在微信开放平台注册应用并获取 AppID
   - 需要配置 Universal Link（iOS 9.0+）

2. **苹果登录**：
   - 需要 iOS 13.0 及以上版本
   - 首次登录会返回用户邮箱和姓名，后续登录不会返回
   - 需要在 Xcode 中开启 Sign in with Apple 能力

3. **Token 管理**：
   - 登录成功后，Token 会自动保存到本地
   - 可以通过 `[[AuthManager sharedManager] isLoggedIn]` 检查登录状态
   - 登出时调用 `[[AuthManager sharedManager] clearToken]`
