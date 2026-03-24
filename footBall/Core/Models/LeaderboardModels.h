#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class TeamIcon;

@interface PNLeaderboardEntry : NSObject <YYModel>
@property (nonatomic, assign) NSInteger rank;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *avatar;
@property (nonatomic, copy) NSString *nickname;
@property (nonatomic, strong) NSArray<TeamIcon *> *followedTeams;
@property (nonatomic, assign) NSInteger matchCount;
@end

@interface PNLeaderboard : NSObject <YYModel>
@property (nonatomic, strong) NSArray<PNLeaderboardEntry *> *list;
@property (nonatomic, assign) NSInteger total;
@property (nonatomic, assign) NSInteger pageNum;
@property (nonatomic, assign) NSInteger pageSize;
@property (nonatomic, strong, nullable) PNLeaderboardEntry *currentUser;
@end

NS_ASSUME_NONNULL_END
