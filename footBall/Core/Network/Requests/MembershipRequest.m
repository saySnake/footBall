//
//  MembershipRequest.m
//  footBall
//
//  购买验证 verifyPurchaseWithBody: 的字段需与 IAP 流程、后端 DTO 一致。
//

#import "MembershipRequest.h"
#import "APIManager.h"
#import "APIPathValues.h"
#import "APIError.h"

@implementation MembershipRequest

+ (instancetype)shared {
    static MembershipRequest *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[MembershipRequest alloc] init];
    });
    return instance;
}

- (void)getMembershipPlansSuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    [[APIManager sharedManager] GET:APIPathValueMembershipPlans parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)verifyPurchaseWithBody:(NSDictionary *)body success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (![body isKindOfClass:NSDictionary.class] || body.count == 0) {
        if (failure) failure([NSError errorWithDomain:@"MembershipRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"请求体不能为空" }]);
        return;
    }
    [[APIManager sharedManager] POST:APIPathValueMembershipPurchase parameters:body headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)getMembershipStatusSuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    [[APIManager sharedManager] GET:APIPathValueMembershipStatus parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)getMembershipBenefitsSuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    [[APIManager sharedManager] GET:APIPathValueMembershipBenefits parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)getMembershipRecordsWithPage:(NSInteger)page pageSize:(NSInteger)pageSize success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    NSDictionary *params = @{ @"pageNum": @(MAX(page, 1)), @"pageSize": @(MAX(pageSize, 1)) };
    [[APIManager sharedManager] GET:APIPathValueMembershipRecords parameters:params headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)redeemCodeWithBody:(NSDictionary *)body success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (![body isKindOfClass:NSDictionary.class] || body.count == 0) {
        if (failure) failure([NSError errorWithDomain:@"MembershipRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"兑换码不能为空" }]);
        return;
    }
    [[APIManager sharedManager] POST:APIPathValueMembershipRedeem parameters:body headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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
