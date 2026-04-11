//
//  IdentityAuthViewController.m
//  footBall
//

#import "IdentityAuthViewController.h"
#import "RealNameAuthViewController.h"
#import "ProfessionalAuthViewController.h"
#import "AuthManager.h"
#import "AuthStateStore.h"
#import "User.h"
#import "VerificationRequest.h"
#import "VerificationModels.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>

// Figma 1:4091「身份认证资料」
#define kIANavHeaderBg  [UIColor colorWithRed:13/255.0 green:33/255.0 blue:34/255.0 alpha:1.0]   // #0d2122
#define kIAPageBg       [UIColor colorWithRed:247/255.0 green:247/255.0 blue:247/255.0 alpha:1.0] // #f7f7f7
#define kIACardBg       [UIColor whiteColor]
#define kIAButtonGreen  [UIColor colorWithRed:40/255.0 green:93/255.0 blue:75/255.0 alpha:1.0]   // #285d4b
#define kIATextDark     [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0]
#define kIATextMuted    [UIColor colorWithRed:90/255.0 green:90/255.0 blue:90/255.0 alpha:1.0]   // #5a5a5a
#define kIATextStatus   [UIColor colorWithRed:53/255.0 green:53/255.0 blue:53/255.0 alpha:1.0] // #353535
#define kIASectionDesc  [UIColor colorWithRed:191/255.0 green:191/255.0 blue:191/255.0 alpha:1.0] // #bfbfbf

static CGFloat const kIAHeaderHeight = 240.f;
static CGFloat const kIAUserCardTop = 198.f;
static CGFloat const kIACardSideInset = 15.f;
static CGFloat const kIACardGap = 12.f;
static CGFloat const kIACertCardH = 138.f;

@interface IdentityAuthViewController ()
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UILabel *navTitleLabel;
@property (nonatomic, strong) UILabel *sectionTitleLabel;
@property (nonatomic, strong) UILabel *sectionDescLabel;
@property (nonatomic, strong) UIView *userCard;
@property (nonatomic, strong) UIView *avatarRingView;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UIView *textWrapView;
@property (nonatomic, strong) UILabel *userNameLabel;
@property (nonatomic, strong) UILabel *userStatusLabel;
@property (nonatomic, strong) UILabel *conditionTitleLabel;
@property (nonatomic, strong) UIView *professionalCard;
@property (nonatomic, strong) UIView *realNameCard;
@property (nonatomic, strong) UIButton *professionalCertButton;
@property (nonatomic, strong) UIButton *realNameCertButton;
@end

static NSString *IAEffectiveStatus(NSString *apiStatus, BOOL fallbackApproved) {
    NSString *s = apiStatus ?: @"";
    s = [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (s.length > 0) {
        return s;
    }
    return fallbackApproved ? @"APPROVED" : @"";
}

static BOOL IAStatusIsApproved(NSString *s) {
    if (s.length == 0) {
        return NO;
    }
    NSString *u = s.uppercaseString;
    return [u isEqualToString:@"APPROVED"] || [u isEqualToString:@"VERIFIED"] || [u isEqualToString:@"PASSED"];
}

static BOOL IAStatusIsPending(NSString *s) {
    return s.length && [s.uppercaseString isEqualToString:@"PENDING"];
}

static BOOL IAStatusNeedsRetry(NSString *s) {
    if (s.length == 0) {
        return NO;
    }
    NSString *u = s.uppercaseString;
    return [u isEqualToString:@"REJECTED"] || [u isEqualToString:@"EXPIRED"];
}

@implementation IdentityAuthViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hidesBottomBarWhenPushed = YES;
    self.shouldShowNavigationBar = NO;
    self.view.backgroundColor = kIAPageBg;
}


