//
//  ProfileViewController.m
//  footBall
//

#import "ProfileViewController.h"
#import "SettingsViewController.h"
#import "PersonalInfoViewController.h"
#import "MyTeamsViewController.h"
#import <Masonry/Masonry.h>

#define kProfileHeaderBg  [UIColor colorWithRed:0.04 green:0.14 blue:0.12 alpha:1.0]
#define kProfilePageBg    [UIColor colorWithWhite:0.95 alpha:1.0]
#define kProfileCardBg    [UIColor whiteColor]
#define kProfileGreen     [UIColor colorWithRed:0.10 green:0.36 blue:0.28 alpha:1.0]

// ─────────────────────────────────────────────
#pragma mark - Team model
// ─────────────────────────────────────────────
@interface ProfileTeam : NSObject
@property (nonatomic, copy)   NSString *nameKey;
@property (nonatomic, copy)   NSString *iconSystemName;
@property (nonatomic, strong) UIColor  *iconTint;
@end
@implementation ProfileTeam @end

// ─────────────────────────────────────────────
#pragma mark - Team cell
// ─────────────────────────────────────────────
@interface ProfileTeamCell : UICollectionViewCell
@property (nonatomic, strong) UIView      *iconBg;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel     *nameLabel;
- (void)configureWithTeam:(ProfileTeam *)team;
@end

@implementation ProfileTeamCell
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _iconBg = [UIView new];
        _iconBg.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
        _iconBg.layer.cornerRadius = 30;
        _iconBg.clipsToBounds = YES;

        _iconView = [UIImageView new];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        _iconView.clipsToBounds = YES;

        _nameLabel = [UILabel new];
        _nameLabel.font = [UIFont systemFontOfSize:11];
        _nameLabel.textColor = [UIColor darkGrayColor];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        _nameLabel.numberOfLines = 2;

        [self.contentView addSubview:_iconBg];
        [_iconBg addSubview:_iconView];
        [self.contentView addSubview:_nameLabel];

        [_iconBg mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView).offset(4);
            make.centerX.equalTo(self.contentView);
            make.size.mas_equalTo(CGSizeMake(60, 60));
        }];
        [_iconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(_iconBg);
            make.size.mas_equalTo(CGSizeMake(38, 38));
        }];
        [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_iconBg.mas_bottom).offset(5);
            make.centerX.equalTo(self.contentView);
            make.leading.trailing.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 2, 0, 2));
        }];
    }
    return self;
}
- (void)configureWithTeam:(ProfileTeam *)team {
    self.nameLabel.text = NSLocalizedString(team.nameKey, nil);
    if (@available(iOS 13.0, *)) {
        self.iconView.image = [UIImage systemImageNamed:team.iconSystemName];
        self.iconView.tintColor = team.iconTint;
    }
}
@end

// ─────────────────────────────────────────────
#pragma mark - ProfileViewController
// ─────────────────────────────────────────────
@interface ProfileViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView       *contentWrap;

// Header
@property (nonatomic, strong) UIView      *headerView;
@property (nonatomic, strong) UILabel     *nameLabel;
@property (nonatomic, strong) UILabel     *badgeLabel;
@property (nonatomic, strong) UILabel     *idLabel;

// Stats
@property (nonatomic, strong) UILabel *friendsNumLabel;
@property (nonatomic, strong) UILabel *friendsTitleLabel;
@property (nonatomic, strong) UILabel *followNumLabel;
@property (nonatomic, strong) UILabel *followTitleLabel;
@property (nonatomic, strong) UILabel *stampsNumLabel;
@property (nonatomic, strong) UILabel *stampsTitleLabel;

// Teams card
@property (nonatomic, strong) UICollectionView *teamsCV;
@property (nonatomic, strong) NSArray<ProfileTeam *> *teams;
@property (nonatomic, strong) UILabel *teamsSectionLabel;

