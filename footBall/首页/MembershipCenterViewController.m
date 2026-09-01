//
//  MembershipCenterViewController.m
//  footBall
//

#import "MembershipCenterViewController.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>
#import <math.h>
#import <StoreKit/StoreKit.h>
#import <SafariServices/SafariServices.h>
#import "AuthManager.h"
#import "FontManager.h"
#import "MembershipRequest.h"
#import "MembershipModels.h"
#import "LoadingManager.h"
#import "APIError.h"
#import "PNIAPObserver.h"
#import "PNIAPSK2Bridge.h"
#import "LegalDocumentViewController.h"
#import "LegalDocumentCache.h"
#import <MBProgressHUD/MBProgressHUD.h>

#define kMCPageBg [UIColor colorWithRed:13/255.0 green:33/255.0 blue:34/255.0 alpha:1.0]
#define kMCMint [UIColor colorWithRed:83/255.0 green:204/255.0 blue:158/255.0 alpha:1.0]
#define kMCMintBorder [UIColor colorWithRed:175/255.0 green:255/255.0 blue:224/255.0 alpha:0.90]
#define kMCDiscountMint [UIColor colorWithRed:175/255.0 green:255/255.0 blue:224/255.0 alpha:1.0]
#define kMCDiscountHintGray [UIColor colorWithRed:203/255.0 green:203/255.0 blue:203/255.0 alpha:1.0]

/// 订阅 / 隐私政策跳转（App Store 审核要求自动续期订阅必须在购买页面提供可点击的条款链接）。
/// 协议/续期条款使用 https 占位链接触发 UITextView 链接回调，在应用内展示 Bundle 文案（勿用自定义 scheme，会被系统路由误处理）。
static NSString *const kMCPrivacyPolicyURL       = @"https://www.nomadfootball.cn/privacy/";
static NSString *const kMCMembershipAgreementURL = @"https://www.nomadfootball.cn/legal/membership";
static NSString *const kMCAutoRenewTermsURL      = @"https://www.nomadfootball.cn/legal/auto-renew";

@interface MCPlan : NSObject
/// 服务端方案 ID（1=月 2=年 3=永久 4=创始人），用于折扣码定位，不随 title 文案变化
@property (nonatomic, copy) NSString *planId;
@property (nonatomic, copy) NSString *title;
/// 卡片大号展示价（如 33）
@property (nonatomic, copy) NSString *price;
/// 底部按钮展示价（稿内常与卡片价不同，如首屏 ¥22）
@property (nonatomic, copy) NSString *payPrice;
/// SKProduct 本地化完整价格（含货币符号，审核要求展示价=Apple 扣款价）
@property (nonatomic, copy) NSString *localizedPrice;
/// 货币符号（卡片 UI 小字号展示，数字部分用大字号）
@property (nonatomic, copy) NSString *currencySymbol;
/// 折扣前 SKProduct 本地化价格
@property (nonatomic, copy) NSString *localizedOriginalPrice;
/// 折扣前展示价（如 33/268/748）
@property (nonatomic, copy) NSString *originalPrice;
@property (nonatomic, copy) NSString *hint;
@property (nonatomic, strong) NSArray<NSString *> *benefits;
/// SF Symbol 名，与 benefits 一一对应
@property (nonatomic, strong) NSArray<NSString *> *benefitIcons;
@end
@implementation MCPlan @end

@interface MembershipCenterViewController () <UIScrollViewDelegate, SKProductsRequestDelegate, SKPaymentTransactionObserver>
@property (nonatomic, strong) UIView *navBar;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) UIButton *helpBtn;

@property (nonatomic, strong) UIView *avatarWrap;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *nameLabel;

@property (nonatomic, strong) UIControl *bannerCard;
@property (nonatomic, strong) UILabel *bannerTitleLabel;
@property (nonatomic, strong) UILabel *bannerSubLabel;
@property (nonatomic, strong) UILabel *bannerHintLabel;
@property (nonatomic, strong) UIButton *redeemBtn;

@property (nonatomic, strong) UIView *segmentWrap;
@property (nonatomic, strong) UIButton *subscribeTabBtn;
@property (nonatomic, strong) UIButton *giftTabBtn;
@property (nonatomic, strong) UIView *contentPanelView;
@property (nonatomic, strong) UIVisualEffectView *contentGlassView;
@property (nonatomic, strong) CAGradientLayer *contentGlassHighlightLayer;

@property (nonatomic, strong) CAGradientLayer *bannerGradientLayer;
@property (nonatomic, strong) UILabel *planTitleLabel;
@property (nonatomic, strong) UIScrollView *cardScrollView;
@property (nonatomic, strong) UIView *cardContentView;
@property (nonatomic, strong) NSArray<UIView *> *cardViews;
@property (nonatomic, strong) UIPageControl *pageControl;

@property (nonatomic, strong) UIButton *payBtn;
@property (nonatomic, strong) UIButton *agreementCheckBtn;
@property (nonatomic, strong) UITextView *agreementLabel;
/// 恢复购买按钮（Apple 审核要求：非消耗型/订阅类应用必须提供 Restore 入口）
@property (nonatomic, strong) UIButton *restoreBtn;
/// 订阅关键信息标签（Apple 审核指南 3.1.2 要求在购买按钮附近明示续期频率、价格周期、取消方式）
@property (nonatomic, strong) UILabel *subscriptionInfoLabel;

@property (nonatomic, strong) UIView *redeemOverlayView;
@property (nonatomic, strong) UIView *redeemDialogView;
@property (nonatomic, strong) CAGradientLayer *redeemDialogGradientLayer;
@property (nonatomic, strong) UIButton *redeemCloseIconBtn;
@property (nonatomic, strong) UILabel *redeemDialogTitleLabel;
@property (nonatomic, strong) UIImageView *redeemDialogTicketIconView;
@property (nonatomic, strong) UIView *redeemInputWrapView;
@property (nonatomic, strong) UITextField *redeemInputField;
@property (nonatomic, strong) UIButton *redeemConfirmBtn;
@property (nonatomic, strong) UILabel *redeemHelpLabel;
@property (nonatomic, strong) UIView *redeemSuccessWrapView;
@property (nonatomic, strong) UILabel *redeemSuccessTitleLabel;
@property (nonatomic, strong) UILabel *redeemSuccessDescLabel;

@property (nonatomic, strong) UIView *giftContainerView;
@property (nonatomic, strong) UILabel *giftPromptLabel;
@property (nonatomic, strong) UIButton *giftCodeTapAreaBtn;
@property (nonatomic, strong) NSArray<UIView *> *giftDigitBoxes;
@property (nonatomic, strong) NSArray<UILabel *> *giftDigitLabels;
@property (nonatomic, strong) UITextField *giftHiddenInput;
@property (nonatomic, strong) UIButton *giftRedeemBtn;
@property (nonatomic, strong) UIView *giftSuccessWrap;
@property (nonatomic, strong) UILabel *giftSuccessLabel;
@property (nonatomic, assign) BOOL showingGiftCode;

@property (nonatomic, strong) NSArray<MCPlan *> *plans;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, assign) BOOL redeemDialogShowingSuccess;
@property (nonatomic, assign) BOOL hasAppliedRedeemDiscount;
/// 兑换码/付费邀请码成功后，服务端返回的折扣商品 ID 和方案 ID
@property (nonatomic, copy) NSString *redeemAppleProductId;
@property (nonatomic, copy) NSString *redeemPlanId;
/// 待随 IAP /purchase 上报的兑换码（EXCHANGE_CODE / INVITE_CODE）
@property (nonatomic, copy) NSString *pendingRedeemCode;
/// 兑换接口返回的划线价/折扣价（SKProduct 未拉到时的展示兜底）
@property (nonatomic, copy) NSString *redeemOriginalPrice;
@property (nonatomic, copy) NSString *redeemDiscountPrice;
/// 服务端返回的方案列表，用于获取 appleProductId 和 planId
@property (nonatomic, strong) NSArray<PNMemberPlan *> *apiPlans;
/// 当前会员状态
@property (nonatomic, strong) PNMembershipStatus *membershipStatus;
/// IAP：当前正在请求的 SKProductsRequest（购买链路）
@property (nonatomic, strong) SKProductsRequest *productsRequest;
/// IAP：预拉取全部方案价格（展示价必须来自 SKProduct，防审核拒 展示价≠扣款价）
@property (nonatomic, strong) SKProductsRequest *preloadProductsRequest;
/// IAP：从 App Store 拉取到的产品列表（productIdentifier → SKProduct）
@property (nonatomic, strong) NSMutableDictionary<NSString *, SKProduct *> *skProducts;
/// IAP：当前正在购买的 planId（用于购买成功后上报服务端）
@property (nonatomic, copy) NSString *pendingPlanId;
/// 支付/拉商品进行中，防连点导致 HUD 叠层卡死
@property (nonatomic, assign) BOOL payInFlight;
/// restore 流程相关状态（多笔事务场景下控制 HUD 与提示）
@property (nonatomic, assign) BOOL restoreInFlight;       // restore 调用进行中，防连点
@property (nonatomic, assign) NSInteger restoreTotalCount;     // 本次 restore 接收到的事务总数
@property (nonatomic, assign) NSInteger restoreProcessedCount; // 已处理完成（success/failure）的事务数
@property (nonatomic, assign) NSInteger restoreSuccessCount;   // 其中服务端识别为有效（success）的事务数
/// 最近一次 restore 上报失败的文案（用于替代笼统的「暂无可恢复」）
@property (nonatomic, copy) NSString *lastRestoreErrorMessage;
/// 本 VC 生命周期内是否已触发过收据刷新（避免同一界面内重复刷新，
/// 但允许下次重新进入会员中心再尝试一次，比 App 级 dispatch_once 更友好）
@property (nonatomic, assign) BOOL receiptRefreshTriggered;
/// loadRemoteData 防抖：购买成功 / restore 完成 / viewWillAppear 等多处都调用，
/// 没有标志位会同时触发 2-3 次并发请求（plans + status），浪费网络 + UI 闪烁。
/// 进行中时普通调用会标记 pending；兑换/支付成功等关键路径用 force 立即刷新。
@property (nonatomic, assign) BOOL loadingRemoteData;
@property (nonatomic, assign) BOOL pendingRemoteDataReload;
@end

@implementation MembershipCenterViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void)viewDidLoad {
    // QMBaseViewController.viewDidLoad 会调用 setupUI / updateTheme。
    // 必须在 [super viewDidLoad] 之前准备好 plans，且此处不能再调 setupUI，
    // 否则 banner / tab 会被创建两份叠在一起（文案看起来「出现两次」）。
    self.initialPlanIndex = MAX(0, MIN(self.initialPlanIndex, 3));
    self.currentIndex = self.initialPlanIndex;
    self.skProducts = [NSMutableDictionary dictionary];
    [self buildPlanData];

    [super viewDidLoad];

    self.hidesBottomBarWhenPushed = YES;
    self.shouldShowNavigationBar = NO;
    self.view.backgroundColor = kMCPageBg;
    [self refreshUserProfile];
    [self loadRemoteData];
    // 注册 StoreKit 支付队列观察者
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    // 告知全局观察者：本 VC 已激活，事务由 VC 处理（避免双重上报/finish）
    [[PNIAPObserver shared] setMembershipCenterActive:YES];
    // 进入会员中心时主动扫描残留事务（掉单恢复）。
    // 解决 Apple 不会主动 re-deliver 已 Purchased 事务的问题：
    // 上次 App 被杀或断网导致服务端验证没回时，事务会停留在队列里，
    // 这里主动拉起后由 VC 走正常的 verifyPurchase 流程。
    [[PNIAPObserver shared] resumePendingTransactions];
    // 预加载法律文档，避免点击协议链接时在主线程读盘卡顿
    [LegalDocumentCache preloadResources:@[ @"membership_agreement", @"auto_renew_terms" ]];
}

- (void)updateTheme {
    // 基类会把背景设成 ThemeManager 的浅色，会员中心必须保持稿面深色底
    self.view.backgroundColor = kMCPageBg;
}

