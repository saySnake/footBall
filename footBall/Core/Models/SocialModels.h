//
//  SocialModels.h
//  footBall
//
//  好友申请、好友列表、用户搜索、关注统计、公开资料等 VO。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PNFriendRequest : NSObject <YYModel>
@property (nonatomic, copy) NSString *requestId;
@property (nonatomic, copy) NSString *fromUserId;
@property (nonatomic, copy) NSString *fromUserNickname;
@property (nonatomic, copy) NSString *fromUserAvatar;
@property (nonatomic, copy) NSString *toUserId;
/// 附言
@property (nonatomic, copy) NSString *message;
/// 状态：PENDING / ACCEPTED / REJECTED 等
@property (nonatomic, copy) NSString *status;
/// 列表分组用（如今日、本周）
@property (nonatomic, copy) NSString *timeGroup;
@property (nonatomic, copy) NSString *createTime;
@property (nonatomic, copy) NSString *handleTime;
@end

@interface PNFriend : NSObject <YYModel>
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *nickname;
@property (nonatomic, copy) NSString *avatar;
/// 是否在线
@property (nonatomic, assign) BOOL online;
@property (nonatomic, copy) NSString *lastOnlineTime;
/// 最近观赛摘要文案
@property (nonatomic, copy) NSString *recentMatchInfo;
@end

@interface PNUser : NSObject <YYModel>
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *nickname;
@property (nonatomic, copy) NSString *avatar;
@property (nonatomic, copy) NSString *city;
@property (nonatomic, copy) NSString *lastOnlineTime;
@end

@interface PNFriendRequestPage : NSObject <YYModel>
@property (nonatomic, strong) NSArray<PNFriendRequest *> *list;
@property (nonatomic, assign) NSInteger pageNum;
@property (nonatomic, assign) NSInteger pageSize;
@property (nonatomic, assign) NSInteger total;
@end

@interface PNFriendPage : NSObject <YYModel>
@property (nonatomic, strong) NSArray<PNFriend *> *list;
@property (nonatomic, assign) NSInteger pageNum;
@property (nonatomic, assign) NSInteger pageSize;
@property (nonatomic, assign) NSInteger total;
@end

@interface PNUserPage : NSObject <YYModel>
@property (nonatomic, strong) NSArray<PNUser *> *list;
@property (nonatomic, assign) NSInteger pageNum;
@property (nonatomic, assign) NSInteger pageSize;
@property (nonatomic, assign) NSInteger total;
@end

/// FriendStatsVO（/friends/stats）
@interface PNFriendStats : NSObject <YYModel>
/// 好友数量
@property (nonatomic, assign) NSInteger friendCount;
/// 关注数
@property (nonatomic, assign) NSInteger followingCount;
/// 粉丝数
@property (nonatomic, assign) NSInteger followerCount;
@end

/// FollowStatsVO（/follows/stats）
@interface PNFollowStats : NSObject <YYModel>
@property (nonatomic, assign) NSInteger followingCount;
@property (nonatomic, assign) NSInteger followerCount;
@end

/// UserPublicVO.YearlyStatsVO
@interface PNYearlyStat : NSObject <YYModel>
@property (nonatomic, assign) NSInteger year;
@property (nonatomic, assign) NSInteger matchCount;
@end

/// UserPublicVO（查看他人公开信息）
@interface PNUserPublic : NSObject <YYModel>
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *nickname;
@property (nonatomic, copy, nullable) NSString *avatar;
@property (nonatomic, assign) NSInteger totalMatches;
@property (nonatomic, assign) NSInteger homeMatches;
@property (nonatomic, assign) NSInteger awayMatches;
@property (nonatomic, strong) NSArray<PNYearlyStat *> *yearlyStats;
@end

NS_ASSUME_NONNULL_END
