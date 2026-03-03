//
//  DiscoverViewController.m
//  footBall
//

#import "DiscoverViewController.h"
#import <Masonry/Masonry.h>
#import "PNAddConsumeViewController.h"
#import "PNMatchVerifyViewController.h"
#import "ConsumptionRecordViewController.h"

#define kDiscoverHeaderBg     [UIColor colorWithRed:0.05 green:0.16 blue:0.15 alpha:1.0]
#define kDiscoverGreen        [UIColor colorWithRed:0.10 green:0.36 blue:0.28 alpha:1.0]
#define kDiscoverPillGreen    [UIColor colorWithRed:0.15 green:0.46 blue:0.34 alpha:1.0]
#define kDiscoverCardBg       [UIColor colorWithWhite:0.97 alpha:1.0]

typedef NS_ENUM(NSInteger, DiscoverMatchType) {
    DiscoverMatchTypeUpcoming,
    DiscoverMatchTypeFinished
};

@interface DiscoverMatch : NSObject
@property (nonatomic, copy) NSString *homeName;
@property (nonatomic, copy) NSString *awayName;
@property (nonatomic, copy) NSString *dateText;
@property (nonatomic, copy) NSString *scoreText;
@property (nonatomic, copy) NSString *verifiedText;
@property (nonatomic, assign) DiscoverMatchType type;
@end

@implementation DiscoverMatch
@end

