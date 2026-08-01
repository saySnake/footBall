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
#import <MBProgressHUD/MBProgressHUD.h>

#define kMCPageBg [UIColor colorWithRed:13/255.0 green:33/255.0 blue:34/255.0 alpha:1.0]
#define kMCMint [UIColor colorWithRed:83/255.0 green:204/255.0 blue:158/255.0 alpha:1.0]
#define kMCMintBorder [UIColor colorWithRed:175/255.0 green:255/255.0 blue:224/255.0 alpha:0.90]
#define kMCDiscountMint [UIColor colorWithRed:175/255.0 green:255/255.0 blue:224/255.0 alpha:1.0]
#define kMCDiscountHintGray [UIColor colorWithRed:203/255.0 green:203/255.0 blue:203/255.0 alpha:1.0]

/// 订阅 / 隐私政策跳转 URL（App Store 审核要求自动续期订阅必须在购买页面提供可点击的条款链接）。
/// TODO: 上架前替换为公司正式 URL（建议 OSS 静态页或官网聚合页）。
static NSString *const kMCMembershipAgreementURL = @"https://passnomad.oss-cn-beijing.aliyuncs.com/agreement/membership.html";
static NSString *const kMCPrivacyPolicyURL      = @"https://passnomad.oss-cn-beijing.aliyuncs.com/agreement/privacy.html";
static NSString *const kCAutoRenewTermsURL      = @"https://passnomad.oss-cn-beijing.aliyuncs.com/agreement/auto-renew.html";

@interface MCPlan : NSObject
@property (nonatomic, copy) NSString *title;
/// 卡片大号展示价（如 33）
@property (nonatomic, copy) NSString *price;
/// 底部按钮展示价（稿内常与卡片价不同，如首屏 ¥22）
@property (nonatomic, copy) NSString *payPrice;
/// 折扣前展示价（如 33/268/748）
@property (nonatomic, copy) NSString *originalPrice;
@property (nonatomic, copy) NSString *hint;
@property (nonatomic, strong) NSArray<NSString *> *benefits;
/// SF Symbol 名，与 benefits 一一对应
@property (nonatomic, strong) NSArray<NSString *> *benefitIcons;
@end
@implementation MCPlan @end

@interface MembershipCenterViewController () <UIScrollViewDelegate, SKProductsRequestDelegate, SKPaymentTransactionObserver>
@property (nonatomic, strong) UIView *topGlowView;
@property (nonatomic, strong) CAGradientLayer *topGlowLayer;
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
/// 服务端返回的方案列表，用于获取 appleProductId 和 planId
@property (nonatomic, strong) NSArray<PNMemberPlan *> *apiPlans;
/// 当前会员状态
@property (nonatomic, strong) PNMembershipStatus *membershipStatus;
/// IAP：当前正在请求的 SKProductsRequest
@property (nonatomic, strong) SKProductsRequest *productsRequest;
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
/// 本 VC 生命周期内是否已触发过收据刷新（避免同一界面内重复刷新，
/// 但允许下次重新进入会员中心再尝试一次，比 App 级 dispatch_once 更友好）
@property (nonatomic, assign) BOOL receiptRefreshTriggered;
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
    [super viewDidLoad];
    self.hidesBottomBarWhenPushed = YES;
    self.shouldShowNavigationBar = NO;
    self.view.backgroundColor = kMCPageBg;
    self.initialPlanIndex = MAX(0, MIN(self.initialPlanIndex, 3));
    self.currentIndex = self.initialPlanIndex;
    self.skProducts = [NSMutableDictionary dictionary];
    [self buildPlanData];
    [self setupUI];
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
}

