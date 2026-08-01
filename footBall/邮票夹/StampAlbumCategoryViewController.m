//
//  StampAlbumCategoryViewController.m
//  footBall
//

#import "StampAlbumCategoryViewController.h"
#import "StampAlbumStampCell.h"
#import "StampAlbumCategoryDetailViewController.h"
#import "StampRequest.h"
#import "StampModels.h"
#import "CommunityRequest.h"
#import "HTTPResponse.h"
#import <Masonry/Masonry.h>
#import <QMUIKit/QMUITips.h>

static UIColor *StampAlbumNavBg(void) {
    return [UIColor colorWithRed:0.051 green:0.129 blue:0.133 alpha:1.0];
}

static const CGFloat kStampFilterRowHeight = 40;
/// 分类标题与上一 section 网格底部、下一 section 网格顶部的间距（各 15pt）
static const CGFloat kStampAlbumSectionTitleTopGap = 15;
static const CGFloat kStampAlbumSectionTitleBottomGap = 15;
/// 每组固定十宫格：5 列 × 2 行，单格边长 = 网格宽度 / 5
static const NSInteger kStampAlbumGridColumns = 5;
static const NSInteger kStampAlbumGridCount = 10;

static CGFloat StampAlbumSectionHeaderHeight(void) {
    UIFont *titleFont = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    return kStampAlbumSectionTitleTopGap + ceil(titleFont.lineHeight) + kStampAlbumSectionTitleBottomGap;
}

static NSArray<NSString *> *StampAlbumCanonicalTitles(void) {
    return @[
        NSLocalizedString(@"stamp_album_section_stadium", nil) ?: @"球场",
        NSLocalizedString(@"stamp_album_section_trophy", nil) ?: @"奖杯",
        NSLocalizedString(@"stamp_album_section_event", nil) ?: @"事件",
        NSLocalizedString(@"stamp_album_section_identity", nil) ?: @"身份"
    ];
}

static NSString *StampAlbumNormalizedCategoryTitle(NSString *rawTitle, NSInteger fallbackIndex) {
    NSArray<NSString *> *canonical = StampAlbumCanonicalTitles();
    NSString *raw = [rawTitle isKindOfClass:NSString.class] ? rawTitle : @"";
    NSString *trimmed = [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *lower = trimmed.lowercaseString;

    if ([trimmed containsString:@"球场"] || [lower containsString:@"stadium"]) return canonical[0];
    if ([trimmed containsString:@"奖杯"] || [lower containsString:@"trophy"]) return canonical[1];
    if ([trimmed containsString:@"事件"] || [lower containsString:@"event"]) return canonical[2];
    if ([trimmed containsString:@"身份"] || [lower containsString:@"identity"]) return canonical[3];

    for (NSString *title in canonical) {
        if ([trimmed isEqualToString:title]) return title;
    }
    if (fallbackIndex >= 0 && fallbackIndex < (NSInteger)canonical.count) {
        return canonical[fallbackIndex];
    }
    return nil;
}

#pragma mark - Grid table cell

@interface StampAlbumGridTableCell : UITableViewCell <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, copy) NSArray<PNStampAlbumItem *> *items;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, assign) CGFloat itemSide;
@property (nonatomic, copy, nullable) void (^onSelectItem)(PNStampAlbumItem *item);
@end

