//
//  BVAPPEnvironmentHostManager.m
//  Bhex
//
//  Created by DZSB-001968 on 6.12.23.
//  Copyright © 2023 Bhex. All rights reserved.
//

#import "BVAPPEnvironmentHostManager.h"
#ifdef DEBUG
#if __has_include(<MLeaksFinder/MLeaksFinder.h>)
@import MLeaksFinder;
#endif
#endif
#import <objc/runtime.h>

@interface BVAPPEnvironmentHostItemModel()

@property (nonatomic, copy, readwrite) NSString *displayName;

@property (nonatomic, assign, readwrite) NSInteger productFlag;

@property (nonatomic, copy, nonnull, readwrite) NSString *domain;

@property (nonatomic, copy, nonnull, readwrite) NSString *domainUrl;

@property (nonatomic, copy, nonnull, readwrite) NSString *apiPrefix;

@property (nonatomic, copy, nullable, readwrite) NSString *wsDomain;

@property (nonatomic, copy, nullable, readwrite) NSString *wsUrl;
@end

@implementation BVAPPEnvironmentHostItemModel

- (instancetype)initWithProduct:(NSInteger)productFlag domain:(NSString *)domain domainUrl:(NSString *)domainUrl apiPrefix:(NSString *)apiPrefix displayName:(NSString *)name {
    return [self initWithProduct:productFlag 
                          domain:domain 
                       domainUrl:domainUrl 
                       apiPrefix:apiPrefix 
                     displayName:name
                        wsDomain:nil
                           wsUrl:nil];
}

- (instancetype)initWithProduct:(NSInteger)productFlag domain:(NSString *)domain domainUrl:(NSString *)domainUrl apiPrefix:(NSString *)apiPrefix displayName:(NSString *)name wsDomain:(nullable NSString *)wsDomain wsUrl:(nullable NSString *)wsUrl {
    if ([super init]) {
        self.productFlag = productFlag;
        self.domain = domain;
        self.domainUrl = domainUrl;
        self.apiPrefix = apiPrefix;
        self.displayName = name;
        self.wsDomain = wsDomain;
        self.wsUrl = wsUrl;
        
        // 内存检测白名单代码
        //        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"isOpenMemoryLeak"]) {
        //            dispatch_async(dispatch_get_main_queue(), ^{
        //                #if __has_include(<MLeaksFinder/MLeaksFinder.h>)
        //                NSMutableArray *allClassName = @[].mutableCopy;
        //                unsigned int count;
        //                Class *classes = objc_copyClassList(&count);
        //                for (int i = 0; i < count; i++) {
        //                    Class class = classes[i];
        //                    const char *className = class_getName(class);
        //                    NSString *classNameString = [NSString stringWithUTF8String:className];
        //                    [allClassName addObject:classNameString];
        //                }
        //                free(classes);
        //                [NSObject addClassNamesToWhitelist:allClassName];
        //                #else
        //                #endif
        //            });
        //        }

    }
    return self;
}
@end


@interface BVAPPEnvironmentHostManager()

@end

@implementation BVAPPEnvironmentHostManager

+ (instancetype)shareInstance {
    static dispatch_once_t once;
    static BVAPPEnvironmentHostManager *instance;
    dispatch_once(&once, ^{
        instance = [[BVAPPEnvironmentHostManager alloc] init];
    });
    return instance;
}

