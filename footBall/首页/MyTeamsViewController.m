//
//  MyTeamsViewController.m
//  footBall
//

#import "MyTeamsViewController.h"
#import "AddTeamsViewController.h"
#import "AuthManager.h"
#import "TeamsRequest.h"
#import "Team.h"
#import <Masonry/Masonry.h>
#import <QuartzCore/QuartzCore.h>
#import <math.h>
#import "ColorManager.h"
#import <SDWebImage/SDWebImage.h>

/// Figma「我关注的球队」1:9089 页面背景 #f7f7f7
#define kMyTeamsPageBg     [UIColor colorWithRed:247/255.0 green:247/255.0 blue:247/255.0 alpha:1.0]
#define kMyTeamsSearchFill [UIColor colorWithRed:247/255.0 green:246/255.0 blue:246/255.0 alpha:1.0]
/// 搜索占位 #595959
#define kMyTeamsSearchPlaceholder [UIColor colorWithRed:89/255.0 green:89/255.0 blue:89/255.0 alpha:1.0]

static CGFloat const kMyTeamsTopGradientH = 208.f;
static CGFloat const kMyTeamsNavRowH = 44.f;
static CGFloat const kMyTeamsSearchH = 36.f;
static CGFloat const kMyTeamsSearchSideInset = 24.f;
static CGFloat const kMyTeamsCardSideInset = 16.f;
static CGFloat const kMyTeamsCardCorner = 6.f;
static CGFloat const kMyTeamsGridSideInset = 14.f;

#define kCardBg    [UIColor whiteColor]
#define kGreen     [ColorManager sharedManager].primaryColor

@interface MyTeamCell : UICollectionViewCell
@property (nonatomic, strong) UIView *circleBg;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIButton *removeBtn;
@property (nonatomic, copy) void (^onRemove)(void);
- (void)configureWithAPITeam:(Team * _Nullable)team isAdd:(BOOL)isAdd;
@end

@implementation MyTeamCell
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.contentView.backgroundColor = [UIColor clearColor];
        _circleBg = [UIView new];
        _circleBg.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
        _circleBg.layer.cornerRadius = 27;
        /// 删除角标叠在队徽上并略超出圆，需关闭裁剪
        _circleBg.clipsToBounds = NO;

        _iconView = [UIImageView new];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        _iconView.layer.cornerRadius = 17;
        _iconView.clipsToBounds = YES;

        _nameLabel = [UILabel new];
        _nameLabel.font = [UIFont systemFontOfSize:12];
        _nameLabel.textColor = [UIColor blackColor];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        _nameLabel.numberOfLines = 2;

        _removeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *rmImg = [UIImage imageNamed:@"set_delete"];
        if (!rmImg) rmImg = [UIImage imageNamed:@"team_removed"];
        if (rmImg) {
            _removeBtn.backgroundColor = [UIColor clearColor];
            [_removeBtn setImage:rmImg forState:UIControlStateNormal];
            _removeBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
        } else {
            _removeBtn.backgroundColor = [UIColor blackColor];
            _removeBtn.layer.cornerRadius = 7;
            _removeBtn.clipsToBounds = YES;
            if (@available(iOS 13.0, *)) {
                UIImageConfiguration *symCfg = [UIImageSymbolConfiguration configurationWithPointSize:8 weight:UIImageSymbolWeightBold];
                UIImage *img = [UIImage systemImageNamed:@"xmark" withConfiguration:symCfg];
                [_removeBtn setImage:[img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
                _removeBtn.tintColor = [UIColor whiteColor];
            }
        }
        [_removeBtn addTarget:self action:@selector(onRemoveTapped) forControlEvents:UIControlEventTouchUpInside];

        [self.contentView addSubview:_circleBg];
        [_circleBg addSubview:_iconView];
        [_circleBg addSubview:_removeBtn];
        [self.contentView addSubview:_nameLabel];

        [_circleBg mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView).offset(4);
            make.centerX.equalTo(self.contentView);
            make.size.mas_equalTo(CGSizeMake(54, 54));
        }];
        [_iconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(_circleBg);
            make.size.mas_equalTo(CGSizeMake(34, 34));
        }];
        /// 角标中心落在灰色圆边缘（右上 45°）：相对圆周「一半在内一半在外」
        {
            CGFloat r = 27.0; // 54pt 直径圆的半径
            CGFloat d = (CGFloat)(r / sqrt(2.0));
            [_removeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
                make.centerX.equalTo(_circleBg.mas_centerX).offset(d);
                make.centerY.equalTo(_circleBg.mas_centerY).offset(-d);
                make.size.mas_equalTo(CGSizeMake(18, 18));
            }];
        }
        [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_circleBg.mas_bottom).offset(4);
            make.leading.trailing.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 2, 0, 2));
        }];
    }
    return self;
}

