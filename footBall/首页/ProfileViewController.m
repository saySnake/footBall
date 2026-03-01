//
//  ProfileViewController.m
//  footBall
//

#import "ProfileViewController.h"
#import "IdentityAuthViewController.h"
#import "PersonalInfoViewController.h"
#import "SettingsViewController.h"
#import "MyTeamsViewController.h"
#import "ProfileTeamsStore.h"
#import <Masonry/Masonry.h>

#define kProfileHeaderBg  [UIColor colorWithRed:0.04 green:0.14 blue:0.12 alpha:1.0]
#define kProfilePageBg    [UIColor colorWithRed:0.96 green:0.96 blue:0.96 alpha:1.0]
#define kProfileCardBg    [UIColor whiteColor]

static NSArray<NSString *> * _menuKeys(void) {
    return @[@"profile_my_info", @"profile_my_stamps", @"profile_id_verify"];
}

// 球队小图标+名字（用于首页展示的一行）
@interface ProfileTeamThumbView : UIView
@property (nonatomic, strong) UIView *iconBg;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *nameLabel;
- (void)configureWithTeam:(ProfileTeamItem *)team;
@end
@implementation ProfileTeamThumbView
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _iconBg = [UIView new];
        _iconBg.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
        _iconBg.layer.cornerRadius = 28;
        _iconBg.clipsToBounds = YES;
        _iconView = [UIImageView new];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        _nameLabel = [UILabel new];
        _nameLabel.font = [UIFont systemFontOfSize:11];
        _nameLabel.textColor = [UIColor darkGrayColor];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        _nameLabel.numberOfLines = 2;
        [self addSubview:_iconBg];
        [_iconBg addSubview:_iconView];
        [self addSubview:_nameLabel];
        [_iconBg mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.centerX.equalTo(self);
            make.size.mas_equalTo(CGSizeMake(56, 56));
        }];
        [_iconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(_iconBg);
            make.size.mas_equalTo(CGSizeMake(32, 32));
        }];
        [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_iconBg.mas_bottom).offset(6);
            make.leading.trailing.equalTo(self);
        }];
    }
    return self;
}
- (void)configureWithTeam:(ProfileTeamItem *)team {
    _nameLabel.text = team ? NSLocalizedString(team.nameKey, nil) : @"";
    if (@available(iOS 13.0, *)) {
        _iconView.image = [UIImage systemImageNamed:(team.iconName ?: @"circle.fill")];
        _iconView.tintColor = team.tintColor ?: [UIColor grayColor];
    }
}
@end

@interface ProfileViewController ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentWrap;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *vipLabel;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIView *reporterBadge;
@property (nonatomic, strong) UILabel *reporterLabel;
@property (nonatomic, strong) UILabel *idLabel;
@property (nonatomic, strong) UILabel *stat1Num;
@property (nonatomic, strong) UILabel *stat1Title;
@property (nonatomic, strong) UILabel *stat2Num;
@property (nonatomic, strong) UILabel *stat2Title;
@property (nonatomic, strong) UILabel *stat3Num;
@property (nonatomic, strong) UILabel *stat3Title;

@property (nonatomic, strong) UIControl *teamsCard;
@property (nonatomic, strong) UILabel *teamsTitleLabel;
@property (nonatomic, strong) UIImageView *teamsArrowView;
@property (nonatomic, strong) UIView *teamsContentWrap;   // 有数据时放横向滑动区
@property (nonatomic, strong) UIScrollView *teamsScrollView;
@property (nonatomic, strong) UIView *teamsScrollContentView;
@property (nonatomic, strong) UILabel *teamsEmptyLabel;    // 无数据时显示
@property (nonatomic, strong) NSArray<ProfileTeamItem *> *followedTeams;

@property (nonatomic, strong) NSArray<UIControl *> *menuControls;
@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.shouldShowNavigationBar = NO;
    self.view.backgroundColor = kProfilePageBg;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadFollowedTeams];
}

- (void)reloadFollowedTeams {
    NSArray<NSString *> *ids = [ProfileTeamsStore loadFollowedTeamIds];
    self.followedTeams = [ProfileTeamsStore teamsForIds:ids];
    [self updateTeamsCardUI];
}

