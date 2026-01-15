//
//  WebSocketPathConfig.m
//  footBall
//
//  Created on 2026/1/15.
//

#import "WebSocketPathConfig.h"
#import "WebSocketPathNames.h"
#import "WebSocketPathValues.h"

@implementation WebSocketPathConfig

+ (instancetype)configWithName:(NSString *)name path:(NSString *)path {
    return [self configWithName:name path:path description:nil];
}

+ (instancetype)configWithName:(NSString *)name path:(NSString *)path description:(nullable NSString *)description {
    WebSocketPathConfig *config = [[WebSocketPathConfig alloc] init];
    config.name = name;
    config.path = path;
    config.pathDescription = description;
    return config;
}

@end

@interface WebSocketPathConfigManager ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, WebSocketPathConfig *> *pathConfigs;

@end

@implementation WebSocketPathConfigManager

+ (instancetype)sharedManager {
    static WebSocketPathConfigManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WebSocketPathConfigManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _pathConfigs = [NSMutableDictionary dictionary];
        
        // 加载默认路径配置
        [self loadDefaultPathConfigs];
    }
    return self;
}

- (void)loadDefaultPathConfigs {
    // 注册默认WebSocket路径
    // 使用路径名称常量和路径值常量，实现配置分离
    
    // 聊天模块
    [self registerPathWithName:WebSocketPathNameChat path:WebSocketPathValueChat description:@"聊天WebSocket"];
    [self registerPathWithName:WebSocketPathNameChatRoom path:WebSocketPathValueChatRoom description:@"聊天室WebSocket"];
    
    // 通知模块
    [self registerPathWithName:WebSocketPathNameNotification path:WebSocketPathValueNotification description:@"通知WebSocket"];
    [self registerPathWithName:WebSocketPathNameNotificationSystem path:WebSocketPathValueNotificationSystem description:@"系统通知WebSocket"];
    
    // 实时数据模块
    [self registerPathWithName:WebSocketPathNameRealtime path:WebSocketPathValueRealtime description:@"实时数据WebSocket"];
    [self registerPathWithName:WebSocketPathNameRealtimePrice path:WebSocketPathValueRealtimePrice description:@"实时价格WebSocket"];
    
    // 其他模块可以根据需要添加
    // 在 WebSocketPathNames.h/m 中添加路径名称常量
    // 在 WebSocketPathValues.h/m 中添加路径值常量
    // 然后在这里注册： [self registerPathWithName:WebSocketPathNameLive path:WebSocketPathValueLive description:@"直播WebSocket"];
}

- (NSString *)pathForPathName:(NSString *)pathName {
    if (!pathName || pathName.length == 0) {
        NSLog(@"⚠️ WebSocket路径名称为空");
        return @"";
    }
    
    WebSocketPathConfig *config = self.pathConfigs[pathName];
    if (!config) {
        NSLog(@"⚠️ 未找到WebSocket路径名称: %@", pathName);
        return @"";
    }
    
    return config.path ?: @"";
}

- (NSDictionary<NSString *, WebSocketPathConfig *> *)allPathConfigs {
    return [self.pathConfigs copy];
}

- (void)registerPathConfig:(WebSocketPathConfig *)pathConfig {
    if (!pathConfig || !pathConfig.name || pathConfig.name.length == 0) {
        NSLog(@"⚠️ WebSocket路径配置无效，忽略注册");
        return;
    }
    
    self.pathConfigs[pathConfig.name] = pathConfig;
    NSLog(@"✅ 已注册WebSocket路径: %@ -> %@", pathConfig.name, pathConfig.path);
}

- (void)registerPathWithName:(NSString *)name path:(NSString *)path {
    WebSocketPathConfig *config = [WebSocketPathConfig configWithName:name path:path];
    [self registerPathConfig:config];
}

- (void)registerPathWithName:(NSString *)name path:(NSString *)path description:(nullable NSString *)description {
    WebSocketPathConfig *config = [WebSocketPathConfig configWithName:name path:path description:description];
    [self registerPathConfig:config];
}

- (void)removePathConfigWithName:(NSString *)pathName {
    if (!pathName || pathName.length == 0) {
        return;
    }
    
    [self.pathConfigs removeObjectForKey:pathName];
    NSLog(@"✅ 已移除WebSocket路径: %@", pathName);
}

- (void)clearAllPathConfigs {
    [self.pathConfigs removeAllObjects];
    NSLog(@"✅ 已清空所有WebSocket路径配置");
}

@end
