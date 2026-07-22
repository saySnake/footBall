//
//  MoreMatchesViewController.m
//  footBall
//

#import "MoreMatchesViewController.h"
#import "MoreDatePickerController.h"
#import "APIError.h"
#import <Masonry/Masonry.h>

static UIColor *kMoreMatchesCardBG(void) {
    return [UIColor colorWithRed:0.965 green:0.965 blue:0.965 alpha:1.0]; // #f6f6f6
}

static UIColor *kMoreMatchesWeekdayText(void) {
    return [UIColor colorWithRed:0.612 green:0.643 blue:0.671 alpha:1.0]; // #9CA4AB
}

static UIColor *kMoreMatchesDateText(void) {
    return [UIColor colorWithRed:0.345 green:0.255 blue:0.255 alpha:1.0]; // #584141
}

static UIColor *kMoreMatchesGreen(void) {
    return [UIColor colorWithRed:0.157 green:0.365 blue:0.294 alpha:1.0]; // #285D4B
}

static UIColor *kMoreMatchesTeamBadgeBg(void) {
    return [UIColor colorWithRed:0.914 green:0.922 blue:0.929 alpha:1.0]; // #E9EBED
}

static UIColor *kMoreMatchesPrimaryText(void) {
    return [UIColor colorWithRed:0.059 green:0.059 blue:0.059 alpha:1.0]; // #0f0f0f
}

