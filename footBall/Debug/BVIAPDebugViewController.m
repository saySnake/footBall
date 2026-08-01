//
//  BVIAPDebugViewController.m
//  footBall
//
//  仅 DEBUG：IAP 调试面板实现。
//

#ifdef DEBUG

#import "BVIAPDebugViewController.h"
#import "MembershipRequest.h"
#import "MembershipModels.h"
#import "PNIAPObserver.h"
#import "AuthManager.h"
#import "APIError.h"
#import <StoreKit/StoreKit.h>
#import <Masonry/Masonry.h>
#import <MBProgressHUD/MBProgressHUD.h>

// 前向声明：cell 在 item 之后定义，但 tableView 数据源需要引用
@class BVDebugActionCell;

#pragma mark - Section / Item model

@interface BVDebugItem : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *desc;
@property (nonatomic, copy) void (^action)(void);
@end
@implementation BVDebugItem
@end

@interface BVDebugSection : NSObject
@property (nonatomic, copy) NSString *header;
@property (nonatomic, strong) NSArray<BVDebugItem *> *items;
@end
@implementation BVDebugSection
@end


#pragma mark - Action Cell

@interface BVDebugActionCell : UITableViewCell
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descLabel;
- (void)configureWithItem:(BVDebugItem *)item;
@end

@implementation BVDebugActionCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.13 green:0.13 blue:0.15 alpha:1.0];
        self.contentView.backgroundColor = self.backgroundColor;

        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.numberOfLines = 0;
        [self.contentView addSubview:_titleLabel];

        _descLabel = [UILabel new];
        _descLabel.font = [UIFont systemFontOfSize:11];
        _descLabel.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
        _descLabel.numberOfLines = 0;
        [self.contentView addSubview:_descLabel];

        [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.equalTo(self.contentView).insets(UIEdgeInsetsMake(10, 14, 0, 14));
        }];
        [_descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.titleLabel.mas_bottom).offset(4);
            make.left.right.bottom.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 14, 10, 14));
        }];
    }
    return self;
}

- (void)configureWithItem:(BVDebugItem *)item {
    self.titleLabel.text = item.title;
    self.descLabel.text = item.desc;
}

@end


@interface BVIAPDebugViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<BVDebugSection *> *sections;
@property (nonatomic, strong) UITextView *logView;
@property (nonatomic, strong) NSMutableArray<NSString *> *logs;
@end

@implementation BVIAPDebugViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"IAP 调试面板";
    self.view.backgroundColor = [UIColor colorWithRed:0.10 green:0.10 blue:0.12 alpha:1.0];

    self.logs = [NSMutableArray array];
    [self buildSections];

    [self setupUI];
    [self logLine:@"面板已加载。所有操作仅影响当前 DEBUG 构建。"];
    [self logLine:[NSString stringWithFormat:@"登录态: %@", [AuthManager sharedManager].isLoggedIn ? @"已登录" : @"未登录"]];
}

- (void)setupUI {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [UIColor colorWithRed:0.10 green:0.10 blue:0.12 alpha:1.0];
    self.tableView.separatorColor = [UIColor colorWithWhite:1 alpha:0.08];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 80;
    [self.tableView registerClass:[BVDebugActionCell class] forCellReuseIdentifier:@"cell"];
    [self.view addSubview:self.tableView];

    self.logView = [[UITextView alloc] init];
    self.logView.editable = NO;
    self.logView.selectable = YES;
    self.logView.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.06 alpha:1.0];
    self.logView.textColor = [UIColor colorWithRed:0.70 green:0.95 blue:0.75 alpha:1.0];
    self.logView.font = [UIFont fontWithName:@"Menlo" size:10];
    self.logView.alwaysBounceVertical = YES;

    [self.view addSubview:self.logView];

    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.height.mas_equalTo(self.view.bounds.size.height * 0.55);
    }];
    [self.logView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tableView.mas_bottom).offset(4);
        make.left.right.bottom.equalTo(self.view);
    }];

    UIButton *clearBtn = [UIButton new];
    [clearBtn setTitle:@"清除日志" forState:UIControlStateNormal];
    [clearBtn setTitleColor:[UIColor colorWithRed:0.4 green:0.7 blue:1 alpha:1] forState:UIControlStateNormal];
    clearBtn.titleLabel.font = [UIFont systemFontOfSize:11];
    [clearBtn addTarget:self action:@selector(onClearLogs) forControlEvents:UIControlEventTouchUpInside];
    [self.logView addSubview:clearBtn];
    [clearBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.right.equalTo(self.logView).insets(UIEdgeInsetsMake(4, 0, 0, 8));
    }];
}

