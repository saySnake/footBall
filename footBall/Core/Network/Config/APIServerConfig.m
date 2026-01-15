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
    APIServerConfig *config = [[APIServerConfig alloc] init];
    config.environment = environment;
    config.serverURL = serverURL;
    config.displayName = displayName;
    return config;
}

@end

@interface APIServerConfigManager ()

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSString *> *serverURLs;

/// 从 BVAPPEnvironmentHostManager 同步服务器地址（Debug模式下）
- (void)syncServerURLsFromEnvironmentHostManager;

/// 获取环境显示名称
- (NSString *)displayNameForEnvironment:(APIEnvironment)environment;

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
        
        // 初始化默认服务器地址配置
        // 可以从 BVAPPEnvironmentHostManager 中提取 domainUrl
        [self loadDefaultServerConfigs];
    }
    return self;
}

- (void)loadDefaultServerConfigs {
    // 默认服务器地址配置
    // 注意：这些是示例地址，需要根据实际项目修改
    _serverURLs[@(APIEnvironmentTest)] = @"https://test-api.example.com";
    _serverURLs[@(APIEnvironmentUAT)] = @"https://uat-api.example.com";
    _serverURLs[@(APIEnvironmentAppStore)] = @"https://api.example.com";
    
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
        
        // 更新服务器地址
        [self setServerURL:domainUrl forEnvironment:env];
        NSLog(@"✅ 已同步服务器地址: %@ -> %@ (productFlag: %ld)", 
              [self displayNameForEnvironment:env], domainUrl, (long)productFlag);
    }
}

#endif

- (NSString *)serverURLForEnvironment:(APIEnvironment)environment {
    NSString *serverURL = self.serverURLs[@(environment)];
    if (!serverURL || serverURL.length == 0) {
        NSLog(@"⚠️ 未找到环境 %ld 的服务器地址，使用Test环境", (long)environment);
        return self.serverURLs[@(APIEnvironmentTest)] ?: @"";
    }
    return serverURL;
}

- (NSArray<APIServerConfig *> *)allServerConfigs {
    NSMutableArray<APIServerConfig *> *configs = [NSMutableArray array];
    for (NSNumber *envNum in self.serverURLs.allKeys) {
        APIEnvironment env = [envNum integerValue];
        NSString *serverURL = self.serverURLs[envNum];
        NSString *displayName = [self displayNameForEnvironment:env];
        
        APIServerConfig *config = [APIServerConfig configWithEnvironment:env
                                                               serverURL:serverURL
                                                             displayName:displayName];
        [configs addObject:config];
    }
    return [configs copy];
}

- (void)setServerURL:(NSString *)serverURL forEnvironment:(APIEnvironment)environment {
    if (!serverURL || serverURL.length == 0) {
        NSLog(@"⚠️ 服务器地址为空，忽略设置");
        return;
    }
    
    // 确保 URL 格式正确
    NSString *cleanURL = serverURL;
    if ([cleanURL hasSuffix:@"/"]) {
        cleanURL = [cleanURL substringToIndex:cleanURL.length - 1];
    }
    
    self.serverURLs[@(environment)] = cleanURL;
    NSLog(@"✅ 已更新环境 %ld 的服务器地址: %@", (long)environment, cleanURL);
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
