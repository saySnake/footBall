//
//  ConsumptionRecordViewController.m
//  footBall
//

#import "ConsumptionRecordViewController.h"
#import "MoreDatePickerController.h"
#import <Masonry/Masonry.h>
#import "ColorManager.h"

static UIColor *kConsumeGreen(void) {
    return [ColorManager sharedManager].primaryColor;
}

@interface ConsumeRecordItem : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *time;
@property (nonatomic, copy) NSString *amount;
@property (nonatomic, strong) UIImage *iconImage;
@end
@implementation ConsumeRecordItem
@end

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
        card.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1.0];
        card.layer.cornerRadius = 12;
        card.tag = 999;
        [self.contentView addSubview:card];
        [card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(4, 16, 4, 16));
        }];

        _iconWrap = [[UIView alloc] init];
        _iconWrap.backgroundColor = [UIColor whiteColor];
        _iconWrap.layer.cornerRadius = 22;
        _iconWrap.layer.masksToBounds = YES;
        if (@available(iOS 13.0, *)) {
            _iconWrap.layer.shadowColor = [UIColor blackColor].CGColor;
            _iconWrap.layer.shadowOpacity = 0.08;
            _iconWrap.layer.shadowOffset = CGSizeMake(0, 1);
            _iconWrap.layer.shadowRadius = 3;
        }

        _iconView = [[UIImageView alloc] init];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        _iconView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
        _iconView.layer.cornerRadius = 20;
        _iconView.clipsToBounds = YES;

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
        _titleLabel.textColor = [UIColor colorWithWhite:0.15 alpha:1.0];

        _timeLabel = [[UILabel alloc] init];
        _timeLabel.font = [UIFont systemFontOfSize:12];
        _timeLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];

        _amountLabel = [[UILabel alloc] init];
        _amountLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
        _amountLabel.textColor = [UIColor colorWithWhite:0.15 alpha:1.0];
        _amountLabel.textAlignment = NSTextAlignmentRight;

        [card addSubview:_iconWrap];
        [_iconWrap addSubview:_iconView];
        [card addSubview:_titleLabel];
        [card addSubview:_timeLabel];
        [card addSubview:_amountLabel];

        [_iconWrap mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(card).offset(16);
            make.centerY.equalTo(card);
            make.width.height.mas_equalTo(44);
        }];
        [_iconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(_iconWrap);
            make.width.height.mas_equalTo(40);
        }];
        [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_iconWrap.mas_trailing).offset(12);
            make.trailing.lessThanOrEqualTo(_amountLabel.mas_leading).offset(-8);
            make.top.equalTo(card).offset(14);
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
@property (nonatomic, strong) NSArray<ConsumeRecordItem *> *records;
@end

