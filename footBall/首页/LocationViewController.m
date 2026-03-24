//
//  LocationViewController.m
//  footBall
//

#import "LocationViewController.h"
#import "AddFriendViewController.h"
#import "MyQRCodeViewController.h"
#import <Masonry/Masonry.h>
#import "ColorManager.h"

#define kCommunityGreen    [ColorManager sharedManager].primaryColor
#define kCommunityHeaderBg [ColorManager sharedManager].primaryDarkColor
#define kCommunityPageBg   [ColorManager sharedManager].secondaryBackgroundColor
static NSString * const kCommunityPendingCountKey = @"community_pending_count";
static NSString * const kCommunityPendingCountDidChangeNotification = @"community_pending_count_did_change";
static NSString * const kCommunityAddedFriendsKey = @"community_added_friends";
static NSString * const kCommunityFriendsDidChangeNotification = @"community_friends_did_change";

@interface CommunityFriend : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *odId;
@property (nonatomic, copy) NSString *statusText;
@property (nonatomic, assign) BOOL isOnline;
@end

@implementation CommunityFriend
@end

typedef NS_ENUM(NSInteger, CommunityRankType) {
    CommunityRankTypeWeek,
    CommunityRankTypeMonth,
    CommunityRankTypeSeason
};

@interface CommunityRankItem : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *team;
@property (nonatomic, copy) NSString *gamesText;
@end

@implementation CommunityRankItem
@end

@interface CommunityFriendCell : UITableViewCell
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *idLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIButton *stampBtn;
@property (nonatomic, strong) UIButton *dataBtn;
- (void)configureWithFriend:(CommunityFriend *)f;
@end

@implementation CommunityFriendCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];

        _cardView = [[UIView alloc] init];
        _cardView.backgroundColor = [UIColor whiteColor];
        _cardView.layer.cornerRadius = 10;

        _avatarView = [[UIImageView alloc] init];
        _avatarView.layer.cornerRadius = 20;
        _avatarView.clipsToBounds = YES;
        _avatarView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];

        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont boldSystemFontOfSize:15];

        _idLabel = [[UILabel alloc] init];
        _idLabel.font = [UIFont systemFontOfSize:12];
        _idLabel.textColor = [UIColor grayColor];

        _statusLabel = [[UILabel alloc] init];
        _statusLabel.font = [UIFont systemFontOfSize:11];

        _stampBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _stampBtn.titleLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
        _stampBtn.layer.cornerRadius = 11;
        _stampBtn.layer.borderWidth = 1;
        _stampBtn.layer.borderColor = kCommunityGreen.CGColor;
        [_stampBtn setTitleColor:kCommunityGreen forState:UIControlStateNormal];

        _dataBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _dataBtn.titleLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
        _dataBtn.layer.cornerRadius = 11;
        _dataBtn.layer.borderWidth = 1;
        _dataBtn.layer.borderColor = kCommunityGreen.CGColor;
        [_dataBtn setTitleColor:kCommunityGreen forState:UIControlStateNormal];

        [self.contentView addSubview:_cardView];
        [_cardView addSubview:_avatarView];
        [_cardView addSubview:_nameLabel];
        [_cardView addSubview:_idLabel];
        [_cardView addSubview:_statusLabel];
        [_cardView addSubview:_stampBtn];
        [_cardView addSubview:_dataBtn];

        [_cardView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(5, 12, 5, 12));
        }];
        [_avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_cardView).offset(10);
            make.centerY.equalTo(_cardView);
            make.width.height.mas_equalTo(40);
        }];
        [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_avatarView.mas_trailing).offset(10);
            make.top.equalTo(_cardView).offset(10);
        }];
        [_idLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_nameLabel);
            make.top.equalTo(_nameLabel.mas_bottom).offset(1);
        }];
        [_statusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_nameLabel);
            make.top.equalTo(_idLabel.mas_bottom).offset(1);
        }];
        [_stampBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(_cardView).offset(-10);
            make.top.equalTo(_cardView).offset(10);
            make.width.mas_equalTo(62);
            make.height.mas_equalTo(22);
        }];
        [_dataBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(_stampBtn);
            make.bottom.equalTo(_cardView).offset(-10);
            make.width.equalTo(_stampBtn);
            make.height.equalTo(_stampBtn);
        }];
    }
    return self;
}