// Menu
@property (nonatomic, strong) NSArray<NSString *> *menuKeys;
@property (nonatomic, strong) NSArray<UIControl *> *menuControls;

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [self buildData];
    [super viewDidLoad];
    self.shouldShowNavigationBar = NO;
    self.view.backgroundColor = kProfilePageBg;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat tabH = self.tabBarController.tabBar.bounds.size.height;
    self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, tabH, 0);
}

- (void)buildData {
    NSArray *raw = @[
        @[@"team_name_mancity",   @"soccerball",    @"#6CABDD"],
        @[@"team_name_wolves",    @"pawprint.fill",  @"#FDB913"],
        @[@"team_name_liverpool", @"flame.fill",     @"#C8102E"],
        @[@"team_name_nforest",   @"tree.fill",      @"#DD0000"],
    ];
    NSMutableArray *arr = [NSMutableArray array];
    for (NSArray *r in raw) {
        ProfileTeam *t = [ProfileTeam new];
        t.nameKey = r[0];
        t.iconSystemName = r[1];
        NSString *hex = [r[2] stringByReplacingOccurrencesOfString:@"#" withString:@""];
        unsigned int rgb = 0;
        [[NSScanner scannerWithString:hex] scanHexInt:&rgb];
        t.iconTint = [UIColor colorWithRed:((rgb>>16)&0xFF)/255.0
                                     green:((rgb>>8)&0xFF)/255.0
                                      blue:(rgb&0xFF)/255.0
                                     alpha:1.0];
        [arr addObject:t];
    }
    self.teams = arr;
    self.menuKeys = @[@"profile_my_info", @"profile_my_stamps", @"profile_id_verify"];
}

