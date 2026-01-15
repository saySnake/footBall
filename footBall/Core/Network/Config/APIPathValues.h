//
//  APIPathValues.h
//  footBall
//
//  Created on 2026/1/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// API路径值常量类 - 统一管理所有API路径值
@interface APIPathValues : NSObject

#pragma mark - 用户模块
/// 用户相关接口路径
FOUNDATION_EXPORT NSString * const APIPathValueUser;
/// 用户资料路径
FOUNDATION_EXPORT NSString * const APIPathValueUserProfile;
/// 用户列表路径
FOUNDATION_EXPORT NSString * const APIPathValueUserList;

#pragma mark - 认证模块
/// 认证相关接口路径
FOUNDATION_EXPORT NSString * const APIPathValueAuth;
/// 登录路径
FOUNDATION_EXPORT NSString * const APIPathValueAuthLogin;
/// 登出路径
FOUNDATION_EXPORT NSString * const APIPathValueAuthLogout;
/// 刷新Token路径
FOUNDATION_EXPORT NSString * const APIPathValueAuthRefresh;

#pragma mark - 文件模块
/// 文件上传路径
FOUNDATION_EXPORT NSString * const APIPathValueUpload;
/// 文件下载路径
FOUNDATION_EXPORT NSString * const APIPathValueDownload;

@end

NS_ASSUME_NONNULL_END
