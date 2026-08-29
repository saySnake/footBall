//
//  PNIAPSK2Bridge.h
//  footBall
//
//  StoreKit 2 桥接到 OC 的接口声明。
//  实现在 PNIAPSK2Bridge.swift（Swift-only API: Transaction / verifyTransaction）。
//
//  iOS 15+ 才支持 SK2，调用方必须先检查 +isAvailable：
//      if ([PNIAPSK2Bridge isAvailable]) { ... }
//  iOS 13/14 走原有 SK1 路径（SKPaymentQueue + appStoreReceiptURL base64）。
//
//  注意：PNIAPSK2Bridge 与 PNIAPSK2Result 的实现位于 PNIAPSK2Bridge.swift，
//  通过 @objc(name) 暴露给 OC，此头文件仅作前向声明。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 单笔交易的 SK2 验证结果。
/// 实际实现在 Swift 端（@objc(PNIAPSK2Result)），OC 端使用此名字引用即可。
@interface PNIAPSK2Result : NSObject
- (instancetype)initWithTransactionId:(NSString *)transactionId
                     jwsRepresentation:(NSString *)jwsRepresentation
                            isRestore:(BOOL)isRestore;
@property (nonatomic, copy, readonly) NSString *transactionId;
@property (nonatomic, copy, readonly) NSString *jwsRepresentation;
@property (nonatomic, assign, readonly) BOOL isRestore;
/// StoreKit 2 productId（用于客户端反查 planId）
@property (nonatomic, copy, readonly) NSString *productId;
@end

@interface PNIAPSK2Bridge : NSObject

/// 当前进程是否支持 StoreKit 2（iOS 15.0+）。运行时判断，iOS 13/14 返回 NO。
+ (BOOL)isAvailable;

/// 获取已购买、尚未 finish 的当前事务的 JWS 表示。
/// 调用场景：客户端在 SK1 paymentQueue:updatedTransactions: 收到 Purchased 状态后，
/// 先尝试用此方法拿 SK2 的 JWS 上报（更安全，可直接被服务端验签）。
///
/// @param transactionId SK1 的 transactionIdentifier（用于在 SK2 currentEntitlements 中匹配）
/// @param completion 主线程回调，result 为 nil 表示匹配失败（应回退到 SK1 收据路径）
+ (void)currentJWSForTransactionId:(NSString *)transactionId
                        completion:(void (^)(PNIAPSK2Result * _Nullable result))completion;

/// 枚举当前有效权益（订阅/非消耗型），每笔带真正的 JWS。
/// 用于「已订阅但 SK1 restore 0 笔」时的补激活（验证失败后 finish 过的场景）。
+ (void)enumerateCurrentEntitlements:(void (^)(NSArray<PNIAPSK2Result *> *results))completion;

/// 主动 finish 当前 SK2 事务（与 SK1 finishTransaction 等价）。
/// 注意：SK1 和 SK2 共享同一个 payment queue，SK1 已经 finish 的事务无需再调用此方法。
/// 此方法仅用于"由 SK2 路径发起购买、需要 SK2 finish"的场景。
+ (void)finishTransactionById:(NSString *)transactionId;

@end

NS_ASSUME_NONNULL_END
