//
//  NetworkEnvironmentManager.m
//  footBall
//
//  Created on 2026/1/15.
//

#import "NetworkEnvironmentManager.h"
#import "APIEnvironmentManager.h"
#import "WebSocketEnvironmentManager.h"
#import "WebSocketManager.h"

@implementation NetworkEnvironmentManager

+ (instancetype)sharedManager {
    static NetworkEnvironmentManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NetworkEnvironmentManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 默认使用Test环境
        #ifdef DEBUG
            _currentEnvironment = APIEnvironmentTest;
        #else
            _currentEnvironment = APIEnvironmentAppStore;
        #endif
        
        // 尝试从UserDefaults读取保存的环境配置
        NSNumber *savedEnvironment = [[NSUserDefaults standardUserDefaults] objectForKey:@"NetworkEnvironment"];
        if (savedEnvironment) {
            _currentEnvironment = [savedEnvironment integerValue];
        }
        
        // 同步到HTTP和WebSocket环境管理器
        [[APIEnvironmentManager sharedManager] switchToEnvironment:_currentEnvironment];
        [[WebSocketEnvironmentManager sharedManager] switchToEnvironment:_currentEnvironment];
    }
    return self;
}

- (void)switchToEnvironment:(APIEnvironment)environment {
    if (environment < APIEnvironmentTest || environment > APIEnvironmentAppStore) {
        NSLog(@"⚠️ 无效的环境类型: %ld", (long)environment);
        return;
    }
    
    self.currentEnvironment = environment;
    
    // 断开WebSocket连接（如果已连接）
    WebSocketManager *wsManager = [WebSocketManager sharedManager];
    if (wsManager.status == 1) { // WebSocketStatusConnected
        [wsManager disconnect];
    }
    
    // 同时切换HTTP和WebSocket环境
    [[APIEnvironmentManager sharedManager] switchToEnvironment:environment];
    [[WebSocketEnvironmentManager sharedManager] switchToEnvironment:environment];
    
    // 保存到UserDefaults（仅在Debug模式下保存）
    #ifdef DEBUG
        [[NSUserDefaults standardUserDefaults] setObject:@(environment) forKey:@"NetworkEnvironment"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    #endif
    
    NSLog(@"✅ 网络环境已切换为: %@", [NetworkEnvironmentManager displayNameForEnvironment:environment]);
    NSLog(@"📍 HTTP Base URL: %@", [[APIEnvironmentManager sharedManager] currentBaseURL]);
    NSLog(@"📍 WebSocket Base URL: %@", [[WebSocketEnvironmentManager sharedManager] currentBaseURL]);
}

+ (NSString *)displayNameForEnvironment:(APIEnvironment)environment {
    switch (environment) {
        case APIEnvironmentTest:
            return @"Test";
        case APIEnvironmentUAT:
            return @"UAT";
        case APIEnvironmentAppStore:
            return @"AppStore";
        default:
            return @"Unknown";
    }
}

@end
