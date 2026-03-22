//
//  HomeViewController.m
//  footBall
//

#import "HomeViewController.h"
#import "MoreMatchesViewController.h"
#import "RefreshPagHeader.h"
#import <Masonry/Masonry.h>
#import "ColorManager.h"

#define kHeaderGreen [ColorManager sharedManager].primaryDarkColor
#define kCardDarkerGreen [UIColor colorWithRed:0.06 green:0.28 blue:0.22 alpha:1.0]
#define kCardLightGray [UIColor colorWithRed:0.96 green:0.96 blue:0.96 alpha:1.0]
#define kScoreOvalBg [UIColor colorWithRed:0.28 green:0.28 blue:0.30 alpha:1.0]
#define kTimePillGreen [UIColor colorWithRed:0.85 green:0.92 blue:0.78 alpha:1.0]
static NSString *const kLogoPlaceholder = @"team_placeholder";

#pragma mark - 顶部关注球队项（与 TeamSelection 的 TeamModel 区分）
@interface HomeTeamItem : NSObject
@property (nonatomic, copy) NSString *teamId;
@property (nonatomic, copy) NSString *name;
@end
@implementation HomeTeamItem
@end

#pragma mark - 赛程模型
@interface MatchModel : NSObject
@property (nonatomic, copy) NSString *date;           // 2025-12
@property (nonatomic, copy) NSString *homeTeamId;
@property (nonatomic, copy) NSString *awayTeamId;
@property (nonatomic, copy) NSString *homeTeam;
@property (nonatomic, copy) NSString *awayTeam;
@property (nonatomic, copy) NSString *score;
@property (nonatomic, copy) NSString *time;
@property (nonatomic, assign) BOOL finished;
@property (nonatomic, copy) NSString *dateDetail;      // 15 Dec, 2025
@end
@implementation MatchModel
@end

#pragma mark - 顶部球队 Cell
@interface HomeTeamCell : UICollectionViewCell
@property (nonatomic, strong) UIView *circleView;
@property (nonatomic, strong) UIImageView *logoView;
@property (nonatomic, strong) UILabel *nameLabel;
@end
@implementation HomeTeamCell
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _circleView = [[UIView alloc] init];
        _circleView.layer.cornerRadius = 28;
        _circleView.clipsToBounds = YES;
        _logoView = [[UIImageView alloc] init];
        _logoView.contentMode = UIViewContentModeScaleAspectFit;
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont systemFontOfSize:11];
        _nameLabel.textColor = [UIColor whiteColor];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        _nameLabel.numberOfLines = 1;
        [self.contentView addSubview:_circleView];
        [_circleView addSubview:_logoView];
        [self.contentView addSubview:_nameLabel];
        [_circleView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.centerX.equalTo(self.contentView);
            make.width.height.mas_equalTo(56);
        }];
        [_logoView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(_circleView);
            make.width.height.mas_equalTo(32);
        }];
        [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_circleView.mas_bottom).offset(6);
            make.leading.trailing.equalTo(self.contentView);
        }];
    }
    return self;
}
- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    _circleView.backgroundColor = selected ? [UIColor colorWithWhite:0.5 alpha:1.0] : [UIColor colorWithWhite:0.25 alpha:1.0];
}
@end

