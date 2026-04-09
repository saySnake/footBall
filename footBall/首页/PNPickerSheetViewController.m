//
//  PNPickerSheetViewController.m
//  footBall
//

#import "PNPickerSheetViewController.h"
#import <Masonry/Masonry.h>

#define kPNPickerGreen [UIColor colorWithRed:0.10 green:0.36 blue:0.28 alpha:1.0]

@interface PNPickerSheetViewController () <UIPickerViewDataSource, UIPickerViewDelegate>
@property (nonatomic, strong) UIView *dimmingView;
@property (nonatomic, strong) UIView *sheetView;
@property (nonatomic, strong) UIPickerView *pickerView;
@property (nonatomic, strong) UIButton *cancelBtn;
@property (nonatomic, strong) UIButton *okBtn;
@property (nonatomic, strong) NSCalendar *calendar;

@property (nonatomic, strong) NSArray<NSNumber *> *years;
@property (nonatomic, strong) NSArray<NSNumber *> *months;
@property (nonatomic, strong) NSArray<NSNumber *> *days;

@property (nonatomic, strong) NSArray<NSNumber *> *hours;
@property (nonatomic, strong) NSArray<NSNumber *> *minutes;
@end

@implementation PNPickerSheetViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];

    self.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    self.calendar.timeZone = [NSTimeZone localTimeZone];

    if (!self.selectedDate) self.selectedDate = [NSDate date];

    UIView *dim = [[UIView alloc] init];
    dim.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.35];
    [self.view addSubview:dim];
    self.dimmingView = dim;
    [dim mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onCancel)];
    [dim addGestureRecognizer:tap];

    UIView *sheet = [[UIView alloc] init];
    sheet.backgroundColor = [UIColor whiteColor];
    sheet.layer.cornerRadius = 18;
    sheet.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    sheet.layer.masksToBounds = YES;
    if (@available(iOS 13.0, *)) {
        // 需求：无论白天/夜间，都要黑色文字。强制该弹层使用浅色外观，避免系统 Dark Mode 自动变白字。
        sheet.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }
    [self.view addSubview:sheet];
    self.sheetView = sheet;
    [sheet mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.bottom.equalTo(self.view);
        make.height.mas_equalTo(320);
    }];

    UIPickerView *picker = [[UIPickerView alloc] init];
    picker.dataSource = self;
    picker.delegate = self;
    if (@available(iOS 13.0, *)) {
        picker.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }
    [sheet addSubview:picker];
    self.pickerView = picker;
    [picker mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(sheet).offset(14);
        make.leading.trailing.equalTo(sheet);
        make.height.mas_equalTo(200);
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
    ok.backgroundColor = kPNPickerGreen;
    [ok setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    ok.layer.cornerRadius = 20;
    [ok addTarget:self action:@selector(onOk) forControlEvents:UIControlEventTouchUpInside];

    [sheet addSubview:cancel];
    [sheet addSubview:ok];
    self.cancelBtn = cancel;
    self.okBtn = ok;
    [cancel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(sheet).offset(24);
        make.bottom.equalTo(sheet.mas_safeAreaLayoutGuideBottom).offset(-12);
        make.width.mas_equalTo(120);
        make.height.mas_equalTo(40);
    }];
    [ok mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(sheet).offset(-24);
        make.bottom.equalTo(sheet.mas_safeAreaLayoutGuideBottom).offset(-12);
        make.width.mas_equalTo(120);
        make.height.mas_equalTo(40);
    }];

    [self buildData];
    [self applyInitialSelection];
}

- (void)buildData {
    NSMutableArray *years = [NSMutableArray array];
    NSInteger currentYear = [self.calendar component:NSCalendarUnitYear fromDate:[NSDate date]];
    NSInteger minY = self.minYear;
    NSInteger maxY = self.maxYear;
    if (minY > 0 && maxY >= minY) {
        for (NSInteger y = minY; y <= maxY; y++) [years addObject:@(y)];
    } else {
        for (NSInteger y = currentYear - 1; y <= currentYear + 2; y++) [years addObject:@(y)];
    }
    self.years = years;

    NSMutableArray *months = [NSMutableArray array];
    for (NSInteger m = 1; m <= 12; m++) [months addObject:@(m)];
    self.months = months;

    NSMutableArray *hours = [NSMutableArray array];
    for (NSInteger h = 0; h <= 23; h++) [hours addObject:@(h)];
    self.hours = hours;
    NSMutableArray *minutes = [NSMutableArray array];
    for (NSInteger m = 0; m <= 59; m++) [minutes addObject:@(m)];
    self.minutes = minutes;

    [self rebuildDays];
}

- (void)rebuildDays {
    NSDateComponents *c = [self.calendar components:NSCalendarUnitYear|NSCalendarUnitMonth fromDate:self.selectedDate ?: [NSDate date]];
    NSDateComponents *first = [NSDateComponents new];
    first.year = c.year;
    first.month = c.month;
    first.day = 1;
    NSDate *firstDate = [self.calendar dateFromComponents:first];
    NSRange range = [self.calendar rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:firstDate];
    NSMutableArray *days = [NSMutableArray array];
    for (NSInteger d = 1; d <= (NSInteger)range.length; d++) [days addObject:@(d)];
    self.days = days;
}

