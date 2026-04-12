//
//  StampAlbumCategoryViewController.m
//  footBall
//

#import "StampAlbumCategoryViewController.h"
#import "StampAlbumModels.h"
#import "StampAlbumStampCell.h"
#import "StampRequest.h"
#import "StampModels.h"
#import "HTTPResponse.h"
#import <Masonry/Masonry.h>

static UIColor *StampCategoryNavBg(void) {
    return [UIColor colorWithRed:0.051 green:0.129 blue:0.133 alpha:1.0];
}

static const NSInteger kStampCategoryColumns = 3;
/// 与 `gridOutlineView` 外边框对齐：无内边距，cell 铺满；边长 floor(宽度/3)
static inline UIEdgeInsets StampCategorySectionInset(void) {
    return UIEdgeInsetsZero;
}

@interface StampAlbumCategoryViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, copy) NSArray<StampAlbumItem *> *items;
/// 含补位占位邮票：仅补满最后一行（总数为列数的整数倍）
@property (nonatomic, copy) NSArray<StampAlbumItem *> *displayItems;
@property (nonatomic, copy, nullable) NSString *categoryId;
@property (nonatomic, copy, nullable) NSString *categoryName;
@property (nonatomic, copy) NSArray<PNStampGridItem *> *apiItems;
@property (nonatomic, copy) NSArray<PNStampGridItem *> *apiDisplayItems;
@property (nonatomic, strong) UIView *topBar;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *gridOutlineView;
@property (nonatomic, strong) UICollectionView *collectionView;
@end

@implementation StampAlbumCategoryViewController

- (instancetype)initWithItems:(NSArray<StampAlbumItem *> *)items {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _items = [items copy] ?: @[];
    }
    return self;
}

- (instancetype)initWithCategoryId:(NSString *)categoryId categoryName:(NSString *)categoryName {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _categoryId = [categoryId copy];
        _categoryName = [categoryName copy];
        _apiItems = @[];
        _apiDisplayItems = @[];
    }
    return self;
}

/// 与 `sizeForItemAtIndexPath:` 一致：outline 宽度 = 屏宽 − 左右各 16
- (CGFloat)stampCategoryGridOutlineWidth {
    CGFloat vw = CGRectGetWidth(self.view.bounds);
    return MAX(0, vw - 32);
}

- (CGFloat)stampCategoryGridContentHeight {
    NSInteger count = (self.categoryId.length ? self.apiDisplayItems.count : self.displayItems.count);
    if (count == 0) {
        return 0;
    }
    CGFloat outlineW = [self stampCategoryGridOutlineWidth];
    CGFloat side = floor(outlineW / (CGFloat)kStampCategoryColumns);
    if (side < 1) {
        side = 1;
    }
    NSInteger rows = (count + kStampCategoryColumns - 1) / kStampCategoryColumns;
    return (CGFloat)rows * side;
}

- (CGFloat)stampCategoryMaxGridHeight {
    [self.view layoutIfNeeded];
    CGFloat gridTop = CGRectGetMaxY(self.topBar.frame) + 12;
    CGFloat bottomLimit = CGRectGetHeight(self.view.bounds) - self.view.safeAreaInsets.bottom - 16;
    CGFloat maxH = bottomLimit - gridTop;
    return MAX(80, maxH);
}

- (void)updateGridOutlineHeight {
    CGFloat contentH = [self stampCategoryGridContentHeight];
    CGFloat maxH = [self stampCategoryMaxGridHeight];
    if ((self.categoryId.length ? self.apiDisplayItems.count : self.displayItems.count) == 0) {
        self.gridOutlineView.hidden = YES;
        [self.gridOutlineView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(0);
        }];
        return;
    }
    self.gridOutlineView.hidden = NO;
    CGFloat h = MIN(contentH, maxH);
    h = MAX(h, 1);
    [self.gridOutlineView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(h);
    }];
}

- (void)rebuildDisplayItems {
    NSArray *src = self.items ?: @[];
    if (src.count == 0) {
        self.displayItems = @[];
        return;
    }
    NSMutableArray<StampAlbumItem *> *m = [src mutableCopy];
    NSInteger cols = kStampCategoryColumns;
    NSInteger rem = (NSInteger)m.count % cols;
    if (rem != 0) {
        NSInteger pad = cols - rem;
        for (NSInteger i = 0; i < pad; i++) {
            StampAlbumItem *p = [[StampAlbumItem alloc] init];
            p.unlocked = NO;
            [m addObject:p];
        }
    }
    self.displayItems = [m copy];
}

