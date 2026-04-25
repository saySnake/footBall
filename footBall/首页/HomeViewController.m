//
//  HomeViewController.m
//  footBall
//

#import "HomeViewController.h"
#import "MoreMatchesViewController.h"
#import "RefreshPagHeader.h"
#import <Masonry/Masonry.h>
#import "ColorManager.h"
#import "MatchRequest.h"
#import "APIError.h"
#import <QMUIKit/QMUITips.h>
#import <SDWebImage/SDWebImage.h>

#define kHeaderGreen [UIColor colorWithRed:0.05 green:0.13 blue:0.13 alpha:1.0]
#define kCardDarkerGreen [UIColor colorWithRed:0.17 green:0.42 blue:0.34 alpha:1.0]
#define kCardLightGray [UIColor colorWithRed:0.96 green:0.96 blue:0.96 alpha:1.0]
#define kHomeContentBg [UIColor whiteColor]
/// Figma 1:9843 赛程列表卡片：#F4F4F4
#define kHomeMatchCardBg [UIColor colorWithRed:0.957 green:0.957 blue:0.957 alpha:1.0]
#define kHomeMatchGreen [UIColor colorWithRed:0.157 green:0.365 blue:0.294 alpha:1.0]
#define kHomeTeamBadgeBg [UIColor colorWithRed:0.965 green:0.973 blue:0.996 alpha:1.0]
#define kHomeMetaIconColor [UIColor colorWithRed:0.114 green:0.114 blue:0.114 alpha:1.0]
static NSString *const kLogoPlaceholder = @"team_placeholder";
static CGFloat const kHomeFeaturedCardH = 168.f;
static CGFloat const kHomeFeaturedCardGap = 12.f;
static CGFloat const kHomeFeaturedCardPad = 16.f;
static CGFloat const kHomeFeaturedBadgeSize = 24.f;
static CGFloat const kHomeFeaturedCardCorner = 24.f;

/// 与「更多比赛」一致：收藏用 match_star
static UIImage *kHomeFavoriteIcon(BOOL favorited) {
    UIImage *asset = [UIImage imageNamed:@"match_star"];
    if (asset) {
        if (favorited) {
            return [asset imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        }
        return [asset imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightRegular];
        NSString *iconName = favorited ? @"star.fill" : @"star";
        return [UIImage systemImageNamed:iconName withConfiguration:cfg];
    }
    return nil;
}

static NSString *kHomeFeaturedTeamDisplayName(NSString *name) {
    NSString *trimmed = [[name ?: @"" stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] copy];
    if (trimmed.length == 0) return @"-";
    return trimmed;
}

/// 关注球队、赛程里的 teamId 可能为数字或字符串，统一成字符串再比较/存储
static NSString *kHomeTeamIdString(id raw) {
    if (raw == nil || raw == (id)kCFNull) return @"";
    if ([raw isKindOfClass:NSString.class]) {
        return [(NSString *)raw copy] ?: @"";
    }
    if ([raw isKindOfClass:NSNumber.class]) {
        return [(NSNumber *)raw stringValue];
    }
    return [raw description] ?: @"";
}

#pragma mark - 顶部球队 Cell
@interface HomeTeamCell : UICollectionViewCell
@property (nonatomic, strong) UIView *circleView;
@property (nonatomic, strong) UIImageView *logoView;
@property (nonatomic, strong) UILabel *nameLabel;
/// 在 cellForItem 中写入的选中态。UICollectionView 布局会在 -applyLayoutAttributes: 里用 layoutAttributes.selected 再调 -setSelected:，
/// 若未使用 selectItemAtIndexPath:，一般为 NO，会覆盖在 cell 里手写的 setSelected:YES，导致白底被刷回深灰。
@property (nonatomic, assign) BOOL homeTeamStyleSelected;
- (void)applyHomeTeamSelectionAppearance;
@end
@implementation HomeTeamCell
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = NO;
        self.contentView.clipsToBounds = NO;

        _circleView = [[UIView alloc] init];
        _circleView.layer.cornerRadius = 28;
        _circleView.clipsToBounds = YES; // 裁剪子视图（logoView），border 画在 layer 内部不受影响
        _circleView.backgroundColor = [UIColor colorWithWhite:0.17 alpha:1.0];

        _logoView = [[UIImageView alloc] init];
        _logoView.layer.cornerRadius = 14;
        _logoView.clipsToBounds = YES;
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
            make.width.height.mas_equalTo(56);
        }];
        [_logoView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(_circleView);
            make.width.height.mas_equalTo(28);
        }];
        [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_circleView.mas_bottom).offset(5);
            make.leading.trailing.equalTo(self.contentView);
        }];
    }
    return self;
}
- (void)applyHomeTeamSelectionAppearance {
    if (self.homeTeamStyleSelected) {
        _circleView.backgroundColor = [UIColor whiteColor];
        _circleView.layer.borderWidth = 0;
        _circleView.layer.borderColor = [UIColor clearColor].CGColor;
        _nameLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
        _nameLabel.textColor = [UIColor whiteColor];
    } else {
        _circleView.backgroundColor = [UIColor colorWithWhite:0.17 alpha:1.0];
        _circleView.layer.borderWidth = 0;
        _circleView.layer.borderColor = [UIColor clearColor].CGColor;
        _nameLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightRegular];
        _nameLabel.textColor = [UIColor colorWithWhite:0.85 alpha:1.0];
    }
}
- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    [self applyHomeTeamSelectionAppearance];
}
- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
    [super applyLayoutAttributes:layoutAttributes];
    [self applyHomeTeamSelectionAppearance];
}
- (void)prepareForReuse {
    [super prepareForReuse];
    _homeTeamStyleSelected = NO;
    [self applyHomeTeamSelectionAppearance];
}
@end