- (void)dealloc {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    [self.productsRequest cancel];
    // VC 销毁后，全局观察者接管兜底处理（如果还有未 finish 事务）
    [[PNIAPObserver shared] setMembershipCenterActive:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshUserProfile];
    [[PNIAPObserver shared] setMembershipCenterActive:YES];
    // 每次返回会员中心都扫描一次残留事务（应对被 pop 后回来、断网重连等场景）
    [[PNIAPObserver shared] resumePendingTransactions];
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
    if (self.isMovingFromParent && (self.payInFlight || self.restoreInFlight)) {
        NSLog(@"[IAP] 购买/恢复进行中，用户尝试离开");
        // 不在这里阻塞 super（已经调用过），通过提示告知用户当前状态。
        // 真正的拦截放在 navigationBar 返回按钮 / swipeBack 的交互层更合适；
        // 这里仅给出 toast 提示（VC 已经 pop 完，无法回滚）。
        // 如果需要"硬拦截"，应改用 navigationBar 自定义 leftBarButtonItem + 自定义 pop 手势。
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.topGlowLayer.frame = self.topGlowView.bounds;
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
    self.topGlowView = [UIView new];
    self.topGlowView.userInteractionEnabled = NO;
    [self.view addSubview:self.topGlowView];
    [self.topGlowView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
        make.height.mas_equalTo(280);
    }];
    self.topGlowLayer = [CAGradientLayer layer];
    self.topGlowLayer.colors = @[
        (id)[UIColor colorWithRed:0.00 green:0.30 blue:0.26 alpha:0.45].CGColor,
        (id)[UIColor colorWithRed:0.00 green:0.00 blue:0.00 alpha:0.00].CGColor
    ];
    self.topGlowLayer.startPoint = CGPointMake(0.5, 0.0);
    self.topGlowLayer.endPoint = CGPointMake(0.5, 1.0);
    [self.topGlowView.layer addSublayer:self.topGlowLayer];

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
    self.bannerSubLabel.text = @"限时兑换码";
    self.bannerSubLabel.textColor = kMCDiscountMint;
    self.bannerSubLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    [self.bannerCard addSubview:self.bannerSubLabel];
    [self.bannerSubLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.bannerTitleLabel);
        make.top.equalTo(self.bannerTitleLabel.mas_bottom).offset(2);
    }];
    self.bannerHintLabel = [UILabel new];
    self.bannerHintLabel.text = @"使用限时兑换码，解锁专属会员优惠";
    self.bannerHintLabel.textColor = kMCDiscountHintGray;
    self.bannerHintLabel.font = [UIFont systemFontOfSize:8 weight:UIFontWeightLight];
    [self.bannerCard addSubview:self.bannerHintLabel];
    [self.bannerHintLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.bannerTitleLabel);
        make.top.equalTo(self.bannerSubLabel.mas_bottom).offset(2);
    }];
    self.redeemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.redeemBtn.backgroundColor = [UIColor colorWithRed:40/255.0 green:93/255.0 blue:75/255.0 alpha:1.0];
    self.redeemBtn.layer.cornerRadius = 11;
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
        make.top.equalTo(self.bannerCard.mas_bottom).offset(12);
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

    self.payBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.payBtn.backgroundColor = kMCMint;
    self.payBtn.layer.cornerRadius = 17.5;
    /// Figma 571:2659：约 12.6pt semibold
    self.payBtn.titleLabel.font = [UIFont systemFontOfSize:12.6 weight:UIFontWeightSemibold];
    self.payBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.payBtn.titleLabel.minimumScaleFactor = 0.85;
    [self.payBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.payBtn addTarget:self action:@selector(onTapPay) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.payBtn];
    [self.payBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.view).offset(47);
        make.trailing.equalTo(self.view).offset(-47);
        make.height.mas_equalTo(35);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-62);
    }];

    self.restoreBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.restoreBtn.titleLabel.font = [UIFont systemFontOfSize:10];
    [self.restoreBtn setTitle:@"恢复购买" forState:UIControlStateNormal];
    [self.restoreBtn setTitleColor:[UIColor colorWithWhite:0.6 alpha:1.0] forState:UIControlStateNormal];
    [self.restoreBtn setTitleColor:[UIColor colorWithWhite:0.4 alpha:1.0] forState:UIControlStateHighlighted];
    self.restoreBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.restoreBtn.titleLabel.minimumScaleFactor = 0.85;
    [self.restoreBtn addTarget:self action:@selector(onTapRestore) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.restoreBtn];
    [self.restoreBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.payBtn.mas_top).offset(-6);
        make.height.mas_equalTo(16);
    }];

    self.agreementCheckBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.agreementCheckBtn.layer.borderColor = [UIColor colorWithWhite:0.93 alpha:1.0].CGColor;
    self.agreementCheckBtn.layer.borderWidth = 1;
    self.agreementCheckBtn.layer.cornerRadius = 2;
    [self.agreementCheckBtn addTarget:self action:@selector(onToggleAgreement) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.agreementCheckBtn];
    [self.agreementCheckBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.view).offset(99);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-20);
        make.size.mas_equalTo(CGSizeMake(14, 14));
    }];

    self.agreementLabel = [[UITextView alloc] init];
    self.agreementLabel.editable = NO;
    self.agreementLabel.selectable = YES;            // 链接可点必须 selectable
    self.agreementLabel.scrollEnabled = NO;          // 自适应高度
    self.agreementLabel.userInteractionEnabled = YES;
    self.agreementLabel.backgroundColor = [UIColor clearColor];
    self.agreementLabel.textContainerInset = UIEdgeInsetsZero;
    self.agreementLabel.textContainer.lineFragmentPadding = 0;
    self.agreementLabel.font = [UIFont systemFontOfSize:10];
    self.agreementLabel.textColor = [UIColor colorWithWhite:0.93 alpha:1.0];
    self.agreementLabel.attributedText = [self agreementAttrText];
    self.agreementLabel.linkTextAttributes = @{
        NSForegroundColorAttributeName: [UIColor colorWithRed:24/255.0 green:115/255.0 blue:1 alpha:1],
        NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)
    };
    // 拦截 UITextView 默认用外链浏览器打开的行为，改为应用内 SFSafariViewController 打开
    self.agreementLabel.delegate = self;
    [self.view addSubview:self.agreementLabel];
    [self.agreementLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.agreementCheckBtn.mas_trailing).offset(6);
        make.centerY.equalTo(self.agreementCheckBtn);
        make.trailing.equalTo(self.view).offset(-16);
    }];

    self.agreementCheckBtn.selected = NO;
    [self.agreementCheckBtn setTitle:@"" forState:UIControlStateNormal];
    [self refreshRedeemBannerState];
    [self applyPlanAtIndex:self.currentIndex animated:NO];
    [self updatePayButtonState];
    [self switchToGiftMode:NO];
    [self setupRedeemDialog];

    [self.view bringSubviewToFront:self.segmentWrap];
    [self.view bringSubviewToFront:self.planTitleLabel];
    [self.view bringSubviewToFront:self.cardScrollView];
    [self.view bringSubviewToFront:self.pageControl];
    [self.view bringSubviewToFront:self.payBtn];
    [self.view bringSubviewToFront:self.agreementCheckBtn];
    [self.view bringSubviewToFront:self.agreementLabel];
    [self.view bringSubviewToFront:self.restoreBtn];
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

