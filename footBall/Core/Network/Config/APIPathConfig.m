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
        
        // 加载默认路径配置
        [self loadDefaultPathConfigs];
    }
    return self;
}

- (void)loadDefaultPathConfigs {
    // 注册默认API路径
    // 使用路径名称常量和路径值常量，实现配置分离
    
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
    
    // 其他模块可以根据需要添加
    // 在 APIPathNames.h/m 中添加路径名称常量
    // 在 APIPathValues.h/m 中添加路径值常量
    // 然后在这里注册： [self registerPathWithName:APIPathNameOrder path:APIPathValueOrder description:@"订单相关接口"];
}

- (NSString *)pathForPathName:(NSString *)pathName {
    if (!pathName || pathName.length == 0) {
        NSLog(@"⚠️ 路径名称为空");
        return @"";
    }
    
    APIPathConfig *config = self.pathConfigs[pathName];
    if (!config) {
        NSLog(@"⚠️ 未找到路径名称: %@", pathName);
        return @"";
    }
    
    return config.path ?: @"";
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