#pragma mark - 赛程卡片 Cell（含日期、比分/时间、06:30 胶囊、播放/收藏）
@interface MatchCell : UITableViewCell
@property (nonatomic, strong) UIImageView *homeLogo;
@property (nonatomic, strong) UIImageView *awayLogo;
@property (nonatomic, strong) UILabel *homeLabel;
@property (nonatomic, strong) UILabel *awayLabel;
@property (nonatomic, strong) UILabel *centerLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UIButton *timePill;
@property (nonatomic, strong) UIButton *playBtn;
@property (nonatomic, strong) UIButton *bookmarkBtn;
@end
@implementation MatchCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor whiteColor];
        UIView *card = [[UIView alloc] init];
        card.backgroundColor = [UIColor whiteColor];
        card.layer.cornerRadius = 12;
        card.layer.shadowColor = [UIColor blackColor].CGColor;
        card.layer.shadowOpacity = 0.06;
        card.layer.shadowOffset = CGSizeMake(0, 2);
        card.layer.shadowRadius = 4;
        card.layer.borderWidth = 0.5;
        card.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:1.0].CGColor;
        [self.contentView addSubview:card];
        [card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(6, 20, 6, 20));
        }];
        _dateLabel = [[UILabel alloc] init];
        _dateLabel.font = [UIFont systemFontOfSize:11];
        _dateLabel.textColor = [UIColor darkGrayColor];
        _homeLogo = [[UIImageView alloc] init];
        _awayLogo = [[UIImageView alloc] init];
        _homeLabel = [[UILabel alloc] init];
        _awayLabel = [[UILabel alloc] init];
        UIView *scoreOval = [[UIView alloc] init];
        scoreOval.backgroundColor = kScoreOvalBg;
        scoreOval.layer.cornerRadius = 14;
        _centerLabel = [[UILabel alloc] init];
        _centerLabel.font = [UIFont boldSystemFontOfSize:16];
        _centerLabel.textAlignment = NSTextAlignmentCenter;
        _centerLabel.textColor = [UIColor whiteColor];
        [scoreOval addSubview:_centerLabel];
        [_centerLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(scoreOval).insets(UIEdgeInsetsMake(4, 12, 4, 12));
        }];
        _timePill = [UIButton buttonWithType:UIButtonTypeSystem];
        _timePill.titleLabel.font = [UIFont systemFontOfSize:12];
        [_timePill setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        _timePill.backgroundColor = kTimePillGreen;
        _timePill.layer.cornerRadius = 10;
        _playBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _bookmarkBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        if (@available(iOS 13.0, *)) {
            [_playBtn setImage:[UIImage systemImageNamed:@"play.circle.fill"] forState:UIControlStateNormal];
            [_bookmarkBtn setImage:[UIImage systemImageNamed:@"bookmark"] forState:UIControlStateNormal];
            _playBtn.tintColor = [UIColor darkGrayColor];
            _bookmarkBtn.tintColor = [UIColor darkGrayColor];
        }
        _homeLabel.font = _awayLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        [card addSubview:_homeLogo];
        [card addSubview:_homeLabel];
        [card addSubview:_dateLabel];
        [card addSubview:scoreOval];
        [card addSubview:_awayLabel];
        [card addSubview:_awayLogo];
        [card addSubview:_timePill];
        [card addSubview:_playBtn];
        [card addSubview:_bookmarkBtn];
        [_homeLogo mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(card).offset(12);
            make.centerY.equalTo(card).offset(-10);
            make.width.height.mas_equalTo(28);
        }];
        [_homeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_homeLogo.mas_trailing).offset(8);
            make.centerY.equalTo(_homeLogo);
        }];
        [_dateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_homeLabel);
            make.top.equalTo(_homeLabel.mas_bottom).offset(4);
        }];
        [scoreOval mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(card);
            make.centerY.equalTo(card).offset(-10);
        }];
        [_timePill mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(card);
            make.top.equalTo(scoreOval.mas_bottom).offset(6);
            make.height.mas_equalTo(22);
            make.width.mas_greaterThanOrEqualTo(44);
        }];
        [_awayLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(_awayLogo.mas_leading).offset(-8);
            make.centerY.equalTo(_homeLogo);
        }];
        [_awayLogo mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(_playBtn.mas_leading).offset(-12);
            make.centerY.equalTo(card).offset(-10);
            make.width.height.mas_equalTo(28);
        }];
        [_bookmarkBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(card).offset(-12);
            make.centerY.equalTo(card).offset(-10);
            make.width.height.mas_equalTo(32);
        }];
        [_playBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(_bookmarkBtn.mas_leading).offset(-8);
            make.centerY.equalTo(_bookmarkBtn);
            make.width.height.mas_equalTo(32);
        }];
    }
    return self;
}
@end

#pragma mark - HomeViewController