- (void)configureWithFriend:(CommunityFriend *)f {
    self.nameLabel.text = f.name;
    self.idLabel.text = [NSString stringWithFormat:NSLocalizedString(@"community_id_format", nil), f.odId];
    self.statusLabel.text = f.statusText;
    self.statusLabel.textColor = f.isOnline ? [UIColor colorWithRed:0.10 green:0.70 blue:0.30 alpha:1.0] : [UIColor grayColor];
    [self.stampBtn setTitle:NSLocalizedString(@"community_view_stamps", nil) forState:UIControlStateNormal];
    [self.dataBtn setTitle:NSLocalizedString(@"community_view_data", nil) forState:UIControlStateNormal];

    if (@available(iOS 13.0, *)) {
        self.avatarView.image = [UIImage systemImageNamed:@"person.crop.circle.fill"];
        self.avatarView.tintColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    }
}

@end

@interface CommunityRankCell : UITableViewCell
@property (nonatomic, strong) UILabel *rankLabel;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *teamLabel;
@property (nonatomic, strong) UILabel *gamesLabel;
- (void)configureWithItem:(CommunityRankItem *)item rank:(NSInteger)rank;
@end

@implementation CommunityRankCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        _rankLabel = [UILabel new];
        _rankLabel.font = [UIFont systemFontOfSize:28 weight:UIFontWeightRegular];
        _rankLabel.textColor = [UIColor blackColor];
        _rankLabel.textAlignment = NSTextAlignmentCenter;
        _avatarView = [UIImageView new];
        _avatarView.layer.cornerRadius = 22;
        _avatarView.clipsToBounds = YES;
        _nameLabel = [UILabel new];
        _nameLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
        _teamLabel = [UILabel new];
        _teamLabel.font = [UIFont systemFontOfSize:12];
        _teamLabel.textColor = [UIColor grayColor];
        _gamesLabel = [UILabel new];
        _gamesLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
        _gamesLabel.textAlignment = NSTextAlignmentRight;
        [self.contentView addSubview:_rankLabel];
        [self.contentView addSubview:_avatarView];
        [self.contentView addSubview:_nameLabel];
        [self.contentView addSubview:_teamLabel];
        [self.contentView addSubview:_gamesLabel];
        [_rankLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentView).offset(8);
            make.centerY.equalTo(self.contentView);
            make.width.mas_equalTo(34);
        }];
        [_avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_rankLabel.mas_trailing).offset(10);
            make.centerY.equalTo(self.contentView);
            make.size.mas_equalTo(CGSizeMake(46, 46));
        }];
        [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_avatarView.mas_trailing).offset(10);
            make.top.equalTo(self.contentView).offset(8);
        }];
        [_teamLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_nameLabel);
            make.top.equalTo(_nameLabel.mas_bottom).offset(2);
        }];
        [_gamesLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(self.contentView).offset(-14);
            make.centerY.equalTo(self.contentView);
            make.leading.greaterThanOrEqualTo(_nameLabel.mas_trailing).offset(10);
        }];
    }
    return self;
}

- (void)configureWithItem:(CommunityRankItem *)item rank:(NSInteger)rank {
    self.rankLabel.text = [NSString stringWithFormat:@"%ld", (long)rank];
    self.nameLabel.text = item.name;
    self.teamLabel.text = item.team;
    self.gamesLabel.text = item.gamesText;
    if (@available(iOS 13.0, *)) {
        self.avatarView.image = [UIImage systemImageNamed:@"person.crop.circle.fill"];
        self.avatarView.tintColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    }
}

@end

