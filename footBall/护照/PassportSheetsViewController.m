//
//  PassportSheetsViewController.m
//  footBall
//

#import "PassportSheetsViewController.h"
#import "PassportHeader2View.h"
#import "PassportViewModel.h"
#import "ProfileRequest.h"
#import "HTTPResponse.h"
#import "Passport.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>
#import "StampRequest.h"
#import "StampModels.h"

static UIColor *PassportSheetsNavBg(void) {
    return [UIColor colorWithRed:0.05 green:0.05 blue:0.06 alpha:1.0];
}

static UIColor *PassportSheetsListBg(void) {
    return [UIColor colorWithRed:0.94 green:0.94 blue:0.95 alpha:1.0];
}

#pragma mark - Stamp sheet grid
@interface PassportStampSheetGridView : UIView
@property (nonatomic, copy) NSArray<PNStampAlbumItem *> *items;
- (void)configureWithItems:(NSArray<PNStampAlbumItem *> *)items;
@end
@implementation PassportStampSheetGridView
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        NSInteger rowItemCount = 5;
        UIImageView *preItem = nil;
        CGFloat itemHorMargin = (SCREEN_WIDTH - 32 - 20 - rowItemCount*50)/(rowItemCount-1);
        for (int i = 0; i<15; i++) {
            UIImageView *item = UIImageView.alloc.init;
            item.tag = 0x900 + i;
            item.image = [UIImage imageNamed:@"stamp_add"];
            item.layer.cornerRadius = 25;
            item.clipsToBounds = YES;
            [self addSubview:item];
            [item mas_makeConstraints:^(MASConstraintMaker *make) {
                make.width.height.equalTo(@50);
                if (preItem == nil) {
                    make.left.equalTo(@0);
                } else {
                    make.left.equalTo(preItem.mas_right).offset(itemHorMargin);
                }
                if (i/rowItemCount == 0) {
                    make.top.equalTo(self);
                } else if (i/rowItemCount == 1) {
                    make.centerY.equalTo(self);
                } else {
                    make.bottom.equalTo(self);
                }
            }];
            if (i%rowItemCount == rowItemCount-1) {
                preItem = nil;
            } else {
                preItem = item;
            }
        }
        
    }
    return self;
}

- (void)configureWithItems:(NSArray<PNStampAlbumItem *> *)items {
    self.items = items ?: @[];
    for (int i = 0; i < 15; i++) {
        UIImageView *iv = (UIImageView *)[self viewWithTag:0x900 + i];
        if (![iv isKindOfClass:UIImageView.class]) {
            continue;
        }
        if (i < (int)self.items.count) {
            PNStampAlbumItem *it = self.items[(NSUInteger)i];
            if (it.image.length > 0) {
                [iv sd_setImageWithURL:[NSURL URLWithString:it.image] placeholderImage:[UIImage imageNamed:@"stamp_add"]];
            } else {
                [iv sd_cancelCurrentImageLoad];
                iv.image = [UIImage imageNamed:@"stamp_add"];
            }
            iv.alpha = it.unlocked ? 1.0 : 0.35;
        } else {
            [iv sd_cancelCurrentImageLoad];
            iv.image = [UIImage imageNamed:@"stamp_add"];
            iv.alpha = 1.0;
        }
    }
}

@end

#pragma mark - Header2 card (first row)

@interface PassportHeader2Card : UIView
@property (nonatomic, strong) UIView *card;
@property (nonatomic, strong) PassportHeader2View *header2;
@property (nonatomic, strong) PassportStampSheetGridView *bottomGridView;
@end

