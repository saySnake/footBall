#import "SocialModels.h"

@implementation PNFriendRequest
+ (NSDictionary<NSString *,id> *)modelCustomPropertyMapper {
    return @{
        @"requestId": @[@"requestId", @"id", @"request_id"],
        @"fromUserId": @[@"fromUserId", @"from_user_id", @"senderId", @"sender_id"],
        @"fromUserNickname": @[@"fromUserNickname", @"from_user_nickname", @"senderNickname", @"nickname", @"name"],
        @"fromUserAvatar": @[@"fromUserAvatar", @"from_user_avatar", @"avatar", @"headImg", @"headUrl"],
        @"toUserId": @[@"toUserId", @"to_user_id"],
        @"message": @[@"message", @"remark", @"note", @"content"],
        @"status": @[@"status", @"state"],
        @"timeGroup": @[@"timeGroup", @"time_group", @"group"],
        @"createTime": @[@"createTime", @"create_time", @"createdAt"],
        @"handleTime": @[@"handleTime", @"handle_time", @"updatedAt", @"handle_at"],
    };
}
/// 支持嵌套 fromUser：{ "fromUser": { "id","nickname","avatar" } }
- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    NSDictionary *from = dic[@"fromUser"];
    if (![from isKindOfClass:NSDictionary.class]) {
        from = dic[@"from_user"];
    }
    if (![from isKindOfClass:NSDictionary.class]) return YES;
    if (self.fromUserId.length == 0) {
        id uid = from[@"userId"] ?: from[@"id"] ?: from[@"uid"];
        if (uid) self.fromUserId = [NSString stringWithFormat:@"%@", uid];
    }
    if (self.fromUserNickname.length == 0) {
        id nn = from[@"nickname"] ?: from[@"nickName"] ?: from[@"name"];
        if (nn) self.fromUserNickname = [NSString stringWithFormat:@"%@", nn];
    }
    if (self.fromUserAvatar.length == 0) {
        id av = from[@"avatar"] ?: from[@"headImg"] ?: from[@"headUrl"];
        if (av) self.fromUserAvatar = [NSString stringWithFormat:@"%@", av];
    }
    return YES;
}
@end

@implementation PNFriend
+ (NSDictionary<NSString *,id> *)modelCustomPropertyMapper {
    return @{@"userId": @[@"userId", @"id"]};
}
@end

@implementation PNUser
+ (NSDictionary<NSString *,id> *)modelCustomPropertyMapper {
    return @{@"userId": @[@"userId", @"id", @"uid"],
             @"nickname": @[@"nickname", @"nickName", @"name"],
             @"avatar": @[@"avatar", @"headImg", @"headUrl", @"avatarUrl", @"headImage"]};
}
@end

@implementation PNFriendRequestPage
+ (NSDictionary<NSString *,id> *)modelCustomPropertyMapper {
    return @{ @"list": @[ @"list", @"records", @"items", @"rows" ] };
}
+ (NSDictionary<NSString *,id> *)modelContainerPropertyGenericClass {
    return @{@"list": PNFriendRequest.class};
}
@end

@implementation PNFriendPage
+ (NSDictionary<NSString *,id> *)modelCustomPropertyMapper {
    return @{ @"list": @[ @"list", @"records", @"items", @"rows", @"friends" ] };
}
+ (NSDictionary<NSString *,id> *)modelContainerPropertyGenericClass {
    return @{@"list": PNFriend.class};
}
@end

@implementation PNUserPage
+ (NSDictionary<NSString *,id> *)modelContainerPropertyGenericClass {
    return @{@"list": PNUser.class};
}
@end

@implementation PNFriendStats
@end

@implementation PNFollowStats
@end

@implementation PNYearlyStat
@end

@implementation PNUserPublic
+ (NSDictionary<NSString *,id> *)modelContainerPropertyGenericClass {
    return @{ @"yearlyStats": PNYearlyStat.class };
}
+ (NSDictionary<NSString *,id> *)modelCustomPropertyMapper {
    return @{ @"userId": @[ @"userId", @"id" ] };
}
@end