- (void)dealloc {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    [self.productsRequest cancel];
    [self.preloadProductsRequest cancel];
    // VC 销毁后，全局观察者接管兜底处理（如果还有未 finish 事务）
    [[PNIAPObserver shared] setMembershipCenterActive:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshUserProfile];
    [[PNIAPObserver shared] setMembershipCenterActive:YES];
    // 每次返回会员中心都扫描一次残留事务（应对被 pop 后回来、断网重连等场景）
    [[PNIAPObserver shared] resumePendingTransactions];
    // 重新进入时强制拉一次状态，确保头部到期日与支付按钮状态最新
    [self loadRemoteData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // 注意：这里不切 membershipCenterActive=NO。
    // 如果购买流程正在异步上报 verifyPurchase 时切了，PNIAPObserver 会"接管"
    // 但实际上拿不到原 transaction 对象，会导致重复请求/双重 finish。
    // active 状态仅在 dealloc 时切回 NO（VC 真正销毁后由 observer 兜底）。

    // 拦截用户在购买进行中（Purchasing 或拉商品 / verifyPurchase 进行中）的 pop 操作：
    // 中断会让用户对是否扣款产生困惑。这里弹窗确认，用户坚持才允许 pop。
    // 注意：此回调会触发多次（包括 present 别的 VC），仅在 isMovingFromParent=YES
    //（即真的要被 pop 出导航栈）时拦截。
    if (self.isMovingFromParentViewController && (self.payInFlight || self.restoreInFlight)) {
        NSLog(@"[IAP] 购买/恢复进行中，用户尝试离开");
        // 不在这里阻塞 super（已经调用过），通过提示告知用户当前状态。
        // 真正的拦截放在 navigationBar 返回按钮 / swipeBack 的交互层更合适；
        // 这里仅给出 toast 提示（VC 已经 pop 完，无法回滚）。
        // 如果需要"硬拦截"，应改用 navigationBar 自定义 leftBarButtonItem + 自定义 pop 手势。
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.bannerGradientLayer.frame = self.bannerCard.bounds;
    self.redeemDialogGradientLayer.frame = self.redeemDialogView.bounds;
    if (self.contentGlassView && self.contentGlassHighlightLayer) {
        self.contentGlassHighlightLayer.frame = self.contentGlassView.bounds;
    }
    for (UIView *card in self.cardViews) {
        for (CALayer *ly in card.layer.sublayers) {
            if ([ly.name isEqualToString:@"mc.card.bg"]) {
                ly.frame = card.bounds;
            }
        }
    }
}

- (void)setupUI {
    self.navBar = [UIView new];
    self.navBar.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.navBar];
    [self.navBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.leading.trailing.equalTo(self.view);
        make.height.mas_equalTo(44);
    }];

    self.backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *backImage = [UIImage imageNamed:@"nav_back"];
    if (!backImage && @available(iOS 13.0, *)) backImage = [UIImage systemImageNamed:@"arrow.left"];
    [self.backBtn setImage:[backImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.backBtn.tintColor = [UIColor whiteColor];
    self.backBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.backBtn addTarget:self action:@selector(onBack) forControlEvents:UIControlEventTouchUpInside];
    [self.navBar addSubview:self.backBtn];
    [self.backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.navBar).offset(16);
        make.centerY.equalTo(self.navBar);
        make.size.mas_equalTo(CGSizeMake(24, 24));
    }];

    self.helpBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    if (@available(iOS 13.0, *)) {
        [self.helpBtn setImage:[UIImage systemImageNamed:@"questionmark.circle"] forState:UIControlStateNormal];
    }
    self.helpBtn.tintColor = [UIColor whiteColor];
    [self.helpBtn addTarget:self action:@selector(onTapHelp) forControlEvents:UIControlEventTouchUpInside];
    [self.navBar addSubview:self.helpBtn];
    [self.helpBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.navBar).offset(-16);
        make.centerY.equalTo(self.navBar);
        make.size.mas_equalTo(CGSizeMake(24, 24));
    }];

    self.titleLabel = [UILabel new];
    self.titleLabel.text = @"会员中心";
    /// Figma 571:2620：标题 18 semibold
    self.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    self.titleLabel.textColor = [UIColor whiteColor];
    [self.navBar addSubview:self.titleLabel];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.centerY.equalTo(self.navBar);
    }];

    self.avatarWrap = [UIView new];
    [self.view addSubview:self.avatarWrap];
    [self.avatarWrap mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.view).offset(20);
        make.top.equalTo(self.navBar.mas_bottom).offset(20);
        make.height.mas_equalTo(52);
    }];
    self.avatarView = [UIImageView new];
    self.avatarView.layer.cornerRadius = 26;
    self.avatarView.clipsToBounds = YES;
    self.avatarView.backgroundColor = [UIColor clearColor];
    self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarView.tintColor = nil;
    self.avatarView.image = [self defaultMembershipAvatarImage];
    [self.avatarWrap addSubview:self.avatarView];
    [self.avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.bottom.equalTo(self.avatarWrap);
        make.size.mas_equalTo(CGSizeMake(52, 52));
    }];
    self.nameLabel = [UILabel new];
    self.nameLabel.text = @"";
    self.nameLabel.textColor = [UIColor whiteColor];
    self.nameLabel.font = [UIFont boldSystemFontOfSize:15.06];
    [self.avatarWrap addSubview:self.nameLabel];
    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.avatarView.mas_trailing).offset(14);
        make.centerY.equalTo(self.avatarView);
        make.trailing.equalTo(self.avatarWrap);
    }];

    self.bannerCard = [UIControl new];
    self.bannerCard.layer.cornerRadius = 24;
    self.bannerCard.clipsToBounds = YES;
    self.bannerCard.backgroundColor = [UIColor colorWithWhite:0 alpha:0.55];
    [self.view addSubview:self.bannerCard];
    [self.bannerCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.view).offset(10);
        make.trailing.equalTo(self.view).offset(-10);
        make.top.equalTo(self.avatarWrap.mas_bottom).offset(14);
        make.height.mas_equalTo(82);
    }];
    /// Figma 571:2648：linear 187.85° 黑 40% → 薄荷 40%
    self.bannerGradientLayer = [CAGradientLayer layer];
    self.bannerGradientLayer.name = @"mc.banner.bg";
    self.bannerGradientLayer.colors = @[
        (id)[UIColor colorWithRed:0 green:0 blue:0 alpha:0.40].CGColor,
        (id)[UIColor colorWithRed:144/255.0 green:1.0 blue:211/255.0 alpha:0.40].CGColor
    ];
    self.bannerGradientLayer.startPoint = CGPointMake(0.15, 1.0);
    self.bannerGradientLayer.endPoint = CGPointMake(0.85, 0.0);
    [self.bannerCard.layer insertSublayer:self.bannerGradientLayer atIndex:0];

    self.bannerTitleLabel = [UILabel new];
    self.bannerTitleLabel.text = @"会员中心";
    self.bannerTitleLabel.textColor = [UIColor whiteColor];
    self.bannerTitleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [self.bannerCard addSubview:self.bannerTitleLabel];
    [self.bannerTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.bannerCard).offset(24);
        make.top.equalTo(self.bannerCard).offset(12);
    }];
    self.bannerSubLabel = [UILabel new];
    self.bannerSubLabel.text = @"限时折扣码";
    self.bannerSubLabel.textColor = kMCDiscountMint;
    self.bannerSubLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    [self.bannerCard addSubview:self.bannerSubLabel];
    [self.bannerSubLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.bannerTitleLabel);
        make.top.equalTo(self.bannerTitleLabel.mas_bottom).offset(2);
    }];
    self.bannerHintLabel = [UILabel new];
    self.bannerHintLabel.text = @"使用限时折扣码，解锁专属会员优惠";
    self.bannerHintLabel.textColor = kMCDiscountHintGray;
    self.bannerHintLabel.font = [UIFont systemFontOfSize:8 weight:UIFontWeightLight];
    [self.bannerCard addSubview:self.bannerHintLabel];
    [self.bannerHintLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.bannerTitleLabel);
        make.top.equalTo(self.bannerSubLabel.mas_bottom).offset(2);
    }];
    self.redeemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.redeemBtn.backgroundColor = [UIColor colorWithRed:40/255.0 green:93/255.0 blue:75/255.0 alpha:1.0];
    self.redeemBtn.layer.cornerRadius = 12;
    self.redeemBtn.titleLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightSemibold];
    [self.redeemBtn setTitle:@"去兑换" forState:UIControlStateNormal];
    [self.redeemBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.redeemBtn addTarget:self action:@selector(onTapRedeemFromBanner) forControlEvents:UIControlEventTouchUpInside];
    [self.bannerCard addSubview:self.redeemBtn];
    [self.redeemBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.bannerCard).offset(-10);
        make.bottom.equalTo(self.bannerCard).offset(-10);
        make.size.mas_equalTo(CGSizeMake(62, 21));
    }];

    self.segmentWrap = [UIView new];
    self.segmentWrap.backgroundColor = [UIColor clearColor];
    self.segmentWrap.clipsToBounds = NO;
    [self.view addSubview:self.segmentWrap];
    [self.segmentWrap mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bannerCard.mas_bottom).offset(14);
        make.leading.equalTo(self.view).offset(0);
        make.width.mas_equalTo(280);
        make.height.mas_equalTo(41);
    }];
    self.subscribeTabBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.subscribeTabBtn.backgroundColor = [UIColor colorWithRed:40/255.0 green:93/255.0 blue:75/255.0 alpha:0.48];
    self.subscribeTabBtn.layer.cornerRadius = 12;
    self.subscribeTabBtn.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    self.subscribeTabBtn.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    [self.subscribeTabBtn setTitle:@"会员订阅" forState:UIControlStateNormal];
    [self.subscribeTabBtn addTarget:self action:@selector(onTapSubscribeTab) forControlEvents:UIControlEventTouchUpInside];
    [self.segmentWrap addSubview:self.subscribeTabBtn];
    [self.subscribeTabBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.bottom.equalTo(self.segmentWrap);
        make.width.mas_equalTo(140);
    }];
    self.giftTabBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.giftTabBtn.backgroundColor = [UIColor blackColor];
    self.giftTabBtn.layer.cornerRadius = 12;
    self.giftTabBtn.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    self.giftTabBtn.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    [self.giftTabBtn setTitle:@"礼包码" forState:UIControlStateNormal];
    [self.giftTabBtn addTarget:self action:@selector(onTapGiftTab) forControlEvents:UIControlEventTouchUpInside];
    [self.segmentWrap addSubview:self.giftTabBtn];
    [self.giftTabBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.top.bottom.equalTo(self.segmentWrap);
        make.width.mas_equalTo(140);
    }];

    /// Figma 571:2613：Tab 下方主内容黑底
    self.contentPanelView = [UIView new];
    self.contentPanelView.backgroundColor = [UIColor blackColor];
    self.contentPanelView.userInteractionEnabled = NO;
    [self.view insertSubview:self.contentPanelView belowSubview:self.segmentWrap];
    [self.contentPanelView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.segmentWrap.mas_bottom);
        make.leading.trailing.bottom.equalTo(self.view);
    }];

    self.giftContainerView = [UIView new];
    self.giftContainerView.hidden = YES;
    [self.view addSubview:self.giftContainerView];
    [self.giftContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.segmentWrap.mas_bottom);
        make.leading.trailing.bottom.equalTo(self.view);
    }];
    self.giftPromptLabel = [UILabel new];
    self.giftPromptLabel.text = @"输入礼包码";
    self.giftPromptLabel.textColor = [UIColor colorWithRed:175/255.0 green:255/255.0 blue:224/255.0 alpha:1.0];
    self.giftPromptLabel.font = [UIFont systemFontOfSize:10.8 weight:UIFontWeightMedium];
    [self.giftContainerView addSubview:self.giftPromptLabel];
    [self.giftPromptLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.giftContainerView).offset(17);
        make.top.equalTo(self.giftContainerView).offset(24);
    }];

    self.giftCodeTapAreaBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.giftCodeTapAreaBtn addTarget:self action:@selector(onTapGiftCodeArea) forControlEvents:UIControlEventTouchUpInside];
    [self.giftContainerView addSubview:self.giftCodeTapAreaBtn];
    [self.giftCodeTapAreaBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.giftContainerView).offset(28);
        make.trailing.equalTo(self.giftContainerView).offset(-31);
        make.top.equalTo(self.giftPromptLabel.mas_bottom).offset(17);
        make.height.mas_equalTo(64.453);
    }];

    NSMutableArray<UIView *> *digitBoxes = [NSMutableArray array];
    NSMutableArray<UILabel *> *digitLabels = [NSMutableArray array];

    UIStackView *digitStack = [[UIStackView alloc] init];
    digitStack.axis = UILayoutConstraintAxisHorizontal;
    digitStack.spacing = 8.761;
    digitStack.distribution = UIStackViewDistributionFillEqually;
    digitStack.alignment = UIStackViewAlignmentFill;
    [self.giftCodeTapAreaBtn addSubview:digitStack];
    [digitStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.giftCodeTapAreaBtn);
    }];

    for (NSInteger i = 0; i < 5; i++) {
        UIView *box = [UIView new];
        box.layer.cornerRadius = 13.428;
        box.layer.borderWidth = 0.895;
        box.layer.borderColor = [UIColor colorWithRed:191/255.0 green:191/255.0 blue:191/255.0 alpha:1.0].CGColor;
        [digitStack addArrangedSubview:box];
        UILabel *digit = [UILabel new];
        digit.textAlignment = NSTextAlignmentCenter;
        digit.textColor = [UIColor colorWithRed:175/255.0 green:255/255.0 blue:224/255.0 alpha:1.0];
        digit.font = [UIFont systemFontOfSize:30.5 weight:UIFontWeightMedium];
        [box addSubview:digit];
        [digit mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(box);
        }];
        [digitBoxes addObject:box];
        [digitLabels addObject:digit];
    }
    self.giftDigitBoxes = digitBoxes;
    self.giftDigitLabels = digitLabels;

    self.giftHiddenInput = [UITextField new];
    self.giftHiddenInput.keyboardType = UIKeyboardTypeNumberPad;
    self.giftHiddenInput.textColor = [UIColor clearColor];
    self.giftHiddenInput.tintColor = [UIColor clearColor];
    [self.giftHiddenInput addTarget:self action:@selector(onGiftCodeChanged) forControlEvents:UIControlEventEditingChanged];
    [self.giftContainerView addSubview:self.giftHiddenInput];
    [self.giftHiddenInput mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.equalTo(self.giftContainerView);
        make.width.height.mas_equalTo(1);
    }];

    self.giftRedeemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.giftRedeemBtn.backgroundColor = kMCMint;
    self.giftRedeemBtn.layer.cornerRadius = 17.5;
    self.giftRedeemBtn.titleLabel.font = [UIFont systemFontOfSize:12.6 weight:UIFontWeightSemibold];
    [self.giftRedeemBtn setTitle:@"确认" forState:UIControlStateNormal];
    [self.giftRedeemBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.giftRedeemBtn addTarget:self action:@selector(onRedeemGiftCode) forControlEvents:UIControlEventTouchUpInside];
    [self.giftContainerView addSubview:self.giftRedeemBtn];
    [self.giftRedeemBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.giftContainerView);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-49);
        make.width.mas_equalTo(226);
        make.height.mas_equalTo(35);
    }];

    self.giftSuccessWrap = [UIView new];
    self.giftSuccessWrap.hidden = YES;
    [self.giftContainerView addSubview:self.giftSuccessWrap];
    [self.giftSuccessWrap mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.giftContainerView);
        make.top.equalTo(self.giftContainerView).offset(156);
        make.size.mas_equalTo(CGSizeMake(117, 117));
    }];
    UIView *successOuter = [UIView new];
    successOuter.layer.cornerRadius = 58.5;
    successOuter.layer.borderWidth = 1;
    successOuter.layer.borderColor = [UIColor colorWithRed:175/255.0 green:255/255.0 blue:224/255.0 alpha:1.0].CGColor;
    [self.giftSuccessWrap addSubview:successOuter];
    [successOuter mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.giftSuccessWrap);
    }];
    UIView *successInner = [UIView new];
    successInner.layer.cornerRadius = 46;
    successInner.backgroundColor = [UIColor colorWithRed:157/255.0 green:234/255.0 blue:208/255.0 alpha:1.0];
    [successOuter addSubview:successInner];
    [successInner mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(successOuter);
        make.size.mas_equalTo(CGSizeMake(89, 89));
    }];
    successInner.layer.cornerRadius = 44.5;
    UILabel *check = [UILabel new];
    check.text = @"✓";
    check.textColor = [UIColor blackColor];
    check.font = [UIFont systemFontOfSize:42 weight:UIFontWeightSemibold];
    [successInner addSubview:check];
    [check mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(successInner);
    }];
    self.giftSuccessLabel = [UILabel new];
    self.giftSuccessLabel.text = @"验证成功";
    self.giftSuccessLabel.textColor = [UIColor colorWithRed:175/255.0 green:255/255.0 blue:224/255.0 alpha:1.0];
    self.giftSuccessLabel.font = [UIFont systemFontOfSize:10.8 weight:UIFontWeightMedium];
    [self.giftContainerView addSubview:self.giftSuccessLabel];
    [self.giftSuccessLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.giftContainerView);
        make.top.equalTo(self.giftSuccessWrap.mas_bottom).offset(18);
    }];

    self.planTitleLabel = [UILabel new];
    /// Figma 571:2657：#dcfff1，约 20.8pt
    self.planTitleLabel.textColor = [UIColor colorWithRed:220/255.0 green:1.0 blue:241/255.0 alpha:1.0];
    self.planTitleLabel.font = [UIFont systemFontOfSize:20.8 weight:UIFontWeightMedium];
    self.planTitleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.planTitleLabel];
    [self.planTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.segmentWrap.mas_bottom).offset(34);
        make.centerX.equalTo(self.view);
    }];

    self.cardScrollView = [UIScrollView new];
    self.cardScrollView.showsHorizontalScrollIndicator = NO;
    self.cardScrollView.delegate = self;
    /// 卡片宽 210 + 间距 12 = 222，与屏宽不等，不能开启系统 paging
    self.cardScrollView.pagingEnabled = NO;
    self.cardScrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    [self.view addSubview:self.cardScrollView];
    [self.cardScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.planTitleLabel.mas_bottom).offset(18);
        make.leading.trailing.equalTo(self.view);
        make.height.mas_equalTo(252);
    }];
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onSwipePlan:)];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.cardScrollView addGestureRecognizer:swipeLeft];
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onSwipePlan:)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    [self.cardScrollView addGestureRecognizer:swipeRight];

    self.cardContentView = [UIView new];
    [self.cardScrollView addSubview:self.cardContentView];
    /// 必须显式 content 宽度，否则横向 UIScrollView 无法正确布局，卡片区会空白
    CGFloat cardW = 210.0, gap = 12.0, side = 82.0;
    CGFloat contentW = side * 2 + cardW * (CGFloat)self.plans.count + gap * MAX(0, (NSInteger)self.plans.count - 1);
    [self.cardContentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.leading.equalTo(self.cardScrollView);
        make.height.equalTo(self.cardScrollView);
        make.width.mas_equalTo(contentW);
    }];

    NSMutableArray *cards = [NSMutableArray array];
    UIView *prev = nil;
    for (NSInteger i = 0; i < self.plans.count; i++) {
        UIView *card = [self buildPlanCard:self.plans[i] large:YES];
        [self.cardContentView addSubview:card];
        [cards addObject:card];
        [card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(self.cardContentView);
            make.width.mas_equalTo(210);
            if (prev) make.leading.equalTo(prev.mas_trailing).offset(12);
            else make.leading.equalTo(self.cardContentView).offset(82);
            if (i == self.plans.count - 1) make.trailing.equalTo(self.cardContentView).offset(-82);
        }];
        prev = card;
    }
    self.cardViews = cards;

    self.pageControl = [UIPageControl new];
    self.pageControl.numberOfPages = self.plans.count;
    self.pageControl.currentPageIndicatorTintColor = [UIColor colorWithRed:141/255.0 green:249/255.0 blue:215/255.0 alpha:1.0];
    self.pageControl.pageIndicatorTintColor = [UIColor colorWithWhite:1 alpha:0.45];
    self.pageControl.currentPage = self.currentIndex;
    [self.pageControl addTarget:self action:@selector(onPageChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.pageControl];
    [self.pageControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.cardScrollView.mas_bottom).offset(10);
        make.centerX.equalTo(self.view);
    }];

    // 底部操作区（自下而上锚到安全区，避免小屏/全面屏贴底、协议挤在一起）
    CGFloat kMCBottomHInset = 24.0;

    self.agreementCheckBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.agreementCheckBtn.layer.borderColor = [UIColor colorWithWhite:0.75 alpha:1.0].CGColor;
    self.agreementCheckBtn.layer.borderWidth = 1.2;
    self.agreementCheckBtn.layer.cornerRadius = 3;
    [self.agreementCheckBtn addTarget:self action:@selector(onToggleAgreement) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.agreementCheckBtn];

    self.agreementLabel = [[UITextView alloc] init];
    self.agreementLabel.editable = NO;
    // selectable=YES 会挂载长按/选择手势，导致链接点击明显延迟；改用手势即时识别 NSLink。
    self.agreementLabel.selectable = NO;
    self.agreementLabel.scrollEnabled = NO;
    self.agreementLabel.userInteractionEnabled = YES;
    self.agreementLabel.backgroundColor = [UIColor clearColor];
    self.agreementLabel.textContainerInset = UIEdgeInsetsZero;
    self.agreementLabel.textContainer.lineFragmentPadding = 0;
    self.agreementLabel.font = [UIFont systemFontOfSize:11];
    self.agreementLabel.textColor = [UIColor colorWithWhite:0.72 alpha:1.0];
    self.agreementLabel.attributedText = [self agreementAttrText];
    UITapGestureRecognizer *agreementTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onAgreementLabelTapped:)];
    agreementTap.cancelsTouchesInView = NO;
    [self.agreementLabel addGestureRecognizer:agreementTap];
    [self.view addSubview:self.agreementLabel];

    // 协议区贴底：文案多行自适应，勾选框与首行顶对齐
    [self.agreementLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.view).offset(kMCBottomHInset + 22);
        make.trailing.equalTo(self.view).offset(-kMCBottomHInset);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-10);
    }];
    [self.agreementCheckBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.view).offset(kMCBottomHInset);
        make.top.equalTo(self.agreementLabel.mas_top).offset(1);
        make.size.mas_equalTo(CGSizeMake(18, 18));
    }];

    self.agreementCheckBtn.selected = NO;
    [self.agreementCheckBtn setTitle:@"" forState:UIControlStateNormal];

    self.restoreBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.restoreBtn.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    NSDictionary *restoreAttrs = @{
        NSForegroundColorAttributeName: kMCMint,
        NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
        NSFontAttributeName: [UIFont systemFontOfSize:12 weight:UIFontWeightMedium]
    };
    [self.restoreBtn setAttributedTitle:[[NSAttributedString alloc] initWithString:@"恢复购买" attributes:restoreAttrs]
                              forState:UIControlStateNormal];
    UIColor *restoreHighlight = [kMCMint colorWithAlphaComponent:0.55];
    NSDictionary *restoreHighlightAttrs = @{
        NSForegroundColorAttributeName: restoreHighlight,
        NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
        NSFontAttributeName: [UIFont systemFontOfSize:12 weight:UIFontWeightMedium]
    };
    [self.restoreBtn setAttributedTitle:[[NSAttributedString alloc] initWithString:@"恢复购买" attributes:restoreHighlightAttrs]
                              forState:UIControlStateHighlighted];
    self.restoreBtn.contentEdgeInsets = UIEdgeInsetsMake(8, 16, 8, 16);
    [self.restoreBtn addTarget:self action:@selector(onTapRestore) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.restoreBtn];
    [self.restoreBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.agreementLabel.mas_top).offset(-10);
        make.height.mas_equalTo(32);
    }];

    self.payBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.payBtn.backgroundColor = kMCMint;
    self.payBtn.layer.cornerRadius = 20;
    self.payBtn.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    self.payBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.payBtn.titleLabel.minimumScaleFactor = 0.85;
    [self.payBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.payBtn addTarget:self action:@selector(onTapPay) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.payBtn];
    [self.payBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.view).offset(40);
        make.trailing.equalTo(self.view).offset(-40);
        make.height.mas_equalTo(40);
        make.bottom.equalTo(self.restoreBtn.mas_top).offset(-6);
    }];

    // 订阅关键信息（Apple 3.1.2）：续期频率 / 买断说明，放在支付按钮上方
    self.subscriptionInfoLabel = [[UILabel alloc] init];
    self.subscriptionInfoLabel.font = [UIFont systemFontOfSize:11];
    self.subscriptionInfoLabel.textColor = [UIColor colorWithWhite:0.55 alpha:1.0];
    self.subscriptionInfoLabel.textAlignment = NSTextAlignmentCenter;
    self.subscriptionInfoLabel.numberOfLines = 2;
    self.subscriptionInfoLabel.adjustsFontSizeToFitWidth = YES;
    self.subscriptionInfoLabel.minimumScaleFactor = 0.85;
    [self.view addSubview:self.subscriptionInfoLabel];
    [self.subscriptionInfoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.payBtn.mas_top).offset(-8);
        make.leading.equalTo(self.view).offset(kMCBottomHInset);
        make.trailing.equalTo(self.view).offset(-kMCBottomHInset);
    }];

    [self refreshRedeemBannerState];
    [self applyPlanAtIndex:self.currentIndex animated:NO];
    [self updatePayButtonState];
    [self switchToGiftMode:NO];
    [self setupRedeemDialog];

    [self.view bringSubviewToFront:self.segmentWrap];
    [self.view bringSubviewToFront:self.planTitleLabel];
    [self.view bringSubviewToFront:self.cardScrollView];
    [self.view bringSubviewToFront:self.pageControl];
    [self.view bringSubviewToFront:self.subscriptionInfoLabel];
    [self.view bringSubviewToFront:self.payBtn];
    [self.view bringSubviewToFront:self.restoreBtn];
    [self.view bringSubviewToFront:self.agreementCheckBtn];
    [self.view bringSubviewToFront:self.agreementLabel];
}