- (void)onRemoveTapped {
    if (self.onRemove) self.onRemove();
}

- (void)configureWithAPITeam:(Team *)team isAdd:(BOOL)isAdd {
    if (isAdd) {
        self.nameLabel.text = NSLocalizedString(@"profile_add_team", nil);
        self.removeBtn.hidden = YES;
        self.circleBg.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
        [self.iconView sd_cancelCurrentImageLoad];
        if (@available(iOS 13.0, *)) {
            self.iconView.image = [UIImage systemImageNamed:@"plus"];
            self.iconView.tintColor = [UIColor colorWithWhite:0.55 alpha:1.0];
        }
        return;
    }
    self.removeBtn.hidden = NO;
    self.circleBg.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
    self.nameLabel.text = team.name.length > 0 ? team.name : @"-";
    self.iconView.tintColor = nil;
    NSURL *url = team.logo.length > 0 ? [NSURL URLWithString:team.logo] : nil;
    UIImage *placeholder = nil;
    if (@available(iOS 13.0, *)) {
        placeholder = [UIImage systemImageNamed:@"sportscourt.fill"];
    }
    __weak typeof(self) weakSelf = self;
    [self.iconView sd_setImageWithURL:url placeholderImage:placeholder completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        weakSelf.iconView.contentMode = UIViewContentModeScaleAspectFit;
        if (!image || error) {
            if (@available(iOS 13.0, *)) {
                weakSelf.iconView.tintColor = [UIColor grayColor];
            }
        } else {
            weakSelf.iconView.tintColor = nil;
        }
    }];
}
@end

@interface MyTeamsViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextFieldDelegate>
@property (nonatomic, strong) UIView *gradientHostView;
@property (nonatomic, strong) CAGradientLayer *topGradientLayer;
@property (nonatomic, strong) UILabel *navTitle;
@property (nonatomic, strong) UITextField *searchField;
@property (nonatomic, strong) UIView *card;
@property (nonatomic, strong) UILabel *cardTitle;
@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, strong) NSArray<Team *> *followedTeams;
@property (nonatomic, strong) NSArray<Team *> *filteredTeams;
@property (nonatomic, assign) BOOL isSearching;
@end

@implementation MyTeamsViewController

- (void)viewDidLoad {
    self.hidesBottomBarWhenPushed = YES;
    [super viewDidLoad];
    self.shouldShowNavigationBar = NO;
    self.view.backgroundColor = kMyTeamsPageBg;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.topGradientLayer && self.gradientHostView) {
        self.topGradientLayer.frame = self.gradientHostView.bounds;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadFollowedTeamsFromAPI];
}

/// GET /api/v1/teams/my-follows
- (void)reloadFollowedTeamsFromAPI {
    if (!AuthManager.sharedManager.isLoggedIn) {
        self.followedTeams = @[];
        self.filteredTeams = @[];
        self.isSearching = NO;
        [self.collectionView reloadData];
        return;
    }
    __weak typeof(self) weakSelf = self;
    [[TeamsRequest shared] getFollowTeamsSuccess:^(HTTPResponse * _Nullable responseObject) {
        NSArray *teams = [responseObject.dataObject isKindOfClass:NSArray.class] ? responseObject.dataObject : @[];
        weakSelf.followedTeams = teams ?: @[];
        [weakSelf updateFilteredTeamsFromSearchField];
        [weakSelf.collectionView reloadData];
    } failure:^(NSError * _Nonnull error) {
        weakSelf.followedTeams = @[];
        weakSelf.filteredTeams = @[];
        [weakSelf.collectionView reloadData];
    }];
}