- (void)setupUI {
    self.scrollView = [UIScrollView new];
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.backgroundColor = kProfilePageBg;
    if (@available(iOS 11.0, *)) {
        self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [self.view addSubview:self.scrollView];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    self.contentWrap = [UIView new];
    [self.scrollView addSubview:self.contentWrap];
    [self.contentWrap mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
    }];

    // 头部深色区
    self.headerView = [UIView new];
    self.headerView.backgroundColor = kProfileHeaderBg;
    [self.contentWrap addSubview:self.headerView];
    [self.headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.contentWrap);
        make.height.mas_equalTo(260);
    }];

    // 设置按钮
    UIButton *settingsBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    if (@available(iOS 13.0, *)) {
        [settingsBtn setImage:[UIImage systemImageNamed:@"gearshape"] forState:UIControlStateNormal];
    }
    [settingsBtn setTintColor:[UIColor whiteColor]];
    [settingsBtn addTarget:self action:@selector(openSettings) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView addSubview:settingsBtn];
    if (@available(iOS 11.0, *)) {
        [settingsBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(self.headerView).offset(-16);
            make.top.equalTo(self.view.mas_safeAreaLayoutGuide).offset(8);
            make.size.mas_equalTo(CGSizeMake(36, 36));
        }];
    } else {
        [settingsBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(self.headerView).offset(-16);
            make.top.equalTo(self.headerView).offset(28);
            make.size.mas_equalTo(CGSizeMake(36, 36));
        }];
    }

    // 头像 + VIP
    UIView *avatarRing = [UIView new];
    avatarRing.layer.cornerRadius = 40;
    avatarRing.clipsToBounds = YES;
    avatarRing.backgroundColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    [self.headerView addSubview:avatarRing];
    [avatarRing mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView).offset(56);
        make.centerX.equalTo(self.headerView);
        make.size.mas_equalTo(CGSizeMake(80, 80));
    }];

    self.avatarView = [UIImageView new];
    self.avatarView.backgroundColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    self.avatarView.layer.cornerRadius = 36;
    self.avatarView.clipsToBounds = YES;
    self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
    if (@available(iOS 13.0, *)) {
        self.avatarView.image = [UIImage systemImageNamed:@"person.crop.circle.fill"];
        self.avatarView.tintColor = [UIColor whiteColor];
    }
    [avatarRing addSubview:self.avatarView];
    [self.avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(avatarRing);
        make.size.mas_equalTo(CGSizeMake(72, 72));
    }];

    self.vipLabel = [UILabel new];
    self.vipLabel.text = @"VIP";
    self.vipLabel.font = [UIFont boldSystemFontOfSize:10];
    self.vipLabel.textColor = [UIColor whiteColor];
    self.vipLabel.backgroundColor = [UIColor colorWithRed:0.85 green:0.65 blue:0.13 alpha:1.0];
    self.vipLabel.layer.cornerRadius = 8;
    self.vipLabel.clipsToBounds = YES;
    self.vipLabel.textAlignment = NSTextAlignmentCenter;
    [avatarRing addSubview:self.vipLabel];
    [self.vipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.trailing.equalTo(avatarRing).offset(2);
        make.size.mas_equalTo(CGSizeMake(24, 16));
    }];

    // 姓名 + 记者
    UIView *nameRow = [UIView new];
    [self.headerView addSubview:nameRow];
    [nameRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(avatarRing.mas_bottom).offset(12);
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

    self.reporterBadge = [UIView new];
    self.reporterBadge.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.2];
    self.reporterBadge.layer.cornerRadius = 8;
    [nameRow addSubview:self.reporterBadge];
    [self.reporterBadge mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.nameLabel.mas_trailing).offset(8);
        make.centerY.equalTo(nameRow);
        make.trailing.equalTo(nameRow);
        make.height.mas_equalTo(20);
    }];

    self.reporterLabel = [UILabel new];
    self.reporterLabel.text = NSLocalizedString(@"profile_badge_verified", nil);
    self.reporterLabel.font = [UIFont systemFontOfSize:11];
    self.reporterLabel.textColor = [UIColor whiteColor];
    [self.reporterBadge addSubview:self.reporterLabel];
    [self.reporterLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.reporterBadge);
    }];

    self.idLabel = [UILabel new];
    self.idLabel.font = [UIFont systemFontOfSize:13];
    self.idLabel.textColor = [UIColor colorWithWhite:0.72 alpha:1.0];
    [self.headerView addSubview:self.idLabel];
    [self.idLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(nameRow.mas_bottom).offset(6);
        make.centerX.equalTo(self.headerView);
    }];

    // 统计行 65 好友 / 123 关注 / 13 打卡球赛
    UIView *statsBar = [UIView new];
    [self.headerView addSubview:statsBar];
    [statsBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.idLabel.mas_bottom).offset(16);
        make.leading.trailing.equalTo(self.headerView);
        make.height.mas_equalTo(52);
    }];

    NSArray *nums = @[@"65", @"123", @"13"];
    self.stat1Num = [UILabel new]; self.stat1Title = [UILabel new];
    self.stat2Num = [UILabel new]; self.stat2Title = [UILabel new];
    self.stat3Num = [UILabel new]; self.stat3Title = [UILabel new];
    NSArray *numL = @[self.stat1Num, self.stat2Num, self.stat3Num];
    NSArray *titL = @[self.stat1Title, self.stat2Title, self.stat3Title];
    for (NSInteger i = 0; i < 3; i++) {
        UIView *col = [UIView new];
        [statsBar addSubview:col];
        [col mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(statsBar);
            if (i == 0) make.leading.equalTo(statsBar);
            else make.leading.equalTo(statsBar.subviews[i - 1].mas_trailing);
            make.width.equalTo(statsBar).multipliedBy(1.0/3.0);
        }];
        UILabel *n = numL[i];
        n.text = nums[i];
        n.font = [UIFont boldSystemFontOfSize:20];
        n.textColor = [UIColor whiteColor];
        n.textAlignment = NSTextAlignmentCenter;
        [col addSubview:n];
        [n mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(col);
            make.top.equalTo(col).offset(4);
        }];
        UILabel *t = titL[i];
        t.text = @[ NSLocalizedString(@"profile_stat_friends", nil), NSLocalizedString(@"profile_stat_follow", nil), NSLocalizedString(@"profile_stat_stamps", nil) ][i];
        t.font = [UIFont systemFontOfSize:12];
        t.textColor = [UIColor colorWithWhite:0.65 alpha:1.0];
        t.textAlignment = NSTextAlignmentCenter;
        [col addSubview:t];
        [t mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(col);
            make.top.equalTo(n.mas_bottom).offset(2);
        }];
    }

    // 我关注的球队 卡片
    self.teamsCard = [UIControl new];
    self.teamsCard.backgroundColor = kProfileCardBg;
    self.teamsCard.layer.cornerRadius = 12;
    [self.teamsCard addTarget:self action:@selector(onTeamsTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentWrap addSubview:self.teamsCard];
    [self.teamsCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView.mas_bottom).offset(12);
        make.leading.equalTo(self.contentWrap).offset(12);
        make.trailing.equalTo(self.contentWrap).offset(-12);
    }];

    self.teamsTitleLabel = [UILabel new];
    self.teamsTitleLabel.text = NSLocalizedString(@"profile_section_teams", nil);
    self.teamsTitleLabel.font = [UIFont systemFontOfSize:16];
    self.teamsTitleLabel.textColor = [UIColor blackColor];
    [self.teamsCard addSubview:self.teamsTitleLabel];

    self.teamsArrowView = [UIImageView new];
    if (@available(iOS 13.0, *)) {
        self.teamsArrowView.image = [UIImage systemImageNamed:@"chevron.right"];
        self.teamsArrowView.tintColor = [UIColor colorWithWhite:0.65 alpha:1.0];
    }
    [self.teamsCard addSubview:self.teamsArrowView];

    self.teamsContentWrap = [UIView new];
    self.teamsContentWrap.clipsToBounds = YES;
    [self.teamsCard addSubview:self.teamsContentWrap];

    self.teamsScrollView = [UIScrollView new];
    self.teamsScrollView.showsHorizontalScrollIndicator = NO;
    self.teamsScrollView.bounces = YES;
    self.teamsScrollView.alwaysBounceHorizontal = YES;
    if (@available(iOS 11.0, *)) {
        self.teamsScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [self.teamsContentWrap addSubview:self.teamsScrollView];
    [self.teamsScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.teamsContentWrap);
    }];

    self.teamsScrollContentView = [UIView new];
    [self.teamsScrollView addSubview:self.teamsScrollContentView];
    [self.teamsScrollContentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.teamsScrollView);
        make.height.equalTo(self.teamsScrollView);
        make.width.mas_equalTo(0);
    }];

    self.teamsEmptyLabel = [UILabel new];
    self.teamsEmptyLabel.font = [UIFont systemFontOfSize:14];
    self.teamsEmptyLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    self.teamsEmptyLabel.textAlignment = NSTextAlignmentCenter;
    self.teamsEmptyLabel.text = NSLocalizedString(@"profile_team_empty_hint", nil);
    self.teamsEmptyLabel.hidden = YES;
    [self.teamsContentWrap addSubview:self.teamsEmptyLabel];
    [self.teamsEmptyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.teamsContentWrap);
    }];

    // 菜单行
    UIView *prevCard = nil;
    NSMutableArray *controls = [NSMutableArray array];
    for (NSInteger i = 0; i < _menuKeys().count; i++) {
        NSString *key = _menuKeys()[i];
        UIControl *card = [UIControl new];
        card.backgroundColor = kProfileCardBg;
        card.layer.cornerRadius = 12;
        card.tag = i;
        [card addTarget:self action:@selector(onMenuTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentWrap addSubview:card];
        [card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentWrap).offset(12);
            make.trailing.equalTo(self.contentWrap).offset(-12);
            make.height.mas_equalTo(52);
            if (prevCard) make.top.equalTo(prevCard.mas_bottom).offset(10);
            else          make.top.equalTo(self.teamsCard.mas_bottom).offset(12);
        }];

        UILabel *lbl = [UILabel new];
        lbl.text = NSLocalizedString(key, nil);
        lbl.font = [UIFont systemFontOfSize:16];
        lbl.textColor = [UIColor blackColor];
        [card addSubview:lbl];
        [lbl mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(card).offset(16);
            make.centerY.equalTo(card);
        }];

        UIImageView *arr = [UIImageView new];
        if (@available(iOS 13.0, *)) {
            arr.image = [UIImage systemImageNamed:@"chevron.right"];
            arr.tintColor = [UIColor colorWithWhite:0.65 alpha:1.0];
        }
        [card addSubview:arr];
        [arr mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(card).offset(-14);
            make.centerY.equalTo(card);
            make.size.mas_equalTo(CGSizeMake(14, 14));
        }];

        prevCard = card;
        [controls addObject:card];
    }
    self.menuControls = [controls copy];
    [prevCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.contentWrap).offset(-24);
    }];

    self.followedTeams = @[];
    [self updateTeamsCardUI];
}

