//
//  SocialRequest.h
//  footBall
//
//  好友、关注、粉丝、推荐等社交相关接口（/api/v1/friends/*、/api/v1/follows/*）。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SocialRequest : NSObject

+ (instancetype)shared;

#pragma mark - 好友请求与列表

/// GET `/api/v1/friends/requests` — 好友申请列表；`dataObject` 为 `PNFriendRequestPage`
- (void)getFriendRequestsSuccess:(nullable APISuccessBlock)success
                         failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/friends/requests/pending-count` — 待处理申请数量；`dataObject` 为 `NSNumber`（整数）
- (void)getFriendRequestsPendingCountSuccess:(nullable APISuccessBlock)success
                                     failure:(nullable APIFailureBlock)failure;

/// PUT `/api/v1/friends/requests/{requestId}` — 同意或拒绝；参数 `action`: accept / reject
- (void)processFriendRequest:(NSString *)requestId
                      accept:(BOOL)accept
                     success:(nullable APISuccessBlock)success
                     failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/friends` — 好友列表；`dataObject` 为 `PNFriendPage`
- (void)getFriendsSuccess:(nullable APISuccessBlock)success
                  failure:(nullable APIFailureBlock)failure;

#pragma mark - 关注 / 粉丝

/// GET `/api/v1/follows/following` — 我关注的用户；`dataObject` 为 `PNUserPage`
- (void)getFollowingSuccess:(nullable APISuccessBlock)success
                    failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/follows/followers` — 粉丝列表；`dataObject` 为 `PNUserPage`
- (void)getFollowersSuccess:(nullable APISuccessBlock)success
                    failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/friends/recommend` — 推荐好友；`dataObject` 为 `PNUser` 数组
- (void)getRecommendFriendsSuccess:(nullable APISuccessBlock)success
                            failure:(nullable APIFailureBlock)failure;

#pragma mark - 关注（写操作 / 统计）

/// POST `/api/v1/follows/{userId}` — 关注用户
- (void)followUser:(NSString *)userId
           success:(nullable APISuccessBlock)success
           failure:(nullable APIFailureBlock)failure;

/// DELETE `/api/v1/follows/{userId}` — 取消关注
- (void)unfollowUser:(NSString *)userId
             success:(nullable APISuccessBlock)success
             failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/follows/stats` — 关注相关统计；`dataObject` 为原始 `data`（字典等）
- (void)getFollowStatsSuccess:(nullable APISuccessBlock)success
                      failure:(nullable APIFailureBlock)failure;

#pragma mark - 好友（写操作 / 统计）

/// POST `/api/v1/friends/requests` — 发送好友请求；body 字段名需与后端一致（如 targetUserId、message）
- (void)sendFriendRequestWithBody:(NSDictionary *)body
                          success:(nullable APISuccessBlock)success
                          failure:(nullable APIFailureBlock)failure;

/// DELETE `/api/v1/friends/{friendId}` — 删除好友
- (void)deleteFriend:(NSString *)friendId
             success:(nullable APISuccessBlock)success
             failure:(nullable APIFailureBlock)failure;

/// POST `/api/v1/friends/scan` — 扫码加好友；payload 与后端扫码协议一致
- (void)scanAddFriendWithPayload:(NSDictionary *)payload
                         success:(nullable APISuccessBlock)success
                         failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/friends/stats` — 好友统计；`dataObject` 为原始 `data`
- (void)getFriendStatsSuccess:(nullable APISuccessBlock)success
                      failure:(nullable APIFailureBlock)failure;

@end

NS_ASSUME_NONNULL_END