- (void)applyInitialSelection {
    NSDateComponents *c = [self.calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute fromDate:self.selectedDate];
    if (self.mode == PNPickerSheetModeDate) {
        NSInteger yearIdx = [self.years indexOfObject:@(c.year)];
        NSInteger monthIdx = [self.months indexOfObject:@(c.month)];
        [self rebuildDays];
        NSInteger dayIdx = [self.days indexOfObject:@(c.day)];
        if (yearIdx == NSNotFound) yearIdx = 0;
        if (monthIdx == NSNotFound) monthIdx = 0;
        if (dayIdx == NSNotFound) dayIdx = 0;
        [self.pickerView selectRow:yearIdx inComponent:0 animated:NO];
        [self.pickerView selectRow:monthIdx inComponent:1 animated:NO];
        [self.pickerView selectRow:dayIdx inComponent:2 animated:NO];
    } else {
        NSInteger hourIdx = [self.hours indexOfObject:@(c.hour)];
        NSInteger minuteIdx = [self.minutes indexOfObject:@(c.minute)];
        if (hourIdx != NSNotFound) [self.pickerView selectRow:hourIdx inComponent:0 animated:NO];
        if (minuteIdx != NSNotFound) [self.pickerView selectRow:minuteIdx inComponent:1 animated:NO];
    }
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return self.mode == PNPickerSheetModeDate ? 3 : 2;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (self.mode == PNPickerSheetModeDate) {
        if (component == 0) return self.years.count;
        if (component == 1) return self.months.count;
        return self.days.count;
    }
    return component == 0 ? self.hours.count : self.minutes.count;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    CGFloat w = pickerView.bounds.size.width;
    if (self.mode == PNPickerSheetModeDate) {
        return component == 0 ? w * 0.34 : w * 0.33;
    }
    return w * 0.5;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (self.mode == PNPickerSheetModeDate) {
        if (component == 0) return [NSString stringWithFormat:@"%@年", self.years[row]];
        if (component == 1) return [NSString stringWithFormat:@"%@月", self.months[row]];
        return [NSString stringWithFormat:@"%@", self.days[row]];
    }
    if (component == 0) return [NSString stringWithFormat:@"%02ld", (long)[self.hours[row] integerValue]];
    return [NSString stringWithFormat:@"%02ld", (long)[self.minutes[row] integerValue]];
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    UILabel *label = [view isKindOfClass:[UILabel class]] ? (UILabel *)view : nil;
    if (!label) {
        label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:17];
    }
    label.textColor = [UIColor blackColor];
    label.text = [self pickerView:pickerView titleForRow:row forComponent:component];
    return label;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (self.mode == PNPickerSheetModeDate) {
        NSInteger y = [self.years[[pickerView selectedRowInComponent:0]] integerValue];
        NSInteger m = [self.months[[pickerView selectedRowInComponent:1]] integerValue];
        [self rebuildDaysForYear:y month:m];
        [pickerView reloadComponent:2];
        NSInteger dRow = MIN([pickerView selectedRowInComponent:2], self.days.count - 1);
        [pickerView selectRow:dRow inComponent:2 animated:NO];
        NSInteger d = [self.days[dRow] integerValue];
        [self setSelectedWithYear:y month:m day:d keepTime:YES];
    } else {
        NSInteger h = [self.hours[[pickerView selectedRowInComponent:0]] integerValue];
        NSInteger min = [self.minutes[[pickerView selectedRowInComponent:1]] integerValue];
        [self setSelectedWithHour:h minute:min];
    }
}

- (void)rebuildDaysForYear:(NSInteger)year month:(NSInteger)month {
    NSDateComponents *first = [NSDateComponents new];
    first.year = year;
    first.month = month;
    first.day = 1;
    NSDate *firstDate = [self.calendar dateFromComponents:first];
    NSRange range = [self.calendar rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:firstDate];
    NSMutableArray *days = [NSMutableArray array];
    for (NSInteger d = 1; d <= (NSInteger)range.length; d++) [days addObject:@(d)];
    self.days = days;
}

- (void)setSelectedWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day keepTime:(BOOL)keepTime {
    NSDateComponents *c = [self.calendar components:NSCalendarUnitHour|NSCalendarUnitMinute fromDate:self.selectedDate ?: [NSDate date]];
    NSDateComponents *nc = [NSDateComponents new];
    nc.year = year;
    nc.month = month;
    nc.day = day;
    if (keepTime) {
        nc.hour = c.hour;
        nc.minute = c.minute;
    }
    NSDate *d = [self.calendar dateFromComponents:nc];
    if (d) self.selectedDate = d;
}

- (void)setSelectedWithHour:(NSInteger)hour minute:(NSInteger)minute {
    NSDateComponents *c = [self.calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:self.selectedDate ?: [NSDate date]];
    NSDateComponents *nc = [NSDateComponents new];
    nc.year = c.year;
    nc.month = c.month;
    nc.day = c.day;
    nc.hour = hour;
    nc.minute = minute;
    NSDate *d = [self.calendar dateFromComponents:nc];
    if (d) self.selectedDate = d;
}

- (void)onCancel {
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)onOk {
    if (self.onConfirm) self.onConfirm(self.selectedDate ?: [NSDate date]);
    [self dismissViewControllerAnimated:NO completion:nil];
}

@end

