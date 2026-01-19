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
        
        // 设置默认路径前缀
        _defaultPathPrefix = @"/ws";
        
        // 不再自动加载默认路径配置
        // 路径配置改为按需注册，或直接使用路径字符串
        // 如果需要预加载某些常用路径，可以手动调用 loadDefaultPathConfigs
    }
    return self;
}

/// 加载默认路径配置（可选，按需调用）
/// 注意：此方法已废弃，建议直接使用路径字符串，无需预注册
- (void)loadDefaultPathConfigs {
    // 仅保留常用路径的注册，其他路径可以直接使用路径字符串
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

/// 获取路径（智能解析）
/// 1. 如果 pathName 已注册，返回注册的路径
/// 2. 如果 pathName 以 / 开头，直接作为路径使用
/// 3. 否则，按照约定转换为路径（如 @"chat" -> @"/ws/chat"）
- (NSString *)pathForPathName:(NSString *)pathName {
    if (!pathName || pathName.length == 0) {
        NSLog(@"⚠️ WebSocket路径名称为空");
        return @"";
    }
    
    // 1. 优先查找已注册的路径
    WebSocketPathConfig *config = self.pathConfigs[pathName];
    if (config && config.path.length > 0) {
        return config.path;
    }
    
    // 2. 如果 pathName 以 / 开头，直接作为路径使用
    if ([pathName hasPrefix:@"/"]) {
        return pathName;
    }
    
    // 3. 按照约定转换为路径：pathName -> {defaultPathPrefix}/pathName
    // 例如：如果 defaultPathPrefix 为 @"/ws"，则 @"chat" -> @"/ws/chat"
    // 如果 defaultPathPrefix 为 @"/websocket/v2"，则 @"chat" -> @"/websocket/v2/chat"
    NSString *prefix = self.defaultPathPrefix ?: @"/ws";
    // 确保前缀以 / 开头，不以 / 结尾
    if (![prefix hasPrefix:@"/"]) {
        prefix = [NSString stringWithFormat:@"/%@", prefix];
    }
    if ([prefix hasSuffix:@"/"]) {
        prefix = [prefix substringToIndex:prefix.length - 1];
    }
    NSString *convertedPath = [NSString stringWithFormat:@"%@/%@", prefix, pathName];
    NSLog(@"ℹ️ WebSocket路径名称 %@ 未注册，使用约定路径: %@ (前缀: %@)", pathName, convertedPath, prefix);
    return convertedPath;
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