static UIImage *kMoreMatchesCalendarBarIcon(void) {
    UIImage *asset = [UIImage imageNamed:@"Calendar"];
    if (asset) {
        return [asset imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:24 weight:UIImageSymbolWeightRegular];
        return [[UIImage systemImageNamed:@"calendar" withConfiguration:cfg] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    return nil;
}

/// 解析比赛时间：无时区后缀按东八区（Asia/Shanghai）；展示侧再用系统时区。
static NSDate *kMoreMatchesDateFromRawString(NSString *raw) {
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
    // Unix 时间戳带小数秒：整串须能完整 scan 为 double，避免 ISO 串里的毫秒被误当成数字
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

    // 带时区的 ISO（含 Z / 偏移）
    if (@available(iOS 11.0, *)) {
        NSISO8601DateFormatter *iso = [[NSISO8601DateFormatter alloc] init];
        iso.formatOptions = NSISO8601DateFormatWithInternetDateTime | NSISO8601DateFormatWithFractionalSeconds;
        NSDate *d = [iso dateFromString:s];
        if (d) return d;
        iso.formatOptions = NSISO8601DateFormatWithInternetDateTime;
        d = [iso dateFromString:s];
        if (d) return d;
    }

    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];

    NSArray<NSString *> *zonedFormats = @[
        @"yyyy-MM-dd'T'HH:mm:ssZ",
        @"yyyy-MM-dd'T'HH:mm:ss.SSSZ",
        @"yyyy-MM-dd'T'HH:mm:ssXXX",
        @"yyyy-MM-dd'T'HH:mm:ss.SSSXXX",
        @"yyyy-MM-dd'T'HH:mm:ss'Z'",
        @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
    ];
    for (NSString *f in zonedFormats) {
        fmt.dateFormat = f;
        fmt.timeZone = nil;
        NSDate *d = [fmt dateFromString:s];
        if (d) return d;
    }

    // 无时区墙钟：后端约定 UTC+8，如 2026-04-25T03:00:00
    NSTimeZone *shanghai = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"] ?: [NSTimeZone timeZoneForSecondsFromGMT:8 * 3600];
    fmt.timeZone = shanghai;
    NSArray<NSString *> *naiveFormats = @[
        @"yyyy-MM-dd'T'HH:mm:ss.SSS",
        @"yyyy-MM-dd'T'HH:mm:ss",
        @"yyyy-MM-dd'T'HH:mm",
        @"yyyy-MM-dd HH:mm:ss.SSS",
        @"yyyy-MM-dd HH:mm:ss",
        @"yyyy-MM-dd HH:mm",
        @"yyyy/MM/dd HH:mm:ss",
        @"yyyy/MM/dd HH:mm",
        @"yyyy-MM-dd",
    ];
    for (NSString *f in naiveFormats) {
        fmt.dateFormat = f;
        NSDate *d = [fmt dateFromString:s];
        if (d) return d;
    }
    return nil;
}

/// 比赛行右侧收藏图标：优先使用资源图 match_star，缺失时回退 SF Symbol。
static UIImage *kMoreMatchesFavoriteIcon(BOOL favorited) {
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

@interface MoreMatchCell : UITableViewCell
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIView *homeBadge;
@property (nonatomic, strong) UIView *awayBadge;
@property (nonatomic, strong) UIImageView *homeLogo;
@property (nonatomic, strong) UIImageView *awayLogo;
@property (nonatomic, strong) UILabel *homeLabel;
@property (nonatomic, strong) UILabel *awayLabel;
@property (nonatomic, strong) UIButton *timePill;
@property (nonatomic, strong) UIButton *favoriteBtn;
@end

@implementation MoreMatchCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;

        UIView *card = [[UIView alloc] init];
        card.backgroundColor = kMoreMatchesCardBG();
        card.layer.cornerRadius = 8;
        card.clipsToBounds = YES;
        card.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
        [self.contentView addSubview:card];
        self.cardView = card;
        [card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(6, 16, 6, 16));
        }];

        _homeBadge = [[UIView alloc] init];
        _homeBadge.backgroundColor = kMoreMatchesTeamBadgeBg();
        _homeBadge.layer.cornerRadius = 16;
        _homeBadge.clipsToBounds = YES;
        _awayBadge = [[UIView alloc] init];
        _awayBadge.backgroundColor = kMoreMatchesTeamBadgeBg();
        _awayBadge.layer.cornerRadius = 16;
        _awayBadge.clipsToBounds = YES;

        _homeLogo = [[UIImageView alloc] init];
        _awayLogo = [[UIImageView alloc] init];
        _homeLogo.contentMode = _awayLogo.contentMode = UIViewContentModeScaleAspectFit;
        _homeLogo.backgroundColor = [UIColor clearColor];
        _awayLogo.backgroundColor = [UIColor clearColor];

        _homeLabel = [[UILabel alloc] init];
        _awayLabel = [[UILabel alloc] init];
        _homeLabel.font = _awayLabel.font = [UIFont systemFontOfSize:24/2.0 weight:UIFontWeightSemibold];
        _homeLabel.adjustsFontSizeToFitWidth = YES;
        _homeLabel.textColor = _awayLabel.textColor = kMoreMatchesPrimaryText();
        _homeLabel.textAlignment = NSTextAlignmentRight;
        _awayLabel.textAlignment = NSTextAlignmentLeft;
        _awayLabel.adjustsFontSizeToFitWidth = YES;
        _homeLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _awayLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _homeLabel.adjustsFontSizeToFitWidth = NO;
        _awayLabel.adjustsFontSizeToFitWidth = NO;
        [_homeLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [_awayLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [_homeLabel setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [_awayLabel setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];

        _timePill = [UIButton buttonWithType:UIButtonTypeSystem];
        _timePill.userInteractionEnabled = NO;
        _timePill.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        [_timePill setTitleColor:kMoreMatchesGreen() forState:UIControlStateNormal];
        _timePill.layer.cornerRadius = 14;
        _timePill.layer.borderWidth = 0.5;
        _timePill.layer.borderColor = kMoreMatchesGreen().CGColor;
        _timePill.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10);
        _timePill.backgroundColor = [UIColor colorWithRed:0.973 green:0.980 blue:0.969 alpha:1.0];

        _favoriteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _favoriteBtn.adjustsImageWhenHighlighted = NO;

        [card addSubview:_homeLabel];
        [card addSubview:_homeBadge];
        [_homeBadge addSubview:_homeLogo];
        [card addSubview:_timePill];
        [card addSubview:_awayBadge];
        [_awayBadge addSubview:_awayLogo];
        [card addSubview:_awayLabel];
        [card addSubview:_favoriteBtn];

        [_homeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(card).offset(12);
            make.centerY.equalTo(card);
            make.right.lessThanOrEqualTo(_homeBadge.mas_left).offset(-6);
            make.width.mas_lessThanOrEqualTo(120);
        }];
        [_homeBadge mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(_timePill.mas_left).offset(-10);
            make.centerY.equalTo(card);
            make.width.height.mas_equalTo(32);
        }];
        [_homeLogo mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(_homeBadge);
            make.width.height.mas_equalTo(18);
        }];
        [_timePill mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(card);
            make.centerY.equalTo(card);
            make.width.mas_equalTo(64);
            make.height.mas_equalTo(28);
        }];
        [_timePill setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [_timePill setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
        [_favoriteBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(card).offset(-16);
            make.centerY.equalTo(card);
            make.width.height.mas_equalTo(20);
        }];
        [_awayBadge mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_timePill.mas_right).offset(10);
            make.centerY.equalTo(card);
            make.width.height.mas_equalTo(32);
        }];
        [_awayLogo mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(_awayBadge);
            make.width.height.mas_equalTo(18);
        }];
        [_awayLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_awayBadge.mas_right).offset(6);
            make.centerY.equalTo(card);
            make.right.lessThanOrEqualTo(_favoriteBtn.mas_left).offset(-10);
            make.width.mas_lessThanOrEqualTo(120);
        }];
    }
    return self;
}

