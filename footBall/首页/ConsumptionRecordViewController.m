//
//  ConsumptionRecordViewController.m
//  footBall
//

#import "ConsumptionRecordViewController.h"
#import "MoreDatePickerController.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>
#import "ColorManager.h"

static UIColor *kConsumeGreen(void) {
    return [ColorManager sharedManager].primaryColor;
}

/// Figma Grayscale 60 — 周几
static UIColor *kConsumeWeekdayMuted(void) {
    return [UIColor colorWithRed:0.612f green:0.643f blue:0.671f alpha:1.0]; // #9CA4AB
}

/// Figma 未选中日期数字
static UIColor *kConsumeDayNumberDefault(void) {
    return [UIColor colorWithRed:0.345f green:0.255f blue:0.255f alpha:1.0]; // #584141
}

/// 优先使用 Assets 中 `Calendar` 图集，缺失时再用 SF Symbol `calendar`
static UIImage *kConsumeCalendarBarIcon(void) {
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

@interface ConsumeRecordCell : UITableViewCell
@property (nonatomic, strong) UIView *iconWrap;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *amountLabel;
@end

@implementation ConsumeRecordCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];

        UIView *card = [[UIView alloc] init];
        card.backgroundColor = [UIColor colorWithRed:0.961f green:0.961f blue:0.961f alpha:1.0]; // #F5F5F5
        card.layer.cornerRadius = 8;
        card.tag = 999;
        [self.contentView addSubview:card];
        [card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(4, 16, 4, 16));
        }];

        _iconWrap = [[UIView alloc] init];
        _iconWrap.backgroundColor = [UIColor whiteColor];
        _iconWrap.layer.cornerRadius = 25;
        _iconWrap.layer.masksToBounds = YES;

        _iconView = [[UIImageView alloc] init];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        _iconView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
        _iconView.layer.cornerRadius = 20;
        _iconView.clipsToBounds = YES;

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
        _titleLabel.textColor = [UIColor colorWithWhite:0.15 alpha:1.0];

        _timeLabel = [[UILabel alloc] init];
        _timeLabel.font = [UIFont systemFontOfSize:12];
        _timeLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];

        _amountLabel = [[UILabel alloc] init];
        _amountLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
        _amountLabel.textColor = [UIColor colorWithWhite:0.15 alpha:1.0];
        _amountLabel.textAlignment = NSTextAlignmentRight;

        [card addSubview:_iconWrap];
        [_iconWrap addSubview:_iconView];
        [card addSubview:_titleLabel];
        [card addSubview:_timeLabel];
        [card addSubview:_amountLabel];

        [_iconWrap mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(card).offset(11);
            make.centerY.equalTo(card);
            make.width.height.mas_equalTo(50);
        }];
        [_iconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(_iconWrap);
            make.width.height.mas_equalTo(40);
        }];
        [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_iconWrap.mas_trailing).offset(12);
            make.trailing.lessThanOrEqualTo(_amountLabel.mas_leading).offset(-8);
            make.top.equalTo(card).offset(15);
        }];
        [_timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_titleLabel);
            make.top.equalTo(_titleLabel.mas_bottom).offset(4);
        }];
        [_amountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(card).offset(-16);
            make.centerY.equalTo(card);
            make.width.mas_greaterThanOrEqualTo(80);
        }];
    }
    return self;
}

@end

#pragma mark -

@interface ConsumptionRecordViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UIView *topBar;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *dateHeader;
@property (nonatomic, strong) UILabel *monthLabel;
@property (nonatomic, strong) UIButton *calendarButton;
@property (nonatomic, strong) NSArray<UIControl *> *weekDayViews;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSDate *selectedDate;
@property (nonatomic, strong) NSDate *weekStartDate;
@property (nonatomic, strong) NSCalendar *calendar;
@property (nonatomic, strong) NSArray<PNExpense *> *records;
@end

@implementation ConsumptionRecordViewController

/// 解析单条消费的时间，用于排序与按日筛选
- (NSDate *)parseAPIInstant:(NSString *)raw {
    if (raw.length == 0) return nil;
    NSDateFormatter *f = [[NSDateFormatter alloc] init];
    f.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    NSArray<NSString *> *fmts = @[
        @"yyyy-MM-dd'T'HH:mm:ssZ",
        @"yyyy-MM-dd'T'HH:mm:ss.SSSZ",
        @"yyyy-MM-dd HH:mm:ss",
        @"yyyy-MM-dd"
    ];
    for (NSString *fmt in fmts) {
        f.dateFormat = fmt;
        NSDate *d = [f dateFromString:raw];
        if (d) return d;
    }
    return nil;
}

