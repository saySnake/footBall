//
//  UserRequest.h
//  footBall
//
//  Created by LWJ on 2026/3/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UserRequest : NSObject
+(instancetype)shared;
/// 完成新用户引导
- (void)completeNewUserOnboardingSuccess:(nullable APISuccessBlock)success
                                 failure:(nullable APIFailureBlock)failure;
/// 获取当前登录用户信息
- (void)getLoginUserInfoSuccess:(nullable APISuccessBlock)success
                   failure:(nullable APIFailureBlock)failure;
/// 更新当前用户个人资料
- (void)updateUserInfo:(UserProfile *)user success:(nullable APISuccessBlock)success
                   failure:(nullable APIFailureBlock)failure;
/// 获取当前用户二维码
- (void)getUserQRCodeSuccess:(nullable APISuccessBlock)success
                     failure:(nullable APIFailureBlock)failure;
/// 根据用户ID查看他人公开信息
- (void)getUserInfo:(NSString *)userId
            success:(nullable APISuccessBlock)success
            failure:(nullable APIFailureBlock)failure;

/// 搜索用户
- (void)searchUser:(NSString *)userId
            success:(nullable APISuccessBlock)success
            failure:(nullable APIFailureBlock)failure;

@end

NS_ASSUME_NONNULL_END
