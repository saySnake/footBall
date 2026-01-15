//
//  BVAPPEnvironmentHostManager.h
//  Bhex
//
//  Created by DZSB-001968 on 6.12.23.
//  Copyright © 2023 Bhex. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BVAPPEnvironmentHostItemModel : NSObject
/*
 生产 1
 uat 2
 测试 3
 */
@property (nonatomic, copy, readonly) NSString *displayName;

@property (nonatomic, assign, readonly) NSInteger productFlag;

@property (nonatomic, copy, nonnull, readonly) NSString *domain;

@property (nonatomic, copy, nonnull, readonly) NSString *domainUrl;

@property (nonatomic, copy, nonnull, readonly) NSString *apiPrefix;

/// WebSocket 域名（可选，如果为空则使用 domain）
@property (nonatomic, copy, nullable, readonly) NSString *wsDomain;

/// WebSocket URL（完整地址，如：wss://ws.example.com）
/// 如果为空，则根据 domain 自动生成（http -> ws, https -> wss）
@property (nonatomic, copy, nullable, readonly) NSString *wsUrl;

@property (nonatomic, assign) BOOL isSelected;

/// 初始化方法（不包含 WebSocket）
- (instancetype)initWithProduct:(NSInteger)productFlag domain:(NSString *)domain domainUrl:(NSString *)domainUrl apiPrefix:(NSString *)apiPrefix displayName:(NSString *)name;

/// 初始化方法（包含 WebSocket）
- (instancetype)initWithProduct:(NSInteger)productFlag 
                          domain:(NSString *)domain 
                       domainUrl:(NSString *)domainUrl 
                       apiPrefix:(NSString *)apiPrefix 
                     displayName:(NSString *)name
                        wsDomain:(nullable NSString *)wsDomain
                           wsUrl:(nullable NSString *)wsUrl;

@end


@interface BVAPPEnvironmentHostManager : NSObject

@property (nonatomic, strong, readonly) BVAPPEnvironmentHostItemModel *currentSelected;

@property (nonatomic, copy, readonly) NSArray<BVAPPEnvironmentHostItemModel *> *datasource;

/*
 YES or NO
 */
@property (nonatomic, assign, readonly) BOOL productFlag;

+ (instancetype)shareInstance;

// 切换环境
- (void)switchEnvironmentHost:(NSInteger)index;

#pragma mark - WebSocket 管理

/// 获取当前环境的 WebSocket URL
/// @return WebSocket URL（如：wss://ws.example.com），如果未配置则返回 nil
- (nullable NSString *)currentWebSocketURL;

/// 获取当前环境的 WebSocket Base URL（不包含路径）
/// @return WebSocket Base URL，如果未配置则根据 domain 自动生成
- (NSString *)currentWebSocketBaseURL;

/// 获取指定索引环境的 WebSocket URL
/// @param index 环境索引
/// @return WebSocket URL，如果未配置则返回 nil
- (nullable NSString *)webSocketURLForIndex:(NSInteger)index;

/// 获取指定索引环境的 WebSocket Base URL
/// @param index 环境索引
/// @return WebSocket Base URL
- (NSString *)webSocketBaseURLForIndex:(NSInteger)index;

/// 根据 HTTP URL 自动生成 WebSocket URL
/// @param httpURL HTTP URL（如：https://api.example.com）
/// @return WebSocket URL（如：wss://api.example.com）
+ (NSString *)webSocketURLFromHTTPURL:(NSString *)httpURL;

@end

NS_ASSUME_NONNULL_END
