//
//  HomeViewController.m
//  footBall
//

#import "HomeViewController.h"
#import "MoreMatchesViewController.h"
#import "RefreshPagHeader.h"
#import <Masonry/Masonry.h>
#import "ColorManager.h"

#define kHeaderGreen [UIColor colorWithRed:0.05 green:0.13 blue:0.13 alpha:1.0]
#define kCardDarkerGreen [UIColor colorWithRed:0.17 green:0.42 blue:0.34 alpha:1.0]
#define kCardLightGray [UIColor colorWithRed:0.96 green:0.96 blue:0.96 alpha:1.0]
#define kScoreOvalBg [UIColor clearColor]
#define kTimePillGreen [UIColor colorWithRed:0.94 green:0.97 blue:0.93 alpha:1.0]
static NSString *const kLogoPlaceholder = @"team_placeholder";

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
        _circleView.layer.cornerRadius = 25;
        _circleView.clipsToBounds = YES;
        _logoView = [[UIImageView alloc] init];
        _logoView.contentMode = UIViewContentModeScaleAspectFit;
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont systemFontOfSize:11];
        _nameLabel.textColor = [UIColor colorWithWhite:0.85 alpha:1.0];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        _nameLabel.numberOfLines = 1;
        [self.contentView addSubview:_circleView];
        [_circleView addSubview:_logoView];
        [self.contentView addSubview:_nameLabel];
        [_circleView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.centerX.equalTo(self.contentView);
            make.width.height.mas_equalTo(50);
        }];
        [_logoView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(_circleView);
            make.width.height.mas_equalTo(28);
        }];
        [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_circleView.mas_bottom).offset(8);
            make.leading.trailing.equalTo(self.contentView);
        }];
    }
    return self;
}
- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    _circleView.backgroundColor = selected ? [UIColor whiteColor] : [UIColor colorWithWhite:0.17 alpha:1.0];
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
        self.backgroundColor = kCardLightGray;
        UIView *card = [[UIView alloc] init];
        card.backgroundColor = [UIColor colorWithWhite:0.91 alpha:1.0];
        card.layer.cornerRadius = 8;
        [self.contentView addSubview:card];
        [card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(6, 16, 6, 16));
        }];
        _dateLabel = [[UILabel alloc] init];
        _dateLabel.font = [UIFont systemFontOfSize:11];
        _dateLabel.textColor = [UIColor colorWithWhite:0.47 alpha:1.0];
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
        _homeLabel.font = _awayLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
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
            make.leading.equalTo(card).offset(24);
            make.centerY.equalTo(card).offset(-13);
            make.width.height.mas_equalTo(24);
        }];
        [_homeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_homeLogo.mas_trailing).offset(10);
            make.centerY.equalTo(_homeLogo);
        }];
        [_dateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_homeLabel);
            make.top.equalTo(_homeLabel.mas_bottom).offset(14);
        }];
        [scoreOval mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(card);
            make.centerY.equalTo(card).offset(-13);
        }];
        [_timePill mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(card);
            make.top.equalTo(scoreOval.mas_bottom).offset(14);
            make.height.mas_equalTo(24);
            make.width.mas_greaterThanOrEqualTo(56);
        }];
        [_awayLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(_awayLogo.mas_leading).offset(-10);
            make.centerY.equalTo(_homeLogo);
        }];
        [_awayLogo mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(_playBtn.mas_leading).offset(-12);
            make.centerY.equalTo(card).offset(-13);
            make.width.height.mas_equalTo(24);
        }];
        [_bookmarkBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(card).offset(-16);
            make.bottom.equalTo(card).offset(-12);
            make.width.height.mas_equalTo(20);
        }];
        [_playBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(_bookmarkBtn.mas_leading).offset(-8);
            make.centerY.equalTo(_bookmarkBtn);
            make.width.height.mas_equalTo(20);
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

@property (nonatomic, strong) NSMutableArray<Match *> *dataSource;
@property (nonatomic, strong) NSMutableArray<Match *> *filteredData;
@property (nonatomic, strong) Match *highlightFinished;
@property (nonatomic, strong) Match *highlightUpcoming;

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
    self.view.backgroundColor = kCardLightGray;
    self.shouldShowNavigationBar = NO;
    [self buildTeams];
    self.dataSource = NSMutableArray.array;
    self.filteredData = NSMutableArray.array;
    self.selectedTeamId = nil;
    [self filterData];
    [self setupUI];
    [self setupRefresh];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self fetchUserProfile];
    [self fetchFollowTeams];
    [self fetchFeatureMatchs];
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