- (NSDate *)eventDateForExpense:(PNExpense *)e {
    NSString *raw = e.expenseDate.length ? e.expenseDate : e.createTime;
    NSDate *d = [self parseAPIInstant:raw];
    if (!d && e.createTime.length) d = [self parseAPIInstant:e.createTime];
    return d;
}

- (BOOL)expense:(PNExpense *)e matchesCalendarDayString:(NSString *)dayStr {
    if (dayStr.length < 10) return NO;
    NSString *pre = [dayStr substringToIndex:10];
    NSString *ed = e.expenseDate ?: @"";
    NSString *ct = e.createTime ?: @"";
    if (ed.length >= 10 && [[ed substringToIndex:10] isEqualToString:pre]) return YES;
    if (ct.length >= 10 && [[ct substringToIndex:10] isEqualToString:pre]) return YES;
    return NO;
}

- (NSArray<PNExpense *> *)filterAndSortExpenses:(NSArray<PNExpense *> *)all
                                  forCalendarDay:(NSDate *)day
                                       dayString:(NSString *)dayStr {
    if (!day || all.count == 0) return all ?: @[];
    NSMutableArray<PNExpense *> *m = [NSMutableArray array];
    for (PNExpense *e in all) {
        NSDate *d = [self eventDateForExpense:e];
        if (d && [self isSameDay:d other:day]) {
            [m addObject:e];
        }
    }
    if (m.count == 0 && all.count > 0) {
        for (PNExpense *e in all) {
            if ([self expense:e matchesCalendarDayString:dayStr]) {
                [m addObject:e];
            }
        }
    }
    [m sortUsingComparator:^NSComparisonResult(PNExpense *a, PNExpense *b) {
        NSDate *da = [self eventDateForExpense:a];
        NSDate *db = [self eventDateForExpense:b];
        if (!da && !db) return NSOrderedSame;
        if (!da) return NSOrderedAscending;
        if (!db) return NSOrderedDescending;
        return [db compare:da];
    }];
    return [m copy];
}

- (NSString *)displayAmountForExpense:(PNExpense *)e {
    id v = e.amount;
    if ([v isKindOfClass:[NSNumber class]]) {
        return [NSString stringWithFormat:@"-%0.2f", [(NSNumber *)v doubleValue]];
    }
    if ([v isKindOfClass:[NSString class]]) {
        NSString *s = [(NSString *)v stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (s.length == 0) return @"-0";
        if ([s hasPrefix:@"-"]) return s;
        return [NSString stringWithFormat:@"-%@", s];
    }
    return @"-0";
}

- (void)updateConsumeEmptyState {
    if (self.records.count > 0) {
        self.tableView.backgroundView = nil;
        return;
    }
    UILabel *hint = [[UILabel alloc] init];
    hint.text = NSLocalizedString(@"consume_record_empty", nil) ?: @"暂无消费记录";
    hint.font = [UIFont systemFontOfSize:14];
    hint.textColor = [UIColor colorWithWhite:0.55 alpha:1.0];
    hint.textAlignment = NSTextAlignmentCenter;
    self.tableView.backgroundView = hint;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hidesBottomBarWhenPushed = YES;
    self.shouldShowNavigationBar = NO;
    self.view.backgroundColor = [UIColor whiteColor];
    self.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    self.calendar.firstWeekday = 1;
    self.calendar.timeZone = [NSTimeZone localTimeZone];
    self.selectedDate = [NSDate date];
    self.records = @[];

    [self buildTopBar];
    [self buildDateHeader];
    [self buildTable];
    [self updateWeekHeaderForSelectedDate];
    [self updateConsumeEmptyState];
    [self reloadRecordsForSelectedDate];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onExpenseDidCreateNotification:) name:@"PNExpenseDidCreate" object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PNExpenseDidCreate" object:nil];
}

- (void)onExpenseDidCreateNotification:(NSNotification *)n {
    (void)n;
    [self reloadRecordsForSelectedDate];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tabBarController.tabBar.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.tabBarController.tabBar.hidden = NO;
}