- (void)setupUI {
    // 顶部深色区 #0d2122，稿高度 240px
    self.headerView = [UIView new];
    self.headerView.backgroundColor = kIANavHeaderBg;
    [self.view addSubview:self.headerView];
    [self.headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
        make.height.mas_equalTo(kIAHeaderHeight);
    }];

    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *adLeft = [UIImage imageNamed:@"ad_left"];
    UIImage *backImg = adLeft ?: [UIImage imageNamed:@"nav_back"];
    if (!backImg && @available(iOS 13.0, *)) {
        backImg = [UIImage systemImageNamed:@"arrow.left"];
    }
    // 深色顶栏：ad_left 资源多为深色箭头，原图在深色背景上会发黑；用 Template + 白色与稿一致
    if (backImg) {
        [backBtn setImage:[backImg imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        backBtn.tintColor = [UIColor whiteColor];
    }
    backBtn.adjustsImageWhenHighlighted = NO;
    [backBtn addTarget:self action:@selector(onBack) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView addSubview:backBtn];
    static CGFloat const kBackHit = 44.f;
    static CGFloat const kBackVisual = 24.f;
    CGFloat backInset = (kBackHit - kBackVisual) / 2.f;
    // 仅上下缩进，左右不缩进，便于与下方文案左缘对齐后整体微调
    backBtn.imageEdgeInsets = UIEdgeInsetsMake(backInset, 0, backInset, 0);
    backBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11.0, *)) {
            make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft).offset(14);
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(17);
        } else {
            make.left.equalTo(self.headerView).offset(14);
            make.top.equalTo(self.mas_topLayoutGuide).offset(17);
        }
        make.size.mas_equalTo(CGSizeMake(kBackHit, kBackHit));
    }];

    self.navTitleLabel = [UILabel new];
    self.navTitleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    self.navTitleLabel.textColor = [UIColor whiteColor];
    self.navTitleLabel.text = NSLocalizedString(@"auth_identity_title", nil);
    [self.headerView addSubview:self.navTitleLabel];
    [self.navTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.headerView);
        make.centerY.equalTo(backBtn);
    }];

    self.sectionTitleLabel = [UILabel new];
    self.sectionTitleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    self.sectionTitleLabel.textColor = [UIColor whiteColor];
    self.sectionTitleLabel.numberOfLines = 0;
    self.sectionTitleLabel.text = NSLocalizedString(@"auth_pro_identity_title", nil);
    [self.headerView addSubview:self.sectionTitleLabel];
    [self.sectionTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(backBtn.mas_bottom).offset(23);
        if (@available(iOS 11.0, *)) {
            make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft).offset(14);
            make.right.equalTo(self.view.mas_safeAreaLayoutGuideRight).offset(-14);
        } else {
            make.left.equalTo(self.headerView).offset(14);
            make.right.equalTo(self.headerView).offset(-14);
        }
    }];

    self.sectionDescLabel = [UILabel new];
    self.sectionDescLabel.font = [UIFont systemFontOfSize:13];
    self.sectionDescLabel.textColor = kIASectionDesc;
    self.sectionDescLabel.numberOfLines = 0;
    self.sectionDescLabel.text = NSLocalizedString(@"auth_pro_identity_desc", nil);
    [self.headerView addSubview:self.sectionDescLabel];
    [self.sectionDescLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.sectionTitleLabel.mas_bottom).offset(9);
        make.leading.trailing.equalTo(self.sectionTitleLabel);
    }];

    // 用户白卡：343×84，圆角 6，顶约 198px 与深色头重叠（稿 1:4091）
    self.userCard = [UIView new];
    self.userCard.backgroundColor = kIACardBg;
    self.userCard.layer.cornerRadius = 6;
    self.userCard.layer.shadowColor = [UIColor blackColor].CGColor;
    self.userCard.layer.shadowOpacity = 0.08;
    self.userCard.layer.shadowOffset = CGSizeMake(0, 2);
    self.userCard.layer.shadowRadius = 8;
    [self.view addSubview:self.userCard];
    [self.userCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(kIAUserCardTop);
        make.leading.equalTo(self.view).offset(kIACardSideInset);
        make.trailing.equalTo(self.view).offset(-kIACardSideInset);
        make.height.mas_equalTo(84);
    }];

    self.avatarRingView = [UIView new];
    self.avatarRingView.backgroundColor = [UIColor clearColor];
    [self.userCard addSubview:self.avatarRingView];
    [self.avatarRingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.userCard).offset(15);
        make.top.equalTo(self.userCard).offset(15);
        make.size.mas_equalTo(CGSizeMake(54, 54));
    }];

    self.avatarView = [UIImageView new];
    self.avatarView.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1.0];
    self.avatarView.layer.cornerRadius = 27;
    self.avatarView.clipsToBounds = YES;
    self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
    if (@available(iOS 13.0, *)) {
        self.avatarView.image = [UIImage systemImageNamed:@"person.circle.fill"];
        self.avatarView.tintColor = kIATextMuted;
    }
    [self.avatarRingView addSubview:self.avatarView];
    [self.avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.avatarRingView);
    }];

    self.textWrapView = [UIView new];
    [self.userCard addSubview:self.textWrapView];
    [self.textWrapView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.avatarRingView.mas_trailing).offset(12);
        make.trailing.equalTo(self.userCard).offset(-15);
        make.centerY.equalTo(self.userCard);
    }];

    self.userNameLabel = [UILabel new];
    self.userNameLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    self.userNameLabel.textColor = [UIColor blackColor];
    [self.textWrapView addSubview:self.userNameLabel];
    [self.userNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.equalTo(self.textWrapView);
        make.trailing.lessThanOrEqualTo(self.textWrapView);
    }];

    self.userStatusLabel = [UILabel new];
    self.userStatusLabel.font = [UIFont systemFontOfSize:14];
    self.userStatusLabel.textColor = kIATextStatus;
    [self.textWrapView addSubview:self.userStatusLabel];
    [self.userStatusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.textWrapView);
        make.top.equalTo(self.userNameLabel.mas_bottom).offset(4);
        make.trailing.lessThanOrEqualTo(self.textWrapView);
        make.bottom.equalTo(self.textWrapView);
    }];

    self.conditionTitleLabel = [UILabel new];
    self.conditionTitleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    self.conditionTitleLabel.textColor = [UIColor blackColor];
    [self.view addSubview:self.conditionTitleLabel];
    [self.conditionTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.userCard.mas_bottom).offset(12);
        make.leading.equalTo(self.view).offset(16);
    }];

    UIView *cardsRow = [UIView new];
    [self.view addSubview:cardsRow];
    [cardsRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.conditionTitleLabel.mas_bottom).offset(9);
        make.leading.equalTo(self.view).offset(kIACardSideInset);
        make.trailing.equalTo(self.view).offset(-kIACardSideInset);
        make.height.mas_equalTo(kIACertCardH);
    }];

    self.professionalCard = [self makeCertCardWithTitleKey:@"auth_professional_title" descKey:@"auth_professional_desc" buttonKey:@"auth_start_cert" tag:0];
    [cardsRow addSubview:self.professionalCard];
    [self.professionalCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.bottom.equalTo(cardsRow);
    }];

    self.realNameCard = [self makeCertCardWithTitleKey:@"auth_realname_title" descKey:@"auth_realname_desc" buttonKey:@"auth_start_cert" tag:1];
    [cardsRow addSubview:self.realNameCard];
    [self.realNameCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.top.bottom.equalTo(cardsRow);
        make.leading.equalTo(self.professionalCard.mas_trailing).offset(kIACardGap);
        make.width.equalTo(self.professionalCard);
    }];

    self.professionalCertButton = [self firstButtonInSubviewTree:self.professionalCard];
    self.realNameCertButton = [self firstButtonInSubviewTree:self.realNameCard];
}