- (void)setupRedeemDialog {
    self.redeemOverlayView = [UIView new];
    self.redeemOverlayView.hidden = YES;
    self.redeemOverlayView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    [self.view addSubview:self.redeemOverlayView];
    [self.redeemOverlayView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    self.redeemDialogView = [UIView new];
    self.redeemDialogView.layer.cornerRadius = 20;
    self.redeemDialogView.clipsToBounds = YES;
    [self.redeemOverlayView addSubview:self.redeemDialogView];
    [self.redeemDialogView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.redeemOverlayView);
        make.width.mas_equalTo(294);
        make.height.mas_equalTo(241);
    }];
    self.redeemDialogGradientLayer = [CAGradientLayer layer];
    self.redeemDialogGradientLayer.colors = @[
        (id)[UIColor colorWithRed:40/255.0 green:93/255.0 blue:75/255.0 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:84/255.0 green:195/255.0 blue:157/255.0 alpha:1.0].CGColor
    ];
    self.redeemDialogGradientLayer.startPoint = CGPointMake(0.0, 0.2);
    self.redeemDialogGradientLayer.endPoint = CGPointMake(1.0, 1.0);
    [self.redeemDialogView.layer insertSublayer:self.redeemDialogGradientLayer atIndex:0];

    UIImageView *redeemDecor = [UIImageView new];
    redeemDecor.userInteractionEnabled = NO;
    redeemDecor.alpha = 0.30;
    redeemDecor.image = [UIImage imageNamed:@"vip_alert"];
    redeemDecor.contentMode = UIViewContentModeScaleAspectFit;
    [self.redeemDialogView addSubview:redeemDecor];
    [redeemDecor mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.redeemDialogView);
        make.trailing.equalTo(self.redeemDialogView);
        make.size.mas_equalTo(CGSizeMake(88, 88));
    }];

    self.redeemCloseIconBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.redeemCloseIconBtn.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9];
    self.redeemCloseIconBtn.layer.cornerRadius = 9;
    [self.redeemCloseIconBtn setTitle:@"×" forState:UIControlStateNormal];
    [self.redeemCloseIconBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.redeemCloseIconBtn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    [self.redeemCloseIconBtn addTarget:self action:@selector(hideRedeemDialog) forControlEvents:UIControlEventTouchUpInside];
    [self.redeemOverlayView addSubview:self.redeemCloseIconBtn];
    [self.redeemCloseIconBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(18);
        make.trailing.equalTo(self.redeemDialogView.mas_trailing);
        make.top.equalTo(self.redeemDialogView.mas_top).offset(-8);
    }];

    self.redeemDialogTitleLabel = [UILabel new];
    self.redeemDialogTitleLabel.text = @"NOMAD PASS会员折扣";
    self.redeemDialogTitleLabel.textColor = [UIColor whiteColor];
    self.redeemDialogTitleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [self.redeemDialogView addSubview:self.redeemDialogTitleLabel];
    [self.redeemDialogTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.redeemDialogView).offset(43);
        make.centerX.equalTo(self.redeemDialogView);
    }];

    self.redeemDialogTicketIconView = [UIImageView new];
    self.redeemDialogTicketIconView.image = [UIImage imageNamed:@"vip_ticket"];
    self.redeemDialogTicketIconView.contentMode = UIViewContentModeScaleAspectFit;
    [self.redeemDialogView addSubview:self.redeemDialogTicketIconView];
    [self.redeemDialogTicketIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.redeemDialogTitleLabel.mas_bottom).offset(20);
        make.centerX.equalTo(self.redeemDialogView);
        make.size.mas_equalTo(CGSizeMake(38, 38));
    }];

    self.redeemInputWrapView = [UIView new];
    self.redeemInputWrapView.backgroundColor = [UIColor whiteColor];
    self.redeemInputWrapView.layer.cornerRadius = 15.5;
    self.redeemInputWrapView.clipsToBounds = YES;
    [self.redeemDialogView addSubview:self.redeemInputWrapView];
    [self.redeemInputWrapView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.redeemDialogView).offset(4.5);
        make.width.mas_equalTo(228);
        make.top.equalTo(self.redeemDialogTicketIconView.mas_bottom).offset(9);
        make.height.mas_equalTo(31);
    }];

    self.redeemInputField = [UITextField new];
    self.redeemInputField.placeholder = @"请输入兑换码/邀请码";
    self.redeemInputField.textColor = [UIColor colorWithRed:40/255.0 green:93/255.0 blue:75/255.0 alpha:1.0];
    self.redeemInputField.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    self.redeemInputField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"请输入兑换码/邀请码" attributes:@{
        NSForegroundColorAttributeName: [UIColor colorWithRed:173/255.0 green:173/255.0 blue:173/255.0 alpha:1.0],
        NSFontAttributeName: [UIFont systemFontOfSize:8 weight:UIFontWeightRegular]
    }];
    // 支持邀请码（12 位字母数字）与原有兑换码（数字）
    self.redeemInputField.keyboardType = UIKeyboardTypeASCIICapable;
    self.redeemInputField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
    self.redeemInputField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.redeemInputField.spellCheckingType = UITextSpellCheckingTypeNo;
    [self.redeemInputField addTarget:self action:@selector(onRedeemDialogInputChanged) forControlEvents:UIControlEventEditingChanged];
    [self.redeemInputWrapView addSubview:self.redeemInputField];
    [self.redeemInputField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.redeemInputWrapView).offset(14);
        make.top.bottom.equalTo(self.redeemInputWrapView);
        make.trailing.equalTo(self.redeemInputWrapView).offset(-76);
    }];

    self.redeemConfirmBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.redeemConfirmBtn.backgroundColor = [UIColor colorWithRed:86/255.0 green:219/255.0 blue:166/255.0 alpha:1.0];
    self.redeemConfirmBtn.layer.cornerRadius = 15.5;
    self.redeemConfirmBtn.layer.maskedCorners = kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner | kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    self.redeemConfirmBtn.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    [self.redeemConfirmBtn setTitle:@"兑换" forState:UIControlStateNormal];
    [self.redeemConfirmBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.redeemConfirmBtn addTarget:self action:@selector(onTapRedeemDialogConfirm) forControlEvents:UIControlEventTouchUpInside];
    [self.redeemInputWrapView addSubview:self.redeemConfirmBtn];
    [self.redeemConfirmBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.trailing.equalTo(self.redeemInputWrapView);
        make.width.mas_equalTo(76);
    }];

    self.redeemHelpLabel = [UILabel new];
    self.redeemHelpLabel.text = @"兑换失败  点击寻求帮助";
    self.redeemHelpLabel.textAlignment = NSTextAlignmentCenter;
    self.redeemHelpLabel.font = [UIFont systemFontOfSize:6 weight:UIFontWeightLight];
    self.redeemHelpLabel.hidden = YES;
    [self applyRedeemHelpLabelStyle];
    [self.redeemDialogView addSubview:self.redeemHelpLabel];
    [self.redeemHelpLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.redeemInputWrapView.mas_bottom).offset(12);
        make.centerX.equalTo(self.redeemDialogView);
    }];

    self.redeemSuccessWrapView = [UIView new];
    self.redeemSuccessWrapView.hidden = YES;
    [self.redeemDialogView addSubview:self.redeemSuccessWrapView];
    [self.redeemSuccessWrapView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.redeemDialogView);
        make.top.equalTo(self.redeemDialogTitleLabel.mas_bottom).offset(26);
        make.size.mas_equalTo(CGSizeMake(61.008, 61.008));
    }];
    UIView *successRing = [UIView new];
    successRing.layer.cornerRadius = 30.504;
    successRing.layer.borderWidth = 1.2;
    successRing.layer.borderColor = [UIColor colorWithRed:175/255.0 green:255/255.0 blue:224/255.0 alpha:1.0].CGColor;
    [self.redeemSuccessWrapView addSubview:successRing];
    [successRing mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.redeemSuccessWrapView);
    }];
    UIView *successInner = [UIView new];
    successInner.layer.cornerRadius = 23;
    successInner.backgroundColor = [UIColor colorWithRed:175/255.0 green:255/255.0 blue:224/255.0 alpha:1.0];
    [successRing addSubview:successInner];
    [successInner mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(successRing);
        make.size.mas_equalTo(CGSizeMake(46, 46));
    }];
    UIImageView *successTicketIcon = [UIImageView new];
    successTicketIcon.image = [UIImage imageNamed:@"vip_ticket"];
    successTicketIcon.contentMode = UIViewContentModeScaleAspectFit;
    [successInner addSubview:successTicketIcon];
    [successTicketIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(successInner);
        make.size.mas_equalTo(CGSizeMake(30, 30));
    }];

    self.redeemSuccessTitleLabel = [UILabel new];
    self.redeemSuccessTitleLabel.text = @"兑换成功！";
    self.redeemSuccessTitleLabel.textColor = [UIColor colorWithRed:175/255.0 green:255/255.0 blue:224/255.0 alpha:1.0];
    self.redeemSuccessTitleLabel.font = [UIFont systemFontOfSize:10.805 weight:UIFontWeightSemibold];
    self.redeemSuccessTitleLabel.hidden = YES;
    [self.redeemDialogView addSubview:self.redeemSuccessTitleLabel];
    [self.redeemSuccessTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.redeemSuccessWrapView.mas_bottom).offset(13);
        make.centerX.equalTo(self.redeemDialogView);
    }];

    self.redeemSuccessDescLabel = [UILabel new];
    self.redeemSuccessDescLabel.text = @"折扣已应用到相应会员订阅中";
    self.redeemSuccessDescLabel.textColor = [UIColor whiteColor];
    self.redeemSuccessDescLabel.font = [UIFont systemFontOfSize:10.805 weight:UIFontWeightLight];
    self.redeemSuccessDescLabel.hidden = YES;
    [self.redeemDialogView addSubview:self.redeemSuccessDescLabel];
    [self.redeemSuccessDescLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.redeemSuccessTitleLabel.mas_bottom).offset(6);
        make.centerX.equalTo(self.redeemDialogView);
    }];
}

- (NSInteger)indexForPlanId:(NSString *)planId {
    NSArray<NSString *> *ids = @[ @"1", @"2", @"3", @"4" ];
    NSUInteger idx = [ids indexOfObject:planId ?: @""];
    return idx == NSNotFound ? NSNotFound : (NSInteger)idx;
}

- (BOOL)isMonthlyPlanId:(NSString *)planId {
    return [planId isEqualToString:@"1"];
}

- (BOOL)isLifetimePlanId:(NSString *)planId {
    return [planId isEqualToString:@"3"];
}

- (BOOL)isFounderPlanId:(NSString *)planId {
    return [planId isEqualToString:@"4"];
}

- (BOOL)isPlan:(MCPlan *)plan matchingRedeemPlanId:(NSString *)redeemPlanId {
    if (!plan) return NO;
    NSString *targetId = redeemPlanId.length > 0 ? redeemPlanId : @"1";
    return [plan.planId isEqualToString:targetId];
}

- (NSString *)normalizedDecimalPriceString:(id)raw {
    if ([raw isKindOfClass:NSString.class]) {
        return [(NSString *)raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    if ([raw isKindOfClass:NSNumber.class]) {
        double value = [(NSNumber *)raw doubleValue];
        if (fabs(value - round(value)) < 0.001) {
            return [NSString stringWithFormat:@"%.0f", value];
        }
        return [NSString stringWithFormat:@"%.2f", value];
    }
    return nil;
}

- (void)applyPaidRedeemResult:(PNRedeemResult *)result code:(NSString *)code {
    if (!result || result.appleProductId.length == 0) return;
    self.hasAppliedRedeemDiscount = YES;
    self.pendingRedeemCode = code;
    self.redeemAppleProductId = result.appleProductId;
    if (result.planId.length > 0) {
        self.redeemPlanId = result.planId;
    }
    self.redeemOriginalPrice = [self normalizedDecimalPriceString:result.originalPrice];
    self.redeemDiscountPrice = [self normalizedDecimalPriceString:result.discountPrice];
    NSInteger targetIndex = [self indexForPlanId:self.redeemPlanId];
    if (targetIndex != NSNotFound) {
        self.currentIndex = targetIndex;
    }
    [self reloadPlanCardsPreservingIndex];
    [self preloadAppStorePrices];
    [self refreshRedeemBannerState];
    [self switchToGiftMode:NO];
}

- (UIView *)buildPlanCard:(MCPlan *)plan large:(BOOL)large {
    BOOL isMonthlyPlan = [self isMonthlyPlanId:plan.planId];
    BOOL isLifetimePlan = [self isLifetimePlanId:plan.planId];
    BOOL isFounderPlan = [self isFounderPlanId:plan.planId];
    BOOL isLargeLifetimePlan = large && isLifetimePlan;
    BOOL isLargeFounderPlan = large && isFounderPlan;
    UIView *card = [UIView new];
    card.layer.cornerRadius = large ? 15.133 : 11.29;
    card.clipsToBounds = YES;
    card.layer.borderWidth = large ? 1.005 : 0.75;
    card.layer.borderColor = kMCMintBorder.CGColor;
    CAGradientLayer *g = [CAGradientLayer layer];
    g.name = @"mc.card.bg";
    g.colors = @[(id)[UIColor colorWithRed:175/255.0 green:255/255.0 blue:224/255.0 alpha:0.30].CGColor, (id)[UIColor colorWithRed:0 green:0 blue:0 alpha:0.30].CGColor];
    g.startPoint = CGPointMake(0.5, 0);
    g.endPoint = CGPointMake(0.5, 1);
    [card.layer addSublayer:g];

    UILabel *type = nil;
    if (!isLargeLifetimePlan && !isLargeFounderPlan) {
        type = [UILabel new];
        type.text = plan.title;
        type.textColor = [UIColor whiteColor];
        type.font = [UIFont systemFontOfSize:(large ? (isMonthlyPlan ? 15.14 : 15.0) : 11.0) weight:UIFontWeightSemibold];
        [card addSubview:type];
        [type mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(card).offset(15);
            make.top.equalTo(card).offset(14);
        }];
    }

    UIView *crownRow = [UIView new];
    [card addSubview:crownRow];
    [crownRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(card).offset((isLargeLifetimePlan || isLargeFounderPlan) ? 19 : 14);
        if (isLargeLifetimePlan || isLargeFounderPlan) {
            make.top.equalTo(card).offset(21);
            make.height.mas_equalTo(17.01);
        } else {
            make.top.equalTo(type.mas_bottom).offset(10);
            make.height.mas_equalTo(18);
        }
    }];
    UIImageView *crown = [UIImageView new];
    crown.contentMode = UIViewContentModeScaleAspectFit;
    UIImage *crownImage = [UIImage imageNamed:@"vip_crown"];
    if (!crownImage && @available(iOS 13.0, *)) {
        crown.tintColor = [UIColor colorWithRed:175/255.0 green:255/255.0 blue:224/255.0 alpha:1.0];
        crownImage = [[UIImage systemImageNamed:@"crown.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    crown.image = crownImage;
    [crownRow addSubview:crown];
    [crown mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.centerY.equalTo(crownRow);
        CGFloat crownSize = (isLargeLifetimePlan || isLargeFounderPlan) ? 15.998 : (large ? 16.0 : 12.0);
        make.size.mas_equalTo(CGSizeMake(crownSize, crownSize));
    }];
    UILabel *spec = [UILabel new];
    spec.text = (isLargeLifetimePlan || isLargeFounderPlan) ? @"终身权益" : @"特殊权益";
    spec.textColor = [UIColor whiteColor];
    spec.font = [UIFont systemFontOfSize:(isLargeLifetimePlan || isLargeFounderPlan) ? 11.991 : (large ? 12.06 : 9) weight:UIFontWeightMedium];
    [crownRow addSubview:spec];
    [spec mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(crown.mas_trailing).offset((isLargeLifetimePlan || isLargeFounderPlan) ? 3.0 : 6.0);
        make.centerY.equalTo(crownRow);
        make.trailing.lessThanOrEqualTo(crownRow);
    }];

    NSArray<NSString *> *icons = plan.benefitIcons;
    CGFloat lineStep = isLargeFounderPlan ? 28.2 : (large ? 29.34 : 22.03);
    CGFloat lineTopOffset = (isLargeLifetimePlan || isLargeFounderPlan) ? 19.08 : (large ? 21.03 : 16.57);
    CGFloat textLeading = large ? 53.54 : 40.15;
    CGFloat ringLeading = large ? 19.0 : 14.25;
    CGFloat ringSize = isLargeFounderPlan ? 24.0 : (large ? 25.01 : 18.75);
    CGFloat defaultIconSize = isLargeFounderPlan ? 17.777 : (large ? 15.28 : 11.46);
    UILabel *lastBenefitLine = nil;
    for (NSInteger i = 0; i < plan.benefits.count; i++) {
        NSString *sym = (icons && i < (NSInteger)icons.count) ? icons[i] : @"circle.fill";
        NSString *benefitText = plan.benefits[i];
        UILabel *line = [UILabel new];
        line.text = benefitText;
        line.textColor = [UIColor whiteColor];
        line.font = [UIFont systemFontOfSize:(isLargeLifetimePlan ? 7.484 : (isLargeFounderPlan ? 8.71 : (large ? 7.53 : 5.62))) weight:UIFontWeightMedium];
        line.numberOfLines = 1;
        [card addSubview:line];
        [line mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(card).offset(textLeading);
            make.trailing.lessThanOrEqualTo(card).offset((isLargeLifetimePlan || isLargeFounderPlan) ? -15 : -8);
            make.top.equalTo(crownRow.mas_bottom).offset(lineTopOffset + i * lineStep);
        }];
        if (isLargeFounderPlan && i == plan.benefits.count - 1) {
            lastBenefitLine = line;
        }
        UIView *ring = [UIView new];
        ring.backgroundColor = [UIColor blackColor];
        ring.layer.cornerRadius = ringSize / 2.0;
        [card addSubview:ring];
        [ring mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(line);
            make.leading.equalTo(card).offset(ringLeading);
            make.size.mas_equalTo(CGSizeMake(ringSize, ringSize));
        }];
        UIImageView *ic = [UIImageView new];
        ic.contentMode = UIViewContentModeScaleAspectFit;
        ic.tintColor = [UIColor whiteColor];
        UIImage *benefitImage = nil;
        if ([benefitText containsString:@"解锁全部内容"]) {
            benefitImage = [UIImage imageNamed:@"vip_unlock"];
        } else if ([benefitText containsString:@"数据可视化"] || [benefitText containsString:@"数据回顾"]) {
            benefitImage = [UIImage imageNamed:@"vip_data"];
        } else if ([benefitText containsString:@"邮票"]) {
            benefitImage = [UIImage imageNamed:@"vip_stamp"];
        } else if ([benefitText containsString:@"未来产品"]) {
            benefitImage = [UIImage imageNamed:@"vip_product"];
        } else if ([benefitText containsString:@"社群"]) {
            benefitImage = [UIImage imageNamed:@"vip_global"];
        } else if ([benefitText containsString:@"球衣"]) {
            benefitImage = [UIImage imageNamed:@"vip_clothes"];
        } else if ([benefitText containsString:@"终身全部权益"]) {
            benefitImage = [UIImage imageNamed:@"vip_trophy"];
        } else if ([benefitText containsString:@"会员徽章"]) {
            benefitImage = [UIImage imageNamed:@"vip_postcard"];
        } else if ([benefitText containsString:@"编号徽章"]) {
            benefitImage = [UIImage imageNamed:@"vip_coins"];
        }
        if (!benefitImage && @available(iOS 13.0, *)) {
            benefitImage = [[UIImage systemImageNamed:sym] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }
        ic.image = benefitImage;
        [card addSubview:ic];
        [ic mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(ring);
            CGFloat iconSize = defaultIconSize;
            if (isLargeLifetimePlan && [benefitText containsString:@"会员徽章"]) {
                iconSize = 13.998;
            }
            make.size.mas_equalTo(CGSizeMake(iconSize, iconSize));
        }];
    }

    NSString *hintText = [self cardHintTextForPlan:plan];
    UILabel *hint = [UILabel new];
    hint.text = hintText.length ? hintText : nil;
    hint.hidden = hintText.length == 0;
    hint.textColor = [UIColor colorWithRed:147/255.0 green:221/255.0 blue:196/255.0 alpha:1.0]; // #93DDC4
    CGFloat hintSize = 6.9;
    if (isLargeFounderPlan) {
        hintSize = 9.2;
    } else if (large && isMonthlyPlan) {
        // Figma 兑换后「限时优惠」在月卡上字号更大。
        hintSize = 9.248;
    }
    hint.font = [UIFont systemFontOfSize:hintSize];
    hint.textAlignment = NSTextAlignmentRight;
    [card addSubview:hint];

    NSString *originalPriceText = [self cardOriginalPriceTextForPlan:plan];
    UILabel *originPrice = [UILabel new];
    originPrice.hidden = originalPriceText.length == 0;
    originPrice.attributedText = [self cardOriginalPriceAttrTextForPlan:plan large:large];
    originPrice.textColor = kMCDiscountHintGray;
    originPrice.textAlignment = NSTextAlignmentRight;
    [card addSubview:originPrice];
    [originPrice mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(card).offset(isMonthlyPlan ? -12 : -10);
        if (large && isMonthlyPlan && !originPrice.hidden) {
            make.bottom.equalTo(card).offset(-78);
        } else if (isLargeFounderPlan && !hint.hidden) {
            make.bottom.equalTo(hint.mas_top).offset(-1);
        } else {
            make.bottom.equalTo(card).offset(large ? -79 : -58);
        }
    }];
    if (!originPrice.hidden) {
        UIView *strikeLine = [UIView new];
        strikeLine.backgroundColor = kMCDiscountHintGray;
        [card addSubview:strikeLine];
        [strikeLine mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(originPrice).offset(-1);
            make.trailing.equalTo(originPrice).offset(1);
            make.centerY.equalTo(originPrice).offset(1);
            make.height.mas_equalTo(large ? 0.6 : 0.25);
        }];
    }

    [hint mas_makeConstraints:^(MASConstraintMaker *make) {
        if (large && isMonthlyPlan && !originPrice.hidden) {
            make.trailing.equalTo(originPrice.mas_leading).offset(-8);
            make.centerY.equalTo(originPrice);
        } else {
            make.trailing.equalTo(card).offset(isMonthlyPlan ? -8 : -10);
            if (isLargeFounderPlan && lastBenefitLine) {
                make.centerY.equalTo(lastBenefitLine);
            } else {
                CGFloat hintBottom = -58;
                if (large) {
                    if (isMonthlyPlan) hintBottom = -82;
                    else hintBottom = -78;
                }
                make.bottom.equalTo(card).offset(hintBottom);
            }
        }
    }];

    UILabel *price = [UILabel new];
    price.attributedText = [self cardPriceAttrTextForPlan:plan large:large];
    price.textColor = [UIColor colorWithRed:175/255.0 green:255/255.0 blue:224/255.0 alpha:1.0];
    price.textAlignment = NSTextAlignmentRight;
    [card addSubview:price];
    [price mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(card).offset(isMonthlyPlan ? -12 : -10);
        make.bottom.equalTo(card).offset(8);
    }];
    /// 月度通行证「限时优惠」需要显示在价格上层，避免被大号金额遮挡
    if (!hint.hidden) {
        [card bringSubviewToFront:hint];
    }
    return card;
}