- (UIView *)buildPlanCard:(MCPlan *)plan large:(BOOL)large {
    BOOL isMonthlyPlan = [plan.title isEqualToString:@"连续包月"];
    BOOL isLifetimePlan = [plan.title isEqualToString:@"永久权益"];
    BOOL isFounderPlan = [plan.title isEqualToString:@"终身权益"];
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

- (NSAttributedString *)cardPriceAttrTextForPlan:(MCPlan *)plan large:(BOOL)large {
    NSString *priceText = plan.price ?: @"";
    NSString *full = [NSString stringWithFormat:@"¥%@", priceText];
    UIColor *mint = [UIColor colorWithRed:175/255.0 green:255/255.0 blue:224/255.0 alpha:1.0];
    CGFloat priceSize = large ? 72.38 : 54.0;
    CGFloat unitSize = large ? 25.46 : 19.0;
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:full attributes:@{
        NSForegroundColorAttributeName: mint,
        NSFontAttributeName: [self membershipNeueFontOfSize:priceSize fallbackWeight:UIFontWeightRegular]
    }];
    if (full.length > 0) {
        [attr addAttribute:NSFontAttributeName value:[self membershipNeueFontOfSize:unitSize fallbackWeight:UIFontWeightRegular] range:NSMakeRange(0, 1)];
    }
    return attr;
}

