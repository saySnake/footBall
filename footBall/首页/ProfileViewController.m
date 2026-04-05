//
//  ProfileViewController.m
//  footBall
//

#import "ProfileViewController.h"
#import "IdentityAuthViewController.h"
#import "PersonalInfoViewController.h"
#import "SettingsViewController.h"
#import "MyTeamsViewController.h"
#import "StampAlbumViewController.h"
#import "ProfileTeamsStore.h"
#import "AuthManager.h"
#import "User.h"
#import "UserRequest.h"
#import "SocialRequest.h"
#import "ProfileRequest.h"
#import "TeamsRequest.h"
#import "Team.h"
#import "SocialModels.h"
#import "StatisticsModels.h"
#import "APIManager.h"
#import "APIPathValues.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>

#define kProfileHeaderBg  [UIColor colorWithRed:0.051 green:0.129 blue:0.133 alpha:1.0]
/// Figma「我的」1:6361 画板背景 #f7f7f7
#define kProfilePageBg    [UIColor colorWithRed:0.969 green:0.969 blue:0.969 alpha:1.0]
#define kProfileCardBg    [UIColor whiteColor]
/// 卡片距屏幕左右边距（375 宽画板下与 343 宽卡片对齐）
static CGFloat const kProfileScreenInset = 16.f;
/// 卡片内标题左侧 padding（稿约 31pt ≈ 16+15）
static CGFloat const kProfileCardInnerLeading = 15.f;

static NSArray<NSString *> * _menuKeys(void) {
    return @[@"profile_my_info", @"profile_my_stamps", @"profile_id_verify"];
}

// 球队小图标+名字（用于首页展示的一行）
@interface ProfileTeamThumbView : UIView
@property (nonatomic, strong) UIView *iconBg;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *nameLabel;
- (void)configureWithTeam:(ProfileTeamItem *)team;
- (void)configureWithAPITeam:(Team *)team;
@end
@implementation ProfileTeamThumbView
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _iconBg = [UIView new];
        _iconBg.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
        _iconBg.layer.cornerRadius = 27;
        _iconBg.clipsToBounds = YES;
        _iconView = [UIImageView new];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        _nameLabel = [UILabel new];
        _nameLabel.font = [UIFont systemFontOfSize:12];
        _nameLabel.textColor = [UIColor blackColor];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        _nameLabel.numberOfLines = 1;
        [self addSubview:_iconBg];
        [_iconBg addSubview:_iconView];
        [self addSubview:_nameLabel];
        [_iconBg mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.centerX.equalTo(self);
            make.size.mas_equalTo(CGSizeMake(54, 54));
        }];
        [_iconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(_iconBg);
            make.size.mas_equalTo(CGSizeMake(34, 34));
        }];
        [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_iconBg.mas_bottom).offset(4);
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
    _iconView.contentMode = UIViewContentModeScaleAspectFit;
}

- (void)configureWithAPITeam:(Team *)team {
    if (!team) return;
    _nameLabel.text = team.name.length > 0 ? team.name : @"-";
    _iconView.tintColor = nil;
    NSURL *url = team.logo.length > 0 ? [NSURL URLWithString:team.logo] : nil;
    UIImage *placeholder = nil;
    if (@available(iOS 13.0, *)) {
        placeholder = [UIImage systemImageNamed:@"sportscourt.fill"];
    }
    __weak typeof(self) weakSelf = self;
    [_iconView sd_setImageWithURL:url placeholderImage:placeholder completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        weakSelf.iconView.contentMode = UIViewContentModeScaleAspectFit;
        if (!image || error) {
            if (@available(iOS 13.0, *)) {
                weakSelf.iconView.tintColor = [UIColor grayColor];
            }
        } else {
            weakSelf.iconView.tintColor = nil;
        }
    }];
}
@end

@interface ProfileViewController ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentWrap;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIButton *settingsBtn;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UIImageView *vipBadgeView;
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
/// 接口「我关注的球队」
@property (nonatomic, strong) NSArray<Team *> *apiFollowedTeams;