- (UIFont *)membershipNeueFontOfSize:(CGFloat)size fallbackWeight:(UIFontWeight)weight {
    UIFont *base = FontManager.sharedManager.font75Regular;
    UIFont *custom = base ? [UIFont fontWithDescriptor:base.fontDescriptor size:size] : nil;
    if (custom) return custom;
    if (@available(iOS 13.0, *)) {
        return [UIFont monospacedDigitSystemFontOfSize:size weight:weight];
    }
    return [UIFont systemFontOfSize:size weight:weight];
}

- (UIImage *)defaultMembershipAvatarImage {
    CGSize size = CGSizeMake(52, 52);
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull rendererContext) {
        CGRect bounds = (CGRect){CGPointZero, size};
        [[UIColor clearColor] setFill];
        UIRectFill(bounds);

        UIBezierPath *circlePath = [UIBezierPath bezierPathWithOvalInRect:bounds];
        [[UIColor colorWithWhite:1 alpha:0.12] setFill];
        [circlePath fill];

        UIImage *icon = nil;
        if (@available(iOS 13.0, *)) {
            UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:24 weight:UIImageSymbolWeightRegular];
            icon = [[UIImage systemImageNamed:@"person.fill" withConfiguration:config] imageWithTintColor:[UIColor colorWithWhite:1 alpha:0.92] renderingMode:UIImageRenderingModeAlwaysOriginal];
        }
        if (!icon) {
            UIImage *fallback = [UIImage imageNamed:@"setting_photo"];
            if (fallback) {
                CGFloat fallbackSide = 22;
                [fallback drawInRect:CGRectMake((size.width - fallbackSide) / 2.0, (size.height - fallbackSide) / 2.0, fallbackSide, fallbackSide)];
            }
            return;
        }

        CGSize iconSize = icon.size;
        CGRect iconRect = CGRectMake((size.width - iconSize.width) / 2.0, (size.height - iconSize.height) / 2.0, iconSize.width, iconSize.height);
        [icon drawInRect:iconRect];
    }];
}

- (NSString *)displayPriceTextForPlan:(MCPlan *)plan {
    if (plan.localizedPrice.length > 0) return plan.localizedPrice;
    NSString *pay = plan.payPrice.length ? plan.payPrice : plan.price;
    return pay.length > 0 ? pay : @"—";
}

- (NSString *)displayOriginalPriceTextForPlan:(MCPlan *)plan {
    if (plan.localizedOriginalPrice.length > 0) return plan.localizedOriginalPrice;
    return plan.originalPrice.length > 0 ? plan.originalPrice : @"";
}

- (NSString *)currencySymbolFromProduct:(SKProduct *)product {
    if (!product) return nil;
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterCurrencyStyle;
    formatter.locale = product.priceLocale ?: [NSLocale currentLocale];
    return formatter.currencySymbol;
}

- (NSAttributedString *)cardPriceAttrTextWithCurrencySymbol:(NSString *)symbol
                                                 numberText:(NSString *)numberText
                                                      large:(BOOL)large
                                                      color:(UIColor *)color {
    NSString *currency = symbol.length > 0 ? symbol : @"¥";
    NSString *number = numberText.length > 0 ? numberText : @"—";
    NSString *full = [NSString stringWithFormat:@"%@%@", currency, number];
    UIColor *textColor = color ?: [UIColor colorWithRed:175/255.0 green:255/255.0 blue:224/255.0 alpha:1.0];
    CGFloat priceSize = large ? 72.38 : 54.0;
    CGFloat unitSize = large ? 25.46 : 19.0;
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:full attributes:@{
        NSForegroundColorAttributeName: textColor,
        NSFontAttributeName: [self membershipNeueFontOfSize:priceSize fallbackWeight:UIFontWeightRegular]
    }];
    if (currency.length > 0) {
        [attr addAttribute:NSFontAttributeName value:[self membershipNeueFontOfSize:unitSize fallbackWeight:UIFontWeightRegular]
                     range:NSMakeRange(0, currency.length)];
    }
    return attr;
}

- (NSAttributedString *)cardPriceAttrTextForPlan:(MCPlan *)plan large:(BOOL)large {
    UIColor *mint = [UIColor colorWithRed:175/255.0 green:255/255.0 blue:224/255.0 alpha:1.0];
    NSString *number = plan.price.length > 0 ? plan.price : plan.payPrice;
    return [self cardPriceAttrTextWithCurrencySymbol:plan.currencySymbol numberText:number large:large color:mint];
}

- (void)loadRemoteData {
    [self loadRemoteDataWithForce:NO];
}

- (void)loadRemoteDataWithForce:(BOOL)force {
    if (!force && self.loadingRemoteData) {
        self.pendingRemoteDataReload = YES;
        return;
    }
    self.pendingRemoteDataReload = NO;
    self.loadingRemoteData = YES;
    __weak typeof(self) weakSelf = self;
    __block NSInteger pendingCount = 2; // plans + status

    void (^onOneDone)(void) = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            pendingCount -= 1;
            if (pendingCount <= 0) {
                weakSelf.loadingRemoteData = NO;
                if (weakSelf.pendingRemoteDataReload) {
                    weakSelf.pendingRemoteDataReload = NO;
                    [weakSelf loadRemoteDataWithForce:YES];
                }
            }
        });
    };

    // 加载会员方案列表，用价格和 appleProductId 更新本地 plans
    [[MembershipRequest shared] getMembershipPlansSuccess:^(HTTPResponse * _Nullable responseObject) {
        id raw = responseObject.dataObject ?: responseObject.data;
        NSArray *list = nil;
        if ([raw isKindOfClass:NSArray.class]) {
            list = raw;
        } else if ([raw isKindOfClass:NSDictionary.class]) {
            id inner = ((NSDictionary *)raw)[@"list"] ?: ((NSDictionary *)raw)[@"data"];
            if ([inner isKindOfClass:NSArray.class]) list = inner;
        }
        if (list.count > 0) {
            NSArray<PNMemberPlan *> *apiPlans = [NSArray yy_modelArrayWithClass:PNMemberPlan.class json:list];
            weakSelf.apiPlans = apiPlans;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf applyAPIPlansToUI:apiPlans];
                // Apple：展示价必须与 SKProduct.price 一致，服务端价仅作占位
                [weakSelf preloadAppStorePrices];
            });
        }
        onOneDone();
    } failure:^(NSError * _Nonnull error) {
        // 接口失败时保留本地写死数据；仍尝试拉 SKProduct 价（若有 apiPlans/缓存）
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf preloadAppStorePrices];
        });
        onOneDone();
    }];

    // 加载会员状态，更新 banner 标题
    [[MembershipRequest shared] getMembershipStatusSuccess:^(HTTPResponse * _Nullable responseObject) {
        id raw = responseObject.dataObject ?: responseObject.data;
        PNMembershipStatus *status = [PNMembershipStatus yy_modelWithJSON:raw];
        weakSelf.membershipStatus = status;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf applyMembershipStatusToUI:status];
        });
        onOneDone();
    } failure:^(NSError * _Nonnull error) {
        onOneDone();
    }];
}

/// 用服务端方案数据更新本地 MCPlan 的价格和 appleProductId
- (void)applyAPIPlansToUI:(NSArray<PNMemberPlan *> *)apiPlans {
    if (apiPlans.count == 0) return;
    [self reloadPlanCardsPreservingIndex];
}

- (void)mergeAPIPlansIntoPlans:(NSArray<MCPlan *> *)plans {
    if (self.apiPlans.count == 0 || plans.count == 0) return;
    NSArray<PNMemberPlan *> *sorted = [self.apiPlans sortedArrayUsingComparator:^NSComparisonResult(PNMemberPlan *a, PNMemberPlan *b) {
        return [a.planId compare:b.planId options:NSNumericSearch];
    }];
    for (NSInteger i = 0; i < (NSInteger)sorted.count && i < (NSInteger)plans.count; i++) {
        PNMemberPlan *api = sorted[i];
        MCPlan *local = plans[i];
        if (api.price.length > 0) {
            local.price = api.price;
            local.payPrice = api.price;
        }
        if (api.planId.length > 0) {
            local.planId = api.planId;
        }
        if (api.name.length > 0) {
            local.title = api.name;
        }
    }
    // 若 SKProduct 已缓存，立即用真实 App Store 价覆盖（审核要求展示价=扣款价）
    [self applySKProductPricesToPlans:plans];
}