//https://static.bvox.io/config/db_test2.json 不读取配置文件，直接写死
- (NSArray<BVAPPEnvironmentHostItemModel *> *)datasource {
    return @[
        // UAT 环境
        [[BVAPPEnvironmentHostItemModel alloc] initWithProduct:2 
                                                        domain:@"bitvenus.live" 
                                                     domainUrl:@"https://static.bvox.io/config/db_uat.json" 
                                                     apiPrefix:@"" 
                                                   displayName:@"UAT0"
                                                      wsDomain:@"ws-bitvenus.live"
                                                         wsUrl:@"wss://ws-bitvenus.live"],

        // 测试环境 1
        [[BVAPPEnvironmentHostItemModel alloc] initWithProduct:3 
                                                        domain:@"bxingupdate.com" 
                                                     domainUrl:@"" 
                                                     apiPrefix:@"-t1" 
                                                   displayName:@"test1"
                                                      wsDomain:@"ws-test1.bxingupdate.com"
                                                         wsUrl:@"wss://ws-test1.bxingupdate.com"],
        
        // 测试环境 2
        [[BVAPPEnvironmentHostItemModel alloc] initWithProduct:3 
                                                        domain:@"bxingupdate.com" 
                                                     domainUrl:@"" 
                                                     apiPrefix:@"-t2" 
                                                   displayName:@"test2"
                                                      wsDomain:@"ws-test2.bxingupdate.com"
                                                         wsUrl:@"wss://ws-test2.bxingupdate.com"],
        
        // 生产环境 - 企业签用户
        [[BVAPPEnvironmentHostItemModel alloc] initWithProduct:1 
                                                        domain:@"bitvenus.com" 
                                                     domainUrl:@"https://static.bvox.io/config/db_prod.json" 
                                                     apiPrefix:@"" 
                                                   displayName:@"企业签用户"
                                                      wsDomain:@"ws.bitvenus.com"
                                                         wsUrl:@"wss://ws.bitvenus.com"],
        
        // 生产环境 - TF签和appstore
        [[BVAPPEnvironmentHostItemModel alloc] initWithProduct:1 
                                                        domain:@"bitvenus.com" 
                                                     domainUrl:@"https://static.bvox.io/config/db_prod.json" 
                                                     apiPrefix:@"" 
                                                   displayName:@"TF签和appstore"
                                                      wsDomain:@"ws.bitvenus.com"
                                                         wsUrl:@"wss://ws.bitvenus.com"]
    ];
}