@implementation StampAlbumGridTableCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.contentView.layoutMargins = UIEdgeInsetsZero;
        self.preservesSuperviewLayoutMargins = NO;
        self.separatorInset = UIEdgeInsetsZero;
        UICollectionViewFlowLayout *flow = [[UICollectionViewFlowLayout alloc] init];
        flow.minimumInteritemSpacing = 0;
        flow.minimumLineSpacing = 0;
        flow.sectionInset = UIEdgeInsetsZero;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flow];
        _collectionView.backgroundColor = [UIColor whiteColor];
        _collectionView.layer.borderWidth = 0.5;
        _collectionView.layer.borderColor = [UIColor colorWithWhite:0.88 alpha:1.0].CGColor;
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.scrollEnabled = NO;
        _collectionView.userInteractionEnabled = YES;
        _collectionView.allowsSelection = YES;
        [_collectionView registerClass:[StampAlbumStampCell class] forCellWithReuseIdentifier:@"StampAlbumStampCell"];
        [self.contentView addSubview:_collectionView];
        [_collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentView).offset(16);
            make.trailing.equalTo(self.contentView).offset(-16);
            make.top.equalTo(self.contentView);
            make.height.mas_equalTo(0);
            make.bottom.equalTo(self.contentView);
        }];
    }
    return self;
}

- (void)configureWithItems:(NSArray<PNStampAlbumItem *> *)items tableWidth:(CGFloat)tableWidth {
    NSMutableArray<PNStampAlbumItem *> *display = [NSMutableArray arrayWithCapacity:kStampAlbumGridCount];
    NSArray<PNStampAlbumItem *> *src = items ?: @[];
    NSInteger take = MIN((NSInteger)src.count, kStampAlbumGridCount);
    for (NSInteger i = 0; i < take; i++) {
        [display addObject:src[i]];
    }
    while ((NSInteger)display.count < kStampAlbumGridCount) {
        PNStampAlbumItem *pad = [[PNStampAlbumItem alloc] init];
        pad.stampId = @"";
        [display addObject:pad];
    }
    self.items = [display copy];
    CGFloat inner = MAX(0, tableWidth - 32);
    self.itemSide = inner > 0 ? floor(inner / (CGFloat)kStampAlbumGridColumns) : 0;
    NSInteger rows = kStampAlbumGridCount / kStampAlbumGridColumns;
    CGFloat h = rows * self.itemSide;
    [_collectionView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(h);
    }];
    [_collectionView reloadData];
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return kStampAlbumGridCount;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    StampAlbumStampCell *c = [collectionView dequeueReusableCellWithReuseIdentifier:@"StampAlbumStampCell" forIndexPath:indexPath];
    PNStampAlbumItem *item = (indexPath.item < (NSInteger)self.items.count) ? self.items[indexPath.item] : nil;
    [c configureWithStampItem:item indexPath:indexPath totalCount:kStampAlbumGridCount columnCount:kStampAlbumGridColumns];
    return c;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item < 0 || indexPath.item >= (NSInteger)self.items.count) {
        return;
    }
    PNStampAlbumItem *it = self.items[indexPath.item];
    if (![it.stampId isKindOfClass:NSString.class] || it.stampId.length == 0) {
        return;
    }
    if (self.onSelectItem) {
        self.onSelectItem(it);
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(self.itemSide, self.itemSide);
}

@end

#pragma mark - StampAlbumCategoryViewController

@interface StampAlbumCategoryViewController () <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIView *topBar;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *filterButton;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<PNStampCategory *> *allCategories;
@property (nonatomic, copy) NSArray<PNStampCategory *> *categories;
@property (nonatomic, assign) CGFloat tableLayoutWidth;

// Filter dropdown
@property (nonatomic, copy) NSArray<NSString *> *filterOptions; // e.g. 球场分类/分类二/分类三
@property (nonatomic, assign) BOOL filterApplied;
@property (nonatomic, assign) NSInteger selectedFilterIndex;
@property (nonatomic, copy) NSString *filterBaseTitle;
@property (nonatomic, strong) UIView *filterOverlayView;
@property (nonatomic, strong) UIView *filterDropdownView;
@property (nonatomic, strong) UITableView *filterTableView;
@property (nonatomic, strong) UITapGestureRecognizer *filterOverlayTapGesture;
@end