/// 预拉取全部 IAP 商品的 SKProduct，用于刷新展示价（场景 1.2）。
- (void)preloadAppStorePrices {
    NSMutableSet<NSString *> *ids = [NSMutableSet set];
    for (PNMemberPlan *p in self.apiPlans) {
        NSString *pid = [p.appleProductId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (pid.length > 0) [ids addObject:pid];
    }
    // 兑换码折扣商品也一并拉价
    NSString *redeemPid = [self.redeemAppleProductId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (redeemPid.length > 0) [ids addObject:redeemPid];
    if (ids.count == 0) return;

    [self.preloadProductsRequest cancel];
    self.preloadProductsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:ids];
    self.preloadProductsRequest.delegate = self;
    [self.preloadProductsRequest start];
}

/// SKProduct 完整本地化价格（含货币符号，与 Apple 购买确认页一致）。
- (NSString *)localizedPriceStringFromProduct:(SKProduct *)product {
    if (!product) return nil;
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterCurrencyStyle;
    formatter.locale = product.priceLocale ?: [NSLocale currentLocale];
    return [formatter stringFromNumber:product.price] ?: product.price.stringValue;
}

/// 把 SKProduct.price 按 priceLocale 格式化后写回本地方案（仅数字部分，兼容旧逻辑）。
- (NSString *)numericPriceStringFromProduct:(SKProduct *)product {
    if (!product) return nil;
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.locale = product.priceLocale ?: [NSLocale currentLocale];
    formatter.minimumFractionDigits = 0;
    formatter.maximumFractionDigits = 2;
    return [formatter stringFromNumber:product.price] ?: product.price.stringValue;
}

- (nullable NSString *)resolvedAppleProductIdForPlanIndex:(NSInteger)index {
    NSArray<NSString *> *expectedPlanIds = @[ @"1", @"2", @"3", @"4" ];
    NSString *selectedPlanId = (index >= 0 && index < (NSInteger)expectedPlanIds.count)
        ? expectedPlanIds[index] : nil;
    BOOL useRedeemDiscount = self.hasAppliedRedeemDiscount
        && self.redeemAppleProductId.length > 0
        && selectedPlanId.length > 0
        && (self.redeemPlanId.length == 0 || [self.redeemPlanId isEqualToString:selectedPlanId]);
    if (useRedeemDiscount) {
        return [self.redeemAppleProductId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    if (self.apiPlans.count == 0 || selectedPlanId.length == 0) return nil;
    for (PNMemberPlan *p in self.apiPlans) {
        if ([p.planId isEqualToString:selectedPlanId]) {
            return [[p.appleProductId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] copy];
        }
    }
    return nil;
}

- (BOOL)isStoreKitPriceReadyForPlanIndex:(NSInteger)index {
    NSString *pid = [self resolvedAppleProductIdForPlanIndex:index];
    return pid.length > 0 && self.skProducts[pid] != nil;
}

- (void)applySKProductPricesToPlans:(NSArray<MCPlan *> *)plans {
    if (plans.count == 0 || self.skProducts.count == 0) return;
    NSArray<PNMemberPlan *> *sorted = [self.apiPlans sortedArrayUsingComparator:^NSComparisonResult(PNMemberPlan *a, PNMemberPlan *b) {
        return [a.planId compare:b.planId options:NSNumericSearch];
    }];
    for (NSInteger i = 0; i < (NSInteger)sorted.count && i < (NSInteger)plans.count; i++) {
        PNMemberPlan *api = sorted[i];
        NSString *pid = [api.appleProductId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        SKProduct *product = pid.length > 0 ? self.skProducts[pid] : nil;
        NSString *localized = [self localizedPriceStringFromProduct:product];
        NSString *priceStr = [self numericPriceStringFromProduct:product];
        if (localized.length == 0 || priceStr.length == 0) continue;
        MCPlan *local = plans[i];
        local.localizedPrice = localized;
        local.currencySymbol = [self currencySymbolFromProduct:product];
        local.price = priceStr;
        local.payPrice = priceStr;
    }
    // 折扣场景：展示价改用折扣商品的 SKProduct 价
    if (self.hasAppliedRedeemDiscount) {
        for (MCPlan *plan in plans) {
            [self applyRedeemDiscountToPlan:plan];
        }
    }
}

- (void)refreshUIAfterSKProductPricesApplied {
    if (self.plans.count == 0) return;
    // 重建卡片：buildPlanData → mergeAPIPlans → applySKProductPrices
    [self reloadPlanCardsPreservingIndex];
}

/// 兑换/支付成功后立即用结果刷新 banner，避免等 status 接口期间界面无变化。
- (void)applyMembershipActivationFromRedeemResult:(PNRedeemResult *)result {
    if (!result || result.needPayment) return;
    PNMembershipStatus *status = [PNMembershipStatus new];
    status.isMember = YES;
    status.expireTime = result.expireTime;
    status.nearExpiry = NO;
    self.membershipStatus = status;
    [self applyMembershipStatusToUI:status];
}

/// 强制拉取会员状态（不受 loadRemoteData 防抖影响），用于兑换/支付成功后刷新。
- (void)refreshMembershipStatusForce {
    __weak typeof(self) weakSelf = self;
    [[MembershipRequest shared] getMembershipStatusSuccess:^(HTTPResponse * _Nullable responseObject) {
        id raw = responseObject.dataObject ?: responseObject.data;
        PNMembershipStatus *status = [PNMembershipStatus yy_modelWithJSON:raw];
        weakSelf.membershipStatus = status;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf applyMembershipStatusToUI:status];
        });
    } failure:nil];
}

/// 根据会员状态更新 banner 文案
- (void)applyMembershipStatusToUI:(PNMembershipStatus *)status {
    if (!status) return;
    // isMember=true 且 expireTime 非空：有限期会员（月/季/年）。
    // expireTime=null：永久会员（duration_days=0），banner 显示"永久有效"。
    // Apple 3.1.2：永久会员不能显示具体到期日，否则审核会判定"伪造永久"。
    if (status.isMember && status.expireTime.length > 0) {
        self.bannerTitleLabel.text = [NSString stringWithFormat:@"会员有效期至 %@",
                                      [status.expireTime substringToIndex:MIN(10, status.expireTime.length)]];
        if (status.nearExpiry) {
            self.bannerSubLabel.text = @"即将到期，续费享优惠";
            self.bannerSubLabel.textColor = [UIColor colorWithRed:1.0 green:0.8 blue:0.2 alpha:1.0];
            self.bannerHintLabel.text = @"使用限时兑换码，解锁专属会员优惠";
            self.bannerHintLabel.textColor = kMCDiscountHintGray;
        } else {
            // 会员且非临期：清掉兑换码副标题，避免仍显示「限时兑换码」
            self.bannerSubLabel.text = nil;
            self.bannerSubLabel.textColor = [UIColor clearColor];
            self.bannerHintLabel.text = @"尊享全部会员权益";
            self.bannerHintLabel.textColor = kMCDiscountHintGray;
        }
    } else if (status.isMember) {
        // 永久会员：expireTime=null（duration_days=0）。Apple 3.1.2：禁止显示具体到期日。
        self.bannerTitleLabel.text = @"永久会员，永久有效";
        self.bannerSubLabel.text = nil;
        self.bannerSubLabel.textColor = [UIColor clearColor];
        self.bannerHintLabel.text = @"尊享全部会员权益";
        self.bannerHintLabel.textColor = kMCDiscountHintGray;
    } else {
        // 非会员：恢复设计稿默认标题 + 兑换/折扣 banner 文案
        self.bannerTitleLabel.text = @"会员中心";
        [self refreshRedeemBannerState];
    }
}

- (void)refreshUserProfile {
    User *user = AuthManager.sharedManager.user;
    UserProfile *profile = user.profile;
    NSString *nickname = profile.nickname.length > 0 ? profile.nickname : user.nickname;
    self.nameLabel.text = nickname;

    NSString *avatarString = profile.avatar.length > 0 ? profile.avatar : user.avatar;
    NSString *trimmedAvatarString = [avatarString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSURL *avatarURL = trimmedAvatarString.length > 0 ? [NSURL URLWithString:trimmedAvatarString] : nil;
    UIImage *placeholder = [self defaultMembershipAvatarImage];
    if (avatarURL) {
        self.avatarView.tintColor = nil;
        self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
        self.avatarView.backgroundColor = [UIColor clearColor];
    } else {
        [self.avatarView sd_cancelCurrentImageLoad];
        self.avatarView.tintColor = nil;
        self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
        self.avatarView.backgroundColor = [UIColor clearColor];
        self.avatarView.image = placeholder;
        return;
    }
    [self.avatarView sd_setImageWithURL:avatarURL placeholderImage:placeholder];
}

- (NSString *)displayTitleForPlan:(MCPlan *)plan {
    if ([self isMonthlyPlanId:plan.planId] || [plan.title containsString:@"月"]) return @"月度通行证";
    if ([plan.planId isEqualToString:@"2"] || [plan.title containsString:@"年"]) return @"赛季通行证（12个月）";
    if ([self isLifetimePlanId:plan.planId] || [plan.title containsString:@"永久"] || [plan.title containsString:@"终身VIP"]) return @"终身会员";
    if ([self isFounderPlanId:plan.planId] || [plan.title containsString:@"创始"] || [plan.title containsString:@"超级"]) return @"创始人会员";
    if ([plan.title isEqualToString:@"连续包月"]) return @"月度通行证";
    if ([plan.title isEqualToString:@"连续包年"]) return @"赛季通行证（12个月）";
    if ([plan.title isEqualToString:@"永久权益"]) return @"终身会员";
    if ([plan.title isEqualToString:@"终身权益"]) return @"创始人会员";
    return plan.title.length ? plan.title : @"会员方案";
}

- (NSAttributedString *)paymentButtonAttrTitleForPlan:(MCPlan *)plan {
    NSString *pay = [self displayPriceTextForPlan:plan];
    // Apple 审核指南 3.1.2 要求：自动续期订阅的支付按钮文案必须明示价格 + 周期
    NSString *period = [self subscriptionPeriodTextForPlan:plan];
    NSString *full;
    if (period.length > 0) {
        full = [NSString stringWithFormat:@"确认协议并支付 %@/%@", pay ?: @"", period];
    } else {
        full = [NSString stringWithFormat:@"确认协议并支付 %@", pay ?: @""];
    }
    return [[NSAttributedString alloc] initWithString:full attributes:@{
        NSForegroundColorAttributeName: [UIColor whiteColor],
        NSFontAttributeName: [UIFont systemFontOfSize:12.57 weight:UIFontWeightSemibold]
    }];
}

/// 返回方案的续期周期文案（用于按钮和订阅信息标签）。
/// 按月续期 → "月"；按年续期 → "年"；永久/创始人 → ""（非续期商品）。
/// Apple 3.1.2: 续期频率必须明示。
- (NSString *)subscriptionPeriodTextForPlan:(MCPlan *)plan {
    NSString *title = plan.title ?: @"";
    if ([title containsString:@"月"]) return @"月";
    if ([title containsString:@"年"]) return @"年";
    if ([title containsString:@"季"]) return @"季";
    // 永久 / 创始人 / 兑换码激活的方案：非自动续期，不显示周期
    return @"";
}

/// 返回订阅关键信息文案（Apple 审核指南 3.1.2 要求在购买按钮附近明示）。
/// 月/季/年订阅 → "¥33/月，按月自动续期，到期前 24 小时内扣费，可随时取消"
/// 永久/创始人 → "¥748 一次性买断，永久有效"
- (NSString *)subscriptionInfoTextForPlan:(MCPlan *)plan {
    NSString *pay = [self displayPriceTextForPlan:plan];
    NSString *period = [self subscriptionPeriodTextForPlan:plan];
    if (period.length > 0) {
        return [NSString stringWithFormat:@"%@/%@，按%@自动续期，到期前24小时内扣费，可随时取消",
                pay, period, period];
    }
    return [NSString stringWithFormat:@"%@ 一次性买断，永久有效，无需续费", pay];
}

- (void)updatePayButtonPresentationForPlan:(MCPlan *)plan {
    if (![self isStoreKitPriceReadyForPlanIndex:self.currentIndex]) {
        NSString *title = (self.preloadProductsRequest != nil || self.loadingRemoteData)
            ? @"价格加载中..."
            : @"暂无法获取价格，请稍后重试";
        [self.payBtn setAttributedTitle:nil forState:UIControlStateNormal];
        [self.payBtn setAttributedTitle:nil forState:UIControlStateDisabled];
        [self.payBtn setTitle:title forState:UIControlStateNormal];
        [self.payBtn setTitle:title forState:UIControlStateDisabled];
        self.subscriptionInfoLabel.text = @"正在从 App Store 获取价格…";
        return;
    }
    [self.payBtn setTitle:nil forState:UIControlStateNormal];
    [self.payBtn setTitle:nil forState:UIControlStateDisabled];
    NSAttributedString *attr = [self paymentButtonAttrTitleForPlan:plan];
    [self.payBtn setAttributedTitle:attr forState:UIControlStateNormal];
    [self.payBtn setAttributedTitle:attr forState:UIControlStateDisabled];
    self.subscriptionInfoLabel.text = [self subscriptionInfoTextForPlan:plan];
}

/// 当前选中方案是否为永久/终身/创始人类型（非续期商品）。
/// 用于购买成功文案适配（Apple 3.1.2：永久会员不能暗示自动续期）。
- (BOOL)isCurrentPlanLifetime {
    NSInteger idx = self.currentIndex;
    if (idx < 0 || idx >= (NSInteger)self.plans.count) return NO;
    MCPlan *plan = self.plans[idx];
    NSString *title = plan.title ?: @"";
    return [title containsString:@"永久"] || [title containsString:@"终身"] || [title containsString:@"创始"];
}

/// 本次实际购买的方案是否为永久/终身/创始人类型（非续期商品）。
/// 传入本次购买捕获的 planId（勿在清掉 pendingPlanId 后再读属性）。
- (BOOL)isPurchasedPlanLifetimeWithPlanId:(NSString *)pid {
    if (pid.length == 0) return [self isCurrentPlanLifetime]; // 兜底
    for (PNMemberPlan *plan in self.apiPlans) {
        if ([plan.planId isEqualToString:pid]) {
            return plan.durationDays == 0;
        }
    }
    // apiPlans 还没拉到（极端情况）：用本地 plans + currentIndex 兜底
    return [self isCurrentPlanLifetime];
}

- (NSString *)cardHintTextForPlan:(MCPlan *)plan {
    if (self.hasAppliedRedeemDiscount && [self isPlan:plan matchingRedeemPlanId:self.redeemPlanId]) {
        if ([self isMonthlyPlanId:plan.planId]) return @"限时优惠";
        if ([self isFounderPlanId:plan.planId]) return plan.hint ?: @"";
        return @"";
    }
    return plan.hint ?: @"";
}

- (NSString *)cardOriginalPriceTextForPlan:(MCPlan *)plan {
    if (self.hasAppliedRedeemDiscount) {
        return plan.originalPrice ?: @"";
    }
    return @"";
}

- (NSAttributedString *)cardOriginalPriceAttrTextForPlan:(MCPlan *)plan large:(BOOL)large {
    NSString *number = [self cardOriginalPriceTextForPlan:plan];
    if (number.length == 0) return nil;
    NSString *currency = plan.currencySymbol.length > 0 ? plan.currencySymbol : @"¥";
    NSString *full = [NSString stringWithFormat:@"%@%@", currency, number];
    CGFloat numberSize = large ? 16.0 : 13.0;
    CGFloat unitSize = large ? 8.0 : 6.5;
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:full attributes:@{
        NSForegroundColorAttributeName: kMCDiscountHintGray,
        NSFontAttributeName: [self membershipNeueFontOfSize:numberSize fallbackWeight:UIFontWeightRegular]
    }];
    if (currency.length > 0) {
        [attr addAttribute:NSFontAttributeName value:[self membershipNeueFontOfSize:unitSize fallbackWeight:UIFontWeightRegular]
                     range:NSMakeRange(0, currency.length)];
    }
    [attr addAttribute:NSForegroundColorAttributeName value:kMCDiscountHintGray range:NSMakeRange(0, full.length)];
    return attr;
}

- (void)refreshRedeemBannerState {
    if (self.hasAppliedRedeemDiscount) {
        self.bannerSubLabel.text = @"限时折扣码";
        self.bannerHintLabel.text = @"使用限时折扣码，解锁专属会员优惠";
        [self.redeemBtn setTitle:@"去兑换" forState:UIControlStateNormal];
    } else {
        self.bannerSubLabel.text = @"限时兑换码";
        self.bannerHintLabel.text = @"使用限时兑换码，解锁专属会员优惠";
        [self.redeemBtn setTitle:@"去兑换" forState:UIControlStateNormal];
    }
    self.bannerSubLabel.textColor = kMCDiscountMint;
    self.bannerHintLabel.textColor = kMCDiscountHintGray;
}

- (NSAttributedString *)agreementAttrText {
    // 结构：第 1 行同意条款；第 2 行弱化取消说明 + 管理订阅（续期细节已在按钮上方 subscriptionInfoLabel）
    NSString *prefix = @"开通前请阅读并同意";
    NSString *agreementText = @"《会员服务协议》";
    NSString *privacyText   = @"《隐私政策》";
    NSString *autoRenewText = @"《自动续期条款》";
    NSString *line2Prefix = @"可随时在系统设置中取消自动续期  ";
    NSString *manageLink = @"管理 Apple 订阅";
    NSString *all = [NSString stringWithFormat:@"%@%@、%@、%@\n%@%@",
                     prefix, agreementText, privacyText, autoRenewText, line2Prefix, manageLink];

    UIFont *bodyFont = [UIFont systemFontOfSize:11 weight:UIFontWeightRegular];
    UIFont *linkFont = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    UIColor *bodyColor = [UIColor colorWithWhite:0.68 alpha:1.0];
    UIColor *mutedColor = [UIColor colorWithWhite:0.48 alpha:1.0];

    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineSpacing = 4;
    style.paragraphSpacing = 2;
    style.alignment = NSTextAlignmentLeft;

    NSMutableAttributedString *m = [[NSMutableAttributedString alloc] initWithString:all attributes:@{
        NSForegroundColorAttributeName: bodyColor,
        NSFontAttributeName: bodyFont,
        NSParagraphStyleAttributeName: style
    }];

    // 第二行弱化
    NSRange rLine2 = [all rangeOfString:line2Prefix];
    if (rLine2.location != NSNotFound) {
        [m addAttributes:@{
            NSForegroundColorAttributeName: mutedColor,
            NSFontAttributeName: [UIFont systemFontOfSize:10 weight:UIFontWeightRegular]
        } range:NSMakeRange(rLine2.location, all.length - rLine2.location)];
    }

    NSDictionary *linkAttrs = @{
        NSForegroundColorAttributeName: kMCMint,
        NSFontAttributeName: linkFont,
        NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)
    };
    NSRange rAgreement = [all rangeOfString:agreementText];
    NSRange rPrivacy   = [all rangeOfString:privacyText];
    NSRange rAutoRenew = [all rangeOfString:autoRenewText];
    NSRange rManage    = [all rangeOfString:manageLink];
    if (rAgreement.location != NSNotFound) {
        [m addAttributes:linkAttrs range:rAgreement];
        [m addAttribute:NSLinkAttributeName value:kMCMembershipAgreementURL range:rAgreement];
    }
    if (rPrivacy.location != NSNotFound) {
        [m addAttributes:linkAttrs range:rPrivacy];
        [m addAttribute:NSLinkAttributeName value:kMCPrivacyPolicyURL range:rPrivacy];
    }
    if (rAutoRenew.location != NSNotFound) {
        [m addAttributes:linkAttrs range:rAutoRenew];
        [m addAttribute:NSLinkAttributeName value:kMCAutoRenewTermsURL range:rAutoRenew];
    }
    if (rManage.location != NSNotFound) {
        [m addAttributes:@{
            NSForegroundColorAttributeName: kMCMint,
            NSFontAttributeName: [UIFont systemFontOfSize:10 weight:UIFontWeightMedium],
            NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)
        } range:rManage];
        [m addAttribute:NSLinkAttributeName value:@"itms-apps://apps.apple.com/account/subscriptions" range:rManage];
    }
    return m;
}

/// 统一的应用内网页打开入口（SFSafariViewController）
- (void)openAgreementURL:(NSURL *)url {
    if (![url isKindOfClass:[NSURL class]] || !url.absoluteString.length) return;
    SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:url];
    safari.preferredControlTintColor = [UIColor colorWithRed:24/255.0 green:115/255.0 blue:1 alpha:1];
    [self presentViewController:safari animated:YES completion:nil];
}

- (void)openLegalDocumentForHost:(NSString *)host {
    if (host.length == 0) return;
    NSString *title = nil;
    NSString *resourceName = nil;
    if ([host isEqualToString:@"membership"]) {
        title = @"会员服务协议";
        resourceName = @"membership_agreement";
    } else if ([host isEqualToString:@"auto-renew"]) {
        title = @"自动续期服务条款";
        resourceName = @"auto_renew_terms";
    } else {
        return;
    }
    LegalDocumentViewController *vc = [LegalDocumentViewController documentWithTitle:title resourceName:resourceName];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)handleAgreementLinkURL:(NSURL *)URL {
    if (!URL) return;
    NSString *legalKey = [self legalDocumentKeyForURL:URL];
    if (legalKey.length) {
        [self openLegalDocumentForHost:legalKey];
        return;
    }
    NSString *scheme = URL.scheme.lowercaseString;
    if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]) {
        [self openAgreementURL:URL];
        return;
    }
    if ([URL.absoluteString isEqualToString:@"itms-apps://apps.apple.com/account/subscriptions"]) {
        [[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:nil];
    }
}

- (void)onAgreementLabelTapped:(UITapGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateEnded) return;
    UITextView *textView = self.agreementLabel;
    if (!textView.attributedText.length) return;

    CGPoint point = [gesture locationInView:textView];
    point.x -= textView.textContainerInset.left;
    point.y -= textView.textContainerInset.top;

    NSUInteger charIndex = [textView.layoutManager characterIndexForPoint:point
                                                          inTextContainer:textView.textContainer
                                 fractionOfDistanceBetweenInsertionPoints:NULL];
    if (charIndex >= textView.textStorage.length) return;

    NSRange range = NSMakeRange(0, 0);
    id linkValue = [textView.attributedText attribute:NSLinkAttributeName atIndex:charIndex effectiveRange:&range];
    if (!linkValue) return;

    NSURL *url = nil;
    if ([linkValue isKindOfClass:[NSURL class]]) {
        url = (NSURL *)linkValue;
    } else if ([linkValue isKindOfClass:[NSString class]]) {
        url = [NSURL URLWithString:(NSString *)linkValue];
    }
    [self handleAgreementLinkURL:url];
}

/// 解析应用内法律文档占位链接，如 /legal/membership
- (nullable NSString *)legalDocumentKeyForURL:(NSURL *)URL {
    if (![URL.host.lowercaseString isEqualToString:@"www.nomadfootball.cn"]) return nil;
    NSString *path = URL.path.lowercaseString;
    if ([path isEqualToString:@"/legal/membership"]) return @"membership";
    if ([path isEqualToString:@"/legal/auto-renew"]) return @"auto-renew";
    return nil;
}

- (void)applyRedeemDiscountToPlan:(MCPlan *)plan {
    if (!plan || !self.hasAppliedRedeemDiscount) return;
    if (![self isPlan:plan matchingRedeemPlanId:self.redeemPlanId]) return;

    SKProduct *discountProduct = self.redeemAppleProductId.length > 0
        ? self.skProducts[self.redeemAppleProductId] : nil;
    NSString *discountPrice = [self numericPriceStringFromProduct:discountProduct];
    if (discountPrice.length == 0) {
        discountPrice = self.redeemDiscountPrice;
    }
    if (discountPrice.length == 0) {
        NSString *pid = self.redeemPlanId ?: @"1";
        if ([pid isEqualToString:@"1"]) discountPrice = @"22";
        else if ([pid isEqualToString:@"2"]) discountPrice = @"188";
        else if ([pid isEqualToString:@"3"]) discountPrice = @"698";
    }
    if (discountPrice.length == 0) return;

    NSString *originalPrice = self.redeemOriginalPrice;
    if (originalPrice.length == 0) {
        originalPrice = plan.price;
    }
    if (plan.originalPrice.length == 0) {
        plan.originalPrice = originalPrice;
        plan.localizedOriginalPrice = plan.localizedPrice;
    }
    plan.price = discountPrice;
    plan.payPrice = discountPrice;
    NSString *discountLocalized = [self localizedPriceStringFromProduct:discountProduct];
    if (discountLocalized.length > 0) {
        plan.localizedPrice = discountLocalized;
    }
    if (discountProduct && plan.currencySymbol.length == 0) {
        plan.currencySymbol = [self currencySymbolFromProduct:discountProduct];
    }
}

- (void)buildPlanData {
    MCPlan *m = [MCPlan new];
    m.planId = @"1";
    m.title = @"连续包月";
    m.price = @"33";
    m.payPrice = @"33";
    m.originalPrice = @"";
    m.hint = @"";
    m.benefits = @[@"解锁全部内容", @"数据可视化"];
    m.benefitIcons = @[@"lock.open", @"chart.bar.fill"];

    MCPlan *y = [MCPlan new];
    y.planId = @"2";
    y.title = @"连续包年";
    y.price = @"268";
    y.payPrice = @"268";
    y.originalPrice = @"";
    y.hint = @"";
    y.benefits = @[@"解锁全部内容", @"赛季总结报告｜年度数据回顾", @"限定数字邮票|边框"];
    y.benefitIcons = @[@"lock.open", @"doc.text.fill", @"stamp.fill"];

    MCPlan *l = [MCPlan new];
    l.planId = @"3";
    l.title = @"永久权益";
    l.price = @"748";
    l.payPrice = @"748";
    l.originalPrice = @"";
    l.hint = @"";
    l.benefits = @[@"解锁全部内容，永久全部权益", @"赛季终身会员徽章", @"终身限定数字邮票|边框"];
    l.benefitIcons = @[@"lock.open", @"star.circle.fill", @"stamp.fill"];

    MCPlan *f = [MCPlan new];
    f.planId = @"4";
    f.title = @"终身权益";
    f.price = @"998";
    f.payPrice = @"998";
    f.originalPrice = @"";
    f.hint = @"限前100名";
    f.benefits = @[@"终身全部权益", @"未来产品优先体验权", @"APP 内专属编号徽章", @"创始人社群", @"限定编号球衣"];
    f.benefitIcons = @[@"trophy.fill", @"shippingbox.fill", @"number.square.fill", @"globe", @"tshirt.fill"];

    NSArray<MCPlan *> *builtPlans = @[m, y, l, f];
    [self mergeAPIPlansIntoPlans:builtPlans];

    if (self.hasAppliedRedeemDiscount) {
        for (MCPlan *plan in builtPlans) {
            [self applyRedeemDiscountToPlan:plan];
        }
    }

    self.plans = builtPlans;
}

