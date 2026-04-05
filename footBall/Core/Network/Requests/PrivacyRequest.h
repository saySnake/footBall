//
//  PrivacyRequest.h
//  footBall
//
//  隐私设置读写（GET/PUT `/api/v1/privacy/settings`）。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PrivacyRequest : NSObject

+ (instancetype)shared;

/// GET `/api/v1/privacy/settings` — 获取当前用户隐私设置；`dataObject` 为原始 `data`
- (void)getPrivacySettingsSuccess:(nullable APISuccessBlock)success
                          failure:(nullable APIFailureBlock)failure;

/// PUT `/api/v1/privacy/settings` — 更新隐私设置；body 字段与后端 VO 对齐
- (void)updatePrivacySettingsWithBody:(NSDictionary *)body
                              success:(nullable APISuccessBlock)success
                              failure:(nullable APIFailureBlock)failure;

@end

NS_ASSUME_NONNULL_END
