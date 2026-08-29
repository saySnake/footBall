//
//  PNIAPObserver.m
//  footBall
//

#import "PNIAPObserver.h"
#import "MembershipRequest.h"
#import "AuthManager.h"
#import "PNIAPSK2Bridge.h"

@interface PNIAPObserver ()
@property (nonatomic, assign) BOOL started;
/// 会员中心 VC 当前是否激活（激活时由 VC 处理，observer 不重复上报）
@property (nonatomic, assign, getter=isMembershipCenterActive) BOOL membershipCenterActive;
/// SK1 整本收据 base64（兜底路径用）
- (NSString *)sk1ReceiptBase64;
@end

@implementation PNIAPObserver

+ (instancetype)shared {
    static PNIAPObserver *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PNIAPObserver alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _membershipCenterActive = NO;
    }
    return self;
}

- (void)start {
    if (self.started) return;
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    self.started = YES;
}

- (void)stop {
    if (!self.started) return;
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    self.started = NO;
}

/// 主动扫描队列中残留事务（App 启动 / 进入会员中心场景），
/// 把它们再次交给 updatedTransactions 回调路径处理。
- (void)resumePendingTransactions {
    if (!self.started) return;
    NSArray<SKPaymentTransaction *> *pending = [[SKPaymentQueue defaultQueue] transactions];
    if (pending.count == 0) return;
    NSLog(@"[IAP] resumePendingTransactions: 发现 %lu 笔残留事务", (unsigned long)pending.count);
    // 直接走我们自己的处理逻辑（不调用 [self paymentQueue:updatedTransactions:]，因为那是协议方法）
    [self handleTransactions:pending];
}

#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    [self handleTransactions:transactions];
}

/// 统一处理入口（updatedTransactions 回调与 resumePendingTransactions 共用）
- (void)handleTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    BOOL loggedIn = [[AuthManager sharedManager] isLoggedIn];

    for (SKPaymentTransaction *txn in transactions) {
        // 只关心 Purchased / Restored；Purchasing/Failed/Deferred 不上报
        if (txn.transactionState != SKPaymentTransactionStatePurchased
            && txn.transactionState != SKPaymentTransactionStateRestored) {
            continue;
        }

        // 关键：会员中心 VC 激活时，由 VC 处理（避免双重 finish / 双重 verifyPurchase 请求）
        if (self.isMembershipCenterActive) {
            continue;
        }

        if (!loggedIn) {
            // 关键：已付款事务（Purchased/Restored）绝不能在未登录时 finish！
            // 触发场景：用户在登录页发起购买、付款成功后但还没登录成功（验证码还在输入），
            // 或者购买成功后用户立即 logout。一旦 finish，Apple 不再 re-deliver，
            // 用户付了钱拿不到会员、客服也无法对账。
            // 正确策略：保留事务在队列里，下次启动 SceneDelegate 已登录分支会调用
            // resumePendingTransactions，把这笔事务重新交给 verifyPurchase 流程处理。
            NSLog(@"[IAP][重要] 未登录但收到已付款事务，保留在队列等待登录后补单: txnId=%@ state=%ld",
                  txn.transactionIdentifier ?: @"-", (long)txn.transactionState);
            continue;
        }
        [self uploadTransaction:txn];
    }
}

- (void)uploadTransaction:(SKPaymentTransaction *)transaction {
    NSString *transactionId = transaction.transactionIdentifier ?: @"";

    // 兜底场景拿不到 planId/redeemCode：必须 restore=true + planId=0，
    // 让服务端按 Apple productId 幂等查询/补激活。
    // 若 restore=false 且 planId=0，会走「普通购买」分支查方案失败。
    NSDictionary *baseBody = @{
        @"transactionId": transactionId,
        @"planId": @(0),
        @"agreementAccepted": @NO,
        @"restore": @YES
    };

    void (^submitWithBody)(NSDictionary *) = ^(NSDictionary *extra) {
        NSMutableDictionary *body = [baseBody mutableCopy];
        if (extra) [body addEntriesFromDictionary:extra];
        [[MembershipRequest shared] verifyPurchaseWithBody:body success:^(HTTPResponse * _Nullable responseObject) {
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            NSLog(@"[IAP] 兜底事务上报成功: txnId=%@", transactionId);
            [[NSNotificationCenter defaultCenter] postNotificationName:@"PNMembershipDidChangeNotification" object:nil];
        } failure:^(NSError * _Nonnull error) {
            // 上报失败：仍 finish 事务防止队列堆积（堆积超 Apple 阈值后 StoreKit 拒绝新支付）。
            // 详细日志保留供客服对账兜底；用户下次进入会员中心可手动重试 restore。
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            NSLog(@"[IAP][严重] 兜底事务上报失败已 finish，请人工对账: txnId=%@, err=%@", transactionId, error);
        }];
    };

    // iOS 15+: 优先用 SK2 JWS 上报（与服务端 verifyViaJws 路径匹配，不依赖 .p8 配置）。
    // iOS 13/14 或 SK2 未命中：退回 SK1 整本收据 base64。
    if ([PNIAPSK2Bridge isAvailable] && transactionId.length > 0) {
        [PNIAPSK2Bridge currentJWSForTransactionId:transactionId completion:^(PNIAPSK2Result * _Nullable result) {
            NSString *jws = result.jwsRepresentation ?: @"";
            NSUInteger dotCount = [[jws componentsSeparatedByString:@"."] count];
            NSString *signedTxn = (jws.length > 0 && dotCount >= 3)
                ? jws
                : [self sk1ReceiptBase64];
            submitWithBody(@{ @"signedTransaction": signedTxn ?: @"" });
        }];
    } else {
        submitWithBody(@{ @"signedTransaction": [self sk1ReceiptBase64] });
    }
}

/// SK1 整本收据 base64（兜底路径，iOS 13/14 或 SK2 未命中时使用）
- (NSString *)sk1ReceiptBase64 {
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData = receiptURL ? [NSData dataWithContentsOfURL:receiptURL] : nil;
    return receiptData ? [receiptData base64EncodedStringWithOptions:0] : @"";
}

@end
