//
//  MoreMatchesViewController.m
//  footBall
//

#import "MoreMatchesViewController.h"
#import <Masonry/Masonry.h>

@interface MoreMatchModel : NSObject
@property (nonatomic, copy) NSString *homeName;
@property (nonatomic, copy) NSString *awayName;
@property (nonatomic, copy) NSString *time;
@property (nonatomic, copy) NSString *homeLogoName;
@property (nonatomic, copy) NSString *awayLogoName;
@end
@implementation MoreMatchModel
@end

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

#pragma mark - 日期选择弹窗

@interface MoreDatePickerController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) UIView *container;
@property (nonatomic, strong) UILabel *monthLabel;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSDate *currentMonth;
@property (nonatomic, strong) NSDate *selectedDate;
@property (nonatomic, copy) void (^onConfirm)(NSDate *date);
@property (nonatomic, strong) NSCalendar *calendar;
@end

@implementation MoreDatePickerController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.35];

    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [UIColor whiteColor];
    card.layer.cornerRadius = 16;
    [self.view addSubview:card];
    self.container = card;
    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.width.equalTo(self.view).multipliedBy(0.8);
        make.height.mas_equalTo(360);
    }];

    UILabel *title = [[UILabel alloc] init];
    title.text = NSLocalizedString(@"more_pick_time_title", nil) ?: @"选择时间";
    title.font = [UIFont boldSystemFontOfSize:16];
    title.textAlignment = NSTextAlignmentCenter;

    self.monthLabel = [[UILabel alloc] init];
    self.monthLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    self.monthLabel.textAlignment = NSTextAlignmentCenter;

    UIButton *prev = [UIButton buttonWithType:UIButtonTypeSystem];
    [prev setTitle:@"<" forState:UIControlStateNormal];
    [prev addTarget:self action:@selector(onPrevMonth) forControlEvents:UIControlEventTouchUpInside];

    UIButton *next = [UIButton buttonWithType:UIButtonTypeSystem];
    [next setTitle:@">" forState:UIControlStateNormal];
    [next addTarget:self action:@selector(onNextMonth) forControlEvents:UIControlEventTouchUpInside];

    [card addSubview:title];
    [card addSubview:self.monthLabel];
    [card addSubview:prev];
    [card addSubview:next];

    [title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(card).offset(16);
        make.centerX.equalTo(card);
    }];
    [self.monthLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(title.mas_bottom).offset(12);
        make.centerX.equalTo(card);
    }];
    [prev mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.monthLabel);
        make.leading.equalTo(card).offset(16);
    }];
    [next mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.monthLabel);
        make.trailing.equalTo(card).offset(-16);
    }];

    // 星期标题行：Sun ~ Sat 固定一行
    UIView *weekHeader = [[UIView alloc] init];
    [card addSubview:weekHeader];
    [weekHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.monthLabel.mas_bottom).offset(12);
        make.leading.trailing.equalTo(card).insets(UIEdgeInsetsMake(0, 12, 0, 12));
        make.height.mas_equalTo(20);
    }];
    NSArray *week = @[ @"Sun", @"Mon", @"Tue", @"Wed", @"Thu", @"Fri", @"Sat" ];
    UILabel *previous = nil;
    for (NSInteger i = 0; i < 7; i++) {
        UILabel *lab = [[UILabel alloc] init];
        lab.text = week[i];
        lab.font = [UIFont systemFontOfSize:11];
        lab.textAlignment = NSTextAlignmentCenter;
        lab.textColor = [UIColor darkGrayColor];
        [weekHeader addSubview:lab];
        [lab mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(weekHeader);
            if (previous) {
                make.leading.equalTo(previous.mas_trailing);
                make.width.equalTo(previous);
            } else {
                make.leading.equalTo(weekHeader.mas_leading);
            }
            if (i == 6) {
                make.trailing.equalTo(weekHeader.mas_trailing);
            }
        }];
        previous = lab;
    }

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumInteritemSpacing = 0;
    layout.minimumLineSpacing = 0;
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"DayCell"];
    [card addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weekHeader.mas_bottom).offset(4);
        make.leading.trailing.equalTo(card).insets(UIEdgeInsetsMake(0, 12, 0, 12));
        make.height.mas_equalTo(220);
    }];

    UIButton *cancel = [UIButton buttonWithType:UIButtonTypeSystem];
    [cancel setTitle:NSLocalizedString(@"cancel", nil) ?: @"取消" forState:UIControlStateNormal];
    [cancel setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    cancel.layer.cornerRadius = 20;
    cancel.layer.borderWidth = 1;
    cancel.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1.0].CGColor;
    [cancel addTarget:self action:@selector(onCancel) forControlEvents:UIControlEventTouchUpInside];

    UIButton *ok = [UIButton buttonWithType:UIButtonTypeSystem];
    [ok setTitle:NSLocalizedString(@"ok", nil) ?: @"确定" forState:UIControlStateNormal];
    ok.backgroundColor = [UIColor colorWithRed:0.09 green:0.36 blue:0.28 alpha:1.0];
    [ok setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    ok.layer.cornerRadius = 20;
    [ok addTarget:self action:@selector(onOk) forControlEvents:UIControlEventTouchUpInside];

    [card addSubview:cancel];
    [card addSubview:ok];
    [cancel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(card).offset(24);
        make.bottom.equalTo(card).offset(-12);
        make.width.mas_equalTo(96);
        make.height.mas_equalTo(40);
    }];
    [ok mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(card).offset(-24);
        make.bottom.equalTo(card).offset(-12);
        make.width.mas_equalTo(96);
        make.height.mas_equalTo(40);
    }];

    // 初始化公历日历，强制以周日为一周第一天，避免系统区域设置干扰
    self.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    self.calendar.firstWeekday = 1; // 1 = Sunday
    self.calendar.timeZone = [NSTimeZone localTimeZone];
    NSDate *baseDate = self.selectedDate ?: [NSDate date];
    NSDateComponents *comp = [self.calendar components:NSCalendarUnitYear|NSCalendarUnitMonth fromDate:baseDate];
    comp.day = 1;
    self.currentMonth = [self.calendar dateFromComponents:comp];
    if (!self.selectedDate) {
        self.selectedDate = baseDate;
    }
    [self updateMonthLabel];
}