@interface HomeViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *challengerLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UIButton *heartBtn;
@property (nonatomic, strong) UICollectionView *teamCollectionView;
@property (nonatomic, strong) NSArray<TeamIcon *> *teamItems;
@property (nonatomic, copy, nullable) NSString *selectedTeamId; // nil = 全部

@property (nonatomic, strong) NSMutableArray<MatchModel *> *dataSource;
@property (nonatomic, strong) NSMutableArray<MatchModel *> *filteredData;
@property (nonatomic, strong) MatchModel *highlightFinished;
@property (nonatomic, strong) MatchModel *highlightUpcoming;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *bodyBgView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *moreBtn;
@property (nonatomic, strong) UIView *twoCardsContainer;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) MASConstraint *tableHeightConstraint;
@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.shouldShowNavigationBar = NO;
    [self buildTeams];
    [self loadFakeData];
    self.selectedTeamId = nil;
    [self filterData];
    [self setupUI];
    [self setupRefresh];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self fetchUserProfile];
    [self fetchFollowTeams];
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // 底部预留 tab bar 高度，避免内容滑到 tab bar 下方导致无法点击
    CGFloat tabBarH = self.tabBarController.tabBar.bounds.size.height;
    if (tabBarH > 0 && _scrollView.contentInset.bottom != tabBarH) {
        _scrollView.contentInset = UIEdgeInsetsMake(0, 0, tabBarH, 0);
    }
}

- (void)buildTeams {
//    HomeTeamItem *all = [HomeTeamItem new];
//    all.teamId = nil;
//    all.name = NSLocalizedString(@"home_all_teams", nil);
//    NSArray *ids = @[ @"burnley", @"wolves", @"liverpool", @"brentford", @"brighton", @"arsenal" ];
//    NSArray *names = @[
//        NSLocalizedString(@"team_name_burnley", nil),
//        NSLocalizedString(@"team_name_wolves", nil),
//        NSLocalizedString(@"team_name_liverpool", nil),
//        NSLocalizedString(@"team_name_brentford", nil),
//        NSLocalizedString(@"team_name_brighton", nil),
//        NSLocalizedString(@"team_name_arsenal", nil),
//    ];
//    NSMutableArray *arr = [NSMutableArray arrayWithObject:all];
//    for (NSInteger i = 0; i < ids.count; i++) {
//        HomeTeamItem *item = [HomeTeamItem new];
//        item.teamId = ids[i];
//        item.name = names[i];
//        [arr addObject:item];
//    }
//    self.teamItems = [arr copy];
}