@implementation ConsumptionRecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hidesBottomBarWhenPushed = YES;
    self.shouldShowNavigationBar = NO;
    self.view.backgroundColor = [UIColor whiteColor];
    self.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    self.calendar.firstWeekday = 1;
    self.calendar.timeZone = [NSTimeZone localTimeZone];
    self.selectedDate = [NSDate date];

    [self buildTopBar];
    [self buildDateHeader];
    [self buildTable];
    [self updateWeekHeaderForSelectedDate];
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

    UIButton *back = [UIButton buttonWithType:UIButtonTypeSystem];
    if (@available(iOS 13.0, *)) {
        [back setImage:[UIImage systemImageNamed:@"chevron.left"] forState:UIControlStateNormal];
    }
    back.tintColor = [UIColor blackColor];
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
        make.width.height.mas_equalTo(28);
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
    self.monthLabel.font = [UIFont boldSystemFontOfSize:18];
    self.monthLabel.textColor = [UIColor colorWithWhite:0.15 alpha:1.0];
    self.monthLabel.textAlignment = NSTextAlignmentLeft;
    [header addSubview:self.monthLabel];

    UIButton *calendarBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    if (@available(iOS 13.0, *)) {
        [calendarBtn setImage:[UIImage systemImageNamed:@"calendar"] forState:UIControlStateNormal];
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
        make.leading.equalTo(header).offset(16);
    }];
    [calendarBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(header).offset(-16);
        make.centerY.equalTo(self.monthLabel);
        make.width.height.mas_equalTo(28);
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

        UILabel *weekLab = [[UILabel alloc] init];
        weekLab.textAlignment = NSTextAlignmentCenter;
        weekLab.font = [UIFont systemFontOfSize:11];
        weekLab.textColor = [UIColor darkGrayColor];
        weekLab.text = weekTitles[i];

        UILabel *dateLab = [[UILabel alloc] init];
        dateLab.textAlignment = NSTextAlignmentCenter;
        dateLab.font = [UIFont boldSystemFontOfSize:14];
        dateLab.textColor = [UIColor blackColor];
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
            make.top.equalTo(weekLab.mas_bottom).offset(4);
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

        UILabel *dateLab = nil;
        for (UIView *sub in dayView.subviews) {
            if (sub.tag == 200 && [sub isKindOfClass:[UILabel class]]) {
                dateLab = (UILabel *)sub;
                break;
            }
        }
        dateLab.text = dayString;

        BOOL isSameDay = [self isSameDay:date other:self.selectedDate];
        if (isSameDay) {
            dayView.backgroundColor = kConsumeGreen();
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

- (void)reloadRecordsForSelectedDate {
    // 假数据：根据选中日期构造不同的消费记录，切换日期时列表内容会变化
    NSInteger day = 0, month = 0;
    if (self.selectedDate) {
        NSDateComponents *comp = [self.calendar components:NSCalendarUnitDay|NSCalendarUnitMonth fromDate:self.selectedDate];
        day = comp.day;
        month = comp.month;
    }
    NSInteger seed = day * 7 + (month % 5);

    NSArray *allTemplates = @[
        @[ @"消费标题", @"10:30", @"-800.00" ],
        @[ @"赛事周边购买", @"14:00", @"-299.00" ],
        @[ @"观赛门票", @"18:45", @"-1200.00" ],
        @[ @"球场餐饮", @"12:15", @"-65.00" ],
        @[ @"会员续费", @"09:00", @"-199.00" ],
        @[ @"球衣定制", @"11:20", @"-458.00" ],
        @[ @"VIP包厢", @"19:00", @"-2680.00" ],
        @[ @"停车费", @"08:45", @"-30.00" ],
        @[ @"纪念品", @"16:30", @"-128.00" ],
        @[ @"饮料小食", @"13:00", @"-52.00" ],
        @[ @"儿童票", @"09:30", @"-120.00" ],
        @[ @"年卡续费", @"10:00", @"-599.00" ],
        @[ @"现场照片打印", @"15:20", @"-25.00" ],
        @[ @"应援物资", @"12:40", @"-88.00" ],
        @[ @"寄存服务", @"17:10", @"-15.00" ],
    ];
    NSInteger count = 3 + (seed % 5);
    if (count > (NSInteger)allTemplates.count) count = (NSInteger)allTemplates.count;
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:count];
    for (NSInteger i = 0; i < count; i++) {
        NSInteger idx = (seed + i * 3) % (NSInteger)allTemplates.count;
        NSArray *t = allTemplates[idx];
        ConsumeRecordItem *item = [ConsumeRecordItem new];
        item.title = t[0];
        item.time = t[1];
        item.amount = t[2];
        item.iconImage = nil;
        [arr addObject:item];
    }
    self.records = [arr copy];
    [self.tableView reloadData];
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
    return self.records.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 72;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ConsumeRecordCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ConsumeRecordCell" forIndexPath:indexPath];
    ConsumeRecordItem *item = self.records[indexPath.row];
    cell.titleLabel.text = item.title;
    cell.timeLabel.text = item.time;
    cell.amountLabel.text = item.amount;
    if (item.iconImage) {
        cell.iconView.image = item.iconImage;
        cell.iconView.backgroundColor = [UIColor clearColor];
    } else {
        cell.iconView.image = nil;
        cell.iconView.backgroundColor = [UIColor colorWithRed:0.85 green:0.2 blue:0.2 alpha:0.3];
    }
    return cell;
}

@end
