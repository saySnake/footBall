#import "SocialRequest.h"

@implementation SocialRequest
+ (instancetype)shared {
    static SocialRequest *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = SocialRequest.alloc.init;
    });
    return instance;
}

- (void)getFriendRequestsSuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    [[APIManager sharedManager] GET:APIPathValueFriendsRequests parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) success(responseObject);
        else failure([APIError errorWithResponse:responseObject]);
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];
}

- (void)getFriendRequestsPendingCountSuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    [[APIManager sharedManager] GET:APIPathValueFriendsRequestsPendingCount parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) success(responseObject);
        else failure([APIError errorWithResponse:responseObject]);
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];
}

- (void)processFriendRequest:(NSString *)requestId accept:(BOOL)accept success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (requestId.length == 0) {
        failure([NSError errorWithDomain:@"SocialRequestErrorDomain" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"requestId不能为空"}]);
        return;
    }
    NSDictionary *params = @{@"action": accept ? @"accept" : @"reject"};
    [[APIManager sharedManager] PUT:APIPathValueFriendsRequestProcess(requestId) parameters:params headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) success(responseObject);
        else failure([APIError errorWithResponse:responseObject]);
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];
}

- (void)getFriendsSuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    [[APIManager sharedManager] GET:APIPathValueFriendsList parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) success(responseObject);
        else failure([APIError errorWithResponse:responseObject]);
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];
}

- (void)getFollowingSuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    [[APIManager sharedManager] GET:APIPathValueFollowsFollowing parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) success(responseObject);
        else failure([APIError errorWithResponse:responseObject]);
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];
}

- (void)getFollowersSuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    [[APIManager sharedManager] GET:APIPathValueFollowsFollowers parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) success(responseObject);
        else failure([APIError errorWithResponse:responseObject]);
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];
}

- (void)getRecommendFriendsSuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    [[APIManager sharedManager] GET:APIPathValueFriendsRecommend parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) success(responseObject);
        else failure([APIError errorWithResponse:responseObject]);
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];
}
@end