- (void)loadFakeData {
    _dataSource = [NSMutableArray array];
    NSString *nforest = NSLocalizedString(@"team_name_nforest", nil);
    NSString *liverpool = NSLocalizedString(@"team_name_liverpool", nil);
    NSString *arsenal = NSLocalizedString(@"team_name_arsenal", nil);
    NSString *brighton = NSLocalizedString(@"team_name_brighton", nil);
    NSString *burnley = NSLocalizedString(@"team_name_burnley", nil);
    NSString *wolves = NSLocalizedString(@"team_name_wolves", nil);
    NSString *brentford = NSLocalizedString(@"team_name_brentford", nil);

    MatchModel *last = [MatchModel new];
    last.date = @"2025-02";
    last.homeTeamId = @"nforest";
    last.awayTeamId = @"liverpool";
    last.homeTeam = nforest;
    last.awayTeam = liverpool;
    last.score = @"0 : 2";
    last.time = @"11:00 pm";
    last.finished = YES;
    last.dateDetail = @"Sun, 18 Feb 25";
    self.highlightFinished = last;

    MatchModel *next = [MatchModel new];
    next.date = @"2025-02";
    next.homeTeamId = @"nforest";
    next.awayTeamId = @"liverpool";
    next.homeTeam = nforest;
    next.awayTeam = liverpool;
    next.score = @"";
    next.time = @"11:00 pm";
    next.finished = NO;
    next.dateDetail = @"Sun, 18 Feb 25";
    self.highlightUpcoming = next;

    // 2025-12：阿森纳 vs 布莱顿，4 场已结束（与原型一致）
    for (NSInteger i = 0; i < 4; i++) {
        MatchModel *m = [MatchModel new];
        m.date = @"2025-12";
        m.homeTeamId = @"arsenal";
        m.awayTeamId = @"brighton";
        m.homeTeam = arsenal;
        m.awayTeam = brighton;
        m.score = @"2:0";
        m.time = @"06:30";
        m.finished = YES;
        m.dateDetail = @"15 Dec, 2025";
        [_dataSource addObject:m];
    }

    // 2025-12：两场未开始的阿森纳 vs 布莱顿（下一场示例）
    for (NSInteger i = 0; i < 2; i++) {
        MatchModel *m = [MatchModel new];
        m.date = @"2025-12";
        m.homeTeamId = @"arsenal";
        m.awayTeamId = @"brighton";
        m.homeTeam = arsenal;
        m.awayTeam = brighton;
        m.score = @"";
        m.time = @"08:30";
        m.finished = NO;
        m.dateDetail = @"20 Dec, 2025";
        [_dataSource addObject:m];
    }

    // 2025-11：狼队 vs 利物浦
    for (NSInteger i = 0; i < 3; i++) {
        MatchModel *m = [MatchModel new];
        m.date = @"2025-11";
        m.homeTeamId = @"wolves";
        m.awayTeamId = @"liverpool";
        m.homeTeam = wolves;
        m.awayTeam = liverpool;
        m.score = (i % 2 == 0) ? @"1:1" : @"0:3";
        m.time = @"09:00";
        m.finished = (i != 2); // 最后一场未开始
        if (!m.finished) m.score = @"";
        m.dateDetail = @"10 Nov, 2025";
        [_dataSource addObject:m];
    }

    // 2025-10：伯恩利 vs 布伦特福德
    for (NSInteger i = 0; i < 3; i++) {
        MatchModel *m = [MatchModel new];
        m.date = @"2025-10";
        m.homeTeamId = @"burnley";
        m.awayTeamId = @"brentford";
        m.homeTeam = burnley;
        m.awayTeam = brentford;
        m.score = @"2:1";
        m.time = @"07:45";
        m.finished = YES;
        m.dateDetail = @"05 Oct, 2025";
        [_dataSource addObject:m];
    }

    _filteredData = [_dataSource mutableCopy];
}

- (void)filterData {
    if (!_selectedTeamId.length) {
        _filteredData = [_dataSource mutableCopy];
    } else {
        NSMutableArray *arr = [NSMutableArray array];
        for (MatchModel *m in _dataSource) {
            if ([m.homeTeamId isEqualToString:_selectedTeamId] || [m.awayTeamId isEqualToString:_selectedTeamId])
                [arr addObject:m];
        }
        _filteredData = arr;
    }
    [_tableView reloadData];
    if (_tableView) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateTableHeight];
        });
    }
}

- (void)setupUI {
    [self setupHeader];
    [self setupScrollContent];
}

