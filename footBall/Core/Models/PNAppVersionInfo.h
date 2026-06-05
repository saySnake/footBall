//
//  PNAppVersionInfo.h
//  footBall
//

#import <Foundation/Foundation.h>
#import <YYModel/YYModel.h>

NS_ASSUME_NONNULL_BEGIN

/// GET /api/v1/app/version-check 返回 data
@interface PNAppVersionInfo : NSObject <YYModel>

@property (nonatomic, assign) BOOL forceUpdate;
@property (nonatomic, copy, nullable) NSString *platform;
@property (nonatomic, copy, nullable) NSString *clientVersion;
@property (nonatomic, assign) NSInteger clientBuild;
@property (nonatomic, copy, nullable) NSString *minVersion;
@property (nonatomic, copy, nullable) NSString *latestVersion;
@property (nonatomic, copy, nullable) NSString *updateTitle;
@property (nonatomic, copy, nullable) NSString *updateMessage;
@property (nonatomic, copy, nullable) NSString *storeUrl;

@end

/// 服务端业务错误码：版本过低
FOUNDATION_EXPORT NSString * const PNAppVersionOutdatedErrorCode;
/// 须展示强制更新页（启动检查或接口 000007）
FOUNDATION_EXPORT NSString * const PNAppVersionForceUpdateRequiredNotification;

NS_ASSUME_NONNULL_END
