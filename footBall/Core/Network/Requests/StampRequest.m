//
//  StampRequest.m
//  footBall
//
//  响应体解析为业务 Model 可在各接口 success 内扩展 yy_model；当前保留原始 data。
//

#import "StampRequest.h"
#import "APIManager.h"
#import "APIPathValues.h"
#import "APIError.h"

@implementation StampRequest

+ (instancetype)shared {
    static StampRequest *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[StampRequest alloc] init];
    });
    return instance;
}

- (void)getStampCollectionSuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    [[APIManager sharedManager] GET:APIPathValueStampsCollection parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)getStampCategoriesSuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    [[APIManager sharedManager] GET:APIPathValueStampsCategories parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)getAllStampsInCategory:(NSString *)categoryId success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (categoryId.length == 0) {
        if (failure) failure([NSError errorWithDomain:@"StampRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"分类ID不能为空" }]);
        return;
    }
    [[APIManager sharedManager] GET:APIPathValueStampsCategoryAll(categoryId) parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)getStampDetail:(NSString *)stampId success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (stampId.length == 0) {
        if (failure) failure([NSError errorWithDomain:@"StampRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"邮票ID不能为空" }]);
        return;
    }
    [[APIManager sharedManager] GET:APIPathValueStampsDetail(stampId) parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)updateStampDisplayWithBody:(NSDictionary *)body success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (![body isKindOfClass:NSDictionary.class]) {
        if (failure) failure([NSError errorWithDomain:@"StampRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"请求体无效" }]);
        return;
    }
    [[APIManager sharedManager] PUT:APIPathValueStampsDisplay parameters:body headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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