- (void)refreshPlanInfoAtIndex:(NSInteger)idx {
    if (idx < 0 || idx >= self.plans.count) return;
    self.currentIndex = idx;
    MCPlan *plan = self.plans[idx];
    self.planTitleLabel.text = [self displayTitleForPlan:plan];
    [self updatePayButtonPresentationForPlan:plan];
    self.pageControl.currentPage = idx;
    [self updatePayButtonState];
}

- (void)reloadPlanCardsPreservingIndex {
    NSInteger targetIndex = MAX(0, MIN(self.currentIndex, (NSInteger)self.plans.count - 1));
    [self buildPlanData];

    NSMutableArray<UIView *> *cards = [NSMutableArray array];
    [self.cardViews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    UIView *prev = nil;
    for (NSInteger i = 0; i < self.plans.count; i++) {
        UIView *card = [self buildPlanCard:self.plans[i] large:YES];
        [self.cardContentView addSubview:card];
        [cards addObject:card];
        [card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(self.cardContentView);
            make.width.mas_equalTo(210);
            if (prev) make.leading.equalTo(prev.mas_trailing).offset(12);
            else make.leading.equalTo(self.cardContentView).offset(82);
            if (i == self.plans.count - 1) make.trailing.equalTo(self.cardContentView).offset(-82);
        }];
        prev = card;
    }

    self.cardViews = cards;
    self.pageControl.numberOfPages = self.plans.count;
    [self applyPlanAtIndex:targetIndex animated:NO];
}

- (void)applyPlanAtIndex:(NSInteger)idx animated:(BOOL)animated {
    if (idx < 0 || idx >= self.plans.count) return;
    [self refreshPlanInfoAtIndex:idx];
    [self updateCardScaleAtIndex:idx animated:animated];

    CGFloat pageW = 222.0;
    CGFloat target = idx * pageW;
    [self.cardScrollView setContentOffset:CGPointMake(target, 0) animated:animated];
}

- (void)updateCardScaleAtIndex:(NSInteger)idx animated:(BOOL)animated {
    [self.cardViews enumerateObjectsUsingBlock:^(UIView * _Nonnull card, NSUInteger i, BOOL * _Nonnull stop) {
        CGFloat scale = (i == (NSUInteger)idx) ? 1.0 : 0.75;
        CGAffineTransform transform = CGAffineTransformMakeScale(scale, scale);
        if (animated) {
            [UIView animateWithDuration:0.22 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                card.transform = transform;
            } completion:nil];
        } else {
            card.transform = transform;
        }
    }];
}

- (void)updateCardInteractiveScaleForOffset:(CGFloat)offsetX {
    CGFloat pageW = 222.0;
    CGFloat floatingIndex = MAX(0, MIN((CGFloat)(self.plans.count - 1), offsetX / pageW));
    [self.cardViews enumerateObjectsUsingBlock:^(UIView * _Nonnull card, NSUInteger i, BOOL * _Nonnull stop) {
        CGFloat dist = fabs((CGFloat)i - floatingIndex);
        CGFloat normalized = MIN(1.0, dist);
        CGFloat scale = 1.0 - 0.25 * normalized; // 1.0 -> 0.75
        card.transform = CGAffineTransformMakeScale(scale, scale);
    }];
}

- (void)onBack {
    // 购买 / 恢复进行中时拦截返回，避免中断支付流程让用户对扣款状态产生困惑。
    if (self.payInFlight || self.restoreInFlight) {
        UIAlertController *alert = [UIAlertController
            alertControllerWithTitle:@"支付进行中"
                             message:@"当前有支付或恢复流程正在进行，离开可能导致会员激活失败。确认离开吗？"
                      preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"继续等待" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"确认离开" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self.navigationController popViewControllerAnimated:YES];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onTapHelp {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"会员说明"
                                                                   message:@"可左右滑动查看月度/赛季/终身/创始人方案，勾选协议后可继续支付。"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)onTapRedeemFromBanner {
    [self showRedeemDialog];
}

- (void)onTapSubscribeTab {
    [self switchToGiftMode:NO];
}

- (void)onTapGiftTab {
    [self switchToGiftMode:YES];
}

- (void)showRedeemDialog {
    self.redeemDialogShowingSuccess = NO;
    [self.view bringSubviewToFront:self.redeemOverlayView];
    self.redeemOverlayView.hidden = NO;
    self.redeemInputField.text = @"";
    self.redeemHelpLabel.hidden = YES;
    self.redeemInputWrapView.hidden = NO;
    self.redeemDialogTicketIconView.hidden = NO;
    self.redeemSuccessWrapView.hidden = YES;
    self.redeemSuccessTitleLabel.hidden = YES;
    self.redeemSuccessDescLabel.hidden = YES;
    [self updateRedeemDialogForInput];
    [self.redeemInputField becomeFirstResponder];
}

- (void)hideRedeemDialog {
    [self.view endEditing:YES];
    self.redeemOverlayView.hidden = YES;
}

- (NSString *)normalizedRedeemInput:(NSString *)raw {
    NSString *trimmed = [raw ?: @"" stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    trimmed = [trimmed uppercaseString];
    // 仅保留 A-Z / 0-9，兼容邀请码（12 位字母数字）与原兑换码
    NSMutableString *code = [NSMutableString stringWithCapacity:trimmed.length];
    for (NSUInteger i = 0; i < trimmed.length; i++) {
        unichar c = [trimmed characterAtIndex:i];
        if ((c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9')) {
            [code appendFormat:@"%C", c];
        }
    }
    if (code.length > 12) {
        return [code substringToIndex:12];
    }
    return [code copy];
}

- (BOOL)isRedeemCodeReadyToSubmit:(NSString *)code {
    // 邀请码固定 12 位；历史兑换码多为 5 位数字
    return code.length == 12 || code.length == 5;
}

- (void)onRedeemDialogInputChanged {
    NSString *code = [self normalizedRedeemInput:self.redeemInputField.text];
    if (![code isEqualToString:self.redeemInputField.text ?: @""]) {
        self.redeemInputField.text = code;
    }
    [self updateRedeemDialogForInput];
}

- (void)updateRedeemDialogForInput {
    NSString *code = self.redeemInputField.text ?: @"";
    BOOL hasInput = code.length > 0;
    [self applyRedeemHelpLabelStyle];
    self.redeemHelpLabel.hidden = !hasInput;
    self.redeemConfirmBtn.alpha = [self isRedeemCodeReadyToSubmit:code] ? 1.0 : 0.88;
}

- (void)applyRedeemHelpLabelStyle {
    NSString *text = self.redeemHelpLabel.text ?: @"";
    NSMutableAttributedString *helpAttr = [[NSMutableAttributedString alloc] initWithString:text attributes:@{
        NSForegroundColorAttributeName: [UIColor colorWithRed:219/255.0 green:219/255.0 blue:219/255.0 alpha:1.0] // #DBDBDB
    }];
    NSRange failRange = [text rangeOfString:@"兑换失败"];
    if (failRange.location != NSNotFound) {
        [helpAttr addAttributes:@{
            NSForegroundColorAttributeName: [UIColor colorWithRed:147/255.0 green:205/255.0 blue:1.0 alpha:1.0], // #93CDFF
            NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)
        } range:failRange];
    }
    NSRange helpRange = [text rangeOfString:@"点击寻求帮助"];
    if (helpRange.location == NSNotFound) {
        helpRange = [text rangeOfString:@"点此寻求帮助"];
    }
    if (helpRange.location != NSNotFound) {
        [helpAttr addAttribute:NSForegroundColorAttributeName
                         value:[UIColor colorWithRed:219/255.0 green:219/255.0 blue:219/255.0 alpha:1.0] // #DBDBDB
                         range:helpRange];
    }
    self.redeemHelpLabel.attributedText = helpAttr;
}

- (NSString *)displayDateText:(NSString *)raw {
    if (raw.length == 0) return @"";
    // 兼容 "2026-07-15T10:00:00" / "2026-07-15 10:00:00"
    NSString *normalized = [[raw stringByReplacingOccurrencesOfString:@"T" withString:@" "] componentsSeparatedByString:@"."].firstObject;
    if (normalized.length >= 16) {
        return [normalized substringToIndex:16];
    }
    return normalized ?: raw;
}

- (void)showRedeemDialogSuccessWithTitle:(NSString *)title desc:(NSString *)desc autoHide:(BOOL)autoHide {
    self.redeemDialogShowingSuccess = YES;
    self.redeemDialogTicketIconView.hidden = YES;
    self.redeemInputWrapView.hidden = YES;
    self.redeemHelpLabel.hidden = YES;
    self.redeemSuccessWrapView.hidden = NO;
    self.redeemSuccessTitleLabel.hidden = NO;
    self.redeemSuccessDescLabel.hidden = NO;
    self.redeemSuccessTitleLabel.text = title.length ? title : @"兑换成功！";
    self.redeemSuccessDescLabel.text = desc.length ? desc : @"";
    self.redeemSuccessDescLabel.numberOfLines = 0;
    self.redeemSuccessDescLabel.textAlignment = NSTextAlignmentCenter;
    if (autoHide) {
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (weakSelf.redeemDialogShowingSuccess) {
                [weakSelf hideRedeemDialog];
            }
        });
    }
}

- (void)onTapRedeemDialogConfirm {
    // IAP 硬约束：兑换码激活/折扣购买都需登录态（服务端用 userId 关联会员/兑换码使用记录）
    if (![AuthManager sharedManager].isLoggedIn) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"请先登录"
                                                                       message:@"兑换会员需要先登录"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"去登录" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            Class loginClass = NSClassFromString(@"LoginChoiceViewController");
            if (!loginClass) return;
            UIViewController *loginVC = [loginClass new];
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginVC];
            nav.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:nav animated:YES completion:nil];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    NSString *code = [self normalizedRedeemInput:self.redeemInputField.text];
    self.redeemInputField.text = code;
    if (![self isRedeemCodeReadyToSubmit:code]) {
        // 长度不符合（邀请码 12 位 / 历史兑换码 5 位）时给用户明确提示，
        // 而不是静默 return 让用户以为按钮坏了
        NSString *tip = code.length == 0
            ? (NSLocalizedString(@"redeem_code_empty", nil) ?: @"请输入兑换码")
            : (NSLocalizedString(@"redeem_code_format_invalid", nil) ?: @"兑换码格式不正确，请检查后重试");
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = tip;
        hud.removeFromSuperViewOnHide = YES;
        [hud hideAnimated:YES afterDelay:1.6];
        return;
    }
    [self.view endEditing:YES];

    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    __weak typeof(self) weakSelf = self;
    [[MembershipRequest shared] redeemCodeWithBody:@{@"code": code} success:^(HTTPResponse * _Nullable responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
            id raw = responseObject.dataObject ?: responseObject.data;
            PNRedeemResult *result = [PNRedeemResult yy_modelWithJSON:raw];
            NSLog(@"[Redeem] codeType=%@ needPayment=%@ appleProductId=%@ planId=%@",
                  result.codeType, result.needPayment ? @"YES" : @"NO", result.appleProductId, result.planId);

            if (!result.needPayment) {
                // 免费码（GIFT / 免费 INVITE）：服务端已直接激活会员
                weakSelf.hasAppliedRedeemDiscount = NO;
                weakSelf.pendingRedeemCode = nil;
                weakSelf.redeemAppleProductId = nil;
                weakSelf.redeemPlanId = nil;
                weakSelf.redeemOriginalPrice = nil;
                weakSelf.redeemDiscountPrice = nil;
                NSMutableString *desc = [NSMutableString stringWithString:@"会员权益已激活"];
                NSString *activateText = [weakSelf displayDateText:result.activateTime];
                NSString *expireText = [weakSelf displayDateText:result.expireTime];
                if (activateText.length > 0) {
                    [desc appendFormat:@"\n激活时间：%@", activateText];
                }
                if (expireText.length > 0) {
                    [desc appendFormat:@"\n到期时间：%@", expireText];
                } else if (result.durationDays == 0 &&
                           ([result.codeType isEqualToString:@"INVITE_CODE"] || [result.codeType isEqualToString:@"GIFT_CODE"])) {
                    [desc appendString:@"\n到期时间：永久"];
                }
                [weakSelf applyMembershipActivationFromRedeemResult:result];
                [weakSelf showRedeemDialogSuccessWithTitle:@"激活成功！" desc:desc autoHide:YES];
                [weakSelf switchToGiftMode:NO];
                [weakSelf loadRemoteDataWithForce:YES];
                [weakSelf refreshMembershipStatusForce];
                [weakSelf refreshRedeemBannerState];
                return;
            }

            // 付费码（EXCHANGE / 付费 INVITE）：记录商品信息，引导走 Apple IAP
            if (result.appleProductId.length == 0) {
                weakSelf.redeemHelpLabel.text = @"该兑换码配置异常，请联系客服 点击寻求帮助";
                weakSelf.redeemHelpLabel.hidden = NO;
                [weakSelf applyRedeemHelpLabelStyle];
                return;
            }
            weakSelf.hasAppliedRedeemDiscount = YES;
            weakSelf.pendingRedeemCode = code;
            NSString *paidDesc = [result.codeType isEqualToString:@"INVITE_CODE"]
                ? @"请继续完成支付以激活会员权益"
                : @"折扣已应用到相应会员订阅中";
            [weakSelf showRedeemDialogSuccessWithTitle:@"兑换成功！" desc:paidDesc autoHide:YES];
            [weakSelf applyPaidRedeemResult:result code:code];
        });
    } failure:^(NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
            NSString *msg = @"兑换失败";
            if ([error isKindOfClass:[APIError class]]) {
                msg = [(APIError *)error displayMessageWithFallback:msg];
            } else if (error.localizedDescription.length > 0) {
                msg = error.localizedDescription;
            }
            weakSelf.redeemHelpLabel.text = [NSString stringWithFormat:@"%@ 点击寻求帮助", msg];
            weakSelf.redeemHelpLabel.hidden = NO;
            [weakSelf applyRedeemHelpLabelStyle];
        });
    }];
}

- (void)switchToGiftMode:(BOOL)giftMode {
    BOOL wasGiftMode = self.showingGiftCode;
    self.showingGiftCode = giftMode;
    UIColor *activeBg = [UIColor colorWithRed:40/255.0 green:93/255.0 blue:75/255.0 alpha:0.48];
    UIColor *inactiveBg = [UIColor blackColor];
    self.subscribeTabBtn.backgroundColor = giftMode ? inactiveBg : activeBg;
    self.giftTabBtn.backgroundColor = giftMode ? activeBg : inactiveBg;

    self.planTitleLabel.hidden = giftMode;
    self.cardScrollView.hidden = giftMode;
    self.pageControl.hidden = giftMode;
    self.payBtn.hidden = giftMode;
    self.agreementCheckBtn.hidden = giftMode;
    self.agreementLabel.hidden = giftMode;
    self.restoreBtn.hidden = giftMode;
    self.subscriptionInfoLabel.hidden = giftMode;
    self.giftContainerView.hidden = !giftMode;
    if (giftMode) {
        // 切到礼包码时收掉 IAP「开通成功」（延迟回调可能已 present，避免盖在礼包页上）
        UIViewController *presented = self.presentedViewController;
        if ([presented isKindOfClass:[UIAlertController class]]) {
            NSString *title = [(UIAlertController *)presented title] ?: @"";
            if ([title containsString:@"开通成功"]) {
                [presented dismissViewControllerAnimated:NO completion:nil];
            }
        }
        if (!wasGiftMode) {
            [self resetGiftCodeUI];
        }
        [self.view bringSubviewToFront:self.giftContainerView];
        if (self.giftSuccessWrap.hidden) {
            [self.giftHiddenInput becomeFirstResponder];
        }
    } else {
        [self.view endEditing:YES];
    }
}

- (void)updatePayButtonState {
    // 注意：不能把 payBtn.enabled 直接绑死在 agreementCheckBtn.selected 上，
    // 否则未勾选协议时按钮禁用、收不到 TouchUpInside，onTapPay 开头的
    // 「请先勾选协议」弹窗就永远走不到。这里只改透明度做视觉提示，点击拦截交给 onTapPay。
    BOOL priceReady = [self isStoreKitPriceReadyForPlanIndex:self.currentIndex];
    BOOL visuallyEnabled = self.agreementCheckBtn.selected && !self.payInFlight && priceReady;
    self.payBtn.enabled = YES; // 始终可点击，让 onTapPay 能统一处理校验逻辑
    self.payBtn.alpha = visuallyEnabled ? 1.0 : 0.55;
    // 同步禁用 / 启用系统侧滑返回手势，避免购买进行中用户从边缘滑动中断支付。
    // 与 onBack 中的拦截一起构成完整的「支付保护」。
    UIGestureRecognizer *popGesture = self.navigationController.interactivePopGestureRecognizer;
    BOOL shouldBlockBack = self.payInFlight || self.restoreInFlight;
    if (popGesture && popGesture.enabled == shouldBlockBack) {
        popGesture.enabled = !shouldBlockBack;
    }
}

- (void)onTapPay {
    // IAP 支付硬约束：购买必须登录态。
    // 入口已拦截（Profile/StampAlbum），这里做兜底：用户进入会员中心后 logout、token 过期等场景。
    // 服务端 verifyAndActivate 会校验 JWT，未登录返回 401，但 Apple 支付已经发起无法回滚，
    // 用户付了款却拿不到会员，所以必须在 addPayment 之前拦截。
    if (![AuthManager sharedManager].isLoggedIn) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"请先登录"
                                                                       message:@"开通会员需要先登录，登录后可继续完成支付"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"去登录" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            Class loginClass = NSClassFromString(@"LoginChoiceViewController");
            if (!loginClass) return;
            UIViewController *loginVC = [loginClass new];
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginVC];
            nav.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:nav animated:YES completion:nil];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    // 支付进行中拦截：按钮现在始终 enabled（为了能弹「请先勾选协议」），
    // 所以必须在入口显式拦截 payInFlight，避免连点触发重复购买。
    // 同时拦截 restoreInFlight：restore 进行中再发起购买会让 SKPaymentQueue 状态混乱
    //（同时有 restore 和 payment 在跑），Apple 行为未定义。
    if (self.payInFlight || self.restoreInFlight) {
        return;
    }
    if (![self isStoreKitPriceReadyForPlanIndex:self.currentIndex]) {
        NSString *msg = (self.preloadProductsRequest != nil || self.loadingRemoteData)
            ? @"正在从 App Store 获取价格，请稍后再试"
            : @"暂无法获取 App Store 价格，请检查网络后重试";
        [[LoadingManager sharedManager] showError:msg inView:self.view];
        return;
    }
    if (!self.agreementCheckBtn.selected) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                       message:@"请先勾选《会员服务协议》"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }

    // 场景 3.1.5：已是会员再次购买 → 二次确认，避免误触重复扣费（仍允许续费/升级）。
    if (self.membershipStatus.isMember) {
        BOOL isLifetime = (self.membershipStatus.expireTime.length == 0);
        NSString *message = isLifetime
            ? @"您已是永久会员，再次购买将按所选方案额外扣费。确认继续？"
            : @"您当前已是会员，继续购买将延长或升级会员权益。确认继续？";
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"您已是会员"
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        __weak typeof(self) weakSelf = self;
        [alert addAction:[UIAlertAction actionWithTitle:@"继续购买" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf continuePayAfterChecks];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }

    [self continuePayAfterChecks];
}

