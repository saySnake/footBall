//
//  MoreDatePickerController.m
//  footBall
//

#import "MoreDatePickerController.h"
#import <Masonry/Masonry.h>

static UIColor *kPickerWeekdayColor(void) {
    return [UIColor colorWithRed:0.612f green:0.643f blue:0.671f alpha:1.0]; // #9CA4AB
}

@interface MoreDatePickerController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) UIView *container;
@property (nonatomic, strong) UILabel *monthLabel;
@property (nonatomic, strong) UIButton *prevMonthButton;
@property (nonatomic, strong) UIButton *nextMonthButton;
@property (nonatomic, strong) UIView *calendarPane;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSDate *currentMonth;
@property (nonatomic, strong) NSCalendar *calendar;
@end

@implementation MoreDatePickerController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.35];

    self.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    self.calendar.firstWeekday = 1;
    self.calendar.timeZone = [NSTimeZone localTimeZone];

    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [UIColor whiteColor];
    card.layer.cornerRadius = 16;
    card.clipsToBounds = YES;
    [self.view addSubview:card];
    self.container = card;
    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.width.equalTo(self.view).multipliedBy(323.0 / 375.0);
    }];

    UILabel *title = [[UILabel alloc] init];
    title.text = NSLocalizedString(@"more_pick_time_title", nil) ?: @"选择时间";
    title.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
    title.textColor = [UIColor blackColor];
    title.textAlignment = NSTextAlignmentCenter;

    self.monthLabel = [[UILabel alloc] init];
    self.monthLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    self.monthLabel.textColor = [UIColor blackColor];
    self.monthLabel.textAlignment = NSTextAlignmentCenter;

    UIButton *prev = [UIButton buttonWithType:UIButtonTypeCustom];
    UIButton *next = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *leftImg = [UIImage imageNamed:@"team_left"];
    UIImage *rightImg = [UIImage imageNamed:@"team_right"];
    if (leftImg) {
        [prev setImage:leftImg forState:UIControlStateNormal];
    } else if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightMedium];
        [prev setImage:[[UIImage systemImageNamed:@"chevron.left" withConfiguration:cfg] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        prev.tintColor = [UIColor blackColor];
    }
    if (rightImg) {
        [next setImage:rightImg forState:UIControlStateNormal];
    } else if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightMedium];
        [next setImage:[[UIImage systemImageNamed:@"chevron.right" withConfiguration:cfg] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        next.tintColor = [UIColor blackColor];
    }
    prev.imageView.contentMode = UIViewContentModeScaleAspectFit;
    next.imageView.contentMode = UIViewContentModeScaleAspectFit;
    prev.adjustsImageWhenHighlighted = NO;
    next.adjustsImageWhenHighlighted = NO;
    [prev addTarget:self action:@selector(onPrevMonth) forControlEvents:UIControlEventTouchUpInside];
    [next addTarget:self action:@selector(onNextMonth) forControlEvents:UIControlEventTouchUpInside];
    self.prevMonthButton = prev;
    self.nextMonthButton = next;

    [card addSubview:title];
    [card addSubview:self.monthLabel];
    [card addSubview:prev];
    [card addSubview:next];

    [title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(card).offset(20);
        make.centerX.equalTo(card);
    }];
    [prev mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(card).offset(12);
        make.top.equalTo(title.mas_bottom).offset(21);
        make.width.height.mas_equalTo(32);
    }];
    [next mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(card).offset(-12);
        make.centerY.equalTo(prev);
        make.width.height.mas_equalTo(32);
    }];
    [self.monthLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(prev);
        make.centerX.equalTo(card);
        make.leading.greaterThanOrEqualTo(prev.mas_trailing).offset(8);
        make.trailing.lessThanOrEqualTo(next.mas_leading).offset(-8);
    }];

    UIView *calendarPane = [[UIView alloc] init];
    calendarPane.backgroundColor = [UIColor whiteColor];
    calendarPane.layer.cornerRadius = 12;
    calendarPane.clipsToBounds = YES;
    [card addSubview:calendarPane];
    self.calendarPane = calendarPane;
    [calendarPane mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(prev.mas_bottom).offset(12);
        make.leading.equalTo(card).offset(8);
        make.trailing.equalTo(card).offset(-8);
    }];

    UIView *weekHeader = [[UIView alloc] init];
    [calendarPane addSubview:weekHeader];
    [weekHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(calendarPane);
        make.height.mas_equalTo(34);
    }];
    NSDateFormatter *weekFmt = [[NSDateFormatter alloc] init];
    weekFmt.locale = [NSLocale currentLocale];
    NSArray<NSString *> *shortSyms = weekFmt.shortWeekdaySymbols;
    NSMutableArray<NSString *> *week = [NSMutableArray arrayWithCapacity:7];
    NSInteger fw = self.calendar.firstWeekday;
    if (shortSyms.count >= 7) {
        for (NSInteger i = 0; i < 7; i++) {
            NSInteger idx = (fw - 1 + i) % 7;
            [week addObject:shortSyms[idx]];
        }
    } else {
        [week addObjectsFromArray:@[ @"Sun", @"Mon", @"Tue", @"Wed", @"Thu", @"Fri", @"Sat" ]];
    }
    UILabel *previous = nil;
    for (NSInteger i = 0; i < 7; i++) {
        UILabel *lab = [[UILabel alloc] init];
        lab.text = week[i];
        lab.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        lab.textAlignment = NSTextAlignmentCenter;
        lab.textColor = kPickerWeekdayColor();
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
    [calendarPane addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weekHeader.mas_bottom);
        make.leading.trailing.bottom.equalTo(calendarPane);
        make.height.mas_equalTo(256);
    }];

    UIButton *cancel = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancel setTitle:NSLocalizedString(@"cancel", nil) ?: @"取消" forState:UIControlStateNormal];
    [cancel setTitleColor:[UIColor colorWithRed:0.325f green:0.325f blue:0.325f alpha:1.0] forState:UIControlStateNormal];
    cancel.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    cancel.backgroundColor = [UIColor colorWithRed:0.878f green:0.878f blue:0.878f alpha:0.1];
    cancel.layer.cornerRadius = 23;
    cancel.layer.borderWidth = 1;
    cancel.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.1].CGColor;
    [cancel addTarget:self action:@selector(onCancel) forControlEvents:UIControlEventTouchUpInside];

    UIButton *ok = [UIButton buttonWithType:UIButtonTypeCustom];
    [ok setTitle:NSLocalizedString(@"ok", nil) ?: @"确定" forState:UIControlStateNormal];
    ok.backgroundColor = [ColorManager sharedManager].primaryColor;
    [ok setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    ok.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    ok.layer.cornerRadius = 23;
    [ok addTarget:self action:@selector(onOk) forControlEvents:UIControlEventTouchUpInside];

    [card addSubview:cancel];
    [card addSubview:ok];
    [cancel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(calendarPane.mas_bottom).offset(16);
        make.leading.equalTo(card).offset(20);
        make.height.mas_equalTo(46);
        make.width.equalTo(ok);
    }];
    [ok mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(cancel);
        make.trailing.equalTo(card).offset(-20);
        make.leading.equalTo(cancel.mas_trailing).offset(16);
        make.height.mas_equalTo(46);
        make.bottom.equalTo(card).offset(-16);
    }];

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
    fmt.locale = [NSLocale currentLocale];
    fmt.dateFormat = @"MMMM yyyy";
    self.monthLabel.text = [fmt stringFromDate:self.currentMonth];
    [self.collectionView.collectionViewLayout invalidateLayout];
    [self.collectionView reloadData];
}

