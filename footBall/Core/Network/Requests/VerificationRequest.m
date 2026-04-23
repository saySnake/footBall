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

static NSString *PNStringOrEmpty(id value) {
    if ([value isKindOfClass:NSString.class]) {
        return (NSString *)value;
    }
    if ([value respondsToSelector:@selector(stringValue)]) {
        return [value stringValue];
    }
    return @"";
}

static NSArray<NSString *> *PNStringArray(id value) {
    if (![value isKindOfClass:NSArray.class]) {
        return @[];
    }
    NSMutableArray<NSString *> *out = [NSMutableArray array];
    for (id item in (NSArray *)value) {
        NSString *s = PNStringOrEmpty(item);
        if (s.length > 0) {
            [out addObject:s];
        }
    }
    return out;
}

+ (instancetype)shared {
    static VerificationRequest *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[VerificationRequest alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _cachedHistory = @[];
        _cachedProfessionalImageUrls = @[];
    }
    return self;
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
#if DEBUG
            NSLog(@"[VerifDebug] status response: %@", responseObject.data);
#endif
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
    NSDictionary *params = @{
        @"workCertUrls": urls,
        @"professionInfo": @"职业认证"
    };
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
            PNRealnameInfo *info = [PNRealnameInfo yy_modelWithJSON:responseObject.data];
            VerificationRequest *req = [VerificationRequest shared];
            req.cachedRealnameInfo = info;
            NSDictionary *raw = [responseObject.data isKindOfClass:NSDictionary.class] ? (NSDictionary *)responseObject.data : @{};
            NSString *frontUrl = PNStringOrEmpty(raw[@"idCardFrontUrl"]);
            if (frontUrl.length == 0) {
                frontUrl = PNStringOrEmpty(raw[@"id_card_front_url"]);
            }
            NSString *backUrl = PNStringOrEmpty(raw[@"idCardBackUrl"]);
            if (backUrl.length == 0) {
                backUrl = PNStringOrEmpty(raw[@"id_card_back_url"]);
            }
            req.cachedRealnameFrontUrl = frontUrl;
            req.cachedRealnameBackUrl = backUrl;
            responseObject.dataObject = info ?: responseObject.data;
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
            VerificationRequest *req = [VerificationRequest shared];
            NSArray *history = [NSArray yy_modelArrayWithClass:PNVerificationHistory.class json:responseObject.data];
            req.cachedHistory = history ?: @[];

            NSArray *rawList = [responseObject.data isKindOfClass:NSArray.class] ? (NSArray *)responseObject.data : @[];
            NSMutableArray<NSString *> *professionalUrls = [NSMutableArray array];
            NSString *frontUrl = req.cachedRealnameFrontUrl ?: @"";
            NSString *backUrl = req.cachedRealnameBackUrl ?: @"";
            for (id item in rawList) {
                if (![item isKindOfClass:NSDictionary.class]) {
                    continue;
                }
                NSDictionary *dict = (NSDictionary *)item;
                NSString *type = [PNStringOrEmpty(dict[@"type"]) uppercaseString];
                if ([type isEqualToString:@"PROFESSIONAL"]) {
                    NSArray<NSString *> *urls = PNStringArray(dict[@"workCertUrls"]);
                    if (urls.count == 0) urls = PNStringArray(dict[@"work_cert_urls"]);
                    if (urls.count == 0) urls = PNStringArray(dict[@"imageUrls"]);
                    if (urls.count == 0) urls = PNStringArray(dict[@"image_urls"]);
                    if (urls.count > 0) {
                        [professionalUrls addObjectsFromArray:urls];
                    }
                } else if ([type isEqualToString:@"REALNAME"]) {
                    if (frontUrl.length == 0) {
                        frontUrl = PNStringOrEmpty(dict[@"idCardFrontUrl"]);
                    }
                    if (frontUrl.length == 0) {
                        frontUrl = PNStringOrEmpty(dict[@"id_card_front_url"]);
                    }
                    if (backUrl.length == 0) {
                        backUrl = PNStringOrEmpty(dict[@"idCardBackUrl"]);
                    }
                    if (backUrl.length == 0) {
                        backUrl = PNStringOrEmpty(dict[@"id_card_back_url"]);
                    }
                }
            }
            req.cachedProfessionalImageUrls = professionalUrls.copy;
            req.cachedRealnameFrontUrl = frontUrl;
            req.cachedRealnameBackUrl = backUrl;
            responseObject.dataObject = history ?: responseObject.data;
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