@interface LocationViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *switchBgView;
@property (nonatomic, strong) UIButton *friendsTab;
@property (nonatomic, strong) UIButton *rankTab;
@property (nonatomic, strong) UIButton *addFriendBtn;
@property (nonatomic, strong) UIButton *qrCodeBtn;
@property (nonatomic, strong) UIView *pendingBadgeView;
@property (nonatomic, strong) UILabel *pendingBadgeLabel;
@property (nonatomic, strong) UILabel *sectionLabel;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<CommunityFriend *> *friends;
@property (nonatomic, strong) NSArray<CommunityRankItem *> *weekRanks;
@property (nonatomic, strong) NSArray<CommunityRankItem *> *monthRanks;
@property (nonatomic, strong) NSArray<CommunityRankItem *> *seasonRanks;
@property (nonatomic, assign) CommunityRankType currentRankType;
@property (nonatomic, assign) BOOL isFriendsTab;
@property (nonatomic, assign) NSInteger pendingCount;
@property (nonatomic, strong) UIButton *weekBtn;
@property (nonatomic, strong) UIButton *monthBtn;
@property (nonatomic, strong) UIButton *seasonBtn;
@property (nonatomic, strong) UIView *weekLine;
@property (nonatomic, strong) UIView *monthLine;
@property (nonatomic, strong) UIView *seasonLine;
@property (nonatomic, strong) UIView *rankFilterContainer;
@property (nonatomic, strong) MASConstraint *headerHeightConstraint;
@end

@implementation LocationViewController

- (void)viewDidLoad {
    self.isFriendsTab = YES;
    self.currentRankType = CommunityRankTypeWeek;
    self.pendingCount = [[NSUserDefaults standardUserDefaults] integerForKey:kCommunityPendingCountKey];
    [self loadRemoteFriends];
    [self loadRemoteRanks];
    [super viewDidLoad];
    self.view.backgroundColor = kCommunityPageBg;
    self.shouldShowNavigationBar = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onPendingCountChanged) name:kCommunityPendingCountDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFriendsChanged) name:kCommunityFriendsDidChangeNotification object:nil];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat tabBarH = self.tabBarController.tabBar.bounds.size.height;
    if (tabBarH > 0 && self.tableView.contentInset.bottom != tabBarH) {
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, tabBarH + 6, 0);
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.pendingCount = [[NSUserDefaults standardUserDefaults] integerForKey:kCommunityPendingCountKey];
    [self loadRemoteFriends];
    [self.tableView reloadData];
    [self updatePendingBadge];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadRemoteFriends {
    __weak typeof(self) weakSelf = self;
    [SocialRequest.shared getFriendsSuccess:^(HTTPResponse * _Nullable responseObject) {
        NSArray *list = [responseObject.data[@"list"] isKindOfClass:NSArray.class] ? responseObject.data[@"list"] : ([responseObject.data isKindOfClass:NSArray.class] ? responseObject.data : @[]);
        NSMutableArray *arr = NSMutableArray.array;
        for (NSDictionary *item in list) {
            if (![item isKindOfClass:NSDictionary.class]) continue;
            CommunityFriend *f = CommunityFriend.new;
            f.name = [item[@"nickname"] isKindOfClass:NSString.class] ? item[@"nickname"] : NSLocalizedString(@"team_name_arsenal", nil);
            f.odId = [[item[@"userId"] respondsToSelector:@selector(stringValue)] ? [item[@"userId"] stringValue] : @"12653795" copy];
            f.isOnline = [item[@"online"] boolValue];
            f.statusText = f.isOnline ? NSLocalizedString(@"community_online_15m", nil) : NSLocalizedString(@"community_online_5m_ago", nil);
            [arr addObject:f];
        }
        weakSelf.friends = arr;
        [weakSelf.tableView reloadData];
    } failure:^(NSError * _Nonnull error) {
        weakSelf.friends = @[];
        [weakSelf.tableView reloadData];
    }];

    [SocialRequest.shared getFriendRequestsPendingCountSuccess:^(HTTPResponse * _Nullable responseObject) {
        NSInteger count = [responseObject.data respondsToSelector:@selector(integerValue)] ? [responseObject.data integerValue] : [responseObject.data[@"count"] integerValue];
        weakSelf.pendingCount = MAX(count, 0);
        [[NSUserDefaults standardUserDefaults] setInteger:weakSelf.pendingCount forKey:kCommunityPendingCountKey];
        [weakSelf updatePendingBadge];
    } failure:^(NSError * _Nonnull error) {
    }];
}