- (void)buildTopBar {
    UIView *bar = [[UIView alloc] init];
    bar.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:bar];
    self.topBar = bar;

    UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *backImg = [UIImage imageNamed:@"nav_back"];
    if (!backImg && @available(iOS 13.0, *)) {
        backImg = [UIImage systemImageNamed:@"chevron.left"];
    }
    if (backImg) {
        [back setImage:[backImg imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        back.tintColor = [UIColor blackColor];
    }
    back.imageView.contentMode = UIViewContentModeScaleAspectFit;
    back.adjustsImageWhenHighlighted = NO;
    [back addTarget:self action:@selector(onBack) forControlEvents:UIControlEventTouchUpInside];

    UILabel *title = [[UILabel alloc] init];
    title.text = NSLocalizedString(@"consume_record_title", nil) ?: @"消费记录";
    title.font = [UIFont boldSystemFontOfSize:18];
    title.textAlignment = NSTextAlignmentCenter;

    [bar addSubview:back];
    [bar addSubview:title];
    self.backButton = back;
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
    [title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(bar);
        make.centerY.equalTo(bar);
    }];
}

- (void)buildDateHeader {
    UIView *header = [[UIView alloc] init];
    header.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:header];
    self.dateHeader = header;

    self.monthLabel = [[UILabel alloc] init];
    self.monthLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.monthLabel.textColor = [UIColor blackColor];
    self.monthLabel.textAlignment = NSTextAlignmentCenter;
    [header addSubview:self.monthLabel];

    UIButton *calendarBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImage *calImg = kConsumeCalendarBarIcon();
    if (calImg) {
        [calendarBtn setImage:calImg forState:UIControlStateNormal];
    }
    calendarBtn.tintColor = [UIColor blackColor];
    [calendarBtn addTarget:self action:@selector(onCalendarTapped) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:calendarBtn];
    self.calendarButton = calendarBtn;

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
    [calendarBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(header).offset(-16);
        make.centerY.equalTo(self.monthLabel);
        make.width.height.mas_equalTo(24);
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
        [day addTarget:self action:@selector(onWeekDayTapped:) forControlEvents:UIControlEventTouchUpInside];
        [weekRow addSubview:day];

        UIView *pill = [[UIView alloc] init];
        pill.tag = 201;
        pill.backgroundColor = kConsumeGreen();
        pill.layer.cornerRadius = 6;
        pill.hidden = YES;
        [day insertSubview:pill atIndex:0];
        [pill mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.centerY.equalTo(day);
            make.width.mas_equalTo(38);
            make.height.mas_equalTo(56);
        }];

        UILabel *weekLab = [[UILabel alloc] init];
        weekLab.textAlignment = NSTextAlignmentCenter;
        weekLab.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
        weekLab.textColor = kConsumeWeekdayMuted();
        weekLab.text = weekTitles[i];

        UILabel *dateLab = [[UILabel alloc] init];
        dateLab.textAlignment = NSTextAlignmentCenter;
        dateLab.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        dateLab.textColor = kConsumeDayNumberDefault();
        dateLab.tag = 200;

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
            make.top.equalTo(weekLab.mas_bottom).offset(2);
            make.leading.trailing.equalTo(day);
        }];
        [views addObject:day];
    }
    self.weekDayViews = [views copy];
}

- (void)buildTable {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor whiteColor];
    [self.tableView registerClass:[ConsumeRecordCell class] forCellReuseIdentifier:@"ConsumeRecordCell"];
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.dateHeader.mas_bottom);
        make.leading.trailing.bottom.equalTo(self.view);
    }];
}

- (void)updateWeekHeaderForSelectedDate {
    if (!self.selectedDate || self.weekDayViews.count == 0) return;

    NSDateComponents *weekdayComp = [self.calendar components:NSCalendarUnitWeekday fromDate:self.selectedDate];
    NSInteger weekday = weekdayComp.weekday;
    NSInteger daysToSubtract = weekday - 1;
    NSDate *startOfWeek = [self.calendar dateByAddingUnit:NSCalendarUnitDay value:-daysToSubtract toDate:self.selectedDate options:0];
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

        UILabel *weekLab = nil;
        UILabel *dateLab = nil;
        for (UIView *sub in dayView.subviews) {
            if (![sub isKindOfClass:[UILabel class]]) continue;
            UILabel *lab = (UILabel *)sub;
            if (lab.tag == 200) dateLab = lab;
            else weekLab = lab;
        }
        if (dateLab) dateLab.text = dayString;

        UIView *pill = [dayView viewWithTag:201];
        BOOL isSameDay = [self isSameDay:date other:self.selectedDate];
        pill.hidden = !isSameDay;

        if (!weekLab || !dateLab) continue;
        if (isSameDay) {
            weekLab.textColor = [UIColor whiteColor];
            dateLab.textColor = [UIColor whiteColor];
            dateLab.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        } else {
            weekLab.textColor = kConsumeWeekdayMuted();
            dateLab.textColor = kConsumeDayNumberDefault();
            dateLab.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        }
    }
}