- (void)updateTeamsCardUI {
    NSArray<ProfileTeamItem *> *teams = self.followedTeams ?: @[];
    BOOL hasData = teams.count > 0;

    self.teamsEmptyLabel.hidden = hasData;
    self.teamsScrollView.hidden = !hasData;

    // 无数据：单行卡片 52pt，与「个人资料」等一致；有数据：标题行 + 球队图标区 90pt，可横向滑动
    [self.teamsCard mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView.mas_bottom).offset(12);
        make.leading.equalTo(self.contentWrap).offset(12);
        make.trailing.equalTo(self.contentWrap).offset(-12);
        if (hasData) {
            make.bottom.equalTo(self.teamsContentWrap.mas_bottom).offset(16);
        } else {
            make.height.mas_equalTo(52);
        }
    }];

    [self.teamsTitleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.teamsCard).offset(16);
        if (hasData) {
            make.top.equalTo(self.teamsCard).offset(16);
        } else {
            make.centerY.equalTo(self.teamsCard);
        }
    }];

    [self.teamsArrowView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.teamsCard).offset(-14);
        make.size.mas_equalTo(CGSizeMake(14, 14));
        if (hasData) {
            make.centerY.equalTo(self.teamsTitleLabel);
        } else {
            make.centerY.equalTo(self.teamsCard);
        }
    }];

    [self.teamsContentWrap mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.teamsTitleLabel.mas_bottom).offset(12);
        make.leading.equalTo(self.teamsCard).offset(14);
        make.trailing.equalTo(self.teamsCard).offset(-14);
        make.height.mas_equalTo(hasData ? 90 : 0);
        if (hasData) {
            make.bottom.equalTo(self.teamsCard).offset(-16);
        }
    }];

    if (hasData) {
        // 清空后按球队数量动态添加 thumb，支持横向滑动
        for (UIView *sub in [self.teamsScrollContentView.subviews copy]) {
            [sub removeFromSuperview];
        }
        static const CGFloat kThumbItemW = 72;
        static const CGFloat kThumbGap = 12;
        NSUInteger n = teams.count;
        CGFloat contentW = n * kThumbItemW + (n > 0 ? (n - 1) * kThumbGap : 0);
        [self.teamsScrollContentView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(contentW);
        }];

        ProfileTeamThumbView *prevThumb = nil;
        for (NSUInteger i = 0; i < n; i++) {
            ProfileTeamThumbView *thumb = [ProfileTeamThumbView new];
            [thumb configureWithTeam:teams[i]];
            [self.teamsScrollContentView addSubview:thumb];
            [thumb mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.bottom.equalTo(self.teamsScrollContentView);
                make.width.mas_equalTo(kThumbItemW);
                if (i == 0) {
                    make.leading.equalTo(self.teamsScrollContentView);
                } else {
                    make.leading.equalTo(prevThumb.mas_trailing).offset(kThumbGap);
                }
            }];
            prevThumb = thumb;
        }
    } else {
        self.teamsEmptyLabel.text = NSLocalizedString(@"profile_team_empty_hint", nil);
    }
}

