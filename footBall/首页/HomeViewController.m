//
//  HomeViewController.m
//  footBall
//

#import "HomeViewController.h"
#import "MoreMatchesViewController.h"
#import "RefreshPagHeader.h"
#import <MJRefresh/MJRefreshAutoNormalFooter.h>
#import <Masonry/Masonry.h>
#import "ColorManager.h"
#import "MatchRequest.h"
#import "APIError.h"
#import "APIEnvironmentManager.h"
#import "PNBackendDateTime.h"
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
static NSString * const kHomeOfflineCacheKeyPrefix = @"home.offline.cache.v1";
static CGFloat const kHomeFeaturedCardH = 168.f;
static CGFloat const kHomeFeaturedCardGap = 12.f;
static CGFloat const kHomeFeaturedCardPad = 16.f;
static CGFloat const kHomeFeaturedBadgeSize = 24.f;
/// 顶部球队：圈 56 + 名上间距 5 + 11pt 单行字高约 13
static CGFloat const kHomeTeamNameBottomFromCollectionTop = 74.f;
/// 球队名底到白色内容区顶（Figma）
static CGFloat const kHomeTeamNameToBodyGap = 18.f;
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
    [_homeLogo sd_cancelCurrentImageLoad];
    [_awayLogo sd_cancelCurrentImageLoad];
    _homeLogo.image = nil;
    _awayLogo.image = nil;
    _homeLogo.backgroundColor = [UIColor clearColor];
    _awayLogo.backgroundColor = [UIColor clearColor];
    _homeLabel.text = nil;
    _awayLabel.text = nil;
    _centerLabel.text = nil;
    _dateLabel.text = nil;
    [_timePill setTitle:nil forState:UIControlStateNormal];
    [_bookmarkBtn setImage:nil forState:UIControlStateNormal];
    _bookmarkBtn.tag = 0;
    _bookmarkBtn.alpha = 1.0;
    _bookmarkBtn.tintColor = kHomeMetaIconColor;
}
@end

#pragma mark - HomeViewController

@interface HomeViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *challengerLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UICollectionView *teamCollectionView;
@property (nonatomic, strong) NSArray<Team *> *teamItems;
@property (nonatomic, copy, nullable) NSString *selectedTeamId; // 当前选中的关注球队；有球队时默认第一个

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
/// 赛程分页
@property (nonatomic, assign) NSInteger scheduleCurrentPage;
@property (nonatomic, assign) BOOL scheduleHasMore;
/// 预计算的分组缓存：按月份分组，key=月份字符串，value=该月比赛数组，顺序与 sortedDateKeys 一致
@property (nonatomic, strong) NSArray<NSString *> *sortedDateKeys;
@property (nonatomic, strong) NSDictionary<NSString *, NSArray<Match *> *> *groupedMatches;
/// 首页定位版：记录一次加载链路起点（用于打印各阶段耗时）
@property (nonatomic, assign) CFTimeInterval homeDebugLoadStartAt;
@end

@implementation HomeViewController

static const NSInteger kHomeScheduleFetchPageSize = 20;

- (NSString *)homeCacheKey {
    NSString *uid = AuthManager.sharedManager.user.profile.userId ?: AuthManager.sharedManager.user.userId ?: @"guest";
    if (uid.length == 0) uid = @"guest";
    return [NSString stringWithFormat:@"%@.%@", kHomeOfflineCacheKeyPrefix, uid];
}

- (NSDictionary *)home_teamIconDictFromModel:(Team *)item {
    if (!item) return @{};
    return @{
        @"teamId": item.teamId ?: @"",
        @"name": item.name ?: @"",
        @"logo": item.logo ?: @"",
        @"nameEn": item.nameEn ?: @"",
    };
}

- (Team *)home_teamIconFromDict:(NSDictionary *)dict {
    if (![dict isKindOfClass:NSDictionary.class]) return nil;
    Team *item = [Team new];
    item.teamId = [dict[@"teamId"] isKindOfClass:NSString.class] ? dict[@"teamId"] : @"";
    item.name = [dict[@"name"] isKindOfClass:NSString.class] ? dict[@"name"] : @"";
    item.logo = [dict[@"logo"] isKindOfClass:NSString.class] ? dict[@"logo"] : @"";
    item.nameEn = [dict[@"nameEn"] isKindOfClass:NSString.class] ? dict[@"nameEn"] : @"";
    return item;
}

