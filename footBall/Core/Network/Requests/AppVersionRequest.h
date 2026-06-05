//
//  AppVersionRequest.h
//  footBall
//

#import <Foundation/Foundation.h>
#import "APIManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface AppVersionRequest : NSObject

+ (instancetype)shared;

/// GET `/api/v1/app/version-check` — 检查是否须强制更新（无需登录）
- (void)checkVersionSuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure;

@end

NS_ASSUME_NONNULL_END