- (void)switchEnvironmentHost:(NSInteger)index {
    
    [[NSUserDefaults standardUserDefaults] setValue:[NSString stringWithFormat:@"%lu", index] forKey:@"BVAPPEnvironmentHostManager.currentSelected"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

- (BVAPPEnvironmentHostItemModel *)currentSelected {
    /*
     idnex = 0          uat
     index 1-2          test1 到 test2
     index 3            企业签
     index 4           App Store 和 TF 签名
     */
    id obj = [[NSUserDefaults standardUserDefaults] valueForKey:@"BVAPPEnvironmentHostManager.currentSelected"];
    NSInteger index;
    if (obj == nil) {
        index = 1;
    } else {
        index = [obj integerValue];
    }
    return self.datasource[index];
}

- (BOOL)productFlag {
    /*
     idnex = 0          uat
     index 1-2          test1 到 test2
     index 4            企业签
     index 5           App Store 和 TF 签名
     //
     */
    id obj = [[NSUserDefaults standardUserDefaults] valueForKey:@"BVAPPEnvironmentHostManager.currentSelected"];
    NSInteger index;
    if (obj == nil) {
        index = 1;
    } else {
        index = [obj integerValue];
    }
    
    //是生产包
    if (index == 3 || index == 4) {
        return YES;
    }
    //是测试包
    return NO;
}

#pragma mark - WebSocket 管理

- (nullable NSString *)currentWebSocketURL {
    BVAPPEnvironmentHostItemModel *selected = self.currentSelected;
    if (selected.wsUrl && selected.wsUrl.length > 0) {
        return selected.wsUrl;
    }
    
    // 如果没有配置 wsUrl，根据 domainUrl 自动生成
    if (selected.domainUrl && selected.domainUrl.length > 0) {
        return [[self class] webSocketURLFromHTTPURL:selected.domainUrl];
    }
    
    return nil;
}

- (NSString *)currentWebSocketBaseURL {
    NSString *wsURL = [self currentWebSocketURL];
    if (wsURL && wsURL.length > 0) {
        // 移除路径部分，只保留基础 URL
        NSURL *url = [NSURL URLWithString:wsURL];
        if (url) {
            NSString *scheme = url.scheme ?: @"wss";
            NSString *host = url.host;
            if (host) {
                NSInteger port = url.port ? [url.port integerValue] : 0;
                if (port > 0 && port != 443 && port != 80) {
                    return [NSString stringWithFormat:@"%@://%@:%ld", scheme, host, (long)port];
                } else {
                    return [NSString stringWithFormat:@"%@://%@", scheme, host];
                }
            }
        }
        return wsURL;
    }
    
    // 如果都没有，根据 domain 生成
    BVAPPEnvironmentHostItemModel *selected = self.currentSelected;
    if (selected.wsDomain && selected.wsDomain.length > 0) {
        return [NSString stringWithFormat:@"wss://%@", selected.wsDomain];
    }
    
    // 最后使用 domain 生成
    if (selected.domain && selected.domain.length > 0) {
        return [NSString stringWithFormat:@"wss://%@", selected.domain];
    }
    
    return @"";
}

- (nullable NSString *)webSocketURLForIndex:(NSInteger)index {
    if (index < 0 || index >= self.datasource.count) {
        return nil;
    }
    
    BVAPPEnvironmentHostItemModel *item = self.datasource[index];
    if (item.wsUrl && item.wsUrl.length > 0) {
        return item.wsUrl;
    }
    
    // 如果没有配置 wsUrl，根据 domainUrl 自动生成
    if (item.domainUrl && item.domainUrl.length > 0) {
        return [[self class] webSocketURLFromHTTPURL:item.domainUrl];
    }
    
    return nil;
}

- (NSString *)webSocketBaseURLForIndex:(NSInteger)index {
    NSString *wsURL = [self webSocketURLForIndex:index];
    if (wsURL && wsURL.length > 0) {
        // 移除路径部分，只保留基础 URL
        NSURL *url = [NSURL URLWithString:wsURL];
        if (url) {
            NSString *scheme = url.scheme ?: @"wss";
            NSString *host = url.host;
            if (host) {
                NSInteger port = url.port ? [url.port integerValue] : 0;
                if (port > 0 && port != 443 && port != 80) {
                    return [NSString stringWithFormat:@"%@://%@:%ld", scheme, host, (long)port];
                } else {
                    return [NSString stringWithFormat:@"%@://%@", scheme, host];
                }
            }
        }
        return wsURL;
    }
    
    // 如果都没有，根据 domain 生成
    if (index >= 0 && index < self.datasource.count) {
        BVAPPEnvironmentHostItemModel *item = self.datasource[index];
        if (item.wsDomain && item.wsDomain.length > 0) {
            return [NSString stringWithFormat:@"wss://%@", item.wsDomain];
        }
        
        if (item.domain && item.domain.length > 0) {
            return [NSString stringWithFormat:@"wss://%@", item.domain];
        }
    }
    
    return @"";
}

+ (NSString *)webSocketURLFromHTTPURL:(NSString *)httpURL {
    if (!httpURL || httpURL.length == 0) {
        return @"";
    }
    
    NSString *wsURL = httpURL;
    
    // 将 https:// 转换为 wss://
    if ([wsURL hasPrefix:@"https://"]) {
        wsURL = [wsURL stringByReplacingOccurrencesOfString:@"https://" withString:@"wss://"];
    }
    // 将 http:// 转换为 ws://
    else if ([wsURL hasPrefix:@"http://"]) {
        wsURL = [wsURL stringByReplacingOccurrencesOfString:@"http://" withString:@"ws://"];
    }
    // 如果没有协议前缀，默认使用 wss://
    else if (![wsURL hasPrefix:@"ws://"] && ![wsURL hasPrefix:@"wss://"]) {
        wsURL = [NSString stringWithFormat:@"wss://%@", wsURL];
    }
    
    return wsURL;
}

@end
