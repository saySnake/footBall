//
//  LeaderboardModels.h
//  footBall
//
//  排行榜条目与分页结果。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class TeamIcon;

@interface PNLeaderboardEntry : NSObject <YYModel>
@property (nonatomic, assign) NSInteger rank;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *avatar;
@property (nonatomic, copy) NSString *nickname;
/// 接口可能在条目上直接给球队名，优先于 followedTeams.firstObject
@property (nonatomic, copy, nullable) NSString *teamName;
@property (nonatomic, strong) NSArray<TeamIcon *> *followedTeams;
/// 观赛/认证场次等业务计数
@property (nonatomic, assign) NSInteger matchCount;
@end

@interface PNLeaderboard : NSObject <YYModel>
@property (nonatomic, strong) NSArray<PNLeaderboardEntry *> *list;
@property (nonatomic, assign) NSInteger total;
@property (nonatomic, assign) NSInteger pageNum;
@property (nonatomic, assign) NSInteger pageSize;
/// 当前登录用户在榜中的位置（可能为 nil）
@property (nonatomic, strong, nullable) PNLeaderboardEntry *currentUser;
@end

NS_ASSUME_NONNULL_END