@property (nonatomic, strong) NSArray<UIControl *> *menuControls;
@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.shouldShowNavigationBar = NO;
    self.view.backgroundColor = kProfilePageBg;

    // Figma 1:6361：右上角设置 setIcon，稿 24×24，距右 16，距状态栏区域下约 9pt（稿全屏 top≈53）
    self.settingsBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *setIconAsset = [UIImage imageNamed:@"setIcon"];
    UIImage *settingsIcon = setIconAsset ?: [UIImage imageNamed:@"icon_settings"];
    if (settingsIcon) {
        BOOL useOriginal = (setIconAsset != nil);
        [self.settingsBtn setImage:[settingsIcon imageWithRenderingMode:useOriginal ? UIImageRenderingModeAlwaysOriginal : UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        self.settingsBtn.tintColor = useOriginal ? nil : [UIColor whiteColor];
    } else if (@available(iOS 13.0, *)) {
        UIImage *sfIcon = [UIImage systemImageNamed:@"gearshape"];
        if (sfIcon) {
            [self.settingsBtn setImage:[sfIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        } else {
            [self.settingsBtn setTitle:@"⚙" forState:UIControlStateNormal];
            self.settingsBtn.titleLabel.font = [UIFont systemFontOfSize:22];
        }
        self.settingsBtn.tintColor = [UIColor whiteColor];
    } else {
        [self.settingsBtn setTitle:@"⚙" forState:UIControlStateNormal];
        self.settingsBtn.titleLabel.font = [UIFont systemFontOfSize:22];
    }
    [self.settingsBtn setTitleColor:[UIColor clearColor] forState:UIControlStateNormal];
    self.settingsBtn.adjustsImageWhenHighlighted = NO;
    self.settingsBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    static CGFloat const kSetIconVisual = 24.f;
    static CGFloat const kSetIconHit = 44.f;
    CGFloat inset = (kSetIconHit - kSetIconVisual) / 2.f;
    self.settingsBtn.imageEdgeInsets = UIEdgeInsetsMake(inset, inset, inset, inset);
    [self.settingsBtn addTarget:self action:@selector(openSettings) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.settingsBtn];
    [self.settingsBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11.0, *)) {
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(9);
        } else {
            make.top.equalTo(self.mas_topLayoutGuide).offset(9);
        }
        make.trailing.equalTo(self.view).offset(-kProfileScreenInset);
        make.size.mas_equalTo(CGSizeMake(kSetIconHit, kSetIconHit));
    }];
    [self.view bringSubviewToFront:self.settingsBtn];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.view bringSubviewToFront:self.settingsBtn];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadProfileRemoteData];
}

/// 个人页：用户资料、好友/关注/观赛场次、关注球队、会员标识
- (void)loadProfileRemoteData {
    if (!AuthManager.sharedManager.isLoggedIn) {
        [self applyUserProfile:nil];
        self.stat1Num.text = @"0";
        self.stat2Num.text = @"0";
        self.stat3Num.text = @"0";
        self.apiFollowedTeams = @[];
        [self updateTeamsCardUI];
        self.vipBadgeView.hidden = YES;
        return;
    }

    __weak typeof(self) weakSelf = self;

    [[UserRequest shared] getLoginUserInfoSuccess:^(HTTPResponse * _Nullable responseObject) {
        UserProfile *p = AuthManager.sharedManager.user.profile;
        [weakSelf applyUserProfile:p];
    } failure:^(NSError * _Nonnull error) {
        [weakSelf applyUserProfile:AuthManager.sharedManager.user.profile];
    }];

    [SocialRequest.shared getFriendsSuccess:^(HTTPResponse * _Nullable responseObject) {
        PNFriendPage *page = [responseObject.dataObject isKindOfClass:PNFriendPage.class] ? responseObject.dataObject : nil;
        NSInteger n = 0;
        if (page) {
            n = page.total > 0 ? page.total : page.list.count;
        }
        weakSelf.stat1Num.text = [NSString stringWithFormat:@"%ld", (long)MAX(n, 0)];
    } failure:^(NSError * _Nonnull error) {
        weakSelf.stat1Num.text = @"0";
    }];

    [SocialRequest.shared getFollowingSuccess:^(HTTPResponse * _Nullable responseObject) {
        PNUserPage *page = [responseObject.dataObject isKindOfClass:PNUserPage.class] ? responseObject.dataObject : nil;
        NSInteger n = 0;
        if (page) {
            n = page.total > 0 ? page.total : page.list.count;
        }
        weakSelf.stat2Num.text = [NSString stringWithFormat:@"%ld", (long)MAX(n, 0)];
    } failure:^(NSError * _Nonnull error) {
        weakSelf.stat2Num.text = @"0";
    }];

    [[ProfileRequest shared] getMyStatisticsWithPeriod:@"all" success:^(HTTPResponse * _Nullable responseObject) {
        PNStatistics *stats = [responseObject.dataObject isKindOfClass:PNStatistics.class] ? responseObject.dataObject : nil;
        NSInteger matches = stats.basicStats ? MAX(stats.basicStats.totalMatches, 0) : 0;
        weakSelf.stat3Num.text = [NSString stringWithFormat:@"%ld", (long)matches];
    } failure:^(NSError * _Nonnull error) {
        weakSelf.stat3Num.text = @"0";
    }];

    [[TeamsRequest shared] getFollowTeamsSuccess:^(HTTPResponse * _Nullable responseObject) {
        NSArray *teams = [responseObject.dataObject isKindOfClass:NSArray.class] ? responseObject.dataObject : nil;
        weakSelf.apiFollowedTeams = teams ?: @[];
        [weakSelf updateTeamsCardUI];
    } failure:^(NSError * _Nonnull error) {
        weakSelf.apiFollowedTeams = @[];
        [weakSelf updateTeamsCardUI];
    }];

    [[APIManager sharedManager] GET:APIPathValueMembershipStatus parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (!responseObject.success) {
            weakSelf.vipBadgeView.hidden = YES;
            return;
        }
        BOOL showVIP = [weakSelf parseMembershipActiveFromPayload:responseObject.data];
        weakSelf.vipBadgeView.hidden = !showVIP;
    } failure:^(NSError * _Nonnull error) {
        weakSelf.vipBadgeView.hidden = YES;
    }];
}

