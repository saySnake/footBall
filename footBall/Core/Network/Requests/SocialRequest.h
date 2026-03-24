#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SocialRequest : NSObject
+ (instancetype)shared;
/// 好友申请列表
- (void)getFriendRequestsSuccess:(nullable APISuccessBlock)success
                         failure:(nullable APIFailureBlock)failure;
/// 待处理好友申请数
- (void)getFriendRequestsPendingCountSuccess:(nullable APISuccessBlock)success
                                     failure:(nullable APIFailureBlock)failure;
/// 处理好友申请
- (void)processFriendRequest:(NSString *)requestId
                      accept:(BOOL)accept
                     success:(nullable APISuccessBlock)success
                     failure:(nullable APIFailureBlock)failure;
/// 好友列表
- (void)getFriendsSuccess:(nullable APISuccessBlock)success
                  failure:(nullable APIFailureBlock)failure;
/// 关注列表
- (void)getFollowingSuccess:(nullable APISuccessBlock)success
                    failure:(nullable APIFailureBlock)failure;
/// 粉丝列表
- (void)getFollowersSuccess:(nullable APISuccessBlock)success
                    failure:(nullable APIFailureBlock)failure;
/// 推荐好友
- (void)getRecommendFriendsSuccess:(nullable APISuccessBlock)success
                            failure:(nullable APIFailureBlock)failure;
@end

NS_ASSUME_NONNULL_END
