//
//  DiscoverViewController.m
//  footBall
//

#import "DiscoverViewController.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>
#import "PNAddConsumeViewController.h"
#import "PNMatchVerifyViewController.h"
#import "ConsumptionRecordViewController.h"
#import "PassportViewController.h"
#import "PassportSheetsViewController.h"
#import "PNMatchDetailViewController.h"
#import "PNMatchInfoInputViewController.h"
#import "AuthManager.h"
#import "User.h"
#import "StatisticsModels.h"

#define kDiscoverHeaderBg     [UIColor colorWithRed:0.051 green:0.129 blue:0.133 alpha:1.0]   // #0D2122
#define kDiscoverGreen        [UIColor colorWithRed:0.157 green:0.365 blue:0.294 alpha:1.0]   // #285D4B
#define kDiscoverPillGreen    kDiscoverGreen
#define kDiscoverCardBg       [UIColor colorWithRed:0.976 green:0.976 blue:0.976 alpha:1.0]   // #F9F9F9
#define kDiscoverCellBg       [UIColor colorWithRed:0.961 green:0.961 blue:0.961 alpha:1.0]   // #F5F5F5 未来观赛卡片
#define kDiscoverFinishedCardBg [UIColor colorWithRed:0.957 green:0.957 blue:0.957 alpha:1.0]   // #F4F4F4 已经观赛卡片（Figma 1:7162）

typedef NS_ENUM(NSInteger, DiscoverMatchType) {
    DiscoverMatchTypeUpcoming,
    DiscoverMatchTypeFinished
};

/// 与 MoreMatches 一致的比赛时间字符串解析（多字段名见 Match.m）
static NSDate *DiscoverDateFromRawString(NSString *raw) {
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
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
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
    for (NSString *f in formats) {
        fmt.dateFormat = f;
        NSDate *d = [fmt dateFromString:s];
        if (d) return d;
    }
    return nil;
}

@interface DiscoverMatch : NSObject
@property (nonatomic, copy) NSString *matchId;
@property (nonatomic, copy) NSString *homeName;
@property (nonatomic, copy) NSString *awayName;
/// 比赛时间（HH:mm），用于中间时间胶囊
@property (nonatomic, copy) NSString *timeText;
@property (nonatomic, copy) NSString *dateText;
@property (nonatomic, copy) NSString *scoreText;
@property (nonatomic, copy) NSString *verifiedText;
/// 是否已经完成“输入信息”
@property (nonatomic, assign) BOOL hasInputInfo;
/// 是否已经完成“认证比赛”
@property (nonatomic, assign) BOOL hasVerified;
@property (nonatomic, assign) DiscoverMatchType type;
@property (nonatomic, copy) NSString *homeLogoURL;
@property (nonatomic, copy) NSString *awayLogoURL;
@end

@implementation DiscoverMatch
@end

@interface DiscoverMatchCell : UITableViewCell
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIImageView *homeLogo;
@property (nonatomic, strong) UIImageView *awayLogo;
@property (nonatomic, strong) UIImageView *middleBadge;
@property (nonatomic, strong) UILabel *homeLabel;
@property (nonatomic, strong) UILabel *awayLabel;
@property (nonatomic, strong) UILabel *scoreLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UIButton *inputButton;
@property (nonatomic, strong) UIButton *verifiedPill;
@end