#pragma mark - Sections

- (void)buildSections {
    NSMutableArray<BVDebugSection *> *arr = [NSMutableArray array];

    // ===== 1. 环境 / 状态 =====
    BVDebugItem *iEnv = [self itemWithTitle:@"查看当前 IAP 环境"
                                         desc:@"登录态、收据文件、沙箱/生产、队列残留事务数"
                                        action:^{
        [self dumpEnvironment];
    }];

    BVDebugItem *iScan = [self itemWithTitle:@"扫描队列残留事务 (resumePendingTransactions)"
                                         desc:@"模拟 App 启动时进入会员中心，触发 PNIAPObserver 兜底"
                                        action:^{
        [[PNIAPObserver shared] resumePendingTransactions];
        [self logLine:@"已调用 resumePendingTransactions。观察日志输出。"];
    }];

    [arr addObject:({
        BVDebugSection *s = [BVDebugSection new];
        s.header = @"① 环境 / 掉单恢复";
        s.items = @[iEnv, iScan];
        s;
    })];

    // ===== 2. verifyPurchase 上报分支 =====
    BVDebugItem *iVerifyOk = [self itemWithTitle:@"verifyPurchase 上报成功（伪造 txnId）"
                                              desc:@"用假 transactionId 调 /purchase；预期服务端返回成功或幂等命中"
                                             action:^{
        [self postVerifyWithFakeTxnId:@"DEBUG_FAKE_OK_0001" planId:@"1" redeem:nil restore:NO];
    }];

    BVDebugItem *iVerifyFail = [self itemWithTitle:@"verifyPurchase 上报失败（无效 txnId）"
                                                desc:@"用空/无效 txnId 调 /purchase；预期 4xx，看 UI/日志降级"
                                               action:^{
        [self postVerifyWithFakeTxnId:@"DEBUG_INVALID_FAIL" planId:@"1" redeem:nil restore:NO];
    }];

    BVDebugItem *iVerifyRestore = [self itemWithTitle:@"verifyPurchase 上报（restore=YES）"
                                                   desc:@"模拟恢复购买单笔事务上报；planId=0"
                                                  action:^{
        [self postVerifyWithFakeTxnId:@"DEBUG_RESTORE_0001" planId:@"0" redeem:nil restore:YES];
    }];

    [arr addObject:({
        BVDebugSection *s = [BVDebugSection new];
        s.header = @"② 服务端验证 /purchase（直接调用，不走 Apple 支付）";
        s.items = @[iVerifyOk, iVerifyFail, iVerifyRestore];
        s;
    })];

    // ===== 3. 兑换码 =====
    BVDebugItem *iRedeemFree = [self itemWithTitle:@"兑换码 redeem（免费码预期）"
                                                desc:@"调 /redeem 期望 needPayment=NO 直接激活"
                                               action:^{
        [self postRedeemWithCode:@"DEBUG_FREE"];
    }];

    BVDebugItem *iRedeemPaid = [self itemWithTitle:@"兑换码 redeem（付费码预期）"
                                                desc:@"调 /redeem 期望 needPayment=YES 返回 appleProductId"
                                               action:^{
        [self postRedeemWithCode:@"DEBUG_PAID"];
    }];

    BVDebugItem *iRedeemInvalid = [self itemWithTitle:@"兑换码 redeem（无效码）"
                                                   desc:@"用乱码调 /redeem，预期失败，验证降级文案"
                                                  action:^{
        [self postRedeemWithCode:@"XXXX_INVALID_XXXX"];
    }];

    [arr addObject:({
        BVDebugSection *s = [BVDebugSection new];
        s.header = @"③ 兑换码 /redeem";
        s.items = @[iRedeemFree, iRedeemPaid, iRedeemInvalid];
        s;
    })];

    // ===== 4. 会员状态 =====
    BVDebugItem *iStatus = [self itemWithTitle:@"拉取会员状态 /membership/status"
                                            desc:@"看当前用户是否已是会员、级别、到期时间"
                                           action:^{
        [self fetchMembershipStatus];
    }];

    [arr addObject:({
        BVDebugSection *s = [BVDebugSection new];
        s.header = @"④ 会员状态";
        s.items = @[iStatus];
        s;
    })];

    // ===== 5. 真实操作（需 SandboxTester） =====
    BVDebugItem *iRestore = [self itemWithTitle:@"触发「恢复购买」(restoreCompletedTransactions)"
                                             desc:@"与会员中心点「恢复购买」等价；需当前 App 处于已购 Apple ID"
                                            action:^{
        [self triggerRestore];
    }];

    BVDebugItem *iCanPay = [self itemWithTitle:@"检查 canMakePayments"
                                            desc:@"YES=允许 IAP；NO=设备禁用（家长控制）"
                                           action:^{
        BOOL ok = [SKPaymentQueue canMakePayments];
        [self logLine:[NSString stringWithFormat:@"canMakePayments = %@", ok ? @"YES ✅" : @"NO ❌ (检查家长控制)"]];
    }];

    [arr addObject:({
        BVDebugSection *s = [BVDebugSection new];
        s.header = @"⑤ 真实 Apple 操作（需 SandboxTester 登录）";
        s.items = @[iRestore, iCanPay];
        s;
    })];

    // ===== 6. 操作指引 =====
    BVDebugItem *iGuide = [self itemWithTitle:@"查看完整测试场景文档"
                                           desc:@"打开 docs/IAP审核测试场景.md（80+ 场景）"
                                          action:^{
        [self showGuide];
    }];

    [arr addObject:({
        BVDebugSection *s = [BVDebugSection new];
        s.header = @"⑥ 文档";
        s.items = @[iGuide];
        s;
    })];

    self.sections = [arr copy];
}

