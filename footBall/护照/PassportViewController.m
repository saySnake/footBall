//
//  PassportViewController.m
//  footBall
//

#import "PassportViewController.h"
#import "PassportHeaderView.h"
#import "PassportYearTabStrip.h"
#import "PassportViewModel.h"
#import "PassportTableCells.h"
#import "PassportSheetsViewController.h"
#import "ProfileRequest.h"
#import "HTTPResponse.h"
#import <Masonry/Masonry.h>

static UIColor *PassportPageBg(void) {
    return [UIColor colorWithHexString:@"#E6E6E6"];
}

@interface PassportViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UIView *topBar;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *refreshButton;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *headerWrap;
@property (nonatomic, strong) PassportHeaderView *passportHeader;
@property (nonatomic, strong) PassportYearTabStrip *yearStrip;
@property (nonatomic, strong) PassportViewModel *viewModel;
@property (nonatomic, assign) NSInteger selectedYear;
@property (nonatomic, assign) CGFloat passportHeaderCachedWidth;
@property (nonatomic, assign) CGFloat passportHeaderCachedHeight;
@end

@implementation PassportViewController

- (NSArray<NSNumber *> *)recentFiveYears {
    NSCalendar *cal = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    NSInteger cy = [cal component:NSCalendarUnitYear fromDate:[NSDate date]];
    NSMutableArray<NSNumber *> *years = [NSMutableArray array];
    for (NSInteger i = 0; i < 5; i++) {
        [years addObject:@(cy - i)];
    }
    return [years copy];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hidesBottomBarWhenPushed = YES;
    self.shouldShowNavigationBar = NO;
    self.view.backgroundColor = PassportPageBg();

    NSCalendar *cal = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    self.selectedYear = [cal component:NSCalendarUnitYear fromDate:[NSDate date]];
    self.passportHeaderCachedWidth = -1;
    self.passportHeaderCachedHeight = -1;

    [self buildTopBar];
    [self buildTable];
    [self buildTableHeader];
    __weak typeof(self) weakSelf = self;
    self.passportHeader.onPassportHeader2Tap = ^{
        PassportViewModel *m = weakSelf.viewModel;
        if (!m) {
            return;
        }
        PassportSheetsViewController *vc = [[PassportSheetsViewController alloc] initWithViewModel:m year:weakSelf.selectedYear];
        [weakSelf.navigationController pushViewController:vc animated:YES];
    };
    self.viewModel = [PassportViewModel viewModelWithPassport:nil year:self.selectedYear];
    [self.passportHeader configureWithModel:self.viewModel];
    [self.tableView reloadData];
    [self loadPassportData];
}

- (void)buildTopBar {
    _topBar = [[UIView alloc] init];
    _topBar.backgroundColor = [UIColor colorWithHexString:@"#0D2122"];
    [self.view addSubview:_topBar];

    _backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    if (@available(iOS 13.0, *)) {
        UIImage *img = [UIImage systemImageNamed:@"chevron.left"];
        [_backButton setImage:[img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    } else {
        [_backButton setTitle:NSLocalizedString(@"back", nil) ?: @"返回" forState:UIControlStateNormal];
    }
    _backButton.tintColor = [UIColor whiteColor];
    [_backButton addTarget:self action:@selector(onBack) forControlEvents:UIControlEventTouchUpInside];

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.text = NSLocalizedString(@"passport_nav_title", nil) ?: @"我的护照";

    _refreshButton = [UIButton buttonWithType:UIButtonTypeSystem];
    if (@available(iOS 13.0, *)) {
        UIImage *img = [UIImage imageNamed:@"passport_share"];
        [_refreshButton setImage:[img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    _refreshButton.tintColor = [UIColor whiteColor];
    [_refreshButton addTarget:self action:@selector(loadPassportData) forControlEvents:UIControlEventTouchUpInside];

    [_topBar addSubview:_backButton];
    [_topBar addSubview:_titleLabel];
    [_topBar addSubview:_refreshButton];

    [_topBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(44);
    }];
    [_backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(_topBar).offset(8);
        make.bottom.equalTo(_topBar).offset(-8);
        make.width.height.mas_equalTo(36);
    }];
    [_refreshButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(_topBar).offset(-8);
        make.centerY.equalTo(_backButton);
        make.width.height.mas_equalTo(36);
    }];
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(_topBar);
        make.centerY.equalTo(_backButton);
    }];
}

