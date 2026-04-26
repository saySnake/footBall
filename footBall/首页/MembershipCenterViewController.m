//
//  MembershipCenterViewController.m
//  footBall
//

#import "MembershipCenterViewController.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>
#import <math.h>
#import <StoreKit/StoreKit.h>
#import "AuthManager.h"
#import "FontManager.h"
#import "MembershipRequest.h"
#import "MembershipModels.h"
#import "LoadingManager.h"
#import <MBProgressHUD/MBProgressHUD.h>

#define kMCPageBg [UIColor colorWithRed:13/255.0 green:33/255.0 blue:34/255.0 alpha:1.0]
#define kMCMint [UIColor colorWithRed:83/255.0 green:204/255.0 blue:158/255.0 alpha:1.0]
#define kMCMintBorder [UIColor colorWithRed:175/255.0 green:255/255.0 blue:224/255.0 alpha:0.90]
#define kMCDiscountMint [UIColor colorWithRed:175/255.0 green:255/255.0 blue:224/255.0 alpha:1.0]
#define kMCDiscountHintGray [UIColor colorWithRed:203/255.0 green:203/255.0 blue:203/255.0 alpha:1.0]

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
@property (nonatomic, strong) UILabel *agreementLabel;

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
/// 兑换码(EXCHANGE_CODE)成功后，服务端返回的折扣商品 ID 和方案 ID
@property (nonatomic, copy) NSString *redeemAppleProductId;
@property (nonatomic, copy) NSString *redeemPlanId;
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
@end

@implementation MembershipCenterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
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
}

- (void)dealloc {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    [self.productsRequest cancel];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshUserProfile];
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
    UIView *prevBox = nil;
    for (NSInteger i = 0; i < 5; i++) {
        UIView *box = [UIView new];
        box.layer.cornerRadius = 13.428;
        box.layer.borderWidth = 0.895;
        box.layer.borderColor = [UIColor colorWithRed:191/255.0 green:191/255.0 blue:191/255.0 alpha:1.0].CGColor;
        [self.giftCodeTapAreaBtn addSubview:box];
        [box mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(self.giftCodeTapAreaBtn);
            make.width.mas_equalTo(56.397);
            if (prevBox) {
                make.leading.equalTo(prevBox.mas_trailing).offset(8.761);
            } else {
                make.leading.equalTo(self.giftCodeTapAreaBtn);
            }
        }];
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
        prevBox = box;
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

    self.agreementLabel = [UILabel new];
    self.agreementLabel.font = [UIFont systemFontOfSize:10];
    self.agreementLabel.textColor = [UIColor colorWithWhite:0.93 alpha:1.0];
    self.agreementLabel.attributedText = [self agreementAttrText];
    [self.view addSubview:self.agreementLabel];
    [self.agreementLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.agreementCheckBtn.mas_trailing).offset(6);
        make.centerY.equalTo(self.agreementCheckBtn);
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
    self.redeemInputField.placeholder = @"请输入兑换码";
    self.redeemInputField.textColor = [UIColor colorWithRed:40/255.0 green:93/255.0 blue:75/255.0 alpha:1.0];
    self.redeemInputField.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    self.redeemInputField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"请输入兑换码" attributes:@{
        NSForegroundColorAttributeName: [UIColor colorWithRed:173/255.0 green:173/255.0 blue:173/255.0 alpha:1.0],
        NSFontAttributeName: [UIFont systemFontOfSize:8 weight:UIFontWeightRegular]
    }];
    self.redeemInputField.keyboardType = UIKeyboardTypeNumberPad;
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
    if (apiPlans.count == 0 || self.plans.count == 0) return;
    // 按 planId 升序排列（1=月, 2=年, 3=永久, 4=创始人），与本地 plans 数组顺序一致
    NSArray<PNMemberPlan *> *sorted = [apiPlans sortedArrayUsingComparator:^NSComparisonResult(PNMemberPlan *a, PNMemberPlan *b) {
        return [a.planId compare:b.planId options:NSNumericSearch];
    }];
    for (NSInteger i = 0; i < (NSInteger)sorted.count && i < (NSInteger)self.plans.count; i++) {
        PNMemberPlan *api = sorted[i];
        MCPlan *local = self.plans[i];
        if (api.price.length > 0) {
            local.price = api.price;
            local.payPrice = api.price;
        }
        if (api.name.length > 0) {
            local.title = api.name;
        }
    }
    [self reloadPlanCardsPreservingIndex];
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
        }
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
    NSString *all = @"开通前阅读并同意《会员服务协议》";
    NSMutableAttributedString *m = [[NSMutableAttributedString alloc] initWithString:all attributes:@{
        NSForegroundColorAttributeName: [UIColor colorWithWhite:0.93 alpha:1.0],
        NSFontAttributeName: [UIFont systemFontOfSize:10 weight:UIFontWeightMedium]
    }];
    NSRange r = [all rangeOfString:@"《会员服务协议》"];
    if (r.location != NSNotFound) {
        [m addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:24/255.0 green:115/255.0 blue:1 alpha:1] range:r];
    }
    return m;
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

    if (self.hasAppliedRedeemDiscount) {
        m.originalPrice = m.price;
        m.price = @"22";
        m.payPrice = @"22";

        y.originalPrice = y.price;
        y.price = @"188";
        y.payPrice = @"188";

        l.originalPrice = l.price;
        l.price = @"698";
        l.payPrice = @"698";

        f.originalPrice = @"";
    }

    self.plans = @[m, y, l, f];
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