@implementation StampAlbumCategoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hidesBottomBarWhenPushed = YES;
    self.shouldShowNavigationBar = NO;
    self.view.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0];
    self.tableLayoutWidth = CGRectGetWidth(self.view.bounds);
    [self buildTopBar];
    [self buildTable];
    [self buildFilterDropdownUI];
    [self loadStampCollection];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat w = CGRectGetWidth(self.tableView.bounds);
    if (w > 0 && fabs(w - self.tableLayoutWidth) > 0.5) {
        self.tableLayoutWidth = w;
        [self.tableView reloadData];
    }
}



static UIColor *StampAlbumRarityColor(NSString *rarity) {
    NSString *r = [rarity isKindOfClass:NSString.class] ? [(NSString *)rarity uppercaseString] : @"";
    if ([r isEqualToString:@"LEGENDARY"]) return [UIColor colorWithHexString:@"#D9B44A"];
    if ([r isEqualToString:@"EPIC"]) return [UIColor colorWithHexString:@"#8E62D9"];
    if ([r isEqualToString:@"RARE"]) return [UIColor colorWithHexString:@"#3C6FD9"];
    return [UIColor colorWithHexString:@"#7C9A8B"];
}

- (void)loadStampCollection {
    __weak typeof(self) weakSelf = self;
    void (^handleCategories)(NSArray<PNStampCategory *> *) = ^(NSArray<PNStampCategory *> *cats) {
        weakSelf.allCategories = cats ?: @[];
        weakSelf.categories = weakSelf.allCategories;
        [weakSelf setupFilterOptions];
        [weakSelf.tableView reloadData];
        [weakSelf.filterTableView reloadData];
    };
    void (^handleError)(NSError *) = ^(NSError *error) {
        [QMUITips showError:error.localizedDescription];
    };
    // 查看自己邮票
    [[StampRequest shared] getSelectableStampsSuccess:^(HTTPResponse * _Nullable responseObject) {
        NSArray<PNStampCategory *> *cats = [responseObject.dataObject isKindOfClass:NSArray.class] ? (NSArray<PNStampCategory *> *)responseObject.dataObject : @[];
        handleCategories(cats);
    } failure:handleError];
}
;

- (void)setupFilterOptions {
    // 分类名：按 allCategories 出现顺序去重（不含「全部」）
    NSMutableArray<NSString *> *categoryTitles = [NSMutableArray array];
    for (PNStampCategory *c in self.allCategories) {
        NSString *t = c.categoryName ?: @"";
        if (!t.length) continue;
        BOOL exists = NO;
        for (NSString *x in categoryTitles) {
            if ([x isEqualToString:t]) { exists = YES; break; }
        }
        if (!exists) [categoryTitles addObject:t];
    }

    NSMutableArray *uiTitles = [NSMutableArray array];
    [uiTitles addObject:NSLocalizedString(@"stamp_album_filter_all", nil) ?: @"全部"];
    [uiTitles addObjectsFromArray:categoryTitles];
    self.filterOptions = [uiTitles copy];

    self.filterApplied = NO;
    self.selectedFilterIndex = -1;
    // 复位筛选按钮标题：否则上次选了某分类后标题仍是「XX分类 ▼」，与实际已重置的 filterApplied 状态不符
    [self.filterButton setTitle:[NSString stringWithFormat:@"%@ ▼", self.filterBaseTitle ?: (NSLocalizedString(@"stamp_album_filter", nil) ?: @"筛选")] forState:UIControlStateNormal];
}

