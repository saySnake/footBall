//
//  MoreMatchesViewController.m
//  footBall
//

#import "MoreMatchesViewController.h"
#import "MoreDatePickerController.h"
#import <Masonry/Masonry.h>

@interface MoreMatchCell : UITableViewCell
@property (nonatomic, strong) UIImageView *homeLogo;
@property (nonatomic, strong) UIImageView *awayLogo;
@property (nonatomic, strong) UILabel *homeLabel;
@property (nonatomic, strong) UILabel *awayLabel;
@property (nonatomic, strong) UIButton *timePill;
@property (nonatomic, strong) UIButton *shareBtn;
@end

@implementation MoreMatchCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];

        UIView *card = [[UIView alloc] init];
        card.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1.0];
        card.layer.cornerRadius = 12;
        [self.contentView addSubview:card];
        [card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(4, 16, 4, 16));
        }];

        _homeLogo = [[UIImageView alloc] init];
        _awayLogo = [[UIImageView alloc] init];
        _homeLogo.contentMode = _awayLogo.contentMode = UIViewContentModeScaleAspectFit;
        _homeLogo.layer.cornerRadius = _awayLogo.layer.cornerRadius = 14;
        _homeLogo.clipsToBounds = _awayLogo.clipsToBounds = YES;

        _homeLabel = [[UILabel alloc] init];
        _awayLabel = [[UILabel alloc] init];
        _homeLabel.font = _awayLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];

        _timePill = [UIButton buttonWithType:UIButtonTypeSystem];
        _timePill.titleLabel.font = [UIFont systemFontOfSize:12];
        [_timePill setTitleColor:[UIColor colorWithRed:0.20 green:0.45 blue:0.33 alpha:1.0] forState:UIControlStateNormal];
        _timePill.layer.cornerRadius = 12;
        _timePill.layer.borderWidth = 1;
        _timePill.layer.borderColor = [UIColor colorWithRed:0.20 green:0.45 blue:0.33 alpha:1.0].CGColor;

        _shareBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        if (@available(iOS 13.0, *)) {
            [_shareBtn setImage:[UIImage systemImageNamed:@"square.and.arrow.up"] forState:UIControlStateNormal];
            _shareBtn.tintColor = [UIColor blackColor];
        }

        [card addSubview:_homeLogo];
        [card addSubview:_homeLabel];
        [card addSubview:_awayLogo];
        [card addSubview:_awayLabel];
        [card addSubview:_timePill];
        [card addSubview:_shareBtn];

        [_homeLogo mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(card).offset(16);
            make.centerY.equalTo(card);
            make.width.height.mas_equalTo(28);
        }];
        [_homeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_homeLogo.mas_trailing).offset(8);
            make.centerY.equalTo(_homeLogo);
        }];
        [_awayLogo mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(card.mas_centerX).offset(8);
            make.centerY.equalTo(card);
            make.width.height.mas_equalTo(28);
        }];
        [_awayLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_awayLogo.mas_trailing).offset(8);
            make.centerY.equalTo(_awayLogo);
        }];
        [_shareBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(card).offset(-16);
            make.centerY.equalTo(card);
            make.width.height.mas_equalTo(28);
        }];
        [_timePill mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(card);
            make.trailing.equalTo(_shareBtn.mas_leading).offset(-12);
            make.height.mas_equalTo(24);
            make.width.mas_greaterThanOrEqualTo(64);
        }];
    }
    return self;
}

@end

#pragma mark - MoreMatchesViewController