@end

@interface MoreMatchDayView : UIControl
@property (nonatomic, strong) UIView *selectionBackgroundView;
@property (nonatomic, strong) UILabel *weekdayLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@end

@implementation MoreMatchDayView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.selectionBackgroundView = [[UIView alloc] init];
        self.selectionBackgroundView.backgroundColor = kMoreMatchesGreen();
        self.selectionBackgroundView.layer.cornerRadius = 6.0;
        self.selectionBackgroundView.hidden = YES;

        self.weekdayLabel = [[UILabel alloc] init];
        self.weekdayLabel.textAlignment = NSTextAlignmentCenter;
        self.weekdayLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
        self.weekdayLabel.textColor = kMoreMatchesWeekdayText();

        self.dateLabel = [[UILabel alloc] init];
        self.dateLabel.textAlignment = NSTextAlignmentCenter;
        self.dateLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        self.dateLabel.textColor = kMoreMatchesDateText();

        [self addSubview:self.selectionBackgroundView];
        [self addSubview:self.weekdayLabel];
        [self addSubview:self.dateLabel];

        [self.selectionBackgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
            make.width.mas_equalTo(38);
            make.height.mas_equalTo(56);
        }];
        [self.weekdayLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.selectionBackgroundView).offset(6);
            make.centerX.equalTo(self.selectionBackgroundView);
        }];
        [self.dateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.weekdayLabel.mas_bottom).offset(2);
            make.centerX.equalTo(self.selectionBackgroundView);
        }];
    }
    return self;
}

@end

#pragma mark - MoreMatchesViewController

static NSInteger const kMoreMatchesPageSize = 50;

@interface MoreMatchesViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UIView *topBar;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *calendarButton;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *monthLabel;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<Match *> *matches;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) BOOL hasMore;
@property (nonatomic, assign) BOOL isLoadingSchedule;
@property (nonatomic, assign) NSUInteger scheduleRequestToken;
@property (nonatomic, strong) NSDate *selectedDate;        // 当前选中的日期（默认今天）
@property (nonatomic, strong) NSDate *weekStartDate;       // 当前周的周日日期
@property (nonatomic, strong) NSCalendar *calendar;
@property (nonatomic, strong) NSArray<UIControl *> *weekDayViews;
@end