- (NSDictionary *)home_matchDictFromModel:(Match *)m {
    if (!m) return @{};
    return @{
        @"matchId": m.matchId ?: @"",
        @"homeTeamId": m.homeTeamId ?: @"",
        @"awayTeamId": m.awayTeamId ?: @"",
        @"homeTeamName": m.homeTeamName ?: @"",
        @"awayTeamName": m.awayTeamName ?: @"",
        @"homeTeamLogo": m.homeTeamLogo ?: @"",
        @"awayTeamLogo": m.awayTeamLogo ?: @"",
        @"matchDate": m.matchDate ?: @"",
        @"matchStatus": m.matchStatus ?: @"",
        @"homeScore": @(m.homeScore),
        @"awayScore": @(m.awayScore),
        @"favorited": @(m.favorited),
    };
}

- (Match *)home_matchFromDict:(NSDictionary *)dict {
    if (![dict isKindOfClass:NSDictionary.class]) return nil;
    Match *m = [Match new];
    m.matchId = [dict[@"matchId"] isKindOfClass:NSString.class] ? dict[@"matchId"] : @"";
    m.homeTeamId = [dict[@"homeTeamId"] isKindOfClass:NSString.class] ? dict[@"homeTeamId"] : @"";
    m.awayTeamId = [dict[@"awayTeamId"] isKindOfClass:NSString.class] ? dict[@"awayTeamId"] : @"";
    m.homeTeamName = [dict[@"homeTeamName"] isKindOfClass:NSString.class] ? dict[@"homeTeamName"] : @"";
    m.awayTeamName = [dict[@"awayTeamName"] isKindOfClass:NSString.class] ? dict[@"awayTeamName"] : @"";
    m.homeTeamLogo = [dict[@"homeTeamLogo"] isKindOfClass:NSString.class] ? dict[@"homeTeamLogo"] : @"";
    m.awayTeamLogo = [dict[@"awayTeamLogo"] isKindOfClass:NSString.class] ? dict[@"awayTeamLogo"] : @"";
    m.matchDate = [dict[@"matchDate"] isKindOfClass:NSString.class] ? dict[@"matchDate"] : @"";
    m.matchStatus = [dict[@"matchStatus"] isKindOfClass:NSString.class] ? dict[@"matchStatus"] : @"";
    m.homeScore = [dict[@"homeScore"] respondsToSelector:@selector(integerValue)] ? [dict[@"homeScore"] integerValue] : 0;
    m.awayScore = [dict[@"awayScore"] respondsToSelector:@selector(integerValue)] ? [dict[@"awayScore"] integerValue] : 0;
    m.favorited = [dict[@"favorited"] respondsToSelector:@selector(boolValue)] ? [dict[@"favorited"] boolValue] : NO;
    return m;
}

