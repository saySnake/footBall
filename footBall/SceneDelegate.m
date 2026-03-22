//
//  SceneDelegate.m
//  footBall
//
//  Created on 2026/1/15.
//

#import "SceneDelegate.h"
#import "MainTabBarController.h"
#import "AuthManager.h"
#import "ThemeObserverView.h"
#import <DoraemonKit/DoraemonManager.h>
#ifdef DEBUG
#import "BVAPPDebugTool.h"
#import "BVAPPEnvironmentHostManager.h"
#endif
#import "LoginChoiceViewController.h"
#import "TeamSelectionViewController.h"
@interface SceneDelegate ()

@property (nonatomic, strong) ThemeObserverView *themeObserverView; // 用于监听主题变化的透明视图

@end

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if ([scene isKindOfClass:[UIWindowScene class]]) {
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
        
        // 根据登录状态直接决定根视图控制器（不再使用 SplashViewController）
        UIViewController *rootVC = nil;
        if ([AuthManager sharedManager].isLoggedIn) {
            // 已登录，进入底部 4 个 Tab 的主界面
            self.window.rootViewController = [TeamSelectionViewController new];//[[MainTabBarController alloc] init];
        } else {
            // 未登录，进入登录流程的第一个页面（需要 Nav 以便 push）
            LoginChoiceViewController *rootVC = [LoginChoiceViewController new];
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:rootVC];
            self.window.rootViewController = nav;
        }
        
        [self.window makeKeyAndVisible];
        
        // 添加主题监听视图（透明，仅用于监听主题变化）
        [self setupThemeObserver];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenExpiredNotification) name:TokenExpiredNotification object:nil];
        // 初始化 DoKit（仅在Debug模式下，且非生产环境）
        // 注意：必须在 window makeKeyAndVisible 之后初始化
        #ifdef DEBUG
            // 延迟一下确保 window 完全显示
            dispatch_async(dispatch_get_main_queue(), ^{
                // 检查是否为生产环境
                BOOL isProduction = [BVAPPEnvironmentHostManager shareInstance].productFlag;
                NSLog(@"🔍 当前环境 productFlag: %@", isProduction ? @"YES (生产环境)" : @"NO (非生产环境)");
                
                if (!isProduction) {
                    // 非生产环境，初始化调试工具
                    NSLog(@"✅ 开始初始化 DoKit...");
                    [BVAPPDebugTool setup];
                } else {
                    // 生产环境，不显示 DoKit
                    NSLog(@"⚠️ 生产环境，DoKit 已禁用");
                }
            });
        #endif
    }
}

- (void)tokenExpiredNotification {
    LoginChoiceViewController *rootVC = [LoginChoiceViewController new];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:rootVC];
    self.window.rootViewController = nav;
}
- (void)sceneDidDisconnect:(UIScene *)scene {
    // Called as the scene is being released by the system.
    // This occurs shortly after the scene enters the background, or when its session is discarded.
    // Release any resources associated with this scene that can be re-created the next time the scene connects.
    // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
}


- (void)sceneDidBecomeActive:(UIScene *)scene {
    // Called when the scene has moved from an inactive state to an active state.
    // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
}


- (void)sceneWillResignActive:(UIScene *)scene {
    // Called when the scene will move from an active state to an inactive state.
    // This may occur due to temporary interruptions (ex. an incoming phone call).
}


- (void)sceneWillEnterForeground:(UIScene *)scene {
    // Called as the scene transitions from the background to the foreground.
    // Use this method to undo the changes made on entering the background.
}


- (void)sceneDidEnterBackground:(UIScene *)scene {
    // Called as the scene transitions from the foreground to the background.
    // Use this method to save data, release shared resources, and store enough scene-specific state information
    // to restore the scene back to its current state.
}

#pragma mark - Theme Observer

- (void)setupThemeObserver {
    // 创建一个透明的视图用于监听主题变化
    // 这个视图会被添加到 window 上，但不会显示，仅用于监听 traitCollection 变化
    self.themeObserverView = [[ThemeObserverView alloc] initWithFrame:self.window.bounds];
    self.themeObserverView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.window addSubview:self.themeObserverView];
    [self.window sendSubviewToBack:self.themeObserverView];
}

@end