- (void)setupUI {
    // ── ScrollView ───────────────────────────
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.backgroundColor = kProfilePageBg;
    if (@available(iOS 11.0, *)) {
        // 取消系统自动安全区 inset，避免头部出现空白
        self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [self.view addSubview:self.scrollView];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    self.contentWrap = [[UIView alloc] init];
    [self.scrollView addSubview:self.contentWrap];
    [self.contentWrap mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
    }];

    // ── Header dark block (全宽，底部圆角) ──
    self.headerView = [UIView new];
    self.headerView.backgroundColor = kProfileHeaderBg;
    self.headerView.layer.cornerRadius = 20;
    self.headerView.layer.maskedCorners = kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
    self.headerView.clipsToBounds = YES;
    [self.contentWrap addSubview:self.headerView];
    [self.headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.contentWrap);
    }];

    // Settings button - top right
    UIButton *settingsBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightMedium];
        [settingsBtn setImage:[[UIImage systemImageNamed:@"gearshape"] imageWithConfiguration:cfg]
                     forState:UIControlStateNormal];
    }
    settingsBtn.tintColor = [UIColor whiteColor];
    [settingsBtn addTarget:self action:@selector(openSettings) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView addSubview:settingsBtn];
    [settingsBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView.mas_safeAreaLayoutGuideTop).offset(10);
        make.trailing.equalTo(self.headerView).offset(-14);
        make.size.mas_equalTo(CGSizeMake(36, 36));
    }];

    // ── Avatar container (渐变圆环) ───────────
    UIView *ringView = [UIView new];
    ringView.layer.cornerRadius = 44;
    ringView.clipsToBounds = YES;
    CAGradientLayer *grad = [CAGradientLayer layer];
    grad.colors = @[
        (__bridge id)[UIColor colorWithRed:0.36 green:0.20 blue:0.90 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:0.20 green:0.60 blue:0.95 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:0.95 green:0.40 blue:0.20 alpha:1.0].CGColor,
    ];
    grad.startPoint = CGPointMake(0, 0);
    grad.endPoint   = CGPointMake(1, 1);
    grad.frame = CGRectMake(0, 0, 88, 88);
    [ringView.layer addSublayer:grad];
    [self.headerView addSubview:ringView];
    [ringView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(settingsBtn.mas_bottom).offset(4);
        make.centerX.equalTo(self.headerView);
        make.size.mas_equalTo(CGSizeMake(88, 88));
    }];

    UIImageView *avatarView = [UIImageView new];
    avatarView.layer.cornerRadius = 37;
    avatarView.clipsToBounds = YES;
    avatarView.contentMode = UIViewContentModeScaleAspectFill;
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:64 weight:UIImageSymbolWeightThin];
        avatarView.image = [[UIImage systemImageNamed:@"person.crop.circle.fill"] imageWithConfiguration:cfg];
        avatarView.tintColor = [UIColor colorWithRed:0.55 green:0.40 blue:0.85 alpha:1.0];
    }
    [ringView addSubview:avatarView];
    [avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(ringView);
        make.size.mas_equalTo(CGSizeMake(74, 74));
    }];

    // VIP 标签（贴在头像底部中间）
    UIView *vipBadge = [UIView new];
    vipBadge.backgroundColor = [UIColor colorWithRed:0.98 green:0.72 blue:0.08 alpha:1.0];
    vipBadge.layer.cornerRadius = 8;
    [self.headerView addSubview:vipBadge];
    [vipBadge mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(ringView);
        // 轻微上移，贴合设计图的重叠感
        make.bottom.equalTo(ringView).offset(-2);
        make.height.mas_equalTo(16);
    }];
    UILabel *vipLabel = [UILabel new];
    vipLabel.text = @"VIP";
    vipLabel.font = [UIFont boldSystemFontOfSize:9];
    vipLabel.textColor = [UIColor whiteColor];
    [vipBadge addSubview:vipLabel];
    [vipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(vipBadge);
        make.leading.equalTo(vipBadge).offset(6);
        make.trailing.equalTo(vipBadge).offset(-6);
    }];

    // ── 姓名 + 记者标签 ──────────────────────
    UIView *nameRow = [UIView new];
    [self.headerView addSubview:nameRow];
    [nameRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(ringView.mas_bottom).offset(10);
        make.centerX.equalTo(self.headerView);
    }];

    self.nameLabel = [UILabel new];
    self.nameLabel.text = @"Arisha Ireen";
    self.nameLabel.font = [UIFont boldSystemFontOfSize:20];
    self.nameLabel.textColor = [UIColor whiteColor];
    [nameRow addSubview:self.nameLabel];
    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.bottom.equalTo(nameRow);
    }];

    UIView *tagView = [UIView new];
    tagView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.18];
    tagView.layer.cornerRadius = 6;
    tagView.layer.borderWidth = 1;
    tagView.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.35].CGColor;
    [nameRow addSubview:tagView];
    [tagView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.nameLabel.mas_trailing).offset(6);
        make.centerY.equalTo(nameRow);
        make.trailing.equalTo(nameRow);
        make.height.mas_equalTo(18);
    }];

    self.badgeLabel = [UILabel new];
    self.badgeLabel.font = [UIFont systemFontOfSize:10];
    self.badgeLabel.textColor = [UIColor whiteColor];
    [tagView addSubview:self.badgeLabel];
    [self.badgeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(tagView);
        make.leading.equalTo(tagView).offset(5);
        make.trailing.equalTo(tagView).offset(-5);
    }];

    // ID
    self.idLabel = [UILabel new];
    self.idLabel.text = [NSString stringWithFormat:NSLocalizedString(@"profile_id_format", nil), @"145477487"];
    self.idLabel.font = [UIFont systemFontOfSize:13];
    self.idLabel.textColor = [UIColor colorWithWhite:0.72 alpha:1.0];
    [self.headerView addSubview:self.idLabel];
    [self.idLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(nameRow.mas_bottom).offset(5);
        make.centerX.equalTo(self.headerView);
    }];

    // ── Stats row（设计图：直接在深色背景上展示，无额外底色条） ──────────────
    UIView *statsBar = [UIView new];
    statsBar.backgroundColor = [UIColor clearColor];
    [self.headerView addSubview:statsBar];
    [statsBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.idLabel.mas_bottom).offset(16);
        make.leading.trailing.equalTo(self.headerView);
        make.height.mas_equalTo(56);
        make.bottom.equalTo(self.headerView).offset(-18);
    }];

    NSArray *nums   = @[@"65",  @"123", @"13"];
    NSArray *numLbs = @[self.friendsNumLabel   = [UILabel new],
                        self.followNumLabel    = [UILabel new],
                        self.stampsNumLabel    = [UILabel new]];
    NSArray *txtLbs = @[self.friendsTitleLabel = [UILabel new],
                        self.followTitleLabel  = [UILabel new],
                        self.stampsTitleLabel  = [UILabel new]];

    for (NSInteger i = 0; i < 3; i++) {
        UIView *col = [UIView new];
        [statsBar addSubview:col];
        [col mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(statsBar);
            if (i == 0)      make.leading.equalTo(statsBar);
            else             make.leading.equalTo(((UIView *)statsBar.subviews[i - 1]).mas_trailing);
            make.width.equalTo(statsBar).multipliedBy(1.0 / 3.0);
        }];

        UILabel *n = numLbs[i];
        n.text = nums[i];
        n.font = [UIFont boldSystemFontOfSize:20];
        n.textColor = [UIColor whiteColor];
        n.textAlignment = NSTextAlignmentCenter;
        [col addSubview:n];
        [n mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(col);
            make.top.equalTo(col).offset(8);
        }];

        UILabel *t = txtLbs[i];
        t.font = [UIFont systemFontOfSize:11];
        t.textColor = [UIColor colorWithWhite:0.65 alpha:1.0];
        t.textAlignment = NSTextAlignmentCenter;
        [col addSubview:t];
        [t mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(col);
            make.top.equalTo(n.mas_bottom).offset(2);
        }];

        // 设计图无明显分隔线，这里不加 divider
    }

    // ── 我关注的球队 card ─────────────────────
    UIControl *teamsCard = [UIControl new];
    teamsCard.backgroundColor = kProfileCardBg;
    teamsCard.layer.cornerRadius = 12;
    teamsCard.clipsToBounds = YES;
    [teamsCard addTarget:self action:@selector(onMyTeams) forControlEvents:UIControlEventTouchUpInside];
    [self.contentWrap addSubview:teamsCard];
    [teamsCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView.mas_bottom).offset(12);
        make.leading.equalTo(self.contentWrap).offset(12);
        make.trailing.equalTo(self.contentWrap).offset(-12);
    }];

    self.teamsSectionLabel = [UILabel new];
    self.teamsSectionLabel.font = [UIFont boldSystemFontOfSize:15];
    self.teamsSectionLabel.textColor = [UIColor blackColor];
    [teamsCard addSubview:self.teamsSectionLabel];
    [self.teamsSectionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(teamsCard).offset(14);
        make.leading.equalTo(teamsCard).offset(14);
    }];

    UIImageView *teamsArrow = [UIImageView new];
    if (@available(iOS 13.0, *)) {
        teamsArrow.image = [UIImage systemImageNamed:@"chevron.right"];
        teamsArrow.tintColor = [UIColor colorWithWhite:0.65 alpha:1.0];
    }
    [teamsCard addSubview:teamsArrow];
    [teamsArrow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(teamsCard).offset(-14);
        make.centerY.equalTo(self.teamsSectionLabel);
        make.size.mas_equalTo(CGSizeMake(14, 14));
    }];

    UICollectionViewFlowLayout *fl = [[UICollectionViewFlowLayout alloc] init];
    fl.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    // 宽度用 delegate 动态计算，确保 4 个图标均匀分布且不滚动
    fl.itemSize = CGSizeMake(76, 90);
    fl.minimumInteritemSpacing = 16;
    fl.minimumLineSpacing = 16;
    fl.sectionInset = UIEdgeInsetsMake(0, 14, 0, 14);

    self.teamsCV = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:fl];
    self.teamsCV.backgroundColor = [UIColor clearColor];
    self.teamsCV.showsHorizontalScrollIndicator = NO;
    self.teamsCV.scrollEnabled = NO;
    self.teamsCV.dataSource = self;
    self.teamsCV.delegate   = self;
    [self.teamsCV registerClass:[ProfileTeamCell class] forCellWithReuseIdentifier:@"TeamCell"];
    [teamsCard addSubview:self.teamsCV];
    [self.teamsCV mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.teamsSectionLabel.mas_bottom).offset(8);
        make.leading.trailing.equalTo(teamsCard);
        make.height.mas_equalTo(96);
        make.bottom.equalTo(teamsCard).offset(-8);
    }];

    // ── 菜单：三条独立卡片（按原型图每行一张卡）─
    UIView *prevCard = nil;
    NSMutableArray *controls = [NSMutableArray array];
    for (NSInteger i = 0; i < self.menuKeys.count; i++) {
        NSString *key = self.menuKeys[i];
        UIControl *card = [UIControl new];
        card.backgroundColor = kProfileCardBg;
        card.layer.cornerRadius = 12;
        card.clipsToBounds = YES;
        card.tag = i;
        [card addTarget:self action:@selector(onMenuTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentWrap addSubview:card];
        [card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentWrap).offset(12);
            make.trailing.equalTo(self.contentWrap).offset(-12);
            make.height.mas_equalTo(52);
            if (prevCard) make.top.equalTo(prevCard.mas_bottom).offset(10);
            else          make.top.equalTo(teamsCard.mas_bottom).offset(12);
            if (i == self.menuKeys.count - 1) {
                make.bottom.equalTo(self.contentWrap).offset(-20);
            }
        }];

        UILabel *lbl = [UILabel new];
        lbl.text = NSLocalizedString(key, nil);
        lbl.font = [UIFont systemFontOfSize:15];
        lbl.textColor = [UIColor blackColor];
        [card addSubview:lbl];
        [lbl mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(card);
            make.leading.equalTo(card).offset(16);
        }];

        UIImageView *arr = [UIImageView new];
        if (@available(iOS 13.0, *)) {
            arr.image = [UIImage systemImageNamed:@"chevron.right"];
            arr.tintColor = [UIColor colorWithWhite:0.65 alpha:1.0];
        }
        arr.contentMode = UIViewContentModeScaleAspectFit;
        [card addSubview:arr];
        [arr mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(card);
            make.trailing.equalTo(card).offset(-14);
            make.size.mas_equalTo(CGSizeMake(14, 14));
        }];

        prevCard = card;
        [controls addObject:card];
    }
    self.menuControls = controls;
}