- (void)saveHomeOfflineCache {
    NSMutableArray *teams = [NSMutableArray array];
    for (Team *item in self.teamItems ?: @[]) {
        [teams addObject:[self home_teamIconDictFromModel:item]];
    }
    NSMutableArray *schedule = [NSMutableArray array];
    for (Match *m in self.dataSource ?: @[]) {
        [schedule addObject:[self home_matchDictFromModel:m]];
    }
    NSMutableArray *featured = [NSMutableArray array];
    if (self.highlightFinished) [featured addObject:[self home_matchDictFromModel:self.highlightFinished]];
    if (self.highlightUpcoming) [featured addObject:[self home_matchDictFromModel:self.highlightUpcoming]];
    NSDictionary *profile = @{
        @"nickname": self.challengerLabel.text ?: @"",
        @"dateText": self.dateLabel.text ?: @"",
        @"avatarURL": AuthManager.sharedManager.user.profile.avatar ?: AuthManager.sharedManager.user.avatar ?: @"",
    };
    NSDictionary *payload = @{
        @"teams": teams,
        @"selectedTeamId": self.selectedTeamId ?: @"",
        @"schedule": schedule,
        @"featured": featured,
        @"profile": profile,
        @"savedAt": @([[NSDate date] timeIntervalSince1970]),
    };
    [[NSUserDefaults standardUserDefaults] setObject:payload forKey:[self homeCacheKey]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)restoreHomeOfflineCacheIfNeeded {
    NSDictionary *payload = [[NSUserDefaults standardUserDefaults] objectForKey:[self homeCacheKey]];
    if (![payload isKindOfClass:NSDictionary.class]) return;
    NSArray *teamArr = [payload[@"teams"] isKindOfClass:NSArray.class] ? payload[@"teams"] : @[];
    NSMutableArray<Team *> *teams = [NSMutableArray arrayWithCapacity:teamArr.count];
    for (id item in teamArr) {
        Team *team = [self home_teamIconFromDict:item];
        if (team) [teams addObject:team];
    }
    if (teams.count > 0) {
        self.teamItems = [teams copy];
    }
    NSString *selected = [payload[@"selectedTeamId"] isKindOfClass:NSString.class] ? payload[@"selectedTeamId"] : @"";
    if (selected.length > 0) {
        self.selectedTeamId = selected;
    }
    NSArray *scheduleArr = [payload[@"schedule"] isKindOfClass:NSArray.class] ? payload[@"schedule"] : @[];
    NSMutableArray<Match *> *matches = [NSMutableArray arrayWithCapacity:scheduleArr.count];
    for (id item in scheduleArr) {
        Match *m = [self home_matchFromDict:item];
        if (m) [matches addObject:m];
    }
    if (matches.count > 0) {
        self.dataSource = [matches mutableCopy];
    }
    NSArray *featuredArr = [payload[@"featured"] isKindOfClass:NSArray.class] ? payload[@"featured"] : @[];
    if (featuredArr.count > 0) {
        self.highlightFinished = [self home_matchFromDict:featuredArr.firstObject];
    }
    if (featuredArr.count > 1) {
        self.highlightUpcoming = [self home_matchFromDict:featuredArr[1]];
    }
}

/// 首页数据防护：按 matchId+matchDate 去重并限制最大数量，避免异常大包导致首屏卡死。
- (NSArray<Match *> *)home_sanitizedMatchesForHome:(NSArray<Match *> *)input maxCount:(NSInteger)maxCount {
    if (![input isKindOfClass:NSArray.class] || input.count == 0) return @[];
    NSMutableArray<Match *> *out = [NSMutableArray array];
    NSMutableSet<NSString *> *seen = [NSMutableSet set];
    for (id obj in input) {
        if (![obj isKindOfClass:Match.class]) continue;
        Match *m = (Match *)obj;
        NSString *mid = [m.matchId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *md = [m.matchDate stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *key = [NSString stringWithFormat:@"%@#%@", mid ?: @"", md ?: @""];
        // 仅跳过“有稳定主键”的重复项；无主键项仍保留，避免误删。
        if (mid.length > 0 && md.length > 0) {
            if ([seen containsObject:key]) continue;
            [seen addObject:key];
        }
        [out addObject:m];
        if (maxCount > 0 && out.count >= maxCount) break;
    }
    return out;
}


- (BOOL)home_scheduleHasMoreFromResponse:(HTTPResponse *)responseObject
                                pageNum:(NSInteger)pageNum
                               pageSize:(NSInteger)pageSize
                              listCount:(NSInteger)listCount {
    if ([responseObject.data isKindOfClass:NSDictionary.class]) {
        NSDictionary *d = (NSDictionary *)responseObject.data;
        NSInteger total = [d[@"total"] respondsToSelector:@selector(longLongValue)] ? (NSInteger)[d[@"total"] longLongValue] : 0;
        if (total > 0) {
            return pageNum * pageSize < total;
        }
    }
    return listCount >= pageSize;
}

#if DEBUG
- (NSString *)home_monthUpcomingScheduleCurlWithTeamId:(NSString *)teamId page:(NSInteger)page pageSize:(NSInteger)pageSize myTeamOnly:(BOOL)myTeamOnly {
    NSString *base = [APIEnvironmentManager sharedManager].currentBaseURL ?: @"";
    if ([base hasSuffix:@"/"]) {
        base = [base substringToIndex:base.length - 1];
    }
    NSString *token = AuthManager.sharedManager.user.accessToken ?: @"<token>";
    NSMutableArray<NSString *> *parts = [NSMutableArray arrayWithObjects:
                                         [NSString stringWithFormat:@"myTeamOnly=%d", myTeamOnly ? 1 : 0],
                                         [NSString stringWithFormat:@"pageNum=%ld", (long)MAX(page, 1)],
                                         [NSString stringWithFormat:@"pageSize=%ld", (long)MAX(pageSize, 1)],
                                         nil];
    if (teamId.length > 0) {
        [parts addObject:[NSString stringWithFormat:@"teamId=%@", teamId]];
    }
    NSString *url = [NSString stringWithFormat:@"%@/api/v1/home/schedule/month-upcoming?%@",
                     base, [parts componentsJoinedByString:@"&"]];
    return [NSString stringWithFormat:
            @"curl '%@' \\\n"
            "  -H 'Accept: application/json' \\\n"
            "  -H 'Authorization: Bearer %@'",
            url, token];
}
#endif

- (void)viewDidLoad {
    // 先准备好赛程数据源：QMBaseViewController 会在 [super viewDidLoad] 里调用 -setupUI，本页若晚于 super 再建数据，第一次建 UI 时 table 无有效数据
    [self buildTeams];
    self.dataSource = NSMutableArray.array;
    self.filteredData = NSMutableArray.array;
    self.selectedTeamId = nil;
    self.scheduleCurrentPage = 0;
    self.scheduleHasMore = YES;
    [self restoreHomeOfflineCacheIfNeeded];
    [self filterData];

    // super 内会调一次 -setupUI；切勿在本方法末尾再调 setupUI，否则 header/body/scroll/table 会重复添加，出现叠在一起的重复布局
    [super viewDidLoad];

    self.view.backgroundColor = kCardLightGray;
    self.shouldShowNavigationBar = NO;
    NSMutableArray<Match *> *cachedFeatured = [NSMutableArray array];
    if ([self.highlightFinished isKindOfClass:Match.class]) [cachedFeatured addObject:self.highlightFinished];
    if ([self.highlightUpcoming isKindOfClass:Match.class]) [cachedFeatured addObject:self.highlightUpcoming];
    if (cachedFeatured.count > 0) {
        [self applyFeaturedList:cachedFeatured];
    }
    if (self.teamItems.count > 0) {
        [self.teamCollectionView reloadData];
    }
    [self filterData];
    [self setupRefresh];
    NSLog(@"[HomeDebug] viewDidLoad done");
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"[HomeDebug] viewWillAppear");
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

- (void)ensureDefaultSelectedTeamIfNeeded {
    if (self.selectedTeamId.length > 0) return;
    if (self.teamItems.count == 0) return;
    NSString *firstId = kHomeTeamIdString(self.teamItems.firstObject.teamId);
    if (firstId.length > 0) {
        self.selectedTeamId = firstId;
    }
}

- (void)filterData {
    CFTimeInterval t0 = CACurrentMediaTime();
    [self ensureDefaultSelectedTeamIfNeeded];
    // 赛程已按 selectedTeamId 走服务端 teamId 过滤；直接展示 dataSource，避免旧缓存/其它队数据被本地误滤空
    _filteredData = [_dataSource mutableCopy];
    // 预计算分组缓存，避免 tableView 回调里反复遍历
    [self rebuildGroupCache];
    [_tableView reloadData];
    // 用 performSelector 防抖，避免短时间内多次触发布局计算
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateTableHeight) object:nil];
    [self performSelector:@selector(updateTableHeight) withObject:nil afterDelay:0.05];
    NSLog(@"[HomeDebug] filterData done data=%ld filtered=%ld sections=%ld cost=%.3f",
          (long)self.dataSource.count, (long)self.filteredData.count, (long)self.sortedDateKeys.count, CACurrentMediaTime() - t0);
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
    // 按月份升序（小到大）：例如 2026-04 在 2026-05 前
    [keys sortUsingComparator:^NSComparisonResult(NSString *a, NSString *b) {
        return [a compare:b];
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
    _challengerLabel.text = @"--";
    _challengerLabel.font = [UIFont boldSystemFontOfSize:16];
    _challengerLabel.textColor = [UIColor whiteColor];
    _dateLabel = [[UILabel alloc] init];
    {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        df.locale = [NSLocale currentLocale];
        df.timeZone = [NSTimeZone localTimeZone];
        df.dateFormat = @"MMMM d, yyyy";
        _dateLabel.text = [df stringFromDate:[NSDate date]];
    }
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
        // 相对球队列表定位，保证队名与白色内容区间距恒为 18pt（不随安全区变化）
        make.top.equalTo(_teamCollectionView.mas_top).offset(kHomeTeamNameBottomFromCollectionTop + kHomeTeamNameToBodyGap);
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
    CFTimeInterval t0 = CACurrentMediaTime();
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
    NSLog(@"[HomeDebug] updateTableHeight total=%.1f sections=%ld cost=%.3f", total, (long)self.sortedDateKeys.count, CACurrentMediaTime() - t0);
}

- (void)updateLocalizedStrings {
    [super updateLocalizedStrings];
    NSString *nickname = AuthManager.sharedManager.user.profile.nickname;
    _challengerLabel.text = nickname.length > 0 ? nickname : @"--";
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
    dateL.text = detailText.length ? detailText : @"--";
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
    NSString *homeScore = m ? [NSString stringWithFormat:@"%ld", (long)m.homeScore] : @"--";
    NSString *awayScore = m ? [NSString stringWithFormat:@"%ld", (long)m.awayScore] : @"--";
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
    NSDateFormatter *fmt = [PNBackendDateTime displayFormatter];
    fmt.locale = [NSLocale currentLocale];
    [fmt setLocalizedDateFormatFromTemplate:@"Hm"];
    return [fmt stringFromDate:date];
}

/// 精选卡片顶部星期：按系统语言显示（如「周六」/「Sat」）
- (NSString *)featuredWeekdayTextFromRaw:(NSString *)raw {
    NSDate *date = [self dateFromRaw:raw];
    if (!date) return @"";
    NSDateFormatter *fmt = [PNBackendDateTime displayFormatter];
    fmt.locale = [NSLocale currentLocale];
    [fmt setLocalizedDateFormatFromTemplate:@"EEE"];
    return [fmt stringFromDate:date];
}

/// 精选卡片日期：与设计一致（如 Sun,18 Feb 25）
- (NSString *)featuredDateTextFromRaw:(NSString *)raw {
    NSDate *date = [self dateFromRaw:raw];
    if (!date) return @"--";
    NSDateFormatter *fmt = [PNBackendDateTime displayFormatter];
    fmt.locale = [NSLocale currentLocale];
    [fmt setLocalizedDateFormatFromTemplate:@"d MMM yy"];
    return [fmt stringFromDate:date];
}

- (void)setupRefresh {
    RefreshPagHeader *header = [RefreshPagHeader headerWithRefreshingTarget:self refreshingAction:@selector(refreshData)];
    [header prepare];
    _scrollView.mj_header = header;
    __weak typeof(self) weakSelf = self;
    MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
        [weakSelf loadMoreScheduleMatches];
    }];
    footer.automaticallyHidden = YES;
    footer.stateLabel.font = [UIFont systemFontOfSize:12];
    _scrollView.mj_footer = footer;
}

- (void)refreshData {
    [self loadHomeDataAndEndRefreshing:YES];
}

- (void)loadMoreScheduleMatches {
    [self fetchScheduleMatchesReset:NO];
}

- (void)loadHomeDataAndEndRefreshing:(BOOL)endRefreshing {
    self.homeDebugLoadStartAt = CACurrentMediaTime();
    NSLog(@"[HomeDebug] loadHomeData begin loggedIn=%d", AuthManager.sharedManager.isLoggedIn);
    if (AuthManager.sharedManager.isLoggedIn) {
        [self fetchUserProfile];
        [self fetchFollowTeamsThenSchedule:endRefreshing];
    } else {
        self.teamItems = @[];
        [self.teamCollectionView reloadData];
        [self refreshDiscoverLikeGuestState];
        [self fetchFeatureMatchs];
        [self fetchScheduleMatchesReset:YES];
        if (endRefreshing) {
            [self.scrollView.mj_header endRefreshing];
        }
    }
}

- (void)fetchFollowTeamsThenSchedule:(BOOL)endRefreshing {
    __weak typeof(self) weakSelf = self;
    [TeamsRequest.shared getFollowTeamIconsSuccess:^(HTTPResponse <NSArray <Team *> *>* _Nullable responseObject) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        NSArray *list = [responseObject.dataObject isKindOfClass:NSArray.class] ? responseObject.dataObject : @[];
        self.teamItems = list;
        NSString *kept = self.selectedTeamId;
        if (kept.length) {
            BOOL found = NO;
            for (Team *t in list) {
                if ([kHomeTeamIdString(t.teamId) isEqualToString:kept]) { found = YES; break; }
            }
            if (!found) self.selectedTeamId = nil;
        }
        [self ensureDefaultSelectedTeamIfNeeded];
        [self.teamCollectionView reloadData];
        [self fetchFeatureMatchs];
        [self fetchScheduleMatchesReset:YES];
        if (endRefreshing) {
            [self.scrollView.mj_header endRefreshing];
        }
        [self saveHomeOfflineCache];
    } failure:^(NSError * _Nonnull error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [self fetchFeatureMatchs];
        [self fetchScheduleMatchesReset:YES];
        if (endRefreshing) {
            [self.scrollView.mj_header endRefreshing];
        }
    }];
}

