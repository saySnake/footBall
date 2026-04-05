//
//  CommunityRequest.m
//  footBall
//
//  社区好友相关 GET；分页参数与后端约定为 pageNum / pageSize。
//

#import "CommunityRequest.h"
#import "APIManager.h"
#import "APIPathValues.h"
#import "APIError.h"

@implementation CommunityRequest

+ (instancetype)shared {
    static CommunityRequest *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[CommunityRequest alloc] init];
    });
    return instance;
}

- (void)getCommunityFriendsWithPage:(NSInteger)page pageSize:(NSInteger)pageSize success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    NSDictionary *params = @{ @"pageNum": @(MAX(page, 1)), @"pageSize": @(MAX(pageSize, 1)) };
    [[APIManager sharedManager] GET:APIPathValueCommunityFriends parameters:params headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            responseObject.dataObject = responseObject.data;
            if (success) success(responseObject);
        } else {
            if (failure) failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

- (void)getFriendStamps:(NSString *)friendId success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (friendId.length == 0) {
        if (failure) failure([NSError errorWithDomain:@"CommunityRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"好友ID不能为空" }]);
        return;
    }
    [[APIManager sharedManager] GET:APIPathValueCommunityFriendStamps(friendId) parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            responseObject.dataObject = responseObject.data;
            if (success) success(responseObject);
        } else {
            if (failure) failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

- (void)getFriendData:(NSString *)friendId success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (friendId.length == 0) {
        if (failure) failure([NSError errorWithDomain:@"CommunityRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"好友ID不能为空" }]);
        return;
    }
    [[APIManager sharedManager] GET:APIPathValueCommunityFriendData(friendId) parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            responseObject.dataObject = responseObject.data;
            if (success) success(responseObject);
        } else {
            if (failure) failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

@end