@implementation MoreMatchesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hidesBottomBarWhenPushed = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    // 使用自定义顶部栏，而不是系统导航栏
    self.shouldShowNavigationBar = NO;

    // 默认选中今天，使用公历并固定以周日为一周第一天
    self.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    self.calendar.firstWeekday = 1;
    self.calendar.timeZone = [NSTimeZone localTimeZone];
    self.selectedDate = [NSDate date];
    self.matches = [NSMutableArray array];
    self.currentPage = 1;
    self.hasMore = YES;

    [self buildTopBar];
    [self buildHeader];
    [self buildTable];
    [self reloadDataForSelectedDate];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 进入「更多比赛」时隐藏底部导航
    self.tabBarController.tabBar.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // 返回首页或其它页面时恢复底部导航
    self.tabBarController.tabBar.hidden = NO;
}

- (void)buildTopBar {
    UIView *bar = [[UIView alloc] init];
    bar.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:bar];
    self.topBar = bar;

    UIButton *back = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImage *backImage = [[UIImage imageNamed:@"nav_back"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    if (!backImage) {
        backImage = [UIImage imageNamed:@"left"];
        backImage = [backImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    if (!backImage && @available(iOS 13.0, *)) {
        backImage = [UIImage systemImageNamed:@"chevron.left"];
    }
    [back setImage:backImage forState:UIControlStateNormal];
    back.tintColor = [UIColor blackColor];
    [back addTarget:self action:@selector(onBack) forControlEvents:UIControlEventTouchUpInside];

    UIButton *calendar = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImage *calendarImage = kMoreMatchesCalendarBarIcon();
    if (calendarImage) {
        [calendar setImage:calendarImage forState:UIControlStateNormal];
    }
    calendar.tintColor = [UIColor blackColor];
    [calendar addTarget:self action:@selector(onCalendar) forControlEvents:UIControlEventTouchUpInside];

    UILabel *title = [[UILabel alloc] init];
    title.text = NSLocalizedString(@"more_matches_title", nil) ?: @"更多比赛";
    title.font = [UIFont boldSystemFontOfSize:18];
    title.textAlignment = NSTextAlignmentCenter;
    title.textColor = [UIColor blackColor];

    [bar addSubview:back];
    [bar addSubview:calendar];
    [bar addSubview:title];
    self.backButton = back;
    self.calendarButton = calendar;
    self.titleLabel = title;

    [bar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.leading.trailing.equalTo(self.view);
        make.height.mas_equalTo(44);
    }];
    [back mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(bar).offset(16);
        make.centerY.equalTo(bar);
        make.width.height.mas_equalTo(24);
    }];
    [calendar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(bar).offset(-16);
        make.centerY.equalTo(bar);
        make.width.height.mas_equalTo(24);
    }];
    [title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(bar);
        make.centerY.equalTo(bar);
    }];
}

- (void)buildHeader {
    UIView *header = [[UIView alloc] init];
    header.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:header];

    self.monthLabel = [[UILabel alloc] init];
    self.monthLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    self.monthLabel.textAlignment = NSTextAlignmentCenter;
    self.monthLabel.textColor = [UIColor blackColor];
    [header addSubview:self.monthLabel];

    NSArray *weekTitles = @[ @"周日", @"周一", @"周二", @"周三", @"周四", @"周五", @"周六" ];
    UIView *weekRow = [[UIView alloc] init];
    [header addSubview:weekRow];

    [header mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.topBar.mas_bottom);
        make.leading.trailing.equalTo(self.view);
    }];
    [self.monthLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(header).offset(10);
        make.centerX.equalTo(header);
    }];
    [weekRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.monthLabel.mas_bottom).offset(10);
        make.leading.trailing.equalTo(header);
        make.height.mas_equalTo(56);
        make.bottom.equalTo(header).offset(-8);
    }];

    CGFloat width = [UIScreen mainScreen].bounds.size.width / 7.0;
    NSMutableArray<UIControl *> *views = [NSMutableArray array];
    for (NSInteger i = 0; i < 7; i++) {
        MoreMatchDayView *day = [[MoreMatchDayView alloc] initWithFrame:CGRectZero];
        day.backgroundColor = [UIColor clearColor];
        day.tag = i;
        [day addTarget:self action:@selector(onWeekTapped:) forControlEvents:UIControlEventTouchUpInside];
        [weekRow addSubview:day];
        day.weekdayLabel.text = weekTitles[i];

        [day mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(weekRow);
            make.width.mas_equalTo(width);
            make.leading.equalTo(weekRow.mas_leading).offset(width * i);
        }];

        [views addObject:day];
    }
    self.weekDayViews = views;

    [self updateWeekHeaderForSelectedDate];
}