- (void)updateMonthLabel {
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"MMMM yyyy";
    self.monthLabel.text = [fmt stringFromDate:self.currentMonth];
    [self.collectionView reloadData];
}

- (NSInteger)daysInCurrentMonth {
    NSRange range = [self.calendar rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:self.currentMonth];
    return (NSInteger)range.length;
}

- (NSInteger)rowCountForCurrentMonth {
    // 根据当前月 1 号是周几以及当月天数，动态计算需要几行（4~6 行）
    NSInteger days = [self daysInCurrentMonth];
    NSInteger weekdayFirst = [self.calendar component:NSCalendarUnitWeekday fromDate:self.currentMonth]; // 1=Sun..7=Sat
    NSInteger firstColumn = weekdayFirst - 1; // 0=Sun..6=Sat
    NSInteger totalSlots = firstColumn + days; // 从第 0 个格开始到最后一天占用的格子数
    NSInteger rows = (totalSlots + 6) / 7;     // 向上取整
    if (rows < 4) rows = 4;
    if (rows > 6) rows = 6;
    return rows;
}

- (NSDate *)dateForDay:(NSInteger)day {
    NSDateComponents *c = [self.calendar components:NSCalendarUnitYear|NSCalendarUnitMonth fromDate:self.currentMonth];
    c.day = day;
    return [self.calendar dateFromComponents:c];
}