/// 协议/登录/会员确认通过后的实际拉起支付逻辑
- (void)continuePayAfterChecks {
    // 找到当前方案对应的 appleProductId 和 planId
    // 按 planId 升序排列（1=月, 2=年, 3=永久, 4=创始人），与本地 plans 数组顺序一致
    NSString *appleProductId = nil;
    NSString *planId = nil;

    // 折扣场景：仅当当前选中卡就是兑换码对应方案时，才用折扣商品 ID
    NSArray<NSString *> *expectedPlanIds = @[ @"1", @"2", @"3", @"4" ];
    NSString *selectedPlanId = (self.currentIndex >= 0 && self.currentIndex < (NSInteger)expectedPlanIds.count)
        ? expectedPlanIds[self.currentIndex] : nil;
    BOOL useRedeemDiscount = self.hasAppliedRedeemDiscount
        && self.redeemAppleProductId.length > 0
        && selectedPlanId.length > 0
        && (self.redeemPlanId.length == 0 || [self.redeemPlanId isEqualToString:selectedPlanId]);

    if (useRedeemDiscount) {
        appleProductId = self.redeemAppleProductId;
        planId = self.redeemPlanId.length ? self.redeemPlanId : selectedPlanId;
    } else if (self.apiPlans.count > 0) {
        NSString *expectedPlanId = selectedPlanId;
        PNMemberPlan *target = nil;
        // 优先按 planId 精确匹配，避免服务端返回顺序/缺项导致 index 对错方案。
        if (expectedPlanId.length > 0) {
            for (PNMemberPlan *p in self.apiPlans) {
                if ([p.planId isEqualToString:expectedPlanId]) {
                    target = p;
                    break;
                }
            }
        }
        // 兜底：仍使用按 planId 排序后的同 index 项。
        if (!target) {
            NSArray<PNMemberPlan *> *sorted = [self.apiPlans sortedArrayUsingComparator:^NSComparisonResult(PNMemberPlan *a, PNMemberPlan *b) {
                return [a.planId compare:b.planId options:NSNumericSearch];
            }];
            if ((NSUInteger)self.currentIndex < sorted.count) {
                target = sorted[self.currentIndex];
            }
        }
        if (target) {
            appleProductId = target.appleProductId;
            planId = target.planId;
        }
    }

    appleProductId = [appleProductId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (appleProductId.length == 0) {
        [[LoadingManager sharedManager] showError:@"该方案暂不支持购买" inView:self.view];
        return;
    }

    if (![SKPaymentQueue canMakePayments]) {
        [[LoadingManager sharedManager] showError:@"当前设备不支持应用内购买，请检查家长控制设置" inView:self.view];
        return;
    }

    if (self.payInFlight) {
        return;
    }

    self.pendingPlanId = planId;
    // 关键：payInFlight 必须在 startPaymentWithProduct / fetchProductAndPay 调用前就置 YES，
    // 否则当 skProducts 已缓存（第二次进入 / restore 之后）会走 startPaymentWithProduct 分支
    // 直接跳过 fetchProductAndPay 里的 payInFlight=YES 设置，导致：
    // (1) updatePayButtonState 不会禁用侧滑返回手势，用户可在支付中滑动中断
    // (2) 用户快速连点支付按钮会触发重复 SKPayment
    self.payInFlight = YES;
    [self updatePayButtonState];

    // 如果已缓存该产品，直接发起购买；否则先向 App Store 请求产品信息
    SKProduct *cachedProduct = self.skProducts[appleProductId];
    if (cachedProduct) {
        [self startPaymentWithProduct:cachedProduct];
    } else {
        [self fetchProductAndPay:appleProductId];
    }
}

/// 向 App Store 请求产品信息，成功后发起购买
- (void)fetchProductAndPay:(NSString *)productId {
    productId = [productId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (productId.length == 0) {
        [[LoadingManager sharedManager] showError:@"商品标识无效，请稍后重试" inView:self.view];
        return;
    }
    // 注意：不能在此处再检查/设置 payInFlight。
    // onTapPay 在调用本方法之前就已经把 payInFlight 置为 YES（见 onTapPay 注释），
    // 这里再检查 payInFlight 会立即 return，导致首次进入（skProducts 无缓存）的购买流程
    // 永远走不通——SKProductsRequest 根本不会被 start，回调当然不会来。
    self.payBtn.enabled = NO;
    // cancel 不会走 didFail，先清掉可能残留的 HUD，避免叠层卡死
    [self.productsRequest cancel];
    [MBProgressHUD hideHUDForView:self.view animated:NO];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:productId]];
    self.productsRequest.delegate = self;
    [self.productsRequest start];
}

/// 拿到 SKProduct 后发起支付
- (void)startPaymentWithProduct:(SKProduct *)product {
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
    payment.quantity = 1;
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 缓存所有返回的产品（预拉价 + 购买链路共用）
        for (SKProduct *product in response.products) {
            self.skProducts[product.productIdentifier] = product;
        }
        NSLog(@"[IAP] products=%@, invalidProductIdentifiers=%@",
              [response.products valueForKey:@"productIdentifier"],
              response.invalidProductIdentifiers);

        // 预拉取价格：只刷新 UI，不发起支付
        if (request == self.preloadProductsRequest) {
            self.preloadProductsRequest = nil;
            [self refreshUIAfterSKProductPricesApplied];
            return;
        }

        [MBProgressHUD hideHUDForView:self.view animated:YES];
        // 注意：这里不能重置 payInFlight=NO！F1 修复后 onTapPay 在调用 fetchProductAndPay
        // 之前就置 payInFlight=YES，拉到商品后立即进入 startPaymentWithProduct，
        // 整个购买流程仍未结束。如果这里清掉，到 SKPayment 入队之间用户连点会触发重复购买。
        // payInFlight 的清零由 SKPaymentTransactionObserver 的 Failed/Purchased 分支负责。
        [self updatePayButtonState];
        // 购买链路返回的商品也同步刷新一次展示价
        [self applySKProductPricesToPlans:self.plans];
        [self refreshPlanInfoAtIndex:self.currentIndex];
        if (response.products.count == 0) {
            // 商品无效：才算真正的流程结束，清 payInFlight 让用户可以重试
            self.payInFlight = NO;
            [self updatePayButtonState];
            [[LoadingManager sharedManager] showError:@"未找到对应商品，请稍后重试" inView:self.view];
            return;
        }
        [self startPaymentWithProduct:response.products.firstObject];
    });
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (request == self.preloadProductsRequest) {
            self.preloadProductsRequest = nil;
            NSLog(@"[IAP] preload SKProducts failed: %@", error.localizedDescription);
            [self refreshPlanInfoAtIndex:self.currentIndex];
            return;
        }
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        self.payInFlight = NO;
        [self updatePayButtonState];
        NSString *msg = error.localizedDescription ?: @"获取商品信息失败，请稍后重试";
        [[LoadingManager sharedManager] showError:msg inView:self.view];
    });
}

#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing: {
                // 礼包码页不展示购买 loading（多为队列残留，非本页发起）
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.showingGiftCode) { return; }
                    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                });
                break;
            }

            case SKPaymentTransactionStatePurchased: {
                // 购买成功，上报服务端验证
                [self handlePurchasedTransaction:transaction];
                break;
            }

            case SKPaymentTransactionStateRestored: {
                // 恢复购买：上报服务端做幂等查询，命中则激活/返回会员信息
                [self handleRestoredTransaction:transaction];
                break;
            }

            case SKPaymentTransactionStateFailed: {
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                    // 支付失败必须重置 payInFlight，否则用户再次点击支付会被 onTapPay 的
                    // 防连点拦截，导致本次会话永远无法再次发起购买（必须重启 App）。
                    self.payInFlight = NO;
                    // 清理本次购买上下文（兑换码 / 折扣商品 ID），避免下次普通购买时
                    // 误带 redeemCode 导致服务端走兑换码激活分支，用错的兑换码激活会员。
                    // 必须与其他 success/failure 分支清理的字段保持一致（5 字段全清）。
                    self.pendingPlanId = nil;
                    self.pendingRedeemCode = nil;
                    self.hasAppliedRedeemDiscount = NO;
                    self.redeemAppleProductId = nil;
                    self.redeemPlanId = nil;
                    self.redeemOriginalPrice = nil;
                    self.redeemDiscountPrice = nil;
                    [self updatePayButtonState]; // 同步恢复侧滑返回手势
                    // 礼包码页不打扰用户（可能是后台残留事务失败）
                    // 此处在 dispatch_async block 内，不能用 break（不在 loop/switch 中），用 return 提前结束 block。
                    if (self.showingGiftCode) {
                        return;
                    }
                    if (transaction.error.code == SKErrorPaymentCancelled) {
                        [[LoadingManager sharedManager] showError:@"支付已取消，可重试" inView:self.view];
                    } else {
                        NSString *msg = transaction.error.localizedDescription ?: @"购买失败，请稍后重试";
                        [[LoadingManager sharedManager] showError:msg inView:self.view];
                    }
                });
                break;
            }

            case SKPaymentTransactionStateDeferred: {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                    self.payInFlight = NO;
                    [self updatePayButtonState];
                    [[LoadingManager sharedManager] showError:@"购买待审批，请等待家长确认" inView:self.view];
                });
                break;
            }

            default:
                break;
        }
    }
}

/// 本会话已提交过 verify 的 Apple transactionId（进程级，防 StoreKit 重复回调 / 重进页面二次上报）
static NSMutableSet<NSString *> *PNSubmittedVerifyTxnIds(void) {
    static NSMutableSet<NSString *> *set;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        set = [NSMutableSet set];
    });
    return set;
}

/// 购买成功后，将 transactionId 和 signedTransaction 上报服务端验证
- (void)handlePurchasedTransaction:(SKPaymentTransaction *)transaction {
    NSString *transactionId = transaction.transactionIdentifier ?: @"";
    if (transactionId.length == 0) {
        return;
    }
    // StoreKit 会在 finish 前多次回调同一笔 Purchased；首笔成功后 pendingPlanId 已清空，
    // 若再次走「购买」路径会传空 planId → 服务端 @NotNull「planId不能为空」。
    if ([PNSubmittedVerifyTxnIds() containsObject:transactionId]) {
        NSLog(@"[IAP] 跳过重复 Purchased 回调: txnId=%@", transactionId);
        return;
    }
    [PNSubmittedVerifyTxnIds() addObject:transactionId];

    // 上报内容选择策略（修复 StoreKit 版本不匹配阻塞）：
    // - iOS 15+: 优先取 VerificationResult.jwsRepresentation（真正 JWS）
    // - 未命中：退回 SK1 appStoreReceiptURL base64
    // 本地立刻捕获 planId / redeemCode，避免异步回调时 pending 已被成功分支清空。
    //
    // 关键：只有「本页点过支付」留下的 pendingPlanId 才算用户主动购买，才弹「开通成功」。
    // 队列残留 / 重放事务即使能从 productId 反查出 planId，也一律走 restore 补单且不弹窗，
    // 否则用户只停在礼包码 Tab 也会被延迟回调打断。
    NSString *pendingPlanId = [self.pendingPlanId copy] ?: @"";
    NSString *redeemCode = [self.pendingRedeemCode copy] ?: @"";
    // 仅「点过支付留下的 pending」算主动购买；礼包页即使还有 pending 也不弹开通成功
    BOOL userInitiatedPurchase = (pendingPlanId.length > 0);
    NSString *planId = pendingPlanId;
    if (planId.length == 0) {
        NSString *productId = transaction.payment.productIdentifier ?: @"";
        planId = [self planIdForAppleProductId:productId] ?: @"";
    }
    // 队列残留（无 pending）：restore 补单。主动购买仍走购买分支。
    BOOL asRestore = !userInitiatedPurchase || (planId.length == 0);
    BOOL allowSuccessUI = userInitiatedPurchase && !asRestore && !self.showingGiftCode;
    __weak typeof(self) weakSelf = self;

    void (^submitWithSignedTransaction)(NSString *) = ^(NSString *signedTransaction) {
        NSMutableDictionary *body = [@{
            @"transactionId": transactionId,
            @"signedTransaction": signedTransaction ?: @"",
            @"planId": asRestore ? @(0) : @([planId longLongValue]),
            @"agreementAccepted": asRestore ? @NO : @YES,
            @"restore": @(asRestore)
        } mutableCopy];
        if (!asRestore && redeemCode.length > 0) {
            body[@"redeemCode"] = redeemCode;
        }
        if (asRestore || !allowSuccessUI) {
            NSLog(@"[IAP] Purchased 静默补单/不弹窗: txnId=%@ product=%@ gift=%d pending=%@ restore=%d",
                  transactionId,
                  transaction.payment.productIdentifier ?: @"",
                  (int)weakSelf.showingGiftCode,
                  pendingPlanId,
                  (int)asRestore);
        }
        [weakSelf submitPurchaseVerification:body
                                 transaction:transaction
                              purchasedPlanId:(allowSuccessUI ? planId : nil)];
    };

    if ([PNIAPSK2Bridge isAvailable]) {
        [PNIAPSK2Bridge currentJWSForTransactionId:transactionId completion:^(PNIAPSK2Result * _Nullable result) {
            // JWS 必须是 header.payload.signature 三段式；否则视为未命中，回退 SK1 收据
            NSString *jws = result.jwsRepresentation ?: @"";
            NSUInteger dotCount = [[jws componentsSeparatedByString:@"."] count];
            if (jws.length > 0 && dotCount >= 3) {
                NSLog(@"[IAP] 使用 SK2 JWS 上报（iOS 15+）: txnId=%@", transactionId);
                submitWithSignedTransaction(jws);
            } else {
                NSLog(@"[IAP] SK2 JWS 未命中或格式非法(dots=%lu)，回退到 SK1 收据: txnId=%@",
                      (unsigned long)dotCount, transactionId);
                submitWithSignedTransaction([weakSelf currentReceiptBase64]);
            }
        }];
    } else {
        submitWithSignedTransaction([self currentReceiptBase64]);
    }
}

/// 本会话已弹出过「开通成功」的 transactionId（进程级，防延迟回调重复弹窗）
static NSMutableSet<NSString *> *PNShownPurchaseSuccessTxnIds(void) {
    static NSMutableSet<NSString *> *set;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        set = [NSMutableSet set];
    });
    return set;
}

/// 实际上报 verifyPurchase 的统一入口（SK2 JWS 路径与 SK1 receipt 路径共用）
/// @param purchasedPlanId 本次用户主动购买的方案（restore 补单传 nil，不弹「开通成功」）
- (void)submitPurchaseVerification:(NSDictionary *)body
                       transaction:(SKPaymentTransaction *)transaction
                    purchasedPlanId:(NSString *)purchasedPlanId {
    __weak typeof(self) weakSelf = self;
    BOOL showPurchaseSuccessUI = (purchasedPlanId.length > 0);
    NSString *txnId = transaction.transactionIdentifier ?: (body[@"transactionId"] ?: @"");
    [[MembershipRequest shared] verifyPurchaseWithBody:body success:^(HTTPResponse * _Nullable responseObject) {
        // 服务端验证成功，结束事务
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!weakSelf) { return; }
            [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
            weakSelf.payInFlight = NO;
            [weakSelf updatePayButtonState];
            // 先刷新会员状态（到期日 banner）；不要紧接着调 refreshRedeemBannerState，
            // 否则会把「会员有效期至 xxx」盖回「限时兑换码」。
            [weakSelf loadRemoteDataWithForce:YES];
            [weakSelf refreshMembershipStatusForce];
            // 无论是否弹窗，成功后都清购买上下文，避免礼包页静默成功后 pending 残留再弹窗
            weakSelf.pendingPlanId = nil;
            weakSelf.pendingRedeemCode = nil;
            weakSelf.hasAppliedRedeemDiscount = NO;
            weakSelf.redeemAppleProductId = nil;
            weakSelf.redeemPlanId = nil;
            weakSelf.redeemOriginalPrice = nil;
            weakSelf.redeemDiscountPrice = nil;
            if (!showPurchaseSuccessUI) {
                return;
            }

            // 同一笔 txn 只弹一次成功；延迟重复回调 / 并发 verify 不再弹窗
            if (txnId.length > 0 && [PNShownPurchaseSuccessTxnIds() containsObject:txnId]) {
                NSLog(@"[IAP] 跳过重复开通成功弹窗: txnId=%@", txnId);
                return;
            }
            if (txnId.length > 0) {
                [PNShownPurchaseSuccessTxnIds() addObject:txnId];
            }
            // 礼包码 Tab / 页面不可见 / 已有弹窗：只静默刷新，不弹「开通成功」
            // （用户切到礼包码后，延迟的 IAP 回调不应再打断当前页）
            if (weakSelf.showingGiftCode || weakSelf.view.window == nil || weakSelf.presentedViewController != nil) {
                NSLog(@"[IAP] 跳过开通成功 UI: gift=%d window=%d presented=%d txnId=%@",
                      (int)weakSelf.showingGiftCode,
                      (int)(weakSelf.view.window != nil),
                      (int)(weakSelf.presentedViewController != nil),
                      txnId);
                return;
            }

            BOOL isLifetime = [weakSelf isPurchasedPlanLifetimeWithPlanId:purchasedPlanId];
            NSString *title = @"开通成功";
            NSString *message = isLifetime
                ? @"永久会员已激活，感谢您的支持，尽情享受全部权益！"
                : @"会员权益已激活，尽情享受吧！";
            if ([weakSelf isAppStoreSandbox]) {
                title = @"开通成功（测试环境）";
                message = isLifetime
                    ? @"当前为 App Store 沙箱环境购买，不会真实扣款。永久会员已激活。"
                    : @"当前为 App Store 沙箱环境购买，不会真实扣款。会员权益已激活。";
            }
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [weakSelf.navigationController popViewControllerAnimated:YES];
            }]];
            [weakSelf presentViewController:alert animated:YES completion:nil];
        });
    } failure:^(NSError * _Nonnull error) {
        // 服务端验证失败处理策略：
        // - 仍要 finish 事务：保留事务不 finish 会让 StoreKit 队列堆积（Apple 阈值约 50 笔），
        //   一旦超限所有新支付都会被 StoreKit 拒绝。改为 finish + 详细日志，由客服对账兜底。
        // - 清理本地支付状态（payInFlight），否则用户再点支付会被拦截。
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        NSLog(@"[IAP][严重] 购买验证失败已 finish，请人工对账: txnId=%@, planId=%@, err=%@",
              transaction.transactionIdentifier ?: @"", purchasedPlanId ?: body[@"planId"], error);
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
            weakSelf.payInFlight = NO;
            [weakSelf updatePayButtonState];
            // 补单失败 / 礼包码页：不弹「验证失败」
            if (!showPurchaseSuccessUI || weakSelf.showingGiftCode) {
                NSLog(@"[IAP] verify 失败（不弹窗）gift=%d: %@", (int)weakSelf.showingGiftCode, error);
                return;
            }
            NSString *msg = @"购买成功，但服务器验证失败，请联系客服处理";
            if ([error isKindOfClass:[APIError class]]) {
                msg = [(APIError *)error displayMessageWithFallback:msg];
            }
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"验证失败"
                                                                           message:msg
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
            [weakSelf presentViewController:alert animated:YES completion:nil];
        });
    }];
}

/// App 启动或进入前台时，处理上次未完成的事务（断网重连等场景）
- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    // 事务移除后无需额外处理
}

#pragma mark - Restore Purchases

