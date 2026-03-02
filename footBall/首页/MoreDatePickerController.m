//
//  MoreDatePickerController.m
//  footBall
//

#import "MoreDatePickerController.h"
#import <Masonry/Masonry.h>

@interface MoreDatePickerController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) UIView *container;
@property (nonatomic, strong) UILabel *monthLabel;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSDate *currentMonth;
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

    self.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    self.calendar.firstWeekday = 1;
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
        label.font = [UIFont systemFontOfSize:13];
        label.tag = 100;
        [cell.contentView addSubview:label];
    }
    cell.contentView.backgroundColor = [UIColor clearColor];
    cell.contentView.layer.cornerRadius = 0;

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
    if (cellComp.month != currentMonth) {
        label.textColor = [UIColor lightGrayColor];
    } else {
        label.textColor = [UIColor blackColor];
    }

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