#pragma mark - 赛程卡片 Cell（日期下 — 队名+队徽 / 比分 / 队徽+队名；底行日期 + 时间胶囊 + 播放 + match_star）

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
        self.backgroundColor = [UIColor clearColor];
        self.contentView.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
        UIView *card = [[UIView alloc] init];
        card.backgroundColor = kHomeMatchCardBg;
        card.layer.cornerRadius = 8;
        card.clipsToBounds = YES;
        // 体育赛程固定「主队左、客队右」，避免在 RTL 语言环境下 leading/trailing 镜像后主队跑到右侧
        card.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
        [self.contentView addSubview:card];
        [card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(6, 16, 6, 16));
        }];

        UIView *homeBadge = [[UIView alloc] init];
        homeBadge.backgroundColor = kHomeTeamBadgeBg;
        homeBadge.layer.cornerRadius = 16;
        homeBadge.clipsToBounds = YES;
        UIView *awayBadge = [[UIView alloc] init];
        awayBadge.backgroundColor = kHomeTeamBadgeBg;
        awayBadge.layer.cornerRadius = 16;
        awayBadge.clipsToBounds = YES;

        _homeLogo = [[UIImageView alloc] init];
        _awayLogo = [[UIImageView alloc] init];
        _homeLogo.contentMode = _awayLogo.contentMode = UIViewContentModeScaleAspectFit;
        _homeLogo.backgroundColor = [UIColor clearColor];
        _homeLogo.layer.cornerRadius = 9;
        _awayLogo.backgroundColor = [UIColor clearColor];
        _awayLogo.layer.cornerRadius = 9;

        _homeLabel = [[UILabel alloc] init];
        _awayLabel = [[UILabel alloc] init];
        _homeLabel.font = _awayLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
        _homeLabel.textColor = _awayLabel.textColor = [UIColor blackColor];
        _homeLabel.textAlignment = NSTextAlignmentRight;
        _awayLabel.textAlignment = NSTextAlignmentLeft;
        _homeLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _awayLabel.lineBreakMode = NSLineBreakByTruncatingTail;

        _centerLabel = [[UILabel alloc] init];
        _centerLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
        _centerLabel.textAlignment = NSTextAlignmentCenter;
        _centerLabel.textColor = [UIColor blackColor];

        _dateLabel = [[UILabel alloc] init];
        _dateLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        _dateLabel.textColor = [UIColor colorWithRed:0.471 green:0.471 blue:0.471 alpha:1.0];

        _timePill = [UIButton buttonWithType:UIButtonTypeCustom];
        _timePill.userInteractionEnabled = NO;
        _timePill.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        [_timePill setTitleColor:kHomeMatchGreen forState:UIControlStateNormal];
        _timePill.backgroundColor = [UIColor colorWithRed:0.973 green:0.980 blue:0.969 alpha:1.0];
        _timePill.layer.cornerRadius = 12;
        _timePill.layer.borderWidth = 0.5;
        _timePill.layer.borderColor = kHomeMatchGreen.CGColor;
        _timePill.contentEdgeInsets = UIEdgeInsetsMake(4, 8, 4, 8);

        _playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _bookmarkBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _bookmarkBtn.adjustsImageWhenHighlighted = NO;
        _playBtn.adjustsImageWhenHighlighted = NO;
        UIImage *replayAsset = [UIImage imageNamed:@"replay_btn"];
        if (replayAsset) {
            [_playBtn setImage:[replayAsset imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
        } else if (@available(iOS 13.0, *)) {
            UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightRegular];
            [_playBtn setImage:[UIImage systemImageNamed:@"play.circle" withConfiguration:cfg] forState:UIControlStateNormal];
            _playBtn.tintColor = kHomeMetaIconColor;
        }

        [card addSubview:_homeLabel];
        [card addSubview:homeBadge];
        [homeBadge addSubview:_homeLogo];
        [card addSubview:_centerLabel];
        [card addSubview:awayBadge];
        [awayBadge addSubview:_awayLogo];
        [card addSubview:_awayLabel];
        [card addSubview:_dateLabel];
        [card addSubview:_timePill];
        [card addSubview:_bookmarkBtn];

        [_centerLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(card);
            make.centerY.equalTo(card).offset(-14);
            make.width.mas_greaterThanOrEqualTo(56);
        }];
        [homeBadge mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(_centerLabel.mas_left).offset(-14);
            make.centerY.equalTo(_centerLabel);
            make.width.height.mas_equalTo(32);
        }];
        [_homeLogo mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(homeBadge);
            make.width.height.mas_equalTo(18);
        }];
        [_homeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.greaterThanOrEqualTo(card).offset(12);
            make.right.equalTo(homeBadge.mas_left).offset(-8);
            make.centerY.equalTo(homeBadge);
            make.width.mas_lessThanOrEqualTo(card.mas_width).multipliedBy(0.28);
        }];
        [awayBadge mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_centerLabel.mas_right).offset(14);
            make.centerY.equalTo(_centerLabel);
            make.width.height.mas_equalTo(32);
        }];
        [_awayLogo mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(awayBadge);
            make.width.height.mas_equalTo(18);
        }];
        [_awayLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(awayBadge.mas_right).offset(6);
            make.centerY.equalTo(awayBadge);
            make.right.lessThanOrEqualTo(card).offset(-12);
            make.width.mas_lessThanOrEqualTo(card.mas_width).multipliedBy(0.28);
        }];

        [_dateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(card).offset(33);
            make.bottom.equalTo(card).offset(-12);
        }];
        [_timePill mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(card);
            make.centerY.equalTo(_dateLabel);
            make.height.mas_equalTo(24);
        }];
        [_bookmarkBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(card).offset(-16);
            make.centerY.equalTo(_dateLabel);
            make.width.height.mas_equalTo(20);
        }];
    }
    return self;
}
- (void)prepareForReuse {
    [super prepareForReuse];
    [_bookmarkBtn removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
}
@end

#pragma mark - HomeViewController

@interface HomeViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *challengerLabel;
@property (nonatomic, strong) UILabel *dateLabel;
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
/// 防止切 tab 时反复触发全量请求，记录上次加载时间
@property (nonatomic, assign) NSTimeInterval lastLoadTime;
/// 是否正在加载中，防止并发请求
@property (nonatomic, assign) BOOL isLoadingSchedule;
/// 预计算的分组缓存：按月份分组，key=月份字符串，value=该月比赛数组，顺序与 sortedDateKeys 一致
@property (nonatomic, strong) NSArray<NSString *> *sortedDateKeys;
@property (nonatomic, strong) NSDictionary<NSString *, NSArray<Match *> *> *groupedMatches;
@end

@implementation HomeViewController

- (void)viewDidLoad {
    // 先准备好赛程数据源：QMBaseViewController 会在 [super viewDidLoad] 里调用 -setupUI，本页若晚于 super 再建数据，第一次建 UI 时 table 无有效数据
    [self buildTeams];
    self.dataSource = NSMutableArray.array;
    self.filteredData = NSMutableArray.array;
    self.selectedTeamId = nil;
    [self filterData];

    // super 内会调一次 -setupUI；切勿在本方法末尾再调 setupUI，否则 header/body/scroll/table 会重复添加，出现叠在一起的重复布局
    [super viewDidLoad];

    self.view.backgroundColor = kCardLightGray;
    self.shouldShowNavigationBar = NO;
    [self filterData];
    [self setupRefresh];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 防抖：30秒内切 tab 不重复触发全量请求，避免收藏回调与数据刷新并发导致死锁
    NSTimeInterval now = [NSDate date].timeIntervalSince1970;
    if (now - self.lastLoadTime > 30.0) {
        self.lastLoadTime = now;
        [self loadHomeDataAndEndRefreshing:NO];
    }
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
    // 预计算分组缓存，避免 tableView 回调里反复遍历
    [self rebuildGroupCache];
    [_tableView reloadData];
    // 用 performSelector 防抖，避免短时间内多次触发布局计算
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateTableHeight) object:nil];
    [self performSelector:@selector(updateTableHeight) withObject:nil afterDelay:0.05];
}