- (void)refreshDiscoverLikeGuestState {
    _challengerLabel.text = @"--";
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.locale = [NSLocale currentLocale];
    df.timeZone = [NSTimeZone localTimeZone];
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
    [self ensureDefaultSelectedTeamIfNeeded];
    NSString *teamId = self.selectedTeamId.length > 0 ? self.selectedTeamId : nil;
    [MatchRequest.shared getFeaturesMatchsWithTeamId:teamId success:^(HTTPResponse <NSArray <Match*> *>* _Nullable responseObject) {
        NSArray<Match *> *list = [responseObject.dataObject isKindOfClass:NSArray.class] ? responseObject.dataObject : @[];
        if (list.count > 30) {
            list = [list subarrayWithRange:NSMakeRange(0, 30)];
        }
        NSLog(@"[HomeDebug] featured callback count=%ld elapsed=%.3f",
              (long)list.count, CACurrentMediaTime() - self.homeDebugLoadStartAt);
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
        [self saveHomeOfflineCache];
    } failure:^(NSError * _Nonnull error) {
#if DEBUG
        NSLog(@"[HomeFeatured] failed error=%@", error);
#endif
        // 失败时保留已有精选卡（可能来自缓存），避免离线清空。
    }];
}

- (BOOL)home_match:(Match *)match involvesTeamId:(NSString *)teamId {
    if (teamId.length == 0 || !match) return NO;
    NSString *homeId = kHomeTeamIdString(match.homeTeamId);
    NSString *awayId = kHomeTeamIdString(match.awayTeamId);
    return [homeId isEqualToString:teamId] || [awayId isEqualToString:teamId];
}

