//
//  APIServerConfig.m
//  footBall
//
//  Created on 2026/1/15.
//

#import "APIServerConfig.h"

@implementation APIServerConfig

+ (instancetype)configWithEnvironment:(APIEnvironment)environment
                            serverURL:(NSString *)serverURL
                          displayName:(NSString *)displayName {
    return [self configWithEnvironment:environment
                             serverURL:serverURL
                          webSocketURL:nil
                           displayName:displayName];
}

+ (instancetype)configWithEnvironment:(APIEnvironment)environment
                            serverURL:(NSString *)serverURL
                         webSocketURL:(nullable NSString *)webSocketURL
                          displayName:(NSString *)displayName {
    APIServerConfig *config = [[APIServerConfig alloc] init];
    config.environment = environment;
    config.serverURL = serverURL;
    config.webSocketURL = webSocketURL;
    config.displayName = displayName;
    return config;
}

@end

@interface APIServerConfigManager ()

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSString *> *serverURLs; // HTTP地址
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSString *> *webSocketURLs; // WebSocket地址

/// 从 BVAPPEnvironmentHostManager 同步服务器地址（Debug模式下）
- (void)syncServerURLsFromEnvironmentHostManager;

/// 获取环境显示名称
- (NSString *)displayNameForEnvironment:(APIEnvironment)environment;

/// 将HTTP地址转换为WebSocket地址
/// @param httpURL HTTP地址
/// @return WebSocket地址
- (NSString *)convertHTTPURLToWebSocketURL:(NSString *)httpURL;

@end

@implementation APIServerConfigManager

+ (instancetype)sharedManager {
    static APIServerConfigManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[APIServerConfigManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _serverURLs = [NSMutableDictionary dictionary];
        _webSocketURLs = [NSMutableDictionary dictionary];
        
        // 初始化默认服务器地址配置
        // 可以从 BVAPPEnvironmentHostManager 中提取 domainUrl
        [self loadDefaultServerConfigs];
    }
    return self;
}

- (void)loadDefaultServerConfigs {
    // 默认HTTP服务器地址配置
    // 注意：这些是示例地址，需要根据实际项目修改
    _serverURLs[@(APIEnvironmentTest)] = @"https://112.126.56.42:8443";
    _serverURLs[@(APIEnvironmentUAT)] = @"https://112.126.56.42:8443";
    _serverURLs[@(APIEnvironmentAppStore)] = @"https://112.126.56.42:8443";
    
    // WebSocket地址默认从HTTP地址自动转换，也可以单独配置
    // 如果需要独立的WebSocket地址，可以在这里设置：
    // _webSocketURLs[@(APIEnvironmentTest)] = @"wss://test-ws.example.com";
    
    // 尝试从 BVAPPEnvironmentHostManager 同步服务器地址
    #ifdef DEBUG
        [self syncServerURLsFromEnvironmentHostManager];
    #endif
}