- (void)updateFilteredTeamsFromSearchField {
    NSString *kw = [self.searchField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (kw.length == 0) {
        self.isSearching = NO;
        self.filteredTeams = self.followedTeams;
        return;
    }
    self.isSearching = YES;
    NSString *lower = kw.lowercaseString;
    NSMutableArray *arr = [NSMutableArray array];
    for (Team *t in self.followedTeams) {
        NSString *n1 = t.name.length ? t.name.lowercaseString : @"";
        NSString *n2 = t.nameEn.length ? t.nameEn.lowercaseString : @"";
        NSString *tid = t.teamId.length ? t.teamId.lowercaseString : @"";
        if ([n1 containsString:lower] || [n2 containsString:lower] || [tid containsString:lower]) {
            [arr addObject:t];
        }
    }
    self.filteredTeams = arr;
}

- (void)setupUI {
    ColorManager *cm = [ColorManager sharedManager];

    self.gradientHostView = [UIView new];
    self.gradientHostView.backgroundColor = [UIColor clearColor];
    self.gradientHostView.userInteractionEnabled = NO;
    [self.view addSubview:self.gradientHostView];
    [self.gradientHostView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
        make.height.mas_equalTo(kMyTeamsTopGradientH);
    }];
    self.topGradientLayer = [CAGradientLayer layer];
    self.topGradientLayer.colors = @[(id)[UIColor whiteColor].CGColor, (id)kMyTeamsPageBg.CGColor];
    self.topGradientLayer.startPoint = CGPointMake(0.5, 0);
    self.topGradientLayer.endPoint = CGPointMake(0.5, 1);
    [self.gradientHostView.layer addSublayer:self.topGradientLayer];

    UIView *nav = [UIView new];
    nav.backgroundColor = [UIColor clearColor];
    [self.view addSubview:nav];

    UIView *navRow = [UIView new];
    navRow.backgroundColor = [UIColor clearColor];
    [nav addSubview:navRow];
    [navRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.bottom.equalTo(nav);
        make.top.equalTo(nav.mas_safeAreaLayoutGuideTop);
        make.height.mas_equalTo(kMyTeamsNavRowH);
    }];
    [nav mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(navRow);
    }];

    UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *backImg = [UIImage imageNamed:@"nav_back"];
    if (!backImg) {
        backImg = [UIImage imageNamed:@"ad_left"];
    }
    if (!backImg && @available(iOS 13.0, *)) {
        backImg = [UIImage systemImageNamed:@"arrow.left"];
    }
    if (backImg) {
        [back setImage:[backImg imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        back.tintColor = cm.textColor;
    }
    back.imageView.contentMode = UIViewContentModeScaleAspectFit;
    back.adjustsImageWhenHighlighted = NO;
    [back addTarget:self action:@selector(onBack) forControlEvents:UIControlEventTouchUpInside];
    [navRow addSubview:back];
    [back mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(navRow).offset(16);
        make.centerY.equalTo(navRow);
        make.size.mas_equalTo(CGSizeMake(44, 44));
    }];

    self.navTitle = [UILabel new];
    self.navTitle.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    self.navTitle.textColor = cm.textColor;
    [navRow addSubview:self.navTitle];
    [self.navTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(navRow);
    }];

    UIView *searchPill = [UIView new];
    searchPill.backgroundColor = kMyTeamsSearchFill;
    searchPill.layer.cornerRadius = kMyTeamsSearchH / 2.0;
    searchPill.clipsToBounds = YES;
    [self.view addSubview:searchPill];
    [searchPill mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(nav.mas_bottom).offset(10);
        make.leading.equalTo(self.view).offset(kMyTeamsSearchSideInset);
        make.trailing.equalTo(self.view).offset(-kMyTeamsSearchSideInset);
        make.height.mas_equalTo(kMyTeamsSearchH);
    }];

    UIImageView *icon = [UIImageView new];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    if (@available(iOS 13.0, *)) {
        icon.image = [UIImage systemImageNamed:@"magnifyingglass"];
        icon.tintColor = kMyTeamsSearchPlaceholder;
    }
    [searchPill addSubview:icon];
    [icon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(searchPill).offset(8);
        make.centerY.equalTo(searchPill);
        make.size.mas_equalTo(CGSizeMake(24, 24));
    }];

    self.searchField = [UITextField new];
    self.searchField.font = [UIFont systemFontOfSize:12];
    self.searchField.textColor = cm.textColor;
    self.searchField.delegate = self;
    self.searchField.returnKeyType = UIReturnKeySearch;
    [self.searchField addTarget:self action:@selector(onSearchChanged) forControlEvents:UIControlEventEditingChanged];
    [searchPill addSubview:self.searchField];
    [self.searchField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(icon.mas_trailing).offset(6);
        make.trailing.equalTo(searchPill).offset(-12);
        make.centerY.equalTo(searchPill);
        make.height.mas_equalTo(32);
    }];

    self.card = [UIView new];
    self.card.backgroundColor = kCardBg;
    self.card.layer.cornerRadius = kMyTeamsCardCorner;
    self.card.clipsToBounds = YES;
    [self.view addSubview:self.card];
    [self.card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(searchPill.mas_bottom).offset(12);
        make.leading.equalTo(self.view).offset(kMyTeamsCardSideInset);
        make.trailing.equalTo(self.view).offset(-kMyTeamsCardSideInset);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-12);
    }];

    self.cardTitle = [UILabel new];
    self.cardTitle.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    self.cardTitle.textColor = cm.textColor;
    [self.card addSubview:self.cardTitle];
    [self.cardTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.card).offset(16);
        make.leading.equalTo(self.card).offset(15);
    }];

    UICollectionViewFlowLayout *fl = [UICollectionViewFlowLayout new];
    fl.minimumInteritemSpacing = 0;
    fl.minimumLineSpacing = 0;
    fl.sectionInset = UIEdgeInsetsMake(8, kMyTeamsGridSideInset, 16, kMyTeamsGridSideInset);

    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:fl];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.showsVerticalScrollIndicator = NO;
    [self.collectionView registerClass:[MyTeamCell class] forCellWithReuseIdentifier:@"MyTeamCell"];
    [self.card addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.cardTitle.mas_bottom).offset(8);
        make.leading.trailing.bottom.equalTo(self.card);
    }];
}

