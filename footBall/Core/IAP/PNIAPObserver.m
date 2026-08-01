//
//  PNIAPObserver.m
//  footBall
//

#import "PNIAPObserver.h"
#import "MembershipRequest.h"
#import "AuthManager.h"

@interface PNIAPObserver ()
@property (nonatomic, assign) BOOL started;
/// VC 正在处理的 transactionId 集合（避免重复上报/finish）
@property (nonatomic, strong) NSMutableSet<NSString *> *inFlightTxnIds;
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
        self.inFlightTxnIds = [NSMutableSet set];
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
    [self.inFlightTxnIds removeAllObjects];
}

- (void)markTransactionInFlightById:(NSString *)transactionId {
    if (transactionId.length == 0) return;
    @synchronized (self.inFlightTxnIds) {
        [self.inFlightTxnIds addObject:transactionId];
    }
}

- (void)clearTransactionInFlightById:(NSString *)transactionId {
    if (transactionId.length == 0) return;
    @synchronized (self.inFlightTxnIds) {
        [self.inFlightTxnIds removeObject:transactionId];
    }
}

- (BOOL)isInFlight:(NSString *)transactionId {
    if (transactionId.length == 0) return NO;
    @synchronized (self.inFlightTxnIds) {
        return [self.inFlightTxnIds containsObject:transactionId];
    }
}

#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    // 仅处理 VC 未在处理的事务（掉单恢复）；VC 已 inFlight 标记的跳过交给 VC 自己。
    BOOL loggedIn = [[AuthManager sharedManager] isLoggedIn];
    for (SKPaymentTransaction *txn in transactions) {
        // 只关心需要上报的状态
        if (txn.transactionState != SKPaymentTransactionStatePurchased
            && txn.transactionState != SKPaymentTransactionStateRestored) {
            continue;
        }
        NSString *txnId = txn.transactionIdentifier ?: @"";
        if ([self isInFlight:txnId]) continue;

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

    // planId 由 VC 在主动支付时设置；这里是兜底恢复场景，传 0 让服务端仅做幂等查询。
    NSDictionary *body = @{
        @"transactionId": transactionId,
        @"signedTransaction": receiptBase64,
        @"planId": @(0),
        @"agreementAccepted": @YES,
        @"restore": @(isRestore)
    };

    __weak typeof(self) weakSelf = self;
    [[MembershipRequest shared] verifyPurchaseWithBody:body success:^(HTTPResponse * _Nullable responseObject) {
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        NSLog(@"[IAP] 兜底事务上报成功: txnId=%@", transactionId);
        [weakSelf postMembershipChangedNotification];
    } failure:^(NSError * _Nonnull error) {
        // 上报失败：保留事务不 finish，下次 App 启动会再次尝试。
        // Apple 不会无限重投，但事务会保留在队列里直至 finish。
        NSLog(@"[IAP] 兜底事务上报失败（保留待重试）: txnId=%@ err=%@", transactionId, error);
    }];
}

- (void)postMembershipChangedNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PNMembershipDidChangeNotification" object:nil];
}

@end