- (NSArray<Match *> *)home_featuredScopeFromList:(NSArray<Match *> *)list {
    if (list.count == 0) return @[];
    if (_selectedTeamId.length == 0) return list;
    NSMutableArray<Match *> *teamOnly = [NSMutableArray array];
    for (Match *m in list) {
        if ([self home_match:m involvesTeamId:_selectedTeamId]) {
            [teamOnly addObject:m];
        }
    }
    return teamOnly.count > 0 ? [teamOnly copy] : list;
}

- (void)applyFeaturedList:(NSArray<Match *> *)list {
    if (list.count == 0) {
        self.highlightFinished = nil;
        self.highlightUpcoming = nil;
        [self buildTwoCards];
        return;
    }

    NSArray<Match *> *scope = [self home_featuredScopeFromList:list];
    Match *lastFinished = nil;
    Match *nextUpcoming = nil;
    for (Match *m in scope) {
        if ([self home_isMatchFinished:m]) {
            lastFinished = m;
        } else if (!nextUpcoming && [self home_isMatchUpcomingForFeatured:m]) {
            nextUpcoming = m;
        }
    }
    // 与服务端一致：左卡=上一场（已结束+比分），右卡=下一场（未开赛）
    self.highlightFinished = lastFinished;
    self.highlightUpcoming = nextUpcoming;

    [self buildTwoCards];
}

