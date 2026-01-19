//
//  APIPathConfig.m
//  footBall
//
//  Created on 2026/1/15.
//

#import "APIPathConfig.h"
#import "APIPathNames.h"
#import "APIPathValues.h"

@implementation APIPathConfig

+ (instancetype)configWithName:(NSString *)name path:(NSString *)path {
    return [self configWithName:name path:path description:nil];
}

+ (instancetype)configWithName:(NSString *)name path:(NSString *)path description:(nullable NSString *)description {
    APIPathConfig *config = [[APIPathConfig alloc] init];
    config.name = name;
    config.path = path;
    config.pathDescription = description;
    return config;
}

@end

@interface APIPathConfigManager ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, APIPathConfig *> *pathConfigs;

@end

@implementation APIPathConfigManager

+ (instancetype)sharedManager {
    static APIPathConfigManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[APIPathConfigManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _pathConfigs = [NSMutableDictionary dictionary];
        
        // 设置默认路径前缀
        _defaultPathPrefix = @"/api/v1";
        
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
    // 用户模块
    [self registerPathWithName:APIPathNameUser path:APIPathValueUser description:@"用户相关接口"];
    [self registerPathWithName:APIPathNameUserProfile path:APIPathValueUserProfile description:@"用户资料"];
    [self registerPathWithName:APIPathNameUserList path:APIPathValueUserList description:@"用户列表"];
    
    // 认证模块
    [self registerPathWithName:APIPathNameAuth path:APIPathValueAuth description:@"认证相关接口"];
    [self registerPathWithName:APIPathNameAuthLogin path:APIPathValueAuthLogin description:@"登录"];
    [self registerPathWithName:APIPathNameAuthLogout path:APIPathValueAuthLogout description:@"登出"];
    [self registerPathWithName:APIPathNameAuthRefresh path:APIPathValueAuthRefresh description:@"刷新Token"];
    
    // 文件模块
    [self registerPathWithName:APIPathNameUpload path:APIPathValueUpload description:@"文件上传"];
    [self registerPathWithName:APIPathNameDownload path:APIPathValueDownload description:@"文件下载"];
}

/// 获取路径（智能解析）
/// 1. 如果 pathName 已注册，返回注册的路径
/// 2. 如果 pathName 以 / 开头，直接作为路径使用
/// 3. 否则，按照约定转换为路径（如 @"user" -> @"/api/v1/user"）
- (NSString *)pathForPathName:(NSString *)pathName {
    if (!pathName || pathName.length == 0) {
        NSLog(@"⚠️ 路径名称为空");
        return @"";
    }
    
    // 1. 优先查找已注册的路径
    APIPathConfig *config = self.pathConfigs[pathName];
    if (config && config.path.length > 0) {
        return config.path;
    }
    
    // 2. 如果 pathName 以 / 开头，直接作为路径使用
    if ([pathName hasPrefix:@"/"]) {
        return pathName;
    }
    
    // 3. 按照约定转换为路径：pathName -> {defaultPathPrefix}/pathName
    // 例如：如果 defaultPathPrefix 为 @"/api/v1"，则 @"user" -> @"/api/v1/user"
    // 如果 defaultPathPrefix 为 @"/api/v2"，则 @"user" -> @"/api/v2/user"
    NSString *prefix = self.defaultPathPrefix ?: @"/api/v1";
    // 确保前缀以 / 开头，不以 / 结尾
    if (![prefix hasPrefix:@"/"]) {
        prefix = [NSString stringWithFormat:@"/%@", prefix];
    }
    if ([prefix hasSuffix:@"/"]) {
        prefix = [prefix substringToIndex:prefix.length - 1];
    }
    NSString *convertedPath = [NSString stringWithFormat:@"%@/%@", prefix, pathName];
    NSLog(@"ℹ️ 路径名称 %@ 未注册，使用约定路径: %@ (前缀: %@)", pathName, convertedPath, prefix);
    return convertedPath;
}

- (NSDictionary<NSString *, APIPathConfig *> *)allPathConfigs {
    return [self.pathConfigs copy];
}

- (void)registerPathConfig:(APIPathConfig *)pathConfig {
    if (!pathConfig || !pathConfig.name || pathConfig.name.length == 0) {
        NSLog(@"⚠️ 路径配置无效，忽略注册");
        return;
    }
    
    self.pathConfigs[pathConfig.name] = pathConfig;
    NSLog(@"✅ 已注册路径: %@ -> %@", pathConfig.name, pathConfig.path);
}

- (void)registerPathWithName:(NSString *)name path:(NSString *)path {
    APIPathConfig *config = [APIPathConfig configWithName:name path:path];
    [self registerPathConfig:config];
}

- (void)registerPathWithName:(NSString *)name path:(NSString *)path description:(nullable NSString *)description {
    APIPathConfig *config = [APIPathConfig configWithName:name path:path description:description];
    [self registerPathConfig:config];
}

- (void)removePathConfigWithName:(NSString *)pathName {
    if (!pathName || pathName.length == 0) {
        return;
    }
    
    [self.pathConfigs removeObjectForKey:pathName];
    NSLog(@"✅ 已移除路径: %@", pathName);
}

- (void)clearAllPathConfigs {
    [self.pathConfigs removeAllObjects];
    NSLog(@"✅ 已清空所有路径配置");
}

@end