- (void)rebuildAPIDisplayItems {
    NSArray<PNStampGridItem *> *src = self.apiItems ?: @[];
    if (src.count == 0) {
        self.apiDisplayItems = @[];
        return;
    }
    NSMutableArray<PNStampGridItem *> *m = [src mutableCopy];
    NSInteger cols = kStampCategoryColumns;
    NSInteger rem = (NSInteger)m.count % cols;
    if (rem != 0) {
        NSInteger pad = cols - rem;
        for (NSInteger i = 0; i < pad; i++) {
            PNStampGridItem *p = [[PNStampGridItem alloc] init];
            p.unlocked = NO;
            [m addObject:p];
        }
    }
    self.apiDisplayItems = [m copy];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hidesBottomBarWhenPushed = YES;
    self.shouldShowNavigationBar = NO;
    self.view.backgroundColor = [UIColor whiteColor];

    _topBar = [[UIView alloc] init];
    _topBar.backgroundColor = StampCategoryNavBg();
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
    // 设计稿：与邮票夹主页相同顶栏标题
    _titleLabel.text = self.categoryName.length ? self.categoryName : (NSLocalizedString(@"discover_stamp_album", nil) ?: @"邮票夹");

    [_topBar addSubview:_backButton];
    [_topBar addSubview:_titleLabel];

    [self rebuildDisplayItems];
    [self rebuildAPIDisplayItems];

    _gridOutlineView = [[UIView alloc] init];
    _gridOutlineView.backgroundColor = [UIColor whiteColor];
    _gridOutlineView.layer.cornerRadius = 8;
    _gridOutlineView.layer.borderWidth = 0.5;
    _gridOutlineView.layer.borderColor = [UIColor colorWithWhite:0.82 alpha:1.0].CGColor;
    _gridOutlineView.clipsToBounds = YES;
    [self.view addSubview:_gridOutlineView];

    UICollectionViewFlowLayout *flow = [[UICollectionViewFlowLayout alloc] init];
    flow.minimumInteritemSpacing = 0;
    flow.minimumLineSpacing = 0;
    flow.sectionInset = StampCategorySectionInset();

    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flow];
    _collectionView.backgroundColor = [UIColor whiteColor];
    _collectionView.bounces = NO;
    _collectionView.alwaysBounceVertical = NO;
    if (@available(iOS 11.0, *)) {
        _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    [_collectionView registerClass:[StampAlbumStampCell class] forCellWithReuseIdentifier:@"StampAlbumStampCell"];
    [_gridOutlineView addSubview:_collectionView];

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
    [_gridOutlineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_topBar.mas_bottom).offset(12);
        make.leading.equalTo(self.view).offset(16);
        make.trailing.equalTo(self.view).offset(-16);
        // 高度按内容计算（见 updateGridOutlineHeight），不足一屏时下边框贴齐最后一行；超过一屏则限高并滚动
        make.height.mas_equalTo(120);
    }];
    [_collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(_gridOutlineView);
    }];

    if (self.categoryId.length > 0) {
        [self loadAllStampsInCategory];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self updateGridOutlineHeight];
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)onBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)updateLocalizedStrings {
    [super updateLocalizedStrings];
    _titleLabel.text = self.categoryName.length ? self.categoryName : (NSLocalizedString(@"discover_stamp_album", nil) ?: @"邮票夹");
}

#pragma mark - UICollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.categoryId.length ? self.apiDisplayItems.count : self.displayItems.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    StampAlbumStampCell *c = [collectionView dequeueReusableCellWithReuseIdentifier:@"StampAlbumStampCell" forIndexPath:indexPath];
    if (self.categoryId.length) {
        PNStampGridItem *item = self.apiDisplayItems[indexPath.item];
        [c configureWithStamp:item indexPath:indexPath totalCount:self.apiDisplayItems.count columnCount:kStampCategoryColumns];
    } else {
        StampAlbumItem *item = self.displayItems[indexPath.item];
        [c configureWithItem:item indexPath:indexPath totalCount:self.displayItems.count columnCount:kStampCategoryColumns];
    }
    return c;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat w = CGRectGetWidth(collectionView.bounds);
    if (w < 1) {
        w = [self stampCategoryGridOutlineWidth];
    }
    CGFloat side = floor(w / (CGFloat)kStampCategoryColumns);
    if (side < 1) {
        side = 1;
    }
    return CGSizeMake(side, side);
}

#pragma mark - API

- (void)loadAllStampsInCategory {
    if (self.categoryId.length == 0) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [self showLoading];
    [[StampRequest shared] getAllStampsInCategory:self.categoryId success:^(HTTPResponse * _Nullable responseObject) {
        [weakSelf hideLoading];
        // 兼容后端暂时返回分类列表的情况（见 StampRequest 解析）。
        id obj = responseObject.dataObject;
        if ([obj isKindOfClass:NSArray.class] && [(NSArray *)obj count] > 0) {
            id first = [(NSArray *)obj firstObject];
            if ([first isKindOfClass:PNStampGridItem.class]) {
                weakSelf.apiItems = (NSArray<PNStampGridItem *> *)obj;
                [weakSelf rebuildAPIDisplayItems];
                [weakSelf.collectionView reloadData];
                [weakSelf updateGridOutlineHeight];
                return;
            }
            if ([first isKindOfClass:PNStampCategory.class]) {
                [weakSelf showError:@"接口返回了分类列表（id/name/icon/sortOrder），缺少邮票字段，无法渲染网格。请确认后端返回 StampVO 列表。"];
                weakSelf.apiItems = @[];
                [weakSelf rebuildAPIDisplayItems];
                [weakSelf.collectionView reloadData];
                [weakSelf updateGridOutlineHeight];
                return;
            }
        }

        // 兜底：尝试按 StampVO 列表解析
        NSArray<PNStampGridItem *> *list = nil;
        if ([responseObject.data isKindOfClass:NSArray.class]) {
            list = [NSArray yy_modelArrayWithClass:PNStampGridItem.class json:responseObject.data];
        }
        weakSelf.apiItems = list ?: @[];
        [weakSelf rebuildAPIDisplayItems];
        [weakSelf.collectionView reloadData];
        [weakSelf updateGridOutlineHeight];
    } failure:^(NSError * _Nonnull error) {
        [weakSelf hideLoading];
        [weakSelf showError:error.localizedDescription ?: (NSLocalizedString(@"network_error", nil) ?: @"")];
    }];
}

@end
