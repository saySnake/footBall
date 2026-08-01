//
//  PassportViewController.m
//  footBall
//

#import "PassportViewController.h"
#import "PassportHeaderView.h"
#import "PassportYearTabStrip.h"
#import "PassportViewModel.h"
#import "PassportTableCells.h"
#import "StampAlbumMainPageViewController.h"
#import "ProfileRequest.h"
#import "HTTPResponse.h"
#import "AuthManager.h"
#import "CommunityRequest.h"
#import "StatisticsModels.h"
#import "PNMatchInfoInputViewController.h"
#import "TeamsRequest.h"
#import <Masonry/Masonry.h>

static UIColor *PassportPageBg(void) {
    return [UIColor colorWithHexString:@"#E6E6E6"];
}

@interface PassportViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UIView *topBar;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *refreshButton;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *headerWrap;
@property (nonatomic, strong) PassportHeaderView *passportHeader;
@property (nonatomic, strong) PassportYearTabStrip *yearStrip;
@property (nonatomic, strong) PassportViewModel *viewModel;
@property (nonatomic, assign) NSInteger selectedYear;
@property (nonatomic, assign) NSInteger passportLoadGeneration;
@property (nonatomic, assign) CGFloat passportHeaderCachedWidth;
@property (nonatomic, assign) CGFloat passportHeaderCachedHeight;
/// 当前展示是否为接口失败空态（九图各空状态，而非全 0）
@property (nonatomic, assign) BOOL passportLoadFailed;
/// 是否曾成功加载过护照（刷新失败时保留旧数据）
@property (nonatomic, assign) BOOL passportHasLoadedSuccessfully;
/// 当前 viewModel 对应的赛季年（用于判断刷新失败是否可保留）
@property (nonatomic, assign) NSInteger passportLoadedYear;
@end

@implementation PassportViewController

- (NSArray<NSNumber *> *)recentFiveYears {
    NSCalendar *cal = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    NSInteger cy = [cal component:NSCalendarUnitYear fromDate:[NSDate date]];
    NSMutableArray<NSNumber *> *years = [NSMutableArray array];
    for (NSInteger i = 0; i < 5; i++) {
        [years addObject:@(cy - i)];
    }
    return [years copy];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hidesBottomBarWhenPushed = YES;
    self.shouldShowNavigationBar = NO;
    self.view.backgroundColor = PassportPageBg();

    NSCalendar *cal = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    self.selectedYear = [cal component:NSCalendarUnitYear fromDate:[NSDate date]];
    self.passportHeaderCachedWidth = -1;
    self.passportHeaderCachedHeight = -1;

    [self buildTopBar];
    [self buildTable];
    [self setupRefresh];
    [self buildTableHeader];
    __weak typeof(self) weakSelf = self;
//    self.passportHeader.onPassportHeader2Tap = ^{
//        PassportViewModel *m = weakSelf.viewModel;
//        if (!m) {
//            return;
//        }
//        StampAlbumMainPageViewController *vc = [[StampAlbumMainPageViewController alloc] initWithViewModel:m year:weakSelf.selectedYear];
//        [weakSelf.navigationController pushViewController:vc animated:YES];
//    };
    self.viewModel = nil;
    self.passportLoadFailed = NO;
    self.passportHasLoadedSuccessfully = NO;
    [self.passportHeader applyLoadFailedEmptyAppearance];
    [self.tableView reloadData];
    [self loadPassportData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onMatchRecordDidUpdate:)
                                                 name:PNMatchRecordDidUpdateNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onTeamFollowDidUpdate:)
                                                 name:PNTeamFollowDidUpdateNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.targetUserId.length == 0 && !self.isMovingToParentViewController) {
        [self loadPassportDataForceRefresh:NO];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 自定义导航栏页面也开启系统左侧滑动返回
    if (self.navigationController.viewControllers.count > 1) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        self.navigationController.interactivePopGestureRecognizer.delegate = nil;
    }
}

