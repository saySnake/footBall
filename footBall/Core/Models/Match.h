//
//  Match.h
//  footBall
//
//  Created by LWJ on 2026/3/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Match : NSObject <YYModel>
/// 比赛 ID
@property (nonatomic, copy) NSString *matchId;
/// 主队 Logo URL
@property (nonatomic, copy) NSString *homeTeamLogo;
/// 客队 Logo URL
@property (nonatomic, copy) NSString *awayTeamLogo;
/// 主队名称
@property (nonatomic, copy) NSString *homeTeamName;
/// 客队名称
@property (nonatomic, copy) NSString *awayTeamName;
/// 客队 ID
@property (nonatomic, copy) NSString *awayTeamId;
/// 比赛状态（SCHEDULED / FINISHED / CANCELLED 等）
@property (nonatomic, copy) NSString *matchStatus;
/// 点赞数
@property (nonatomic, copy) NSString *likeCount;
/// 比赛时间（ISO 8601）
@property (nonatomic, copy) NSString *matchDate;
/// 观看数
@property (nonatomic, copy) NSString *viewCount;
/// 主队 ID
@property (nonatomic, copy) NSString *homeTeamId;
/// 主队比分
@property (nonatomic, assign) NSInteger homeScore;
/// 客队比分
@property (nonatomic, assign) NSInteger awayScore;
/// 是否已提交观赛信息（字段名按后端可多种）
@property (nonatomic, assign) BOOL infoCompleted;
/// 是否已完成球票/比赛认证
@property (nonatomic, assign) BOOL verifyCompleted;
/// 认证审核状态（PENDING/APPROVED/REJECTED 等）
@property (nonatomic, copy) NSString *verificationStatus;
/// 已认证时长（分钟），用于「已认证 xx 分钟」
@property (nonatomic, assign) NSInteger certifiedMinutes;
/// 首页日程 MatchScheduleVO：是否已收藏
@property (nonatomic, assign) BOOL favorited;
/// 首页日程 MatchScheduleVO：是否已点赞
@property (nonatomic, assign) BOOL liked;
/// 观赛记录主键；`MatchVO` / `MatchScheduleVO` 在有记录时由后端下发
@property (nonatomic, copy) NSString *recordId;
/// 展示层缓存：matchDate 解析出的开球时间（供列表滚动复用，非后端字段）
@property (nonatomic, strong, nullable) NSDate *parsedKickoffDate;
/// 展示层缓存：parsedKickoffDate 是否已尝试解析（区分「未解析」与「解析失败」）
@property (nonatomic, assign) BOOL kickoffDateParsed;
@end

@interface MatchDetail : Match
/// 半场主队比分
@property (nonatomic, assign) NSInteger halfHomeScore;
/// 半场客队比分
@property (nonatomic, assign) NSInteger halfAwayScore;
@property (nonatomic, copy) NSString *stadiumId;
@property (nonatomic, copy) NSString *stadiumName;
@property (nonatomic, copy) NSString *leagueId;
@property (nonatomic, copy) NSString *leagueName;
/// 比赛时长（分钟）
@property (nonatomic, assign) NSInteger duration;
@property (nonatomic, assign) NSInteger yellowCards;
@property (nonatomic, assign) NSInteger redCards;
@property (nonatomic, assign) NSInteger attendance;
/// 主队赛果文案（胜/平/负等）
@property (nonatomic, copy) NSString *homeResult;
@property (nonatomic, copy) NSString *awayResult;
@end

/// PageResult<MatchVO> — 比赛搜索 / 我的球队比赛 / 收藏列表等分页
@interface PNMatchPage : NSObject <YYModel>
@property (nonatomic, strong) NSArray<Match *> *list;
@property (nonatomic, assign) NSInteger total;
@property (nonatomic, assign) NSInteger pageNum;
@property (nonatomic, assign) NSInteger pageSize;
@end

NS_ASSUME_NONNULL_END