- (void)filterData {
    if (!_selectedTeamId.length) {
        _filteredData = [_dataSource mutableCopy];
    } else {
        NSMutableArray *arr = [NSMutableArray array];
        for (Match *m in _dataSource) {
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
    _avatarView.layer.cornerRadius = 20;
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
    _dateLabel.font = [UIFont systemFontOfSize:12];
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
        make.height.mas_equalTo(241);
    }];
    [_avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_headerView.mas_safeAreaLayoutGuideTop).offset(12);
        make.leading.equalTo(_headerView).offset(16);
        make.width.height.mas_equalTo(40);
    }];
    [_challengerLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(_avatarView.mas_trailing).offset(10);
        make.centerY.equalTo(_avatarView).offset(-7);
    }];
    [_dateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(_challengerLabel);
        make.top.equalTo(_challengerLabel.mas_bottom).offset(1);
    }];
    [_heartBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(_headerView).offset(-16);
        make.centerY.equalTo(_avatarView);
        make.width.height.mas_equalTo(32);
    }];
    [_teamCollectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_avatarView.mas_bottom).offset(24);
        make.leading.trailing.equalTo(_headerView);
        make.height.mas_equalTo(80);
    }];
}

- (void)setupScrollContent {
    // 白色内容区（顶部双圆弧，按原型“查看赛事/更多”所在区域）
    self.bodyBgView = [[UIView alloc] init];
    self.bodyBgView.backgroundColor = kCardLightGray;
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
    _contentView.backgroundColor = kCardLightGray;
    [_scrollView addSubview:_contentView];

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.text = NSLocalizedString(@"home_view_matches", nil);
    _titleLabel.font = [UIFont boldSystemFontOfSize:16];
    _titleLabel.textColor = [UIColor blackColor];
    _moreBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [_moreBtn setTitle:NSLocalizedString(@"home_more", nil) forState:UIControlStateNormal];
    [_moreBtn setTitleColor:[UIColor colorWithWhite:0.47 alpha:1.0] forState:UIControlStateNormal];
    _moreBtn.titleLabel.font = [UIFont systemFontOfSize:12];
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
    _tableView.backgroundColor = kCardLightGray;
    _tableView.sectionHeaderHeight = 44;
    _tableView.sectionFooterHeight = 0.01;
    [_tableView registerClass:[MatchCell class] forCellReuseIdentifier:@"MatchCell"];
    [_contentView addSubview:_tableView];

    [self.bodyBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        // 轻微上移，让顶部圆弧露出绿底（与设计图一致）
        make.top.equalTo(self.view).offset(214);
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
        make.leading.equalTo(_contentView).offset(16);
    }];
    [_moreBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_titleLabel);
        make.trailing.equalTo(_contentView).offset(-16);
    }];
    [_twoCardsContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_titleLabel.mas_bottom).offset(16);
        make.leading.equalTo(_contentView).offset(15);
        make.trailing.equalTo(_contentView).offset(-15);
        make.height.mas_equalTo(198);
    }];
    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_twoCardsContainer.mas_bottom).offset(10);
        make.leading.trailing.equalTo(_contentView);
        self.tableHeightConstraint = make.height.mas_equalTo(0); // 实际高度后面根据 contentSize 更新
        make.bottom.equalTo(_contentView).offset(-12);
    }];

    // 初次布局根据当前数据刷新列表高度
    [_tableView reloadData];
    [self updateTableHeight];
}

