//
//  AddTeamsViewController.m
//  footBall
//

#import "AddTeamsViewController.h"
#import "TeamsRequest.h"
#import "Team.h"
#import <Masonry/Masonry.h>
#import <math.h>
#import "ColorManager.h"
#import "LoadingManager.h"
#import <SDWebImage/SDWebImage.h>

/// Figma「添加球队 / 选球队」1:9176
static CGFloat const kAddTeamsPadding = 16.f;
static CGFloat const kAddTeamsSearchH = 36.f;
static CGFloat const kAddTeamsSearchSideInset = 24.f;
static CGFloat const kAddTeamsNavRowH = 44.f;
static CGFloat const kAddTeamsBottomBtnH = 54.f;
/// 外圈白底圆直径、队标、右上角选中角标（与稿一致）
static CGFloat const kAddTeamOuterD = 90.f;
static CGFloat const kAddTeamLogoD = 50.f;
static CGFloat const kAddTeamCheckBadgeD = 24.f;

#define kGreen   [ColorManager sharedManager].primaryColor

@interface AddTeamCell : UICollectionViewCell
@property (nonatomic, strong) UIView *outerCircle;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIImageView *checkBadge;
- (void)configureWithAPITeam:(Team *)team selected:(BOOL)selected;
@end

@implementation AddTeamCell
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.contentView.backgroundColor = [UIColor clearColor];

        _outerCircle = [UIView new];
        _outerCircle.backgroundColor = [UIColor whiteColor];
        _outerCircle.layer.cornerRadius = kAddTeamOuterD / 2.f;
        _outerCircle.clipsToBounds = NO;
        _outerCircle.layer.borderWidth = 0;
        _outerCircle.layer.borderColor = kGreen.CGColor;
        _outerCircle.layer.shadowColor = [UIColor blackColor].CGColor;
        _outerCircle.layer.shadowOpacity = 0.06f;
        _outerCircle.layer.shadowOffset = CGSizeMake(0, 9);
        _outerCircle.layer.shadowRadius = 16;

        _iconView = [UIImageView new];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        _iconView.layer.cornerRadius = kAddTeamLogoD / 2.f;
        _iconView.clipsToBounds = YES;
        _iconView.backgroundColor = [UIColor clearColor];

        _nameLabel = [UILabel new];
        _nameLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
        _nameLabel.textColor = [UIColor colorWithRed:0.208 green:0.200 blue:0.208 alpha:1.0];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        _nameLabel.numberOfLines = 2;

        _checkBadge = [UIImageView new];
        _checkBadge.contentMode = UIViewContentModeScaleAspectFit;
        UIImage *yesImg = [UIImage imageNamed:@"set_yes"];
        if (yesImg) {
            _checkBadge.image = yesImg;
        } else if (@available(iOS 13.0, *)) {
            UIImage *sf = [UIImage systemImageNamed:@"checkmark.circle.fill"];
            _checkBadge.image = [sf imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            _checkBadge.tintColor = kGreen;
        }
        _checkBadge.hidden = YES;

        [self.contentView addSubview:_outerCircle];
        [_outerCircle addSubview:_iconView];
        [_outerCircle addSubview:_checkBadge];
        [self.contentView addSubview:_nameLabel];

        [_outerCircle mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView);
            make.centerX.equalTo(self.contentView);
            make.size.mas_equalTo(CGSizeMake(kAddTeamOuterD, kAddTeamOuterD));
        }];
        [_iconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(_outerCircle);
            make.size.mas_equalTo(CGSizeMake(kAddTeamLogoD, kAddTeamLogoD));
        }];
        /// 选中角标中心落在外圈圆周（右上 45°），一半在圆内一半在圆外
        {
            CGFloat r = kAddTeamOuterD / 2.f;
            CGFloat d = (CGFloat)(r / sqrt(2.0));
            [_checkBadge mas_makeConstraints:^(MASConstraintMaker *make) {
                make.centerX.equalTo(_outerCircle.mas_centerX).offset(d);
                make.centerY.equalTo(_outerCircle.mas_centerY).offset(-d);
                make.size.mas_equalTo(CGSizeMake(kAddTeamCheckBadgeD, kAddTeamCheckBadgeD));
            }];
        }
        [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_outerCircle.mas_bottom).offset(8);
            make.leading.trailing.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 2, 0, 2));
        }];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.outerCircle.bounds.size.width > 0) {
        UIBezierPath *p = [UIBezierPath bezierPathWithRoundedRect:self.outerCircle.bounds cornerRadius:kAddTeamOuterD / 2.f];
        self.outerCircle.layer.shadowPath = p.CGPath;
    }
}

- (void)configureWithAPITeam:(Team *)team selected:(BOOL)selected {
    NSString *title = @"";
    if (team.name.length > 0) title = team.name;
    else if (team.nameEn.length > 0) title = team.nameEn;
    else title = @"-";
    self.nameLabel.text = title;

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

    self.outerCircle.layer.borderWidth = selected ? 2.0 : 0.0;
    self.checkBadge.hidden = !selected;
}
@end