@implementation DiscoverMatchCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];

        UIView *card = [[UIView alloc] init];
        card.backgroundColor = kDiscoverCellBg;
        card.layer.cornerRadius = 8;
        [self.contentView addSubview:card];
        self.cardView = card;
        [card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(5, 16, 5, 16));
        }];

        _homeLogo = [[UIImageView alloc] init];
        _homeLogo.backgroundColor = [UIColor clearColor];
        _homeLogo.layer.cornerRadius = 12;
        _homeLogo.clipsToBounds = YES;
        _homeLogo.contentMode = UIViewContentModeScaleAspectFit;
        _awayLogo = [[UIImageView alloc] init];
        _awayLogo.backgroundColor = [UIColor clearColor];
        _awayLogo.layer.cornerRadius = 12;
        _awayLogo.clipsToBounds = YES;
        _awayLogo.contentMode = UIViewContentModeScaleAspectFit;

        _middleBadge = [[UIImageView alloc] init];
        _middleBadge.contentMode = UIViewContentModeScaleAspectFit;

        _homeLabel = [[UILabel alloc] init];
        _homeLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        _homeLabel.textColor = [UIColor colorWithRed:0.208 green:0.200 blue:0.208 alpha:1.0]; // #353335
        _homeLabel.textAlignment = NSTextAlignmentRight;
        _awayLabel = [[UILabel alloc] init];
        _awayLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        _awayLabel.textColor = [UIColor colorWithRed:0.208 green:0.200 blue:0.208 alpha:1.0]; // #353335
        _awayLabel.textAlignment = NSTextAlignmentLeft;
        _homeLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _awayLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _homeLabel.adjustsFontSizeToFitWidth = YES;
        _awayLabel.adjustsFontSizeToFitWidth = YES;
        _homeLabel.minimumScaleFactor = 0.75f;
        _awayLabel.minimumScaleFactor = 0.75f;

        _scoreLabel = [[UILabel alloc] init];
        _scoreLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        _scoreLabel.textColor = kDiscoverGreen;
        _scoreLabel.textAlignment = NSTextAlignmentCenter;
        _scoreLabel.layer.cornerRadius = 12;
        _scoreLabel.layer.borderWidth = 0.5;
        _scoreLabel.layer.borderColor = kDiscoverGreen.CGColor;
        _scoreLabel.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.18];
        _scoreLabel.clipsToBounds = YES;

        _dateLabel = [[UILabel alloc] init];
        _dateLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        _dateLabel.textColor = [UIColor colorWithWhite:0.47 alpha:1.0]; // #787878
        _dateLabel.textAlignment = NSTextAlignmentCenter;

        _inputButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _inputButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [_inputButton setTitle:(NSLocalizedString(@"discover_input_info", nil) ?: @"输入信息") forState:UIControlStateNormal];
        [_inputButton setTitleColor:[UIColor colorWithRed:0.192 green:0.192 blue:0.192 alpha:1.0] forState:UIControlStateNormal]; // #313131
        _inputButton.layer.cornerRadius = 13;
        _inputButton.layer.borderWidth = 0.5;
        _inputButton.layer.borderColor = [UIColor blackColor].CGColor;
        [_inputButton setImage:[UIImage imageNamed:@"edit_icon"] forState:UIControlStateNormal];
        _inputButton.tintColor = [UIColor colorWithRed:0.192 green:0.192 blue:0.192 alpha:1.0];
        _inputButton.imageEdgeInsets = UIEdgeInsetsMake(0, -4, 0, 0);

        _verifiedPill = [UIButton buttonWithType:UIButtonTypeSystem];
        _verifiedPill.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        _verifiedPill.layer.cornerRadius = 13;
        _verifiedPill.backgroundColor = kDiscoverPillGreen;
        [_verifiedPill setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_verifiedPill setImage:[UIImage imageNamed:@"verified_icon"] forState:UIControlStateNormal];
        _verifiedPill.tintColor = [UIColor whiteColor];
        _verifiedPill.imageEdgeInsets = UIEdgeInsetsMake(0, -4, 0, 0);

        [card addSubview:_homeLogo];
        [card addSubview:_homeLabel];
        [card addSubview:_awayLogo];
        [card addSubview:_awayLabel];
        [card addSubview:_middleBadge];
        [card addSubview:_scoreLabel];
        [card addSubview:_dateLabel];
        [card addSubview:_inputButton];
        [card addSubview:_verifiedPill];

        // Figma 1:9284：队名 — 队徽 — 14 — 时间 — 14 — 队徽 — 队名
        [_homeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(card).offset(16);
            make.centerY.equalTo(_homeLogo);
            make.width.mas_lessThanOrEqualTo(card.mas_width).multipliedBy(0.34);
        }];
        [_homeLogo mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_homeLabel.mas_trailing).offset(8);
            make.top.equalTo(card).offset(14);
            make.width.height.mas_equalTo(24);
        }];
        [_scoreLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_homeLogo.mas_trailing).offset(14);
            make.centerY.equalTo(_homeLogo);
            make.height.mas_equalTo(24);
            make.width.mas_greaterThanOrEqualTo(56);
        }];
        [_scoreLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [_awayLogo mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_scoreLabel.mas_trailing).offset(14);
            make.centerY.equalTo(_homeLogo);
            make.width.height.mas_equalTo(24);
        }];
        [_awayLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_awayLogo.mas_trailing).offset(6);
            make.centerY.equalTo(_homeLogo);
            make.trailing.lessThanOrEqualTo(card).offset(-16);
        }];
        // Figma 里“中间徽章”与客队队徽重叠/相邻，这里保留占位但隐藏，避免影响布局
        _middleBadge.hidden = YES;
        [_middleBadge mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_awayLogo);
            make.centerY.equalTo(_awayLogo);
            make.width.height.mas_equalTo(0);
        }];

        // 日期：在时间胶囊下方，左对齐到时间胶囊
        [_dateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_scoreLabel);
            make.top.equalTo(_scoreLabel.mas_bottom).offset(10);
        }];
        [_inputButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(card).offset(16);
            make.bottom.equalTo(card).offset(-12);
            make.height.mas_equalTo(26);
            make.width.mas_equalTo(86);
        }];
        [_verifiedPill mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(card).offset(-16);
            make.bottom.equalTo(card).offset(-12);
            make.height.mas_equalTo(26);
            make.width.mas_greaterThanOrEqualTo(86);
        }];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.cardView.backgroundColor = kDiscoverCellBg;
    self.scoreLabel.layer.borderWidth = 0.5;
    self.scoreLabel.layer.borderColor = kDiscoverGreen.CGColor;
    self.scoreLabel.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.18];
    self.scoreLabel.textColor = kDiscoverGreen;
    self.scoreLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    self.verifiedPill.backgroundColor = kDiscoverPillGreen;
    [self.verifiedPill setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.verifiedPill.layer.borderWidth = 0;
    [self.homeLogo sd_cancelCurrentImageLoad];
    [self.awayLogo sd_cancelCurrentImageLoad];
}

@end

#pragma mark - DiscoverViewController

@interface DiscoverViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *headerDateLabel;
@property (nonatomic, strong) UILabel *passportTitleLabel;
@property (nonatomic, strong) UIImageView *passportSubIcon;
@property (nonatomic, strong) UILabel *passportSubLabel;

@property (nonatomic, strong) UILabel *statAValue;
@property (nonatomic, strong) UILabel *statBValue;
@property (nonatomic, strong) UILabel *statCValue;
@property (nonatomic, strong) UILabel *statDValue;
@property (nonatomic, strong) UILabel *statEValue;

@property (nonatomic, strong) UIButton *consumeBtn;
@property (nonatomic, strong) UIButton *myPassportBtn;

@property (nonatomic, strong) UIView *whiteContainer;
@property (nonatomic, strong) UIView *leagueCard;
@property (nonatomic, strong) UIButton *addConsumeBtn;
@property (nonatomic, strong) UIButton *stampBtn;

@property (nonatomic, strong) UIButton *upcomingPill;
@property (nonatomic, strong) UIButton *finishedPill;
@property (nonatomic, strong) UIView *tabBar;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) MASConstraint *tableHeightConstraint;
@property (nonatomic, strong) NSArray<DiscoverMatch *> *upcomingMatches;
@property (nonatomic, strong) NSArray<DiscoverMatch *> *finishedMatches;
@property (nonatomic, assign) DiscoverMatchType currentType;

/// 联赛信息卡片大数字（对接 PNStatistics.teamRecord）
@property (nonatomic, strong) UILabel *leagueWinValueLabel;
@property (nonatomic, strong) UILabel *leagueDrawValueLabel;
@property (nonatomic, strong) UILabel *leagueLossValueLabel;
@property (nonatomic, strong) UILabel *leagueElimValueLabel;
@property (nonatomic, strong) UILabel *leagueQualValueLabel;
@end

@implementation DiscoverViewController