- (void)buildTopBar {
    _topBar = [[UIView alloc] init];
    _topBar.backgroundColor = StampAlbumNavBg();
    [self.view addSubview:_topBar];
    _backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImage *backImage = [[UIImage imageNamed:@"nav_back"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    if (backImage) {
        [_backButton setImage:backImage forState:UIControlStateNormal];
        _backButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    } else {
        [_backButton setTitle:NSLocalizedString(@"back", nil) ?: @"返回" forState:UIControlStateNormal];
    }
    _backButton.tintColor = [UIColor whiteColor];
    [_backButton addTarget:self action:@selector(onBack) forControlEvents:UIControlEventTouchUpInside];
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.text = NSLocalizedString(@"discover_stamp_album", nil) ?: @"邮票夹";

    _filterButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _filterButton.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    _filterButton.backgroundColor = [UIColor clearColor];
    _filterButton.tintColor = [UIColor whiteColor];
    _filterButton.adjustsImageWhenHighlighted = NO;
    _filterButton.adjustsImageWhenDisabled = NO;
    _filterButton.showsTouchWhenHighlighted = NO;
    [_filterButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_filterButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    self.filterBaseTitle = NSLocalizedString(@"stamp_album_filter", nil) ?: @"筛选";
    [_filterButton setTitle:[NSString stringWithFormat:@"%@ ▼", self.filterBaseTitle] forState:UIControlStateNormal];
    _filterButton.layer.cornerRadius = 2;
    _filterButton.layer.borderWidth = 0.6;
    _filterButton.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.55].CGColor;
    _filterButton.contentEdgeInsets = UIEdgeInsetsMake(3.5, 8, 3.5, 8);
    [_filterButton addTarget:self action:@selector(onFilterTapped) forControlEvents:UIControlEventTouchUpInside];
    [_topBar addSubview:_backButton];
    [_topBar addSubview:_titleLabel];
    [_topBar addSubview:_filterButton];
    [_topBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(44);
    }];
    [_backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(_topBar).offset(16);
        make.bottom.equalTo(_topBar).offset(-8);
        make.width.height.mas_equalTo(24);
    }];
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(_topBar);
        make.centerY.equalTo(_backButton);
    }];
    [_filterButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(_topBar).offset(-12);
        make.centerY.equalTo(_backButton);
    }];
}

- (void)buildTable {
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0];
    _tableView.estimatedRowHeight = 200;
    _tableView.rowHeight = UITableViewAutomaticDimension;
    if (@available(iOS 15.0, *)) {
        // 避免系统默认在首个 section 前插入额外空白，使 section 与首行紧贴
        _tableView.sectionHeaderTopPadding = 0;
    }
    [_tableView registerClass:[StampAlbumGridTableCell class] forCellReuseIdentifier:@"StampAlbumGridTableCell"];
    [self.view addSubview:_tableView];
    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_topBar.mas_bottom);
        make.leading.trailing.bottom.equalTo(self.view);
    }];
}

- (void)onBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)buildFilterDropdownUI {
    _filterOverlayView = [[UIView alloc] initWithFrame:self.view.bounds];
    _filterOverlayView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.0];
    _filterOverlayView.hidden = YES;
    [self.view addSubview:_filterOverlayView];

    _filterOverlayTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onOverlayTapped)];
    _filterOverlayTapGesture.delegate = self;
    _filterOverlayTapGesture.cancelsTouchesInView = NO;
    [_filterOverlayView addGestureRecognizer:_filterOverlayTapGesture];

    _filterDropdownView = [[UIView alloc] initWithFrame:CGRectZero];
    _filterDropdownView.backgroundColor = [UIColor whiteColor];
    _filterDropdownView.layer.cornerRadius = 12;
    _filterDropdownView.layer.masksToBounds = YES;
    _filterDropdownView.layer.shadowColor = [UIColor blackColor].CGColor;
    _filterDropdownView.layer.shadowOpacity = 0.15;
    _filterDropdownView.layer.shadowRadius = 10;
    _filterDropdownView.layer.shadowOffset = CGSizeMake(0, 4);
    [_filterOverlayView addSubview:_filterDropdownView];

    _filterTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _filterTableView.dataSource = self;
    _filterTableView.delegate = self;
    _filterTableView.backgroundColor = [UIColor clearColor];
    _filterTableView.scrollEnabled = NO;
    _filterTableView.allowsSelection = YES;
    _filterTableView.separatorInset = UIEdgeInsetsMake(0, 16, 0, 16);
    _filterTableView.separatorColor = [UIColor colorWithWhite:0.88 alpha:1.0];
    _filterTableView.rowHeight = kStampFilterRowHeight;
    _filterTableView.estimatedRowHeight = 0;
    if (@available(iOS 15.0, *)) {
        // 默认非 0 会在首行前多出一块空白，固定高度容器里会把最后一行挤出可视区域
        _filterTableView.sectionHeaderTopPadding = 0;
    }
    if (@available(iOS 11.0, *)) {
        _filterTableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [_filterDropdownView addSubview:_filterTableView];
    [_filterTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(_filterDropdownView);
    }];

    [_filterTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"StampFilterCell"];
}