- (void)onMoreTapped {
    MoreMatchesViewController *vc = [[MoreMatchesViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)setupHeader {
    _headerView = [[UIView alloc] init];
    _headerView.backgroundColor = kHeaderGreen;
    [self.view addSubview:_headerView];

    _avatarView = [[UIImageView alloc] init];
    _avatarView.backgroundColor = [UIColor colorWithRed:0.4 green:0.3 blue:0.5 alpha:1.0];
    _avatarView.layer.cornerRadius = 24;
    _avatarView.clipsToBounds = YES;
    _avatarView.contentMode = UIViewContentModeScaleAspectFill;
    if (@available(iOS 13.0, *)) {
        _avatarView.image = [UIImage systemImageNamed:@"person.fill"];
        _avatarView.tintColor = [UIColor whiteColor];
    }
    _challengerLabel = [[UILabel alloc] init];
    _challengerLabel.text = NSLocalizedString(@"home_challenger", nil);
    _challengerLabel.font = [UIFont boldSystemFontOfSize:16];
    _challengerLabel.textColor = [UIColor whiteColor];
    _dateLabel = [[UILabel alloc] init];
    _dateLabel.text = @"February 20, 2025";
    _dateLabel.font = [UIFont systemFontOfSize:13];
    _dateLabel.textColor = [UIColor colorWithWhite:0.75 alpha:1.0];
    _heartBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    if (@available(iOS 13.0, *)) {
        [_heartBtn setImage:[UIImage systemImageNamed:@"heart"] forState:UIControlStateNormal];
        _heartBtn.tintColor = [UIColor whiteColor];
    }
    [_headerView addSubview:_avatarView];
    [_headerView addSubview:_challengerLabel];
    [_headerView addSubview:_dateLabel];
    [_headerView addSubview:_heartBtn];

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumInteritemSpacing = 16;
    layout.sectionInset = UIEdgeInsetsMake(0, 20, 0, 20);
    _teamCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _teamCollectionView.backgroundColor = [UIColor clearColor];
    _teamCollectionView.showsHorizontalScrollIndicator = NO;
    _teamCollectionView.dataSource = self;
    _teamCollectionView.delegate = self;
    [_teamCollectionView registerClass:[HomeTeamCell class] forCellWithReuseIdentifier:@"TeamCell"];
    [_headerView addSubview:_teamCollectionView];

    [_headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(_teamCollectionView.mas_bottom).offset(16);
    }];
    [_avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_headerView.mas_safeAreaLayoutGuideTop).offset(12);
        make.leading.equalTo(_headerView).offset(20);
        make.width.height.mas_equalTo(48);
    }];
    [_challengerLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(_avatarView.mas_trailing).offset(12);
        make.centerY.equalTo(_avatarView).offset(-8);
    }];
    [_dateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(_challengerLabel);
        make.top.equalTo(_challengerLabel.mas_bottom).offset(2);
    }];
    [_heartBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(_headerView).offset(-20);
        make.centerY.equalTo(_avatarView);
        make.width.height.mas_equalTo(32);
    }];
    [_teamCollectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_avatarView.mas_bottom).offset(16);
        make.leading.trailing.equalTo(_headerView);
        make.height.mas_equalTo(80);
    }];
}

- (void)setupScrollContent {
    // 白色内容区（顶部双圆弧，按原型“查看赛事/更多”所在区域）
    self.bodyBgView = [[UIView alloc] init];
    self.bodyBgView.backgroundColor = [UIColor whiteColor];
    self.bodyBgView.layer.cornerRadius = 24;
    self.bodyBgView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    if (@available(iOS 13.0, *)) {
        self.bodyBgView.layer.cornerCurve = kCACornerCurveContinuous;
    }
    self.bodyBgView.clipsToBounds = YES;
    [self.view addSubview:self.bodyBgView];

    _scrollView = [[UIScrollView alloc] init];
    _scrollView.backgroundColor = [UIColor clearColor];
    _scrollView.showsVerticalScrollIndicator = NO;
    if (@available(iOS 11.0, *)) _scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.bodyBgView addSubview:_scrollView];
    _contentView = [[UIView alloc] init];
    _contentView.backgroundColor = [UIColor whiteColor];
    [_scrollView addSubview:_contentView];

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.text = NSLocalizedString(@"home_view_matches", nil);
    _titleLabel.font = [UIFont boldSystemFontOfSize:18];
    _titleLabel.textColor = [UIColor blackColor];
    _moreBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [_moreBtn setTitle:NSLocalizedString(@"home_more", nil) forState:UIControlStateNormal];
    [_moreBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    _moreBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [_moreBtn addTarget:self action:@selector(onMoreTapped) forControlEvents:UIControlEventTouchUpInside];
    [_contentView addSubview:_titleLabel];
    [_contentView addSubview:_moreBtn];

    _twoCardsContainer = [[UIView alloc] init];
    [_contentView addSubview:_twoCardsContainer];
    [self buildTwoCards];

    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.scrollEnabled = NO; // 让整页由外层 scrollView 滚动
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.backgroundColor = [UIColor whiteColor];
    _tableView.sectionHeaderHeight = 44;
    _tableView.sectionFooterHeight = 0.01;
    [_tableView registerClass:[MatchCell class] forCellReuseIdentifier:@"MatchCell"];
    [_contentView addSubview:_tableView];

    [self.bodyBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        // 轻微上移，让顶部圆弧露出绿底（与设计图一致）
        make.top.equalTo(_headerView.mas_bottom).offset(-18);
        make.leading.trailing.bottom.equalTo(self.view);
    }];
    [_scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.bodyBgView);
    }];
    [_contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(_scrollView);
        make.width.equalTo(_scrollView);
    }];
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_contentView).offset(20);
        make.leading.equalTo(_contentView).offset(20);
    }];
    [_moreBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_titleLabel);
        make.trailing.equalTo(_contentView).offset(-20);
    }];
    [_twoCardsContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_titleLabel.mas_bottom).offset(16);
        make.leading.equalTo(_contentView).offset(20);
        make.trailing.equalTo(_contentView).offset(-20);
        make.height.mas_equalTo(168);
    }];
    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_twoCardsContainer.mas_bottom).offset(16);
        make.leading.trailing.equalTo(_contentView);
        self.tableHeightConstraint = make.height.mas_equalTo(0); // 实际高度后面根据 contentSize 更新
        make.bottom.equalTo(_contentView).offset(-24);
    }];

    // 初次布局根据当前数据刷新列表高度
    [_tableView reloadData];
    [self updateTableHeight];
}