- (void)updateTableHeight {
    if (!_tableView || !_filteredData.count) return;
    // 不依赖 contentSize（scrollEnabled=NO 时可能不准确），按分组与行数手动算高
    NSArray *dates = [self sortedDates];
    CGFloat headerH = 40.f, footerH = 0.01f, rowH = 103.f;
    CGFloat total = 0;
    for (NSString *date in dates) {
        NSPredicate *p = [NSPredicate predicateWithBlock:^BOOL(Match *evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
            return [[self monthTextFromRaw:evaluatedObject.matchDate] isEqualToString:date];
        }];
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
    // 左右两张精选卡
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

- (UIView *)cardWithModel:(Match *)m bg:(UIColor *)bg textColor:(UIColor *)textColor showScore:(BOOL)showScore {
    if (!m) {
        m = Match.new;
        m.homeTeamName = @"-";
        m.awayTeamName = @"-";
        m.matchDate = @"";
        m.homeScore = 0;
        m.awayScore = 0;
    }
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = bg;
    // 原型：大圆角 + 连续曲线
    card.layer.cornerRadius = 24;
    if (@available(iOS 13.0, *)) {
        card.layer.cornerCurve = kCACornerCurveContinuous;
    }
    card.clipsToBounds = YES;
    UILabel *timeL = [[UILabel alloc] init];
    // Fri/11:00 pm：优先从 dateDetail 里取星期缩写
    NSString *weekday = @"";
    NSString *detailText = [self dateDetailFromRaw:m.matchDate];
    if ([detailText containsString:@","]) {
        weekday = [[detailText componentsSeparatedByString:@","] firstObject] ?: @"";
    }
    weekday = [weekday stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (weekday.length == 0) weekday = @"Fri";
    NSString *t = [self timeTextFromRaw:m.matchDate];
    timeL.text = [NSString stringWithFormat:@"%@/%@", weekday, t];
    timeL.font = [UIFont systemFontOfSize:28 weight:UIFontWeightSemibold];
    timeL.textColor = textColor;
    UILabel *dateL = [[UILabel alloc] init];
    dateL.text = detailText;
    dateL.font = [UIFont systemFontOfSize:11];
    dateL.textColor = [textColor colorWithAlphaComponent:0.9];
    UIImageView *homeIcon = [[UIImageView alloc] init];
    homeIcon.contentMode = UIViewContentModeScaleAspectFit;
    homeIcon.backgroundColor = [UIColor colorWithRed:0.7 green:0.2 blue:0.2 alpha:1.0];
    homeIcon.layer.cornerRadius = 12;
    homeIcon.clipsToBounds = YES;
    UIImageView *awayIcon = [[UIImageView alloc] init];
    awayIcon.contentMode = UIViewContentModeScaleAspectFit;
    awayIcon.backgroundColor = [UIColor colorWithRed:0.7 green:0.2 blue:0.2 alpha:1.0];
    awayIcon.layer.cornerRadius = 12;
    awayIcon.clipsToBounds = YES;
    UIImage *placeImg = [UIImage imageNamed:kLogoPlaceholder];
    if (placeImg) { homeIcon.image = placeImg; awayIcon.image = placeImg; }
    NSString *homeScore = [NSString stringWithFormat:@"%ld", (long)m.homeScore];
    NSString *awayScore = [NSString stringWithFormat:@"%ld", (long)m.awayScore];
    UILabel *homeL = [[UILabel alloc] init];
    homeL.text = m.homeTeamName;
    homeL.font = [UIFont systemFontOfSize:22 weight:UIFontWeightSemibold];
    homeL.textColor = textColor;
    UILabel *awayL = [[UILabel alloc] init];
    awayL.text = m.awayTeamName;
    awayL.font = [UIFont systemFontOfSize:22 weight:UIFontWeightSemibold];
    awayL.textColor = textColor;
    [card addSubview:timeL];
    [card addSubview:dateL];
    [card addSubview:homeIcon];
    [card addSubview:homeL];
    [card addSubview:awayIcon];
    [card addSubview:awayL];
    CGFloat pad = 16;
    [timeL mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(card).offset(18);
        make.leading.equalTo(card).offset(pad);
    }];
    [dateL mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(timeL.mas_bottom).offset(4);
        make.leading.equalTo(card).offset(pad);
    }];

    // 底部两行球队：与原型一致的留白与行距
    [awayIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(card).offset(pad);
        make.bottom.equalTo(card).offset(-20);
        make.width.height.mas_equalTo(24);
    }];
    [awayL mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(awayIcon.mas_trailing).offset(6);
        make.centerY.equalTo(awayIcon);
        make.trailing.lessThanOrEqualTo(card).offset(-58);
    }];

    [homeIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(card).offset(pad);
        make.bottom.equalTo(awayIcon.mas_top).offset(-10);
        make.width.height.mas_equalTo(24);
    }];
    [homeL mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(homeIcon.mas_trailing).offset(6);
        make.centerY.equalTo(homeIcon);
        make.trailing.lessThanOrEqualTo(card).offset(-58);
    }];
    if (showScore) {
        UILabel *homeScoreL = [[UILabel alloc] init];
        homeScoreL.text = homeScore.length ? homeScore : @"0";
        homeScoreL.textColor = textColor;
        homeScoreL.font = [UIFont fontWithName:@"BebasNeue-Regular" size:30] ?: [UIFont systemFontOfSize:30 weight:UIFontWeightSemibold];
        UILabel *awayScoreL = [[UILabel alloc] init];
        awayScoreL.text = awayScore.length ? awayScore : @"0";
        awayScoreL.textColor = textColor;
        awayScoreL.font = [UIFont fontWithName:@"BebasNeue-Regular" size:30] ?: [UIFont systemFontOfSize:30 weight:UIFontWeightSemibold];
        [card addSubview:homeScoreL];
        [card addSubview:awayScoreL];
        [homeScoreL mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(card).offset(-16);
            make.centerY.equalTo(homeIcon);
        }];
        [awayScoreL mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(card).offset(-16);
            make.centerY.equalTo(awayIcon);
        }];
    }
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
- (void)fetchFeatureMatchs {
    [MatchRequest.shared getFeaturesMatchsSuccess:^(HTTPResponse <NSArray <Match*> *>* _Nullable responseObject) {
        NSArray<Match *> *list = [responseObject.dataObject isKindOfClass:NSArray.class] ? responseObject.dataObject : @[];
        self.dataSource = list.mutableCopy;
        self.filteredData = list.mutableCopy;
        Match *firstFinished = nil;
        Match *firstUpcoming = nil;
        for (Match *m in list) {
            BOOL finished = [m.matchStatus isEqualToString:@"FINISHED"];
            if (finished && !firstFinished) firstFinished = m;
            if (!finished && !firstUpcoming) firstUpcoming = m;
            if (firstFinished && firstUpcoming) break;
        }
        self.highlightFinished = firstFinished ?: list.firstObject;
        self.highlightUpcoming = firstUpcoming ?: list.firstObject;
        [self buildTwoCards];
        [self filterData];
        [self updateTableHeight];
    } failure:^(NSError * _Nonnull error) {
        self.dataSource = NSMutableArray.array;
        self.filteredData = NSMutableArray.array;
        [self.tableView reloadData];
    }];
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

- (NSDate *)dateFromRaw:(NSString *)raw {
    if (raw.length == 0) return nil;
    NSDateFormatter *fmt = NSDateFormatter.new;
    fmt.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    fmt.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
    NSDate *date = [fmt dateFromString:raw];
    if (!date) {
        fmt.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        date = [fmt dateFromString:raw];
    }
    return date;
}

- (NSString *)monthTextFromRaw:(NSString *)raw {
    NSDate *date = [self dateFromRaw:raw];
    if (!date) return @"-";
    NSDateFormatter *fmt = NSDateFormatter.new;
    fmt.dateFormat = @"yyyy-MM";
    return [fmt stringFromDate:date];
}

- (NSString *)timeTextFromRaw:(NSString *)raw {
    NSDate *date = [self dateFromRaw:raw];
    if (!date) return @"--:--";
    NSDateFormatter *fmt = NSDateFormatter.new;
    fmt.dateFormat = @"HH:mm";
    return [fmt stringFromDate:date];
}

- (NSString *)dateDetailFromRaw:(NSString *)raw {
    NSDate *date = [self dateFromRaw:raw];
    if (!date) return @"--";
    NSDateFormatter *fmt = NSDateFormatter.new;
    fmt.dateFormat = @"dd MMM, yyyy";
    return [fmt stringFromDate:date];
}

#pragma mark - UICollectionView
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _teamItems.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HomeTeamCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TeamCell" forIndexPath:indexPath];
    TeamIcon *item = _teamItems[indexPath.item];
    cell.nameLabel.text = item.name;
    [cell.logoView sd_setImageWithURL:[NSURL URLWithString:item.logo] placeholderImage:[UIImage imageNamed:kLogoPlaceholder]];
    if (!cell.logoView.image) cell.logoView.backgroundColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    BOOL sel = (item.teamId == nil && _selectedTeamId == nil) || (item.teamId && [_selectedTeamId isEqualToString:item.teamId]);
    cell.selected = sel;
    return cell;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(60, 80);
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    TeamIcon *item = _teamItems[indexPath.item];
    _selectedTeamId = item.teamId; // nil 表示全部
    [collectionView reloadData];
    [self filterData];
}

