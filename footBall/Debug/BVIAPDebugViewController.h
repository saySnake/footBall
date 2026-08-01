//
//  BVIAPDebugViewController.h
//  footBall
//
//  仅 DEBUG：IAP（App Store 内购）调试面板。
//  覆盖审核测试场景：购买成功/失败/恢复/兑换码/掉单/收据为空等。
//  说明：SKPaymentTransaction 由系统管理，无法直接 mock，
//  本面板用「等价触发」方式验证关键路径（直接调 MembershipRequest、
//  触发 PNIAPObserver.resumePendingTransactions、模拟用户已是会员等）。
//

#ifdef DEBUG

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BVIAPDebugViewController : UIViewController

@end

NS_ASSUME_NONNULL_END

#endif