/// Figma 1:9284「消费记录 / 我的足球护照」：并排 160×40、12 Regular、白 80%、底 15% 白、边 20% 白
- (UIButton *)discover_headerListRowButtonWithTitle:(NSString *)title imageName:(NSString *)imageName action:(SEL)action {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *img = [[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [b setImage:img forState:UIControlStateNormal];
    b.tintColor = [UIColor colorWithWhite:1 alpha:0.8];
    [b setTitle:title forState:UIControlStateNormal];
    [b setTitleColor:[UIColor colorWithWhite:1 alpha:0.8] forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    b.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    b.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    // 稿：图标距左 9、与文案间隔 6；右侧预留给 chevron
    b.contentEdgeInsets = UIEdgeInsetsMake(0, 9, 0, 28);
    CGFloat gap = 6;
    b.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, gap);
    b.titleEdgeInsets = UIEdgeInsetsMake(0, gap, 0, -gap);
    b.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.15];
    b.layer.cornerRadius = 8;
    b.layer.borderWidth = 1;
    b.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.2].CGColor;
    b.clipsToBounds = YES;
    b.adjustsImageWhenHighlighted = NO;
    [b addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return b;
}

- (void)discover_attachWhiteChevronToListRow:(UIButton *)row {
    UIButton *arrow = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *arr = [[UIImage imageNamed:@"setting_right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [arrow setImage:arr forState:UIControlStateNormal];
    arrow.tintColor = [UIColor colorWithWhite:1 alpha:0.8];
    arrow.userInteractionEnabled = NO;
    arrow.adjustsImageWhenHighlighted = NO;
    [row addSubview:arrow];
    [arrow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(row).offset(-12);
        make.centerY.equalTo(row);
        make.width.height.mas_equalTo(14);
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.shouldShowNavigationBar = NO;

    [self buildHeader];
    [self buildBody];
    [self refreshDiscoverHeader];
    [self switchToType:DiscoverMatchTypeUpcoming];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshDiscoverHeader];
    /// 每次进入发现页并行拉取 upcoming / finished，保证列表与后端筛选排序一致（如刚关注球队后返回）
    [self loadRemoteData];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // 底部预留 tab bar 高度，避免内容滑到 tab bar 下方导致无法点击
    CGFloat tabBarH = self.tabBarController.tabBar.bounds.size.height;
    if (tabBarH > 0 && _scrollView.contentInset.bottom != tabBarH) {
        _scrollView.contentInset = UIEdgeInsetsMake(0, 0, tabBarH, 0);
    }
}

- (void)buildHeader {
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.showsVerticalScrollIndicator = NO;
    if (@available(iOS 11.0, *)) _scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:_scrollView];

    _contentView = [[UIView alloc] init];
    [_scrollView addSubview:_contentView];

    [_scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [_contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(_scrollView);
        make.width.equalTo(_scrollView);
    }];

    UIView *header = [[UIView alloc] init];
    header.backgroundColor = kDiscoverHeaderBg;
    [_contentView addSubview:header];
    self.headerView = header;

    _avatarView = [[UIImageView alloc] init];
    _avatarView.backgroundColor = [UIColor colorWithRed:0.30 green:0.18 blue:0.35 alpha:1.0];
    _avatarView.layer.cornerRadius = 20;
    _avatarView.clipsToBounds = YES;
    if (@available(iOS 13.0, *)) {
        _avatarView.image = [UIImage systemImageNamed:@"person.fill"];
        _avatarView.tintColor = [UIColor whiteColor];
        _avatarView.contentMode = UIViewContentModeCenter;
    }

    _nameLabel = [[UILabel alloc] init];
    _nameLabel.text = @"CHALLENGER";
    _nameLabel.font = [UIFont boldSystemFontOfSize:15];
    _nameLabel.textColor = [UIColor whiteColor];

    _headerDateLabel = [[UILabel alloc] init];
    _headerDateLabel.text = @"February 20, 2025";
    _headerDateLabel.font = [UIFont systemFontOfSize:11];
    _headerDateLabel.textColor = [UIColor colorWithWhite:0.75 alpha:1.0];

    _passportTitleLabel = [[UILabel alloc] init];
    _passportTitleLabel.text = NSLocalizedString(@"discover_passport_title", nil) ?: @"我的足球护照";
    _passportTitleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    _passportTitleLabel.textColor = [UIColor whiteColor];

    _passportSubIcon = [[UIImageView alloc] init];
    _passportSubIcon.image = [UIImage imageNamed:@"passport"];
    
    _passportSubLabel = [[UILabel alloc] init];
    _passportSubLabel.text = (NSLocalizedString(@"discover_passport_subtitle", nil) ?: @"护照·通行证");
    _passportSubLabel.font = [UIFont systemFontOfSize:11];
    _passportSubLabel.textColor = [UIColor colorWithWhite:0.75 alpha:1.0];

    [header addSubview:_avatarView];
    [header addSubview:_nameLabel];
    [header addSubview:_headerDateLabel];
    [header addSubview:_passportTitleLabel];
    [header addSubview:_passportSubIcon];
    [header addSubview:_passportSubLabel];

    UILabel* (^makeValue)(void) = ^UILabel*{
        UILabel *l = [[UILabel alloc] init];
        l.font = [UIFont systemFontOfSize:30 weight:UIFontWeightRegular];
        l.textColor = [UIColor whiteColor];
        return l;
    };
    UILabel* (^makeDesc)(NSString *) = ^UILabel*(NSString *t){
        UILabel *l = [[UILabel alloc] init];
        l.text = t;
        l.font = [UIFont systemFontOfSize:11];
        l.textColor = [UIColor colorWithWhite:0.75 alpha:1.0];
        return l;
    };

    _statAValue = makeValue(); UILabel *statADesc = makeDesc(NSLocalizedString(@"discover_stat_matches", nil) ?: @"总场次");
    _statBValue = makeValue(); UILabel *statBDesc = makeDesc(NSLocalizedString(@"discover_stat_duration", nil) ?: @"总观看时长");
    _statCValue = makeValue(); UILabel *statCDesc = makeDesc(NSLocalizedString(@"discover_stat_venues", nil) ?: @"总球场数");
    _statDValue = makeValue(); UILabel *statDDesc = makeDesc(NSLocalizedString(@"discover_stat_league", nil) ?: @"联赛");
    _statEValue = makeValue(); UILabel *statEDesc = makeDesc(NSLocalizedString(@"discover_stat_country", nil) ?: @"国家");

    [header addSubview:_statAValue];
    [header addSubview:statADesc];
    [header addSubview:_statBValue];
    [header addSubview:statBDesc];

    UIView *row2 = [[UIView alloc] init];
    [header addSubview:row2];
    [row2 addSubview:_statCValue];
    [row2 addSubview:statCDesc];
    [row2 addSubview:_statDValue];
    [row2 addSubview:statDDesc];
    [row2 addSubview:_statEValue];
    [row2 addSubview:statEDesc];

    NSString *consumeTitle = NSLocalizedString(@"discover_consume_record", nil) ?: @"消费记录";
    NSString *passportBtnTitle = NSLocalizedString(@"discover_my_passport_btn", nil) ?: @"我的足球护照";
    _consumeBtn = [self discover_headerListRowButtonWithTitle:consumeTitle imageName:@"payment_record" action:@selector(onConsumeRecordTapped)];
    _myPassportBtn = [self discover_headerListRowButtonWithTitle:passportBtnTitle imageName:@"football_passport" action:@selector(onMyPassportTapped)];

    [header addSubview:_consumeBtn];
    [header addSubview:_myPassportBtn];
    [self discover_attachWhiteChevronToListRow:_consumeBtn];
    [self discover_attachWhiteChevronToListRow:_myPassportBtn];

    [header mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(_contentView);
        make.bottom.equalTo(_myPassportBtn.mas_bottom).offset(36);
        make.height.mas_greaterThanOrEqualTo(330);
    }];
    [_avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(header.mas_safeAreaLayoutGuideTop).offset(12);
        make.leading.equalTo(header).offset(16);
        make.width.height.mas_equalTo(40);
    }];
    [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(_avatarView.mas_trailing).offset(10);
        make.bottom.equalTo(_avatarView.mas_centerY).offset(1);
    }];
    [_headerDateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(_nameLabel);
        make.top.equalTo(_nameLabel.mas_bottom).offset(2);
    }];
    [_passportTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(header).offset(16);
        make.top.equalTo(_avatarView.mas_bottom).offset(22);
    }];
    [_passportSubIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(_passportTitleLabel);
        make.top.equalTo(_passportTitleLabel.mas_bottom).offset(8);
    }];
    [_passportSubLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(_passportSubIcon.mas_trailing).offset(2);
        make.centerY.equalTo(_passportSubIcon.mas_centerY);
    }];
    [_statAValue mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(header).offset(16);
        make.top.equalTo(_passportSubLabel.mas_bottom).offset(18);
    }];
    [statADesc mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(_statAValue);
        make.top.equalTo(_statAValue.mas_bottom).offset(4);
    }];
    [_statBValue mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(header.mas_centerX).offset(-20);
        make.top.equalTo(_statAValue);
    }];
    [statBDesc mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(_statBValue);
        make.top.equalTo(_statBValue.mas_bottom).offset(4);
    }];

    [row2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(header).offset(16);
        make.trailing.equalTo(header).offset(-16);
        make.top.equalTo(statADesc.mas_bottom).offset(16);
        make.height.mas_equalTo(52);
    }];