- (UIView *)makeCertCardWithTitleKey:(NSString *)titleKey descKey:(NSString *)descKey buttonKey:(NSString *)btnKey tag:(NSInteger)tag {
    UIView *card = [UIView new];
    card.backgroundColor = kIACardBg;
    card.layer.cornerRadius = 6;
    card.layer.shadowColor = [UIColor blackColor].CGColor;
    card.layer.shadowOpacity = 0.12;
    card.layer.shadowOffset = CGSizeMake(0, 2);
    card.layer.shadowRadius = 4;
    card.tag = tag;

    UILabel *titleL = [UILabel new];
    titleL.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    titleL.textColor = kIATextStatus;
    titleL.text = NSLocalizedString(titleKey, nil);
    [card addSubview:titleL];
    [titleL mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(card).offset(14);
        make.leading.equalTo(card).offset(12);
        make.trailing.equalTo(card).offset(-12);
    }];

    UILabel *descL = [UILabel new];
    descL.font = [UIFont systemFontOfSize:12];
    descL.textColor = kIATextMuted;
    descL.text = NSLocalizedString(descKey, nil);
    descL.numberOfLines = 2;
    [card addSubview:descL];
    [descL mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleL.mas_bottom).offset(6);
        make.leading.trailing.equalTo(titleL);
    }];

    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.backgroundColor = kIAButtonGreen;
    static CGFloat const kBtnH = 36.f;
    btn.layer.cornerRadius = kBtnH / 2.f;
    btn.layer.shadowColor = [UIColor blackColor].CGColor;
    btn.layer.shadowOpacity = 0.19f;
    btn.layer.shadowOffset = CGSizeMake(0, 2);
    btn.layer.shadowRadius = 4;
    btn.layer.masksToBounds = NO;
    [btn setTitle:NSLocalizedString(btnKey, nil) forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    btn.tag = tag;
    [btn addTarget:self action:@selector(onCertTapped:) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:btn];
    [btn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(card).offset(10);
        make.trailing.equalTo(card).offset(-10);
        make.top.equalTo(descL.mas_bottom).offset(10);
        make.height.mas_equalTo(kBtnH);
        make.bottom.equalTo(card).offset(-12);
    }];

    return card;
}

