//
//  APIPathValues.m
//  footBall
//
//  Created on 2026/1/15.
//

#import "APIPathValues.h"

#pragma mark - 用户模块
NSString * const APIPathValueUser = @"/api/v1/users/me";
NSString * const APIPathValueUserQRCode = @"/api/v1/users/me/qrcode";
NSString * const APIPathValueGetUser(NSString *userId) {
    return [NSString stringWithFormat:@"/api/v1/users/%@",userId];
};
NSString * const APIPathValueSearchUser = @"/api/v1/users/search";
#pragma mark - 认证模块
NSString * const APIPathValueSendCode = @"/api/v1/auth/send-code";
NSString * const APIPathValueAuthLoginPhone = @"/api/v1/auth/login/phone";
NSString * const APIPathValueAuthLogout = @"/api/v1/auth/logout";
NSString * const APIPathValueAuthRefresh = @"/api/v1/auth/refresh";

#pragma mark - 文件模块
NSString * const APIPathValueOSSToken = @"/api/v1/oss/sts-token";

#pragma mark - 新用户引导
/// 批量关注球队
NSString * const APIPathValueOnboardingBatchFollow = @"/api/v1/onboarding/teams/batch-follow";
/// 完成新用户引导
NSString * const APIPathValueOnboardingComplete = @"/api/v1/onboarding/complete";

#pragma mark - 球队模块
/// 搜索球队
NSString * const APIPathValueTeamsSearch = @"/api/v1/teams/search";
/// 获取球队详情
NSString * const APIPathValueTeams(NSString *teamId) {
    return [NSString stringWithFormat:@"/api/v1/teams/%@",teamId];
};
/// POST关注球队 ，DELETE取消关注球队
NSString * const APIPathValueTeamsFollow(NSString *teamId) {
    return [NSString stringWithFormat:@"/api/v1/teams/%@/follow",teamId];
}
/// 批量关注球队
NSString * const APIPathValueTeamsBatchFollow = @"/api/v1/teams/batch-follow";
/// 获取我关注的球队列表
NSString * const APIPathValueTeamsMyFollow = @"/api/v1/teams/my-follows";
