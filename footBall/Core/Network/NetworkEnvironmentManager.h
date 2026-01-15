//
//  NetworkEnvironmentManager.h
//  footBall
//
//  Created on 2026/1/15.
//

#import <Foundation/Foundation.h>
#import "APIServerConfig.h"

NS_ASSUME_NONNULL_BEGIN

/// 统一网络环境管理器 - 同时管理HTTP和WebSocket环境
/// 解决HTTP和WebSocket环境切换不同步的问题
@interface NetworkEnvironmentManager : NSObject

/// 单例
+ (instancetype)sharedManager;

/// 当前环境（默认：Test）
@property (nonatomic, assign) APIEnvironment currentEnvironment;

/// 切换环境（同时切换HTTP和WebSocket环境）
/// @param environment 目标环境
- (void)switchToEnvironment:(APIEnvironment)environment;

/// 获取环境显示名称
/// @param environment 环境类型
+ (NSString *)displayNameForEnvironment:(APIEnvironment)environment;

@end

NS_ASSUME_NONNULL_END