- (void)updateTableHeight {
    if (!_tableView || !_filteredData.count) return;
    // 不依赖 contentSize（scrollEnabled=NO 时可能不准确），按分组与行数手动算高
    NSArray *dates = [self sortedDates];
    CGFloat headerH = 44.f, footerH = 0.01f, rowH = 88.f;
    CGFloat total = 0;
    for (NSString *date in dates) {
        NSPredicate *p = [NSPredicate predicateWithFormat:@"date == %@", date];
        NSInteger rows = [[_filteredData filteredArrayUsingPredicate:p] count];
        total += headerH + footerH + rows * rowH;
    }
    if (total <= 0) return;
    self.tableHeightConstraint.offset = total;
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

- (void)updateLocalizedStrings {
    [super updateLocalizedStrings];
    _challengerLabel.text = NSLocalizedString(@"home_challenger", nil);
    _titleLabel.text = NSLocalizedString(@"home_view_matches", nil);
    [_moreBtn setTitle:NSLocalizedString(@"home_more", nil) forState:UIControlStateNormal];
    [self buildTeams];
    [_teamCollectionView reloadData];
}

- (void)buildTwoCards {
    for (UIView *v in _twoCardsContainer.subviews) [v removeFromSuperview];
    // 左卡：深青绿（与顶栏一致），已结束显示比分；右卡：更深绿，未开始无比分
    UIView *left = [self cardWithModel:_highlightFinished bg:kHeaderGreen textColor:[UIColor whiteColor] showScore:YES];
    UIView *right = [self cardWithModel:_highlightUpcoming bg:kCardDarkerGreen textColor:[UIColor whiteColor] showScore:NO];
    [_twoCardsContainer addSubview:left];
    [_twoCardsContainer addSubview:right];
    [left mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.bottom.equalTo(_twoCardsContainer);
    }];
    [right mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.top.bottom.equalTo(_twoCardsContainer);
        make.leading.equalTo(left.mas_trailing).offset(12);
        make.width.equalTo(left);
    }];
}

