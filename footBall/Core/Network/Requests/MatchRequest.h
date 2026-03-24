//
//  MatchRequest.h
//  footBall
//
//  Created by LWJ on 2026/3/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MatchRequest : NSObject
+(instancetype)shared;
/// 获取精选比赛卡片
- (void)getFeaturesMatchsSuccess:(nullable APISuccessBlock)success
                         failure:(nullable APIFailureBlock)failure;
/// 获取比赛日程列表
- (void)getMatchScheduleWithDate:(nullable NSString *)date
                       myTeamOnly:(BOOL)myTeamOnly
                             page:(NSInteger)page
                         pageSize:(NSInteger)pageSize
                          success:(nullable APISuccessBlock)success
                          failure:(nullable APIFailureBlock)failure;

/// 获取指定月份有比赛的日期列表
/// 按日期查询 Nami 比赛列表
/// 查询正在进行的 Nami 比赛
/// 获取 Nami 比赛详情（比赛 + 实时比分 + 统计 + 事件）
/// 获取 Nami 比赛实时数据（实时比分 + 统计 + 事件 + 文字直播）
/// 获取 Nami 比赛趋势数据
/// 获取 Nami 比赛阵容
/// 获取 Nami 比赛球员统计
/// 获取 Nami 比赛直播地址
/// 获取 Nami 比赛集锦录像
/// 搜索比赛
/// 获取比赛详情
- (void)getMatchDetail:(NSString *)matchId
               success:(nullable APISuccessBlock)success
               failure:(nullable APIFailureBlock)failure;
/// 获取指定月份有比赛的日期列表
/// 获取关注球队的比赛列表
- (void)getMyTeamMatchesWithPage:(NSInteger)page
                        pageSize:(NSInteger)pageSize
                         success:(nullable APISuccessBlock)success
                         failure:(nullable APIFailureBlock)failure;
/// 收藏比赛
/// 取消收藏比赛
/// 获取收藏的比赛列表
- (void)getFavoriteMatchesWithPage:(NSInteger)page
                          pageSize:(NSInteger)pageSize
                           success:(nullable APISuccessBlock)success
                           failure:(nullable APIFailureBlock)failure;
/// 创建观赛记录
/// 更新观赛记录
/// 获取观赛记录详情
/// 点赞比赛
/// 取消点赞比赛
/// 记录比赛浏览量
@end

NS_ASSUME_NONNULL_END