- (void)buildTable {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor whiteColor];
    [self.tableView registerClass:[MoreMatchCell class] forCellReuseIdentifier:@"MoreMatchCell"];
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.contentInset = UIEdgeInsetsMake(8, 0, 16, 0);
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.monthLabel.superview.mas_bottom);
        make.leading.trailing.bottom.equalTo(self.view);
    }];

    __weak typeof(self) weakSelf = self;
    MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
        [weakSelf loadMoreMatches];
    }];
    footer.stateLabel.font = [UIFont systemFontOfSize:13];
    footer.stateLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    footer.hidden = YES;
    self.tableView.mj_footer = footer;
}

- (NSInteger)moreMatches_totalFromPageData:(id)data {
    if (![data isKindOfClass:NSDictionary.class]) return 0;
    NSDictionary *d = (NSDictionary *)data;
    id total = d[@"total"] ?: d[@"totalCount"] ?: d[@"totalElements"];
    if ([total respondsToSelector:@selector(longLongValue)]) {
        return (NSInteger)[total longLongValue];
    }
    return 0;
}

- (NSArray<Match *> *)moreMatches_sortedMatches:(NSArray *)matches {
    return [matches sortedArrayUsingComparator:^NSComparisonResult(Match *obj1, Match *obj2) {
        NSString *d1 = obj1.matchDate ?: @"";
        NSString *d2 = obj2.matchDate ?: @"";
        return [d1 compare:d2];
    }];
}

- (void)moreMatches_updateFooterState {
    MJRefreshAutoNormalFooter *footer = (MJRefreshAutoNormalFooter *)self.tableView.mj_footer;
    if (!footer) return;
    footer.hidden = (self.matches.count == 0 && !self.hasMore);
    [footer endRefreshing];
    if (!self.hasMore && self.matches.count > 0) {
        [footer endRefreshingWithNoMoreData];
    }
}

- (void)reloadDataForSelectedDate {
    self.scheduleRequestToken += 1;
    self.currentPage = 1;
    self.hasMore = YES;
    self.isLoadingSchedule = NO;
    [self.matches removeAllObjects];
    [self.tableView reloadData];
    [self.tableView.mj_footer resetNoMoreData];
    self.tableView.mj_footer.hidden = YES;
    [self fetchSchedulePage:1 append:NO];
}

- (void)loadMoreMatches {
    if (!self.hasMore || self.isLoadingSchedule) {
        [self.tableView.mj_footer endRefreshing];
        return;
    }
    [self fetchSchedulePage:self.currentPage + 1 append:YES];
}

- (void)fetchSchedulePage:(NSInteger)page append:(BOOL)append {
    if (self.isLoadingSchedule) {
        if (append) {
            [self.tableView.mj_footer endRefreshing];
        }
        return;
    }
    if (!self.selectedDate) self.selectedDate = [NSDate date];

    self.isLoadingSchedule = YES;
    NSUInteger requestToken = self.scheduleRequestToken;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    NSString *dateStr = [formatter stringFromDate:self.selectedDate];

    __weak typeof(self) weakSelf = self;
    [[MatchRequest shared] getMatchScheduleWithDate:dateStr
                                         myTeamOnly:NO
                                               page:page
                                           pageSize:kMoreMatchesPageSize
                                            success:^(HTTPResponse * _Nullable responseObject) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || requestToken != self.scheduleRequestToken) return;
        self.isLoadingSchedule = NO;

        NSArray *raw = [responseObject.dataObject isKindOfClass:NSArray.class] ? responseObject.dataObject : @[];
        NSArray<Match *> *sorted = [self moreMatches_sortedMatches:raw];
        if (append) {
            [self.matches addObjectsFromArray:sorted];
        } else {
            [self.matches removeAllObjects];
            [self.matches addObjectsFromArray:sorted];
        }
        self.currentPage = page;

        NSInteger total = [self moreMatches_totalFromPageData:responseObject.data];
        if (total > 0) {
            self.hasMore = self.matches.count < total;
        } else {
            self.hasMore = sorted.count >= kMoreMatchesPageSize;
        }

        [self.tableView reloadData];
        [self moreMatches_updateFooterState];
    } failure:^(NSError * _Nonnull error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || requestToken != self.scheduleRequestToken) return;
        self.isLoadingSchedule = NO;
        if (append) {
            [self.tableView.mj_footer endRefreshing];
        } else {
            [self.matches removeAllObjects];
            [self.tableView reloadData];
            self.tableView.mj_footer.hidden = YES;
        }
    }];
}