- (UIView *)cardWithModel:(MatchModel *)m bg:(UIColor *)bg textColor:(UIColor *)textColor showScore:(BOOL)showScore {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = bg;
    // 原型：大圆角 + 连续曲线
    card.layer.cornerRadius = 18;
    if (@available(iOS 13.0, *)) {
        card.layer.cornerCurve = kCACornerCurveContinuous;
    }
    card.clipsToBounds = YES;
    UILabel *timeL = [[UILabel alloc] init];
    // Fri/11:00 pm：优先从 dateDetail 里取星期缩写
    NSString *weekday = @"";
    if ([m.dateDetail containsString:@","]) {
        weekday = [[m.dateDetail componentsSeparatedByString:@","] firstObject] ?: @"";
    }
    weekday = [weekday stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (weekday.length == 0) weekday = @"Fri";
    NSString *t = m.time.length ? m.time : @"11:00 pm";
    timeL.text = [NSString stringWithFormat:@"%@/%@", weekday, t];
    timeL.font = [UIFont boldSystemFontOfSize:13];
    timeL.textColor = textColor;
    UILabel *dateL = [[UILabel alloc] init];
    dateL.text = m.dateDetail;
    dateL.font = [UIFont systemFontOfSize:11];
    dateL.textColor = [textColor colorWithAlphaComponent:0.9];
    UIImageView *homeIcon = [[UIImageView alloc] init];
    homeIcon.contentMode = UIViewContentModeScaleAspectFit;
    homeIcon.backgroundColor = [UIColor colorWithRed:0.7 green:0.2 blue:0.2 alpha:1.0];
    homeIcon.layer.cornerRadius = 11;
    homeIcon.clipsToBounds = YES;
    UIImageView *awayIcon = [[UIImageView alloc] init];
    awayIcon.contentMode = UIViewContentModeScaleAspectFit;
    awayIcon.backgroundColor = [UIColor colorWithRed:0.7 green:0.2 blue:0.2 alpha:1.0];
    awayIcon.layer.cornerRadius = 11;
    awayIcon.clipsToBounds = YES;
    UIImage *placeImg = [UIImage imageNamed:kLogoPlaceholder];
    if (placeImg) { homeIcon.image = placeImg; awayIcon.image = placeImg; }
    NSArray *scoreParts = [m.score componentsSeparatedByString:@" : "];
    NSString *homeScore = scoreParts.count > 0 ? [scoreParts[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] : @"";
    NSString *awayScore = scoreParts.count > 1 ? [scoreParts[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] : @"";
    UILabel *homeL = [[UILabel alloc] init];
    homeL.text = showScore && homeScore.length ? [NSString stringWithFormat:@"%@ %@", m.homeTeam, homeScore] : m.homeTeam;
    homeL.font = [UIFont systemFontOfSize:12];
    homeL.textColor = textColor;
    UILabel *awayL = [[UILabel alloc] init];
    awayL.text = showScore && awayScore.length ? [NSString stringWithFormat:@"%@ %@", m.awayTeam, awayScore] : m.awayTeam;
    awayL.font = [UIFont systemFontOfSize:12];
    awayL.textColor = textColor;
    [card addSubview:timeL];
    [card addSubview:dateL];
    [card addSubview:homeIcon];
    [card addSubview:homeL];
    [card addSubview:awayIcon];
    [card addSubview:awayL];
    CGFloat pad = 16;
    [timeL mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(card).offset(14);
        make.leading.equalTo(card).offset(pad);
    }];
    [dateL mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(timeL.mas_bottom).offset(4);
        make.leading.equalTo(card).offset(pad);
    }];

    // 底部两行球队：与原型一致的留白与行距
    [awayIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(card).offset(pad);
        make.bottom.equalTo(card).offset(-16);
        make.width.height.mas_equalTo(22);
    }];
    [awayL mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(awayIcon.mas_trailing).offset(8);
        make.centerY.equalTo(awayIcon);
        make.trailing.lessThanOrEqualTo(card).offset(-12);
    }];

    [homeIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(card).offset(pad);
        make.bottom.equalTo(awayIcon.mas_top).offset(-10);
        make.width.height.mas_equalTo(22);
    }];
    [homeL mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(homeIcon.mas_trailing).offset(8);
        make.centerY.equalTo(homeIcon);
        make.trailing.lessThanOrEqualTo(card).offset(-12);
    }];
    return card;
}

- (void)setupRefresh {
    RefreshPagHeader *header = [RefreshPagHeader headerWithRefreshingTarget:self refreshingAction:@selector(refreshData)];
    [header prepare];
    _scrollView.mj_header = header;
}

