//
//  DiscoverViewController.m
//  footBall
//

#import "DiscoverViewController.h"
#import <Masonry/Masonry.h>
#import "PNAddConsumeViewController.h"
#import "PNMatchVerifyViewController.h"
#import "ConsumptionRecordViewController.h"
#import "PassportViewController.h"
#import "StampAlbumViewController.h"
#import "PNMatchDetailViewController.h"
#import "PNMatchInfoInputViewController.h"

#define kDiscoverHeaderBg     [UIColor colorWithRed:0.051 green:0.129 blue:0.133 alpha:1.0]   // #0D2122
#define kDiscoverGreen        [UIColor colorWithRed:0.157 green:0.365 blue:0.294 alpha:1.0]   // #285D4B
#define kDiscoverPillGreen    kDiscoverGreen
#define kDiscoverCardBg       [UIColor colorWithRed:0.976 green:0.976 blue:0.976 alpha:1.0]   // #F9F9F9
#define kDiscoverCellBg       [UIColor colorWithRed:0.961 green:0.961 blue:0.961 alpha:1.0]   // #F5F5F5

typedef NS_ENUM(NSInteger, DiscoverMatchType) {
    DiscoverMatchTypeUpcoming,
    DiscoverMatchTypeFinished
};

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
@end

@implementation DiscoverMatch
@end

@interface DiscoverMatchCell : UITableViewCell
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

        // 顶部一行：主队名(右对齐) - 主队队徽 - 时间胶囊 - 客队队徽 - 客队名(左对齐)
        [_homeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(card).offset(16);
            make.centerY.equalTo(_homeLogo);
            make.width.mas_equalTo(80);
        }];
        [_homeLogo mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_homeLabel.mas_trailing).offset(6);
            make.top.equalTo(card).offset(14);
            make.width.height.mas_equalTo(24);
        }];
        [_scoreLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_homeLogo.mas_trailing).offset(10);
            make.centerY.equalTo(_homeLogo);
            make.height.mas_equalTo(24);
            make.width.mas_greaterThanOrEqualTo(60);
        }];
        [_awayLogo mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_scoreLabel.mas_trailing).offset(10);
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
            make.width.mas_equalTo(86);
        }];
    }
    return self;
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
@end