- (BVDebugItem *)itemWithTitle:(NSString *)title desc:(NSString *)desc action:(void(^)(void))action {
    BVDebugItem *it = [BVDebugItem new];
    it.title = title;
    it.desc = desc;
    it.action = action;
    return it;
}

#pragma mark - Actions

- (void)dumpEnvironment {
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSString *receiptName = receiptURL.lastPathComponent ?: @"<nil>";
    BOOL isSandbox = [receiptName isEqualToString:@"sandboxReceipt"];
    NSData *rd = receiptURL ? [NSData dataWithContentsOfURL:receiptURL] : nil;
    BOOL hasReceipt = rd.length > 0;

    NSUInteger pending = [[SKPaymentQueue defaultQueue] transactions].count;
    BOOL loggedIn = [AuthManager sharedManager].isLoggedIn;

    [self logLine:@"==== IAP 环境 ===="];
    [self logLine:[NSString stringWithFormat:@"登录态       : %@", loggedIn ? @"已登录" : @"未登录"]];
    [self logLine:[NSString stringWithFormat:@"收据文件     : %@ (%@)", receiptName, isSandbox ? @"沙箱 Sandbox" : @"生产 Production"]];
    [self logLine:[NSString stringWithFormat:@"收据是否存在 : %@ (%lu bytes)", hasReceipt ? @"YES" : @"NO ❌(首次安装/重装会触发 SKReceiptRefreshRequest)", (unsigned long)rd.length]];
    [self logLine:[NSString stringWithFormat:@"队列残留事务 : %lu 笔", (unsigned long)pending]];
    [self logLine:[NSString stringWithFormat:@"canMakePayments : %@", [SKPaymentQueue canMakePayments] ? @"YES" : @"NO"]];
}

