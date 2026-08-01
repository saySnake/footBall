//
//  PNIAPObserver.h
//  footBall
//
//  全局 IAP 事务观察者（与具体 VC 解耦）。
//  在 App 启动后通过 +start 注册到 SKPaymentQueue.defaultQueue，
//  即使未进入会员中心，也能接收并上报 App 上次被杀进程时遗留的未 finish 事务，
//  避免掉单。VC 内的支付流程仍由 VC 自己处理；这里只在 VC 未拦截时兜底。
//

#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PNIAPObserver : NSObject <SKPaymentTransactionObserver>

+ (instancetype)shared;

/// 启动事务观察。重复调用安全（内部判断已注册则跳过）。
/// 仅在用户已登录时调用，否则不上报服务端，事务会被本地 finish 清空。
- (void)start;

/// 停止观察（登出时调用）。
- (void)stop;

/// 标记当前正在被会员中心 VC 处理的事务 ID，避免与 VC 重复 finish。
- (void)markTransactionInFlightById:(NSString *)transactionId;
/// 清除「VC 在处理」标记。
- (void)clearTransactionInFlightById:(NSString *)transactionId;

@end

NS_ASSUME_NONNULL_END
