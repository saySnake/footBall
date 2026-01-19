//
//  APIEnvironmentManager.m
//  footBall
//
//  Created on 2026/1/15.
//

#import "APIEnvironmentManager.h"
#import "APIServerConfig.h"
#import "APIPathConfig.h"

@interface APIEnvironmentManager ()

@end

@implementation APIEnvironmentManager

+ (instancetype)sharedManager {
    static APIEnvironmentManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[APIEnvironmentManager alloc] init];
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
        NSNumber *savedEnvironment = [[NSUserDefaults standardUserDefaults] objectForKey:@"APIEnvironment"];
        if (savedEnvironment) {
            _currentEnvironment = [savedEnvironment integerValue];
        }
        
        // 初始化时同步服务器地址（从 BVAPPEnvironmentHostManager）
        #ifdef DEBUG
            [[APIServerConfigManager sharedManager] syncServerURLsFromEnvironmentHostManager];
        #endif
    }
    return self;
}

- (NSString *)currentBaseURL {
    return [self baseURLForEnvironment:self.currentEnvironment];
}

- (NSString *)baseURLForEnvironment:(APIEnvironment)environment {
    // 从 APIServerConfigManager 获取服务器地址
    return [[APIServerConfigManager sharedManager] serverURLForEnvironment:environment];
}

- (NSString *)fullURLForPathName:(NSString *)pathName {
    NSString *baseURL = self.currentBaseURL;
    NSString *path = [self pathForPathName:pathName];
    
    if (!path) {
        NSLog(@"⚠️ 未找到路径名称: %@", pathName);
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
    // 从 APIPathConfigManager 获取路径（支持智能解析）
    return [[APIPathConfigManager sharedManager] pathForPathName:pathName];
}

- (void)switchToEnvironment:(APIEnvironment)environment {
    if (environment < APIEnvironmentTest || environment > APIEnvironmentAppStore) {
        NSLog(@"⚠️ 无效的环境类型: %ld", (long)environment);
        return;
    }
    
    self.currentEnvironment = environment;
    
    // 保存到UserDefaults（仅在Debug模式下保存，生产环境不保存）
    #ifdef DEBUG
        [[NSUserDefaults standardUserDefaults] setObject:@(environment) forKey:@"APIEnvironment"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    #endif
    
    NSLog(@"✅ API环境已切换为: %@", [APIEnvironmentManager displayNameForEnvironment:environment]);
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