- (void)fetchScheduleMatchesReset:(BOOL)reset {
    if (self.isLoadingSchedule) return;
    if (!reset && !self.scheduleHasMore) {
        [self.scrollView.mj_footer endRefreshingWithNoMoreData];
        return;
    }
    self.isLoadingSchedule = YES;
    __weak typeof(self) weakSelf = self;
    [self ensureDefaultSelectedTeamIfNeeded];

    NSString *teamId = self.selectedTeamId.length > 0 ? self.selectedTeamId : nil;
    BOOL myTeamOnly = (teamId.length == 0 && AuthManager.sharedManager.isLoggedIn);
    NSInteger pageNum = reset ? 1 : MAX(self.scheduleCurrentPage + 1, 1);
    NSArray<Match *> *previous = [self.dataSource copy];
#if DEBUG
    NSLog(@"[HomeDebug] schedule page=%ld teamId=%@ myTeamOnly=%d pageSize=%ld",
          (long)pageNum, teamId ?: @"(nil)", myTeamOnly, (long)kHomeScheduleFetchPageSize);
    NSLog(@"[HomeDebug] schedule curl:\n%@",
          [self home_monthUpcomingScheduleCurlWithTeamId:teamId page:pageNum pageSize:kHomeScheduleFetchPageSize myTeamOnly:myTeamOnly]);
#endif
    [[MatchRequest shared] getMonthUpcomingScheduleWithStartTime:nil
                                                      myTeamOnly:myTeamOnly
                                                          teamId:teamId
                                                            page:pageNum
                                                        pageSize:kHomeScheduleFetchPageSize
                                                         success:^(HTTPResponse * _Nullable responseObject) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.isLoadingSchedule = NO;
        NSArray<Match *> *list = [responseObject.dataObject isKindOfClass:NSArray.class] ? responseObject.dataObject : @[];
        if (reset) {
            // 切换球队时服务端返回空列表即展示空，不能保留上一支球队的数据
            self.dataSource = [list mutableCopy];
        } else if (list.count > 0) {
            [self.dataSource addObjectsFromArray:list];
        }
        self.dataSource = [[self home_sanitizedMatchesForHome:self.dataSource maxCount:0] mutableCopy];
        self.scheduleCurrentPage = pageNum;
        self.scheduleHasMore = [self home_scheduleHasMoreFromResponse:responseObject
                                                              pageNum:pageNum
                                                             pageSize:kHomeScheduleFetchPageSize
                                                            listCount:list.count];
        NSLog(@"[HomeDebug] schedule page done page=%ld count=%ld batch=%ld hasMore=%d elapsed=%.3f",
              (long)pageNum, (long)self.dataSource.count, (long)list.count, self.scheduleHasMore,
              CACurrentMediaTime() - self.homeDebugLoadStartAt);
        [self filterData];
        [self updateTableHeight];
        [self saveHomeOfflineCache];
        [self.scrollView.mj_header endRefreshing];
        if (self.scheduleHasMore) {
            [self.scrollView.mj_footer endRefreshing];
            [self.scrollView.mj_footer resetNoMoreData];
        } else {
            [self.scrollView.mj_footer endRefreshingWithNoMoreData];
        }
    } failure:^(NSError * _Nonnull error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.isLoadingSchedule = NO;
        NSLog(@"[HomeDebug] schedule page failed page=%ld error=%@", (long)pageNum, error.localizedDescription);
        // 仅网络失败时保留旧数据；成功但为空已在 success 分支清空
        if (reset && previous.count > 0 && self.dataSource.count == 0) {
            self.dataSource = [previous mutableCopy];
            [self filterData];
            [self updateTableHeight];
        }
        [self.scrollView.mj_header endRefreshing];
        [self.scrollView.mj_footer endRefreshing];
    }];
}