- (void)buildTopBar {
    _topBar = [[UIView alloc] init];
    _topBar.backgroundColor = [UIColor colorWithHexString:@"#0D2122"];
    [self.view addSubview:_topBar];

    _backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    if (@available(iOS 13.0, *)) {
        UIImage *img = [UIImage systemImageNamed:@"chevron.left"];
        [_backButton setImage:[img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    } else {
        [_backButton setTitle:NSLocalizedString(@"back", nil) ?: @"返回" forState:UIControlStateNormal];
    }
    _backButton.tintColor = [UIColor whiteColor];
    [_backButton addTarget:self action:@selector(onBack) forControlEvents:UIControlEventTouchUpInside];

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    _titleLabel.textColor = [UIColor whiteColor];
    if (self.targetUserId.length > 0) {
        NSString *name = self.targetNickname.length > 0 ? self.targetNickname : (NSLocalizedString(@"passport_nav_title_friend", nil) ?: @"TA的护照");
        _titleLabel.text = name;
    } else {
        _titleLabel.text = NSLocalizedString(@"passport_nav_title", nil) ?: @"我的护照";
    }

    _refreshButton = [UIButton buttonWithType:UIButtonTypeSystem];
    if (@available(iOS 13.0, *)) {
        UIImage *img = [UIImage imageNamed:@"passport_share"];
        [_refreshButton setImage:[img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    _refreshButton.hidden = YES;
    _refreshButton.tintColor = [UIColor whiteColor];
    [_refreshButton addTarget:self action:@selector(loadPassportData) forControlEvents:UIControlEventTouchUpInside];

    [_topBar addSubview:_backButton];
    [_topBar addSubview:_titleLabel];
    [_topBar addSubview:_refreshButton];

    [_topBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(44);
    }];
    [_backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(_topBar).offset(8);
        make.bottom.equalTo(_topBar).offset(-8);
        make.width.height.mas_equalTo(36);
    }];
    [_refreshButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(_topBar).offset(-8);
        make.centerY.equalTo(_backButton);
        make.width.height.mas_equalTo(36);
    }];
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(_topBar);
        make.centerY.equalTo(_backButton);
    }];
}

- (void)buildTable {
    UIView *topBg = UIView.alloc.init;
    topBg.backgroundColor = [UIColor colorWithHexString:@"#0D2122"];
    [self.view addSubview:topBg];
    [topBg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_topBar.mas_bottom);
        make.leading.trailing.equalTo(self.view);
        make.height.equalTo(@30);
    }];
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.backgroundColor = UIColor.clearColor;
    _tableView.showsVerticalScrollIndicator = YES;
    _tableView.estimatedRowHeight = 200;
    _tableView.rowHeight = UITableViewAutomaticDimension;
    _tableView.contentInset = UIEdgeInsetsMake(0, 0, 24, 0);
    _tableView.scrollIndicatorInsets = _tableView.contentInset;
    [self.view addSubview:_tableView];

    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_topBar.mas_bottom);
        make.leading.trailing.bottom.equalTo(self.view);
    }];

    [_tableView registerClass:[PassportDarkStatsCardCell class] forCellReuseIdentifier:@"stats"];
    [_tableView registerClass:[PassportGrowthBannerCell class] forCellReuseIdentifier:@"growth"];
    [_tableView registerClass:[PassportBarChartCardCell class] forCellReuseIdentifier:@"bar"];
    [_tableView registerClass:[PassportPossessionCardCell class] forCellReuseIdentifier:@"poss"];
    [_tableView registerClass:[PassportPositionStrengthCell class] forCellReuseIdentifier:@"pos"];
    [_tableView registerClass:[PassportAbilityBlockCell class] forCellReuseIdentifier:@"abil"];
    [_tableView registerClass:[PassportTacticalCell class] forCellReuseIdentifier:@"tact"];
    [_tableView registerClass:[PassportMetricBarsCell class] forCellReuseIdentifier:@"metric"];
    [_tableView registerClass:[PassportOutcomeCell class] forCellReuseIdentifier:@"out"];
    [_tableView registerClass:[PassportChartEmptyStateCell class] forCellReuseIdentifier:@"chartEmpty"];
}

