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
#import "StampModels.h"
#import "StatisticsModels.h"
#import <YYModel/YYModel.h>

/// 好友邮票接口返回 MyStampsVO（categories），展平为带 position 的主页邮票列表
static NSArray<PNStampAlbumItem *> *PNHomeStampItemsFromFriendStampsPayload(id data) {
    if ([data isKindOfClass:NSArray.class]) {
        return [NSArray yy_modelArrayWithClass:PNStampAlbumItem.class json:data] ?: @[];
    }
    if (![data isKindOfClass:NSDictionary.class]) {
        return @[];
    }
    id categories = ((NSDictionary *)data)[@"categories"];
    if (![categories isKindOfClass:NSArray.class]) {
        return @[];
    }
    NSMutableArray<PNStampAlbumItem *> *items = [NSMutableArray array];
    for (id category in (NSArray *)categories) {
        if (![category isKindOfClass:NSDictionary.class]) {
            continue;
        }
        id stamps = ((NSDictionary *)category)[@"stamps"];
        if (![stamps isKindOfClass:NSArray.class]) {
            continue;
        }
        NSArray<PNStampAlbumItem *> *parsed = [NSArray yy_modelArrayWithClass:PNStampAlbumItem.class json:stamps] ?: @[];
        for (PNStampAlbumItem *item in parsed) {
            if (item.position.length > 0) {
                [items addObject:item];
            }
        }
    }
    return [items copy];
}

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
            responseObject.dataObject = PNHomeStampItemsFromFriendStampsPayload(responseObject.data);
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
            PNStatistics *statistics = [PNStatistics yy_modelWithJSON:responseObject.data];
            responseObject.dataObject = statistics ?: responseObject.data;
            if (success) success(responseObject);
        } else {
            if (failure) failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

@end
