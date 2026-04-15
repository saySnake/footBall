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
- (void)getStampCollectionSuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    [[APIManager sharedManager] GET:APIPathValueStampsCollection parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            PNStampCollection *collection = nil;
            if ([responseObject.data isKindOfClass:NSDictionary.class]) {
                collection = [PNStampCollection yy_modelWithJSON:responseObject.data];
            }
            responseObject.dataObject = collection;
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
            // data: array
            // - stamps: [{ stampId/id, name, image, rarity, unlocked, ... }]
            // - or categories (backend compatibility): [{ id, name, icon, sortOrder }]
            id data = responseObject.data;
            id out = data;
            if ([data isKindOfClass:NSArray.class]) {
                NSDictionary *first = ([(NSArray *)data count] > 0 && [[(NSArray *)data firstObject] isKindOfClass:NSDictionary.class]) ? (NSDictionary *)[(NSArray *)data firstObject] : nil;
                BOOL looksLikeStamp = (first[@"image"] != nil || first[@"rarity"] != nil || first[@"unlocked"] != nil || first[@"unlockCondition"] != nil);
                BOOL looksLikeCategory = (first[@"sortOrder"] != nil || first[@"icon"] != nil);
                if (looksLikeStamp) {
                    out = [NSArray yy_modelArrayWithClass:PNStampGridItem.class json:data] ?: @[];
                } else if (looksLikeCategory) {
                    out = [NSArray yy_modelArrayWithClass:PNStampCategory.class json:data] ?: @[];
                }
            }
            responseObject.dataObject = out;
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
