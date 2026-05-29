//
//  StampAlbumCategoryDetailViewController.m
//  footBall
//

#import "StampAlbumCategoryDetailViewController.h"
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

@interface StampAlbumCategoryDetailViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, copy, nullable) NSString *categoryId;
@property (nonatomic, copy, nullable) NSString *categoryName;
@property (nonatomic, copy) NSArray<PNStampAlbumItem *> *apiItems;
@property (nonatomic, copy) NSArray<PNStampAlbumItem *> *apiDisplayItems;
@property (nonatomic, strong) UIView *topBar;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *gridOutlineView;
@property (nonatomic, strong) UICollectionView *collectionView;
@end

@implementation StampAlbumCategoryDetailViewController

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
    NSInteger count = self.apiDisplayItems.count;
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
    if (self.apiDisplayItems.count == 0) {
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

- (void)rebuildAPIDisplayItems {
    NSArray<PNStampAlbumItem *> *src = self.apiItems ?: @[];
    if (src.count == 0) {
        self.apiDisplayItems = @[];
        return;
    }
    NSMutableArray<PNStampAlbumItem *> *m = [src mutableCopy];
    NSInteger cols = kStampCategoryColumns;
    NSInteger rem = (NSInteger)m.count % cols;
    if (rem != 0) {
        NSInteger pad = cols - rem;
        for (NSInteger i = 0; i < pad; i++) {
            PNStampAlbumItem *p = [[PNStampAlbumItem alloc] init];
            p.stampId = @"";
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
    return self.apiDisplayItems.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    StampAlbumStampCell *c = [collectionView dequeueReusableCellWithReuseIdentifier:@"StampAlbumStampCell" forIndexPath:indexPath];
    PNStampAlbumItem *item = (indexPath.item < self.apiDisplayItems.count) ? self.apiDisplayItems[indexPath.item] : nil;
    [c configureWithStampItem:item indexPath:indexPath totalCount:self.apiDisplayItems.count columnCount:kStampCategoryColumns];
    return c;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item < 0 || indexPath.item >= (NSInteger)self.apiItems.count) {
        return;
    }
    PNStampAlbumItem *it = self.apiItems[indexPath.item];
    if (it.stampId.length == 0) {
        return;
    }
    if (self.didSelected) {
        self.didSelected(it);
        [self.navigationController popViewControllerAnimated:YES];
    }
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
        id obj = responseObject.dataObject;
        if ([obj isKindOfClass:NSArray.class]) {
            weakSelf.apiItems = (NSArray<PNStampAlbumItem *> *)obj;
        } else if ([responseObject.data isKindOfClass:NSArray.class]) {
            weakSelf.apiItems = [NSArray yy_modelArrayWithClass:PNStampAlbumItem.class json:responseObject.data] ?: @[];
        } else {
            weakSelf.apiItems = @[];
        }
        [weakSelf rebuildAPIDisplayItems];
        [weakSelf.collectionView reloadData];
        [weakSelf updateGridOutlineHeight];
    } failure:^(NSError * _Nonnull error) {
        [weakSelf hideLoading];
        [weakSelf showError:error.localizedDescription ?: (NSLocalizedString(@"network_error", nil) ?: @"")];
    }];
}

@end