- (void)rebuildGroupCache {
    NSMutableDictionary<NSString *, NSMutableArray<Match *> *> *dict = [NSMutableDictionary dictionary];
    NSMutableArray<NSString *> *keys = [NSMutableArray array];
    for (Match *m in _filteredData) {
        NSString *key = [self monthTextFromRaw:m.matchDate];
        if (!dict[key]) {
            dict[key] = [NSMutableArray array];
            [keys addObject:key];
        }
        [dict[key] addObject:m];
    }
    // 按月份倒序
    [keys sortUsingComparator:^NSComparisonResult(NSString *a, NSString *b) {
        return [b compare:a];
    }];
    self.sortedDateKeys = [keys copy];
    NSMutableDictionary *immutable = [NSMutableDictionary dictionary];
    for (NSString *k in dict) {
        immutable[k] = [dict[k] copy];
    }
    self.groupedMatches = [immutable copy];
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
    [_headerView addSubview:_avatarView];
    [_headerView addSubview:_challengerLabel];
    [_headerView addSubview:_dateLabel];

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumInteritemSpacing = 16;
    layout.sectionInset = UIEdgeInsetsMake(0, 20, 0, 20);
    _teamCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _teamCollectionView.backgroundColor = [UIColor clearColor];
    _teamCollectionView.showsHorizontalScrollIndicator = NO;
    _teamCollectionView.clipsToBounds = NO; // 允许圆圈超出 collectionView 边界显示
    _teamCollectionView.dataSource = self;
    _teamCollectionView.delegate = self;
    [_teamCollectionView registerClass:[HomeTeamCell class] forCellWithReuseIdentifier:@"TeamCell"];
    [_headerView addSubview:_teamCollectionView];

    [_headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
        make.height.mas_equalTo(257);
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
    [_teamCollectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_avatarView.mas_bottom).offset(24);
        make.leading.trailing.equalTo(_headerView);
        make.height.mas_equalTo(96);
    }];
}

