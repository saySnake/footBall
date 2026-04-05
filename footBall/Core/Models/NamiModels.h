//
//  NamiModels.h
//  footBall
//
//  对应 NamiMatchVO、NamiMatchDetailVO、NamiMatchLiveVO、NamiMatchTrendVO、
//  NamiMatchLineupVO、NamiPlayerStatVO、NamiStreamUrlVO、NamiVideoCollectionVO。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 单条技术统计（主客队数值）
@interface PNNamiStatItem : NSObject <YYModel>
/// 统计类型 ID
@property (nonatomic, assign) NSInteger statType;
/// 统计项名称
@property (nonatomic, copy, nullable) NSString *statName;
@property (nonatomic, assign) NSInteger homeValue;
@property (nonatomic, assign) NSInteger awayValue;
@end

/// 单条比赛事件（进球、红黄牌等）
@interface PNNamiIncidentItem : NSObject <YYModel>
@property (nonatomic, assign) NSInteger incidentType;
@property (nonatomic, copy, nullable) NSString *incidentTypeName;
@property (nonatomic, assign) NSInteger position;
@property (nonatomic, copy, nullable) NSString *positionName;
@property (nonatomic, assign) NSInteger minute;
@property (nonatomic, assign) NSInteger second;
@property (nonatomic, assign) NSInteger playerId;
@property (nonatomic, copy, nullable) NSString *playerName;
@property (nonatomic, assign) NSInteger homeScore;
@property (nonatomic, assign) NSInteger awayScore;
@end

/// 文字直播一条
@interface PNNamiTextLiveItem : NSObject <YYModel>
@property (nonatomic, assign) NSInteger isMain;
@property (nonatomic, assign) NSInteger eventType;
@property (nonatomic, copy, nullable) NSString *eventTypeName;
@property (nonatomic, assign) NSInteger position;
@property (nonatomic, copy, nullable) NSString *positionName;
@property (nonatomic, copy, nullable) NSString *time;
@property (nonatomic, copy, nullable) NSString *content;
@end

/// 纳米比赛列表项
@interface PNNamiMatch : NSObject <YYModel>
@property (nonatomic, assign) NSInteger matchId;
@property (nonatomic, assign) NSInteger competitionId;
@property (nonatomic, assign) NSInteger seasonId;
@property (nonatomic, assign) NSInteger homeTeamId;
@property (nonatomic, assign) NSInteger awayTeamId;
@property (nonatomic, assign) NSInteger statusId;
@property (nonatomic, copy, nullable) NSString *matchStatus;
@property (nonatomic, copy, nullable) NSString *matchTime;
@property (nonatomic, assign) NSInteger homeScore;
@property (nonatomic, assign) NSInteger awayScore;
@property (nonatomic, assign) NSInteger homeHalfScore;
@property (nonatomic, assign) NSInteger awayHalfScore;
@property (nonatomic, assign) NSInteger homeRedCards;
@property (nonatomic, assign) NSInteger awayRedCards;
@property (nonatomic, assign) NSInteger homeCorners;
@property (nonatomic, assign) NSInteger awayCorners;
@property (nonatomic, assign) NSInteger homeExtraScore;
@property (nonatomic, assign) NSInteger awayExtraScore;
@property (nonatomic, assign) NSInteger homePenaltyScore;
@property (nonatomic, assign) NSInteger awayPenaltyScore;
/// 是否有阵容：0/1
@property (nonatomic, assign) NSInteger hasLineup;
@property (nonatomic, assign) NSInteger venueId;
@property (nonatomic, assign) NSInteger roundNum;
@end

@class PNNamiMatchLive;

/// 纳米比赛详情（含 live、统计、事件）
@interface PNNamiMatchDetail : NSObject <YYModel>
@property (nonatomic, assign) NSInteger matchId;
@property (nonatomic, assign) NSInteger competitionId;
@property (nonatomic, assign) NSInteger homeTeamId;
@property (nonatomic, assign) NSInteger awayTeamId;
@property (nonatomic, assign) NSInteger statusId;
@property (nonatomic, copy, nullable) NSString *matchStatus;
@property (nonatomic, copy, nullable) NSString *matchTime;
@property (nonatomic, assign) NSInteger homeScore;
@property (nonatomic, assign) NSInteger awayScore;
@property (nonatomic, strong, nullable) PNNamiMatchLive *live;
@property (nonatomic, strong) NSArray<PNNamiStatItem *> *stats;
@property (nonatomic, strong) NSArray<PNNamiIncidentItem *> *incidents;
@end