//    NSArray *vals = @[ _statCValue, _statDValue, _statEValue ];
//    NSArray *descs = @[ statCDesc, statDDesc, statEDesc ];
//    UILabel *prev = nil;
//    for (NSInteger i = 0; i < vals.count; i++) {
//        UILabel *v = vals[i];
//        UILabel *d = descs[i];
//        [v mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.top.equalTo(row2);
//            if (prev) { make.leading.equalTo(prev.mas_trailing); make.width.equalTo(prev); }
//            else { make.leading.equalTo(row2); }
//        }];
//        [d mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.top.equalTo(v.mas_bottom).offset(4);
//            make.centerX.equalTo(v);
//        }];
//        prev = v;
//    }
//    [prev mas_makeConstraints:^(MASConstraintMaker *make) { make.trailing.equalTo(row2); }];
    [_statCValue mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(row2);
        make.top.equalTo(row2);
    }];
    [statCDesc mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(_statCValue);
        make.top.equalTo(_statCValue.mas_bottom).offset(4);
    }];
    [_statDValue mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(row2).offset(-10);
        make.top.equalTo(row2);
    }];
    [statDDesc mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(_statDValue);
        make.top.equalTo(_statDValue.mas_bottom).offset(4);
    }];
    [_statEValue mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(row2);
        make.leading.equalTo(row2.mas_centerX).offset(120);
    }];
    [statEDesc mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(_statEValue);
        make.top.equalTo(_statEValue.mas_bottom).offset(4);
    }];

    [_consumeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(header).offset(16);
        make.top.equalTo(row2.mas_bottom).offset(16);
        make.height.mas_equalTo(40);
        make.width.equalTo(_myPassportBtn);
    }];
    [_myPassportBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(_consumeBtn.mas_trailing).offset(23);
        make.trailing.equalTo(header).offset(-16);
        make.centerY.equalTo(_consumeBtn);
        make.height.equalTo(_consumeBtn);
    }];
}

- (void)buildBody {
    UIView *white = [[UIView alloc] init];
    white.backgroundColor = [UIColor whiteColor];
    white.layer.cornerRadius = 24;
    white.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    white.layer.masksToBounds = YES;
    [_contentView addSubview:white];
    self.whiteContainer = white;

    // Figma：白色容器顶部无彩色分割线

    UILabel *leagueTitle = [[UILabel alloc] init];
    leagueTitle.text = (NSLocalizedString(@"discover_league_info", nil) ?: @"联赛信息");
    leagueTitle.font = [UIFont boldSystemFontOfSize:16];
    leagueTitle.textColor = [UIColor blackColor];
    [white addSubview:leagueTitle];

    UIView *leagueCard = [[UIView alloc] init];
    leagueCard.backgroundColor = kDiscoverCardBg;
    leagueCard.layer.cornerRadius = 8;
    [white addSubview:leagueCard];
    self.leagueCard = leagueCard;

    UILabel* (^bigNum)(void) = ^UILabel*{
        UILabel *l = [[UILabel alloc] init];
        l.font = [UIFont systemFontOfSize:36 weight:UIFontWeightRegular];
        l.textColor = [UIColor blackColor];
        l.textAlignment = NSTextAlignmentCenter;
        return l;
    };
    UILabel* (^smallLab)(NSString *) = ^UILabel*(NSString *t){
        UILabel *l = [[UILabel alloc] init];
        l.text = t;
        l.font = [UIFont systemFontOfSize:12];
        l.textColor = [UIColor darkGrayColor];
        l.textAlignment = NSTextAlignmentCenter;
        return l;
    };

    UILabel *w40 = bigNum(); w40.text = @"40";
    UILabel *w40d = smallLab(NSLocalizedString(@"discover_win", nil) ?: @"胜利");
    UILabel *d20 = bigNum(); d20.text = @"20";
    UILabel *d20d = smallLab(NSLocalizedString(@"discover_draw", nil) ?: @"平局");
    UILabel *l30 = bigNum(); l30.text = @"30";
    UILabel *l30d = smallLab(NSLocalizedString(@"discover_loss", nil) ?: @"失败");
    UILabel *k2 = bigNum(); k2.text = @"2";
    UILabel *k2d = smallLab(NSLocalizedString(@"discover_eliminated", nil) ?: @"淘汰");
    UILabel *q2 = bigNum(); q2.text = @"2";
    UILabel *q2d = smallLab(NSLocalizedString(@"discover_qualified", nil) ?: @"出线");
    self.leagueWinValueLabel = w40;
    self.leagueDrawValueLabel = d20;
    self.leagueLossValueLabel = l30;
    self.leagueElimValueLabel = k2;
    self.leagueQualValueLabel = q2;

    NSArray *topNums = @[ w40, d20, l30 ];
    NSArray *topDescs = @[ w40d, d20d, l30d ];
    UILabel *prevTop = nil;
    for (NSInteger i = 0; i < topNums.count; i++) {
        UILabel *n = topNums[i];
        UILabel *d = topDescs[i];
        [leagueCard addSubview:n];
        [leagueCard addSubview:d];
        [n mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(leagueCard).offset(16);
            if (prevTop) { make.leading.equalTo(prevTop.mas_trailing); make.width.equalTo(prevTop); }
            else { make.leading.equalTo(leagueCard); }
        }];
        [d mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(n.mas_bottom).offset(4);
            make.centerX.equalTo(n);
        }];
        prevTop = n;
    }
    [prevTop mas_makeConstraints:^(MASConstraintMaker *make) { make.trailing.equalTo(leagueCard); }];

    UIView *bottomRow = [[UIView alloc] init];
    [leagueCard addSubview:bottomRow];
    [bottomRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(w40d.mas_bottom).offset(14);
        make.leading.trailing.equalTo(leagueCard);
        make.height.mas_equalTo(48);
    }];
