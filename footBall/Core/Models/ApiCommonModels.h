//
//  ApiCommonModels.h
//  footBall
//
//  通用接口返回模型，如 OSS StsTokenVO。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 阿里云 OSS 临时凭证
@interface PNStsToken : NSObject <YYModel>
/// 临时访问密钥 ID
@property (nonatomic, copy) NSString *accessKeyId;
/// 临时访问密钥 Secret
@property (nonatomic, copy) NSString *accessKeySecret;
/// 安全令牌（Session Token）
@property (nonatomic, copy) NSString *securityToken;
/// 临时凭证过期时间
@property (nonatomic, copy, nullable) NSString *expiration;
/// 目标存储桶
@property (nonatomic, copy, nullable) NSString *bucket;
/// 区域，如 oss-cn-beijing
@property (nonatomic, copy, nullable) NSString *region;
@end

NS_ASSUME_NONNULL_END