@interface AddTeamsViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextFieldDelegate>
@property (nonatomic, strong) UILabel *navTitle;
@property (nonatomic, strong) UITextField *searchField;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIButton *confirmBtn;

@property (nonatomic, strong) NSArray<Team *> *allTeams;
@property (nonatomic, strong) NSMutableSet<NSString *> *selectedIds;
@property (nonatomic, assign) NSInteger searchDebounceToken;
@end

@implementation AddTeamsViewController

- (void)viewDidLoad {
    self.hidesBottomBarWhenPushed = YES;
    self.selectedIds = [NSMutableSet setWithArray:(self.preselectedTeamIds ?: @[])];
    self.allTeams = @[];
    [super viewDidLoad];
    self.shouldShowNavigationBar = NO;
    self.view.backgroundColor = [UIColor whiteColor];
    [self fetchTeamsForKeyword:@""];
}

/// GET /api/v1/teams/search
- (void)fetchTeamsForKeyword:(NSString *)keyword {
    __weak typeof(self) weakSelf = self;
    NSString *kw = keyword ?: @"";
    [[TeamsRequest shared] searchTeams:kw leagueId:nil page:1 pageSize:100 success:^(HTTPResponse * _Nullable responseObject) {
        NSArray *teams = [responseObject.dataObject isKindOfClass:NSArray.class] ? responseObject.dataObject : @[];
        weakSelf.allTeams = teams ?: @[];
        [weakSelf.collectionView reloadData];
    } failure:^(NSError * _Nonnull error) {
        weakSelf.allTeams = @[];
        [weakSelf.collectionView reloadData];
    }];
}

- (void)setupUI {
    ColorManager *cm = [ColorManager sharedManager];

    UIView *nav = [UIView new];
    nav.backgroundColor = [UIColor clearColor];
    [self.view addSubview:nav];

    UIView *navRow = [UIView new];
    navRow.backgroundColor = [UIColor clearColor];
    [nav addSubview:navRow];
    [navRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.bottom.equalTo(nav);
        make.top.equalTo(nav.mas_safeAreaLayoutGuideTop);
        make.height.mas_equalTo(kAddTeamsNavRowH);
    }];
    [nav mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(navRow);
    }];

    UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
    /// 固定 nav_back，Original 不随主题染色
    UIImage *backImg = [UIImage imageNamed:@"nav_back"];
    if (backImg) {
        [back setImage:[backImg imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
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
    self.navTitle.textColor = [UIColor blackColor];
    [navRow addSubview:self.navTitle];
    [self.navTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(navRow);
        make.centerY.equalTo(navRow);
    }];

    UIView *searchPill = [UIView new];
    searchPill.backgroundColor = [UIColor colorWithRed:247/255.0 green:246/255.0 blue:246/255.0 alpha:1.0];
    searchPill.layer.cornerRadius = kAddTeamsSearchH / 2.f;
    searchPill.clipsToBounds = YES;
    [self.view addSubview:searchPill];
    [searchPill mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(nav.mas_bottom).offset(10);
        make.leading.equalTo(self.view).offset(kAddTeamsSearchSideInset);
        make.trailing.equalTo(self.view).offset(-kAddTeamsSearchSideInset);
        make.height.mas_equalTo(kAddTeamsSearchH);
    }];

    UIImageView *icon = [UIImageView new];
    if (@available(iOS 13.0, *)) {
        icon.image = [UIImage systemImageNamed:@"magnifyingglass"];
        icon.tintColor = [UIColor colorWithRed:89/255.0 green:89/255.0 blue:89/255.0 alpha:1.0];
    }
    icon.contentMode = UIViewContentModeScaleAspectFit;
    [searchPill addSubview:icon];
    [icon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(searchPill).offset(8);
        make.centerY.equalTo(searchPill);
        make.size.mas_equalTo(CGSizeMake(24, 24));
    }];

    self.searchField = [UITextField new];
    self.searchField.font = [UIFont systemFontOfSize:12];
    self.searchField.delegate = self;
    self.searchField.returnKeyType = UIReturnKeySearch;
    self.searchField.textColor = cm.textColor;
    [self.searchField addTarget:self action:@selector(onSearchChanged) forControlEvents:UIControlEventEditingChanged];
    [searchPill addSubview:self.searchField];
    [self.searchField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(icon.mas_trailing).offset(6);
        make.trailing.equalTo(searchPill).offset(-12);
        make.centerY.equalTo(searchPill);
        make.height.mas_equalTo(32);
    }];
    [self applySearchFieldPlaceholderStyle];

    CGFloat bottomCorner = kAddTeamsBottomBtnH / 2.f;
    UIView *bottom = [UIView new];
    bottom.backgroundColor = [UIColor clearColor];
    [self.view addSubview:bottom];
    [bottom mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-16);
        make.height.mas_equalTo(kAddTeamsBottomBtnH);
    }];

    self.confirmBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.confirmBtn.backgroundColor = kGreen;
    self.confirmBtn.layer.cornerRadius = bottomCorner;
    self.confirmBtn.clipsToBounds = YES;
    self.confirmBtn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [self.confirmBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.confirmBtn addTarget:self action:@selector(onConfirmTapped) forControlEvents:UIControlEventTouchUpInside];
    [bottom addSubview:self.confirmBtn];

    [self.confirmBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(bottom).offset(kAddTeamsPadding);
        make.trailing.equalTo(bottom).offset(-kAddTeamsPadding);
        make.top.bottom.equalTo(bottom);
    }];

    UICollectionViewFlowLayout *fl = [UICollectionViewFlowLayout new];
    fl.sectionInset = UIEdgeInsetsMake(12, kAddTeamsPadding, 24, kAddTeamsPadding);
    fl.minimumInteritemSpacing = 0;
    fl.minimumLineSpacing = 16;

    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:fl];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.showsVerticalScrollIndicator = NO;
    if (@available(iOS 11.0, *)) {
        self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [self.collectionView registerClass:[AddTeamCell class] forCellWithReuseIdentifier:@"AddTeamCell"];
    [self.view addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(searchPill.mas_bottom).offset(8);
        make.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(bottom.mas_top).offset(-8);
    }];
}

