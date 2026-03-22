//
//  TeamsRequest.h
//  footBall
//
//  Created by LWJ on 2026/3/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TeamsRequest : NSObject
+(instancetype)shared;
/// 搜索球队
- (void)searchTeams:(nullable NSString * )searckKey
           leagueId:(nullable NSString *)leagueId
               page:(NSInteger)page
           pageSize:(NSInteger)pageSize
            success:(nullable APISuccessBlock)success
            failure:(nullable APIFailureBlock)failure;
/// 获取球队详情
- (void)getTeamsDetail:(NSString *)teamsId
               success:(nullable APISuccessBlock)success
               failure:(nullable APIFailureBlock)failure;
/// 新手引导批量关注球队
- (void)onboardingFollows:(NSArray <NSString *> *)teamIds
                  success:(nullable APISuccessBlock)success
                  failure:(nullable APIFailureBlock)failure;
/// 批量关注球队
- (void)followTeams:(NSArray <NSString *> *)teamIds
            success:(nullable APISuccessBlock)success
            failure:(nullable APIFailureBlock)failure;

/// 关注单个球队
- (void)followTeam:(NSString *)teamId
           success:(nullable APISuccessBlock)success
           failure:(nullable APIFailureBlock)failure;
/// 取消关注球队
- (void)cancelFollowTeam:(NSString *)teamId
                 success:(nullable APISuccessBlock)success
                 failure:(nullable APIFailureBlock)failure;
/// 获取我关注的球队列表
- (void)getFollowTeamsSuccess:(nullable APISuccessBlock)success
                      failure:(nullable APIFailureBlock)failure;

/// 获取当前用户关注球队的队徽列表
- (void)getFollowTeamIconsSuccess:(nullable APISuccessBlock)success
                      failure:(nullable APIFailureBlock)failure;

@end

NS_ASSUME_NONNULL_END