/// 用户点击「恢复购买」。
/// 优先走 StoreKit 2 currentEntitlements（已 finish 的订阅仍在权益里），
/// 再回退 SK1 restoreCompletedTransactions。
- (void)onTapRestore {
    if (![AuthManager sharedManager].isLoggedIn) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"请先登录"
                                                                       message:@"恢复购买需要先登录"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"去登录" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            Class loginClass = NSClassFromString(@"LoginChoiceViewController");
            if (!loginClass) return;
            UIViewController *loginVC = [loginClass new];
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginVC];
            nav.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:nav animated:YES completion:nil];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    if (self.payInFlight || self.restoreInFlight) {
        return;
    }
    self.restoreInFlight = YES;
    self.restoreTotalCount = 0;
    self.restoreProcessedCount = 0;
    self.restoreSuccessCount = 0;
    self.lastRestoreErrorMessage = nil;
    [self updatePayButtonState];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];

    __weak typeof(self) weakSelf = self;
    if ([PNIAPSK2Bridge isAvailable]) {
        [PNIAPSK2Bridge enumerateCurrentEntitlements:^(NSArray<PNIAPSK2Result *> *results) {
            if (results.count > 0) {
                NSLog(@"[IAP] restore 走 SK2 entitlements: %lu 笔", (unsigned long)results.count);
                for (PNIAPSK2Result *item in results) {
                    [weakSelf submitRestoredEntitlement:item];
                }
                return;
            }
            NSLog(@"[IAP] SK2 entitlements 为空，回退 SK1 restoreCompletedTransactions");
            [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
        }];
    } else {
        [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    }
}

/// 将 SK2 当前权益上报服务端（restore 优先；失败且能映射 planId 时再以购买路径补激活）
- (void)submitRestoredEntitlement:(PNIAPSK2Result *)item {
    NSString *transactionId = item.transactionId ?: @"";
    NSString *jws = item.jwsRepresentation ?: @"";
    if (transactionId.length == 0 || jws.length == 0) {
        return;
    }
    self.restoreTotalCount += 1;

    NSString *planId = [self planIdForAppleProductId:item.productId];
    __weak typeof(self) weakSelf = self;

    void (^finishFail)(NSError *) = ^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *msg = error.localizedDescription;
            if (msg.length > 0) {
                weakSelf.lastRestoreErrorMessage = msg;
            }
            [weakSelf finishOneRestore];
        });
    };

    void (^finishOK)(void) = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.restoreSuccessCount += 1;
            [weakSelf finishOneRestore];
        });
    };

    // 1) 先按 restore 上报（新服务端可补激活）
    [[MembershipRequest shared] verifyPurchaseWithBody:@{
        @"transactionId": transactionId,
        @"signedTransaction": jws,
        @"planId": @(0),
        @"agreementAccepted": @NO,
        @"restore": @YES
    } success:^(HTTPResponse * _Nullable responseObject) {
        finishOK();
    } failure:^(NSError * _Nonnull error) {
        // 2) 旧服务端 / PENDING_VERIFY：改走「正式购买」路径（需能映射 planId）
        if (planId.length == 0) {
            NSLog(@"[IAP] restore 失败且无法映射 planId productId=%@ err=%@", item.productId, error);
            finishFail(error);
            return;
        }
        NSLog(@"[IAP] restore 失败，改以 purchase 补报 planId=%@ productId=%@", planId, item.productId);
        [[MembershipRequest shared] verifyPurchaseWithBody:@{
            @"transactionId": transactionId,
            @"signedTransaction": jws,
            @"planId": planId,
            @"agreementAccepted": @YES,
            @"restore": @NO
        } success:^(HTTPResponse * _Nullable responseObject) {
            finishOK();
        } failure:^(NSError * _Nonnull error2) {
            NSLog(@"[IAP] purchase 补报仍失败: %@", error2);
            finishFail(error2);
        }];
    }];
}

/// 用 apiPlans 把 Apple productId 反查为服务端 planId
- (NSString *)planIdForAppleProductId:(NSString *)productId {
    productId = [productId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (productId.length == 0) return nil;
    for (PNMemberPlan *p in self.apiPlans) {
        NSString *pid = [p.appleProductId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([pid isEqualToString:productId] && p.planId.length > 0) {
            return p.planId;
        }
    }
    return nil;
}

/// SKPaymentQueueObserver — 恢复流程完成。
- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.restoreTotalCount == 0 && self.restoreInFlight) {
            // SK1 也是 0 笔：再尝试一次 SK2 entitlements（防时序）
            if ([PNIAPSK2Bridge isAvailable]) {
                __weak typeof(self) weakSelf = self;
                [PNIAPSK2Bridge enumerateCurrentEntitlements:^(NSArray<PNIAPSK2Result *> *results) {
                    if (results.count > 0) {
                        for (PNIAPSK2Result *item in results) {
                            [weakSelf submitRestoredEntitlement:item];
                        }
                        return;
                    }
                    [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
                    weakSelf.restoreInFlight = NO;
                    [weakSelf updatePayButtonState];
                    [[LoadingManager sharedManager] showError:@"暂无可恢复的购买记录" inView:weakSelf.view];
                }];
                return;
            }
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            self.restoreInFlight = NO;
            [self updatePayButtonState];
            [[LoadingManager sharedManager] showError:@"暂无可恢复的购买记录" inView:self.view];
            return;
        }
        NSLog(@"[IAP] restore finished: %ld 笔事务等待上报完成", (long)self.restoreTotalCount);
    });
}

/// SKPaymentQueueObserver — 恢复流程失败
- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        self.restoreInFlight = NO;
        [self updatePayButtonState];
        NSString *msg = error.localizedDescription ?: @"恢复购买失败，请稍后重试";
        [[LoadingManager sharedManager] showError:msg inView:self.view];
    });
}

/// 恢复购买拿到一笔事务：把 transactionId + JWS 上报服务端。
/// 服务端按 appleTransactionId 命中已有会员记录，或验证通过后按 productId 补激活。
- (void)handleRestoredTransaction:(SKPaymentTransaction *)transaction {
    NSString *transactionId = transaction.transactionIdentifier ?: @"";
    if (transactionId.length == 0) {
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        return;
    }
    // 计入本次 restore 总数（用于在所有回调返回后统一收尾 HUD）
    self.restoreTotalCount += 1;

    __weak typeof(self) weakSelf = self;
    void (^submitRestore)(NSString *) = ^(NSString *signedTransaction) {
        [[MembershipRequest shared] verifyPurchaseWithBody:@{
            @"transactionId": transactionId,
            @"signedTransaction": signedTransaction ?: @"",
            @"planId": @(0),
            // restore 不要求用户勾选协议（Apple 也不要求），传 NO 保持数据真实，
            // 服务端在 restore=true 时会跳过 agreementAccepted 校验。
            @"agreementAccepted": @NO,
            @"restore": @YES
        } success:^(HTTPResponse * _Nullable responseObject) {
            // 服务端已识别并返回会员信息，可 finish 事务
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.restoreSuccessCount += 1;
                [weakSelf finishOneRestore];
            });
        } failure:^(NSError * _Nonnull error) {
            // 服务端未识别也 finish 避免堆积；保留错误文案供收尾展示
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error.localizedDescription.length > 0) {
                    weakSelf.lastRestoreErrorMessage = error.localizedDescription;
                }
                [weakSelf finishOneRestore];
            });
        }];
    };

    // 与购买路径一致：优先 SK2 JWS，避免 SK1 收据在服务端 .p8 未配齐时验不过
    if ([PNIAPSK2Bridge isAvailable]) {
        [PNIAPSK2Bridge currentJWSForTransactionId:transactionId completion:^(PNIAPSK2Result * _Nullable result) {
            NSString *jws = result.jwsRepresentation ?: @"";
            NSUInteger dotCount = [[jws componentsSeparatedByString:@"."] count];
            if (jws.length > 0 && dotCount >= 3) {
                NSLog(@"[IAP] restore 使用 SK2 JWS: txnId=%@", transactionId);
                submitRestore(jws);
            } else {
                NSLog(@"[IAP] restore JWS 未命中，回退 SK1 收据: txnId=%@", transactionId);
                submitRestore([weakSelf currentReceiptBase64]);
            }
        }];
    } else {
        submitRestore([self currentReceiptBase64]);
    }
}

/// 单笔 restore 事务处理完成的统一收尾逻辑：
/// 当所有事务都处理完成时，刷新一次会员状态并提示用户。
- (void)finishOneRestore {
    self.restoreProcessedCount += 1;
    if (self.restoreProcessedCount < self.restoreTotalCount) {
        // 还有未完成的事务，HUD 保持
        return;
    }
    // 全部完成
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.restoreInFlight = NO;
    [self updatePayButtonState]; // 恢复侧滑返回
    // 仅在至少有一笔成功时刷新会员状态（避免无效请求）
    if (self.restoreSuccessCount > 0) {
        [self loadRemoteData];
        // 礼包码页不弹「恢复成功」，避免误以为是礼包兑换结果
        if (!self.showingGiftCode) {
            [[LoadingManager sharedManager] showError:@"恢复成功" inView:self.view];
        }
    } else if (!self.showingGiftCode) {
        NSString *msg = self.lastRestoreErrorMessage.length > 0
            ? self.lastRestoreErrorMessage
            : @"暂无可恢复的购买记录";
        [[LoadingManager sharedManager] showError:msg inView:self.view];
    }
    self.lastRestoreErrorMessage = nil;
    // 复位计数器
    self.restoreTotalCount = 0;
    self.restoreProcessedCount = 0;
    self.restoreSuccessCount = 0;
}

#pragma mark - Receipt Helpers

/// 获取本机 App Store 收据（base64 编码）。
/// 若 appStoreReceiptURL 不存在（首次安装 / 重装后未购买过），返回空串并触发一次
/// 异步收据刷新请求；下次购买流程再进来时即可拿到有效收据。
- (NSString *)currentReceiptBase64 {
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData = receiptURL ? [NSData dataWithContentsOfURL:receiptURL] : nil;
    if (receiptData.length == 0) {
        // 触发异步刷新（不阻塞当前流程，下次调用就能拿到）
        [self refreshAppStoreReceiptIfNeeded];
        return @"";
    }
    return [receiptData base64EncodedStringWithOptions:0];
}

/// 通过 SKReceiptRefreshRequest 让 App Store 重新下发本机收据。
/// 首次安装、重装后 appStoreReceiptURL 可能为 nil，此时直接发起购买会导致上报空收据。
/// 控制频率：每个 MembershipCenterViewController 实例最多触发一次（用户离开后再次进入会创建
/// 新实例，相当于每次进入会员中心允许重试一次，比 App 级 dispatch_once 更宽容）。
- (void)refreshAppStoreReceiptIfNeeded {
    if (self.receiptRefreshTriggered) return;
    self.receiptRefreshTriggered = YES;
    SKReceiptRefreshRequest *req = [[SKReceiptRefreshRequest alloc] init];
    [req start];
    NSLog(@"[IAP] 触发收据刷新请求（appStoreReceiptURL 为空）");
}

/// 判断当前是否为 App Store 沙箱环境（TestFlight / Sandbox 测试账号）。
/// 通过 appStoreReceiptURL 路径名区分：生产环境文件名为 receipt，沙箱为 sandboxReceipt。
/// 用于在购买成功后给出"测试购买不会真实扣款"的明确提示，改善测试体验。
- (BOOL)isAppStoreSandbox {
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSString *lastComponent = receiptURL.lastPathComponent ?: @"";
    return [lastComponent isEqualToString:@"sandboxReceipt"];
}

- (void)onGiftCodeChanged {
    NSCharacterSet *nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSString *raw = [self.giftHiddenInput.text ?: @"" stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *code = [[raw componentsSeparatedByCharactersInSet:nonDigits] componentsJoinedByString:@""];
    if (code.length > 5) code = [code substringToIndex:5];
    if (![code isEqualToString:self.giftHiddenInput.text ?: @""]) {
        self.giftHiddenInput.text = code;
    }
    for (NSInteger i = 0; i < self.giftDigitLabels.count; i++) {
        UILabel *lb = self.giftDigitLabels[i];
        UIView *box = self.giftDigitBoxes[i];
        BOOL filled = i < (NSInteger)code.length;
        lb.text = filled ? [code substringWithRange:NSMakeRange(i, 1)] : @"";
        UIColor *active = [UIColor colorWithRed:175/255.0 green:255/255.0 blue:224/255.0 alpha:1.0];
        UIColor *inactive = [UIColor colorWithRed:191/255.0 green:191/255.0 blue:191/255.0 alpha:1.0];
        box.layer.borderColor = ((i == code.length && code.length < 5) || filled) ? active.CGColor : inactive.CGColor;
    }
    BOOL valid = code.length == 5;
    BOOL typing = code.length > 0;
    self.giftSuccessWrap.hidden = YES;
    self.giftSuccessLabel.hidden = YES;
    self.giftPromptLabel.hidden = NO;
    self.giftCodeTapAreaBtn.hidden = NO;
    self.giftRedeemBtn.hidden = NO;
    self.giftRedeemBtn.enabled = valid;
    self.giftRedeemBtn.alpha = valid ? 1.0 : 0.55;
    if (typing) {
        [self.giftRedeemBtn setTitle:@"确认" forState:UIControlStateNormal];
    }
}

- (void)onRedeemGiftCode {
    // IAP 硬约束：礼包码激活会员同样需登录态
    if (![AuthManager sharedManager].isLoggedIn) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"请先登录"
                                                                       message:@"兑换会员需要先登录"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"去登录" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            Class loginClass = NSClassFromString(@"LoginChoiceViewController");
            if (!loginClass) return;
            UIViewController *loginVC = [loginClass new];
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginVC];
            nav.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:nav animated:YES completion:nil];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    NSString *code = self.giftHiddenInput.text ?: @"";
    if (code.length < 5) return;
    [self.view endEditing:YES];

    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    __weak typeof(self) weakSelf = self;
    [[MembershipRequest shared] redeemCodeWithBody:@{@"code": code} success:^(HTTPResponse * _Nullable responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
            id raw = responseObject.dataObject ?: responseObject.data;
            PNRedeemResult *result = [PNRedeemResult yy_modelWithJSON:raw];
            // 礼包入口若误输入付费码/邀请付费码，引导走订阅支付
            if (result.needPayment && result.appleProductId.length > 0) {
                [[LoadingManager sharedManager] showError:@"该码需支付后激活，已为你应用优惠" inView:weakSelf.view];
                [weakSelf applyPaidRedeemResult:result code:code];
                return;
            }
            weakSelf.hasAppliedRedeemDiscount = NO;
            weakSelf.pendingRedeemCode = nil;
            weakSelf.redeemAppleProductId = nil;
            weakSelf.redeemPlanId = nil;
            weakSelf.redeemOriginalPrice = nil;
            weakSelf.redeemDiscountPrice = nil;
            weakSelf.giftPromptLabel.hidden = YES;
            weakSelf.giftCodeTapAreaBtn.hidden = YES;
            weakSelf.giftRedeemBtn.hidden = YES;
            weakSelf.giftSuccessWrap.hidden = NO;
            weakSelf.giftSuccessLabel.hidden = NO;
            NSString *expireText = [weakSelf displayDateText:result.expireTime];
            if (expireText.length > 0) {
                weakSelf.giftSuccessLabel.text = [NSString stringWithFormat:@"激活成功\n到期：%@", expireText];
                weakSelf.giftSuccessLabel.numberOfLines = 0;
            } else if (result.durationDays == 0 &&
                       ([result.codeType isEqualToString:@"GIFT_CODE"] || [result.codeType isEqualToString:@"INVITE_CODE"])) {
                weakSelf.giftSuccessLabel.text = @"激活成功\n永久有效";
                weakSelf.giftSuccessLabel.numberOfLines = 0;
            } else {
                weakSelf.giftSuccessLabel.text = @"兑换成功";
            }
            [weakSelf applyMembershipActivationFromRedeemResult:result];
            [weakSelf switchToGiftMode:NO];
            [weakSelf loadRemoteDataWithForce:YES];
            [weakSelf refreshMembershipStatusForce];
        });
    } failure:^(NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
            NSString *msg = @"兑换失败，请检查礼包码";
            if ([error isKindOfClass:[APIError class]]) {
                msg = [(APIError *)error displayMessageWithFallback:msg];
            }
            [[LoadingManager sharedManager] showError:msg inView:weakSelf.view];
        });
    }];
}

- (void)onTapGiftCodeArea {
    if (self.giftSuccessWrap.hidden) {
        [self.giftHiddenInput becomeFirstResponder];
    }
}

- (void)resetGiftCodeUI {
    self.giftHiddenInput.text = @"";
    [self onGiftCodeChanged];
    self.giftPromptLabel.hidden = NO;
    self.giftCodeTapAreaBtn.hidden = NO;
    self.giftRedeemBtn.hidden = NO;
    self.giftSuccessWrap.hidden = YES;
    self.giftSuccessLabel.hidden = YES;
}

- (void)onToggleAgreement {
    self.agreementCheckBtn.selected = !self.agreementCheckBtn.selected;
    self.agreementCheckBtn.layer.borderColor = (self.agreementCheckBtn.selected ? kMCMint : [UIColor colorWithWhite:0.75 alpha:1.0]).CGColor;
    [self.agreementCheckBtn setTitle:(self.agreementCheckBtn.selected ? @"✓" : @"") forState:UIControlStateNormal];
    [self.agreementCheckBtn setTitleColor:kMCMint forState:UIControlStateNormal];
    self.agreementCheckBtn.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
    [self updatePayButtonState];
}

- (void)onPageChanged:(UIPageControl *)pc {
    [self applyPlanAtIndex:pc.currentPage animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != self.cardScrollView || self.showingGiftCode) return;
    [self updateCardInteractiveScaleForOffset:scrollView.contentOffset.x];
    CGFloat pageW = 222.0;
    NSInteger nearest = (NSInteger)llround(scrollView.contentOffset.x / pageW);
    nearest = MAX(0, MIN(nearest, (NSInteger)self.plans.count - 1));
    if (nearest != self.currentIndex) {
        [self refreshPlanInfoAtIndex:nearest];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView != self.cardScrollView) return;
    [self snapCarouselAndSyncPage];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (scrollView != self.cardScrollView || decelerate) return;
    [self snapCarouselAndSyncPage];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (scrollView != self.cardScrollView || self.showingGiftCode) return;
    CGFloat pageW = 222.0;
    NSInteger idx = self.currentIndex;
    if (fabs(velocity.x) > 0.22) {
        idx += (velocity.x > 0 ? 1 : -1);
    } else {
        idx = (NSInteger)llround(targetContentOffset->x / pageW);
    }
    idx = MAX(0, MIN(idx, (NSInteger)self.plans.count - 1));
    targetContentOffset->x = idx * pageW;
    targetContentOffset->y = 0;
    [self refreshPlanInfoAtIndex:idx];
}

- (void)snapCarouselAndSyncPage {
    CGFloat pageW = 222.0;
    CGFloat x = self.cardScrollView.contentOffset.x;
    NSInteger idx = (NSInteger)llround(x / pageW);
    idx = MAX(0, MIN(idx, (NSInteger)self.plans.count - 1));
    [self applyPlanAtIndex:idx animated:YES];
}

- (void)onSwipePlan:(UISwipeGestureRecognizer *)gesture {
    if (self.showingGiftCode) return;
    NSInteger next = self.currentIndex + (gesture.direction == UISwipeGestureRecognizerDirectionLeft ? 1 : -1);
    next = MAX(0, MIN(next, (NSInteger)self.plans.count - 1));
    if (next != self.currentIndex) {
        [self applyPlanAtIndex:next animated:YES];
    }
}

@end