- (void)setupScrollContent {
    // 白色内容区（顶部双圆弧，按原型“查看赛事/更多”所在区域）
    self.bodyBgView = [[UIView alloc] init];
    self.bodyBgView.backgroundColor = kHomeContentBg;
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
    _contentView.backgroundColor = kHomeContentBg;
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
    _tableView.backgroundColor = kHomeContentBg;
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
        make.leading.equalTo(_contentView).offset(16);
        make.trailing.equalTo(_contentView).offset(-16);
        make.height.mas_equalTo(kHomeFeaturedCardH);
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
    if (!_tableView || !self.sortedDateKeys.count) return;
    CGFloat headerH = 40.f, footerH = 0.01f, rowH = 103.f;
    CGFloat total = 0;
    for (NSString *key in self.sortedDateKeys) {
        NSInteger rows = self.groupedMatches[key].count;
        total += headerH + footerH + rows * rowH;
    }
    if (total <= 0) return;
    self.tableHeightConstraint.offset = total;
    [self.view setNeedsLayout];
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
        make.leading.equalTo(left.mas_trailing).offset(kHomeFeaturedCardGap);
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
    card.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
    // 原型：大圆角 + 连续曲线
    card.layer.cornerRadius = kHomeFeaturedCardCorner;
    if (@available(iOS 13.0, *)) {
        card.layer.cornerCurve = kCACornerCurveContinuous;
    }
    card.clipsToBounds = YES;
    UILabel *timeL = [[UILabel alloc] init];
    // 顶部星期与时间使用系统语言，避免固定英文。
    NSString *weekday = [self featuredWeekdayTextFromRaw:m.matchDate];
    NSString *detailText = [self featuredDateTextFromRaw:m.matchDate];
    if (weekday.length == 0) weekday = @"--";
    NSString *t = [self featuredTimeTextFromRaw:m.matchDate];
    timeL.text = [NSString stringWithFormat:@"%@/%@", weekday, t];
    timeL.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    timeL.textColor = [textColor colorWithAlphaComponent:0.96];
    UILabel *dateL = [[UILabel alloc] init];
    dateL.text = detailText;
    dateL.font = [UIFont systemFontOfSize:11 weight:UIFontWeightRegular];
    dateL.textColor = [textColor colorWithAlphaComponent:0.75];
    UIImageView *homeIcon = [[UIImageView alloc] init];
    homeIcon.contentMode = UIViewContentModeScaleAspectFit;
    homeIcon.backgroundColor = kHomeTeamBadgeBg;
    homeIcon.layer.cornerRadius = 12;
    homeIcon.clipsToBounds = YES;
    UIImageView *awayIcon = [[UIImageView alloc] init];
    awayIcon.contentMode = UIViewContentModeScaleAspectFit;
    awayIcon.backgroundColor = kHomeTeamBadgeBg;
    awayIcon.layer.cornerRadius = 12;
    awayIcon.clipsToBounds = YES;
    UIImage *placeImg = [UIImage imageNamed:kLogoPlaceholder];
    if (placeImg) { homeIcon.image = placeImg; awayIcon.image = placeImg; }
    // 加载球队 Logo（圆角已通过 cornerRadius + clipsToBounds 设置）
    if (m.homeTeamLogo.length > 0) {
        [homeIcon sd_setImageWithURL:[NSURL URLWithString:m.homeTeamLogo] placeholderImage:placeImg];
    }
    if (m.awayTeamLogo.length > 0) {
        [awayIcon sd_setImageWithURL:[NSURL URLWithString:m.awayTeamLogo] placeholderImage:placeImg];
    }
    NSString *homeScore = [NSString stringWithFormat:@"%ld", (long)m.homeScore];
    NSString *awayScore = [NSString stringWithFormat:@"%ld", (long)m.awayScore];
    UILabel *homeL = [[UILabel alloc] init];
    homeL.text = kHomeFeaturedTeamDisplayName(m.homeTeamName);
    homeL.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    homeL.textColor = [textColor colorWithAlphaComponent:0.96];
    homeL.lineBreakMode = NSLineBreakByTruncatingTail;
    UILabel *awayL = [[UILabel alloc] init];
    awayL.text = kHomeFeaturedTeamDisplayName(m.awayTeamName);
    awayL.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    awayL.textColor = [textColor colorWithAlphaComponent:0.96];
    awayL.lineBreakMode = NSLineBreakByTruncatingTail;
    [card addSubview:timeL];
    [card addSubview:dateL];
    [card addSubview:homeIcon];
    [card addSubview:homeL];
    [card addSubview:awayIcon];
    [card addSubview:awayL];
    CGFloat pad = kHomeFeaturedCardPad;
    [timeL mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(card).offset(24);
        make.leading.equalTo(card).offset(pad);
        make.height.mas_equalTo(17);
    }];
    [dateL mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(timeL.mas_bottom).offset(0);
        make.leading.equalTo(card).offset(pad);
        make.height.mas_equalTo(22);
    }];

    // 底部两行球队：与原型一致的留白与行距
    [awayIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(card).offset(pad);
        make.bottom.equalTo(card).offset(-20);
        make.width.height.mas_equalTo(kHomeFeaturedBadgeSize);
    }];
    [awayL mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(awayIcon.mas_trailing).offset(4);
        make.centerY.equalTo(awayIcon);
        make.height.mas_equalTo(22);
        make.trailing.lessThanOrEqualTo(card).offset(showScore ? -58 : -16);
    }];

    [homeIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(card).offset(pad);
        make.bottom.equalTo(awayIcon.mas_top).offset(-16);
        make.width.height.mas_equalTo(kHomeFeaturedBadgeSize);
    }];
    [homeL mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(homeIcon.mas_trailing).offset(4);
        make.centerY.equalTo(homeIcon);
        make.height.mas_equalTo(22);
        make.trailing.lessThanOrEqualTo(card).offset(showScore ? -58 : -16);
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

/// 精选卡片顶部时间：12 小时制并带小写 am/pm（如 11:00 pm）
- (NSString *)featuredTimeTextFromRaw:(NSString *)raw {
    NSDate *date = [self dateFromRaw:raw];
    if (!date) return @"--:--";
    NSDateFormatter *fmt = NSDateFormatter.new;
    fmt.locale = [NSLocale currentLocale];
    [fmt setLocalizedDateFormatFromTemplate:@"Hm"];
    return [fmt stringFromDate:date];
}

/// 精选卡片顶部星期：按系统语言显示（如「周六」/「Sat」）
- (NSString *)featuredWeekdayTextFromRaw:(NSString *)raw {
    NSDate *date = [self dateFromRaw:raw];
    if (!date) return @"";
    NSDateFormatter *fmt = NSDateFormatter.new;
    fmt.locale = [NSLocale currentLocale];
    [fmt setLocalizedDateFormatFromTemplate:@"EEE"];
    return [fmt stringFromDate:date];
}

/// 精选卡片日期：与设计一致（如 Sun,18 Feb 25）
- (NSString *)featuredDateTextFromRaw:(NSString *)raw {
    NSDate *date = [self dateFromRaw:raw];
    if (!date) return @"--";
    NSDateFormatter *fmt = NSDateFormatter.new;
    fmt.locale = [NSLocale currentLocale];
    [fmt setLocalizedDateFormatFromTemplate:@"d MMM yy"];
    return [fmt stringFromDate:date];
}

- (void)setupRefresh {
    RefreshPagHeader *header = [RefreshPagHeader headerWithRefreshingTarget:self refreshingAction:@selector(refreshData)];
    [header prepare];
    _scrollView.mj_header = header;
}

- (void)refreshData {
    [self loadHomeDataAndEndRefreshing:YES];
}

- (void)loadHomeDataAndEndRefreshing:(BOOL)endRefreshing {
    if (AuthManager.sharedManager.isLoggedIn) {
        [self fetchUserProfile];
        [self fetchFollowTeams];
    } else {
        self.teamItems = @[];
        [self.teamCollectionView reloadData];
        [self refreshDiscoverLikeGuestState];
    }
    [self fetchFeatureMatchs];
    [self fetchScheduleMatches];

    if (endRefreshing) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.scrollView.mj_header endRefreshing];
        });
    }
}