- (NSInteger)daysInCurrentMonth {
    NSRange range = [self.calendar rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:self.currentMonth];
    return (NSInteger)range.length;
}

- (NSInteger)rowCountForCurrentMonth {
    NSInteger days = [self daysInCurrentMonth];
    NSInteger weekdayFirst = [self.calendar component:NSCalendarUnitWeekday fromDate:self.currentMonth];
    NSInteger firstColumn = weekdayFirst - 1;
    NSInteger totalSlots = firstColumn + days;
    NSInteger rows = (totalSlots + 6) / 7;
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
        label.tag = 100;
        [cell.contentView addSubview:label];
    }
    cell.contentView.backgroundColor = [UIColor clearColor];
    cell.contentView.layer.cornerRadius = 0;
    cell.contentView.layer.masksToBounds = NO;

    NSInteger weekdayFirst = [self.calendar component:NSCalendarUnitWeekday fromDate:self.currentMonth];
    NSInteger firstColumn = weekdayFirst - 1;
    NSInteger gridIndex = indexPath.item;
    NSInteger delta = gridIndex - firstColumn;

    NSDateComponents *baseComp = [self.calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:self.currentMonth];
    baseComp.day = 1;
    NSDate *firstDayOfMonth = [self.calendar dateFromComponents:baseComp];
    NSDate *cellDate = [self.calendar dateByAddingUnit:NSCalendarUnitDay value:delta toDate:firstDayOfMonth options:0];

    NSDateComponents *cellComp = [self.calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:cellDate];
    label.text = [NSString stringWithFormat:@"%ld", (long)cellComp.day];

    NSInteger currentMonth = baseComp.month;
    label.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    BOOL inMonth = (cellComp.month == currentMonth);
    if (!inMonth) {
        label.textColor = [UIColor blackColor];
        label.alpha = 0.5;
    } else {
        label.alpha = 1.0;
        label.textColor = [UIColor blackColor];
    }

    BOOL selected = [self isSameDay:cellDate other:self.selectedDate];
    if (selected) {
        cell.contentView.backgroundColor = [ColorManager sharedManager].primaryColor;
        cell.contentView.layer.cornerRadius = 8;
        cell.contentView.layer.masksToBounds = YES;
        label.textColor = [UIColor whiteColor];
        label.alpha = 1.0;
    }

    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)layout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat totalW = collectionView.bounds.size.width;
    CGFloat w = floor(totalW / 7.0);
    NSInteger rows = [self rowCountForCurrentMonth];
    CGFloat h = collectionView.bounds.size.height / MAX(rows, 1);
    return CGSizeMake(w, h);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger weekdayFirst = [self.calendar component:NSCalendarUnitWeekday fromDate:self.currentMonth];
    NSInteger firstColumn = weekdayFirst - 1;
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