- (void)buildTable {
    UIView *topBg = UIView.alloc.init;
    topBg.backgroundColor = [UIColor colorWithHexString:@"#0D2122"];
    [self.view addSubview:topBg];
    [topBg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_topBar.mas_bottom);
        make.leading.trailing.equalTo(self.view);
        make.height.equalTo(@30);
    }];
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.backgroundColor = UIColor.clearColor;
    _tableView.showsVerticalScrollIndicator = YES;
    _tableView.estimatedRowHeight = 200;
    _tableView.rowHeight = UITableViewAutomaticDimension;
    _tableView.contentInset = UIEdgeInsetsMake(0, 0, 24, 0);
    _tableView.scrollIndicatorInsets = _tableView.contentInset;
    [self.view addSubview:_tableView];

    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_topBar.mas_bottom);
        make.leading.trailing.bottom.equalTo(self.view);
    }];

    [_tableView registerClass:[PassportDarkStatsCardCell class] forCellReuseIdentifier:@"stats"];
    [_tableView registerClass:[PassportGrowthBannerCell class] forCellReuseIdentifier:@"growth"];
    [_tableView registerClass:[PassportBarChartCardCell class] forCellReuseIdentifier:@"bar"];
    [_tableView registerClass:[PassportPossessionCardCell class] forCellReuseIdentifier:@"poss"];
    [_tableView registerClass:[PassportPositionStrengthCell class] forCellReuseIdentifier:@"pos"];
    [_tableView registerClass:[PassportAbilityBlockCell class] forCellReuseIdentifier:@"abil"];
    [_tableView registerClass:[PassportTacticalCell class] forCellReuseIdentifier:@"tact"];
    [_tableView registerClass:[PassportMetricBarsCell class] forCellReuseIdentifier:@"metric"];
    [_tableView registerClass:[PassportOutcomeCell class] forCellReuseIdentifier:@"out"];
}

- (void)buildTableHeader {
    _headerWrap = [[UIView alloc] init];
    _headerWrap.backgroundColor = UIColor.clearColor;

    _passportHeader = [[PassportHeaderView alloc] init];
    _yearStrip = [[PassportYearTabStrip alloc] init];

    NSArray<NSNumber *> *years = [self recentFiveYears];
    NSInteger sel = self.selectedYear;
    if (![years containsObject:@(sel)]) {
        sel = years.firstObject.integerValue;
        self.selectedYear = sel;
    }
    [_yearStrip setYears:years selectedYear:sel];
    __weak typeof(self) weakSelf = self;
    _yearStrip.onYearChanged = ^(NSInteger year) {
        weakSelf.selectedYear = year;
        [weakSelf invalidatePassportHeaderLayoutCache];
        [weakSelf.view setNeedsLayout];
        [weakSelf loadPassportData];
    };

    [_headerWrap addSubview:_passportHeader];
    [_headerWrap addSubview:_yearStrip];

    [_passportHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@15);
        make.leading.equalTo(@0);
        make.trailing.equalTo(@0);
    }];
    [_yearStrip mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_passportHeader.mas_bottom);
        make.leading.trailing.bottom.equalTo(_headerWrap);
        make.height.mas_equalTo(52);
    }];

    _headerWrap.translatesAutoresizingMaskIntoConstraints = NO;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutPassportTableHeaderIfNeeded];
}