@implementation PassportHeader2Card

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        UIView *topBg = UIView.alloc.init;
        topBg.backgroundColor = [UIColor colorWithHexString:@"#0D2122"];
        [self addSubview:topBg];
        [topBg mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.equalTo(self);
            make.height.equalTo(@76);
        }];
        
        
        _card = [[UIView alloc] init];
        _card.backgroundColor = [UIColor colorWithHexString:@"#FEFEFE"];
        _card.layer.cornerRadius = 16;
        _card.clipsToBounds = YES;
        [self addSubview:_card];

        UIImageView *sepTop= [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"passport_header_sep"]];
        [_card addSubview:sepTop];
        [sepTop mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_card).offset(10);
            make.height.mas_equalTo(10);
            make.leading.trailing.equalTo(_card).insets(UIEdgeInsetsMake(0, 10, 0, 10));
        }];

        _header2 = [[PassportHeader2View alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH-32, 0)];
        [_card addSubview:_header2];

        CGFloat whUnit = (SCREEN_WIDTH - 32 - 32) / 8.0;
        CGFloat headerH = whUnit * 5.0;

        [_card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self).insets(UIEdgeInsetsMake(8, 16, 8, 16));
        }];
        [_header2 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_card).offset(30);
            make.leading.trailing.equalTo(_card).insets(UIEdgeInsetsMake(0, 16, 0, 16));
            make.height.mas_equalTo(headerH);
        }];

        StampDashView *dashView = [[StampDashView alloc] init];
        [_card addSubview:dashView];
        [dashView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.header2.mas_bottom).offset(10);
            make.height.mas_equalTo(5);
            make.leading.trailing.equalTo(_card);
        }];
        UIImageView *sepMid= [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"passport_header_sep"]];
        [_card addSubview:sepMid];
        self.bottomGridView = PassportStampSheetGridView.alloc.init;
        [_card addSubview:self.bottomGridView];
        [sepMid mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.header2.mas_bottom).offset(20);
            make.height.mas_equalTo(10);
            make.leading.trailing.equalTo(_card).insets(UIEdgeInsetsMake(0, 10, 0, 10));
        }];

        [self.bottomGridView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.header2.mas_bottom).offset(40);
            make.height.mas_equalTo(200);
            make.leading.trailing.equalTo(_card).insets(UIEdgeInsetsMake(0, 10, 0, 10));
        }];

    }
    return self;
}

- (void)configureWithModel:(PassportViewModel *)model {
    [self.header2 configureWithModel:model];
}

@end

#pragma mark - Stamp sheet placeholder (5×3 grid)

@interface PassportStampSheetCardCell : UITableViewCell
@property (nonatomic, strong) UIView *card;
@property (nonatomic, strong) PassportStampSheetGridView *topGridView;
@property (nonatomic, strong) PassportStampSheetGridView *bottomGridView;
@property (nonatomic, strong) UILabel *categoryTitleLabel;
@property (nonatomic, strong) UILabel *categoryProgressLabel;

@end

@implementation PassportStampSheetCardCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];

        _card = [[UIView alloc] init];
        _card.backgroundColor = [UIColor whiteColor];
        _card.layer.cornerRadius = 16;
        _card.clipsToBounds = YES;
        [self.contentView addSubview:_card];
        [_card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(8, 16, 8, 16));
        }];
        
        UIImageView *sepTop= [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"passport_header_sep"]];
        [_card addSubview:sepTop];
        [sepTop mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_card).offset(10);
            make.height.mas_equalTo(10);
            make.leading.trailing.equalTo(_card).insets(UIEdgeInsetsMake(0, 10, 0, 10));
        }];
        self.categoryTitleLabel = [[UILabel alloc] init];
        self.categoryTitleLabel.font = FontManager.sharedManager.font16Bold;
        self.categoryTitleLabel.textColor = [UIColor colorWithHexString:@"#285D4B"];
        [_card addSubview:self.categoryTitleLabel];
        self.categoryProgressLabel = [[UILabel alloc] init];
        self.categoryProgressLabel.font = FontManager.sharedManager.font14Regular;
        self.categoryProgressLabel.textColor = [UIColor colorWithHexString:@"#34343B"];
        self.categoryProgressLabel.textAlignment = NSTextAlignmentRight;
        [_card addSubview:self.categoryProgressLabel];
        [self.categoryTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_card).offset(16);
            make.top.equalTo(_card).offset(26);
        }];
        [self.categoryProgressLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(_card).offset(-16);
            make.centerY.equalTo(self.categoryTitleLabel);
        }];

        self.topGridView = PassportStampSheetGridView.alloc.init;
        [_card addSubview:self.topGridView];
        [self.topGridView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.categoryTitleLabel.mas_bottom).offset(10);
            make.height.mas_equalTo(200);
            make.leading.trailing.equalTo(_card).insets(UIEdgeInsetsMake(0, 10, 0, 10));
        }];
        
        StampDashView *dashView = [[StampDashView alloc] init];
        [_card addSubview:dashView];
        [dashView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.topGridView.mas_bottom).offset(10);
            make.height.mas_equalTo(5);
            make.leading.trailing.equalTo(_card);
        }];
        UIImageView *sepMid= [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"passport_header_sep"]];
        [_card addSubview:sepMid];
        self.bottomGridView = PassportStampSheetGridView.alloc.init;
        [_card addSubview:self.bottomGridView];
        [sepMid mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.topGridView.mas_bottom).offset(20);
            make.height.mas_equalTo(10);
            make.leading.trailing.equalTo(_card).insets(UIEdgeInsetsMake(0, 10, 0, 10));
        }];

        [self.bottomGridView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.topGridView.mas_bottom).offset(40);
            make.height.mas_equalTo(200);
            make.leading.trailing.equalTo(_card).insets(UIEdgeInsetsMake(0, 10, 0, 10));
            make.bottom.equalTo(@-10);
        }];

    }
    return self;
}