- (BOOL)isSameDay:(NSDate *)a other:(NSDate *)b {
    if (!a || !b) return NO;
    NSDateComponents *c1 = [self.calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:a];
    NSDateComponents *c2 = [self.calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:b];
    return (c1.year == c2.year && c1.month == c2.month && c1.day == c2.day);
}

- (void)reloadRecordsForSelectedDate {
    NSDate *day = self.selectedDate ?: [NSDate date];
    NSDateFormatter *ym = [[NSDateFormatter alloc] init];
    ym.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    ym.dateFormat = @"yyyy-MM";
    NSString *monthStr = [ym stringFromDate:day];
    NSDateFormatter *ymd = [[NSDateFormatter alloc] init];
    ymd.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    ymd.dateFormat = @"yyyy-MM-dd";
    NSString *dayStr = [ymd stringFromDate:day];

    __weak typeof(self) weakSelf = self;
    [[ExpenseRequest shared] getExpensesWithMonth:monthStr date:dayStr page:1 pageSize:100 success:^(HTTPResponse * _Nullable responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            PNExpensePage *page = [responseObject.dataObject isKindOfClass:PNExpensePage.class] ? responseObject.dataObject : nil;
            NSArray<PNExpense *> *list = page.list ?: @[];
            weakSelf.records = [weakSelf filterAndSortExpenses:list forCalendarDay:day dayString:dayStr];
            [weakSelf.tableView reloadData];
            [weakSelf updateConsumeEmptyState];
        });
    } failure:^(NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.records = @[];
            [weakSelf.tableView reloadData];
            [weakSelf updateConsumeEmptyState];
        });
    }];
}

- (NSString *)shortTimeFromString:(NSString *)raw {
    if (raw.length == 0) return @"--:--";
    NSDateFormatter *input = [[NSDateFormatter alloc] init];
    input.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    input.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
    NSDate *date = [input dateFromString:raw];
    if (!date) {
        input.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        date = [input dateFromString:raw];
    }
    if (!date) {
        input.dateFormat = @"yyyy-MM-dd";
        date = [input dateFromString:raw];
    }
    if (!date) return @"--:--";
    NSDateFormatter *output = [[NSDateFormatter alloc] init];
    output.dateFormat = @"HH:mm";
    return [output stringFromDate:date];
}

#pragma mark - Actions

- (void)onBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onCalendarTapped {
    MoreDatePickerController *vc = [MoreDatePickerController new];
    vc.selectedDate = self.selectedDate;
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    __weak typeof(self) weakSelf = self;
    vc.onConfirm = ^(NSDate *date) {
        weakSelf.selectedDate = date;
        [weakSelf updateWeekHeaderForSelectedDate];
        [weakSelf reloadRecordsForSelectedDate];
    };
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)onWeekDayTapped:(UIControl *)sender {
    NSInteger index = sender.tag;
    if (self.weekStartDate) {
        NSDate *date = [self.calendar dateByAddingUnit:NSCalendarUnitDay value:index toDate:self.weekStartDate options:0];
        self.selectedDate = date;
        [self updateWeekHeaderForSelectedDate];
        [self reloadRecordsForSelectedDate];
    }
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)(self.records ?: @[]).count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 82;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ConsumeRecordCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ConsumeRecordCell" forIndexPath:indexPath];
    PNExpense *item = self.records[indexPath.row];
    cell.titleLabel.text = item.itemName.length > 0 ? item.itemName : @"消费";
    NSString *timeRaw = item.createTime.length ? item.createTime : item.expenseDate;
    cell.timeLabel.text = [self shortTimeFromString:timeRaw];
    cell.amountLabel.text = [self displayAmountForExpense:item];
    cell.iconView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    NSURL *logoURL = [NSURL URLWithString:item.logoUrl ?: @""];
    if (logoURL && logoURL.scheme.length) {
        [cell.iconView sd_setImageWithURL:logoURL placeholderImage:nil options:SDWebImageRetryFailed];
    } else {
        [cell.iconView sd_cancelCurrentImageLoad];
        cell.iconView.image = nil;
    }
    return cell;
}

@end