- (void)postVerifyWithFakeTxnId:(NSString *)txnId planId:(NSString *)planId redeem:(nullable NSString *)redeem restore:(BOOL)restore {
    [self logLine:[NSString stringWithFormat:@"→ verifyPurchase txnId=%@ planId=%@ restore=%d", txnId, planId, restore]];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    __weak typeof(self) weakSelf = self;
    NSMutableDictionary *body = [@{
        @"transactionId": txnId,
        @"signedTransaction": @"DEBUG_FAKE_RECEUT_BASE64",
        @"planId": planId,
        @"agreementAccepted": @YES,
        @"restore": @(restore)
    } mutableCopy];
    if (redeem.length > 0) body[@"redeemCode"] = redeem;

    [[MembershipRequest shared] verifyPurchaseWithBody:body success:^(HTTPResponse * _Nullable responseObject) {
        [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
        id data = responseObject.dataObject ?: responseObject.data;
        PNMembership *m = [PNMembership yy_modelWithJSON:data];
        [weakSelf logLine:[NSString stringWithFormat:@"✅ 成功: errCode=%@ errMsg=%@", responseObject.errorCode ?: @"-", responseObject.errorMessage ?: @""]];
        [weakSelf logLine:[NSString stringWithFormat:@"   levelName=%@ expireTime=%@", m.levelName ?: @"-", m.expireTime ?: @"-"]];
    } failure:^(NSError * _Nonnull error) {
        [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
        NSString *msg = [error.localizedDescription ?: @"<no desc>" copy];
        if ([error isKindOfClass:[APIError class]]) {
            msg = [(APIError *)error displayMessageWithFallback:msg];
        }
        [weakSelf logLine:[NSString stringWithFormat:@"❌ 失败: code=%ld msg=%@", (long)error.code, msg]];
    }];
}

- (void)postRedeemWithCode:(NSString *)code {
    [self logLine:[NSString stringWithFormat:@"→ redeem code=%@", code]];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    __weak typeof(self) weakSelf = self;
    [[MembershipRequest shared] redeemCodeWithBody:@{@"code": code} success:^(HTTPResponse * _Nullable responseObject) {
        [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
        id raw = responseObject.dataObject ?: responseObject.data;
        PNRedeemResult *r = [PNRedeemResult yy_modelWithJSON:raw];
        [weakSelf logLine:[NSString stringWithFormat:@"✅ 兑换成功: codeType=%@ needPayment=%@ appleProductId=%@ planId=%@ days=%ld",
                            r.codeType ?: @"-", r.needPayment ? @"YES" : @"NO", r.appleProductId ?: @"-",
                            r.planId ?: @"-", (long)r.durationDays]];
    } failure:^(NSError * _Nonnull error) {
        [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
        NSString *msg = error.localizedDescription ?: @"<no desc>";
        if ([error isKindOfClass:[APIError class]]) {
            msg = [(APIError *)error displayMessageWithFallback:msg];
        }
        [weakSelf logLine:[NSString stringWithFormat:@"❌ 兑换失败: code=%ld msg=%@", (long)error.code, msg]];
    }];
}

- (void)fetchMembershipStatus {
    [self logLine:@"→ GET /membership/status"];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    __weak typeof(self) weakSelf = self;
    [[MembershipRequest shared] getMembershipStatusSuccess:^(HTTPResponse * _Nullable responseObject) {
        [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
        id raw = responseObject.dataObject ?: responseObject.data;
        PNMembershipStatus *s = [PNMembershipStatus yy_modelWithJSON:raw];
        [weakSelf logLine:[NSString stringWithFormat:@"✅ isMember=%@ levelName=%@ expireTime=%@ nearExpiry=%d",
                            s.isMember ? @"YES" : @"NO", s.levelName ?: @"-", s.expireTime ?: @"-", s.nearExpiry]];
    } failure:^(NSError * _Nonnull error) {
        [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
        [weakSelf logLine:[NSString stringWithFormat:@"❌ 失败: %@", error.localizedDescription ?: @"<no desc>"]];
    }];
}

- (void)triggerRestore {
    [self logLine:@"→ restoreCompletedTransactions (异步)"];
    [self logLine:@"注意：这会触发 Apple 重新投递历史事务到 updatedTransactions。"];
    [self logLine:@"若 App 当前不在会员中心 VC，PNIAPObserver 会接管上报。"];
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void)showGuide {
    NSString *path = @"/Users/zhangwei/Desktop/footBall/docs/IAP审核测试场景.md";
    NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil] ?: @"(读不到文档，请检查路径)";
    UITextView *tv = [[UITextView alloc] init];
    tv.editable = NO;
    tv.text = content;
    tv.font = [UIFont fontWithName:@"Menlo" size:11];
    tv.backgroundColor = [UIColor whiteColor];
    UIViewController *vc = [UIViewController new];
    vc.view = tv;
    vc.title = @"IAP 审核测试场景";
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Log

- (void)logLine:(NSString *)line {
    NSString *ts = [NSDateFormatter localizedStringFromDate:[NSDate date]
                                                  dateStyle:NSDateFormatterNoStyle
                                                  timeStyle:NSDateFormatterMediumStyle];
    NSString *entry = [NSString stringWithFormat:@"[%@] %@", ts, line];
    [self.logs addObject:entry];
    self.logView.text = [self.logs componentsJoinedByString:@"\n"];
    // 滚到底
    NSRange range = NSMakeRange(self.logView.text.length - 1, 1);
    [self.logView scrollRangeToVisible:range];
    NSLog(@"[IAP-DEBUG] %@", line);
}

- (void)onClearLogs {
    [self.logs removeAllObjects];
    self.logView.text = @"";
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return self.sections.count; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.sections[section].items.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sections[section].header;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BVDebugActionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    BVDebugItem *item = self.sections[indexPath.section].items[indexPath.row];
    [cell configureWithItem:item];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    BVDebugItem *item = self.sections[indexPath.section].items[indexPath.row];
    if (item.action) item.action();
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *hv = (UITableViewHeaderFooterView *)view;
        hv.textLabel.textColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
        hv.textLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
        hv.contentView.backgroundColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.17 alpha:1.0];
    }
}

@end


#endif
