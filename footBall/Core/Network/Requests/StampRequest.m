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
#import "StampModels.h"

@implementation StampRequest

+ (instancetype)shared {
    static StampRequest *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[StampRequest alloc] init];
    });
    return instance;
}
- (void)getStampListSuccess:(nullable APISuccessBlock)success
                    failure:(nullable APIFailureBlock)failure {
    [[APIManager sharedManager] GET:APIPathValueStampsList parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            id data = responseObject.data;
            id objs = data;
            if ([data isKindOfClass:NSArray.class]) {
                objs = [NSArray yy_modelArrayWithClass:PNStampAlbumItem.class json:data] ?: @[];
            }
            responseObject.dataObject = objs;
            if (success) success(responseObject);
        } else {
            if (failure) failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}
- (void)addStamp:(NSString *)stampId position:(NSString *)position success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    [[APIManager sharedManager] POST:APIPathValueDeleteStamps(stampId) parameters:@{@"position":position} headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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
-(void)updateOldStamp:(NSString *)stampId newStamp:(NSString *)newStampId success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (!stampId || !newStampId) {
        if (failure) failure([NSError errorWithDomain:@"StampRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"无效的邮票" }]);
        return;
    }
    [[APIManager sharedManager] PUT:APIPathValueUpdateStamps(stampId) parameters:@{@"newStampId":newStampId} headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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
- (void)deleteStamp:(NSString *)stampId success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    [[APIManager sharedManager] DELETE:APIPathValueDeleteStamps(stampId) parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)getMyStampsSuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    [[APIManager sharedManager] GET:APIPathValueStampsCategories parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            NSArray<PNStampCategory *> *cats = @[];
            if ([responseObject.data isKindOfClass:NSDictionary.class]) {
                id arr = ((NSDictionary *)responseObject.data)[@"categories"];
                if ([arr isKindOfClass:NSArray.class]) {
                    cats = [NSArray yy_modelArrayWithClass:PNStampCategory.class json:arr] ?: @[];
                }
            }
            responseObject.dataObject = cats;
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
            id data = responseObject.data;
            id objs = data;
            if ([data isKindOfClass:NSArray.class]) {
                objs = [NSArray yy_modelArrayWithClass:PNStampAlbumItem.class json:data] ?: @[];
            }
            responseObject.dataObject = objs;
            if (success) success(responseObject);
        } else {
            if (failure) failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

- (void)getSelectableStampsSuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    [[APIManager sharedManager] GET:APIPathValueStampsSelectable parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            NSArray<PNStampCategory *> *cats = @[];
            if ([responseObject.data isKindOfClass:NSDictionary.class]) {
                id arr = ((NSDictionary *)responseObject.data)[@"categories"];
                if ([arr isKindOfClass:NSArray.class]) {
                    cats = [NSArray yy_modelArrayWithClass:PNStampCategory.class json:arr] ?: @[];
                }
            }
            responseObject.dataObject = cats;
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
    [[APIManager sharedManager] GET:APIPathValueStampDetail(stampId) parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)getStampQuotaSuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    [[APIManager sharedManager] GET:APIPathValueStampsQuota parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)selectStamp:(NSString *)stampId position:(nullable NSString *)position success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (stampId.length == 0) {
        if (failure) failure([NSError errorWithDomain:@"StampRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"邮票ID不能为空" }]);
        return;
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (position.length > 0) {
        params[@"position"] = position;
    }
    [[APIManager sharedManager] POST:APIPathValueStampsSelect(stampId) parameters:params headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)updateStampPosition:(NSString *)stampId position:(NSString *)position success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (stampId.length == 0) {
        if (failure) failure([NSError errorWithDomain:@"StampRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"邮票ID不能为空" }]);
        return;
    }
    if (position.length == 0) {
        if (failure) failure([NSError errorWithDomain:@"StampRequestErrorDomain" code:-2 userInfo:@{ NSLocalizedDescriptionKey: @"位置不能为空" }]);
        return;
    }
    [[APIManager sharedManager] PUT:APIPathValueStampPosition(stampId) parameters:@{@"position": position} headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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