- (void)buildTableHeader {
    _headerWrap = [[UIView alloc] init];
    _headerWrap.backgroundColor = UIColor.clearColor;

    _passportHeader = [[PassportHeaderView alloc] init];
    _yearStrip = [[PassportYearTabStrip alloc] init];

    NSArray<NSNumber *> *years = [self recentFiveYears];
    NSInteger sel = self.selectedYear;
    if (![years containsObject:@(sel)]) {
        sel = years.firstObject.integerValue;
        self.selectedYear = sel;
    }
    [_yearStrip setYears:years selectedYear:sel];
    __weak typeof(self) weakSelf = self;
    _yearStrip.onYearChanged = ^(NSInteger year) {
        weakSelf.selectedYear = year;
        [weakSelf invalidatePassportHeaderLayoutCache];
        [weakSelf.view setNeedsLayout];
        [weakSelf loadPassportData];
    };

    [_headerWrap addSubview:_passportHeader];
    [_headerWrap addSubview:_yearStrip];

    [_passportHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@15);
        make.leading.equalTo(@0);
        make.trailing.equalTo(@0);
    }];
    [_yearStrip mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_passportHeader.mas_bottom);
        make.leading.trailing.bottom.equalTo(_headerWrap);
        make.height.mas_equalTo(52);
    }];

    _headerWrap.translatesAutoresizingMaskIntoConstraints = NO;
}

- (void)setupRefresh {
    RefreshPagHeader *header = [RefreshPagHeader headerWithRefreshingTarget:self refreshingAction:@selector(onPullToRefresh)];
    [header prepare];
    _tableView.mj_header = header;
}

- (void)onPullToRefresh {
    [self loadPassportData];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutPassportTableHeaderIfNeeded];
}