- (void)fetchUserProfile {
    [UserRequest.shared getLoginUserInfoSuccess:^(HTTPResponse <User *>* _Nullable responseObject) {
        [self refreshUserProfile];
    } failure:^(NSError * _Nonnull error) {
    }];
}
- (void)refreshUserProfile {
    NSString *avatar = AuthManager.sharedManager.user.profile.avatar ?: AuthManager.sharedManager.user.avatar;
    [_avatarView sd_setImageWithURL:[NSURL URLWithString:avatar]];
    NSString *nickname = AuthManager.sharedManager.user.profile.nickname;
    _challengerLabel.text = nickname.length > 0 ? nickname : @"--";
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.locale = [NSLocale currentLocale];
    df.timeZone = [NSTimeZone localTimeZone];
    df.dateFormat = @"MMMM d, yyyy";
    _dateLabel.text = [df stringFromDate:[NSDate date]];
    [self saveHomeOfflineCache];
}

/// 后端 matchDate → NSDate（东八区）；展示用手机时区。
- (NSDate *)dateFromRaw:(NSString *)raw {
    return [PNBackendDateTime dateFromBackendString:raw];
}

- (NSString *)monthTextFromRaw:(NSString *)raw {
    NSDate *date = [self dateFromRaw:raw];
    if (!date) return @"-";
    NSDateFormatter *fmt = [PNBackendDateTime displayFormatter];
    fmt.locale = [NSLocale currentLocale];
    fmt.dateFormat = @"yyyy-MM";
    return [fmt stringFromDate:date];
}