- (void)refreshDiscoverLikeGuestState {
    _challengerLabel.text = NSLocalizedString(@"home_challenger", nil);
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    df.dateFormat = @"MMMM d, yyyy";
    _dateLabel.text = [df stringFromDate:[NSDate date]];
    _avatarView.image = [UIImage imageNamed:kLogoPlaceholder];
    if (!_avatarView.image && @available(iOS 13.0, *)) {
        _avatarView.image = [UIImage systemImageNamed:@"person.fill"];
        _avatarView.tintColor = [UIColor whiteColor];
        _avatarView.contentMode = UIViewContentModeCenter;
    }
}

- (void)fetchFeatureMatchs {
    [MatchRequest.shared getFeaturesMatchsSuccess:^(HTTPResponse <NSArray <Match*> *>* _Nullable responseObject) {
        NSArray<Match *> *list = [responseObject.dataObject isKindOfClass:NSArray.class] ? responseObject.dataObject : @[];
#if DEBUG
        NSLog(@"[HomeFeatured] success=%d rawDataClass=%@ rawData=%@",
              responseObject.success,
              NSStringFromClass([responseObject.data class]),
              responseObject.data);
        NSLog(@"[HomeFeatured] parsed count=%ld", (long)list.count);
        if (list.count > 0) {
            Match *first = list.firstObject;
            NSLog(@"[HomeFeatured] first => matchId=%@ status=%@ home=%@ away=%@ score=%ld:%ld date=%@",
                  first.matchId, first.matchStatus, first.homeTeamName, first.awayTeamName,
                  (long)first.homeScore, (long)first.awayScore, first.matchDate);
        }
#endif
        [self applyFeaturedList:list];
    } failure:^(NSError * _Nonnull error) {
#if DEBUG
        NSLog(@"[HomeFeatured] failed error=%@", error);
#endif
        self.highlightFinished = nil;
        self.highlightUpcoming = nil;
        [self buildTwoCards];
    }];
}

- (void)applyFeaturedList:(NSArray<Match *> *)list {
    if (list.count == 0) {
        self.highlightFinished = nil;
        self.highlightUpcoming = nil;
        [self buildTwoCards];
        return;
    }

    Match *firstFinished = nil;
    Match *firstUpcoming = nil;
    for (Match *m in list) {
        BOOL finished = [self home_isMatchFinished:m];
        if (finished && !firstFinished) firstFinished = m;
        if (!finished && !firstUpcoming) firstUpcoming = m;
        if (firstFinished && firstUpcoming) break;
    }

    Match *first = list.firstObject;
    Match *second = (list.count > 1) ? list[1] : first;
    self.highlightFinished = firstFinished ?: first;
    self.highlightUpcoming = firstUpcoming ?: ((second != self.highlightFinished) ? second : first);
    if (self.highlightFinished == self.highlightUpcoming && list.count > 1) {
        self.highlightUpcoming = second;
    }

    [self buildTwoCards];
}