- (UIButton *)makeOutlinedButton {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.layer.cornerRadius = 8;
    btn.layer.borderWidth = 1;
    btn.layer.borderColor = [UIColor colorWithWhite:0.45 alpha:1.0].CGColor;
    btn.backgroundColor = [UIColor clearColor];
    btn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    return btn;
}

- (void)setupUI {
    self.headerView = [[UIView alloc] init];
    self.headerView.backgroundColor = kCommunityHeaderBg;
    [self.view addSubview:self.headerView];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    self.titleLabel.textColor = [UIColor whiteColor];
    [self.headerView addSubview:self.titleLabel];

    self.switchBgView = [[UIView alloc] init];
    self.switchBgView.backgroundColor = [UIColor whiteColor];
    self.switchBgView.layer.cornerRadius = 18;
    [self.headerView addSubview:self.switchBgView];

    self.friendsTab = [UIButton buttonWithType:UIButtonTypeSystem];
    self.friendsTab.layer.cornerRadius = 16;
    self.friendsTab.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [self.friendsTab addTarget:self action:@selector(onFriendsTab) forControlEvents:UIControlEventTouchUpInside];
    [self.switchBgView addSubview:self.friendsTab];

    self.rankTab = [UIButton buttonWithType:UIButtonTypeSystem];
    self.rankTab.layer.cornerRadius = 16;
    self.rankTab.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [self.rankTab addTarget:self action:@selector(onRankTab) forControlEvents:UIControlEventTouchUpInside];
    [self.switchBgView addSubview:self.rankTab];

    self.addFriendBtn = [self makeOutlinedButton];
    if (@available(iOS 13.0, *)) {
        [self.addFriendBtn setImage:[UIImage systemImageNamed:@"plus"] forState:UIControlStateNormal];
        self.addFriendBtn.tintColor = [UIColor blackColor];
    }
    [self.addFriendBtn addTarget:self action:@selector(onAddFriend) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.addFriendBtn];

    self.pendingBadgeView = [[UIView alloc] init];
    self.pendingBadgeView.backgroundColor = [UIColor colorWithRed:0.95 green:0.25 blue:0.24 alpha:1.0];
    self.pendingBadgeView.layer.cornerRadius = 8;
    [self.addFriendBtn addSubview:self.pendingBadgeView];
    self.pendingBadgeLabel = [[UILabel alloc] init];
    self.pendingBadgeLabel.font = [UIFont boldSystemFontOfSize:10];
    self.pendingBadgeLabel.textColor = [UIColor whiteColor];
    [self.pendingBadgeView addSubview:self.pendingBadgeLabel];
    [self.pendingBadgeLabel mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self.pendingBadgeView).insets(UIEdgeInsetsMake(2, 4, 2, 4)); }];
    [self.pendingBadgeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.addFriendBtn.mas_top).offset(12);
        make.trailing.equalTo(self.addFriendBtn).offset(-8);
        make.width.mas_greaterThanOrEqualTo(16);
        make.height.mas_equalTo(16);
    }];

    self.qrCodeBtn = [self makeOutlinedButton];
    if (@available(iOS 13.0, *)) {
        [self.qrCodeBtn setImage:[UIImage systemImageNamed:@"qrcode"] forState:UIControlStateNormal];
        self.qrCodeBtn.tintColor = [UIColor blackColor];
    }
    [self.qrCodeBtn addTarget:self action:@selector(onQRCode) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.qrCodeBtn];

    self.sectionLabel = [[UILabel alloc] init];
    self.sectionLabel.font = [UIFont boldSystemFontOfSize:24];
    [self.view addSubview:self.sectionLabel];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:[CommunityFriendCell class] forCellReuseIdentifier:@"CommunityFriendCell"];
    [self.tableView registerClass:[CommunityRankCell class] forCellReuseIdentifier:@"CommunityRankCell"];
    [self.view addSubview:self.tableView];

    [self.headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
        self.headerHeightConstraint = make.height.mas_equalTo(152);
    }];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.headerView);
        make.top.equalTo(self.headerView.mas_safeAreaLayoutGuideTop).offset(10);
    }];
    [self.switchBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.headerView).offset(12);
        make.trailing.equalTo(self.headerView).offset(-12);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(16);
        make.height.mas_equalTo(36);
    }];
    [self.friendsTab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.bottom.equalTo(self.switchBgView).insets(UIEdgeInsetsMake(2, 2, 2, 0));
        make.trailing.equalTo(self.switchBgView.mas_centerX).offset(-2);
    }];
    [self.rankTab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.top.bottom.equalTo(self.switchBgView).insets(UIEdgeInsetsMake(2, 0, 2, 2));
        make.leading.equalTo(self.switchBgView.mas_centerX).offset(2);
    }];

    self.rankFilterContainer = [[UIView alloc] init];
    self.rankFilterContainer.backgroundColor = [UIColor clearColor];
    [self.headerView addSubview:self.rankFilterContainer];
    self.weekBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    self.monthBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    self.seasonBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    NSArray<UIButton *> *rankButtons = @[self.weekBtn, self.monthBtn, self.seasonBtn];
    for (UIButton *btn in rankButtons) {
        btn.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
        [btn addTarget:self action:@selector(onRankFilterTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.rankFilterContainer addSubview:btn];
    }
    self.weekLine = [[UIView alloc] init];
    self.monthLine = [[UIView alloc] init];
    self.seasonLine = [[UIView alloc] init];
    NSArray<UIView *> *lines = @[self.weekLine, self.monthLine, self.seasonLine];
    for (UIView *line in lines) {
        line.backgroundColor = [UIColor whiteColor];
        line.layer.cornerRadius = 1.5;
        [self.rankFilterContainer addSubview:line];
    }
    [self.rankFilterContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.headerView);
        make.top.equalTo(self.switchBgView.mas_bottom).offset(12);
        make.height.mas_equalTo(38);
    }];
    [self.weekBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.rankFilterContainer).offset(4);
        make.top.equalTo(self.rankFilterContainer);
        make.width.equalTo(self.rankFilterContainer.mas_width).multipliedBy(1.0/3.0).offset(-2);
        make.height.mas_equalTo(30);
    }];
    [self.monthBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.weekBtn.mas_trailing).offset(2);
        make.top.width.height.equalTo(self.weekBtn);
    }];
    [self.seasonBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.monthBtn.mas_trailing).offset(2);
        make.top.width.height.equalTo(self.weekBtn);
    }];
    [self.weekLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.weekBtn.mas_bottom).offset(2);
        make.centerX.equalTo(self.weekBtn);
        make.width.mas_equalTo(26);
        make.height.mas_equalTo(3);
    }];
    [self.monthLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.monthBtn.mas_bottom).offset(2);
        make.centerX.equalTo(self.monthBtn);
        make.width.mas_equalTo(26);
        make.height.mas_equalTo(3);
    }];
    [self.seasonLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.seasonBtn.mas_bottom).offset(2);
        make.centerX.equalTo(self.seasonBtn);
        make.width.mas_equalTo(26);
        make.height.mas_equalTo(3);
    }];
    [self.addFriendBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView.mas_bottom).offset(12);
        make.leading.equalTo(self.view).offset(12);
        make.trailing.equalTo(self.view.mas_centerX).offset(-5);
        make.height.mas_equalTo(36);
    }];
    [self.qrCodeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.height.equalTo(self.addFriendBtn);
        make.leading.equalTo(self.view.mas_centerX).offset(5);
        make.trailing.equalTo(self.view).offset(-12);
    }];
    [self.sectionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.addFriendBtn.mas_bottom).offset(12);
        make.leading.equalTo(self.view).offset(14);
    }];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.sectionLabel.mas_bottom).offset(6);
        make.leading.trailing.bottom.equalTo(self.view);
    }];

    [self updateTabs];
    [self updatePendingBadge];
    [self refreshTableHeaderForCurrentMode];
}

