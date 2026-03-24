#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PNFriendRequest : NSObject <YYModel>
@property (nonatomic, copy) NSString *requestId;
@property (nonatomic, copy) NSString *fromUserId;
@property (nonatomic, copy) NSString *fromUserNickname;
@property (nonatomic, copy) NSString *fromUserAvatar;
@property (nonatomic, copy) NSString *toUserId;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *status;
@property (nonatomic, copy) NSString *timeGroup;
@property (nonatomic, copy) NSString *createTime;
@property (nonatomic, copy) NSString *handleTime;
@end

@interface PNFriend : NSObject <YYModel>
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *nickname;
@property (nonatomic, copy) NSString *avatar;
@property (nonatomic, assign) BOOL online;
@property (nonatomic, copy) NSString *lastOnlineTime;
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

NS_ASSUME_NONNULL_END