- (void)loadRemoteData {
    __weak typeof(self) weakSelf = self;

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
        if (list.count == 0) return;
        NSArray<PNMemberPlan *> *apiPlans = [NSArray yy_modelArrayWithClass:PNMemberPlan.class json:list];
        weakSelf.apiPlans = apiPlans;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf applyAPIPlansToUI:apiPlans];
        });
    } failure:^(NSError * _Nonnull error) {
        // 接口失败时保留本地写死数据，不影响展示
    }];

    // 加载会员状态，更新 banner 标题
    [[MembershipRequest shared] getMembershipStatusSuccess:^(HTTPResponse * _Nullable responseObject) {
        id raw = responseObject.dataObject ?: responseObject.data;
        PNMembershipStatus *status = [PNMembershipStatus yy_modelWithJSON:raw];
        weakSelf.membershipStatus = status;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf applyMembershipStatusToUI:status];
        });
    } failure:^(NSError * _Nonnull error) {
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
        if (api.name.length > 0) {
            local.title = api.name;
        }
    }
}

/// 根据会员状态更新 banner 文案
- (void)applyMembershipStatusToUI:(PNMembershipStatus *)status {
    if (!status) return;
    if (status.isMember && status.expireTime.length > 0) {
        self.bannerTitleLabel.text = [NSString stringWithFormat:@"会员有效期至 %@",
                                      [status.expireTime substringToIndex:MIN(10, status.expireTime.length)]];
        if (status.nearExpiry) {
            self.bannerSubLabel.text = @"即将到期，续费享优惠";
            self.bannerSubLabel.textColor = [UIColor colorWithRed:1.0 green:0.8 blue:0.2 alpha:1.0];
        } else {
            // 会员且非临期：必须复位，否则上次「即将到期」的黄色文案会残留
            self.bannerSubLabel.text = nil;
            self.bannerSubLabel.textColor = [UIColor clearColor];
        }
    } else {
        // 非会员或无有效期：同样复位，避免残留上一次会员态的文案
        self.bannerSubLabel.text = nil;
        self.bannerSubLabel.textColor = [UIColor clearColor];
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
    if ([plan.title isEqualToString:@"连续包月"]) return @"月度通行证";
    if ([plan.title isEqualToString:@"连续包年"]) return @"赛季通行证";
    if ([plan.title isEqualToString:@"永久权益"]) return @"终身会员";
    if ([plan.title isEqualToString:@"终身权益"]) return @"创始人会员";
    return @"会员方案";
}

- (NSAttributedString *)paymentButtonAttrTitleForPlan:(MCPlan *)plan {
    NSString *pay = plan.payPrice.length ? plan.payPrice : plan.price;
    NSString *full = [NSString stringWithFormat:@"确认协议并支付¥%@", pay ?: @""];
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:full attributes:@{
        NSForegroundColorAttributeName: [UIColor whiteColor],
        NSFontAttributeName: [UIFont systemFontOfSize:12.57 weight:UIFontWeightSemibold]
    }];
    NSRange currencyRange = [full rangeOfString:@"¥"];
    if (currencyRange.location != NSNotFound) {
        [attr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:8 weight:UIFontWeightSemibold] range:currencyRange];
    }
    return attr;
}