- (void)updateTabs {
    if (self.isFriendsTab) {
        self.friendsTab.backgroundColor = kCommunityGreen;
        [self.friendsTab setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.rankTab.backgroundColor = [UIColor clearColor];
        [self.rankTab setTitleColor:kCommunityGreen forState:UIControlStateNormal];
    } else {
        self.rankTab.backgroundColor = kCommunityGreen;
        [self.rankTab setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.friendsTab.backgroundColor = [UIColor clearColor];
        [self.friendsTab setTitleColor:kCommunityGreen forState:UIControlStateNormal];
    }
    [self refreshTableHeaderForCurrentMode];
    [self.tableView reloadData];
}

- (void)onFriendsTab {
    self.isFriendsTab = YES;
    [self updateTabs];
}

- (void)onRankTab {
    self.isFriendsTab = NO;
    [self updateTabs];
}

- (void)onRankFilterTapped:(UIButton *)sender {
    if (sender == self.weekBtn) self.currentRankType = CommunityRankTypeWeek;
    else if (sender == self.monthBtn) self.currentRankType = CommunityRankTypeMonth;
    else self.currentRankType = CommunityRankTypeSeason;
    [self refreshRankButtonsUI];
    [self.tableView reloadData];
}

- (void)refreshTableHeaderForCurrentMode {
    if (self.isFriendsTab) {
        self.headerHeightConstraint.offset = 152;
        self.sectionLabel.hidden = NO;
        self.addFriendBtn.hidden = NO;
        self.qrCodeBtn.hidden = NO;
        self.rankFilterContainer.hidden = YES;
        [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.sectionLabel.mas_bottom).offset(6);
            make.leading.trailing.bottom.equalTo(self.view);
        }];
        return;
    }
    self.headerHeightConstraint.offset = 206;
    self.sectionLabel.hidden = YES;
    self.addFriendBtn.hidden = YES;
    self.qrCodeBtn.hidden = YES;
    self.rankFilterContainer.hidden = NO;
    [self.weekBtn setTitle:NSLocalizedString(@"community_rank_week", nil) forState:UIControlStateNormal];
    [self.monthBtn setTitle:NSLocalizedString(@"community_rank_month", nil) forState:UIControlStateNormal];
    [self.seasonBtn setTitle:NSLocalizedString(@"community_rank_season", nil) forState:UIControlStateNormal];
    [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView.mas_bottom);
        make.leading.trailing.bottom.equalTo(self.view);
    }];
    self.tableView.tableHeaderView = nil;
    [self refreshRankButtonsUI];
}