/// 实时比分与文字直播等
@interface PNNamiMatchLive : NSObject <YYModel>
@property (nonatomic, assign) NSInteger matchId;
@property (nonatomic, assign) NSInteger statusId;
@property (nonatomic, copy, nullable) NSString *matchStatus;
@property (nonatomic, assign) NSInteger homeScore;
@property (nonatomic, assign) NSInteger awayScore;
@property (nonatomic, assign) NSInteger homeHalfScore;
@property (nonatomic, assign) NSInteger awayHalfScore;
@property (nonatomic, assign) NSInteger homeRedCards;
@property (nonatomic, assign) NSInteger awayRedCards;
@property (nonatomic, assign) NSInteger homeYellowCards;
@property (nonatomic, assign) NSInteger awayYellowCards;
@property (nonatomic, assign) NSInteger homeCorners;
@property (nonatomic, assign) NSInteger awayCorners;
@property (nonatomic, strong) NSArray<PNNamiStatItem *> *stats;
@property (nonatomic, strong) NSArray<PNNamiIncidentItem *> *incidents;
@property (nonatomic, strong) NSArray<PNNamiTextLiveItem *> *textLives;
@end

/// 比赛走势（控球率等序列，格式由后端约定）
@interface PNNamiMatchTrend : NSObject <YYModel>
@property (nonatomic, assign) NSInteger matchId;
@property (nonatomic, assign) NSInteger halfCount;
@property (nonatomic, assign) NSInteger halfDuration;
@property (nonatomic, copy, nullable) NSString *trendData;
@property (nonatomic, copy, nullable) NSString *incidents;
@end

/// 阵容中一名球员
@interface PNNamiLineupPlayer : NSObject <YYModel>
@property (nonatomic, assign) NSInteger playerId;
@property (nonatomic, assign) NSInteger teamId;
/// 主客侧标识
@property (nonatomic, copy, nullable) NSString *side;
@property (nonatomic, assign) NSInteger isStarter;
@property (nonatomic, assign) NSInteger isCaptain;
@property (nonatomic, copy, nullable) NSString *playerName;
@property (nonatomic, assign) NSInteger shirtNumber;
@property (nonatomic, copy, nullable) NSString *position;
/// 阵型图 X 坐标
@property (nonatomic, assign) NSInteger x;
/// 阵型图 Y 坐标
@property (nonatomic, assign) NSInteger y;
@property (nonatomic, copy, nullable) NSString *rating;
@end

/// 比赛阵容（阵型、颜色、球员列表）
@interface PNNamiMatchLineup : NSObject <YYModel>
@property (nonatomic, assign) NSInteger matchId;
@property (nonatomic, assign) NSInteger confirmed;
@property (nonatomic, copy, nullable) NSString *homeFormation;
@property (nonatomic, copy, nullable) NSString *awayFormation;
@property (nonatomic, assign) NSInteger homeCoachId;
@property (nonatomic, assign) NSInteger awayCoachId;
@property (nonatomic, copy, nullable) NSString *homeColor;
@property (nonatomic, copy, nullable) NSString *awayColor;
@property (nonatomic, strong) NSArray<PNNamiLineupPlayer *> *players;
@end

/// 球员单场技术统计
@interface PNNamiPlayerStat : NSObject <YYModel>
@property (nonatomic, assign) NSInteger matchId;
@property (nonatomic, assign) NSInteger playerId;
@property (nonatomic, assign) NSInteger teamId;
@property (nonatomic, assign) NSInteger isStarter;
@property (nonatomic, assign) NSInteger goals;
@property (nonatomic, assign) NSInteger assists;
@property (nonatomic, assign) NSInteger minutesPlayed;
@property (nonatomic, assign) NSInteger shots;
@property (nonatomic, assign) NSInteger shotsOnTarget;
@property (nonatomic, assign) NSInteger passes;
/// 传球成功率（百分比或原始值，以后端为准）
@property (nonatomic, assign) NSInteger passesAccuracy;
@property (nonatomic, assign) NSInteger keyPasses;
@property (nonatomic, assign) NSInteger dribble;
@property (nonatomic, assign) NSInteger dribbleSucc;
@property (nonatomic, assign) NSInteger tackles;
@property (nonatomic, assign) NSInteger interceptions;
@property (nonatomic, assign) NSInteger fouls;
@property (nonatomic, assign) NSInteger yellowCards;
@property (nonatomic, assign) NSInteger redCards;
@property (nonatomic, copy, nullable) NSString *rating;
@end

/// 直播/回放链接（移动端与 PC）
@interface PNNamiStreamUrl : NSObject <YYModel>
@property (nonatomic, assign) NSInteger matchId;
@property (nonatomic, copy, nullable) NSString *matchTime;
@property (nonatomic, copy, nullable) NSString *comp;
@property (nonatomic, copy, nullable) NSString *home;
@property (nonatomic, copy, nullable) NSString *away;
@property (nonatomic, copy, nullable) NSString *mobileLink;
@property (nonatomic, copy, nullable) NSString *pcLink;
@end

/// 集锦/录像条目
@interface PNNamiVideoCollection : NSObject <YYModel>
@property (nonatomic, assign) NSInteger matchId;
@property (nonatomic, assign) NSInteger videoType;
@property (nonatomic, copy, nullable) NSString *videoTypeName;
@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, copy, nullable) NSString *mobileLink;
@property (nonatomic, copy, nullable) NSString *pcLink;
@property (nonatomic, copy, nullable) NSString *cover;
/// 时长（秒）
@property (nonatomic, assign) NSInteger duration;
@end

NS_ASSUME_NONNULL_END