//    NSArray *botNums = @[ k2, q2 ];
//    NSArray *botDescs = @[ k2d, q2d ];
//    UILabel *prevBot = nil;
//    for (NSInteger i = 0; i < botNums.count; i++) {
//        UILabel *n = botNums[i];
//        UILabel *d = botDescs[i];
//        [bottomRow addSubview:n];
//        [bottomRow addSubview:d];
//        [n mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.top.equalTo(bottomRow);
//            if (prevBot) { make.leading.equalTo(prevBot.mas_trailing); make.width.equalTo(prevBot); }
//            else { make.leading.equalTo(bottomRow); }
//        }];
//        [d mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.top.equalTo(n.mas_bottom).offset(4);
//            make.centerX.equalTo(n);
//        }];
//        prevBot = n;
//    }
//    [prevBot mas_makeConstraints:^(MASConstraintMaker *make) { make.trailing.equalTo(bottomRow); }];
    [bottomRow addSubview:k2];
    [bottomRow addSubview:k2d];
    [bottomRow addSubview:q2];
    [bottomRow addSubview:q2d];
    [k2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(bottomRow);
        make.centerX.equalTo(w40.mas_centerX);
    }];
    [k2d mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(k2.mas_bottom).offset(4);
        make.centerX.equalTo(k2);
    }];
    [q2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(bottomRow);
        make.centerX.equalTo(d20.mas_centerX);
    }];
    [q2d mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(q2.mas_bottom).offset(4);
        make.centerX.equalTo(q2);
    }];

    UIButton* (^outlineBtn)(NSString *, NSString *) = ^UIButton*(NSString *t, NSString *asset){
        UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
        [b setTitle:[NSString stringWithFormat:@"  %@  ", t] forState:UIControlStateNormal];
        [b setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        b.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        b.layer.cornerRadius = 25;
        b.layer.borderWidth = 1;
        b.layer.borderColor = [UIColor colorWithWhite:0.11 alpha:1.0].CGColor;
        [b setImage:[UIImage imageNamed:asset] forState:UIControlStateNormal];
        b.tintColor = [UIColor blackColor];
        return b;
    };
    _addConsumeBtn = outlineBtn((NSLocalizedString(@"discover_add_consume", nil) ?: @"添加消费"), @"add_icon");
    _stampBtn = outlineBtn((NSLocalizedString(@"discover_stamp_album", nil) ?: @"邮票夹"), @"post_icon");
    [white addSubview:_addConsumeBtn];
    [white addSubview:_stampBtn];
    [_addConsumeBtn addTarget:self action:@selector(onAddConsumeTapped) forControlEvents:UIControlEventTouchUpInside];
    [_stampBtn addTarget:self action:@selector(onStampAlbumTapped) forControlEvents:UIControlEventTouchUpInside];

    UIView *tabBar = [[UIView alloc] init];
    tabBar.backgroundColor = [UIColor whiteColor];
    tabBar.layer.cornerRadius = 23.5;
    tabBar.layer.masksToBounds = YES;
    [white addSubview:tabBar];
    self.tabBar = tabBar;

    _upcomingPill = [UIButton buttonWithType:UIButtonTypeSystem];
    _finishedPill = [UIButton buttonWithType:UIButtonTypeSystem];
    NSArray *tabs = @[ _upcomingPill, _finishedPill ];
    NSString *tabUpcoming = [NSString stringWithFormat:(NSLocalizedString(@"discover_tab_upcoming_format", nil) ?: @"未来观赛(%ld)"), (long)0];
    NSString *tabFinished = [NSString stringWithFormat:(NSLocalizedString(@"discover_tab_finished_format", nil) ?: @"已经观赛(%ld)"), (long)0];
    NSArray *tabTitles = @[ tabUpcoming, tabFinished ];
    for (NSInteger i = 0; i < tabs.count; i++) {
        UIButton *b = tabs[i];
        [b setTitle:tabTitles[i] forState:UIControlStateNormal];
        b.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        b.layer.cornerRadius = 20.5;
        [tabBar addSubview:b];
    }
    [_upcomingPill addTarget:self action:@selector(onUpcomingTapped) forControlEvents:UIControlEventTouchUpInside];
    [_finishedPill addTarget:self action:@selector(onFinishedTapped) forControlEvents:UIControlEventTouchUpInside];

    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.backgroundColor = [UIColor whiteColor];
    _tableView.scrollEnabled = NO;
    [_tableView registerClass:[DiscoverMatchCell class] forCellReuseIdentifier:@"DiscoverMatchCell"];
    [white addSubview:_tableView];

    [white mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView.mas_bottom).offset(-26);
        make.leading.trailing.equalTo(_contentView);
        make.bottom.equalTo(_contentView);
    }];
    [leagueTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(white).offset(18);
        make.leading.equalTo(white).offset(16);
    }];
    [leagueCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(leagueTitle.mas_bottom).offset(10);
        make.leading.equalTo(white).offset(16);
        make.trailing.equalTo(white).offset(-16);
        make.height.mas_equalTo(160);
    }];
    [_addConsumeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(leagueCard.mas_bottom).offset(16);
        make.leading.equalTo(white).offset(16);
        make.trailing.equalTo(white.mas_centerX).offset(-8);
        make.height.mas_equalTo(50);
    }];
    [_stampBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(leagueCard.mas_bottom).offset(16);
        make.leading.equalTo(white.mas_centerX).offset(8);
        make.trailing.equalTo(white).offset(-16);
        make.height.mas_equalTo(50);
    }];
    [self.tabBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_addConsumeBtn.mas_bottom).offset(16);
        make.leading.equalTo(white).offset(16);
        make.trailing.equalTo(white).offset(-16);
        make.height.mas_equalTo(47);
    }];
    [_upcomingPill mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.tabBar).offset(4);
        make.top.equalTo(self.tabBar).offset(3);
        make.bottom.equalTo(self.tabBar).offset(-3);
    }];
    [_finishedPill mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.tabBar).offset(-4);
        make.top.equalTo(self.tabBar).offset(3);
        make.bottom.equalTo(self.tabBar).offset(-3);
        make.leading.equalTo(_upcomingPill.mas_trailing).offset(1);
        make.width.equalTo(_upcomingPill);
    }];
    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tabBar.mas_bottom).offset(10);
        make.leading.trailing.equalTo(white);
        self.tableHeightConstraint = make.height.mas_equalTo(0);
        make.bottom.equalTo(white).offset(-24);
    }];
}