- (void)refreshRankButtonsUI {
    NSArray<UIButton *> *buttons = @[self.weekBtn, self.monthBtn, self.seasonBtn];
    NSArray<UIView *> *lines = @[self.weekLine, self.monthLine, self.seasonLine];
    for (NSInteger i = 0; i < buttons.count; i++) {
        UIButton *btn = buttons[i];
        BOOL selected = (i == self.currentRankType);
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        btn.alpha = selected ? 1.0 : 0.78;
        btn.titleLabel.font = [UIFont systemFontOfSize:17 weight:(selected ? UIFontWeightBold : UIFontWeightSemibold)];
        lines[i].hidden = !selected;
    }
}

- (void)onAddFriend {
    AddFriendViewController *vc = [[AddFriendViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onQRCode {
    MyQRCodeViewController *vc = [[MyQRCodeViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onPendingCountChanged {
    self.pendingCount = [[NSUserDefaults standardUserDefaults] integerForKey:kCommunityPendingCountKey];
    [self updatePendingBadge];
}

- (void)onFriendsChanged {
    [self loadRemoteFriends];
    [self.tableView reloadData];
}

- (void)updatePendingBadge {
    BOOL shouldShow = self.pendingCount > 0;
    self.pendingBadgeView.hidden = !shouldShow;
    if (!shouldShow) {
        return;
    }
    self.pendingBadgeLabel.text = self.pendingCount > 99 ? @"99+" : [NSString stringWithFormat:@"%ld", (long)self.pendingCount];
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.isFriendsTab) return self.friends.count;
    if (self.currentRankType == CommunityRankTypeWeek) return self.weekRanks.count;
    if (self.currentRankType == CommunityRankTypeMonth) return self.monthRanks.count;
    return self.seasonRanks.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.isFriendsTab ? 76 : 68;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isFriendsTab) {
        CommunityFriendCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CommunityFriendCell" forIndexPath:indexPath];
        [cell configureWithFriend:self.friends[indexPath.row]];
        return cell;
    }
    CommunityRankCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CommunityRankCell" forIndexPath:indexPath];
    NSArray<CommunityRankItem *> *source = self.currentRankType == CommunityRankTypeWeek ? self.weekRanks : (self.currentRankType == CommunityRankTypeMonth ? self.monthRanks : self.seasonRanks);
    [cell configureWithItem:source[indexPath.row] rank:indexPath.row + 1];
    return cell;
}

- (void)updateLocalizedStrings {
    [super updateLocalizedStrings];
    self.titleLabel.text = NSLocalizedString(@"community_title", nil);
    [self.friendsTab setTitle:NSLocalizedString(@"community_tab_friends", nil) forState:UIControlStateNormal];
    [self.rankTab setTitle:NSLocalizedString(@"community_tab_rank", nil) forState:UIControlStateNormal];
    [self.addFriendBtn setTitle:[NSString stringWithFormat:@"  %@  ", NSLocalizedString(@"community_add_friend", nil)] forState:UIControlStateNormal];
    [self.qrCodeBtn setTitle:[NSString stringWithFormat:@"  %@  ", NSLocalizedString(@"community_my_qrcode", nil)] forState:UIControlStateNormal];
    self.sectionLabel.text = NSLocalizedString(@"community_section_friends", nil);
    [self loadRemoteRanks];
    [self.tableView reloadData];
}

- (void)loadRemoteRanks {
    [self loadLeaderboardForPeriod:@"week" completion:^(NSArray<CommunityRankItem *> *items) {
        self.weekRanks = items;
        [self.tableView reloadData];
    }];
    [self loadLeaderboardForPeriod:@"month" completion:^(NSArray<CommunityRankItem *> *items) {
        self.monthRanks = items;
        [self.tableView reloadData];
    }];
    [self loadLeaderboardForPeriod:@"season" completion:^(NSArray<CommunityRankItem *> *items) {
        self.seasonRanks = items;
        [self.tableView reloadData];
    }];
}

- (void)loadLeaderboardForPeriod:(NSString *)period completion:(void(^)(NSArray<CommunityRankItem *> *items))completion {
    [ProfileRequest.shared getLeaderboardWithPeriod:period page:1 pageSize:30 success:^(HTTPResponse * _Nullable responseObject) {
        NSArray *list = [responseObject.data[@"list"] isKindOfClass:NSArray.class] ? responseObject.data[@"list"] : @[];
        NSMutableArray *items = NSMutableArray.array;
        for (NSDictionary *dict in list) {
            if (![dict isKindOfClass:NSDictionary.class]) continue;
            CommunityRankItem *item = CommunityRankItem.new;
            item.name = [dict[@"nickname"] isKindOfClass:NSString.class] ? dict[@"nickname"] : @"-";
            NSArray *followedTeams = [dict[@"followedTeams"] isKindOfClass:NSArray.class] ? dict[@"followedTeams"] : @[];
            NSDictionary *firstTeam = followedTeams.count > 0 && [followedTeams.firstObject isKindOfClass:NSDictionary.class] ? followedTeams.firstObject : nil;
            item.team = [firstTeam[@"name"] isKindOfClass:NSString.class] ? firstTeam[@"name"] : @"-";
            NSInteger matches = [dict[@"matchCount"] integerValue];
            item.gamesText = [NSString stringWithFormat:@"%ld 场", (long)MAX(matches, 0)];
            [items addObject:item];
        }
        completion(items);
    } failure:^(NSError * _Nonnull error) {
        completion(@[]);
    }];
}

@end
