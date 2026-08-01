//
//  PNIAPObserver.h
//  footBall
//
//  全局 IAP 事务观察者（与具体 VC 解耦）。
//  在 App 启动后通过 +start 注册到 SKPaymentQueue.defaultQueue，
//  即使未进入会员中心，也能接收并上报 App 上次被杀进程时遗留的未 finish 事务，
//  避免掉单。VC 内的支付流程仍由 VC 自己处理；这里只在 VC 未激活时兜底。
//
//  协调规则（避免与 MembershipCenterViewController 双重处理）：
//  - VC 在 viewDidLoad 调 setActive:YES，在 dealloc/viewWillDisappear 调 setActive:NO
//  - 当 VC 处于激活态：observer 不上报 Purchased 事务（由 VC 处理），
//    也不上报 Restored 事务（VC 内的「恢复购买」入口处理）
//  - 当 VC 未激活：observer 才上报兜底，并保存 pendingPlanId/redeemCode 上下文
//    （但兜底场景拿不到兑换码，所以只能用 planId=0 做幂等查询/激活）
//

#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PNIAPObserver : NSObject <SKPaymentTransactionObserver>

+ (instancetype)shared;

/// 启动事务观察。重复调用安全（内部判断已注册则跳过）。
/// 在用户已登录时调用；未登录时事务不会 finish 而是保留在队列里，
/// 下次登录后由 resumePendingTransactions 触发补单（防止已付款事务被永久丢失）。
- (void)start;

/// 停止观察（登出时调用）。
- (void)stop;

/// 标记「会员中心 VC 当前是否激活」。YES=VC 在前台，observer 不上报；
/// NO=VC 不存在或已退到后台，observer 接管兜底处理。
/// VC 应在 viewDidLoad/viewDidAppear 设 YES，viewWillDisappear/dealloc 设 NO。
- (void)setMembershipCenterActive:(BOOL)active;

/// 重新扫描 SKPaymentQueue 中残留的事务，触发 updatedTransactions 回调。
/// 用途：App 启动 / 进入会员中心时，对「上次未 finish 的事务」做兜底处理。
/// 实现为遍历 [queue transactions]，由于 transactions 已是 Purchased/Failed 等终态，
/// StoreKit 不会自动 re-deliver，需手动对每个事务调用回调。
- (void)resumePendingTransactions;

@end

NS_ASSUME_NONNULL_END
