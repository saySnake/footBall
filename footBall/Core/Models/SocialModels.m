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
    return @{@"userId": @[@"userId", @"id"]};
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