- (BOOL)parseMembershipActiveFromPayload:(id)data {
    if ([data isKindOfClass:NSDictionary.class]) {
        NSDictionary *d = data;
        id v = d[@"active"] ?: d[@"isActive"] ?: d[@"vip"] ?: d[@"isVip"] ?: d[@"valid"];
        if ([v isKindOfClass:NSNumber.class]) return [v boolValue];
        if ([v isKindOfClass:NSString.class]) {
            NSString *s = [(NSString *)v lowercaseString];
            if ([s isEqualToString:@"1"] || [s isEqualToString:@"true"] || [s isEqualToString:@"active"]) return YES;
        }
        NSString *st = d[@"status"];
        if ([st isKindOfClass:NSString.class] && [[(NSString *)st lowercaseString] isEqualToString:@"active"]) return YES;
    }
    return NO;
}

- (void)applyUserProfile:(UserProfile *)p {
    if (!AuthManager.sharedManager.isLoggedIn) {
        self.nameLabel.text = @"--";
        self.idLabel.text = [NSString stringWithFormat:NSLocalizedString(@"profile_id_format", nil), @"--"];
        [self.avatarView sd_cancelCurrentImageLoad];
        if (@available(iOS 13.0, *)) {
            self.avatarView.image = [UIImage systemImageNamed:@"person.crop.circle.fill"];
            self.avatarView.tintColor = [UIColor whiteColor];
            self.avatarView.contentMode = UIViewContentModeCenter;
        }
        return;
    }
    User *u = AuthManager.sharedManager.user;
    UserProfile *profile = p ?: u.profile;
    NSString *name = profile.nickname.length > 0 ? profile.nickname : (u.nickname.length > 0 ? u.nickname : @"-");
    self.nameLabel.text = name;
    [self refreshIDLabel];

    NSString *avStr = profile.avatar.length > 0 ? profile.avatar : u.avatar;
    NSURL *avURL = avStr.length > 0 ? [NSURL URLWithString:avStr] : nil;
    UIImage *placeholder = nil;
    if (@available(iOS 13.0, *)) {
        placeholder = [UIImage systemImageNamed:@"person.crop.circle.fill"];
    }
    [self.avatarView sd_setImageWithURL:avURL placeholderImage:placeholder];
    if (!self.avatarView.image && @available(iOS 13.0, *)) {
        self.avatarView.tintColor = [UIColor whiteColor];
        self.avatarView.contentMode = UIViewContentModeCenter;
    } else {
        self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
    }
}

