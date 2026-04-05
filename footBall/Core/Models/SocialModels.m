#import "SocialModels.h"

@implementation PNFriendRequest
+ (NSDictionary<NSString *,id> *)modelCustomPropertyMapper {
    return @{@"requestId": @[@"requestId", @"id"],
             @"fromUserId": @"fromUserId",
             @"toUserId": @"toUserId"};
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
+ (NSDictionary<NSString *,id> *)modelContainerPropertyGenericClass {
    return @{@"list": PNFriendRequest.class};
}
@end

@implementation PNFriendPage
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