- (UIButton *)firstButtonInSubviewTree:(UIView *)root {
    if ([root isKindOfClass:[UIButton class]]) {
        return (UIButton *)root;
    }
    for (UIView *v in root.subviews) {
        UIButton *b = [self firstButtonInSubviewTree:v];
        if (b) {
            return b;
        }
    }
    return nil;
}

- (NSInteger)approvedIdentityCount {
    PNVerificationStatus *st = [VerificationRequest shared].cachedVerificationStatus;
    BOOL useAPI = st && (st.professionalStatus.length > 0 || st.realnameStatus.length > 0);
    if (useAPI) {
        NSInteger n = 0;
        if (IAStatusIsApproved(st.professionalStatus)) {
            n++;
        }
        if (IAStatusIsApproved(st.realnameStatus)) {
            n++;
        }
        return n;
    }
    NSInteger n = 0;
    if ([AuthStateStore isProfessionalAuthCompleted]) {
        n++;
    }
    if ([AuthStateStore isRealNameAuthCompleted]) {
        n++;
    }
    return n;
}

- (NSString *)effectiveProfessionalStatusForUI {
    PNVerificationStatus *st = [VerificationRequest shared].cachedVerificationStatus;
    return IAEffectiveStatus(st.professionalStatus, [AuthStateStore isProfessionalAuthCompleted]);
}

- (NSString *)effectiveRealnameStatusForUI {
    PNVerificationStatus *st = [VerificationRequest shared].cachedVerificationStatus;
    return IAEffectiveStatus(st.realnameStatus, [AuthStateStore isRealNameAuthCompleted]);
}

- (void)applyCertButtonStyleDefault:(UIButton *)btn {
    btn.backgroundColor = kIAButtonGreen;
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.layer.shadowOpacity = 0.19f;
    btn.enabled = YES;
}

- (void)applyCertButtonStyleMuted:(UIButton *)btn {
    btn.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1.0];
    [btn setTitleColor:[UIColor colorWithWhite:0.38 alpha:1.0] forState:UIControlStateNormal];
    btn.layer.shadowOpacity = 0.f;
}

- (void)updateCertButton:(UIButton *)btn statusString:(NSString *)raw {
    NSString *s = raw ?: @"";
    s = [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (IAStatusIsApproved(s)) {
        [btn setTitle:NSLocalizedString(@"auth_cert_status_approved", nil) ?: @"已认证" forState:UIControlStateNormal];
        [self applyCertButtonStyleMuted:btn];
        btn.enabled = NO;
        return;
    }
    if (IAStatusIsPending(s)) {
        [btn setTitle:NSLocalizedString(@"auth_cert_status_pending", nil) ?: @"审核中" forState:UIControlStateNormal];
        [self applyCertButtonStyleMuted:btn];
        btn.enabled = NO;
        return;
    }
    if (IAStatusNeedsRetry(s)) {
        [btn setTitle:NSLocalizedString(@"auth_cert_retry", nil) ?: @"重新认证" forState:UIControlStateNormal];
        [self applyCertButtonStyleDefault:btn];
        btn.enabled = YES;
        return;
    }

    [btn setTitle:NSLocalizedString(@"auth_start_cert", nil) ?: @"开始认证" forState:UIControlStateNormal];
    [self applyCertButtonStyleDefault:btn];
    btn.enabled = YES;
}

- (void)refreshVerificationSummary {
    NSInteger n = [self approvedIdentityCount];
    if (n <= 0) {
        self.userStatusLabel.attributedText = nil;
        self.userStatusLabel.text = NSLocalizedString(@"auth_status_uncertified", nil);
        return;
    }

    NSString *num = [NSString stringWithFormat:@"%ld", (long)n];
    NSString *fmt = NSLocalizedString(@"auth_status_n_identities", nil);
    if (fmt.length == 0) {
        fmt = @"已认证%@种身份";
    }
    NSString *plain = [NSString stringWithFormat:fmt, num];

    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:plain
                                                                             attributes:@{
                                                                                 NSFontAttributeName: [UIFont systemFontOfSize:14],
                                                                                 NSForegroundColorAttributeName: kIATextStatus
                                                                             }];
    NSRange r = [plain rangeOfString:num];
    if (r.location != NSNotFound) {
        UIFont *bebas = [UIFont fontWithName:@"BebasNeue-Regular" size:14];
        if (bebas) {
            [attr addAttributes:@{ NSFontAttributeName: bebas } range:r];
        }
    }
    self.userStatusLabel.attributedText = attr;
}