- (void)refreshData {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.scrollView.mj_header endRefreshing];
    });
}
- (void)fetchUserProfile {
    [UserRequest.shared getLoginUserInfoSuccess:^(HTTPResponse <User *>* _Nullable responseObject) {
        [self refreshUserProfile];
    } failure:^(NSError * _Nonnull error) {
    }];
}
- (void)fetchFollowTeams {
    [TeamsRequest.shared getFollowTeamIconsSuccess:^(HTTPResponse <NSArray <TeamIcon *> *>* _Nullable responseObject) {
        self.teamItems = responseObject.dataObject;
        [self.teamCollectionView reloadData];
    } failure:^(NSError * _Nonnull error) {
        
    }];
}
- (void)refreshUserProfile {
    [_avatarView sd_setImageWithURL:[NSURL URLWithString:AuthManager.sharedManager.user.profile.avatar]];
    _challengerLabel.text = AuthManager.sharedManager.user.profile.nickname;
    _dateLabel.text = AuthManager.sharedManager.user.profile.birthDate;
}
#pragma mark - UICollectionView
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _teamItems.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HomeTeamCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TeamCell" forIndexPath:indexPath];
    HomeTeamItem *item = _teamItems[indexPath.item];
    cell.nameLabel.text = item.name;
    cell.logoView.image = [UIImage imageNamed:kLogoPlaceholder];
    if (!cell.logoView.image) cell.logoView.backgroundColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    BOOL sel = (item.teamId == nil && _selectedTeamId == nil) || (item.teamId && [_selectedTeamId isEqualToString:item.teamId]);
    cell.selected = sel;
    return cell;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(72, 80);
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    HomeTeamItem *item = _teamItems[indexPath.item];
    _selectedTeamId = item.teamId; // nil 表示全部
    [collectionView reloadData];
    [self filterData];
}

#pragma mark - UITableView（按日期倒序、分组）
- (NSArray *)sortedDates {
    NSArray *dates = [_filteredData valueForKey:@"date"];
    NSArray *unique = [[NSSet setWithArray:dates] allObjects];
    return [unique sortedArrayUsingComparator:^NSComparisonResult(NSString *a, NSString *b) {
        return [b compare:a];
    }];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self sortedDates].count;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *date = [self sortedDates][section];
    NSPredicate *p = [NSPredicate predicateWithFormat:@"date == %@", date];
    return [[_filteredData filteredArrayUsingPredicate:p] count];
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *v = [[UIView alloc] init];
    v.backgroundColor = [UIColor whiteColor];
    UIImageView *cal = [[UIImageView alloc] init];
    if (@available(iOS 13.0, *)) {
        cal.image = [UIImage systemImageNamed:@"calendar"];
        cal.tintColor = [UIColor darkGrayColor];
    }
    cal.contentMode = UIViewContentModeScaleAspectFit;
    [v addSubview:cal];
    UILabel *lab = [[UILabel alloc] init];
    lab.text = [self sortedDates][section];
    lab.font = [UIFont boldSystemFontOfSize:15];
    lab.textColor = [UIColor blackColor];
    [v addSubview:lab];
    [cal mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(v).offset(20);
        make.centerY.equalTo(v);
        make.width.height.mas_equalTo(20);
    }];
    [lab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(cal.mas_trailing).offset(8);
        make.centerY.equalTo(v);
    }];
    return v;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 88;
}
- (MatchModel *)modelAtIndexPath:(NSIndexPath *)indexPath {
    NSString *date = [self sortedDates][indexPath.section];
    NSPredicate *p = [NSPredicate predicateWithFormat:@"date == %@", date];
    NSArray *arr = [_filteredData filteredArrayUsingPredicate:p];
    return arr[indexPath.row];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MatchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MatchCell"];
    MatchModel *m = [self modelAtIndexPath:indexPath];
    cell.homeLabel.text = m.homeTeam;
    cell.awayLabel.text = m.awayTeam;
    cell.dateLabel.text = m.dateDetail;
    [cell.timePill setTitle:m.time forState:UIControlStateNormal];
    cell.centerLabel.text = m.finished ? m.score : m.time;
    UIImage *img = [UIImage imageNamed:kLogoPlaceholder];
    cell.homeLogo.image = img ?: nil;
    cell.awayLogo.image = img ?: nil;
    if (!img) {
        cell.homeLogo.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1.0];
        cell.awayLogo.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1.0];
    }
    return cell;
}

@end
