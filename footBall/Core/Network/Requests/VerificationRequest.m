//
//  VerificationRequest.m
//  footBall
//
//  实名/职业认证提交与状态查询；status 成功后会调用 applyVerificationStatusData: 写 AuthStateStore。
//  realname、professional 的 POST 参数字段若后端改为 snake_case，需在对应方法内调整。
//

#import "VerificationRequest.h"
#import "APIManager.h"
#import "APIPathValues.h"
#import "APIError.h"
#import "AuthManager.h"
#import "AuthStateStore.h"
#import "VerificationModels.h"
#import <YYModel/YYModel.h>

@implementation VerificationRequest

+ (instancetype)shared {
    static VerificationRequest *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[VerificationRequest alloc] init];
    });
    return instance;
}

- (void)fetchStatusSuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (!AuthManager.sharedManager.isLoggedIn) {
        if (failure) {
            failure([NSError errorWithDomain:@"AuthManagerErrorDomain" code:-1
                                    userInfo:@{NSLocalizedDescriptionKey: @"用户未登录"}]);
        }
        return;
    }
    [[APIManager sharedManager] GET:APIPathValueVerificationStatus parameters:nil headers:nil
                            success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            [VerificationRequest applyVerificationStatusData:responseObject.data];
            if (success) success(responseObject);
        } else {
            if (failure) failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

- (void)submitRealnameWithFrontUrl:(NSString *)frontUrl backUrl:(NSString *)backUrl
                           success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (!AuthManager.sharedManager.isLoggedIn) {
        if (failure) {
            failure([NSError errorWithDomain:@"AuthManagerErrorDomain" code:-1
                                    userInfo:@{NSLocalizedDescriptionKey: @"用户未登录"}]);
        }
        return;
    }
    if (frontUrl.length == 0 || backUrl.length == 0) {
        if (failure) {
            failure([NSError errorWithDomain:@"VerificationRequest" code:-2
                                    userInfo:@{NSLocalizedDescriptionKey: @"证件图片地址无效"}]);
        }
        return;
    }
    /// 与后端约定：camelCase；若实际为 snake_case，可改为 id_card_front_url / id_card_back_url
    NSDictionary *params = @{
        @"idCardFrontUrl": frontUrl,
        @"idCardBackUrl": backUrl,
    };
    [[APIManager sharedManager] POST:APIPathValueVerificationRealname parameters:params headers:nil
                             success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            if (success) success(responseObject);
        } else {
            if (failure) failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

- (void)submitProfessionalWithImageUrls:(NSArray<NSString *> *)urls
                                success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (!AuthManager.sharedManager.isLoggedIn) {
        if (failure) {
            failure([NSError errorWithDomain:@"AuthManagerErrorDomain" code:-1
                                    userInfo:@{NSLocalizedDescriptionKey: @"用户未登录"}]);
        }
        return;
    }
    if (urls.count == 0) {
        if (failure) {
            failure([NSError errorWithDomain:@"VerificationRequest" code:-2
                                    userInfo:@{NSLocalizedDescriptionKey: @"请至少上传一张职业证明"}]);
        }
        return;
    }
    NSDictionary *params = @{ @"imageUrls": urls };
    [[APIManager sharedManager] POST:APIPathValueVerificationProfessional parameters:params headers:nil
                             success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            if (success) success(responseObject);
        } else {
            if (failure) failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

- (void)fetchRealnameInfoSuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (!AuthManager.sharedManager.isLoggedIn) {
        if (failure) {
            failure([NSError errorWithDomain:@"AuthManagerErrorDomain" code:-1
                                    userInfo:@{NSLocalizedDescriptionKey: @"用户未登录"}]);
        }
        return;
    }
    [[APIManager sharedManager] GET:APIPathValueVerificationRealnameInfo parameters:nil headers:nil
                            success:^(HTTPResponse * _Nullable responseObject) {
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

- (void)fetchHistorySuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (!AuthManager.sharedManager.isLoggedIn) {
        if (failure) {
            failure([NSError errorWithDomain:@"AuthManagerErrorDomain" code:-1
                                    userInfo:@{NSLocalizedDescriptionKey: @"用户未登录"}]);
        }
        return;
    }
    [[APIManager sharedManager] GET:APIPathValueVerificationHistory parameters:nil headers:nil
                            success:^(HTTPResponse * _Nullable responseObject) {
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

+ (void)applyVerificationStatusData:(id)data {
    if (![data isKindOfClass:[NSDictionary class]]) return;
    NSDictionary *d = (NSDictionary *)data;

    PNVerificationStatus *parsed = [PNVerificationStatus yy_modelWithJSON:d];
    [VerificationRequest shared].cachedVerificationStatus = parsed;

    BOOL (^parseBool)(id) = ^BOOL(id o) {
        if ([o isKindOfClass:[NSNumber class]]) return [o boolValue];
        if ([o isKindOfClass:[NSString class]]) {
            NSString *s = [(NSString *)o lowercaseString];
            return [s isEqualToString:@"1"] || [s isEqualToString:@"true"] || [s isEqualToString:@"approved"] || [s isEqualToString:@"verified"] || [s isEqualToString:@"passed"];
        }
        return NO;
    };

    id rn = d[@"realNameVerified"] ?: d[@"realnameVerified"] ?: d[@"idCardVerified"] ?: d[@"realNamePassed"];
    id pr = d[@"professionalVerified"] ?: d[@"workCertVerified"] ?: d[@"professionalPassed"];

    NSDictionary *rnObj = d[@"realName"];
    if ([rnObj isKindOfClass:[NSDictionary class]]) {
        NSString *st = rnObj[@"status"] ?: rnObj[@"state"];
        if (st.length) rn = @([st isEqualToString:@"approved"] || [st isEqualToString:@"verified"] || [st isEqualToString:@"passed"]);
        else if (rnObj[@"verified"]) rn = rnObj[@"verified"];
    }
    NSDictionary *prObj = d[@"professional"];
    if ([prObj isKindOfClass:[NSDictionary class]]) {
        NSString *st = prObj[@"status"] ?: prObj[@"state"];
        if (st.length) pr = @([st isEqualToString:@"approved"] || [st isEqualToString:@"verified"] || [st isEqualToString:@"passed"]);
        else if (prObj[@"verified"]) pr = prObj[@"verified"];
    }

    if (rn) [AuthStateStore setRealNameAuthCompleted:parseBool(rn)];
    if (pr) [AuthStateStore setProfessionalAuthCompleted:parseBool(pr)];
}

@end
