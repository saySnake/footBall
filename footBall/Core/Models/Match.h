//
//  Match.h
//  footBall
//
//  Created by LWJ on 2026/3/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Match : NSObject <YYModel>
// 比赛ID
@property (nonatomic, copy) NSString *matchId;
// 主队Logo
@property (nonatomic, copy) NSString *homeTeamLogo;
// 客队Logo
@property (nonatomic, copy) NSString *awayTeamLogo;
// 主队名称
@property (nonatomic, copy) NSString *homeTeamName;
// 客队名称
@property (nonatomic, copy) NSString *awayTeamName;
// 客队ID
@property (nonatomic, copy) NSString *awayTeamId;
// 比赛状态（SCHEDULED/FINISHED/CANCELLED 等）
@property (nonatomic, copy) NSString *matchStatus;
// 点赞数
@property (nonatomic, copy) NSString *likeCount;
// 比赛时间（ISO 8601格式）
@property (nonatomic, copy) NSString *matchDate;
// 观看数
@property (nonatomic, copy) NSString *viewCount;
// 主队ID
@property (nonatomic, copy) NSString *homeTeamId;
// 主队比分
@property (nonatomic, assign) NSInteger homeScore;
// 客队比分
@property (nonatomic, assign) NSInteger awayScore;
/// 是否已提交观赛信息（字段名按后端可多种）
@property (nonatomic, assign) BOOL infoCompleted;
/// 是否已完成球票/比赛认证
@property (nonatomic, assign) BOOL verifyCompleted;
/// 已认证时长（分钟），用于「已认证xx分钟」
@property (nonatomic, assign) NSInteger certifiedMinutes;

@end

@interface MatchDetail : Match
@property (nonatomic, assign) NSInteger halfHomeScore;
@property (nonatomic, assign) NSInteger halfAwayScore;
@property (nonatomic, copy) NSString *stadiumId;
@property (nonatomic, copy) NSString *stadiumName;
@property (nonatomic, copy) NSString *leagueId;
@property (nonatomic, copy) NSString *leagueName;
@property (nonatomic, assign) NSInteger duration;
@property (nonatomic, assign) NSInteger yellowCards;
@property (nonatomic, assign) NSInteger redCards;
@property (nonatomic, assign) NSInteger attendance;
@property (nonatomic, copy) NSString *homeResult;
@property (nonatomic, copy) NSString *awayResult;
@property (nonatomic, assign) BOOL favorited;
@end

NS_ASSUME_NONNULL_END
