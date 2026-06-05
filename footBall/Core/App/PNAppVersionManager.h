//
//  PNAppVersionManager.h
//  footBall
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class PNAppVersionInfo;

NS_ASSUME_NONNULL_BEGIN

@interface PNAppVersionManager : NSObject

+ (instancetype)shared;

+ (NSString *)marketingVersion;
+ (NSString *)buildNumber;

/// 启动/回前台时检查；network 失败时 `needsForceUpdate=NO` 且 `error` 非空
- (void)checkForceUpdateWithCompletion:(void (^)(BOOL needsForceUpdate, PNAppVersionInfo * _Nullable info, NSError * _Nullable error))completion;

/// 在指定 window 上展示不可关闭的强制更新页
- (void)presentForceUpdateOnWindow:(UIWindow *)window info:(PNAppVersionInfo *)info;

/// 接口返回 000007 时调用
- (void)handleAPIErrorIfNeeded:(NSError *)error;

- (nullable UIWindow *)keyWindow;

/// 强制更新遮罩 window（存在时表示用户须先更新）
@property (nonatomic, weak, readonly, nullable) UIWindow *forceUpdateWindow;

@end

NS_ASSUME_NONNULL_END
