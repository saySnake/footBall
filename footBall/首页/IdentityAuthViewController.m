//
//  IdentityAuthViewController.m
//  footBall
//

#import "IdentityAuthViewController.h"
#import <Masonry/Masonry.h>

// 设计图规范色
#define kIANavHeaderBg  [UIColor colorWithRed:0.114 green:0.188 blue:0.176 alpha:1.0]  // #1D302D
#define kIAPageBg       [UIColor colorWithRed:0.965 green:0.965 blue:0.965 alpha:1.0]  // #F6F6F6
#define kIACardBg       [UIColor whiteColor]
#define kIAButtonGreen  [UIColor colorWithRed:0.18 green:0.424 blue:0.329 alpha:1.0]   // #2E6C54
#define kIATextDark     [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0]
#define kIATextGray     [UIColor colorWithRed:0.45 green:0.45 blue:0.45 alpha:1.0]

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
@end

@implementation IdentityAuthViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hidesBottomBarWhenPushed = YES;
    self.shouldShowNavigationBar = NO;
    self.view.backgroundColor = kIAPageBg;
}


- (void)setupUI {
    // 顶部深色区域：导航栏 + 身份职业认证标题区（设计图 #1D302D）
    self.headerView = [UIView new];
    self.headerView.backgroundColor = kIANavHeaderBg;
    [self.view addSubview:self.headerView];
    [self.headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
        make.height.mas_equalTo(182);
    }];

    // 导航行：返回按钮（左上角固定位置，不依赖 safeArea）
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    if (@available(iOS 13.0, *)) {
        [backBtn setImage:[UIImage systemImageNamed:@"arrow.left"] forState:UIControlStateNormal];
    }
    backBtn.tintColor = [UIColor whiteColor];
    [backBtn addTarget:self action:@selector(onBack) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView addSubview:backBtn];
    [backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.headerView).offset(16);
        make.top.equalTo(self.headerView).offset(50);
        make.size.mas_equalTo(CGSizeMake(36, 36));
    }];

    // 标题「认证身份」居中
    self.navTitleLabel = [UILabel new];
    self.navTitleLabel.font = [UIFont boldSystemFontOfSize:17];
    self.navTitleLabel.textColor = [UIColor whiteColor];
    self.navTitleLabel.text = NSLocalizedString(@"auth_identity_title", nil);
    [self.headerView addSubview:self.navTitleLabel];
    [self.navTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.headerView);
        make.centerY.equalTo(backBtn);
    }];

    // 身份职业认证大标题 + 说明（设计图：大标题粗体白字，说明较小较浅白字）
    self.sectionTitleLabel = [UILabel new];
    self.sectionTitleLabel.font = [UIFont boldSystemFontOfSize:22];
    self.sectionTitleLabel.textColor = [UIColor whiteColor];
    self.sectionTitleLabel.numberOfLines = 0;
    self.sectionTitleLabel.text = NSLocalizedString(@"auth_pro_identity_title", nil);
    [self.headerView addSubview:self.sectionTitleLabel];
    [self.sectionTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(backBtn.mas_bottom).offset(20);
        make.leading.equalTo(self.headerView).offset(20);
        make.trailing.equalTo(self.headerView).offset(-20);
    }];

    self.sectionDescLabel = [UILabel new];
    self.sectionDescLabel.font = [UIFont systemFontOfSize:14];
    self.sectionDescLabel.textColor = [UIColor colorWithWhite:0.82 alpha:1.0];
    self.sectionDescLabel.numberOfLines = 0;
    self.sectionDescLabel.text = NSLocalizedString(@"auth_pro_identity_desc", nil);
    [self.headerView addSubview:self.sectionDescLabel];
    [self.sectionDescLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.sectionTitleLabel.mas_bottom).offset(8);
        make.leading.trailing.equalTo(self.sectionTitleLabel);
    }];

    // 中间用户信息白卡：与头部底缘仅少量重叠，不遮挡「适用于具有职业身份的用户...」
    self.userCard = [UIView new];
    self.userCard.backgroundColor = kIACardBg;
    self.userCard.layer.cornerRadius = 16;
    if (@available(iOS 11.0, *)) {
        self.userCard.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    }
    self.userCard.layer.shadowColor = [UIColor blackColor].CGColor;
    self.userCard.layer.shadowOpacity = 0.08;
    self.userCard.layer.shadowOffset = CGSizeMake(0, 4);
    self.userCard.layer.shadowRadius = 12;
    [self.view addSubview:self.userCard];
    [self.userCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView.mas_bottom).offset(-6);
        make.leading.equalTo(self.view).offset(16);
        make.trailing.equalTo(self.view).offset(-16);
        make.height.mas_equalTo(92);
    }];

    // 左侧圆形头像 + 紫粉渐变环（设计图：左侧头像，与右侧文字垂直居中）
    self.avatarRingView = [UIView new];
    self.avatarRingView.layer.cornerRadius = 28;
    self.avatarRingView.clipsToBounds = YES;
    [self.userCard addSubview:self.avatarRingView];
    [self.avatarRingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.userCard).offset(20);
        make.centerY.equalTo(self.userCard);
        make.size.mas_equalTo(CGSizeMake(56, 56));
    }];
    CAGradientLayer *ringGrad = [CAGradientLayer layer];
    ringGrad.colors = @[
        (__bridge id)[UIColor colorWithRed:0.55 green:0.35 blue:0.85 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:0.85 green:0.45 blue:0.65 alpha:1.0].CGColor,
    ];
    ringGrad.startPoint = CGPointMake(0, 0);
    ringGrad.endPoint = CGPointMake(1, 1);
    ringGrad.frame = CGRectMake(0, 0, 56, 56);
    [self.avatarRingView.layer addSublayer:ringGrad];

    self.avatarView = [UIImageView new];
    self.avatarView.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1.0];
    self.avatarView.layer.cornerRadius = 24;
    self.avatarView.clipsToBounds = YES;
    self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
    if (@available(iOS 13.0, *)) {
        self.avatarView.image = [UIImage systemImageNamed:@"person.circle.fill"];
        self.avatarView.tintColor = kIATextGray;
    }
    [self.avatarRingView addSubview:self.avatarView];
    [self.avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.avatarRingView);
        make.size.mas_equalTo(CGSizeMake(48, 48));
    }];

    // 右侧文字容器：姓名 + 状态，整体在卡片内垂直居中
    self.textWrapView = [UIView new];
    [self.userCard addSubview:self.textWrapView];
    [self.textWrapView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.avatarRingView.mas_trailing).offset(18);
        make.trailing.equalTo(self.userCard).offset(-20);
        make.centerY.equalTo(self.userCard);
    }];

    self.userNameLabel = [UILabel new];
    self.userNameLabel.font = [UIFont boldSystemFontOfSize:17];
    self.userNameLabel.textColor = kIATextDark;
    [self.textWrapView addSubview:self.userNameLabel];
    [self.userNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.equalTo(self.textWrapView);
        make.trailing.lessThanOrEqualTo(self.textWrapView);
    }];

    self.userStatusLabel = [UILabel new];
    self.userStatusLabel.font = [UIFont systemFontOfSize:14];
    self.userStatusLabel.textColor = kIATextGray;
    [self.textWrapView addSubview:self.userStatusLabel];
    [self.userStatusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.textWrapView);
        make.top.equalTo(self.userNameLabel.mas_bottom).offset(5);
        make.trailing.lessThanOrEqualTo(self.textWrapView);
        make.bottom.equalTo(self.textWrapView);
    }];

    // 认证条件标题（设计图：浅灰背景上的粗体深色标题）
    self.conditionTitleLabel = [UILabel new];
    self.conditionTitleLabel.font = [UIFont boldSystemFontOfSize:17];
    self.conditionTitleLabel.textColor = kIATextDark;
    [self.view addSubview:self.conditionTitleLabel];
    [self.conditionTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.userCard.mas_bottom).offset(28);
        make.leading.equalTo(self.view).offset(20);
    }];

    // 两列认证卡片（等宽、间距一致、圆角、阴影）
    UIView *cardsRow = [UIView new];
    [self.view addSubview:cardsRow];
    [cardsRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.conditionTitleLabel.mas_bottom).offset(16);
        make.leading.equalTo(self.view).offset(16);
        make.trailing.equalTo(self.view).offset(-16);
    }];

    CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
    CGFloat margin = 16;
    CGFloat gap = 12;
    CGFloat cardW = (screenW - margin * 2 - gap) / 2.0;

    self.professionalCard = [self makeCertCardWithTitleKey:@"auth_professional_title" descKey:@"auth_professional_desc" buttonKey:@"auth_start_cert" tag:0];
    [cardsRow addSubview:self.professionalCard];
    [self.professionalCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.bottom.equalTo(cardsRow);
        make.width.mas_equalTo(cardW);
    }];

    self.realNameCard = [self makeCertCardWithTitleKey:@"auth_realname_title" descKey:@"auth_realname_desc" buttonKey:@"auth_start_cert" tag:1];
    [cardsRow addSubview:self.realNameCard];
    [self.realNameCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.professionalCard.mas_trailing).offset(gap);
        make.trailing.top.bottom.equalTo(cardsRow);
        make.width.mas_equalTo(cardW);
    }];
}