- (void)updateLocalizedStrings {
    [super updateLocalizedStrings];
    self.navTitle.text = NSLocalizedString(@"profile_my_teams", nil);
    self.cardTitle.text = NSLocalizedString(@"profile_my_teams", nil);
    [self applySearchFieldPlaceholderStyle];
}

- (void)applySearchFieldPlaceholderStyle {
    NSString *ph = NSLocalizedString(@"profile_team_search_placeholder", nil);
    if (ph.length == 0) return;
    self.searchField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:ph attributes:@{
        NSFontAttributeName: [UIFont systemFontOfSize:12],
        NSForegroundColorAttributeName: kMyTeamsSearchPlaceholder,
    }];
}

- (void)onBack { [self.navigationController popViewControllerAnimated:YES]; }

- (void)onSearchChanged {
    [self updateFilteredTeamsFromSearchField];
    [self.collectionView reloadData];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - UICollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    // 搜索时不显示“添加”入口
    return self.isSearching ? self.filteredTeams.count : (self.filteredTeams.count + 1);
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MyTeamCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MyTeamCell" forIndexPath:indexPath];
    NSInteger count = self.filteredTeams.count;
    BOOL isAdd = (!self.isSearching && indexPath.item == count);
    Team *t = isAdd ? nil : self.filteredTeams[indexPath.item];
    __weak typeof(self) weakSelf = self;
    cell.onRemove = ^{
        if (!t || t.teamId.length == 0) return;
        [[TeamsRequest shared] cancelFollowTeam:t.teamId success:^(HTTPResponse * _Nullable responseObject) {
            [weakSelf reloadFollowedTeamsFromAPI];
        } failure:^(NSError * _Nonnull error) {
            [weakSelf reloadFollowedTeamsFromAPI];
        }];
    };
    if (isAdd) {
        [cell configureWithAPITeam:nil isAdd:YES];
    } else {
        [cell configureWithAPITeam:t isAdd:NO];
    }
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    // 原型：4 列
    CGFloat w = collectionView.bounds.size.width;
    NSInteger col = 4;
    CGFloat itemW = floor(w / col);
    /// Figma 行高约 89pt（54 图标 + 文案区）
    return CGSizeMake(itemW, 89);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isSearching) return;
    NSInteger count = self.filteredTeams.count;
    if (indexPath.item == count) {
        AddTeamsViewController *vc = [AddTeamsViewController new];
        vc.hidesBottomBarWhenPushed = YES;
        NSMutableArray *pre = [NSMutableArray array];
        for (Team *tm in self.followedTeams) {
            if (tm.teamId.length > 0) [pre addObject:tm.teamId];
        }
        vc.preselectedTeamIds = [pre copy];
        __weak typeof(self) weakSelf = self;
        vc.onConfirmBlock = ^(NSArray<NSString *> *teamIds) {
            if (teamIds.count == 0) {
                [weakSelf reloadFollowedTeamsFromAPI];
                return;
            }
            [[TeamsRequest shared] followTeams:teamIds success:^(HTTPResponse * _Nullable responseObject) {
                [weakSelf reloadFollowedTeamsFromAPI];
            } failure:^(NSError * _Nonnull error) {
                [weakSelf reloadFollowedTeamsFromAPI];
            }];
        };
        [self.navigationController pushViewController:vc animated:YES];
    }
}

@end