- (void)refreshIDLabel {
    NSString *uid = AuthManager.sharedManager.user.profile.userId ?: AuthManager.sharedManager.user.userId ?: @"";
    self.idLabel.text = [NSString stringWithFormat:NSLocalizedString(@"profile_id_format", nil), uid.length > 0 ? uid : @"--"];
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
        make.height.mas_equalTo(318);
    }];

    // 头像 + VIP
    UIView *avatarRing = [UIView new];
    avatarRing.layer.cornerRadius = 45;
    avatarRing.clipsToBounds = YES;
    avatarRing.backgroundColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    [self.headerView addSubview:avatarRing];
    [avatarRing mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView).offset(83);
        make.centerX.equalTo(self.headerView);
        make.size.mas_equalTo(CGSizeMake(90, 90));
    }];

    self.avatarView = [UIImageView new];
    self.avatarView.backgroundColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    self.avatarView.layer.cornerRadius = 45;
    self.avatarView.clipsToBounds = YES;
    self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
    if (@available(iOS 13.0, *)) {
        self.avatarView.image = [UIImage systemImageNamed:@"person.crop.circle.fill"];
        self.avatarView.tintColor = [UIColor whiteColor];
    }
    [avatarRing addSubview:self.avatarView];
    [self.avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(avatarRing);
        make.size.mas_equalTo(CGSizeMake(90, 90));
    }];

    self.vipBadgeView = [UIImageView new];
    self.vipBadgeView.contentMode = UIViewContentModeScaleAspectFit;
    self.vipBadgeView.image = [UIImage imageNamed:@"setting_vip"];
    self.vipBadgeView.hidden = YES;
    [avatarRing addSubview:self.vipBadgeView];
    [self.vipBadgeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(avatarRing);
        make.bottom.equalTo(avatarRing);
        make.size.mas_equalTo(CGSizeMake(40, 16));
    }];

    // 姓名 + 记者
    UIView *nameRow = [UIView new];
    [self.headerView addSubview:nameRow];
    [nameRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(avatarRing.mas_bottom).offset(8);
        make.centerX.equalTo(self.headerView);
    }];

    self.nameLabel = [UILabel new];
    self.nameLabel.text = @"Arisha Ireen";
    self.nameLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    self.nameLabel.textColor = [UIColor whiteColor];
    [nameRow addSubview:self.nameLabel];
    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.bottom.equalTo(nameRow);
    }];

    self.reporterBadge = [UIView new];
    self.reporterBadge.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.2];
    self.reporterBadge.layer.cornerRadius = 10;
    [nameRow addSubview:self.reporterBadge];
    [self.reporterBadge mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.nameLabel.mas_trailing).offset(8);
        make.centerY.equalTo(nameRow);
        make.trailing.equalTo(nameRow);
        make.height.mas_equalTo(16);
    }];

    self.reporterLabel = [UILabel new];
    self.reporterLabel.text = NSLocalizedString(@"profile_badge_verified", nil);
    self.reporterLabel.font = [UIFont systemFontOfSize:12];
    self.reporterLabel.textColor = [UIColor whiteColor];
    [self.reporterBadge addSubview:self.reporterLabel];
    [self.reporterLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.reporterBadge).offset(8);
        make.trailing.equalTo(self.reporterBadge).offset(-8);
        make.centerY.equalTo(self.reporterBadge);
    }];

    self.idLabel = [UILabel new];
    self.idLabel.font = [UIFont systemFontOfSize:14];
    self.idLabel.textColor = [UIColor whiteColor];
    [self.headerView addSubview:self.idLabel];
    [self.idLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(nameRow.mas_bottom).offset(2);
        make.centerX.equalTo(self.headerView);
    }];

    // 统计行 65 好友 / 123 关注 / 13 打卡球赛
    UIView *statsBar = [UIView new];
    [self.headerView addSubview:statsBar];
    [statsBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.idLabel.mas_bottom).offset(22);
        make.leading.trailing.equalTo(self.headerView);
        make.height.mas_equalTo(52);
    }];

    NSArray *nums = @[@"0", @"0", @"0"];
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
        n.font = [UIFont boldSystemFontOfSize:18];
        n.textColor = [UIColor whiteColor];
        n.textAlignment = NSTextAlignmentCenter;
        [col addSubview:n];
        [n mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(col);
            make.top.equalTo(col).offset(4);
        }];
        UILabel *t = titL[i];
        t.text = @[ NSLocalizedString(@"profile_stat_friends", nil), NSLocalizedString(@"profile_stat_follow", nil), NSLocalizedString(@"profile_stat_stamps", nil) ][i];
        t.font = [UIFont systemFontOfSize:14];
        t.textColor = [UIColor whiteColor];
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
    self.teamsCard.layer.cornerRadius = 6;
    [self.teamsCard addTarget:self action:@selector(onTeamsTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentWrap addSubview:self.teamsCard];
    [self.teamsCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView.mas_bottom).offset(12);
        make.leading.equalTo(self.contentWrap).offset(kProfileScreenInset);
        make.trailing.equalTo(self.contentWrap).offset(-kProfileScreenInset);
    }];

    self.teamsTitleLabel = [UILabel new];
    self.teamsTitleLabel.text = NSLocalizedString(@"profile_section_teams", nil);
    self.teamsTitleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    self.teamsTitleLabel.textColor = [UIColor blackColor];
    [self.teamsCard addSubview:self.teamsTitleLabel];

    self.teamsArrowView = [UIImageView new];
    self.teamsArrowView.contentMode = UIViewContentModeScaleAspectFit;
    self.teamsArrowView.image = [UIImage imageNamed:@"setting_right"];
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
        card.layer.cornerRadius = 6;
        card.tag = i;
        [card addTarget:self action:@selector(onMenuTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentWrap addSubview:card];
        [card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentWrap).offset(kProfileScreenInset);
            make.trailing.equalTo(self.contentWrap).offset(-kProfileScreenInset);
            make.height.mas_equalTo(50);
            if (prevCard) make.top.equalTo(prevCard.mas_bottom).offset(12);
            else          make.top.equalTo(self.teamsCard.mas_bottom).offset(12);
        }];

        UILabel *lbl = [UILabel new];
        lbl.text = NSLocalizedString(key, nil);
        lbl.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
        lbl.textColor = [UIColor blackColor];
        [card addSubview:lbl];
        [lbl mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(card).offset(kProfileCardInnerLeading);
            make.centerY.equalTo(card);
        }];

        UIImageView *arr = [UIImageView new];
        arr.contentMode = UIViewContentModeScaleAspectFit;
        arr.image = [UIImage imageNamed:@"setting_right"];
        [card addSubview:arr];
        [arr mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(card).offset(-kProfileCardInnerLeading);
            make.centerY.equalTo(card);
            make.size.mas_equalTo(CGSizeMake(18, 18));
        }];

        prevCard = card;
        [controls addObject:card];
    }
    self.menuControls = [controls copy];
    [prevCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.contentWrap).offset(-24);
    }];

    self.apiFollowedTeams = @[];
    [self updateTeamsCardUI];
}