#ifdef DEBUG
- (void)syncServerURLsFromEnvironmentHostManager {
    // 同步 BVAPPEnvironmentHostManager 中的服务器地址
    // 遍历所有环境配置，提取 domainUrl
    Class envHostManagerClass = NSClassFromString(@"BVAPPEnvironmentHostManager");
    if (!envHostManagerClass) {
        NSLog(@"⚠️ BVAPPEnvironmentHostManager 类不存在");
        return;
    }
    
    SEL shareInstanceSel = NSSelectorFromString(@"shareInstance");
    if (![envHostManagerClass respondsToSelector:shareInstanceSel]) {
        NSLog(@"⚠️ BVAPPEnvironmentHostManager 没有 shareInstance 方法");
        return;
    }
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    id envHostManager = [envHostManagerClass performSelector:shareInstanceSel];
    #pragma clang diagnostic pop
    
    // 获取 datasource
    SEL datasourceSel = NSSelectorFromString(@"datasource");
    if (![envHostManager respondsToSelector:datasourceSel]) {
        NSLog(@"⚠️ BVAPPEnvironmentHostManager 没有 datasource 方法");
        return;
    }
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    NSArray *datasource = [envHostManager performSelector:datasourceSel];
    #pragma clang diagnostic pop
    
    if (!datasource || datasource.count == 0) {
        NSLog(@"⚠️ BVAPPEnvironmentHostManager datasource 为空");
        return;
    }
    
    // 遍历所有环境配置
    for (id item in datasource) {
        // 获取 domainUrl（使用 KVC 安全获取）
        NSString *domainUrl = nil;
        @try {
            id urlValue = [item valueForKey:@"domainUrl"];
            if ([urlValue isKindOfClass:[NSString class]]) {
                domainUrl = urlValue;
            } else if (urlValue) {
                domainUrl = [urlValue description];
            }
        } @catch (NSException *exception) {
            NSLog(@"⚠️ 获取 domainUrl 失败: %@", exception.reason);
            continue; // 跳过这个item
        }
        
        if (!domainUrl || domainUrl.length == 0) {
            continue;
        }
        
        // 获取 productFlag
        // 注意：productFlag 是 NSInteger 类型（基本类型），不能直接使用 performSelector
        // 使用 KVC (Key-Value Coding) 来安全获取属性值
        NSInteger productFlag = 0;
        @try {
            id flagValue = [item valueForKey:@"productFlag"];
            if (flagValue) {
                if ([flagValue isKindOfClass:[NSNumber class]]) {
                    productFlag = [flagValue integerValue];
                } else if ([flagValue respondsToSelector:@selector(integerValue)]) {
                    productFlag = [flagValue integerValue];
                }
            }
        } @catch (NSException *exception) {
            NSLog(@"⚠️ 获取 productFlag 失败: %@", exception.reason);
            continue; // 跳过这个item
        }
        
        // 根据 productFlag 映射到 APIEnvironment
        // productFlag: 1=生产, 2=UAT, 3=测试
        APIEnvironment env = APIEnvironmentTest;
        if (productFlag == 1) {
            env = APIEnvironmentAppStore; // 生产环境
        } else if (productFlag == 2) {
            env = APIEnvironmentUAT; // UAT环境
        } else {
            env = APIEnvironmentTest; // 测试环境
        }
        
        // 更新HTTP服务器地址
        [self setServerURL:domainUrl forEnvironment:env];
        
        // 尝试获取WebSocket地址（如果存在）
        NSString *webSocketUrl = nil;
        @try {
            id wsUrlValue = [item valueForKey:@"webSocketUrl"];
            if ([wsUrlValue isKindOfClass:[NSString class]]) {
                webSocketUrl = wsUrlValue;
            } else if (wsUrlValue) {
                webSocketUrl = [wsUrlValue description];
            }
        } @catch (NSException *exception) {
            // WebSocket地址不存在或获取失败，使用自动转换
        }
        
        if (webSocketUrl && webSocketUrl.length > 0) {
            [self setWebSocketURL:webSocketUrl forEnvironment:env];
            NSLog(@"✅ 已同步服务器地址: %@ -> HTTP: %@, WebSocket: %@ (productFlag: %ld)", 
                  [self displayNameForEnvironment:env], domainUrl, webSocketUrl, (long)productFlag);
        } else {
            NSLog(@"✅ 已同步HTTP服务器地址: %@ -> %@ (productFlag: %ld, WebSocket将自动转换)", 
                  [self displayNameForEnvironment:env], domainUrl, (long)productFlag);
        }
    }
}

#endif

- (NSString *)serverURLForEnvironment:(APIEnvironment)environment {
    NSString *serverURL = self.serverURLs[@(environment)];
    if (!serverURL || serverURL.length == 0) {
        NSLog(@"⚠️ 未找到环境 %ld 的HTTP服务器地址，使用Test环境", (long)environment);
        return self.serverURLs[@(APIEnvironmentTest)] ?: @"";
    }
    return serverURL;
}