- (void)refreshDiscoverHeader {
    if (!AuthManager.sharedManager.isLoggedIn) {
        self.nameLabel.text = @"--";
        self.headerDateLabel.text = @"";
        [self.avatarView sd_cancelCurrentImageLoad];
        if (@available(iOS 13.0, *)) {
            self.avatarView.image = [UIImage systemImageNamed:@"person.fill"];
            self.avatarView.tintColor = [UIColor whiteColor];
            self.avatarView.contentMode = UIViewContentModeCenter;
        }
        return;
    }
    User *u = AuthManager.sharedManager.user;
    UserProfile *p = u.profile;
    NSString *name = p.nickname.length > 0 ? p.nickname : (u.nickname.length > 0 ? u.nickname : @"--");
    self.nameLabel.text = name;
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    df.dateFormat = @"MMMM d, yyyy";
    self.headerDateLabel.text = [df stringFromDate:[NSDate date]];

    NSString *avStr = p.avatar.length > 0 ? p.avatar : u.avatar;
    NSString *trimmed = [avStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSURL *url = trimmed.length > 0 ? [NSURL URLWithString:trimmed] : nil;
    UIImage *ph = nil;
    if (@available(iOS 13.0, *)) {
        ph = [UIImage systemImageNamed:@"person.crop.circle.fill"];
    }
    __weak typeof(self) weakSelf = self;
    [self.avatarView sd_setImageWithURL:url placeholderImage:ph completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (image && !error) {
            weakSelf.avatarView.contentMode = UIViewContentModeScaleAspectFill;
            weakSelf.avatarView.tintColor = nil;
        } else {
            weakSelf.avatarView.contentMode = UIViewContentModeCenter;
            if (@available(iOS 13.0, *)) {
                weakSelf.avatarView.image = ph;
                weakSelf.avatarView.tintColor = [UIColor whiteColor];
            }
        }
    }];
}

- (void)applyStatistics:(PNStatistics *)statistics {
    void (^setLeagueDefaults)(void) = ^{
        self.leagueWinValueLabel.text = @"0";
        self.leagueDrawValueLabel.text = @"0";
        self.leagueLossValueLabel.text = @"0";
        self.leagueElimValueLabel.text = @"0";
        self.leagueQualValueLabel.text = @"0";
    };
    if (!statistics) {
        self.statAValue.text = @"0";
        self.statBValue.text = @"0 min";
        self.statCValue.text = @"0";
        self.statDValue.text = @"0";
        self.statEValue.text = @"0";
        setLeagueDefaults();
        return;
    }
    NSInteger totalMatches = statistics.basicStats ? MAX(statistics.basicStats.totalMatches, 0) : 0;
    self.statAValue.text = [NSString stringWithFormat:@"%ld", (long)totalMatches];
    NSInteger mins = MAX(statistics.cumulativeWatchTime, 0);
    self.statBValue.text = [NSString stringWithFormat:@"%ld min", (long)mins];
    self.statCValue.text = [NSString stringWithFormat:@"%ld", (long)MAX((NSInteger)statistics.stadiumRanking.count, 0)];
    self.statDValue.text = [NSString stringWithFormat:@"%ld", (long)MAX((NSInteger)statistics.leagueStats.count, 0)];
    self.statEValue.text = [NSString stringWithFormat:@"%ld", (long)MAX(statistics.countryCount, 0)];

    PNStatisticsTeamRecord *tr = statistics.teamRecord;
    if (!tr) {
        setLeagueDefaults();
        return;
    }
    self.leagueWinValueLabel.text = [NSString stringWithFormat:@"%ld", (long)MAX(tr.wins, 0)];
    self.leagueDrawValueLabel.text = [NSString stringWithFormat:@"%ld", (long)MAX(tr.draws, 0)];
    self.leagueLossValueLabel.text = [NSString stringWithFormat:@"%ld", (long)MAX(tr.losses, 0)];
    self.leagueElimValueLabel.text = [NSString stringWithFormat:@"%ld", (long)MAX(tr.eliminated, 0)];
    self.leagueQualValueLabel.text = [NSString stringWithFormat:@"%ld", (long)MAX(tr.qualified, 0)];
}

- (void)loadRemoteData {
    __weak typeof(self) weakSelf = self;
    if (!AuthManager.sharedManager.isLoggedIn) {
        self.upcomingMatches = @[];
        self.finishedMatches = @[];
        [self refreshTabs];
        [self applyStatistics:nil];
        return;
    }
    /// 接口：`/matches/my-team/upcoming` 与 `/matches/my-team/finished` 由服务端筛选排序；客户端只做 VO → DiscoverCell 映射
    dispatch_group_t group = dispatch_group_create();
    __block NSArray<Match *> *upList = @[];
    __block NSArray<Match *> *finList = @[];
    dispatch_group_enter(group);
    [[MatchRequest shared] getMyTeamUpcomingMatchesWithPage:1 pageSize:50 success:^(HTTPResponse * _Nullable responseObject) {
        NSArray *rows = [responseObject.dataObject isKindOfClass:NSArray.class] ? responseObject.dataObject : @[];
        upList = rows;
        dispatch_group_leave(group);
    } failure:^(NSError * _Nonnull error) {
        dispatch_group_leave(group);
    }];
    dispatch_group_enter(group);
    [[MatchRequest shared] getMyTeamFinishedMatchesWithPage:1 pageSize:50 success:^(HTTPResponse * _Nullable responseObject) {
        NSArray *rows = [responseObject.dataObject isKindOfClass:NSArray.class] ? responseObject.dataObject : @[];
        finList = rows;
        dispatch_group_leave(group);
    } failure:^(NSError * _Nonnull error) {
        dispatch_group_leave(group);
    }];
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        weakSelf.upcomingMatches = [weakSelf discoverMatchesFrom:upList type:DiscoverMatchTypeUpcoming];
        weakSelf.finishedMatches = [weakSelf discoverMatchesFrom:finList type:DiscoverMatchTypeFinished];
        [weakSelf refreshTabs];
    });
    [[ProfileRequest shared] getMyStatisticsWithPeriod:@"all" success:^(HTTPResponse * _Nullable responseObject) {
        PNStatistics *statistics = [responseObject.dataObject isKindOfClass:PNStatistics.class] ? responseObject.dataObject : nil;
        [weakSelf applyStatistics:statistics];
    } failure:^(NSError * _Nonnull error) {
        [weakSelf applyStatistics:nil];
    }];
}