/// 用临时宽度约束测量高度；仅在宽高变化时设置 tableHeaderView，避免 layout ↔ 赋值死循环撑满 CPU。
- (void)layoutPassportTableHeaderIfNeeded {
    if (!_headerWrap || !_tableView) return;
    CGFloat w = CGRectGetWidth(_tableView.bounds);
    if (w < 1) return;

    NSLayoutConstraint *tmpWidth = [_headerWrap.widthAnchor constraintEqualToConstant:w];
    tmpWidth.active = YES;
    [_headerWrap setNeedsLayout];
    [_headerWrap layoutIfNeeded];
    CGFloat h = ceil([_headerWrap systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height);
    tmpWidth.active = NO;

    if (!(h > 0) || h > 10000) h = 320;
    if (h < 52) h = 52;

    BOOL same =
        (fabs(w - self.passportHeaderCachedWidth) < 0.5 &&
        fabs(h - self.passportHeaderCachedHeight) < 0.5 &&
        _tableView.tableHeaderView == _headerWrap &&
        fabs(CGRectGetWidth(_headerWrap.bounds) - w) < 0.5 &&
        fabs(CGRectGetHeight(_headerWrap.bounds) - h) < 0.5);
    if (same) return;

    self.passportHeaderCachedWidth = w;
    self.passportHeaderCachedHeight = h;

    _headerWrap.translatesAutoresizingMaskIntoConstraints = YES;
    _headerWrap.frame = CGRectMake(0, 0, w, h);
    _tableView.tableHeaderView = _headerWrap;
}

- (void)invalidatePassportHeaderLayoutCache {
    self.passportHeaderCachedWidth = -1;
    self.passportHeaderCachedHeight = -1;
}

- (void)loadPassportData {
    [self loadPassportDataForceRefresh:NO];
}

- (void)loadPassportDataForceRefresh:(BOOL)forceRefresh {
    __weak typeof(self) weakSelf = self;
    NSInteger generation = ++self.passportLoadGeneration;
    BOOL isPullRefresh = self.tableView.mj_header.isRefreshing;
    if (!isPullRefresh) {
        [self showLoading];
    }
    NSString *y = [NSString stringWithFormat:@"%ld", (long)self.selectedYear];
    BOOL isOther = self.targetUserId.length > 0;
    void (^handleSuccess)(PNPassport *) = ^(PNPassport *p) {
        if (generation != weakSelf.passportLoadGeneration) {
            return;
        }
        [weakSelf hideLoading];
        [weakSelf.tableView.mj_header endRefreshing];
        weakSelf.passportLoadFailed = NO;
        weakSelf.passportHasLoadedSuccessfully = YES;
        weakSelf.passportLoadedYear = weakSelf.selectedYear;
        weakSelf.viewModel = [PassportViewModel viewModelWithPassport:p year:weakSelf.selectedYear];
        // 查看自己的护照时，用本地 AuthManager 的真实头像和城市覆盖接口返回的占位数据
        if (!isOther) {
            NSString *localAvatar = AuthManager.sharedManager.user.profile.avatar;
            if (!localAvatar.length) {
                localAvatar = AuthManager.sharedManager.user.avatar;
            }
            if (localAvatar.length) {
                weakSelf.viewModel.avatarURL = localAvatar;
            }
            NSString *localCity = AuthManager.sharedManager.user.profile.city;
            if (localCity.length) {
                weakSelf.viewModel.userCity = localCity;
            }
        }
        [weakSelf.passportHeader configureWithModel:weakSelf.viewModel];
        [weakSelf.yearStrip setYears:[weakSelf recentFiveYears] selectedYear:weakSelf.selectedYear];
        [weakSelf.tableView reloadData];
        [weakSelf invalidatePassportHeaderLayoutCache];
        [weakSelf.view setNeedsLayout];
        // 软拉取底部 16 坑位图标；失败不影响护照主体展示
        NSString *iconUserId = isOther ? weakSelf.targetUserId : (p.userId.length ? p.userId : (AuthManager.sharedManager.user.profile.userId ?: AuthManager.sharedManager.user.userId));
        if (iconUserId.length > 0) {
            [[ProfileRequest shared] getPassportIconsForUserId:iconUserId success:^(HTTPResponse * _Nullable responseObject) {
                if (generation != weakSelf.passportLoadGeneration) {
                    return;
                }
                NSArray *icons = [responseObject.dataObject isKindOfClass:NSArray.class] ? responseObject.dataObject : @[];
                weakSelf.viewModel.header2IconItems = icons;
                [weakSelf.passportHeader configureWithModel:weakSelf.viewModel];
            } failure:^(NSError * _Nonnull error) {
                // ignore: 图标接口失败时保持空坑位
            }];
        }
    };
    void (^handleFailure)(NSError *) = ^(NSError *error) {
        if (generation != weakSelf.passportLoadGeneration) {
            return;
        }
        [weakSelf hideLoading];
        [weakSelf.tableView.mj_header endRefreshing];
        // 同赛季下拉刷新失败：保留原图表，只 toast，避免刷成全 0
        if (weakSelf.passportHasLoadedSuccessfully &&
            weakSelf.viewModel &&
            !weakSelf.passportLoadFailed &&
            weakSelf.passportLoadedYear == weakSelf.selectedYear) {
            [weakSelf showError:error.localizedDescription ?: (NSLocalizedString(@"network_error", nil) ?: @"")];
            return;
        }
        // 首次加载 / 换年失败：各分区展示空状态，不写入 0 数据
        weakSelf.passportLoadFailed = YES;
        weakSelf.viewModel = nil;
        [weakSelf.passportHeader applyLoadFailedEmptyAppearance];
        [weakSelf.yearStrip setYears:[weakSelf recentFiveYears] selectedYear:weakSelf.selectedYear];
        [weakSelf.tableView reloadData];
        [weakSelf invalidatePassportHeaderLayoutCache];
        [weakSelf.view setNeedsLayout];
    };
    if (isOther) {
        [[ProfileRequest shared] getPassportForUserId:self.targetUserId year:y success:^(HTTPResponse * _Nullable responseObject) {
            PNPassport *p = [responseObject.dataObject isKindOfClass:PNPassport.class] ? responseObject.dataObject : nil;
            if (p && !p.nickname.length && weakSelf.targetNickname.length > 0) {
                p.nickname = weakSelf.targetNickname;
            }
            handleSuccess(p);
        } failure:^(NSError * _Nonnull error) {
            [[CommunityRequest shared] getFriendData:weakSelf.targetUserId success:^(HTTPResponse * _Nullable responseObject) {
                PNStatistics *stats = [responseObject.dataObject isKindOfClass:PNStatistics.class] ? responseObject.dataObject : nil;
                PNPassport *p = stats ? [weakSelf convertStatisticsToPassport:stats] : nil;
                if (p) {
                    handleSuccess(p);
                } else {
                    handleFailure(error);
                }
            } failure:^(NSError * _Nonnull error) {
                handleFailure(error);
            }];
        }];
    } else {
        [[ProfileRequest shared] getMyPassportWithYear:y bypassCache:forceRefresh success:^(HTTPResponse * _Nullable responseObject) {
            PNPassport *p = [responseObject.dataObject isKindOfClass:PNPassport.class] ? responseObject.dataObject : nil;
            handleSuccess(p);
        } failure:^(NSError * _Nonnull error) {
            handleFailure(error);
        }];
    }
}

/// 将统计数据转换为护照数据格式
- (PNPassport *)convertStatisticsToPassport:(PNStatistics *)stats {
    if (!stats) return nil;
    
    PNPassport *passport = [[PNPassport alloc] init];
    passport.userId = self.targetUserId;
    passport.nickname = self.targetNickname.length > 0 ? self.targetNickname : @"";
    
    // 基础统计
    if (stats.basicStats) {
        passport.yearTotalMatches = stats.basicStats.totalMatches;
        if (stats.basicStats.mostVisitedStadium) {
            passport.topLocation = stats.basicStats.mostVisitedStadium.name;
        }
    }
    
    // 累计观赛时长
    passport.careerTotalWatchTime = stats.cumulativeWatchTime ?: 0;
    
    // 国家数和球场数
    passport.yearCountryCount = stats.countryCount ?: 0;
    passport.yearStadiumCount = stats.totalStadiumCount ?: 0;
    passport.yearCityCount = stats.basicStats.mostVisitedStadium.city.length > 0 ? 1 : 0;
    
    // 主队战绩
    if (stats.teamRecord) {
        passport.teamRecord = [[PNPassportTeamRecord alloc] init];
        passport.teamRecord.wins = stats.teamRecord.wins;
        passport.teamRecord.draws = stats.teamRecord.draws;
        passport.teamRecord.losses = stats.teamRecord.losses;
    }
    
    return passport;
}

- (void)onBack {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.passportLoadFailed) {
        return 9;
    }
    return self.viewModel ? 9 : 0;
}

