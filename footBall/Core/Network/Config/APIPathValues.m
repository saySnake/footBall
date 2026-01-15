//
//  APIPathValues.m
//  footBall
//
//  Created on 2026/1/15.
//

#import "APIPathValues.h"

#pragma mark - 用户模块
NSString * const APIPathValueUser = @"/api/v1/user";
NSString * const APIPathValueUserProfile = @"/api/v1/user/profile";
NSString * const APIPathValueUserList = @"/api/v1/user/list";

#pragma mark - 认证模块
NSString * const APIPathValueAuth = @"/api/v1/auth";
NSString * const APIPathValueAuthLogin = @"/api/v1/auth/login";
NSString * const APIPathValueAuthLogout = @"/api/v1/auth/logout";
NSString * const APIPathValueAuthRefresh = @"/api/v1/auth/refresh";

#pragma mark - 文件模块
NSString * const APIPathValueUpload = @"/api/v1/upload";
NSString * const APIPathValueDownload = @"/api/v1/download";