- (void)fetchScheduleMatches {
    // 防止并发：上一次请求还未完成时不重复发起
    if (self.isLoadingSchedule) return;
    self.isLoadingSchedule = YES;
    __weak typeof(self) weakSelf = self;
    NSDateFormatter *dateFmt = [[NSDateFormatter alloc] init];
    dateFmt.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    dateFmt.dateFormat = @"yyyy-MM-dd";
    NSString *todayStr = [dateFmt stringFromDate:[NSDate date]];

    NSDateFormatter *monthFmt = [[NSDateFormatter alloc] init];
    monthFmt.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    monthFmt.dateFormat = @"yyyy-MM";
    NSString *monthStr = [monthFmt stringFromDate:[NSDate date]];

    // 先查当月所有有比赛的日期，然后并发拉每个日期的日程，合并展示
    [[MatchRequest shared] getMatchScheduleDatesWithMonth:monthStr success:^(HTTPResponse * _Nullable responseObject) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;

        NSArray *dates = [responseObject.dataObject isKindOfClass:NSArray.class] ? responseObject.dataObject : @[];
        if (dates.count == 0) {
            // 当月没有比赛，用今天查一次兜底
            dates = @[todayStr];
        }

        // 并发请求所有日期的日程，合并结果
        dispatch_group_t group = dispatch_group_create();
        NSMutableArray<Match *> *allMatches = [NSMutableArray array];

        for (NSString *date in dates) {
            if (![date isKindOfClass:NSString.class]) continue;
            dispatch_group_enter(group);
            [[MatchRequest shared] getMatchScheduleWithDate:date myTeamOnly:NO page:1 pageSize:50 success:^(HTTPResponse<NSArray<Match *> *> * _Nullable r) {
                // success block 在主线程回调，无需加锁
                NSArray<Match *> *list = [r.dataObject isKindOfClass:NSArray.class] ? r.dataObject : @[];
                [allMatches addObjectsFromArray:list];
                dispatch_group_leave(group);
            } failure:^(NSError * _Nonnull error) {
                dispatch_group_leave(group);
            }];
        }

        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            self.isLoadingSchedule = NO;
            // 按日期倒序排列
            NSArray<Match *> *sorted = [allMatches sortedArrayUsingComparator:^NSComparisonResult(Match *a, Match *b) {
                NSDate *da = [self dateFromRaw:a.matchDate];
                NSDate *db = [self dateFromRaw:b.matchDate];
                if (!da && !db) return NSOrderedSame;
                if (!da) return NSOrderedDescending;
                if (!db) return NSOrderedAscending;
                return [db compare:da];
            }];
            self.dataSource = sorted.mutableCopy;
            [self filterData];
            [self updateTableHeight];
        });
    } failure:^(NSError * _Nonnull error) {
        // 日历接口失败，直接用今天查
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) { return; }
        [[MatchRequest shared] getMatchScheduleWithDate:todayStr myTeamOnly:NO page:1 pageSize:50 success:^(HTTPResponse<NSArray<Match *> *> * _Nullable r2) {
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            self.isLoadingSchedule = NO;
            NSArray<Match *> *list = [r2.dataObject isKindOfClass:NSArray.class] ? r2.dataObject : @[];
            self.dataSource = [list mutableCopy];
            [self filterData];
            [self updateTableHeight];
        } failure:^(NSError *e) {
            __strong typeof(weakSelf) self = weakSelf;
            if (self) self.isLoadingSchedule = NO;
        }];
    }];
}

- (void)fetchUserProfile {
    [UserRequest.shared getLoginUserInfoSuccess:^(HTTPResponse <User *>* _Nullable responseObject) {
        [self refreshUserProfile];
    } failure:^(NSError * _Nonnull error) {
    }];
}
- (void)fetchFollowTeams {
    __weak typeof(self) weakSelf = self;
    [TeamsRequest.shared getFollowTeamIconsSuccess:^(HTTPResponse <NSArray <TeamIcon *> *>* _Nullable responseObject) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        NSArray *list = [responseObject.dataObject isKindOfClass:NSArray.class] ? responseObject.dataObject : @[];
        self.teamItems = list;
        // 仅在新列表中找不到当前选中项时清空，避免每次拉取关注球队都把选中态打回未选中
        NSString *kept = self.selectedTeamId;
        if (kept.length) {
            BOOL found = NO;
            for (TeamIcon *t in list) {
                if ([kHomeTeamIdString(t.teamId) isEqualToString:kept]) { found = YES; break; }
            }
            if (!found) self.selectedTeamId = nil;
        }
        [self.teamCollectionView reloadData];
        [self filterData];
    } failure:^(NSError * _Nonnull error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.teamItems = @[];
        self.selectedTeamId = nil;
        [self.teamCollectionView reloadData];
        [self filterData];
    }];
}
- (void)refreshUserProfile {
    [_avatarView sd_setImageWithURL:[NSURL URLWithString:AuthManager.sharedManager.user.profile.avatar]];
    NSString *nickname = AuthManager.sharedManager.user.profile.nickname;
    _challengerLabel.text = nickname.length > 0 ? nickname : (NSLocalizedString(@"home_challenger", nil) ?: @"CHALLENGER");
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    df.dateFormat = @"MMMM d, yyyy";
    _dateLabel.text = [df stringFromDate:[NSDate date]];
}