- (void)onOverlayTapped {
    [self hideFilterDropdown];
}

- (void)onFilterTapped {
    if (self.filterOverlayView.hidden) {
        [self showFilterDropdown];
    } else {
        [self hideFilterDropdown];
    }
}

#pragma mark - Filter dropdown

/// 宽度：按文案略留边即可，避免 minW 过大撑满；上限防止超屏。
- (CGFloat)stampAlbumPreferredFilterDropdownWidth {
    UIFont *font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    CGFloat maxText = 0;
    for (NSString *t in self.filterOptions) {
        if (![t isKindOfClass:[NSString class]] || !t.length) {
            continue;
        }
        CGRect r = [t boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, kStampFilterRowHeight)
                                   options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                attributes:@{ NSFontAttributeName: font }
                                   context:nil];
        maxText = MAX(maxText, ceil(CGRectGetWidth(r)));
    }
    static const CGFloat hPad = 24; // 左右各约 12
    static const CGFloat minW = 112;
    CGFloat w = MAX(maxText + hPad, minW);
    CGFloat screenW = CGRectGetWidth(self.view.bounds);
    CGFloat cap = MAX(100, screenW - 24);
    return MIN(w, cap);
}

- (void)showFilterDropdown {
    if (self.filterOptions.count == 0) return;

    self.filterOverlayView.hidden = NO;
    self.filterOverlayView.frame = self.view.bounds;
    [self.view bringSubviewToFront:self.filterOverlayView];

    // 与筛选按钮右对齐展开（按钮在导航栏右侧），宽度按文案计算
    CGRect btnFrame = [self.filterButton.superview convertRect:self.filterButton.frame toView:self.view];
    CGFloat dropdownW = [self stampAlbumPreferredFilterDropdownWidth];
    CGFloat dropdownH = kStampFilterRowHeight * (CGFloat)self.filterOptions.count;

    CGFloat screenW = CGRectGetWidth(self.view.bounds);
    CGFloat x = CGRectGetMaxX(btnFrame) - dropdownW;
    CGFloat y = CGRectGetMaxY(btnFrame) + 6;
    if (y + dropdownH > CGRectGetHeight(self.view.bounds) - 12) {
        y = CGRectGetHeight(self.view.bounds) - 12 - dropdownH;
    }
    if (x + dropdownW > screenW - 12) {
        x = screenW - 12 - dropdownW;
    }
    if (x < 12) {
        x = 12;
    }

    self.filterDropdownView.frame = CGRectMake(x, y, dropdownW, dropdownH);
    [self.filterTableView reloadData];
    [self.filterTableView layoutIfNeeded];
    self.filterDropdownView.transform = CGAffineTransformMakeScale(0.98, 0.98);
    self.filterDropdownView.alpha = 0.0;

    [UIView animateWithDuration:0.18 animations:^{
        self.filterDropdownView.transform = CGAffineTransformIdentity;
        self.filterDropdownView.alpha = 1.0;
    }];
}

#pragma mark - UIGestureRecognizerDelegate