- (NSString *)timeTextFromMatchDate:(NSString *)matchDate {
    NSDate *date = kMoreMatchesDateFromRawString(matchDate);
    if (!date) return @"--:--";
    NSDateFormatter *output = [[NSDateFormatter alloc] init];
    output.timeZone = [NSTimeZone localTimeZone];
    output.dateFormat = @"HH:mm";
    return [output stringFromDate:date];
}

- (UIImage *)matchPlaceholderLogo {
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightRegular];
        return [UIImage systemImageNamed:@"shield" withConfiguration:cfg];
    }
    return nil;
}

- (void)updateWeekHeaderForSelectedDate {
    if (!self.selectedDate || self.weekDayViews.count == 0) return;

    // 以周日为一周第一天，手动计算本周周日作为起始，避免不同地区 firstWeekday 差异
    NSDateComponents *weekdayComp = [self.calendar components:NSCalendarUnitWeekday fromDate:self.selectedDate];
    NSInteger weekday = weekdayComp.weekday; // 1=Sun..7=Sat
    NSInteger daysToSubtract = weekday - 1;  // 回退到周日（0 表示本身是周日）
    NSDate *startOfWeek = [self.calendar dateByAddingUnit:NSCalendarUnitDay
                                                    value:-daysToSubtract
                                                   toDate:self.selectedDate
                                                  options:0];
    self.weekStartDate = startOfWeek ?: self.selectedDate;

    NSDateFormatter *monthFmt = [[NSDateFormatter alloc] init];
    monthFmt.dateFormat = @"yyyy年MM月";
    self.monthLabel.text = [monthFmt stringFromDate:self.selectedDate];

    NSDateFormatter *dayFmt = [[NSDateFormatter alloc] init];
    dayFmt.dateFormat = @"d";

    for (NSInteger i = 0; i < self.weekDayViews.count; i++) {
        MoreMatchDayView *dayView = (MoreMatchDayView *)self.weekDayViews[i];
        NSDate *date = [self.calendar dateByAddingUnit:NSCalendarUnitDay value:i toDate:self.weekStartDate options:0];
        NSString *dayString = [dayFmt stringFromDate:date];
        dayView.dateLabel.text = dayString;

        // 高亮当前选中的那一天
        BOOL isSameDay = [self isSameDay:date other:self.selectedDate];
        if (isSameDay) {
            dayView.selectionBackgroundView.hidden = NO;
            dayView.weekdayLabel.textColor = [UIColor whiteColor];
            dayView.dateLabel.textColor = [UIColor whiteColor];
            dayView.dateLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        } else {
            dayView.selectionBackgroundView.hidden = YES;
            dayView.weekdayLabel.textColor = kMoreMatchesWeekdayText();
            dayView.dateLabel.textColor = kMoreMatchesDateText();
            dayView.dateLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        }
    }
}

- (BOOL)isSameDay:(NSDate *)a other:(NSDate *)b {
    if (!a || !b) return NO;
    NSDateComponents *c1 = [self.calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:a];
    NSDateComponents *c2 = [self.calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:b];
    return (c1.year == c2.year && c1.month == c2.month && c1.day == c2.day);
}

#pragma mark - Actions