- (NSString *)cardHintTextForPlan:(MCPlan *)plan {
    if (self.hasAppliedRedeemDiscount) {
        if ([plan.title isEqualToString:@"连续包月"]) return @"限时优惠";
        if ([plan.title isEqualToString:@"终身权益"]) return plan.hint ?: @"";
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
    NSString *originalPrice = [self cardOriginalPriceTextForPlan:plan];
    if (originalPrice.length == 0) return nil;
    NSString *full = [NSString stringWithFormat:@"¥%@", originalPrice];
    CGFloat numberSize = large ? 16.0 : 13.0;
    CGFloat unitSize = large ? 8.0 : 6.5;
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:full attributes:@{
        NSForegroundColorAttributeName: kMCDiscountHintGray,
        NSFontAttributeName: [self membershipNeueFontOfSize:numberSize fallbackWeight:UIFontWeightRegular]
    }];
    [attr addAttribute:NSFontAttributeName value:[self membershipNeueFontOfSize:unitSize fallbackWeight:UIFontWeightRegular] range:NSMakeRange(0, 1)];
    // 再次全量写死前景色，避免后续属性覆盖导致显示偏白。
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
    NSString *prefix = @"开通前阅读并同意 ";
    NSString *agreementText = @"《会员服务协议》";
    NSString *privacyText   = @"《隐私政策》";
    NSString *autoRenewText = @"《自动续期条款》";
    NSString *suffix = @"\n付款：会员到期后 24 小时内自动续期，可随时在「设置-Apple ID-订阅」中取消。";
    NSString *all = [NSString stringWithFormat:@"%@%@、%@、%@%@", prefix, agreementText, privacyText, autoRenewText, suffix];

    NSMutableAttributedString *m = [[NSMutableAttributedString alloc] initWithString:all attributes:@{
        NSForegroundColorAttributeName: [UIColor colorWithWhite:0.93 alpha:1.0],
        NSFontAttributeName: [UIFont systemFontOfSize:10 weight:UIFontWeightMedium]
    }];

    // 三个链接统一高亮色 + 下划线，并打上 NSLinkAttributeName 标记。
    // UITextView 原生识别 NSLinkAttributeName，点击即可跳转，不需要手动算命中。
    NSDictionary *linkAttrs = @{
        NSForegroundColorAttributeName: [UIColor colorWithRed:24/255.0 green:115/255.0 blue:1 alpha:1],
        NSFontAttributeName: [UIFont systemFontOfSize:10 weight:UIFontWeightMedium],
        NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)
    };
    NSRange rAgreement = [all rangeOfString:agreementText];
    NSRange rPrivacy   = [all rangeOfString:privacyText];
    NSRange rAutoRenew = [all rangeOfString:autoRenewText];
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
        [m addAttribute:NSLinkAttributeName value:kCAutoRenewTermsURL range:rAutoRenew];
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

- (void)buildPlanData {
    MCPlan *m = [MCPlan new];
    m.title = @"连续包月";
    m.price = @"33";
    m.payPrice = @"33";
    m.originalPrice = @"";
    m.hint = @"";
    m.benefits = @[@"解锁全部内容", @"数据可视化"];
    m.benefitIcons = @[@"lock.open", @"chart.bar.fill"];

    MCPlan *y = [MCPlan new];
    y.title = @"连续包年";
    y.price = @"268";
    y.payPrice = @"268";
    y.originalPrice = @"";
    y.hint = @"";
    y.benefits = @[@"解锁全部内容", @"赛季总结报告｜年度数据回顾", @"限定数字邮票|边框"];
    y.benefitIcons = @[@"lock.open", @"doc.text.fill", @"stamp.fill"];

    MCPlan *l = [MCPlan new];
    l.title = @"永久权益";
    l.price = @"748";
    l.payPrice = @"748";
    l.originalPrice = @"";
    l.hint = @"";
    l.benefits = @[@"解锁全部内容，永久全部权益", @"赛季终身会员徽章", @"终身限定数字邮票|边框"];
    l.benefitIcons = @[@"lock.open", @"star.circle.fill", @"stamp.fill"];

    MCPlan *f = [MCPlan new];
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
        // 折扣只作用在兑换码对应的方案上，避免所有卡片都显示折后价误导用户
        NSString *pid = self.redeemPlanId ?: @"";
        void (^applyDiscount)(MCPlan *, NSString *) = ^(MCPlan *plan, NSString *discountPrice) {
            if (!plan || discountPrice.length == 0) return;
            plan.originalPrice = plan.price;
            plan.price = discountPrice;
            plan.payPrice = discountPrice;
        };
        if ([pid isEqualToString:@"1"]) {
            applyDiscount(m, @"22");
        } else if ([pid isEqualToString:@"2"]) {
            applyDiscount(y, @"188");
        } else if ([pid isEqualToString:@"3"]) {
            applyDiscount(l, @"698");
        }
        // planId=4 创始人通常无折扣；未知 planId 不改价
    }

    self.plans = builtPlans;
}

