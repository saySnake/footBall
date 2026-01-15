//
//  WebSocketEnvironmentManager.m
//  footBall
//
//  Created on 2026/1/15.
//

#import "WebSocketEnvironmentManager.h"
#import "APIServerConfig.h"
#import "WebSocketPathConfig.h"

@interface WebSocketEnvironmentManager ()

@end

@implementation WebSocketEnvironmentManager

+ (instancetype)sharedManager {
    static WebSocketEnvironmentManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WebSocketEnvironmentManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 默认使用Test环境（开发时）
        // 生产环境可以通过编译配置或UserDefaults设置
        #ifdef DEBUG
            _currentEnvironment = APIEnvironmentTest;
        #else
            // 生产环境默认使用AppStore
            _currentEnvironment = APIEnvironmentAppStore;
        #endif
        
        // 尝试从UserDefaults读取保存的环境配置
        NSNumber *savedEnvironment = [[NSUserDefaults standardUserDefaults] objectForKey:@"WebSocketEnvironment"];
        if (savedEnvironment) {
            _currentEnvironment = [savedEnvironment integerValue];
        }
    }
    return self;
}

- (NSString *)currentBaseURL {
    return [self baseURLForEnvironment:self.currentEnvironment];
}

- (NSString *)baseURLForEnvironment:(APIEnvironment)environment {
    // 优先从 BVAPPEnvironmentHostManager 获取 WebSocket URL（Debug 模式）
    #ifdef DEBUG
        Class envHostManagerClass = NSClassFromString(@"BVAPPEnvironmentHostManager");
        if (envHostManagerClass) {
            SEL shareInstanceSel = NSSelectorFromString(@"shareInstance");
            if ([envHostManagerClass respondsToSelector:shareInstanceSel]) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                id envHostManager = [envHostManagerClass performSelector:shareInstanceSel];
                #pragma clang diagnostic pop
                
                // 获取当前选中的 WebSocket URL
                SEL currentWebSocketBaseURLSel = NSSelectorFromString(@"currentWebSocketBaseURL");
                if ([envHostManager respondsToSelector:currentWebSocketBaseURLSel]) {
                    #pragma clang diagnostic push
                    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                    NSString *wsURL = [envHostManager performSelector:currentWebSocketBaseURLSel];
                    #pragma clang diagnostic pop
                    
                    if (wsURL && wsURL.length > 0) {
                        NSLog(@"✅ 从 BVAPPEnvironmentHostManager 获取 WebSocket URL: %@", wsURL);
                        return wsURL;
                    }
                }
            }
        }
    #endif
    
    // 从 APIServerConfigManager 获取服务器地址
    // 注意：WebSocket 使用 ws:// 或 wss:// 协议
    NSString *httpURL = [[APIServerConfigManager sharedManager] serverURLForEnvironment:environment];
    
    // 将 http:// 或 https:// 转换为 ws:// 或 wss://
    NSString *wsURL = httpURL;
    if ([wsURL hasPrefix:@"https://"]) {
        wsURL = [wsURL stringByReplacingOccurrencesOfString:@"https://" withString:@"wss://"];
    } else if ([wsURL hasPrefix:@"http://"]) {
        wsURL = [wsURL stringByReplacingOccurrencesOfString:@"http://" withString:@"ws://"];
    } else {
        // 如果没有协议前缀，默认使用 wss://
        wsURL = [NSString stringWithFormat:@"wss://%@", wsURL];
    }
    
    return wsURL;
}

- (NSString *)fullWebSocketURLForPathName:(NSString *)pathName {
    NSString *baseURL = self.currentBaseURL;
    NSString *path = [self pathForPathName:pathName];
    
    if (!path || path.length == 0) {
        NSLog(@"⚠️ 未找到WebSocket路径名称: %@", pathName);
        return baseURL;
    }
    
    // 确保baseURL不以/结尾，path以/开头
    if ([baseURL hasSuffix:@"/"]) {
        baseURL = [baseURL substringToIndex:baseURL.length - 1];
    }
    if (![path hasPrefix:@"/"]) {
        path = [NSString stringWithFormat:@"/%@", path];
    }
    
    return [NSString stringWithFormat:@"%@%@", baseURL, path];
}

- (NSString *)pathForPathName:(NSString *)pathName {
    // 从 WebSocketPathConfigManager 获取路径
    return [[WebSocketPathConfigManager sharedManager] pathForPathName:pathName];
}

- (void)switchToEnvironment:(APIEnvironment)environment {
    if (environment < APIEnvironmentTest || environment > APIEnvironmentAppStore) {
        NSLog(@"⚠️ 无效的环境类型: %ld", (long)environment);
        return;
    }
    
    self.currentEnvironment = environment;
    
    // 保存到UserDefaults（仅在Debug模式下保存，生产环境不保存）
    #ifdef DEBUG
        [[NSUserDefaults standardUserDefaults] setObject:@(environment) forKey:@"WebSocketEnvironment"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    #endif
    
    NSLog(@"✅ WebSocket环境已切换为: %@", [WebSocketEnvironmentManager displayNameForEnvironment:environment]);
    NSLog(@"📍 Base URL: %@", self.currentBaseURL);
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