- (BOOL)isSameDay:(NSDate *)a other:(NSDate *)b {
    if (!a || !b) return NO;
    NSDateComponents *c1 = [self.calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:a];
    NSDateComponents *c2 = [self.calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:b];
    return (c1.year == c2.year && c1.month == c2.month && c1.day == c2.day);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    // 仅日期网格：7 列 × 行数（4~6 行），每行 7 天
    NSInteger rows = [self rowCountForCurrentMonth];
    return 7 * rows;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"DayCell" forIndexPath:indexPath];
    UILabel *label = [cell.contentView viewWithTag:100];
    if (!label) {
        label = [[UILabel alloc] initWithFrame:cell.contentView.bounds];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:13];
        label.tag = 100;
        [cell.contentView addSubview:label];
    }
    cell.contentView.backgroundColor = [UIColor clearColor];
    cell.contentView.layer.cornerRadius = 0;

    // 日期网格（以星期日为第一列），星期标题已经由上面的 weekHeader 固定展示。
    // 这里每个格子都代表一个真实的日期（包括上月/下月的溢出部分），保证一行恒为 7 天。
    NSInteger weekdayFirst = [self.calendar component:NSCalendarUnitWeekday fromDate:self.currentMonth]; // 1=Sun..7=Sat
    NSInteger firstColumn = weekdayFirst - 1;               // 0=Sun,...,6=Sat
    NSInteger gridIndex = indexPath.item;                   // 0..41
    NSInteger delta = gridIndex - firstColumn;              // 相对当月 1 号的偏移天数（可能为负）

    NSDateComponents *baseComp = [self.calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:self.currentMonth];
    baseComp.day = 1;
    NSDate *firstDayOfMonth = [self.calendar dateFromComponents:baseComp];
    NSDate *cellDate = [self.calendar dateByAddingUnit:NSCalendarUnitDay value:delta toDate:firstDayOfMonth options:0];

    NSDateComponents *cellComp = [self.calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:cellDate];
    label.text = [NSString stringWithFormat:@"%ld", (long)cellComp.day];

    // 区分当前月与前/后月的日期：当前月为黑色，其它月份为浅灰
    NSInteger currentMonth = baseComp.month;
    if (cellComp.month != currentMonth) {
        label.textColor = [UIColor lightGrayColor];
    } else {
        label.textColor = [UIColor blackColor];
    }

    // 高亮当前选中日期
    BOOL selected = [self isSameDay:cellDate other:self.selectedDate];
    if (selected) {
        cell.contentView.backgroundColor = [UIColor colorWithRed:0.10 green:0.36 blue:0.28 alpha:1.0];
        cell.contentView.layer.cornerRadius = MIN(cell.bounds.size.width, cell.bounds.size.height) / 2.0;
        cell.contentView.layer.masksToBounds = YES;
        label.textColor = [UIColor whiteColor];
    }

    label.font = [UIFont systemFontOfSize:13];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)layout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    // 使用向下取整，保证 7 个格子之和不超过宽度，小手机上一行也能完整显示 7 天
    CGFloat totalW = collectionView.bounds.size.width;
    CGFloat w = floor(totalW / 7.0);
    NSInteger rows = [self rowCountForCurrentMonth];
    CGFloat h = collectionView.bounds.size.height / MAX(rows, 1);
    return CGSizeMake(w, h);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // 与 cellForItemAtIndexPath 使用完全相同的日期推算逻辑，保证点击与显示一致
    NSInteger weekdayFirst = [self.calendar component:NSCalendarUnitWeekday fromDate:self.currentMonth]; // 1=Sun..7=Sat
    NSInteger firstColumn = weekdayFirst - 1;               // 0=Sun,...,6=Sat
    NSInteger gridIndex = indexPath.item;
    NSInteger delta = gridIndex - firstColumn;

    NSDateComponents *baseComp = [self.calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:self.currentMonth];
    baseComp.day = 1;
    NSDate *firstDayOfMonth = [self.calendar dateFromComponents:baseComp];
    NSDate *cellDate = [self.calendar dateByAddingUnit:NSCalendarUnitDay value:delta toDate:firstDayOfMonth options:0];

    self.selectedDate = cellDate;
    [self.collectionView reloadData];
}