- (void)refreshPlanInfoAtIndex:(NSInteger)idx {
    if (idx < 0 || idx >= self.plans.count) return;
    self.currentIndex = idx;
    MCPlan *plan = self.plans[idx];
    self.planTitleLabel.text = [self displayTitleForPlan:plan];
    [self.payBtn setAttributedTitle:[self paymentButtonAttrTitleForPlan:plan] forState:UIControlStateNormal];
    [self.payBtn setAttributedTitle:[self paymentButtonAttrTitleForPlan:plan] forState:UIControlStateDisabled];
    self.pageControl.currentPage = idx;
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
                [weakSelf showRedeemDialogSuccessWithTitle:@"激活成功！" desc:desc autoHide:YES];
                [weakSelf loadRemoteData];
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
            weakSelf.redeemAppleProductId = result.appleProductId;
            if (result.planId.length > 0) {
                weakSelf.redeemPlanId = result.planId;
            }
            NSString *paidDesc = [result.codeType isEqualToString:@"INVITE_CODE"]
                ? @"请继续完成支付以激活会员权益"
                : @"折扣已应用到相应会员订阅中";
            [weakSelf showRedeemDialogSuccessWithTitle:@"兑换成功！" desc:paidDesc autoHide:YES];
            [weakSelf reloadPlanCardsPreservingIndex];
            [weakSelf refreshRedeemBannerState];
            [weakSelf switchToGiftMode:NO];
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
    self.giftContainerView.hidden = !giftMode;
    if (giftMode) {
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
    BOOL visuallyEnabled = self.agreementCheckBtn.selected && !self.payInFlight;
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
    // 支付进行中拦截：按钮现在始终 enabled（为了能弹「请先勾选协议」），
    // 所以必须在入口显式拦截 payInFlight，避免连点触发重复购买
    if (self.payInFlight) {
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
        NSLog(@"[Pay] 折扣模式: appleProductId=%@, planId=%@", appleProductId, planId);
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
    if (self.payInFlight) {
        return;
    }
    self.payInFlight = YES;
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
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        self.payInFlight = NO;
        [self updatePayButtonState];
        // 缓存所有返回的产品
        for (SKProduct *product in response.products) {
            self.skProducts[product.productIdentifier] = product;
        }
        NSLog(@"[IAP] products=%@, invalidProductIdentifiers=%@",
              [response.products valueForKey:@"productIdentifier"],
              response.invalidProductIdentifiers);
        if (response.products.count == 0) {
            [[LoadingManager sharedManager] showError:@"未找到对应商品，请稍后重试" inView:self.view];
            return;
        }
        [self startPaymentWithProduct:response.products.firstObject];
    });
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
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
                // 购买中，展示 loading
                dispatch_async(dispatch_get_main_queue(), ^{
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
                    self.pendingPlanId = nil;
                    self.pendingRedeemCode = nil;
                    self.hasAppliedRedeemDiscount = NO;
                    [self updatePayButtonState]; // 同步恢复侧滑返回手势
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
                // 等待家长审批等延迟状态，不做处理
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                    [[LoadingManager sharedManager] showError:@"购买待审批，请等待家长确认" inView:self.view];
                });
                break;
            }

            default:
                break;
        }
    }
}