- (NSDate *)dateFromRaw:(NSString *)raw {
    if (raw.length == 0) return nil;
    NSString *s = [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (s.length == 0) return nil;

    BOOL allDigits = YES;
    for (NSUInteger i = 0; i < s.length; i++) {
        unichar ch = [s characterAtIndex:i];
        if (ch < '0' || ch > '9') {
            allDigits = NO;
            break;
        }
    }
    if (allDigits && s.length >= 10) {
        long long n = [s longLongValue];
        if (n > 1000000000000LL) {
            return [NSDate dateWithTimeIntervalSince1970:n / 1000.0];
        }
        if (n > 1000000000LL) {
            return [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)n];
        }
    }
    if ([s containsString:@"."]) {
        NSScanner *scanner = [NSScanner scannerWithString:s];
        double v = 0;
        if ([scanner scanDouble:&v] && scanner.atEnd && v > 1e9) {
            if (v > 1e12) {
                return [NSDate dateWithTimeIntervalSince1970:v / 1000.0];
            }
            return [NSDate dateWithTimeIntervalSince1970:v];
        }
    }
    if (@available(iOS 11.0, *)) {
        NSISO8601DateFormatter *iso = [[NSISO8601DateFormatter alloc] init];
        iso.formatOptions = NSISO8601DateFormatWithInternetDateTime | NSISO8601DateFormatWithFractionalSeconds;
        NSDate *d = [iso dateFromString:s];
        if (d) return d;
        iso.formatOptions = NSISO8601DateFormatWithInternetDateTime;
        d = [iso dateFromString:s];
        if (d) return d;
    }
    NSDateFormatter *fmt = NSDateFormatter.new;
    fmt.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    NSArray<NSString *> *formats = @[
        @"yyyy-MM-dd'T'HH:mm:ssZ",
        @"yyyy-MM-dd'T'HH:mm:ss.SSSZ",
        @"yyyy-MM-dd'T'HH:mm:ssXXX",
        @"yyyy-MM-dd'T'HH:mm:ss.SSSXXX",
        @"yyyy-MM-dd'T'HH:mm:ss'Z'",
        @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
        @"yyyy-MM-dd HH:mm:ss",
        @"yyyy-MM-dd HH:mm",
        @"yyyy/MM/dd HH:mm:ss",
        @"yyyy/MM/dd HH:mm",
        @"yyyy-MM-dd",
    ];
    for (NSString *format in formats) {
        fmt.dateFormat = format;
        NSDate *date = [fmt dateFromString:s];
        if (date) return date;
    }
    return nil;
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
    fmt.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
    fmt.dateFormat = @"yyyy年MM月dd日";
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
    __weak HomeTeamCell *weakCell = cell;
    [cell.logoView sd_setImageWithURL:[NSURL URLWithString:item.logo]
                     placeholderImage:[UIImage imageNamed:kLogoPlaceholder]
                            completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        __strong HomeTeamCell *c = weakCell;
        if (!c) return;
        c.logoView.backgroundColor = (image && !error) ? [UIColor clearColor] : [UIColor colorWithWhite:0.6 alpha:1.0];
        [c applyHomeTeamSelectionAppearance];
    }];
    if (!cell.logoView.image) {
        cell.logoView.backgroundColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    } else {
        cell.logoView.backgroundColor = [UIColor clearColor];
    }
    NSString *tid = kHomeTeamIdString(item.teamId);
    BOOL sel = (tid.length > 0) && _selectedTeamId.length && [tid isEqualToString:_selectedTeamId];
    // 必须先于 setSelected: 写入，否则系统 layout 会按 layoutAttributes 把 selected 置 NO 时仍要用这里的状态画白底
    cell.homeTeamStyleSelected = sel;
    [cell setSelected:sel];
    return cell;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(64, 96);
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    TeamIcon *item = _teamItems[indexPath.item];
    NSString *tid = kHomeTeamIdString(item.teamId);
    if (tid.length == 0) { return; }
    if (_selectedTeamId.length && [tid isEqualToString:_selectedTeamId]) {
        _selectedTeamId = nil;
    } else {
        _selectedTeamId = [tid copy];
    }
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
- (NSArray *)sortedDates {
    return self.sortedDateKeys ?: @[];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sortedDateKeys.count;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *key = self.sortedDateKeys[section];
    return self.groupedMatches[key].count;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *v = [[UIView alloc] init];
    v.backgroundColor = kHomeContentBg;
    UIImageView *cal = [[UIImageView alloc] init];
    UIImage *calAsset = [UIImage imageNamed:@"Calendar"];
    if (calAsset) {
        cal.image = [calAsset imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cal.tintColor = [UIColor blackColor];
    } else if (@available(iOS 13.0, *)) {
        cal.image = [UIImage systemImageNamed:@"calendar"];
        cal.tintColor = [UIColor blackColor];
    }
    cal.contentMode = UIViewContentModeScaleAspectFit;
    [v addSubview:cal];
    UILabel *lab = [[UILabel alloc] init];
    NSString *monthKey = self.sortedDateKeys[section];
    lab.text = [NSString stringWithFormat:@" %@", monthKey];
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
    NSString *key = self.sortedDateKeys[indexPath.section];
    return self.groupedMatches[key][indexPath.row];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MatchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MatchCell"];
    Match *m = [self modelAtIndexPath:indexPath];
    cell.homeLabel.text = m.homeTeamName ?: @"";
    cell.awayLabel.text = m.awayTeamName ?: @"";
    cell.dateLabel.text = [self dateDetailFromRaw:m.matchDate];
    [cell.timePill setTitle:[self timeTextFromRaw:m.matchDate] forState:UIControlStateNormal];
    BOOL showScore = (![self home_isMatchNotYetStartedForDisplay:m]) || (m.homeScore > 0 || m.awayScore > 0);
    cell.centerLabel.text = showScore ? [NSString stringWithFormat:@"%ld : %ld", (long)m.homeScore, (long)m.awayScore] : @"VS";
    [cell.homeLogo sd_setImageWithURL:[NSURL URLWithString:m.homeTeamLogo] placeholderImage:[UIImage imageNamed:kLogoPlaceholder]];
    [cell.awayLogo sd_setImageWithURL:[NSURL URLWithString:m.awayTeamLogo] placeholderImage:[UIImage imageNamed:kLogoPlaceholder]];
    UIImage *ph = [UIImage imageNamed:kLogoPlaceholder];
    if (!ph) {
        cell.homeLogo.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1.0];
        cell.awayLogo.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1.0];
    }

    UIImage *starImg = kHomeFavoriteIcon(m.favorited);
    [cell.bookmarkBtn setImage:starImg forState:UIControlStateNormal];
    if (m.favorited) {
        cell.bookmarkBtn.tintColor = [UIColor clearColor];
        cell.bookmarkBtn.alpha = 1.0;
    } else {
        cell.bookmarkBtn.tintColor = kHomeMetaIconColor;
        cell.bookmarkBtn.alpha = 0.5;
    }
    cell.bookmarkBtn.tag = (NSInteger)(indexPath.section * 10000 + indexPath.row);
    [cell.bookmarkBtn removeTarget:self action:@selector(onHomeFavoriteTapped:) forControlEvents:UIControlEventTouchUpInside];
    [cell.bookmarkBtn addTarget:self action:@selector(onHomeFavoriteTapped:) forControlEvents:UIControlEventTouchUpInside];
    return cell;
}

