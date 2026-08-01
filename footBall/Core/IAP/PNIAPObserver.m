//
//  PNIAPObserver.m
//  footBall
//

#import "PNIAPObserver.h"
#import "MembershipRequest.h"
#import "AuthManager.h"

@interface PNIAPObserver ()
@property (nonatomic, assign) BOOL started;
/// 会员中心 VC 当前是否激活（激活时由 VC 处理，observer 不重复上报）
@property (nonatomic, assign, getter=isMembershipCenterActive) BOOL membershipCenterActive;
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

- (void)setMembershipCenterActive:(BOOL)active {
    self.membershipCenterActive = active;
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
            // 未登录：本地 finish 清空，避免队列堆积。
            // 未登录用户本来也不能购买，残留事务通常是退出登录前的状态。
            [[SKPaymentQueue defaultQueue] finishTransaction:txn];
            continue;
        }
        [self uploadTransaction:txn];
    }
}

- (void)uploadTransaction:(SKPaymentTransaction *)transaction {
    NSString *transactionId = transaction.transactionIdentifier ?: @"";
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData = receiptURL ? [NSData dataWithContentsOfURL:receiptURL] : nil;
    NSString *receiptBase64 = receiptData ? [receiptData base64EncodedStringWithOptions:0] : @"";
    BOOL isRestore = (transaction.transactionState == SKPaymentTransactionStateRestored);

    // 兜底场景拿不到 planId/redeemCode，传 0 让服务端做幂等查询。
    NSDictionary *body = @{
        @"transactionId": transactionId,
        @"signedTransaction": receiptBase64,
        @"planId": @(0),
        @"agreementAccepted": @YES,
        @"restore": @(isRestore)
    };

    [[MembershipRequest shared] verifyPurchaseWithBody:body success:^(HTTPResponse * _Nullable responseObject) {
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        NSLog(@"[IAP] 兜底事务上报成功: txnId=%@", transactionId);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PNMembershipDidChangeNotification" object:nil];
    } failure:^(NSError * _Nonnull error) {
        // 上报失败：保留事务不 finish，下次 App 启动 / 进入会员中心会再次尝试。
        NSLog(@"[IAP] 兜底事务上报失败（保留待重试）: txnId=%@ err=%@", transactionId, error);
    }];
}

@end
