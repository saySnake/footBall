//
//  StampRequest.m
//  footBall
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

- (void)showStamp:(NSString *)stampId
         position:(NSString *)position
          success:(APISuccessBlock)success
          failure:(APIFailureBlock)failure {
    if (stampId.length == 0) {
        if (failure) failure([NSError errorWithDomain:@"StampRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"邮票ID不能为空" }]);
        return;
    }
    if (position.length == 0) {
        if (failure) failure([NSError errorWithDomain:@"StampRequestErrorDomain" code:-2 userInfo:@{ NSLocalizedDescriptionKey: @"位置不能为空" }]);
        return;
    }
    [[APIManager sharedManager] POST:APIPathValueStampShow(stampId) parameters:@{ @"position": position } headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)hideStamp:(NSString *)stampId
          success:(APISuccessBlock)success
          failure:(APIFailureBlock)failure {
    if (stampId.length == 0) {
        if (failure) failure([NSError errorWithDomain:@"StampRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"邮票ID不能为空" }]);
        return;
    }
    [[APIManager sharedManager] POST:APIPathValueStampHide(stampId) parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)replaceStamp:(NSString *)stampId
          newStampId:(NSString *)newStampId
             success:(APISuccessBlock)success
             failure:(APIFailureBlock)failure {
    if (stampId.length == 0 || newStampId.length == 0) {
        if (failure) failure([NSError errorWithDomain:@"StampRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"无效的邮票" }]);
        return;
    }
    // 文档要求 newStampId 为 Long
    long long nid = [newStampId longLongValue];
    id newIdParam = (nid > 0) ? @(nid) : newStampId;
    [[APIManager sharedManager] POST:APIPathValueStampReplace(stampId) parameters:@{ @"newStampId": newIdParam } headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)updateStampPosition:(NSString *)stampId
                   position:(NSString *)position
                    success:(APISuccessBlock)success
                    failure:(APIFailureBlock)failure {
    if (stampId.length == 0) {
        if (failure) failure([NSError errorWithDomain:@"StampRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"邮票ID不能为空" }]);
        return;
    }
    if (position.length == 0) {
        if (failure) failure([NSError errorWithDomain:@"StampRequestErrorDomain" code:-2 userInfo:@{ NSLocalizedDescriptionKey: @"位置不能为空" }]);
        return;
    }
    [[APIManager sharedManager] POST:APIPathValueStampPosition(stampId) parameters:@{ @"position": position } headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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
            id data = responseObject.data;
            id objs = data;
            if ([data isKindOfClass:NSArray.class]) {
                objs = [NSArray yy_modelArrayWithClass:PNStampAlbumItem.class json:data] ?: @[];
            } else if ([data isKindOfClass:NSDictionary.class]) {
                id arr = ((NSDictionary *)data)[@"stamps"] ?: ((NSDictionary *)data)[@"list"];
                if ([arr isKindOfClass:NSArray.class]) {
                    objs = [NSArray yy_modelArrayWithClass:PNStampAlbumItem.class json:arr] ?: @[];
                }
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
            PNStampAlbumItem *item = [PNStampAlbumItem yy_modelWithJSON:responseObject.data];
            responseObject.dataObject = item ?: responseObject.data;
            if (success) success(responseObject);
        } else {
            if (failure) failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

@end