- (NSArray<DiscoverMatch *> *)discoverMatchesFrom:(NSArray<Match *> *)matches type:(DiscoverMatchType)type {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:matches.count];
    NSString *fmtVerified = (NSLocalizedString(@"discover_verified_minutes_format", nil) ?: @"已认证%ld分钟");
    for (Match *match in matches) {
        DiscoverMatch *m = [DiscoverMatch new];
        m.matchId = match.matchId ?: @"";
        m.homeName = match.homeTeamName ?: @"-";
        m.awayName = match.awayTeamName ?: @"-";
        m.homeLogoURL = match.homeTeamLogo ?: @"";
        m.awayLogoURL = match.awayTeamLogo ?: @"";
        m.timeText = [self shortTimeText:match.matchDate];
        m.dateText = [self shortDateText:match.matchDate];
        if (type == DiscoverMatchTypeUpcoming) {
            m.scoreText = m.timeText;
            m.hasInputInfo = match.infoCompleted;
            m.hasVerified = match.verifyCompleted;
        } else {
            m.scoreText = [NSString stringWithFormat:@"%ld : %ld", (long)match.homeScore, (long)match.awayScore];
            m.hasInputInfo = match.infoCompleted;
            m.hasVerified = match.verifyCompleted;
            NSInteger minutes = match.certifiedMinutes > 0 ? match.certifiedMinutes : (NSInteger)[match.viewCount integerValue];
            m.verifiedText = [NSString stringWithFormat:fmtVerified, (long)MAX(minutes, 0)];
        }
        m.type = type;
        [result addObject:m];
    }
    return result;
}

- (void)refreshTabs {
    NSString *fmtUpcoming = (NSLocalizedString(@"discover_tab_upcoming_format", nil) ?: @"未来观赛(%ld)");
    NSString *fmtFinished = (NSLocalizedString(@"discover_tab_finished_format", nil) ?: @"已经观赛(%ld)");
    [self.upcomingPill setTitle:[NSString stringWithFormat:fmtUpcoming, (long)self.upcomingMatches.count] forState:UIControlStateNormal];
    [self.finishedPill setTitle:[NSString stringWithFormat:fmtFinished, (long)self.finishedMatches.count] forState:UIControlStateNormal];
    [self.tableView reloadData];
    [self updateTableHeight];
}

- (NSString *)shortTimeText:(NSString *)raw {
    NSDate *date = [self dateFromRaw:raw];
    if (!date) return @"--:--";
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"HH:mm";
    return [fmt stringFromDate:date];
}

- (NSString *)shortDateText:(NSString *)raw {
    NSDate *date = [self dateFromRaw:raw];
    if (!date) return @"--";
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"dd MMM, yyyy";
    return [fmt stringFromDate:date];
}

- (NSDate *)dateFromRaw:(NSString *)raw {
    return DiscoverDateFromRawString(raw);
}


- (NSArray<DiscoverMatch *> *)currentDataSource {
    return self.currentType == DiscoverMatchTypeUpcoming ? self.upcomingMatches : self.finishedMatches;
}

- (void)switchToType:(DiscoverMatchType)type {
    self.currentType = type;
    BOOL upcomingSel = (type == DiscoverMatchTypeUpcoming);
    self.upcomingPill.backgroundColor = upcomingSel ? kDiscoverGreen : [UIColor clearColor];
    self.finishedPill.backgroundColor = upcomingSel ? [UIColor clearColor] : kDiscoverGreen;
    [self.upcomingPill setTitleColor:upcomingSel ? [UIColor whiteColor] : kDiscoverGreen forState:UIControlStateNormal];
    [self.finishedPill setTitleColor:upcomingSel ? kDiscoverGreen : [UIColor whiteColor] forState:UIControlStateNormal];
    self.upcomingPill.titleLabel.font = [UIFont systemFontOfSize:14 weight:(upcomingSel ? UIFontWeightSemibold : UIFontWeightMedium)];
    self.finishedPill.titleLabel.font = [UIFont systemFontOfSize:14 weight:(upcomingSel ? UIFontWeightMedium : UIFontWeightSemibold)];
    [self.tableView reloadData];
    [self updateTableHeight];
}

- (void)onUpcomingTapped {
    [self switchToType:DiscoverMatchTypeUpcoming];
}

- (void)onFinishedTapped {
    [self switchToType:DiscoverMatchTypeFinished];
}