- (UIView *)makeCertCardWithTitleKey:(NSString *)titleKey descKey:(NSString *)descKey buttonKey:(NSString *)btnKey tag:(NSInteger)tag {
    UIView *card = [UIView new];
    card.backgroundColor = kIACardBg;
    card.layer.cornerRadius = 14;
    card.layer.shadowColor = [UIColor blackColor].CGColor;
    card.layer.shadowOpacity = 0.06;
    card.layer.shadowOffset = CGSizeMake(0, 2);
    card.layer.shadowRadius = 8;
    card.tag = tag;

    UILabel *titleL = [UILabel new];
    titleL.font = [UIFont boldSystemFontOfSize:16];
    titleL.textColor = kIATextDark;
    titleL.text = NSLocalizedString(titleKey, nil);
    [card addSubview:titleL];
    [titleL mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.equalTo(card).offset(16);
        make.trailing.equalTo(card).offset(-16);
    }];

    UILabel *descL = [UILabel new];
    descL.font = [UIFont systemFontOfSize:13];
    descL.textColor = kIATextGray;
    descL.text = NSLocalizedString(descKey, nil);
    descL.numberOfLines = 2;
    [card addSubview:descL];
    [descL mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleL.mas_bottom).offset(8);
        make.leading.trailing.equalTo(titleL);
    }];

    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.backgroundColor = kIAButtonGreen;
    btn.layer.cornerRadius = 10;
    [btn setTitle:NSLocalizedString(btnKey, nil) forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    btn.tag = tag;
    [btn addTarget:self action:@selector(onCertTapped:) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:btn];
    [btn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(card).offset(16);
        make.trailing.equalTo(card).offset(-16);
        make.top.equalTo(descL.mas_bottom).offset(16);
        make.bottom.equalTo(card).offset(-16);
        make.height.mas_equalTo(44);
    }];

    return card;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CAGradientLayer *grad = (CAGradientLayer *)self.avatarRingView.layer.sublayers.firstObject;
    if ([grad isKindOfClass:[CAGradientLayer class]]) {
        grad.frame = self.avatarRingView.bounds;
    }
}

- (void)updateLocalizedStrings {
    [super updateLocalizedStrings];
    self.navTitleLabel.text = NSLocalizedString(@"auth_identity_title", nil);
    self.sectionTitleLabel.text = NSLocalizedString(@"auth_pro_identity_title", nil);
    self.sectionDescLabel.text = NSLocalizedString(@"auth_pro_identity_desc", nil);
    self.userNameLabel.text = @"Allenger";
    self.userStatusLabel.text = NSLocalizedString(@"auth_status_uncertified", nil);
    self.conditionTitleLabel.text = NSLocalizedString(@"auth_conditions_title", nil);
}

- (void)onBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onCertTapped:(UIButton *)sender {
    (void)sender;
    // 可在此 push 实名认证 / 职业认证 子页
}

@end