- (void)updateLocalizedStrings {
    [super updateLocalizedStrings];
    self.idLabel.text = [NSString stringWithFormat:NSLocalizedString(@"profile_id_format", @"ID : %@"), @"145477487"];
    self.reporterLabel.text = NSLocalizedString(@"profile_badge_verified", nil);
    self.stat1Title.text = NSLocalizedString(@"profile_stat_friends", nil);
    self.stat2Title.text = NSLocalizedString(@"profile_stat_follow", nil);
    self.stat3Title.text = NSLocalizedString(@"profile_stat_stamps", nil);
    self.teamsTitleLabel.text = NSLocalizedString(@"profile_section_teams", nil);
    self.teamsEmptyLabel.text = NSLocalizedString(@"profile_team_empty_hint", nil);
    for (NSInteger i = 0; i < self.menuControls.count && i < (NSInteger)_menuKeys().count; i++) {
        UILabel *lbl = [self.menuControls[i].subviews firstObject];
        if ([lbl isKindOfClass:[UILabel class]]) {
            lbl.text = NSLocalizedString(_menuKeys()[i], nil);
        }
    }
}

- (void)openSettings {
    SettingsViewController *vc = [SettingsViewController new];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onTeamsTapped {
    MyTeamsViewController *vc = [MyTeamsViewController new];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onMenuTapped:(UIControl *)sender {
    NSInteger idx = sender.tag;
    if (idx < 0 || idx >= (NSInteger)_menuKeys().count) return;
    NSString *key = _menuKeys()[idx];
    if ([key isEqualToString:@"profile_id_verify"]) {
        IdentityAuthViewController *vc = [IdentityAuthViewController new];
        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    } else if ([key isEqualToString:@"profile_my_info"]) {
        PersonalInfoViewController *vc = [PersonalInfoViewController new];
        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

@end