- (NSString *)webSocketURLForEnvironment:(APIEnvironment)environment {
    // 优先使用配置的WebSocket地址
    NSString *webSocketURL = self.webSocketURLs[@(environment)];
    if (webSocketURL && webSocketURL.length > 0) {
        return webSocketURL;
    }
    
    // 如果未配置，从HTTP地址自动转换
    NSString *httpURL = [self serverURLForEnvironment:environment];
    if (httpURL && httpURL.length > 0) {
        NSString *convertedURL = [self convertHTTPURLToWebSocketURL:httpURL];
        NSLog(@"ℹ️ 环境 %ld 未配置WebSocket地址，自动从HTTP地址转换: %@ -> %@", 
              (long)environment, httpURL, convertedURL);
        return convertedURL;
    }
    
    NSLog(@"⚠️ 未找到环境 %ld 的WebSocket服务器地址", (long)environment);
    return @"";
}

- (NSString *)convertHTTPURLToWebSocketURL:(NSString *)httpURL {
    if (!httpURL || httpURL.length == 0) {
        return @"";
    }
    
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

- (NSArray<APIServerConfig *> *)allServerConfigs {
    NSMutableArray<APIServerConfig *> *configs = [NSMutableArray array];
    
    // 合并所有环境的配置（包括HTTP和WebSocket）
    NSMutableSet<NSNumber *> *allEnvironments = [NSMutableSet setWithArray:self.serverURLs.allKeys];
    [allEnvironments addObjectsFromArray:self.webSocketURLs.allKeys];
    
    for (NSNumber *envNum in allEnvironments) {
        APIEnvironment env = [envNum integerValue];
        NSString *serverURL = self.serverURLs[envNum] ?: @"";
        NSString *webSocketURL = self.webSocketURLs[envNum];
        NSString *displayName = [self displayNameForEnvironment:env];
        
        APIServerConfig *config = [APIServerConfig configWithEnvironment:env
                                                               serverURL:serverURL
                                                            webSocketURL:webSocketURL
                                                             displayName:displayName];
        [configs addObject:config];
    }
    return [configs copy];
}

- (void)setServerURL:(NSString *)serverURL forEnvironment:(APIEnvironment)environment {
    if (!serverURL || serverURL.length == 0) {
        NSLog(@"⚠️ HTTP服务器地址为空，忽略设置");
        return;
    }
    
    // 确保 URL 格式正确
    NSString *cleanURL = serverURL;
    if ([cleanURL hasSuffix:@"/"]) {
        cleanURL = [cleanURL substringToIndex:cleanURL.length - 1];
    }
    
    self.serverURLs[@(environment)] = cleanURL;
    NSLog(@"✅ 已更新环境 %ld 的HTTP服务器地址: %@", (long)environment, cleanURL);
}

- (void)setWebSocketURL:(NSString *)webSocketURL forEnvironment:(APIEnvironment)environment {
    if (!webSocketURL || webSocketURL.length == 0) {
        NSLog(@"⚠️ WebSocket服务器地址为空，忽略设置");
        return;
    }
    
    // 确保 URL 格式正确
    NSString *cleanURL = webSocketURL;
    if ([cleanURL hasSuffix:@"/"]) {
        cleanURL = [cleanURL substringToIndex:cleanURL.length - 1];
    }
    
    // 验证协议
    if (![cleanURL hasPrefix:@"ws://"] && ![cleanURL hasPrefix:@"wss://"]) {
        NSLog(@"⚠️ WebSocket地址格式不正确，应使用 ws:// 或 wss:// 协议，自动添加 wss://");
        cleanURL = [NSString stringWithFormat:@"wss://%@", cleanURL];
    }
    
    self.webSocketURLs[@(environment)] = cleanURL;
    NSLog(@"✅ 已更新环境 %ld 的WebSocket服务器地址: %@", (long)environment, cleanURL);
}

- (void)setServerURL:(NSString *)serverURL
        webSocketURL:(nullable NSString *)webSocketURL
       forEnvironment:(APIEnvironment)environment {
    [self setServerURL:serverURL forEnvironment:environment];
    if (webSocketURL) {
        [self setWebSocketURL:webSocketURL forEnvironment:environment];
    }
}

- (NSString *)displayNameForEnvironment:(APIEnvironment)environment {
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