- (void)refreshVerificationUI {
    [self refreshVerificationSummary];
    [self updateCertButton:self.professionalCertButton statusString:[self effectiveProfessionalStatusForUI]];
    [self updateCertButton:self.realNameCertButton statusString:[self effectiveRealnameStatusForUI]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    __weak typeof(self) weakSelf = self;
    if (AuthManager.sharedManager.isLoggedIn) {
        [[VerificationRequest shared] fetchStatusSuccess:^(HTTPResponse * _Nullable responseObject) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf refreshUserCard];
            });
        } failure:^(NSError * _Nonnull error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf refreshUserCard];
            });
        }];
    } else {
        [self refreshUserCard];
    }
}

- (void)refreshUserCard {
    if (!AuthManager.sharedManager.isLoggedIn) {
        self.userNameLabel.text = @"--";
        self.userStatusLabel.attributedText = nil;
        self.userStatusLabel.text = NSLocalizedString(@"auth_status_uncertified", nil);
        [self.avatarView sd_cancelCurrentImageLoad];
        if (@available(iOS 13.0, *)) {
            self.avatarView.image = [UIImage systemImageNamed:@"person.circle.fill"];
            self.avatarView.tintColor = kIATextMuted;
        }
        [self refreshVerificationUI];
        return;
    }
    User *u = AuthManager.sharedManager.user;
    UserProfile *p = u.profile;
    NSString *name = (p.nickname.length > 0) ? p.nickname : (u.nickname.length > 0 ? u.nickname : @"-");
    self.userNameLabel.text = name;
    NSString *avStr = p.avatar.length > 0 ? p.avatar : u.avatar;
    NSURL *url = avStr.length > 0 ? [NSURL URLWithString:avStr] : nil;
    UIImage *ph = nil;
    if (@available(iOS 13.0, *)) {
        ph = [UIImage systemImageNamed:@"person.circle.fill"];
    }
    __weak typeof(self) weakSelf = self;
    [self.avatarView sd_setImageWithURL:url placeholderImage:ph completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (image && !error) {
            weakSelf.avatarView.tintColor = nil;
        } else if (@available(iOS 13.0, *)) {
            weakSelf.avatarView.tintColor = kIATextMuted;
        }
    }];

    [self refreshVerificationUI];
}

- (void)updateLocalizedStrings {
    [super updateLocalizedStrings];
    self.navTitleLabel.text = NSLocalizedString(@"auth_identity_title", nil);
    self.sectionTitleLabel.text = NSLocalizedString(@"auth_pro_identity_title", nil);
    self.sectionDescLabel.text = NSLocalizedString(@"auth_pro_identity_desc", nil);
    self.conditionTitleLabel.text = NSLocalizedString(@"auth_conditions_title", nil);
    [self refreshUserCard];
}

- (void)onBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onCertTapped:(UIButton *)sender {
    if (!sender.isEnabled) {
        return;
    }
    if (sender.tag == 0) {
        ProfessionalAuthViewController *vc = [ProfessionalAuthViewController new];
        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    } else if (sender.tag == 1) {
        RealNameAuthViewController *vc = [RealNameAuthViewController new];
        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

@end