- (NSString *)timeTextFromRaw:(NSString *)raw {
    NSDate *date = [self dateFromRaw:raw];
    if (!date) return @"--:--";
    NSDateFormatter *fmt = [PNBackendDateTime displayFormatter];
    fmt.locale = [NSLocale currentLocale];
    fmt.dateFormat = @"HH:mm";
    return [fmt stringFromDate:date];
}

- (NSString *)dateDetailFromRaw:(NSString *)raw {
    NSDate *date = [self dateFromRaw:raw];
    if (!date) return @"--";
    NSDateFormatter *fmt = [PNBackendDateTime displayFormatter];
    fmt.dateFormat = @"yyyy年MM月dd日";
    return [fmt stringFromDate:date];
}

#pragma mark - UICollectionView
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _teamItems.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HomeTeamCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TeamCell" forIndexPath:indexPath];
    Team *item = _teamItems[indexPath.item];
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
    Team *item = _teamItems[indexPath.item];
    NSString *tid = kHomeTeamIdString(item.teamId);
    if (tid.length == 0) { return; }
    if ([tid isEqualToString:_selectedTeamId]) { return; }
    _selectedTeamId = [tid copy];
    [collectionView reloadData];
    self.scheduleCurrentPage = 0;
    self.scheduleHasMore = YES;
    // 切换球队时先清空列表，避免短暂展示上一支球队数据
    [self.dataSource removeAllObjects];
    [self filterData];
    [self fetchFeatureMatchs];
    [self fetchScheduleMatchesReset:YES];
    [self saveHomeOfflineCache];
}

#pragma mark - UITableView（按日期倒序、分组）
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

/// 精选右卡「下一场」：未开赛且非进行中（与赛程 VS 判定一致）
- (BOOL)home_isMatchUpcomingForFeatured:(Match *)match {
    if ([self home_isMatchFinished:match]) {
        return NO;
    }
    return [self home_isMatchNotYetStartedForDisplay:match];
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

/// 按 matchId 定位当前分组表中的 indexPath（数据刷新后仍可用）
- (nullable NSIndexPath *)home_indexPathForMatchId:(NSString *)matchId {
    if (matchId.length == 0 || self.sortedDateKeys.count == 0) {
        return nil;
    }
    for (NSInteger section = 0; section < (NSInteger)self.sortedDateKeys.count; section++) {
        NSArray<Match *> *rows = self.groupedMatches[self.sortedDateKeys[section]];
        for (NSInteger row = 0; row < (NSInteger)rows.count; row++) {
            if ([rows[row].matchId isEqualToString:matchId]) {
                return [NSIndexPath indexPathForRow:row inSection:section];
            }
        }
    }
    return nil;
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
    NSString *matchId = match.matchId;
    sender.enabled = NO;
    __weak typeof(self) weakSelf = self;
    __weak UIButton *weakBtn = sender;
    void (^reloadRow)(void) = ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        weakBtn.enabled = YES;
        NSIndexPath *ip = [self home_indexPathForMatchId:matchId];
        if (!ip) {
            return;
        }
        if (ip.section >= [self.tableView numberOfSections] ||
            ip.row >= [self.tableView numberOfRowsInSection:ip.section]) {
            return;
        }
        [self.tableView reloadRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationNone];
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
