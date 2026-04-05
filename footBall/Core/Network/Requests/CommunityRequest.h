//
//  CommunityRequest.h
//  footBall
//
//  社区相关：好友列表、好友邮票与数据（/api/v1/community/*）。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CommunityRequest : NSObject

+ (instancetype)shared;

/// GET `/api/v1/community/friends` — 社区好友列表；query `pageNum` / `pageSize`
- (void)getCommunityFriendsWithPage:(NSInteger)page
                           pageSize:(NSInteger)pageSize
                            success:(nullable APISuccessBlock)success
                            failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/community/friends/{friendId}/stamps` — 查看好友邮票收藏
- (void)getFriendStamps:(NSString *)friendId
                success:(nullable APISuccessBlock)success
                failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/community/friends/{friendId}/data` — 查看好友数据统计
- (void)getFriendData:(NSString *)friendId
              success:(nullable APISuccessBlock)success
              failure:(nullable APIFailureBlock)failure;

@end

NS_ASSUME_NONNULL_END