@interface DiscoverMatchCell : UITableViewCell
@property (nonatomic, strong) UIImageView *homeLogo;
@property (nonatomic, strong) UIImageView *awayLogo;
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
        card.backgroundColor = kDiscoverCardBg;
        card.layer.cornerRadius = 14;
        [self.contentView addSubview:card];
        [card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(6, 16, 6, 16));
        }];

        _homeLogo = [[UIImageView alloc] init];
        _homeLogo.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
        _homeLogo.layer.cornerRadius = 14;
        _homeLogo.clipsToBounds = YES;
        _homeLogo.contentMode = UIViewContentModeScaleAspectFit;
        _awayLogo = [[UIImageView alloc] init];
        _awayLogo.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
        _awayLogo.layer.cornerRadius = 14;
        _awayLogo.clipsToBounds = YES;
        _awayLogo.contentMode = UIViewContentModeScaleAspectFit;

        _homeLabel = [[UILabel alloc] init];
        _homeLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        _homeLabel.textColor = [UIColor blackColor];
        _awayLabel = [[UILabel alloc] init];
        _awayLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        _awayLabel.textColor = [UIColor blackColor];
        _awayLabel.textAlignment = NSTextAlignmentRight;

        _scoreLabel = [[UILabel alloc] init];
        _scoreLabel.font = [UIFont boldSystemFontOfSize:16];
        _scoreLabel.textColor = [UIColor blackColor];
        _scoreLabel.textAlignment = NSTextAlignmentCenter;

        _dateLabel = [[UILabel alloc] init];
        _dateLabel.font = [UIFont systemFontOfSize:11];
        _dateLabel.textColor = [UIColor darkGrayColor];
        _dateLabel.textAlignment = NSTextAlignmentCenter;

        _inputButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _inputButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [_inputButton setTitle:@"输入信息" forState:UIControlStateNormal];
        [_inputButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        _inputButton.layer.cornerRadius = 14;
        _inputButton.layer.borderWidth = 1;
        _inputButton.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1.0].CGColor;
        if (@available(iOS 13.0, *)) {
            UIImage *icon = [[UIImage systemImageNamed:@"square.and.pencil"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [_inputButton setImage:icon forState:UIControlStateNormal];
            _inputButton.tintColor = [UIColor blackColor];
            _inputButton.imageEdgeInsets = UIEdgeInsetsMake(0, -4, 0, 0);
        }

        _verifiedPill = [UIButton buttonWithType:UIButtonTypeSystem];
        _verifiedPill.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        _verifiedPill.layer.cornerRadius = 14;
        _verifiedPill.backgroundColor = kDiscoverPillGreen;
        [_verifiedPill setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        if (@available(iOS 13.0, *)) {
            UIImage *check = [[UIImage systemImageNamed:@"checkmark.circle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [_verifiedPill setImage:check forState:UIControlStateNormal];
            _verifiedPill.tintColor = [UIColor whiteColor];
            _verifiedPill.imageEdgeInsets = UIEdgeInsetsMake(0, -4, 0, 0);
        }

        [card addSubview:_homeLogo];
        [card addSubview:_homeLabel];
        [card addSubview:_awayLogo];
        [card addSubview:_awayLabel];
        [card addSubview:_scoreLabel];
        [card addSubview:_dateLabel];
        [card addSubview:_inputButton];
        [card addSubview:_verifiedPill];

        [_homeLogo mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(card).offset(16);
            make.top.equalTo(card).offset(12);
            make.width.height.mas_equalTo(28);
        }];
        [_homeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_homeLogo.mas_trailing).offset(8);
            make.centerY.equalTo(_homeLogo);
        }];
        [_awayLogo mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(card).offset(-16);
            make.top.equalTo(card).offset(12);
            make.width.height.mas_equalTo(28);
        }];
        [_awayLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(_awayLogo.mas_leading).offset(-8);
            make.centerY.equalTo(_awayLogo);
        }];
        [_scoreLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(card);
            make.centerY.equalTo(_homeLogo);
        }];
        [_dateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(card);
            make.top.equalTo(_scoreLabel.mas_bottom).offset(10);
        }];
        [_inputButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(card).offset(16);
            make.bottom.equalTo(card).offset(-12);
            make.height.mas_equalTo(28);
            make.width.mas_equalTo(96);
        }];
        [_verifiedPill mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(card).offset(-16);
            make.bottom.equalTo(card).offset(-12);
            make.height.mas_equalTo(28);
            make.width.mas_greaterThanOrEqualTo(120);
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
    [self loadFakeData];
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
    _passportTitleLabel.font = [UIFont boldSystemFontOfSize:18];
    _passportTitleLabel.textColor = [UIColor whiteColor];

    _passportSubLabel = [[UILabel alloc] init];
    _passportSubLabel.text = @"护照·通行证";
    _passportSubLabel.font = [UIFont systemFontOfSize:11];
    _passportSubLabel.textColor = [UIColor colorWithWhite:0.75 alpha:1.0];

    [header addSubview:_avatarView];
    [header addSubview:_nameLabel];
    [header addSubview:_headerDateLabel];
    [header addSubview:_passportTitleLabel];
    [header addSubview:_passportSubLabel];

    UILabel* (^makeValue)(void) = ^UILabel*{
        UILabel *l = [[UILabel alloc] init];
        l.font = [UIFont boldSystemFontOfSize:22];
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

    _statAValue = makeValue(); UILabel *statADesc = makeDesc(@"总场次");
    _statBValue = makeValue(); UILabel *statBDesc = makeDesc(@"总观看时长");
    _statCValue = makeValue(); UILabel *statCDesc = makeDesc(@"总球场数");
    _statDValue = makeValue(); UILabel *statDDesc = makeDesc(@"联赛");
    _statEValue = makeValue(); UILabel *statEDesc = makeDesc(@"国家");

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
    _consumeBtn.layer.cornerRadius = 12;
    _consumeBtn.layer.borderWidth = 1;
    _consumeBtn.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.18].CGColor;
    _consumeBtn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.08];
    [_consumeBtn setTitle:@"  消费记录  " forState:UIControlStateNormal];
    [_consumeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _consumeBtn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    if (@available(iOS 13.0, *)) { [_consumeBtn setImage:[UIImage systemImageNamed:@"doc.text"] forState:UIControlStateNormal]; _consumeBtn.tintColor = [UIColor whiteColor]; }
    [_consumeBtn addTarget:self action:@selector(onConsumeRecordTapped) forControlEvents:UIControlEventTouchUpInside];

    _myPassportBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _myPassportBtn.layer.cornerRadius = 12;
    _myPassportBtn.layer.borderWidth = 1;
    _myPassportBtn.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.18].CGColor;
    _myPassportBtn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.08];
    [_myPassportBtn setTitle:@"  我的足球护照  " forState:UIControlStateNormal];
    [_myPassportBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _myPassportBtn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    if (@available(iOS 13.0, *)) { [_myPassportBtn setImage:[UIImage systemImageNamed:@"soccerball"] forState:UIControlStateNormal]; _myPassportBtn.tintColor = [UIColor whiteColor]; }

    UIButton *arrow1 = [UIButton buttonWithType:UIButtonTypeSystem];
    UIButton *arrow2 = [UIButton buttonWithType:UIButtonTypeSystem];
    if (@available(iOS 13.0, *)) { [arrow1 setImage:[UIImage systemImageNamed:@"chevron.right"] forState:UIControlStateNormal]; [arrow2 setImage:[UIImage systemImageNamed:@"chevron.right"] forState:UIControlStateNormal]; }
    arrow1.tintColor = arrow2.tintColor = [UIColor whiteColor];
    arrow1.userInteractionEnabled = arrow2.userInteractionEnabled = NO;

    [header addSubview:_consumeBtn];
    [header addSubview:_myPassportBtn];
    [_consumeBtn addSubview:arrow1];
    [_myPassportBtn addSubview:arrow2];

    [header mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(_contentView);
        // 让 header 高度随底部两个按钮自适应，避免下方白色容器遮挡按钮
        make.bottom.equalTo(_consumeBtn.mas_bottom).offset(16);
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
    [_passportSubLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(_passportTitleLabel);
        make.top.equalTo(_passportTitleLabel.mas_bottom).offset(8);
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
        make.trailing.equalTo(header).offset(-20);
        make.top.equalTo(_statAValue);
    }];
    [statBDesc mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(_statBValue);
        make.top.equalTo(_statBValue.mas_bottom).offset(4);
    }];

    [row2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(header).offset(20);
        make.trailing.equalTo(header).offset(-20);
        make.top.equalTo(statADesc.mas_bottom).offset(16);
        make.height.mas_equalTo(52);
    }];
    NSArray *vals = @[ _statCValue, _statDValue, _statEValue ];
    NSArray *descs = @[ statCDesc, statDDesc, statEDesc ];
    UILabel *prev = nil;
    for (NSInteger i = 0; i < vals.count; i++) {
        UILabel *v = vals[i];
        UILabel *d = descs[i];
        [v mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(row2);
            if (prev) { make.leading.equalTo(prev.mas_trailing); make.width.equalTo(prev); }
            else { make.leading.equalTo(row2); }
        }];
        [d mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(v.mas_bottom).offset(4);
            make.centerX.equalTo(v);
        }];
        prev = v;
    }
    [prev mas_makeConstraints:^(MASConstraintMaker *make) { make.trailing.equalTo(row2); }];

    [_consumeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(header).offset(20);
        make.top.equalTo(row2.mas_bottom).offset(16);
        make.height.mas_equalTo(44);
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
    white.layer.cornerRadius = 26;
    white.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    white.layer.masksToBounds = YES;
    [_contentView addSubview:white];
    self.whiteContainer = white;

    UIView *topLine = [[UIView alloc] init];
    topLine.backgroundColor = [UIColor colorWithRed:0.14 green:0.45 blue:0.90 alpha:1.0];
    [white addSubview:topLine];

    UILabel *leagueTitle = [[UILabel alloc] init];
    leagueTitle.text = @"联赛信息";
    leagueTitle.font = [UIFont boldSystemFontOfSize:16];
    leagueTitle.textColor = [UIColor blackColor];
    [white addSubview:leagueTitle];

    UIView *leagueCard = [[UIView alloc] init];
    leagueCard.backgroundColor = kDiscoverCardBg;
    leagueCard.layer.cornerRadius = 14;
    [white addSubview:leagueCard];
    self.leagueCard = leagueCard;

    UILabel* (^bigNum)(void) = ^UILabel*{
        UILabel *l = [[UILabel alloc] init];
        l.font = [UIFont boldSystemFontOfSize:22];
        l.textColor = [UIColor blackColor];
        l.textAlignment = NSTextAlignmentCenter;
        return l;
    };
    UILabel* (^smallLab)(NSString *) = ^UILabel*(NSString *t){
        UILabel *l = [[UILabel alloc] init];
        l.text = t;
        l.font = [UIFont systemFontOfSize:11];
        l.textColor = [UIColor darkGrayColor];
        l.textAlignment = NSTextAlignmentCenter;
        return l;
    };

    UILabel *w40 = bigNum(); w40.text = @"40";
    UILabel *w40d = smallLab(@"胜利");
    UILabel *d20 = bigNum(); d20.text = @"20";
    UILabel *d20d = smallLab(@"平局");
    UILabel *l30 = bigNum(); l30.text = @"30";
    UILabel *l30d = smallLab(@"失败");
    UILabel *k2 = bigNum(); k2.text = @"2";
    UILabel *k2d = smallLab(@"淘汰");
    UILabel *q2 = bigNum(); q2.text = @"2";
    UILabel *q2d = smallLab(@"出线");

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
        make.bottom.equalTo(leagueCard).offset(-14);
        make.height.mas_equalTo(48);
    }];
    NSArray *botNums = @[ k2, q2 ];
    NSArray *botDescs = @[ k2d, q2d ];
    UILabel *prevBot = nil;
    for (NSInteger i = 0; i < botNums.count; i++) {
        UILabel *n = botNums[i];
        UILabel *d = botDescs[i];
        [bottomRow addSubview:n];
        [bottomRow addSubview:d];
        [n mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(bottomRow);
            if (prevBot) { make.leading.equalTo(prevBot.mas_trailing); make.width.equalTo(prevBot); }
            else { make.leading.equalTo(bottomRow); }
        }];
        [d mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(n.mas_bottom).offset(4);
            make.centerX.equalTo(n);
        }];
        prevBot = n;
    }
    [prevBot mas_makeConstraints:^(MASConstraintMaker *make) { make.trailing.equalTo(bottomRow); }];

    UIButton* (^outlineBtn)(NSString *, NSString *) = ^UIButton*(NSString *t, NSString *sys){
        UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
        [b setTitle:[NSString stringWithFormat:@"  %@  ", t] forState:UIControlStateNormal];
        [b setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        b.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        b.layer.cornerRadius = 20;
        b.layer.borderWidth = 1;
        b.layer.borderColor = [UIColor colorWithWhite:0.75 alpha:1.0].CGColor;
        if (@available(iOS 13.0, *)) { [b setImage:[UIImage systemImageNamed:sys] forState:UIControlStateNormal]; b.tintColor = [UIColor blackColor]; }
        return b;
    };
    _addConsumeBtn = outlineBtn(@"添加消费", @"plus.circle");
    _stampBtn = outlineBtn(@"邮票夹", @"qrcode.viewfinder");
    [white addSubview:_addConsumeBtn];
    [white addSubview:_stampBtn];
    [_addConsumeBtn addTarget:self action:@selector(onAddConsumeTapped) forControlEvents:UIControlEventTouchUpInside];

    _upcomingPill = [UIButton buttonWithType:UIButtonTypeSystem];
    _finishedPill = [UIButton buttonWithType:UIButtonTypeSystem];
    NSArray *tabs = @[ _upcomingPill, _finishedPill ];
    NSArray *tabTitles = @[ @"未来观赛(2)", @"已经观赛(2)" ];
    for (NSInteger i = 0; i < tabs.count; i++) {
        UIButton *b = tabs[i];
        [b setTitle:tabTitles[i] forState:UIControlStateNormal];
        b.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        b.layer.cornerRadius = 18;
        [white addSubview:b];
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
        make.top.equalTo(self.headerView.mas_bottom).offset(-18);
        make.leading.trailing.equalTo(_contentView);
        make.bottom.equalTo(_contentView);
    }];
    [topLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(white);
        make.height.mas_equalTo(2);
    }];
    [leagueTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(white).offset(18);
        make.leading.equalTo(white).offset(20);
    }];
    [leagueCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(leagueTitle.mas_bottom).offset(10);
        make.leading.equalTo(white).offset(16);
        make.trailing.equalTo(white).offset(-16);
        make.height.mas_equalTo(140);
    }];
    [_addConsumeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(leagueCard.mas_bottom).offset(14);
        make.leading.equalTo(white).offset(16);
        make.trailing.equalTo(white.mas_centerX).offset(-8);
        make.height.mas_equalTo(40);
    }];
    [_stampBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(leagueCard.mas_bottom).offset(14);
        make.leading.equalTo(white.mas_centerX).offset(8);
        make.trailing.equalTo(white).offset(-16);
        make.height.mas_equalTo(40);
    }];
    [_upcomingPill mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_addConsumeBtn.mas_bottom).offset(14);
        make.leading.equalTo(white).offset(16);
        make.height.mas_equalTo(36);
        make.trailing.equalTo(white.mas_centerX).offset(-8);
    }];
    [_finishedPill mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_addConsumeBtn.mas_bottom).offset(14);
        make.leading.equalTo(white.mas_centerX).offset(8);
        make.height.mas_equalTo(36);
        make.trailing.equalTo(white).offset(-16);
    }];
    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_upcomingPill.mas_bottom).offset(10);
        make.leading.trailing.equalTo(white);
        self.tableHeightConstraint = make.height.mas_equalTo(0);
        make.bottom.equalTo(white).offset(-24);
    }];
}