/// 点击下拉列表区域时，不要让全屏 overlay 的手势抢触摸，否则 table 收不到点击、筛选逻辑不触发。
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (gestureRecognizer != self.filterOverlayTapGesture) {
        return YES;
    }
    CGPoint p = [touch locationInView:self.filterOverlayView];
    return !CGRectContainsPoint(self.filterDropdownView.frame, p);
}

- (void)hideFilterDropdown {
    if (self.filterOverlayView.hidden) return;
    [UIView animateWithDuration:0.15 animations:^{
        self.filterDropdownView.alpha = 0.0;
        self.filterDropdownView.transform = CGAffineTransformMakeScale(0.98, 0.98);
    } completion:^(BOOL finished) {
        self.filterOverlayView.hidden = YES;
        self.filterDropdownView.transform = CGAffineTransformIdentity;
        self.filterDropdownView.alpha = 1.0;
    }];
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.filterTableView) return 1;
    return self.categories.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.filterTableView) return self.filterOptions.count;
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.filterTableView) {
        return kStampFilterRowHeight;
    }
    return UITableViewAutomaticDimension;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.filterTableView) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StampFilterCell" forIndexPath:indexPath];
        NSString *opt = (indexPath.row < self.filterOptions.count) ? self.filterOptions[indexPath.row] : @"";
        cell.backgroundColor = [UIColor clearColor];
        cell.contentView.backgroundColor = [UIColor clearColor];
        cell.textLabel.text = opt;
        cell.textLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
        cell.textLabel.textColor = [UIColor colorWithWhite:0 alpha:1.0];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.numberOfLines = 1;
        cell.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        // 下拉列表设计稿：纯文字点击即可，不额外展示勾选图标
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        UIView *selectedBg = [[UIView alloc] init];
        selectedBg.backgroundColor = [UIColor clearColor];
        cell.selectedBackgroundView = selectedBg;
        return cell;
    }

    StampAlbumGridTableCell *c = [tableView dequeueReusableCellWithIdentifier:@"StampAlbumGridTableCell" forIndexPath:indexPath];
    PNStampCategory *sec = self.categories[indexPath.section];
    CGFloat w = CGRectGetWidth(tableView.bounds);
    if (w < 1) {
        w = CGRectGetWidth(self.view.bounds);
    }
    [c configureWithItems:sec.stamps tableWidth:w];
    __weak typeof(self) weakSelf = self;
    c.onSelectItem = ^(PNStampAlbumItem *item) {
        if (!weakSelf) return;
        if (item && weakSelf.didSelected) {
            weakSelf.didSelected(item);
            [weakSelf.navigationController popViewControllerAnimated:YES];
        }
    };
    return c;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (tableView == self.filterTableView) return nil;
    PNStampCategory *m = self.categories[section];
    UIView *wrap = [[UIView alloc] init];
    wrap.backgroundColor = [UIColor clearColor];
    UILabel *title = [[UILabel alloc] init];
    title.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    title.textColor = [UIColor colorWithWhite:0.12 alpha:1.0];
    title.text = m.categoryName;
    UIButton *more = [UIButton buttonWithType:UIButtonTypeSystem];
    [more setTitle:NSLocalizedString(@"stamp_album_view_more", nil) ?: @"查看更多" forState:UIControlStateNormal];
    more.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    [more setTitleColor:[UIColor colorWithWhite:0.55 alpha:1.0] forState:UIControlStateNormal];
    [more addTarget:self action:@selector(onViewMore:) forControlEvents:UIControlEventTouchUpInside];
    more.tag = section;
    [wrap addSubview:title];
    [wrap addSubview:more];
    // 标题上距上一 section 的 StampAlbumGridTableCell 底部 15pt、下距本 section 网格顶 15pt（由 header 总高保证）
    [title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(wrap).offset(16);
        make.top.equalTo(wrap).offset(kStampAlbumSectionTitleTopGap);
    }];
    [more mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(wrap).offset(-16);
        make.centerY.equalTo(title);
    }];
    return wrap;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (tableView == self.filterTableView) return 0;
    return StampAlbumSectionHeaderHeight();
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (tableView == self.filterTableView) return 0;
    return 0.01;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (tableView == self.filterTableView) return nil;
    return [[UIView alloc] init];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView != self.filterTableView) return;
    NSInteger idx = indexPath.row;
    if (idx < 0 || idx >= self.filterOptions.count) return;

    NSString *base = self.filterBaseTitle ?: @"筛选";

    // 第 0 行：全部 → 清除筛选
    if (idx == 0) {
        self.filterApplied = NO;
        self.selectedFilterIndex = -1;
        self.categories = self.allCategories ?: @[];
        [self.filterButton setTitle:[NSString stringWithFormat:@"%@ ▼", base] forState:UIControlStateNormal];
    } else if (self.filterApplied && idx == self.selectedFilterIndex) {
        // 再次点当前分类：取消筛选（与「全部」同效）
        self.filterApplied = NO;
        self.selectedFilterIndex = -1;
        self.categories = self.allCategories ?: @[];
        [self.filterButton setTitle:[NSString stringWithFormat:@"%@ ▼", base] forState:UIControlStateNormal];
    } else {
        self.filterApplied = YES;
        self.selectedFilterIndex = idx;
        NSString *opt = self.filterOptions[idx] ?: @"";
        NSMutableArray<PNStampCategory *> *sub = [NSMutableArray array];
        for (PNStampCategory *c in (self.allCategories ?: @[])) {
            NSString *name = [c.categoryName isKindOfClass:NSString.class] ? c.categoryName : @"";
            if (name.length && [name isEqualToString:opt]) {
                [sub addObject:c];
            }
        }
        self.categories = [sub copy];
        [self.filterButton setTitle:[NSString stringWithFormat:@"%@ ▼", opt] forState:UIControlStateNormal];
    }

    [self.tableView reloadData];
    [self.filterTableView reloadData];
    [self hideFilterDropdown];
}