- (void)onBack { [self.navigationController popViewControllerAnimated:YES]; }

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

- (void)onRedeemDialogInputChanged {
    NSString *raw = [self.redeemInputField.text ?: @"" stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSCharacterSet *nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSString *code = [[raw componentsSeparatedByCharactersInSet:nonDigits] componentsJoinedByString:@""];
    if (code.length > 5) code = [code substringToIndex:5];
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
    self.redeemConfirmBtn.alpha = code.length == 5 ? 1.0 : 0.88;
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

- (void)onTapRedeemDialogConfirm {
    NSString *code = self.redeemInputField.text ?: @"";
    if (code.length < 5) return;
    [self.view endEditing:YES];

    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    __weak typeof(self) weakSelf = self;
    [[MembershipRequest shared] redeemCodeWithBody:@{@"code": code} success:^(HTTPResponse * _Nullable responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
            weakSelf.hasAppliedRedeemDiscount = YES;
            // 解析兑换码返回的折扣商品 ID 和方案 ID，用于后续 IAP 支付
            NSDictionary *data = nil;
            if ([responseObject.dataObject isKindOfClass:NSDictionary.class]) {
                data = responseObject.dataObject;
            } else if ([responseObject.data isKindOfClass:NSDictionary.class]) {
                data = responseObject.data;
            }
            NSString *retAppleProductId = data[@"appleProductId"];
            NSString *retPlanId = data[@"planId"] ? [NSString stringWithFormat:@"%@", data[@"planId"]] : nil;
            if (retAppleProductId.length > 0) {
                weakSelf.redeemAppleProductId = retAppleProductId;
            }
            if (retPlanId.length > 0) {
                weakSelf.redeemPlanId = retPlanId;
            }
            weakSelf.redeemDialogShowingSuccess = YES;
            weakSelf.redeemDialogTicketIconView.hidden = YES;
            weakSelf.redeemInputWrapView.hidden = YES;
            weakSelf.redeemHelpLabel.hidden = YES;
            weakSelf.redeemSuccessWrapView.hidden = NO;
            weakSelf.redeemSuccessTitleLabel.hidden = NO;
            weakSelf.redeemSuccessDescLabel.hidden = NO;
            [weakSelf reloadPlanCardsPreservingIndex];
            [weakSelf refreshRedeemBannerState];
            [weakSelf switchToGiftMode:NO];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.85 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (weakSelf.redeemDialogShowingSuccess) {
                    [weakSelf hideRedeemDialog];
                }
            });
        });
    } failure:^(NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
            NSString *msg = @"兑换失败";
            if ([error isKindOfClass:[APIError class]]) {
                APIError *ae = (APIError *)error;
                if (ae.businessMessage.length) msg = ae.businessMessage;
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
    BOOL enabled = self.agreementCheckBtn.selected;
    self.payBtn.enabled = enabled;
    self.payBtn.alpha = enabled ? 1.0 : 0.55;
}

- (void)onTapPay {
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

    // 折扣场景：优先使用兑换码返回的折扣商品 ID（对应 App Store 里的折扣价商品）
    if (self.hasAppliedRedeemDiscount && self.redeemAppleProductId.length > 0) {
        appleProductId = self.redeemAppleProductId;
        planId = self.redeemPlanId;
    } else if (self.apiPlans.count > (NSUInteger)self.currentIndex) {
        NSArray<PNMemberPlan *> *sorted = [self.apiPlans sortedArrayUsingComparator:^NSComparisonResult(PNMemberPlan *a, PNMemberPlan *b) {
            return [a.planId compare:b.planId options:NSNumericSearch];
        }];
        if ((NSUInteger)self.currentIndex < sorted.count) {
            PNMemberPlan *api = sorted[self.currentIndex];
            appleProductId = api.appleProductId;
            planId = api.planId;
        }
    }

    if (appleProductId.length == 0) {
        [[LoadingManager sharedManager] showError:@"该方案暂不支持购买" inView:self.view];
        return;
    }

    if (![SKPaymentQueue canMakePayments]) {
        [[LoadingManager sharedManager] showError:@"当前设备不支持应用内购买，请检查家长控制设置" inView:self.view];
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
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self.productsRequest cancel];
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
        // 缓存所有返回的产品
        for (SKProduct *product in response.products) {
            self.skProducts[product.productIdentifier] = product;
        }
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
                // 恢复购买（此处仅结束事务，不做额外处理）
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            }

            case SKPaymentTransactionStateFailed: {
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                    // 用户主动取消不弹错误提示
                    if (transaction.error.code != SKErrorPaymentCancelled) {
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
    // iOS 15+ 优先使用 JWS signedTransaction；低版本回退到 base64 收据
    NSString *signedTransaction = @"";
    if (@available(iOS 15.0, *)) {
        // 通过 StoreKit 2 的 Transaction.all 获取 JWS 需要 Swift async，
        // 此处使用 originalTransaction 的 transactionIdentifier 作为凭证，
        // 服务端可通过 Apple verifyReceipt 或 App Store Server API 验证。
        // 如需 JWS，可在 Swift 层封装后回调。
        signedTransaction = transactionId;
    }
    // 低版本：使用 appStoreReceiptURL 的 base64 收据
    if (signedTransaction.length == 0) {
        NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
        NSData *receiptData = receiptURL ? [NSData dataWithContentsOfURL:receiptURL] : nil;
        signedTransaction = receiptData ? [receiptData base64EncodedStringWithOptions:0] : @"";
    }

    NSString *planId = self.pendingPlanId ?: @"";
    NSDictionary *body = @{
        @"transactionId": transactionId,
        @"signedTransaction": signedTransaction,
        @"planId": planId,
        @"agreementAccepted": @YES
    };

    __weak typeof(self) weakSelf = self;
    [[MembershipRequest shared] verifyPurchaseWithBody:body success:^(HTTPResponse * _Nullable responseObject) {
        // 服务端验证成功，结束事务
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
            weakSelf.pendingPlanId = nil;
            // 刷新会员状态
            [weakSelf loadRemoteData];
            // 弹出成功提示
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"开通成功"
                                                                           message:@"会员权益已激活，尽情享受吧！"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [weakSelf.navigationController popViewControllerAnimated:YES];
            }]];
            [weakSelf presentViewController:alert animated:YES completion:nil];
        });
    } failure:^(NSError * _Nonnull error) {
        // 服务端验证失败：不 finish 事务，保留收据，下次启动可重试
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
            NSString *msg = @"购买成功，但服务器验证失败，请联系客服处理";
            if ([error isKindOfClass:[APIError class]]) {
                APIError *ae = (APIError *)error;
                if (ae.businessMessage.length) msg = ae.businessMessage;
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
            weakSelf.giftPromptLabel.hidden = YES;
            weakSelf.giftCodeTapAreaBtn.hidden = YES;
            weakSelf.giftRedeemBtn.hidden = YES;
            weakSelf.giftSuccessWrap.hidden = NO;
            weakSelf.giftSuccessLabel.hidden = NO;
            weakSelf.giftSuccessLabel.text = @"兑换成功";
            // 刷新会员状态
            [weakSelf loadRemoteData];
        });
    } failure:^(NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
            NSString *msg = @"兑换失败，请检查礼包码";
            if ([error isKindOfClass:[APIError class]]) {
                APIError *ae = (APIError *)error;
                if (ae.businessMessage.length) msg = ae.businessMessage;
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
    nearest = MAX(0, MIN(nearest, self.plans.count - 1));
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
    idx = MAX(0, MIN(idx, self.plans.count - 1));
    targetContentOffset->x = idx * pageW;
    targetContentOffset->y = 0;
    [self refreshPlanInfoAtIndex:idx];
}

- (void)snapCarouselAndSyncPage {
    CGFloat pageW = 222.0;
    CGFloat x = self.cardScrollView.contentOffset.x;
    NSInteger idx = (NSInteger)llround(x / pageW);
    idx = MAX(0, MIN(idx, self.plans.count - 1));
    [self applyPlanAtIndex:idx animated:YES];
}

- (void)onSwipePlan:(UISwipeGestureRecognizer *)gesture {
    if (self.showingGiftCode) return;
    NSInteger next = self.currentIndex + (gesture.direction == UISwipeGestureRecognizerDirectionLeft ? 1 : -1);
    next = MAX(0, MIN(next, self.plans.count - 1));
    if (next != self.currentIndex) {
        [self applyPlanAtIndex:next animated:YES];
    }
}

@end