@interface MoreMatchesViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UIView *topBar;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *calendarButton;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *monthLabel;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<Match *> *matches;
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
    if (@available(iOS 13.0, *)) {
        [back setImage:[UIImage systemImageNamed:@"chevron.left"] forState:UIControlStateNormal];
    }
    back.tintColor = [UIColor blackColor];
    [back addTarget:self action:@selector(onBack) forControlEvents:UIControlEventTouchUpInside];

    UIButton *calendar = [UIButton buttonWithType:UIButtonTypeSystem];
    if (@available(iOS 13.0, *)) {
        [calendar setImage:[UIImage systemImageNamed:@"calendar"] forState:UIControlStateNormal];
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
        make.width.height.mas_equalTo(28);
    }];
    [calendar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(bar).offset(-16);
        make.centerY.equalTo(bar);
        make.width.height.mas_equalTo(28);
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
    self.monthLabel.font = [UIFont boldSystemFontOfSize:18];
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
        make.top.equalTo(header).offset(12);
        make.centerX.equalTo(header);
    }];
    [weekRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.monthLabel.mas_bottom).offset(12);
        make.leading.trailing.equalTo(header);
        make.height.mas_equalTo(56);
        make.bottom.equalTo(header);
    }];

    CGFloat width = [UIScreen mainScreen].bounds.size.width / 7.0;
    NSMutableArray<UIControl *> *views = [NSMutableArray array];
    for (NSInteger i = 0; i < 7; i++) {
        UIControl *day = [[UIControl alloc] initWithFrame:CGRectZero];
        day.backgroundColor = [UIColor clearColor];
        day.tag = i;
        [day addTarget:self action:@selector(onWeekTapped:) forControlEvents:UIControlEventTouchUpInside];
        [weekRow addSubview:day];

        UILabel *weekLab = [[UILabel alloc] init];
        weekLab.textAlignment = NSTextAlignmentCenter;
        weekLab.font = [UIFont systemFontOfSize:11];
        weekLab.textColor = [UIColor darkGrayColor];
        weekLab.text = weekTitles[i];

        UILabel *dateLab = [[UILabel alloc] init];
        dateLab.textAlignment = NSTextAlignmentCenter;
        dateLab.font = [UIFont boldSystemFontOfSize:14];
        dateLab.textColor = [UIColor blackColor];
        dateLab.tag = 200; // 用于后续更新日期

        [day addSubview:weekLab];
        [day addSubview:dateLab];

        [day mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(weekRow);
            make.width.mas_equalTo(width);
            make.leading.equalTo(weekRow.mas_leading).offset(width * i);
        }];
        [weekLab mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(day).offset(4);
            make.leading.trailing.equalTo(day);
        }];
        [dateLab mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(weekLab.mas_bottom).offset(4);
            make.leading.trailing.equalTo(day);
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
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        // 列表紧跟在头部（月份 + 星期行）下面
        make.top.equalTo(self.monthLabel.superview.mas_bottom);
        make.leading.trailing.bottom.equalTo(self.view);
    }];
}

- (void)reloadDataForSelectedDate {
    if (!self.selectedDate) self.selectedDate = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    NSString *dateStr = [formatter stringFromDate:self.selectedDate];
    __weak typeof(self) weakSelf = self;
    [[MatchRequest shared] getMatchScheduleWithDate:dateStr myTeamOnly:NO page:1 pageSize:50 success:^(HTTPResponse * _Nullable responseObject) {
        NSArray *matches = [responseObject.dataObject isKindOfClass:NSArray.class] ? responseObject.dataObject : @[];
        weakSelf.matches = matches;
        [weakSelf.tableView reloadData];
    } failure:^(NSError * _Nonnull error) {
        weakSelf.matches = @[];
        [weakSelf.tableView reloadData];
    }];
}

- (NSString *)timeTextFromMatchDate:(NSString *)matchDate {
    if (matchDate.length == 0) return @"--:--";
    NSDateFormatter *input = [[NSDateFormatter alloc] init];
    input.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    input.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
    NSDate *date = [input dateFromString:matchDate];
    if (!date) {
        input.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        date = [input dateFromString:matchDate];
    }
    if (!date) return @"--:--";
    NSDateFormatter *output = [[NSDateFormatter alloc] init];
    output.dateFormat = @"HH:mm";
    return [output stringFromDate:date];
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
        UIControl *dayView = self.weekDayViews[i];
        NSDate *date = [self.calendar dateByAddingUnit:NSCalendarUnitDay value:i toDate:self.weekStartDate options:0];
        NSString *dayString = [dayFmt stringFromDate:date];

        UILabel *dateLab = nil;
        for (UIView *sub in dayView.subviews) {
            if (sub.tag == 200 && [sub isKindOfClass:[UILabel class]]) {
                dateLab = (UILabel *)sub;
                break;
            }
        }
        dateLab.text = dayString;

        // 高亮当前选中的那一天
        BOOL isSameDay = [self isSameDay:date other:self.selectedDate];
        if (isSameDay) {
            dayView.backgroundColor = [ColorManager sharedManager].primaryColor;
            dayView.layer.cornerRadius = 8;
            dayView.layer.masksToBounds = YES;
            for (UIView *sub in dayView.subviews) {
                if ([sub isKindOfClass:[UILabel class]]) {
                    ((UILabel *)sub).textColor = [UIColor whiteColor];
                }
            }
        } else {
            dayView.backgroundColor = [UIColor clearColor];
            dayView.layer.cornerRadius = 0;
            for (UIView *sub in dayView.subviews) {
                if ([sub isKindOfClass:[UILabel class]]) {
                    UILabel *lab = (UILabel *)sub;
                    if (lab.tag == 200) {
                        lab.textColor = [UIColor blackColor];
                    } else {
                        lab.textColor = [UIColor darkGrayColor];
                    }
                }
            }
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
    return 64;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MoreMatchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MoreMatchCell" forIndexPath:indexPath];
    Match *m = self.matches[indexPath.row];
    cell.homeLabel.text = m.homeTeamName ?: @"-";
    cell.awayLabel.text = m.awayTeamName ?: @"-";
    [cell.timePill setTitle:[self timeTextFromMatchDate:m.matchDate] forState:UIControlStateNormal];
    cell.homeLogo.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    cell.awayLogo.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    return cell;
}

@end