- (NSString *)passportChartTitleAtIndex:(NSInteger)index {
    NSInteger y = self.selectedYear;
    switch (index) {
        case 0: return NSLocalizedString(@"passport_year_total_watch_time", nil) ?: @"年度总观赛时长";
        case 1: {
            NSString *suffix = NSLocalizedString(@"passport_growth_wake_suffix", nil) ?: @"年睡醒时间里的";
            return [NSString stringWithFormat:@"%ld%@", (long)y, suffix];
        }
        case 2: return [NSString stringWithFormat:@"%ld年观赛数据", (long)y];
        case 3: return [NSString stringWithFormat:NSLocalizedString(@"passport_followed_team_win_rate_title", nil) ?: @"%ld年我关注的主队胜率", (long)y];
        case 4: return NSLocalizedString(@"passport_position_strength", nil) ?: @"空间维度";
        case 5: return NSLocalizedString(@"passport_ability_detail", nil) ?: @"线下观赛数据观";
        case 6: return NSLocalizedString(@"passport_tactical_identity_title", nil) ?: @"观赛身份";
        case 7: return NSLocalizedString(@"passport_metric_prompt", nil) ?: @"看球之后，我更容易：";
        case 8: {
            NSString *t = NSLocalizedString(@"passport_online_viewing_title", nil);
            if (!t.length || [t isEqualToString:@"passport_online_viewing_title"]) {
                t = NSLocalizedString(@"passport_outcome_vs_last", nil) ?: @"线上观赛数据";
            }
            return t;
        }
        default: return @"";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.passportLoadFailed) {
        PassportChartEmptyStateCell *empty = [tableView dequeueReusableCellWithIdentifier:@"chartEmpty" forIndexPath:indexPath];
        [empty configureWithTitle:[self passportChartTitleAtIndex:indexPath.row]];
        return empty;
    }
    PassportViewModel *m = self.viewModel;
    switch (indexPath.row) {
        case 0: {
            PassportDarkStatsCardCell *c = [tableView dequeueReusableCellWithIdentifier:@"stats" forIndexPath:indexPath];
            [c configureWithModel:m];
            return c;
        }
        case 1: {
            PassportGrowthBannerCell *c = [tableView dequeueReusableCellWithIdentifier:@"growth" forIndexPath:indexPath];
            [c configureWithModel:m];
            return c;
        }
        case 2: {
            PassportBarChartCardCell *c = [tableView dequeueReusableCellWithIdentifier:@"bar" forIndexPath:indexPath];
            [c configureWithModel:m];
            return c;
        }
        case 3: {
            PassportPossessionCardCell *c = [tableView dequeueReusableCellWithIdentifier:@"poss" forIndexPath:indexPath];
            [c configureWithModel:m];
            return c;
        }
        case 4: {
            PassportPositionStrengthCell *c = [tableView dequeueReusableCellWithIdentifier:@"pos" forIndexPath:indexPath];
            [c configureWithModel:m];
            return c;
        }
        case 5: {
            PassportAbilityBlockCell *c = [tableView dequeueReusableCellWithIdentifier:@"abil" forIndexPath:indexPath];
            [c configureWithModel:m];
            return c;
        }
        case 6: {
            PassportTacticalCell *c = [tableView dequeueReusableCellWithIdentifier:@"tact" forIndexPath:indexPath];
            [c configureWithModel:m];
            return c;
        }
        case 7: {
            PassportMetricBarsCell *c = [tableView dequeueReusableCellWithIdentifier:@"metric" forIndexPath:indexPath];
            [c configureWithModel:m];
            return c;
        }
        case 8: {
            PassportOutcomeCell *c = [tableView dequeueReusableCellWithIdentifier:@"out" forIndexPath:indexPath];
            [c configureWithModel:m];
            return c;
        }
        default:
            return [[UITableViewCell alloc] init];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // 失败空态：每个 section 都用统一的占位高度
    if (self.passportLoadFailed || !self.viewModel) {
        return 168;
    }
    // GrowthBannerCell（row 1）固定高度；DarkStatsCardCell（row 0）走 AutomaticDimension
    if (indexPath.row == 1) {
        return 197;
    }
    // BarChartCardCell（row 2）设计稿固定高度
    if (indexPath.row == 2) {
        return 343;
    }
    // PassportPossessionCardCell 设计稿固定高度
    if (indexPath.row == 3) {
        return 254;
    }
    // PassportPositionStrengthCell 设计稿固定高度
    if (indexPath.row == 4) {
        return 412;
    }
    // PassportAbilityBlockCell：10 行座位（与输入信息一致）
    if (indexPath.row == 5) {
        return 422;
    }
    // PassportTacticalCell：图例每行 3 个，高度随 tacticalSegments 数量变化
    if (indexPath.row == 6) {
        NSUInteger segCount = self.viewModel.tacticalSegments.count;
        return [PassportTacticalCell preferredHeightForSegmentCount:segCount];
    }
    // PassportMetricBarsCell 设计稿（90pt 数字 + 7 条情绪 bar）
    if (indexPath.row == 7) {
        return 368 + 2;
    }
    // PassportOutcomeCell 设计稿（标题 + 圆环 + 2x2 图例）
    if (indexPath.row == 8) {
        return 416;
    }
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.passportLoadFailed) {
        return 168;
    }
    if (indexPath.row == 1) {
        return 197;
    }
    if (indexPath.row == 2) {
        return 343;
    }
    if (indexPath.row == 3) {
        return 254;
    }
    if (indexPath.row == 4) {
        return 412;
    }
    if (indexPath.row == 5) {
        return 522;
    }
    if (indexPath.row == 6) {
        return 520;
    }
    if (indexPath.row == 7) {
        return 370;
    }
    if (indexPath.row == 8) {
        return 416;
    }
    return 200;
}

- (void)updateLocalizedStrings {
    [super updateLocalizedStrings];
    if (self.targetUserId.length > 0) {
        NSString *name = self.targetNickname.length > 0 ? self.targetNickname : (NSLocalizedString(@"passport_nav_title_friend", nil) ?: @"TA的护照");
        _titleLabel.text = name;
    } else {
        _titleLabel.text = NSLocalizedString(@"passport_nav_title", nil) ?: @"我的护照";
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Notifications

- (void)onMatchRecordDidUpdate:(NSNotification *)notification {
    [self loadPassportDataForceRefresh:YES];
}

- (void)onTeamFollowDidUpdate:(NSNotification *)notification {
    [self loadPassportData];
}

@end