- (void)updateTeamsCardUI {
    NSArray<Team *> *teams = self.apiFollowedTeams ?: @[];
    BOOL hasData = teams.count > 0;

    self.teamsEmptyLabel.hidden = hasData;
    self.teamsScrollView.hidden = !hasData;

    // 无数据：单行卡片 52pt，与「个人资料」等一致；有数据：标题行 + 球队图标区 90pt，可横向滑动
    [self.teamsCard mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView.mas_bottom).offset(12);
        make.leading.equalTo(self.contentWrap).offset(kProfileScreenInset);
        make.trailing.equalTo(self.contentWrap).offset(-kProfileScreenInset);
        if (hasData) {
            make.height.mas_equalTo(143);
        } else {
            make.height.mas_equalTo(50);
        }
    }];

    [self.teamsTitleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.teamsCard).offset(kProfileCardInnerLeading);
        if (hasData) {
            make.top.equalTo(self.teamsCard).offset(16);
        } else {
            make.centerY.equalTo(self.teamsCard);
        }
    }];

    [self.teamsArrowView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.teamsCard).offset(-kProfileCardInnerLeading);
        make.size.mas_equalTo(CGSizeMake(18, 18));
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
        make.height.mas_equalTo(hasData ? 80 : 0);
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
            [thumb configureWithAPITeam:teams[i]];
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
    [self refreshIDLabel];
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
    } else if ([key isEqualToString:@"profile_my_stamps"]) {
        StampAlbumViewController *vc = [[StampAlbumViewController alloc] init];
        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

@end
