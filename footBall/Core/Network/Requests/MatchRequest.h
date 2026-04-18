//
//  MatchRequest.h
//  footBall
//
//  比赛、首页日程、Nami、观赛记录、比赛互动、打卡认证等网络请求。
//  路径常量见 APIPathValues.h。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MatchRequest : NSObject

+ (instancetype)shared;

#pragma mark - 首页 / 日程

/// GET `/api/v1/home/featured-matches` — 精选比赛卡片；成功时 `dataObject` 为 `Match` 数组
- (void)getFeaturesMatchsSuccess:(nullable APISuccessBlock)success
                         failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/home/schedule` — 比赛日程
/// @param date 可选，如 `yyyy-MM-dd`
/// @param myTeamOnly 是否仅关注球队
/// @param page / pageSize 分页，内部会转为 `pageNum` / `pageSize`
- (void)getMatchScheduleWithDate:(nullable NSString *)date
                       myTeamOnly:(BOOL)myTeamOnly
                             page:(NSInteger)page
                         pageSize:(NSInteger)pageSize
                          success:(nullable APISuccessBlock)success
                          failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/home/schedule/dates` — 有比赛的日期列表
/// @param month 可选，如 `yyyy-MM`，传 `nil` 时由后端默认规则处理
- (void)getMatchScheduleDatesWithMonth:(nullable NSString *)month
                               success:(nullable APISuccessBlock)success
                               failure:(nullable APIFailureBlock)failure;

#pragma mark - 比赛检索 / 详情 / 收藏

/// GET `/api/v1/matches/search` — 搜索比赛
/// @param keyword 关键词，可传空串占位
/// @param leagueId 可选联赛筛选
- (void)searchMatchesWithKeyword:(nullable NSString *)keyword
                        leagueId:(nullable NSString *)leagueId
                            page:(NSInteger)page
                        pageSize:(NSInteger)pageSize
                         success:(nullable APISuccessBlock)success
                         failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/matches/calendar` — 日历上有比赛的标记
/// @param year 年；@param month 1～12
- (void)getMatchCalendarWithYear:(NSInteger)year
                             month:(NSInteger)month
                           success:(nullable APISuccessBlock)success
                           failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/matches/{matchId}` — 比赛详情；`dataObject` 为 `MatchDetail`
- (void)getMatchDetail:(NSString *)matchId
               success:(nullable APISuccessBlock)success
               failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/matches/my-team` — 关注球队比赛（历史聚合列表，兼容旧版；Discover 等请用 upcoming / finished）
- (void)getMyTeamMatchesWithPage:(NSInteger)page
                        pageSize:(NSInteger)pageSize
                         success:(nullable APISuccessBlock)success
                         failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/matches/my-team/upcoming` — 未来观赛；`dataObject` 为 `Match` 数组（服务端已排序）
- (void)getMyTeamUpcomingMatchesWithPage:(NSInteger)page
                                pageSize:(NSInteger)pageSize
                                 success:(nullable APISuccessBlock)success
                                 failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/matches/my-team/finished` — 已经观赛；`dataObject` 为 `Match` 数组（服务端已排序）
- (void)getMyTeamFinishedMatchesWithPage:(NSInteger)page
                                pageSize:(NSInteger)pageSize
                                 success:(nullable APISuccessBlock)success
                                 failure:(nullable APIFailureBlock)failure;

/// POST `/api/v1/matches/{matchId}/favorite` — 收藏比赛
- (void)favoriteMatch:(NSString *)matchId
              success:(nullable APISuccessBlock)success
              failure:(nullable APIFailureBlock)failure;

/// DELETE `/api/v1/matches/{matchId}/favorite` — 取消收藏
- (void)unfavoriteMatch:(NSString *)matchId
                success:(nullable APISuccessBlock)success
                failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/matches/favorites` — 收藏列表分页
- (void)getFavoriteMatchesWithPage:(NSInteger)page
                          pageSize:(NSInteger)pageSize
                           success:(nullable APISuccessBlock)success
                           failure:(nullable APIFailureBlock)failure;