/// 购买成功后，将 transactionId 和 signedTransaction 上报服务端验证
- (void)handlePurchasedTransaction:(SKPaymentTransaction *)transaction {
    NSString *transactionId = transaction.transactionIdentifier ?: @"";

    // 统一使用本机 appStoreReceiptURL 的 base64 收据作为 signedTransaction 上报。
    // 服务端优先用 transactionId 调用 App Store Server API v2 验证，
    // 验证失败时降级解析 signedTransaction。
    // 注意：此值是 base64 编码的整本收据（PKCS#7 container），不是 StoreKit 2 的 JWS。
    // 服务端若开启 JWS_FALLBACK 强校验，需要走 Server API 主路径（依赖 .p8 配置）。
    //
    // 超时设计：当前依赖 APIManager 全局 timeoutInterval，未为 verifyPurchase 单独设置更短超时。
    // 原因：(1) APIManager 不支持 per-request timeout，临时切全局值会有并发安全问题；
    //       (2) Apple Server API v2 在国内偶发慢响应，但通常 < 15s；
    //       (3) 失败分支已 finish 事务并记详细日志（不会卡队列），用户等 30s 后看到提示可接受。
    // 后续若优化可改 APIManager 支持 per-request timeout，或在失败分支走本地落库对账。
    NSString *signedTransaction = [self currentReceiptBase64];

    NSString *planId = self.pendingPlanId ?: @"";
    NSMutableDictionary *body = [@{
        @"transactionId": transactionId,
        @"signedTransaction": signedTransaction,
        @"planId": planId,
        @"agreementAccepted": @YES
    } mutableCopy];
    // 兑换码/付费邀请码：随 purchase 带上 redeemCode，服务端按码关联方案与追踪
    if (self.pendingRedeemCode.length > 0) {
        body[@"redeemCode"] = self.pendingRedeemCode;
    }

    __weak typeof(self) weakSelf = self;
    [[MembershipRequest shared] verifyPurchaseWithBody:body success:^(HTTPResponse * _Nullable responseObject) {
        // 服务端验证成功，结束事务
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
            weakSelf.pendingPlanId = nil;
            weakSelf.pendingRedeemCode = nil;
            weakSelf.hasAppliedRedeemDiscount = NO;
            weakSelf.redeemAppleProductId = nil;
            weakSelf.redeemPlanId = nil;
            // 刷新会员状态
            [weakSelf loadRemoteData];
            [weakSelf refreshRedeemBannerState];
            // 弹出成功提示（沙箱环境加注说明，避免测试人员误以为真实扣款）
            NSString *title = @"开通成功";
            NSString *message = @"会员权益已激活，尽情享受吧！";
            if ([weakSelf isAppStoreSandbox]) {
                title = @"开通成功（测试环境）";
                message = @"当前为 App Store 沙箱环境购买，不会真实扣款。会员权益已激活。";
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
              transaction.transactionIdentifier ?: @"", weakSelf.pendingPlanId ?: @"", error);
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
            weakSelf.payInFlight = NO;
            [weakSelf updatePayButtonState];
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

/// 用户点击「恢复购买」：调用 SKPaymentQueue restoreCompletedTransactions，
/// 系统会把该 Apple ID 已完成的非消耗型/订阅事务重新投递到 updatedTransactions。
- (void)onTapRestore {
    // 防连点：购买进行中 / restore 进行中均拦截
    if (self.payInFlight || self.restoreInFlight) {
        return;
    }
    self.restoreInFlight = YES;
    self.restoreTotalCount = 0;
    self.restoreProcessedCount = 0;
    self.restoreSuccessCount = 0;
    [self updatePayButtonState]; // 同步禁用侧滑返回
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

/// SKPaymentQueueObserver — 恢复流程完成。
/// 注意：此回调触发时，所有 Restored 事务已通过 updatedTransactions 投递给
/// handleRestoredTransaction:，但每笔的网络上报是异步的，不能在这里 hideHUD
/// （否则后续上报还在进行中 UI 就没反馈了）。HUD 改为在最后一笔上报完成后隐藏。
- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 0 笔事务：直接提示并收尾。
        if (self.restoreTotalCount == 0) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            self.restoreInFlight = NO;
            [self updatePayButtonState];
            [[LoadingManager sharedManager] showError:@"暂无可恢复的购买记录" inView:self.view];
            return;
        }
        // 有事务：等 handleRestoredTransaction 的回调逐笔完成后再收尾（见 finishRestoreIfNeeded）
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

/// 恢复购买拿到一笔事务：把 transactionId 上报服务端做幂等查询，
/// 服务端按 appleTransactionId 命中已有会员记录，返回 activateTime/expireTime。
- (void)handleRestoredTransaction:(SKPaymentTransaction *)transaction {
    NSString *transactionId = transaction.transactionIdentifier ?: @"";
    if (transactionId.length == 0) {
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        return;
    }
    // 计入本次 restore 总数（用于在所有回调返回后统一收尾 HUD）
    self.restoreTotalCount += 1;

    // 复用统一的收据获取逻辑（含 nil 时触发 SKReceiptRefreshRequest 的能力）
    NSString *receiptBase64 = [self currentReceiptBase64];

    __weak typeof(self) weakSelf = self;
    [[MembershipRequest shared] verifyPurchaseWithBody:@{
        @"transactionId": transactionId,
        @"signedTransaction": receiptBase64,
        @"planId": @(0),
        @"agreementAccepted": @YES,
        @"restore": @YES
    } success:^(HTTPResponse * _Nullable responseObject) {
        // 服务端已识别并返回会员信息，可 finish 事务
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.restoreSuccessCount += 1;
            [weakSelf finishOneRestore];
        });
    } failure:^(NSError * _Nonnull error) {
        // 服务端未识别（该用户没买过 / 沙箱账号未续费等），也 finish 避免事务堆积
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf finishOneRestore];
        });
    }];
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
        [[LoadingManager sharedManager] showError:@"恢复成功" inView:self.view];
    } else {
        [[LoadingManager sharedManager] showError:@"暂无可恢复的购买记录" inView:self.view];
    }
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
                weakSelf.hasAppliedRedeemDiscount = YES;
                weakSelf.pendingRedeemCode = code;
                weakSelf.redeemAppleProductId = result.appleProductId;
                if (result.planId.length > 0) {
                    weakSelf.redeemPlanId = result.planId;
                }
                [[LoadingManager sharedManager] showError:@"该码需支付后激活，已为你应用优惠" inView:weakSelf.view];
                [weakSelf switchToGiftMode:NO];
                [weakSelf reloadPlanCardsPreservingIndex];
                return;
            }
            weakSelf.hasAppliedRedeemDiscount = NO;
            weakSelf.pendingRedeemCode = nil;
            weakSelf.redeemAppleProductId = nil;
            weakSelf.redeemPlanId = nil;
            weakSelf.giftPromptLabel.hidden = YES;
            weakSelf.giftCodeTapAreaBtn.hidden = YES;
            weakSelf.giftRedeemBtn.hidden = YES;
            weakSelf.giftSuccessWrap.hidden = NO;
            weakSelf.giftSuccessLabel.hidden = NO;
            NSString *expireText = [weakSelf displayDateText:result.expireTime];
            if (expireText.length > 0) {
                weakSelf.giftSuccessLabel.text = [NSString stringWithFormat:@"激活成功\n到期：%@", expireText];
                weakSelf.giftSuccessLabel.numberOfLines = 0;
            } else {
                weakSelf.giftSuccessLabel.text = @"兑换成功";
            }
            // 刷新会员状态
            [weakSelf loadRemoteData];
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
    self.agreementCheckBtn.layer.borderColor = [UIColor colorWithWhite:0.93 alpha:1.0].CGColor;
    [self.agreementCheckBtn setTitle:(self.agreementCheckBtn.selected ? @"✓" : @"") forState:UIControlStateNormal];
    [self.agreementCheckBtn setTitleColor:kMCMint forState:UIControlStateNormal];
    self.agreementCheckBtn.titleLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightBold];
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