- (void)onBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onCalendar {
    MoreDatePickerController *vc = [MoreDatePickerController new];
    vc.selectedDate = self.selectedDate;
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    __weak typeof(self) weakSelf = self;
    vc.onConfirm = ^(NSDate *date) {
        weakSelf.selectedDate = date;
        [weakSelf updateWeekHeaderForSelectedDate];
        [weakSelf reloadDataForSelectedDate];
    };
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)onWeekTapped:(UIControl *)sender {
    // 点击某一天：更新选中日期并刷新头部
    NSInteger index = sender.tag;
    if (self.weekStartDate) {
        NSDate *date = [self.calendar dateByAddingUnit:NSCalendarUnitDay value:index toDate:self.weekStartDate options:0];
        self.selectedDate = date;
        [self updateWeekHeaderForSelectedDate];
        [self reloadDataForSelectedDate];
    }
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.matches.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 66;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MoreMatchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MoreMatchCell" forIndexPath:indexPath];
    Match *m = self.matches[indexPath.row];
    cell.homeLabel.text = m.homeTeamName ?: @"-";
    cell.awayLabel.text = m.awayTeamName ?: @"-";
    [cell.timePill setTitle:[self timeTextFromMatchDate:m.matchDate] forState:UIControlStateNormal];
    UIImage *placeholder = [self matchPlaceholderLogo];
    [cell.homeLogo sd_setImageWithURL:(m.homeTeamLogo.length > 0 ? [NSURL URLWithString:m.homeTeamLogo] : nil) placeholderImage:placeholder];
    [cell.awayLogo sd_setImageWithURL:(m.awayTeamLogo.length > 0 ? [NSURL URLWithString:m.awayTeamLogo] : nil) placeholderImage:placeholder];
    UIImage *starImg = kMoreMatchesFavoriteIcon(m.favorited);
    [cell.favoriteBtn setImage:starImg forState:UIControlStateNormal];
    if (m.favorited) {
        cell.favoriteBtn.tintColor = [UIColor clearColor];
        cell.favoriteBtn.alpha = 1.0;
    } else {
        cell.favoriteBtn.tintColor = [UIColor colorWithWhite:0.45 alpha:1.0];
        cell.favoriteBtn.alpha = 0.55;
    }
    cell.favoriteBtn.tag = indexPath.row;
    [cell.favoriteBtn removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [cell.favoriteBtn addTarget:self action:@selector(onFavoriteTapped:) forControlEvents:UIControlEventTouchUpInside];
    return cell;
}

- (NSString *)moreMatches_errorText:(NSError *)error defaultText:(NSString *)def {
    if ([error isKindOfClass:[APIError class]]) {
        APIError *ae = (APIError *)error;
        if (ae.businessMessage.length > 0) return ae.businessMessage;
    }
    NSString *msg = error.localizedDescription;
    return msg.length > 0 ? msg : def;
}

- (void)onFavoriteTapped:(UIButton *)sender {
    NSInteger index = sender.tag;
    if (index < 0 || index >= self.matches.count) return;
    Match *match = self.matches[index];
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
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        if (index < self.matches.count) {
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }
    };

    if (match.favorited) {
        [[MatchRequest shared] unfavoriteMatch:match.matchId success:^(HTTPResponse * _Nullable responseObject) {
            match.favorited = NO;
            reloadRow();
        } failure:^(NSError * _Nonnull error) {
            weakBtn.enabled = YES;
            __strong typeof(weakSelf) self = weakSelf;
            [QMUITips showError:[self moreMatches_errorText:error defaultText:@"取消收藏失败"]];
        }];
    } else {
        [[MatchRequest shared] favoriteMatch:match.matchId success:^(HTTPResponse * _Nullable responseObject) {
            match.favorited = YES;
            reloadRow();
        } failure:^(NSError * _Nonnull error) {
            weakBtn.enabled = YES;
            __strong typeof(weakSelf) self = weakSelf;
            [QMUITips showError:[self moreMatches_errorText:error defaultText:@"收藏失败"]];
        }];
    }
}

@end

