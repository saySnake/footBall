//
//  ProfileRequest.h
//  footBall
//
//  护照、个人数据统计、排行榜（/api/v1/passport/*、statistics、leaderboard）。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProfileRequest : NSObject

+ (instancetype)shared;

/// GET `/api/v1/passport/me` — 我的护照；query `year` 可选；`dataObject` 为 `PNPassport`
- (void)getMyPassportWithYear:(nullable NSString *)year
                      success:(nullable APISuccessBlock)success
                      failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/passport/{userId}` — 他人护照；query `year` 可选；`dataObject` 为 `PNPassport` 或原始 data
- (void)getPassportForUserId:(NSString *)userId
                        year:(nullable NSString *)year
                     success:(nullable APISuccessBlock)success
                     failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/passport/me/records` — 我的观赛记录列表分页
/// @param year   年份，nil 时后端默认当前年份
/// @param tab    标签筛选：`future`（未来）/ `past`（过去），nil 不筛选
/// @param status 状态筛选：`ALL` / `UNVERIFIED` / `PENDING` / `VERIFIED` / `FUTURE`，nil 不筛选
/// `dataObject` 为原始 `data`（便于后续接 VO）
- (void)getMyPassportMatchRecordsWithYear:(nullable NSString *)year
                                      tab:(nullable NSString *)tab
                                   status:(nullable NSString *)status
                                     page:(NSInteger)page
                                 pageSize:(NSInteger)pageSize
                                  success:(nullable APISuccessBlock)success
                                  failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/statistics/me` — 我的数据统计；`period` 如 all/week；`dataObject` 为 `PNStatistics`
- (void)getMyStatisticsWithPeriod:(nullable NSString *)period
                          success:(nullable APISuccessBlock)success
                          failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/leaderboard` — 排行榜分页；`period` 如 week
- (void)getLeaderboardWithPeriod:(nullable NSString *)period
                            page:(NSInteger)page
                        pageSize:(NSInteger)pageSize
                         success:(nullable APISuccessBlock)success
                         failure:(nullable APIFailureBlock)failure;

@end

NS_ASSUME_NONNULL_END
