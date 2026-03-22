//
//  FileRequest.h
//  footBall
//
//  Created by LWJ on 2026/3/22.
//

#import <Foundation/Foundation.h>
#import <AliyunOSSiOS/OSSService.h>
typedef NS_ENUM(NSUInteger, ImageObjectType) {
    ImageObjectTypeProfile, /// 头像、用户资料相关类
    ImageObjectTypeIDCard, /// 身份证
    ImageObjectTypeProfessional, /// 职业认证
    ImageObjectTypeMatch, /// 球赛认证
    ImageObjectTypeMatchRecord, /// 比赛记录
    ImageObjectTypeOther
};

NS_ASSUME_NONNULL_BEGIN
@class STSToken;
@interface FileRequest : NSObject
@property (nonatomic, strong, nullable) OSSClient *defaultClient;
@property (nonatomic, strong, nullable) STSToken *stsToken;
+(instancetype)shared;
- (void)setupSTSToken;
/// 获取OSS临时上传凭证(STS Token)
- (void)getOSSTokenSuccess:(nullable APISuccessBlock)success
                   failure:(nullable APIFailureBlock)failure;
/// 上传头像到阿里云OSS
- (void)uploadImage:(NSData *)data type:(ImageObjectType)type
           success:(nullable APISuccessBlock)success
           failure:(nullable APIFailureBlock)failure;

@end
@interface STSToken : NSObject
@property (nonatomic, strong) NSString *accessKeyId;
@property (nonatomic, strong) NSString *accessKeySecret;
@property (nonatomic, strong) NSString *securityToken;
@property (nonatomic, strong) NSString *expiration;
@property (nonatomic, strong) NSString *bucket;
@property (nonatomic, strong) NSString *region;
@end
NS_ASSUME_NONNULL_END
