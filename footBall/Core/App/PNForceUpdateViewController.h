//
//  PNForceUpdateViewController.h
//  footBall
//

#import <UIKit/UIKit.h>

@class PNAppVersionInfo;

NS_ASSUME_NONNULL_BEGIN

/// 强制更新全屏页，不可关闭
@interface PNForceUpdateViewController : UIViewController

- (instancetype)initWithVersionInfo:(PNAppVersionInfo *)info;

@end

NS_ASSUME_NONNULL_END