#pragma mark - Nami 实时数据

/// GET `/api/v1/matches/nami/schedule` — 按日期的 Nami 赛程
- (void)getNamiScheduleWithDate:(nullable NSString *)date
                           page:(NSInteger)page
                       pageSize:(NSInteger)pageSize
                        success:(nullable APISuccessBlock)success
                        failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/matches/nami/live` — 进行中的 Nami 比赛
- (void)getNamiLiveMatchesSuccess:(nullable APISuccessBlock)success
                          failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/matches/nami/{matchId}/detail` — Nami 比赛详情（含实时比分等）
- (void)getNamiMatchDetail:(NSString *)matchId
                   success:(nullable APISuccessBlock)success
                   failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/matches/nami/{matchId}/live` — Nami 实时数据（比分、统计、事件等）
- (void)getNamiMatchLiveData:(NSString *)matchId
                     success:(nullable APISuccessBlock)success
                     failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/matches/nami/{matchId}/trend` — 趋势
- (void)getNamiMatchTrend:(NSString *)matchId
                  success:(nullable APISuccessBlock)success
                  failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/matches/nami/{matchId}/lineup` — 阵容
- (void)getNamiMatchLineup:(NSString *)matchId
                   success:(nullable APISuccessBlock)success
                   failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/matches/nami/{matchId}/player-stats` — 球员统计
- (void)getNamiMatchPlayerStats:(NSString *)matchId
                        success:(nullable APISuccessBlock)success
                        failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/matches/nami/{matchId}/stream` — 直播地址（后端可能尚未提供，仍按约定路径请求）
- (void)getNamiMatchStreamWithMatchId:(NSString *)matchId
                              success:(nullable APISuccessBlock)success
                              failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/matches/nami/{matchId}/videos` — 集锦录像（后端可能尚未提供）
- (void)getNamiMatchVideosWithMatchId:(NSString *)matchId
                              success:(nullable APISuccessBlock)success
                              failure:(nullable APIFailureBlock)failure;

#pragma mark - 观赛记录（match-records）

/// POST `/api/v1/match-records` — 创建观赛记录，body 字段与后端 DTO 对齐
- (void)createMatchRecordWithBody:(NSDictionary *)body
                          success:(nullable APISuccessBlock)success
                          failure:(nullable APIFailureBlock)failure;

/// PUT `/api/v1/match-records/{recordId}` — 更新观赛记录
- (void)updateMatchRecord:(NSString *)recordId
                     body:(NSDictionary *)body
                  success:(nullable APISuccessBlock)success
                  failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/match-records/{recordId}` — 观赛记录详情
- (void)getMatchRecordDetail:(NSString *)recordId
                     success:(nullable APISuccessBlock)success
                     failure:(nullable APIFailureBlock)failure;

#pragma mark - 比赛互动（match-interactions）

/// POST `/api/v1/match-interactions/{matchId}/like` — 点赞比赛
- (void)likeMatch:(NSString *)matchId
          success:(nullable APISuccessBlock)success
          failure:(nullable APIFailureBlock)failure;

/// DELETE `/api/v1/match-interactions/{matchId}/like` — 取消点赞
- (void)unlikeMatch:(NSString *)matchId
            success:(nullable APISuccessBlock)success
            failure:(nullable APIFailureBlock)failure;

/// POST `/api/v1/match-interactions/{matchId}/view` — 记录浏览量
- (void)recordMatchView:(NSString *)matchId
                success:(nullable APISuccessBlock)success
                failure:(nullable APIFailureBlock)failure;

#pragma mark - 比赛认证（打卡）

/// POST `/api/v1/match-records/{recordId}/verify` — 提交现场认证/打卡；
/// photoUrls 照片URL列表（最少2张，最多9张）
/// latitude GPS纬度
/// longitude GPS经度
- (void)verifyMatchRecord:(NSString *)recordId
                     body:(nullable NSDictionary *)body
                  success:(nullable APISuccessBlock)success
                  failure:(nullable APIFailureBlock)failure;

@end

NS_ASSUME_NONNULL_END
