//
//  PNMatchVerifyViewController.h
//  footBall
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 认证比赛底部弹层（上传比赛照片 + 定位）
@interface PNMatchVerifyViewController : UIViewController
@property (nonatomic, strong) NSString *recordId;
/// 完成认证后的回调（用于通知上层“认证比赛”流程已完成）
@property (nonatomic, copy) void (^completion)(void);

@end

NS_ASSUME_NONNULL_END