@implementation DiscoverViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.shouldShowNavigationBar = NO;

    [self buildHeader];
    [self buildBody];
    [self loadRemoteData];
    [self switchToType:DiscoverMatchTypeFinished];
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

    _consumeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _consumeBtn.layer.cornerRadius = 8;
    _consumeBtn.layer.borderWidth = 1;
    _consumeBtn.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.20].CGColor;
    _consumeBtn.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.15];
    [_consumeBtn setTitle:(NSLocalizedString(@"discover_consume_record", nil) ?: @"  消费记录") forState:UIControlStateNormal];
    [_consumeBtn setTitleColor:[UIColor colorWithWhite:1 alpha:0.8] forState:UIControlStateNormal];
    _consumeBtn.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    [_consumeBtn setImage:[UIImage imageNamed:@"payment_record"] forState:UIControlStateNormal];
    _consumeBtn.tintColor = [UIColor colorWithWhite:1 alpha:0.8];
    [_consumeBtn addTarget:self action:@selector(onConsumeRecordTapped) forControlEvents:UIControlEventTouchUpInside];

    _myPassportBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _myPassportBtn.layer.cornerRadius = 8;
    _myPassportBtn.layer.borderWidth = 1;
    _myPassportBtn.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.20].CGColor;
    _myPassportBtn.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.15];
    [_myPassportBtn setTitle:(NSLocalizedString(@"discover_my_passport_btn", nil) ?: @"  我的足球护照") forState:UIControlStateNormal];
    [_myPassportBtn setTitleColor:[UIColor colorWithWhite:1 alpha:0.8] forState:UIControlStateNormal];
    _myPassportBtn.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    [_myPassportBtn setImage:[UIImage imageNamed:@"football_passport"] forState:UIControlStateNormal];
    _myPassportBtn.tintColor = [UIColor colorWithWhite:1 alpha:0.8];
    [_myPassportBtn addTarget:self action:@selector(onMyPassportTapped) forControlEvents:UIControlEventTouchUpInside];

    UIButton *arrow1 = [UIButton buttonWithType:UIButtonTypeSystem];
    UIButton *arrow2 = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImage *arr = [UIImage imageNamed:@"arrow_right"];
    [arrow1 setImage:arr forState:UIControlStateNormal];
    [arrow2 setImage:arr forState:UIControlStateNormal];
    arrow1.tintColor = arrow2.tintColor = [UIColor colorWithWhite:1 alpha:0.8];
    arrow1.userInteractionEnabled = arrow2.userInteractionEnabled = NO;

    [header addSubview:_consumeBtn];
    [header addSubview:_myPassportBtn];
    [_consumeBtn addSubview:arrow1];
    [_myPassportBtn addSubview:arrow2];

    [header mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(_contentView);
        // 让 header 高度随底部两个按钮自适应，避免下方白色容器遮挡按钮
        make.bottom.equalTo(_consumeBtn.mas_bottom).offset(36);
        make.height.mas_greaterThanOrEqualTo(330);
    }];
    [_avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(header.mas_safeAreaLayoutGuideTop).offset(12);
        make.leading.equalTo(header).offset(20);
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
        make.leading.equalTo(header).offset(20);
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
        make.leading.equalTo(header).offset(20);
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
        make.leading.equalTo(header).offset(20);
        make.trailing.equalTo(header).offset(-20);
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
        make.leading.equalTo(header).offset(20);
        make.top.equalTo(row2.mas_bottom).offset(16);
        make.height.mas_equalTo(40);
        make.width.equalTo(_myPassportBtn);
    }];
    [_myPassportBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(header).offset(-20);
        make.centerY.equalTo(_consumeBtn);
        make.height.equalTo(_consumeBtn);
        make.leading.equalTo(_consumeBtn.mas_trailing).offset(12);
    }];
    [arrow1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(_consumeBtn).offset(-12);
        make.centerY.equalTo(_consumeBtn);
        make.width.height.mas_equalTo(14);
    }];
    [arrow2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(_myPassportBtn).offset(-12);
        make.centerY.equalTo(_myPassportBtn);
        make.width.height.mas_equalTo(14);
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
    NSString *tabUpcoming = [NSString stringWithFormat:(NSLocalizedString(@"discover_tab_upcoming_format", nil) ?: @"未来观赛(%ld)"), (long)2];
    NSString *tabFinished = [NSString stringWithFormat:(NSLocalizedString(@"discover_tab_finished_format", nil) ?: @"已经观赛(%ld)"), (long)2];
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
        make.leading.equalTo(white).offset(20);
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

- (void)loadRemoteData {
    __weak typeof(self) weakSelf = self;
    [[MatchRequest shared] getMyTeamMatchesWithPage:1 pageSize:20 success:^(HTTPResponse * _Nullable responseObject) {
        NSArray *matches = [responseObject.dataObject isKindOfClass:NSArray.class] ? responseObject.dataObject : @[];
        weakSelf.upcomingMatches = [weakSelf discoverMatchesFrom:matches type:DiscoverMatchTypeUpcoming];
        [weakSelf refreshTabs];
    } failure:^(NSError * _Nonnull error) {
        weakSelf.upcomingMatches = @[];
        [weakSelf refreshTabs];
    }];
    [[MatchRequest shared] getFavoriteMatchesWithPage:1 pageSize:20 success:^(HTTPResponse * _Nullable responseObject) {
        NSArray *matches = [responseObject.dataObject isKindOfClass:NSArray.class] ? responseObject.dataObject : @[];
        weakSelf.finishedMatches = [weakSelf discoverMatchesFrom:matches type:DiscoverMatchTypeFinished];
        [weakSelf refreshTabs];
    } failure:^(NSError * _Nonnull error) {
        weakSelf.finishedMatches = @[];
        [weakSelf refreshTabs];
    }];
    [[ProfileRequest shared] getMyStatisticsWithPeriod:@"all" success:^(HTTPResponse * _Nullable responseObject) {
        PNStatistics *statistics = [responseObject.dataObject isKindOfClass:PNStatistics.class] ? responseObject.dataObject : nil;
        weakSelf.statAValue.text = [NSString stringWithFormat:@"%ld", (long)MAX(statistics.basicStats.totalMatches, 0)];
        weakSelf.statBValue.text = [NSString stringWithFormat:@"%ld", (long)MAX(statistics.cumulativeWatchTime, 0)];
        weakSelf.statCValue.text = [NSString stringWithFormat:@"%ld", (long)MAX(statistics.stadiumRanking.count, 0)];
        weakSelf.statDValue.text = [NSString stringWithFormat:@"%ld", (long)MAX(statistics.leagueStats.count, 0)];
        weakSelf.statEValue.text = @"0";
    } failure:^(NSError * _Nonnull error) {
        weakSelf.statAValue.text = @"0";
        weakSelf.statBValue.text = @"0";
        weakSelf.statCValue.text = @"0";
        weakSelf.statDValue.text = @"0";
        weakSelf.statEValue.text = @"0";
    }];
}

- (NSArray<DiscoverMatch *> *)discoverMatchesFrom:(NSArray<Match *> *)matches type:(DiscoverMatchType)type {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:matches.count];
    NSString *verifiedTicket = (NSLocalizedString(@"discover_verified_ticket", nil) ?: @"认证球票");
    for (Match *match in matches) {
        DiscoverMatch *m = [DiscoverMatch new];
        m.matchId = match.matchId ?: @"";
        m.homeName = match.homeTeamName ?: @"-";
        m.awayName = match.awayTeamName ?: @"-";
        m.timeText = [self shortTimeText:match.matchDate];
        m.dateText = [self shortDateText:match.matchDate];
        if (type == DiscoverMatchTypeUpcoming) {
            m.scoreText = [self shortTimeText:match.matchDate];
            m.verifiedText = verifiedTicket;
        } else {
            m.scoreText = [NSString stringWithFormat:@"%ld : %ld", (long)match.homeScore, (long)match.awayScore];
            NSInteger minutes = [match.viewCount integerValue];
            NSString *fmt = (NSLocalizedString(@"discover_verified_minutes_format", nil) ?: @"已认证%ld分钟");
            m.verifiedText = [NSString stringWithFormat:fmt, (long)MAX(minutes, 0)];
            m.hasInputInfo = NO;
            m.hasVerified = NO;
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
    if (raw.length == 0) return nil;
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    fmt.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
    NSDate *date = [fmt dateFromString:raw];
    if (!date) {
        fmt.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        date = [fmt dateFromString:raw];
    }
    return date;
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
    StampAlbumViewController *vc = [[StampAlbumViewController alloc] init];
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
    self.tableHeightConstraint.offset = rows * 87.f;
    [self.view layoutIfNeeded];
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self currentDataSource].count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 87;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DiscoverMatchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DiscoverMatchCell" forIndexPath:indexPath];
    DiscoverMatch *m = [self currentDataSource][indexPath.row];

    cell.homeLabel.text = m.homeName;
    cell.awayLabel.text = m.awayName;
    // Figma：中间展示的是“比赛时间”胶囊（统一来自 matchDate）
    cell.scoreLabel.text = m.timeText.length > 0 ? m.timeText : @"--:--";
    cell.dateLabel.text = m.dateText;

    if (m.type == DiscoverMatchTypeUpcoming) {
        // 未来观赛：不显示输入信息、认证比赛按钮
        cell.inputButton.hidden = YES;
        cell.verifiedPill.hidden = YES;
        cell.scoreLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    } else {
        // 已经观赛：底部仍然是左侧“输入信息”、右侧 pill，
        // 但当 hasInputInfo=YES 时，隐藏“输入信息”，并将中间时间挪到左侧展示
        cell.verifiedPill.hidden = NO;
        // 右侧始终文案为“认证比赛”，只有在输入信息+认证都完成后，才显示“已认证xx分钟”
        NSString *pillTitle = (m.hasInputInfo && m.hasVerified) ? m.verifiedText : (NSLocalizedString(@"discover_verify_match", nil) ?: @"认证比赛");
        [cell.verifiedPill setTitle:pillTitle forState:UIControlStateNormal];
        cell.verifiedPill.backgroundColor = kDiscoverPillGreen;
        cell.verifiedPill.layer.borderWidth = 0;
        [cell.verifiedPill setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        if (@available(iOS 13.0, *)) {
            // 未完成时统一使用“认证”图标，完成后使用已认证图标
            NSString *iconName = (m.hasInputInfo && m.hasVerified) ? @"checkmark.circle" : @"checkmark.seal";
            UIImage *img = [UIImage systemImageNamed:iconName];
            [cell.verifiedPill setImage:img forState:UIControlStateNormal];
            cell.verifiedPill.tintColor = [UIColor whiteColor];
        }
        cell.scoreLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];

        if (m.hasInputInfo) {
            // 已完成：隐藏“输入信息”按钮
            cell.inputButton.hidden = YES;
            // 日期标签保持左对齐到“时间胶囊”
            cell.dateLabel.textAlignment = NSTextAlignmentLeft;
            [cell.dateLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.leading.equalTo(cell.scoreLabel);                // 与时间胶囊对齐
                make.top.equalTo(cell.scoreLabel.mas_bottom).offset(10);
            }];
        } else {
            // 未完成：保留原始布局（中间时间 + 左侧输入信息按钮）
            cell.inputButton.hidden = NO;
            cell.dateLabel.textAlignment = NSTextAlignmentLeft;
            [cell.dateLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.leading.equalTo(cell.scoreLabel);
                make.top.equalTo(cell.scoreLabel.mas_bottom).offset(10);
            }];
        }

        // 点击右侧操作 pill：根据当前状态在“输入信息 / 认证比赛 / 比赛详情”之间切换
        [cell.verifiedPill removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [cell.verifiedPill addTarget:self action:@selector(onVerifyMatchButtonTapped:) forControlEvents:UIControlEventTouchUpInside];

        // “输入信息”按钮：仅在未完成时可见，进入输入信息弹层
        [cell.inputButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [cell.inputButton addTarget:self action:@selector(onInputInfoButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    }

    if (@available(iOS 13.0, *)) {
        cell.homeLogo.image = [UIImage systemImageNamed:@"shield.fill"];
        cell.homeLogo.tintColor = [UIColor colorWithRed:0.85 green:0.20 blue:0.25 alpha:1.0];
        cell.homeLogo.contentMode = UIViewContentModeCenter;
        cell.awayLogo.image = [UIImage systemImageNamed:@"shield.fill"];
        cell.awayLogo.tintColor = [UIColor colorWithRed:0.10 green:0.45 blue:0.85 alpha:1.0];
        cell.awayLogo.contentMode = UIViewContentModeCenter;
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
    if (m.type != DiscoverMatchTypeFinished) return;
    
    // 右侧 pill：始终表示“认证比赛”
    // 未认证时 -> 进入认证弹窗；已认证并且输入信息完成 -> 进入比赛详情
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
    if (m.type != DiscoverMatchTypeFinished) return;
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