- (void)configureWithCategory:(PNStampCategorySection *)category {
    self.categoryTitleLabel.text = category.name ?: @"";
    self.categoryProgressLabel.text = [NSString stringWithFormat:@"%ld/%ld", (long)category.collectedCount, (long)category.totalCount];
    [self.topGridView configureWithItems:category.stamps ?: @[]];
    [self.bottomGridView configureWithItems:@[]];
}



@end

#pragma mark - View controller

@interface PassportSheetsViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) PassportViewModel *viewModel;
@property (nonatomic, assign) NSInteger year;
@property (nonatomic, strong) UIView *topBar;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *refreshButton;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong, nullable) PNStampCollection *stampCollection;
@property (nonatomic, copy) NSArray<PNStampCategorySection *> *stampCategories;
@end

@implementation PassportSheetsViewController

- (instancetype)initWithViewModel:(PassportViewModel *)viewModel year:(NSInteger)year {
    if (self = [super init]) {
        _viewModel = viewModel;
        _year = year;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hidesBottomBarWhenPushed = YES;
    self.shouldShowNavigationBar = NO;
    self.view.backgroundColor = PassportSheetsListBg();

    [self buildTopBar];
    [self buildTable];
    [self reloadStampRows];
    [self loadStampCollection];
}

- (void)buildTopBar {
    _topBar = [[UIView alloc] init];
    _topBar.backgroundColor = PassportSheetsNavBg();
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
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.backgroundColor = PassportSheetsListBg();
    _tableView.showsVerticalScrollIndicator = YES;
    _tableView.estimatedRowHeight = 280;
    _tableView.rowHeight = UITableViewAutomaticDimension;
    _tableView.contentInset = UIEdgeInsetsMake(0, 0, 24, 0);
    [self.view addSubview:_tableView];

    PassportHeader2Card *header = [PassportHeader2Card.alloc initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 516)];
    self.tableView.tableHeaderView = header;
    
    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_topBar.mas_bottom);
        make.leading.trailing.bottom.equalTo(self.view);
    }];

    [_tableView registerClass:[PassportStampSheetCardCell class] forCellReuseIdentifier:@"stamp"];
}

- (void)reloadStampRows {
    [self.tableView reloadData];
}

- (void)loadStampCollection {
    __weak typeof(self) weakSelf = self;
    [[StampRequest shared] getStampCollectionSuccess:^(HTTPResponse * _Nullable responseObject) {
        PNStampCollection *c = (PNStampCollection *)responseObject.dataObject;
        weakSelf.stampCollection = c;
        weakSelf.stampCategories = c.categories ?: @[];

        [weakSelf reloadStampRows];
    } failure:^(NSError * _Nonnull error) {
        // 页面不阻塞：保持空列表即可
        [QMUITips showError:error.localizedDescription];
    }];
}

- (void)loadPassportData {
    __weak typeof(self) weakSelf = self;
    [self showLoading];
    NSString *y = [NSString stringWithFormat:@"%ld", (long)self.year];
    [[ProfileRequest shared] getMyPassportWithYear:y success:^(HTTPResponse * _Nullable responseObject) {
        [weakSelf hideLoading];
        PNPassport *p = responseObject.dataObject;
        weakSelf.viewModel = [PassportViewModel viewModelWithPassport:p year:weakSelf.year];
        [weakSelf.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    } failure:^(NSError * _Nonnull error) {
        [weakSelf hideLoading];
        [weakSelf showError:error.localizedDescription ?: (NSLocalizedString(@"network_error", nil) ?: @"")];
    }];
}

- (void)onBack {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.stampCategories.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PassportStampSheetCardCell *c = [tableView dequeueReusableCellWithIdentifier:@"stamp" forIndexPath:indexPath];
    if (indexPath.row < self.stampCategories.count) {
        [c configureWithCategory:self.stampCategories[(NSUInteger)indexPath.row]];
    }
    return c;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 236*2;
}

- (void)updateLocalizedStrings {
    [super updateLocalizedStrings];
    _titleLabel.text = NSLocalizedString(@"passport_nav_title", nil) ?: @"我的护照";
}

@end