- (void)loadFakeData {
    NSMutableArray *upcoming = [NSMutableArray array];
    NSMutableArray *finished = [NSMutableArray array];

    // 未来观赛：中间展示时间，右侧为「认证球票」（假数据多一些）
    NSArray *upcomingRaw = @[
        @[ @"诺丁汉森林队", @"利物浦", @"06:30", @"15 Dec, 2025", @"认证球票" ],
        @[ @"曼城", @"布莱顿", @"07:30", @"16 Dec, 2025", @"认证球票" ],
        @[ @"狼队", @"阿森纳", @"08:30", @"16 Dec, 2025", @"认证球票" ],
        @[ @"伯恩利", @"布伦特福德", @"09:00", @"17 Dec, 2025", @"认证球票" ],
        @[ @"阿森纳", @"布莱顿", @"11:00", @"18 Dec, 2025", @"认证球票" ],
        @[ @"曼联", @"切尔西", @"19:30", @"18 Dec, 2025", @"认证球票" ],
        @[ @"热刺", @"曼城", @"20:00", @"19 Dec, 2025", @"认证球票" ],
        @[ @"利物浦", @"狼队", @"21:15", @"19 Dec, 2025", @"认证球票" ]
    ];
    for (NSArray *info in upcomingRaw) {
        DiscoverMatch *m = [DiscoverMatch new];
        m.homeName = info[0];
        m.awayName = info[1];
        m.scoreText = info[2]; // 复用字段显示时间
        m.dateText = info[3];
        m.verifiedText = info[4];
        m.type = DiscoverMatchTypeUpcoming;
        [upcoming addObject:m];
    }

    // 已经观赛：中间展示比分，右侧为「已认证xx分钟」
    NSArray *finishedRaw = @[
        @[ @"阿森纳", @"布莱顿", @"2 : 0", @"15 Dec, 2025", @"已认证98分钟" ],
        @[ @"阿森纳", @"布莱顿", @"3 : 1", @"12 Dec, 2025", @"已认证123分钟" ],
        @[ @"曼城", @"利物浦", @"1 : 1", @"10 Dec, 2025", @"已认证104分钟" ],
        @[ @"狼队", @"阿森纳", @"0 : 2", @"08 Dec, 2025", @"已认证91分钟" ],
        @[ @"诺丁汉森林队", @"利物浦", @"0 : 2", @"05 Dec, 2025", @"已认证110分钟" ],
        @[ @"伯恩利", @"布伦特福德", @"2 : 1", @"02 Dec, 2025", @"已认证96分钟" ]
    ];
    for (NSArray *info in finishedRaw) {
        DiscoverMatch *m = [DiscoverMatch new];
        m.homeName = info[0];
        m.awayName = info[1];
        m.scoreText = info[2];
        m.dateText = info[3];
        m.verifiedText = info[4];
        m.type = DiscoverMatchTypeFinished;
        [finished addObject:m];
    }

    self.upcomingMatches = upcoming;
    self.finishedMatches = finished;

    [self.upcomingPill setTitle:[NSString stringWithFormat:@"未来观赛(%ld)", (long)upcoming.count] forState:UIControlStateNormal];
    [self.finishedPill setTitle:[NSString stringWithFormat:@"已经观赛(%ld)", (long)finished.count] forState:UIControlStateNormal];

    self.statAValue.text = @"29";
    self.statBValue.text = @"3455";
    self.statCValue.text = @"18";
    self.statDValue.text = @"4";
    self.statEValue.text = @"6";
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
    // 未选中按原型：不显示描边
    self.upcomingPill.layer.borderWidth = 0;
    self.finishedPill.layer.borderWidth = 0;
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

- (void)onConsumeRecordTapped {
    ConsumptionRecordViewController *vc = [[ConsumptionRecordViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)updateTableHeight {
    NSInteger rows = [self currentDataSource].count;
    self.tableHeightConstraint.offset = rows * 86.f;
    [self.view layoutIfNeeded];
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self currentDataSource].count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 86;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DiscoverMatchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DiscoverMatchCell" forIndexPath:indexPath];
    DiscoverMatch *m = [self currentDataSource][indexPath.row];

    cell.homeLabel.text = m.homeName;
    cell.awayLabel.text = m.awayName;
    cell.scoreLabel.text = m.scoreText;
    cell.dateLabel.text = m.dateText;

    if (m.type == DiscoverMatchTypeUpcoming) {
        // 未来观赛：不显示输入信息、认证比赛按钮
        cell.inputButton.hidden = YES;
        cell.verifiedPill.hidden = YES;
        cell.scoreLabel.font = [UIFont boldSystemFontOfSize:14];
    } else {
        // 已经观赛：显示输入信息、认证比赛按钮
        cell.inputButton.hidden = NO;
        cell.verifiedPill.hidden = NO;
        [cell.verifiedPill setTitle:@"认证比赛" forState:UIControlStateNormal];
        cell.verifiedPill.backgroundColor = kDiscoverPillGreen;
        cell.verifiedPill.layer.borderWidth = 0;
        [cell.verifiedPill setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        if (@available(iOS 13.0, *)) {
            UIImage *img = [UIImage systemImageNamed:@"camera.fill"];
            [cell.verifiedPill setImage:img forState:UIControlStateNormal];
            cell.verifiedPill.tintColor = [UIColor whiteColor];
        }
        cell.scoreLabel.font = [UIFont boldSystemFontOfSize:16];

        // 点击“认证比赛”进入认证弹层
        [cell.verifiedPill removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [cell.verifiedPill addTarget:self action:@selector(onVerifyMatchButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
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

- (void)onVerifyMatchButtonTapped:(UIButton *)sender {
    CGPoint pointInTable = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:pointInTable];
    if (!indexPath) return;
    DiscoverMatch *m = [self currentDataSource][indexPath.row];
    if (m.type != DiscoverMatchTypeFinished) return;

    PNMatchVerifyViewController *vc = [[PNMatchVerifyViewController alloc] init];
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:vc animated:NO completion:nil];
}

@end
