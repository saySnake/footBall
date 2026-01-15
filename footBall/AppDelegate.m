//
//  AppDelegate.m
//  footBall
//
//  Created by 张玮 on 2026/1/15.
//

#import "AppDelegate.h"
#import "ThemeManager.h"
#import "LanguageManager.h"
#import "ColorManager.h"
#import "APIManager.h"
#import "APIEnvironmentManager.h"
#import "APIRequestInterceptor.h"
#import "AuthManager.h"
#import "PagFilePreloader.h"
#import <DoraemonKit/DoraemonManager.h>

#ifdef DEBUG
#import <easydebug/EasyDebug.h>
#import "EasyDebugPositionConfig.h"
#endif

@interface AppDelegate ()

@end

@implementation AppDelegate

// 重写 window 的 getter，返回 SceneDelegate 的 window（兼容 DoKit）
- (UIWindow *)window {
    if (@available(iOS 13.0, *)) {
        // iOS 13+ 使用 SceneDelegate
        NSArray<UIWindowScene *> *windowScenes = [UIApplication sharedApplication].connectedScenes.allObjects;
        for (UIWindowScene *scene in windowScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                for (UIWindow *window in scene.windows) {
                    if (window.isKeyWindow) {
                        return window;
                    }
                }
                // 如果没有 keyWindow，返回第一个 window
                if (scene.windows.count > 0) {
                    return scene.windows.firstObject;
                }
            }
        }
    } else {
        // iOS 12 及以下，直接返回 keyWindow
        return [UIApplication sharedApplication].keyWindow;
    }
    return nil;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // 初始化主题管理器
    [[ThemeManager sharedManager] setupThemeConfiguration];
    
    // 初始化颜色管理器（支持白天/夜间模式）
    [[ColorManager sharedManager] setupColorConfiguration];
    
    // 初始化语言管理器
    [LanguageManager sharedManager];
    
    // 预加载 PAG 文件（在应用启动时就开始加载，避免首次使用卡顿）
    // preloadRefreshHeaderFiles 内部使用高优先级队列异步加载
    [[PagFilePreloader sharedPreloader] preloadRefreshHeaderFiles];
    NSLog(@"✅ PAG 文件预加载已启动");
    
    // 初始化API环境管理器
    APIEnvironmentManager *envManager = [APIEnvironmentManager sharedManager];
    NSLog(@"📍 当前API环境: %@", [APIEnvironmentManager displayNameForEnvironment:envManager.currentEnvironment]);
    NSLog(@"📍 Base URL: %@", envManager.currentBaseURL);
    
    // 配置网络管理器
    APIManager *apiManager = [APIManager sharedManager];
    apiManager.timeoutInterval = 30.0;
    apiManager.commonHeaders = @{
        @"Content-Type": @"application/json",
        @"Accept": @"application/json"
    };
    
    // 配置认证拦截器 - 自动添加Authorization请求头
    APIAuthenticationInterceptor *authInterceptor = 
        [[APIAuthenticationInterceptor alloc] initWithTokenProvider:^NSString *{
            // 从AuthManager获取token
            return [[AuthManager sharedManager] getToken];
        }];
    [apiManager addInterceptor:authInterceptor];
    NSLog(@"✅ 认证拦截器已配置，将自动添加Authorization请求头");
    
    // Debug模式下添加日志拦截器
    #ifdef DEBUG
        APILoggingInterceptor *loggingInterceptor = 
            [[APILoggingInterceptor alloc] initWithLogLevel:2];
        [apiManager addInterceptor:loggingInterceptor];
        NSLog(@"✅ 日志拦截器已配置（Debug模式）");
    #endif
    
    // 初始化DoKit（仅在Debug模式下启用）
    // 注意：DoKit 的初始化移到 SceneDelegate 中，通过 BVAPPDebugTool 统一管理
    #ifdef DEBUG
        NSLog(@"✅ AppDelegate: DoKit 将在 SceneDelegate 中初始化");
        
        // 初始化 EasyDebug
        [EasyDebug shared].isOn = YES;
        // 配置模块：网络监控 + 性能监控
        EasyDebugModule modules = EasyDebugNetMonitor | EasyDebugPerformance;
        [EasyDebug config:modules];
        
//        [EasyDebugPositionConfig configButtonPosition:1  // 1=右下角
//                                           offsetX:0
//                                           offsetY:-10];

//        // 记录启动日志
//        [EasyDebug logWithTag:@"AppLifecycle" 
//                          log:@"应用启动 - EasyDebug 已初始化"];
        
        NSLog(@"✅ EasyDebug 已初始化");
    #endif
    
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
