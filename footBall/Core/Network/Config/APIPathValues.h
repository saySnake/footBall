//
//  APIPathValues.h
//  footBall
//
//  Created on 2026/1/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// API路径值常量类 - 统一管理所有API路径值

#pragma mark - 用户模块
/// GET获取当前登录用户信息 , PUT更新当前用户个人资料
FOUNDATION_EXPORT NSString * const APIPathValueUser;
/// 获取当前用户二维码
FOUNDATION_EXPORT NSString * const APIPathValueUserQRCode;
/// 根据用户ID查看他人公开信息
FOUNDATION_EXPORT NSString * const APIPathValueGetUser(NSString *userId);
/// 搜索用户
FOUNDATION_EXPORT NSString * const APIPathValueSearchUser;

#pragma mark - 认证模块
/// 发送验证码
FOUNDATION_EXPORT NSString * const APIPathValueSendCode;
/// 手机登录
FOUNDATION_EXPORT NSString * const APIPathValueAuthLoginPhone;
/// 登出路径
FOUNDATION_EXPORT NSString * const APIPathValueAuthLogout;
/// 刷新Token路径
FOUNDATION_EXPORT NSString * const APIPathValueAuthRefresh;

#pragma mark - 文件模块
/// 获取OSS临时上传凭证(STS Token)
FOUNDATION_EXPORT NSString * const APIPathValueOSSToken;

#pragma mark - 新用户引导
/// 批量关注球队
FOUNDATION_EXPORT NSString * const APIPathValueOnboardingBatchFollow;
/// 完成新用户引导
FOUNDATION_EXPORT NSString * const APIPathValueOnboardingComplete;

#pragma mark - 球队模块
/// 搜索球队
FOUNDATION_EXPORT NSString * const APIPathValueTeamsSearch;
/// 获取球队详情
FOUNDATION_EXPORT NSString * const APIPathValueTeams(NSString *teamId);
/// POST关注球队 ，DELETE取消关注球队
FOUNDATION_EXPORT NSString * const APIPathValueTeamsFollow(NSString *teamId);
/// 批量关注球队
FOUNDATION_EXPORT NSString * const APIPathValueTeamsBatchFollow;
/// 获取我关注的球队列表
FOUNDATION_EXPORT NSString * const APIPathValueTeamsMyFollow;

NS_ASSUME_NONNULL_END