/// 与发现页类似：已结束/进行中用于精选卡片等；LIVE 视为未「踢完终场」但不一定算「已结束」
- (BOOL)home_isMatchFinished:(Match *)match {
    NSString *st = match.matchStatus.uppercaseString;
    if (st.length > 0) {
        if ([st containsString:@"FINISH"] || [st containsString:@"COMPLETE"] || [st isEqualToString:@"FT"] || [st containsString:@"ENDED"]) {
            return YES;
        }
        if ([st containsString:@"已结束"] || [st containsString:@"完赛"]) {
            return YES;
        }
        if ([st containsString:@"SCHEDULE"] || [st containsString:@"UPCOM"] || [st isEqualToString:@"NS"] || [st containsString:@"LIVE"]) {
            return NO;
        }
        if ([st containsString:@"未开始"] || [st containsString:@"未赛"] || [st containsString:@"待定"]) {
            return NO;
        }
    }
    NSDate *kickoff = [self dateFromRaw:match.matchDate];
    if (!kickoff) {
        return NO;
    }
    return [kickoff compare:[NSDate date]] == NSOrderedAscending;
}

/// 仅用于赛程列表中间：未开赛（含无法判定时间且无进球）时显示 "VS"；进行中 / 已开球 / 已结束 显示 "x : y"（含 0:0）
- (BOOL)home_isMatchNotYetStartedForDisplay:(Match *)match {
    NSString *st = (match.matchStatus ?: @"").uppercaseString;
    if (st.length > 0) {
        if ([st containsString:@"LIVE"] || [st containsString:@"IN_PLAY"] || [st containsString:@"1ST"] || [st isEqualToString:@"1H"] || [st isEqualToString:@"2H"] || [st containsString:@"2ND"] || [st containsString:@"ET"] || [st containsString:@"PEN"] || [st isEqualToString:@"HT"] || [st containsString:@"HALF"] || [st containsString:@"中场"] || [st containsString:@"INT"] || [st containsString:@"PAUSE"]) {
            return NO;
        }
        if ([st containsString:@"FINISH"] || [st containsString:@"COMPLETE"] || [st isEqualToString:@"FT"] || [st containsString:@"ENDED"] || [st containsString:@"AET"] || [st isEqualToString:@"FT_PEN"] || [st containsString:@"PEN_"] || [st containsString:@"已结束"] || [st containsString:@"完赛"] || [st isEqualToString:@"END"] || [st isEqualToString:@"CLOSED"] || [st isEqualToString:@"RESULT"] || [st isEqualToString:@"FIN"]) {
            return NO;
        }
        if ([st containsString:@"SCHEDULE"] || [st containsString:@"UPCOM"] || [st isEqualToString:@"NS"] || [st containsString:@"TBD"] || [st isEqualToString:@"PST"] || [st isEqualToString:@"NOS"] || [st containsString:@"未开始"] || [st containsString:@"未赛"] || [st containsString:@"待定"] || [st isEqualToString:@"PRE"]) {
            return YES;
        }
    }
    NSDate *kick = [self dateFromRaw:match.matchDate];
    if (!kick) {
        return YES;
    }
    if ([kick compare:[NSDate date]] == NSOrderedDescending) {
        return YES;
    }
    return NO;
}

- (NSString *)home_errorText:(NSError *)error defaultText:(NSString *)def {
    if ([error isKindOfClass:[APIError class]]) {
        APIError *ae = (APIError *)error;
        if (ae.businessMessage.length > 0) {
            return ae.businessMessage;
        }
    }
    NSString *msg = error.localizedDescription;
    return msg.length > 0 ? msg : def;
}

- (void)onHomeFavoriteTapped:(UIButton *)sender {
    NSInteger tag = sender.tag;
    NSInteger section = tag / 10000;
    NSInteger row = tag % 10000;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    Match *match = [self modelAtIndexPath:indexPath];
    if (match.matchId.length == 0) {
        [QMUITips showError:NSLocalizedString(@"more_matches_favorite_no_id", nil) ?: @"比赛信息不完整，无法收藏"];
        return;
    }
    sender.enabled = NO;
    __weak typeof(self) weakSelf = self;
    __weak UIButton *weakBtn = sender;
    void (^reloadRow)(void) = ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        weakBtn.enabled = YES;
        // 用 reloadData 替代 reloadRowsAtIndexPaths，避免切 tab 后 indexPath 失效导致死锁
        [self.tableView reloadData];
    };
    if (match.favorited) {
        [[MatchRequest shared] unfavoriteMatch:match.matchId success:^(HTTPResponse * _Nullable responseObject) {
            match.favorited = NO;
            reloadRow();
        } failure:^(NSError * _Nonnull error) {
            weakBtn.enabled = YES;
            __strong typeof(weakSelf) self = weakSelf;
            [QMUITips showError:[self home_errorText:error defaultText:@"取消收藏失败"]];
        }];
    } else {
        [[MatchRequest shared] favoriteMatch:match.matchId success:^(HTTPResponse * _Nullable responseObject) {
            match.favorited = YES;
            reloadRow();
        } failure:^(NSError * _Nonnull error) {
            weakBtn.enabled = YES;
            __strong typeof(weakSelf) self = weakSelf;
            [QMUITips showError:[self home_errorText:error defaultText:@"收藏失败"]];
        }];
    }
}

@end
