//
//  FileRequest.m
//  footBall
//
//  Created by LWJ on 2026/3/22.
//

#import "FileRequest.h"
#import "HTTPResponse.h"
#import "AuthManager.h"
#define OSS_ENDPOINT                    @"http://oss-cn-region.aliyuncs.com"      // 访问的阿里云endpoint

@implementation FileRequest
+(instancetype)shared {
    static FileRequest *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = FileRequest.alloc.init;
        [[NSNotificationCenter defaultCenter] addObserver:instance selector:@selector(tokenExpiredNotification) name:TokenExpiredNotification object:nil];
    });
    return instance;
}
- (void)tokenExpiredNotification {
    self.stsToken = nil;
    self.defaultClient = nil;
}
- (void)setupSTSToken {
    // 针对只有一个region下bucket的数据上传下载操作时,可以将client实例给App单例持有。
    id<OSSCredentialProvider> credentialProvider = [[OSSFederationCredentialProvider alloc] initWithFederationTokenGetter:^OSSFederationToken * _Nullable{
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [FileRequest.shared getOSSTokenSuccess:^(HTTPResponse <STSToken *> * _Nullable responseObject) {
            dispatch_semaphore_signal(semaphore);
        } failure:^(NSError * _Nonnull error) {
            dispatch_semaphore_signal(semaphore);
        }];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSString *ak = self.stsToken.accessKeyId;
        NSString *sk = self.stsToken.accessKeySecret;
        NSString *token = self.stsToken.securityToken;
        NSString *expiration = self.stsToken.expiration;

        OSSFederationToken * federationToken = [OSSFederationToken new];
        federationToken.tAccessKey = ak;
        federationToken.tSecretKey = sk;
        federationToken.tToken = token;
        federationToken.expirationTimeInGMTFormat = expiration;

        return federationToken;
    }];

    OSSClientConfiguration *cfg = [[OSSClientConfiguration alloc] init];
    cfg.maxRetryCount = 3;
    cfg.timeoutIntervalForRequest = 15;
    cfg.isHttpdnsEnable = NO;
    cfg.crc64Verifiable = YES;
    
    OSSClient *defaultClient = [[OSSClient alloc] initWithEndpoint:OSS_ENDPOINT credentialProvider:credentialProvider clientConfiguration:cfg];
    self.defaultClient = defaultClient;

}
- (void)getOSSTokenSuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (!AuthManager.sharedManager.isLoggedIn) {
        if (failure) {
            NSError *error = [NSError errorWithDomain:@"AuthManagerErrorDomain"
                                                  code:-1
                                              userInfo:@{NSLocalizedDescriptionKey: @"用户未登录"}];
            failure(error);
        }
        return;
    }

    [[APIManager sharedManager] GET:APIPathValueOSSToken parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            STSToken *token = [STSToken yy_modelWithJSON:responseObject.data];
            self.stsToken = token;
            responseObject.dataObject = token;
            success(responseObject);
        } else {
            failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];
}
- (NSString *)objectType:(ImageObjectType)type {
    switch (type) {
        case ImageObjectTypeProfile:
            return @"profile";
            break;
        case ImageObjectTypeIDCard:
            return @"idcard";
            break;
        case ImageObjectTypeProfessional:
            return @"professional";
            break;
        case ImageObjectTypeMatch:
            return @"match";
            break;
        case ImageObjectTypeMatchRecord:
            return @"matchrecord";
            break;
        default:
            return @"other";
            break;
    }
}
- (void)uploadImage:(NSData *)data type:(ImageObjectType)type success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (!data) {
        NSError *error = [NSError errorWithDomain:NSInvalidArgumentException code:0 userInfo:@{NSLocalizedDescriptionKey: @"头像不能为空"}];
        failure(error);
        return;
    }
    if (!self.stsToken || !self.defaultClient) {
        __weak typeof(self) weakSelf = self;
        [self getOSSTokenSuccess:^(HTTPResponse * _Nullable responseObject) {
            [weakSelf setupSTSToken];
            [weakSelf uploadImage:data type:type success:success failure:failure];
        } failure:failure];
        return;
    }

    NSString *objectKey = [NSString stringWithFormat:@"%@/%@/%.0f.jpg",
                           AuthManager.sharedManager.user.userId ?: @"user",
                           [self objectType:type],
                           [NSDate date].timeIntervalSince1970 * 1000.0];

    OSSPutObjectRequest *_normalUploadRequest = [OSSPutObjectRequest new];
    _normalUploadRequest.bucketName = self.stsToken.bucket;
    _normalUploadRequest.objectKey = objectKey;
    _normalUploadRequest.uploadingData = data;
    _normalUploadRequest.isAuthenticationRequired = YES;
    _normalUploadRequest.uploadProgress = ^(int64_t bytesSent, int64_t totalByteSent, int64_t totalBytesExpectedToSend) {
        float progress = 1.f * totalByteSent / totalBytesExpectedToSend;
        OSSLogDebug(@"上传文件进度: %f", progress);
    };
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSSTask * task = [self.defaultClient putObject:_normalUploadRequest];
        [task continueWithBlock:^id(OSSTask *task) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (task.error) {
                    failure(task.error);
                } else {
                    NSLog(@"[OSS] upload result: %@",task.result);
                    NSString *bucket = self.stsToken.bucket ?: @"";
                    NSString *region = self.stsToken.region.length ? self.stsToken.region : @"cn-hangzhou";
                    NSString *urlStr = [NSString stringWithFormat:@"https://%@.oss-%@.aliyuncs.com/%@", bucket, region, objectKey];
                    HTTPResponse *resp = [[HTTPResponse alloc] init];
                    resp.success = YES;
                    resp.dataObject = urlStr;
                    if (success) success(resp);
                }
            });

            return nil;
        }];
    });

}
@end
@implementation STSToken

@end