#pragma mark - UITableView（按日期倒序、分组）
- (NSArray *)sortedDates {
    NSMutableArray *dates = NSMutableArray.array;
    for (Match *m in _filteredData) {
        [dates addObject:[self monthTextFromRaw:m.matchDate]];
    }
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
    NSPredicate *p = [NSPredicate predicateWithBlock:^BOOL(Match *evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [[self monthTextFromRaw:evaluatedObject.matchDate] isEqualToString:date];
    }];
    return [[_filteredData filteredArrayUsingPredicate:p] count];
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *v = [[UIView alloc] init];
    v.backgroundColor = kCardLightGray;
    UIImageView *cal = [[UIImageView alloc] init];
    if (@available(iOS 13.0, *)) {
        cal.image = [UIImage systemImageNamed:@"calendar"];
        cal.tintColor = [UIColor darkGrayColor];
    }
    cal.contentMode = UIViewContentModeScaleAspectFit;
    [v addSubview:cal];
    UILabel *lab = [[UILabel alloc] init];
    lab.text = [self sortedDates][section];
    lab.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    lab.textColor = [UIColor blackColor];
    [v addSubview:lab];
    [cal mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(v).offset(16);
        make.centerY.equalTo(v);
        make.width.height.mas_equalTo(24);
    }];
    [lab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(cal.mas_trailing).offset(5);
        make.centerY.equalTo(v);
    }];
    return v;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 103;
}
- (Match *)modelAtIndexPath:(NSIndexPath *)indexPath {
    NSString *date = [self sortedDates][indexPath.section];
    NSPredicate *p = [NSPredicate predicateWithBlock:^BOOL(Match *evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [[self monthTextFromRaw:evaluatedObject.matchDate] isEqualToString:date];
    }];
    NSArray *arr = [_filteredData filteredArrayUsingPredicate:p];
    return arr[indexPath.row];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MatchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MatchCell"];
    Match *m = [self modelAtIndexPath:indexPath];
    cell.homeLabel.text = m.homeTeamName;
    cell.awayLabel.text = m.awayTeamName;
    cell.dateLabel.text = [self dateDetailFromRaw:m.matchDate];
    [cell.timePill setTitle:[self timeTextFromRaw:m.matchDate] forState:UIControlStateNormal];
    BOOL finished = [m.matchStatus isEqualToString:@"FINISHED"];
    cell.centerLabel.text = finished ? [NSString stringWithFormat:@"%ld : %ld", (long)m.homeScore, (long)m.awayScore] : [self timeTextFromRaw:m.matchDate];
    [cell.homeLogo sd_setImageWithURL:[NSURL URLWithString:m.homeTeamLogo] placeholderImage:[UIImage imageNamed:kLogoPlaceholder]];
    [cell.awayLogo sd_setImageWithURL:[NSURL URLWithString:m.awayTeamLogo] placeholderImage:[UIImage imageNamed:kLogoPlaceholder]];
    UIImage *img = [UIImage imageNamed:kLogoPlaceholder];
    if (!img) {
        cell.homeLogo.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1.0];
        cell.awayLogo.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1.0];
    }
    return cell;
}

@end