- (void)updateLocalizedStrings {
    [super updateLocalizedStrings];
    self.friendsTitleLabel.text  = NSLocalizedString(@"profile_stat_friends", nil);
    self.followTitleLabel.text   = NSLocalizedString(@"profile_stat_follow", nil);
    self.stampsTitleLabel.text   = NSLocalizedString(@"profile_stat_stamps", nil);
    self.teamsSectionLabel.text  = NSLocalizedString(@"profile_section_teams", nil);
    self.badgeLabel.text         = NSLocalizedString(@"profile_badge_verified", nil);
}

- (void)openSettings {
    SettingsViewController *vc = [[SettingsViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onMyTeams {
    MyTeamsViewController *vc = [MyTeamsViewController new];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onMenuTapped:(UIControl *)sender {
    NSInteger idx = sender.tag;
    if (idx < 0 || idx >= self.menuKeys.count) return;
    NSString *key = self.menuKeys[idx];
    if ([key isEqualToString:@"profile_my_info"]) {
        PersonalInfoViewController *vc = [[PersonalInfoViewController alloc] init];
        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)cv numberOfItemsInSection:(NSInteger)s { return self.teams.count; }

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)ip {
    ProfileTeamCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"TeamCell" forIndexPath:ip];
    [cell configureWithTeam:self.teams[ip.item]];
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    // 设计图：4 个球队均匀排布，左右内边距 14，中间间距 16
    CGFloat w = collectionView.bounds.size.width;
    CGFloat inset = 14;
    CGFloat spacing = 16;
    CGFloat available = w - inset * 2 - spacing * 3;
    CGFloat itemW = floor(available / 4.0);
    if (itemW < 70) itemW = 70;
    if (itemW > 86) itemW = 86;
    return CGSizeMake(itemW, 90);
}

@end