- (void)applySearchFieldPlaceholderStyle {
    if (!self.searchField) return;
    ColorManager *cm = [ColorManager sharedManager];
    NSString *ph = NSLocalizedString(@"profile_team_search_placeholder", nil);
    UIFont *font = self.searchField.font ?: [UIFont systemFontOfSize:12];
    UIColor *phColor = [UIColor colorWithRed:89/255.0 green:89/255.0 blue:89/255.0 alpha:1.0];
    self.searchField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:ph attributes:@{
        NSForegroundColorAttributeName: phColor,
        NSFontAttributeName: font
    }];
    self.searchField.typingAttributes = @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: cm.textColor
    };
}

- (void)updateLocalizedStrings {
    [super updateLocalizedStrings];
    self.navTitle.text = NSLocalizedString(@"profile_add_team_title", nil);
    self.navTitle.textColor = [UIColor blackColor];
    [self applySearchFieldPlaceholderStyle];
    [self.confirmBtn setTitle:NSLocalizedString(@"confirm", nil) forState:UIControlStateNormal];
}

- (void)onBack { [self.navigationController popViewControllerAnimated:YES]; }

- (void)onConfirmTapped {
    NSArray *ids = [self selectedIdsInStableOrder];
    if (ids.count == 0) {
        // 需求：不允许“跳过”，必须选择至少一个喜欢的球队
        NSString *msg = NSLocalizedString(@"team_select_required", nil);
        if (msg.length == 0 || [msg hasPrefix:@"team_"]) msg = @"请至少选择一个喜欢的球队";
        [[LoadingManager sharedManager] showError:msg inView:self.view];
        return;
    }
    if (self.onConfirmBlock) self.onConfirmBlock(ids);
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSArray<NSString *> *)selectedIdsInStableOrder {
    NSMutableArray<NSString *> *arr = [NSMutableArray array];
    NSMutableSet<NSString *> *seen = [NSMutableSet set];
    for (Team *t in self.allTeams) {
        if (t.teamId.length > 0 && [self.selectedIds containsObject:t.teamId]) {
            [arr addObject:t.teamId];
            [seen addObject:t.teamId];
        }
    }
    for (NSString *sid in self.selectedIds) {
        if (sid.length > 0 && ![seen containsObject:sid]) {
            [arr addObject:sid];
            [seen addObject:sid];
        }
    }
    return arr;
}

- (void)onSearchChanged {
    NSString *kw = [self.searchField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    self.searchDebounceToken += 1;
    NSInteger token = self.searchDebounceToken;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (token != self.searchDebounceToken) return;
        [self fetchTeamsForKeyword:kw];
    });
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    NSString *kw = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    self.searchDebounceToken += 1;
    [self fetchTeamsForKeyword:kw];
    return YES;
}

#pragma mark - UICollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.allTeams.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AddTeamCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AddTeamCell" forIndexPath:indexPath];
    Team *t = self.allTeams[indexPath.item];
    BOOL sel = [self.selectedIds containsObject:t.teamId];
    [cell configureWithAPITeam:t selected:sel];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat w = collectionView.bounds.size.width;
    CGFloat inset = kAddTeamsPadding;
    CGFloat available = w - inset * 2;
    CGFloat itemW = floor(available / 3.0);
    return CGSizeMake(itemW, 140);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    Team *t = self.allTeams[indexPath.item];
    NSString *tid = t.teamId ?: @"";
    if (tid.length == 0) return;
    if ([self.selectedIds containsObject:tid]) {
        [self.selectedIds removeObject:tid];
    } else {
        [self.selectedIds addObject:tid];
    }
    [collectionView reloadItemsAtIndexPaths:@[indexPath]];
}

@end