- (void)onAddConsumeTapped {
    PNAddConsumeViewController *vc = [[PNAddConsumeViewController alloc] init];
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)onStampAlbumTapped {
    PassportSheetsViewController *vc = [[PassportSheetsViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onConsumeRecordTapped {
    ConsumptionRecordViewController *vc = [[ConsumptionRecordViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onMyPassportTapped {
    PassportViewController *vc = [[PassportViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)updateTableHeight {
    NSInteger rows = [self currentDataSource].count;
    CGFloat rowH = (self.currentType == DiscoverMatchTypeFinished) ? 101.f : 97.f;
    self.tableHeightConstraint.offset = rows * rowH;
    [self.view layoutIfNeeded];
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self currentDataSource].count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    DiscoverMatch *m = [self currentDataSource][indexPath.row];
    return (m.type == DiscoverMatchTypeFinished) ? 101.f : 97.f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DiscoverMatchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DiscoverMatchCell" forIndexPath:indexPath];
    DiscoverMatch *m = [self currentDataSource][indexPath.row];

    cell.homeLabel.text = m.homeName;
    cell.awayLabel.text = m.awayName;
    cell.dateLabel.text = m.dateText;
    cell.cardView.backgroundColor = (m.type == DiscoverMatchTypeFinished) ? kDiscoverFinishedCardBg : kDiscoverCellBg;

    NSURL *homeURL = m.homeLogoURL.length ? [NSURL URLWithString:m.homeLogoURL] : nil;
    NSURL *awayURL = m.awayLogoURL.length ? [NSURL URLWithString:m.awayLogoURL] : nil;
    UIImage *ph = nil;
    if (@available(iOS 13.0, *)) {
        ph = [UIImage systemImageNamed:@"photo"];
    }
    [cell.homeLogo sd_setImageWithURL:homeURL placeholderImage:ph options:SDWebImageRetryFailed];
    [cell.awayLogo sd_setImageWithURL:awayURL placeholderImage:ph options:SDWebImageRetryFailed];
    cell.homeLogo.contentMode = UIViewContentModeScaleAspectFit;
    cell.awayLogo.contentMode = UIViewContentModeScaleAspectFit;

    if (m.type == DiscoverMatchTypeUpcoming) {
        cell.inputButton.hidden = NO;
        cell.verifiedPill.hidden = NO;
        cell.scoreLabel.text = m.timeText.length ? m.timeText : @"--:--";
        cell.scoreLabel.layer.borderWidth = 0.5;
        cell.scoreLabel.layer.borderColor = kDiscoverGreen.CGColor;
        cell.scoreLabel.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.18];
        cell.scoreLabel.textColor = kDiscoverGreen;
        cell.scoreLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        [cell.verifiedPill setTitle:(NSLocalizedString(@"discover_verify_match", nil) ?: @"认证比赛") forState:UIControlStateNormal];
        cell.verifiedPill.backgroundColor = kDiscoverPillGreen;
        [cell.verifiedPill setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [cell.verifiedPill setImage:[UIImage imageNamed:@"verified_icon"] forState:UIControlStateNormal];
        cell.verifiedPill.tintColor = [UIColor whiteColor];
        cell.dateLabel.textAlignment = NSTextAlignmentLeft;
        [cell.dateLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(cell.scoreLabel);
            make.top.equalTo(cell.scoreLabel.mas_bottom).offset(10);
        }];
        [cell.inputButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [cell.inputButton addTarget:self action:@selector(onInputInfoButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [cell.verifiedPill removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [cell.verifiedPill addTarget:self action:@selector(onVerifyMatchButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    } else {
        cell.inputButton.hidden = m.hasInputInfo;
        cell.verifiedPill.hidden = NO;
        cell.scoreLabel.text = m.scoreText.length ? m.scoreText : @"0 : 0";
        cell.scoreLabel.layer.borderWidth = 0;
        cell.scoreLabel.backgroundColor = [UIColor clearColor];
        cell.scoreLabel.textColor = [UIColor blackColor];
        cell.scoreLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
        if (m.hasVerified) {
            [cell.verifiedPill setTitle:m.verifiedText forState:UIControlStateNormal];
            cell.verifiedPill.backgroundColor = [UIColor colorWithRed:6/255.0 green:15/255.0 blue:15/255.0 alpha:1.0];
            [cell.verifiedPill setTitleColor:[UIColor colorWithRed:0.298 green:0.851 blue:0.392 alpha:1.0] forState:UIControlStateNormal];
            if (@available(iOS 13.0, *)) {
                [cell.verifiedPill setImage:[UIImage systemImageNamed:@"checkmark.circle.fill"] forState:UIControlStateNormal];
                cell.verifiedPill.tintColor = [UIColor colorWithRed:0.298 green:0.851 blue:0.392 alpha:1.0];
            } else {
                [cell.verifiedPill setImage:nil forState:UIControlStateNormal];
            }
        } else {
            [cell.verifiedPill setTitle:(NSLocalizedString(@"discover_verify_match", nil) ?: @"认证比赛") forState:UIControlStateNormal];
            cell.verifiedPill.backgroundColor = kDiscoverPillGreen;
            [cell.verifiedPill setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [cell.verifiedPill setImage:[UIImage imageNamed:@"verified_icon"] forState:UIControlStateNormal];
            cell.verifiedPill.tintColor = [UIColor whiteColor];
        }
        cell.dateLabel.textAlignment = NSTextAlignmentLeft;
        [cell.dateLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(cell.cardView).offset(16);
            make.top.equalTo(cell.scoreLabel.mas_bottom).offset(8);
        }];
        [cell.verifiedPill removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [cell.verifiedPill addTarget:self action:@selector(onVerifyMatchButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [cell.inputButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [cell.inputButton addTarget:self action:@selector(onInputInfoButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    DiscoverMatch *m = [self currentDataSource][indexPath.row];
    if (m.type != DiscoverMatchTypeFinished) return;
    
    // 只有在“已输入信息 + 已认证比赛”完成后，才允许进入比赛详情
    if (m.hasInputInfo && m.hasVerified) {
        [self showMatchDetailForMatch:m];
    } else {
        // 仍有步骤未完成时，不允许直接进详情，这里优先引导到“输入信息”
        if (!m.hasInputInfo) {
            [self presentMatchInfoForMatch:m];
        } else {
            [self presentMatchVerifyForMatch:m];
        }
    }
}

- (void)onVerifyMatchButtonTapped:(UIButton *)sender {
    CGPoint pointInTable = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:pointInTable];
    if (!indexPath) return;
    DiscoverMatch *m = [self currentDataSource][indexPath.row];
    if (m.type == DiscoverMatchTypeUpcoming) {
        [self presentMatchVerifyForMatch:m];
        return;
    }
    if (!m.hasVerified) {
        [self presentMatchVerifyForMatch:m];
    } else if (m.hasInputInfo) {
        [self showMatchDetailForMatch:m];
    }
}

- (void)onInputInfoButtonTapped:(UIButton *)sender {
    CGPoint pointInTable = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:pointInTable];
    if (!indexPath) return;
    DiscoverMatch *m = [self currentDataSource][indexPath.row];
    [self presentMatchInfoForMatch:m];
}

- (void)presentMatchInfoForMatch:(DiscoverMatch *)match {
    PNMatchInfoInputViewController *vc = [[PNMatchInfoInputViewController alloc] init];
    vc.homeName = match.homeName;
    vc.awayName = match.awayName;
    __weak typeof(self) weakSelf = self;
    vc.completion = ^{
        // 仅完成“输入信息”，暂不允许看详情，还需“认证比赛”
        match.hasInputInfo = YES;
        [weakSelf.tableView reloadData];
    };
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:vc animated:NO completion:nil];
}

- (void)presentMatchVerifyForMatch:(DiscoverMatch *)match {
    PNMatchVerifyViewController *vc = [[PNMatchVerifyViewController alloc] init];
    vc.recordId = match.matchId;
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    __weak typeof(self) weakSelf = self;
    vc.completion = ^{
        // 完成“认证比赛”流程
        match.hasVerified = YES;
        [weakSelf.tableView reloadData];
    };
    [self presentViewController:vc animated:NO completion:nil];
}

- (void)showMatchDetailForMatch:(DiscoverMatch *)match {
    PNMatchDetailViewController *vc = [[PNMatchDetailViewController alloc] init];
    vc.matchId = match.matchId;
    vc.homeName = match.homeName;
    vc.awayName = match.awayName;
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