- (void)onPrevMonth {
    NSDateComponents *offset = [[NSDateComponents alloc] init];
    offset.month = -1;
    self.currentMonth = [self.calendar dateByAddingComponents:offset toDate:self.currentMonth options:0];

    // 维持选中的“日”，如果超出当月天数则取最后一天
    NSInteger oldDay = [self.calendar component:NSCalendarUnitDay fromDate:self.selectedDate ?: self.currentMonth];
    NSInteger daysInNewMonth = [self daysInCurrentMonth];
    NSInteger newDay = MIN(oldDay, daysInNewMonth);
    self.selectedDate = [self dateForDay:newDay];

    [self updateMonthLabel];
}

- (void)onNextMonth {
    NSDateComponents *offset = [[NSDateComponents alloc] init];
    offset.month = 1;
    self.currentMonth = [self.calendar dateByAddingComponents:offset toDate:self.currentMonth options:0];

    NSInteger oldDay = [self.calendar component:NSCalendarUnitDay fromDate:self.selectedDate ?: self.currentMonth];
    NSInteger daysInNewMonth = [self daysInCurrentMonth];
    NSInteger newDay = MIN(oldDay, daysInNewMonth);
    self.selectedDate = [self dateForDay:newDay];

    [self updateMonthLabel];
}
- (void)onCancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)onOk {
    if (self.onConfirm) self.onConfirm(self.selectedDate ?: [NSDate date]);
    [self dismissViewControllerAnimated:YES completion:nil];
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
@property (nonatomic, strong) NSArray<MoreMatchModel *> *matches;
@property (nonatomic, strong) NSDate *selectedDate;        // 当前选中的日期（默认今天）
@property (nonatomic, strong) NSDate *weekStartDate;       // 当前周的周日日期
@property (nonatomic, strong) NSCalendar *calendar;
@property (nonatomic, strong) NSArray<UIControl *> *weekDayViews;
@end

@implementation MoreMatchesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
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

    NSDateComponents *comp = [self.calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitWeekday fromDate:self.selectedDate];
    NSInteger weekday = comp.weekday; // 1=周日...7=周六

    // 根据星期简单切换一些假数据，方便看到“刷新效果”
    NSArray *templatePairs;
    switch (weekday) {
        case 1: // 周日
            templatePairs = @[
                @[ @"诺丁汉森林队", @"利物浦", @"06:30" ],
                @[ @"曼城", @"布莱顿", @"07:30" ],
                @[ @"狼队", @"阿森纳", @"08:30" ],
            ];
            break;
        case 2: // 周一
            templatePairs = @[
                @[ @"阿森纳", @"布莱顿", @"06:00" ],
                @[ @"曼联", @"利物浦", @"08:00" ],
            ];
            break;
        case 3: // 周二
            templatePairs = @[
                @[ @"曼城", @"阿森纳", @"07:00" ],
                @[ @"诺丁汉森林队", @"布伦特福德", @"09:15" ],
                @[ @"狼队", @"布莱顿", @"10:00" ],
            ];
            break;
        default:
            templatePairs = @[
                @[ @"曼城", @"布莱顿", @"07:30" ],
                @[ @"狼队", @"阿森纳", @"08:30" ],
                @[ @"诺丁汉森林队", @"利物浦", @"06:30" ],
            ];
            break;
    }

    NSMutableArray *arr = [NSMutableArray array];
    for (NSArray *info in templatePairs) {
        MoreMatchModel *m = [MoreMatchModel new];
        m.homeName = info[0];
        m.awayName = info[1];
        m.time = info[2];
        [arr addObject:m];
    }
    self.matches = arr;
    [self.tableView reloadData];
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
            dayView.backgroundColor = [UIColor colorWithRed:0.10 green:0.36 blue:0.28 alpha:1.0];
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
    MoreMatchModel *m = self.matches[indexPath.row];
    cell.homeLabel.text = m.homeName;
    cell.awayLabel.text = m.awayName;
    [cell.timePill setTitle:m.time forState:UIControlStateNormal];
    cell.homeLogo.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    cell.awayLogo.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    return cell;
}

@end