/// 用临时宽度约束测量高度；仅在宽高变化时设置 tableHeaderView，避免 layout ↔ 赋值死循环撑满 CPU。
- (void)layoutPassportTableHeaderIfNeeded {
    if (!_headerWrap || !_tableView) return;
    CGFloat w = CGRectGetWidth(_tableView.bounds);
    if (w < 1) return;

    NSLayoutConstraint *tmpWidth = [_headerWrap.widthAnchor constraintEqualToConstant:w];
    tmpWidth.active = YES;
    [_headerWrap setNeedsLayout];
    [_headerWrap layoutIfNeeded];
    CGFloat h = ceil([_headerWrap systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height);
    tmpWidth.active = NO;

    if (!(h > 0) || h > 10000) h = 320;
    if (h < 52) h = 52;

    BOOL same =
        (fabs(w - self.passportHeaderCachedWidth) < 0.5 &&
        fabs(h - self.passportHeaderCachedHeight) < 0.5 &&
        _tableView.tableHeaderView == _headerWrap &&
        fabs(CGRectGetWidth(_headerWrap.bounds) - w) < 0.5 &&
        fabs(CGRectGetHeight(_headerWrap.bounds) - h) < 0.5);
    if (same) return;

    self.passportHeaderCachedWidth = w;
    self.passportHeaderCachedHeight = h;

    _headerWrap.translatesAutoresizingMaskIntoConstraints = YES;
    _headerWrap.frame = CGRectMake(0, 0, w, h);
    _tableView.tableHeaderView = _headerWrap;
}

- (void)invalidatePassportHeaderLayoutCache {
    self.passportHeaderCachedWidth = -1;
    self.passportHeaderCachedHeight = -1;
}

- (void)loadPassportData {
    __weak typeof(self) weakSelf = self;
    [self showLoading];
    NSString *y = [NSString stringWithFormat:@"%ld", (long)self.selectedYear];
    [[ProfileRequest shared] getMyPassportWithYear:y success:^(HTTPResponse * _Nullable responseObject) {
        [weakSelf hideLoading];
        PNPassport *p = responseObject.dataObject;
        weakSelf.viewModel = [PassportViewModel viewModelWithPassport:p year:weakSelf.selectedYear];
        [weakSelf.passportHeader configureWithModel:weakSelf.viewModel];
        [weakSelf.yearStrip setYears:[weakSelf recentFiveYears] selectedYear:weakSelf.selectedYear];
        [weakSelf.tableView reloadData];
        [weakSelf invalidatePassportHeaderLayoutCache];
        [weakSelf.view setNeedsLayout];
    } failure:^(NSError * _Nonnull error) {
        [weakSelf hideLoading];
        [weakSelf showError:error.localizedDescription ?: (NSLocalizedString(@"network_error", nil) ?: @"")];
        weakSelf.viewModel = [PassportViewModel viewModelWithPassport:nil year:weakSelf.selectedYear];
        [weakSelf.passportHeader configureWithModel:weakSelf.viewModel];
        [weakSelf.tableView reloadData];
        [weakSelf invalidatePassportHeaderLayoutCache];
        [weakSelf.view setNeedsLayout];
    }];
}

- (void)onBack {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.viewModel ? 9 : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PassportViewModel *m = self.viewModel;
    switch (indexPath.row) {
        case 0: {
            PassportDarkStatsCardCell *c = [tableView dequeueReusableCellWithIdentifier:@"stats" forIndexPath:indexPath];
            [c configureWithModel:m];
            return c;
        }
        case 1: {
            PassportGrowthBannerCell *c = [tableView dequeueReusableCellWithIdentifier:@"growth" forIndexPath:indexPath];
            [c configureWithModel:m];
            return c;
        }
        case 2: {
            PassportBarChartCardCell *c = [tableView dequeueReusableCellWithIdentifier:@"bar" forIndexPath:indexPath];
            [c configureWithModel:m];
            return c;
        }
        case 3: {
            PassportPossessionCardCell *c = [tableView dequeueReusableCellWithIdentifier:@"poss" forIndexPath:indexPath];
            [c configureWithModel:m];
            return c;
        }
        case 4: {
            PassportPositionStrengthCell *c = [tableView dequeueReusableCellWithIdentifier:@"pos" forIndexPath:indexPath];
            [c configureWithModel:m];
            return c;
        }
        case 5: {
            PassportAbilityBlockCell *c = [tableView dequeueReusableCellWithIdentifier:@"abil" forIndexPath:indexPath];
            [c configureWithModel:m];
            return c;
        }
        case 6: {
            PassportTacticalCell *c = [tableView dequeueReusableCellWithIdentifier:@"tact" forIndexPath:indexPath];
            [c configureWithModel:m];
            return c;
        }
        case 7: {
            PassportMetricBarsCell *c = [tableView dequeueReusableCellWithIdentifier:@"metric" forIndexPath:indexPath];
            [c configureWithModel:m];
            return c;
        }
        case 8: {
            PassportOutcomeCell *c = [tableView dequeueReusableCellWithIdentifier:@"out" forIndexPath:indexPath];
            [c configureWithModel:m];
            return c;
        }
        default:
            return [[UITableViewCell alloc] init];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // DarkStatsCardCell 使用叠压布局（负间距），某些系统版本 AutomaticDimension 计算会偏小甚至为 0，直接给固定高度更稳
    if (indexPath.row == 1) {
        return 197;
    }
    // BarChartCardCell 设计稿固定高度
    if (indexPath.row == 2) {
        return 341;
    }
    // PassportPossessionCardCell 设计稿固定高度
    if (indexPath.row == 3) {
        return 254;
    }
    // PassportPositionStrengthCell 设计稿固定高度
    if (indexPath.row == 4) {
        return 411;
    }
    // PassportAbilityBlockCell 设计稿固定高度
    if (indexPath.row == 5) {
        return 522;
    }
    // PassportTacticalCell（图例每行 3 个，最多 6 种身份为 2 行）
    if (indexPath.row == 6) {
        return 520;
    }
    // PassportMetricBarsCell 设计稿（90pt 数字 + 7 条情绪 bar）
    if (indexPath.row == 7) {
        return 368;
    }
    // PassportOutcomeCell 设计稿（标题 + 圆环 + 2x2 图例）
    if (indexPath.row == 8) {
        return 416;
    }
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 1) {
        return 197;
    }
    if (indexPath.row == 2) {
        return 341;
    }
    if (indexPath.row == 3) {
        return 254;
    }
    if (indexPath.row == 4) {
        return 411;
    }
    if (indexPath.row == 5) {
        return 522;
    }
    if (indexPath.row == 6) {
        return 520;
    }
    if (indexPath.row == 7) {
        return 368;
    }
    if (indexPath.row == 8) {
        return 416;
    }
    return 200;
}

- (void)updateLocalizedStrings {
    [super updateLocalizedStrings];
    _titleLabel.text = NSLocalizedString(@"passport_nav_title", nil) ?: @"我的护照";
}

@end