- (void)onViewMore:(UIButton *)sender {
    NSInteger section = sender.tag;
    if (section < 0 || section >= (NSInteger)self.categories.count) {
        return;
    }
    PNStampCategory *sec = self.categories[section];
    NSString *catId = sec.categoryId;
    NSString *catName = sec.categoryName;
    StampAlbumCategoryDetailViewController *vc = nil;
    vc = [[StampAlbumCategoryDetailViewController alloc] initWithCategoryId:catId categoryName:catName];
    __weak typeof(self) weakSelf = self;
    vc.didSelected = ^(PNStampAlbumItem *stamp) {
        if (!weakSelf) return;
        if (weakSelf.didSelected) {
            weakSelf.didSelected(stamp);
            [weakSelf.navigationController popViewControllerAnimated:YES];
        }
    };
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)updateLocalizedStrings {
    [super updateLocalizedStrings];
    _titleLabel.text = NSLocalizedString(@"discover_stamp_album", nil) ?: @"邮票夹";
    NSString *base = NSLocalizedString(@"stamp_album_filter", nil) ?: @"筛选";
    self.filterBaseTitle = base;
    if (self.filterOptions.count > 0) {
        NSMutableArray *opts = [self.filterOptions mutableCopy];
        opts[0] = NSLocalizedString(@"stamp_album_filter_all", nil) ?: @"全部";
        self.filterOptions = [opts copy];
    }
    if (self.filterApplied && self.selectedFilterIndex >= 1 && self.selectedFilterIndex < (NSInteger)self.filterOptions.count) {
        NSString *opt = self.filterOptions[self.selectedFilterIndex] ?: @"";
        [_filterButton setTitle:[NSString stringWithFormat:@"%@ ▼", opt] forState:UIControlStateNormal];
    } else {
        [_filterButton setTitle:[NSString stringWithFormat:@"%@ ▼", base] forState:UIControlStateNormal];
    }
    [self.tableView reloadData];
    [self.filterTableView reloadData];
}

@end
