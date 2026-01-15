//
//  APIPathNames.h
//  footBall
//
//  Created on 2026/1/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// API路径名称常量类 - 统一管理所有API路径名称
@interface APIPathNames : NSObject

#pragma mark - 用户模块
/// 用户相关接口
FOUNDATION_EXPORT NSString * const APIPathNameUser;
/// 用户资料
FOUNDATION_EXPORT NSString * const APIPathNameUserProfile;
/// 用户列表
FOUNDATION_EXPORT NSString * const APIPathNameUserList;

#pragma mark - 认证模块
/// 认证相关接口
FOUNDATION_EXPORT NSString * const APIPathNameAuth;
/// 登录
FOUNDATION_EXPORT NSString * const APIPathNameAuthLogin;
/// 登出
FOUNDATION_EXPORT NSString * const APIPathNameAuthLogout;
/// 刷新Token
FOUNDATION_EXPORT NSString * const APIPathNameAuthRefresh;

#pragma mark - 文件模块
/// 文件上传
FOUNDATION_EXPORT NSString * const APIPathNameUpload;
/// 文件下载
FOUNDATION_EXPORT NSString * const APIPathNameDownload;

@end

NS_ASSUME_NONNULL_END
