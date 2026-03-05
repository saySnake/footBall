//
//  AddTeamsViewController.m
//  footBall
//

#import "AddTeamsViewController.h"
#import "ProfileTeamsStore.h"
#import <Masonry/Masonry.h>
#import "ColorManager.h"

#define kAddBg   [UIColor whiteColor]
#define kGreen   [ColorManager sharedManager].primaryColor

@interface AddTeamCell : UICollectionViewCell
@property (nonatomic, strong) UIView *circleBg;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIView *selectedRing;
@property (nonatomic, strong) UIView *checkBadge;
@property (nonatomic, strong) UIImageView *checkIcon;
- (void)configureWithTeam:(ProfileTeamItem *)team selected:(BOOL)selected;
@end

@implementation AddTeamCell
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.contentView.backgroundColor = [UIColor clearColor];
        _selectedRing = [UIView new];
        _selectedRing.layer.cornerRadius = 38;
        _selectedRing.layer.borderWidth = 2;
        _selectedRing.layer.borderColor = kGreen.CGColor;
        _selectedRing.hidden = YES;

        _circleBg = [UIView new];
        _circleBg.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
        _circleBg.layer.cornerRadius = 36;
        _circleBg.clipsToBounds = YES;

        _iconView = [UIImageView new];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;

        _nameLabel = [UILabel new];
        _nameLabel.font = [UIFont systemFontOfSize:12];
        _nameLabel.textColor = [UIColor darkGrayColor];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        _nameLabel.numberOfLines = 2;

        _checkBadge = [UIView new];
        _checkBadge.backgroundColor = kGreen;
        _checkBadge.layer.cornerRadius = 10;
        _checkBadge.hidden = YES;
        _checkBadge.clipsToBounds = YES;

        _checkIcon = [UIImageView new];
        if (@available(iOS 13.0, *)) {
            _checkIcon.image = [UIImage systemImageNamed:@"checkmark"];
            _checkIcon.tintColor = [UIColor whiteColor];
        }
        _checkIcon.contentMode = UIViewContentModeScaleAspectFit;
        [_checkBadge addSubview:_checkIcon];
        [_checkIcon mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(_checkBadge);
            make.size.mas_equalTo(CGSizeMake(12, 12));
        }];

        [self.contentView addSubview:_selectedRing];
        [self.contentView addSubview:_circleBg];
        [_circleBg addSubview:_iconView];
        [self.contentView addSubview:_nameLabel];
        [self.contentView addSubview:_checkBadge];

        [_selectedRing mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView).offset(2);
            make.centerX.equalTo(self.contentView);
            make.size.mas_equalTo(CGSizeMake(76, 76));
        }];
        [_circleBg mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(_selectedRing);
            make.size.mas_equalTo(CGSizeMake(72, 72));
        }];
        [_iconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(_circleBg);
            make.size.mas_equalTo(CGSizeMake(44, 44));
        }];
        [_checkBadge mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_selectedRing).offset(-4);
            make.trailing.equalTo(_selectedRing).offset(4);
            make.size.mas_equalTo(CGSizeMake(20, 20));
        }];
        [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_selectedRing.mas_bottom).offset(8);
            make.leading.trailing.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 2, 0, 2));
        }];
    }
    return self;
}

- (void)configureWithTeam:(ProfileTeamItem *)team selected:(BOOL)selected {
    self.nameLabel.text = NSLocalizedString(team.nameKey, nil);
    if (@available(iOS 13.0, *)) {
        self.iconView.image = [UIImage systemImageNamed:(team.iconName ?: @"circle.fill")];
        self.iconView.tintColor = team.tintColor ?: [UIColor grayColor];
    }
    self.selectedRing.hidden = !selected;
    self.checkBadge.hidden = !selected;
}
@end

@interface AddTeamsViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextFieldDelegate>
@property (nonatomic, strong) UILabel *navTitle;
@property (nonatomic, strong) UITextField *searchField;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIButton *cancelBtn;
@property (nonatomic, strong) UIButton *confirmBtn;

@property (nonatomic, strong) NSArray<ProfileTeamItem *> *allTeams;
@property (nonatomic, strong) NSArray<ProfileTeamItem *> *filteredTeams;
@property (nonatomic, strong) NSMutableSet<NSString *> *selectedIds;
@property (nonatomic, assign) BOOL isSearching;
@end

@implementation AddTeamsViewController

- (void)viewDidLoad {
    self.hidesBottomBarWhenPushed = YES;
    self.allTeams = [ProfileTeamsStore allTeams];
    self.filteredTeams = self.allTeams;
    self.selectedIds = [NSMutableSet setWithArray:(self.preselectedTeamIds ?: @[])];
    [super viewDidLoad];
    self.shouldShowNavigationBar = NO;
    self.view.backgroundColor = kAddBg;
}

- (void)setupUI {
    // Nav
    UIView *nav = [UIView new];
    nav.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:nav];
    [nav mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
        make.height.mas_equalTo(88);
    }];

    UIButton *back = [UIButton buttonWithType:UIButtonTypeSystem];
    if (@available(iOS 13.0, *)) [back setImage:[UIImage systemImageNamed:@"arrow.left"] forState:UIControlStateNormal];
    back.tintColor = [UIColor blackColor];
    [back addTarget:self action:@selector(onBack) forControlEvents:UIControlEventTouchUpInside];
    [nav addSubview:back];
    [back mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(nav).offset(12);
        make.bottom.equalTo(nav).offset(-10);
        make.size.mas_equalTo(CGSizeMake(36, 36));
    }];

    self.navTitle = [UILabel new];
    self.navTitle.font = [UIFont boldSystemFontOfSize:17];
    self.navTitle.textColor = [UIColor blackColor];
    [nav addSubview:self.navTitle];
    [self.navTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(nav);
        make.centerY.equalTo(back);
    }];

    // Search pill
    UIView *searchPill = [UIView new];
    searchPill.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
    searchPill.layer.cornerRadius = 18;
    [self.view addSubview:searchPill];
    [searchPill mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(nav.mas_bottom).offset(10);
        make.leading.equalTo(self.view).offset(12);
        make.trailing.equalTo(self.view).offset(-12);
        make.height.mas_equalTo(36);
    }];

    UIImageView *icon = [UIImageView new];
    if (@available(iOS 13.0, *)) { icon.image = [UIImage systemImageNamed:@"magnifyingglass"]; icon.tintColor = [UIColor grayColor]; }
    [searchPill addSubview:icon];
    [icon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(searchPill).offset(12);
        make.centerY.equalTo(searchPill);
        make.size.mas_equalTo(CGSizeMake(16, 16));
    }];

    self.searchField = [UITextField new];
    self.searchField.font = [UIFont systemFontOfSize:13];
    self.searchField.delegate = self;
    self.searchField.returnKeyType = UIReturnKeySearch;
    [self.searchField addTarget:self action:@selector(onSearchChanged) forControlEvents:UIControlEventEditingChanged];
    [searchPill addSubview:self.searchField];
    [self.searchField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(icon.mas_trailing).offset(8);
        make.trailing.equalTo(searchPill).offset(-12);
        make.centerY.equalTo(searchPill);
        make.height.mas_equalTo(30);
    }];

    // Bottom buttons
    UIView *bottom = [UIView new];
    bottom.backgroundColor = [UIColor clearColor];
    [self.view addSubview:bottom];
    [bottom mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-10);
        make.height.mas_equalTo(54);
    }];

    self.cancelBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    self.cancelBtn.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    self.cancelBtn.layer.cornerRadius = 22;
    self.cancelBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [self.cancelBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.cancelBtn addTarget:self action:@selector(onCancelTapped) forControlEvents:UIControlEventTouchUpInside];
    [bottom addSubview:self.cancelBtn];

    self.confirmBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    self.confirmBtn.backgroundColor = kGreen;
    self.confirmBtn.layer.cornerRadius = 22;
    self.confirmBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [self.confirmBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.confirmBtn addTarget:self action:@selector(onConfirmTapped) forControlEvents:UIControlEventTouchUpInside];
    [bottom addSubview:self.confirmBtn];

    [self.cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(bottom).offset(16);
        make.top.bottom.equalTo(bottom);
        make.trailing.equalTo(bottom.mas_centerX).offset(-8);
    }];
    [self.confirmBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(bottom).offset(-16);
        make.top.bottom.equalTo(bottom);
        make.leading.equalTo(bottom.mas_centerX).offset(8);
    }];

    // Collection
    UICollectionViewFlowLayout *fl = [UICollectionViewFlowLayout new];
    fl.sectionInset = UIEdgeInsetsMake(10, 12, 10, 12);
    fl.minimumInteritemSpacing = 0;
    fl.minimumLineSpacing = 16;

    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:fl];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.showsVerticalScrollIndicator = NO;
    [self.collectionView registerClass:[AddTeamCell class] forCellWithReuseIdentifier:@"AddTeamCell"];
    [self.view addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(searchPill.mas_bottom).offset(6);
        make.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(bottom.mas_top).offset(-6);
    }];
}

- (void)updateLocalizedStrings {
    [super updateLocalizedStrings];
    self.navTitle.text = NSLocalizedString(@"profile_add_team_title", nil);
    self.searchField.placeholder = NSLocalizedString(@"profile_team_search_placeholder", nil);
    [self.cancelBtn setTitle:NSLocalizedString(@"cancel", nil) forState:UIControlStateNormal];
    [self.confirmBtn setTitle:NSLocalizedString(@"confirm", nil) forState:UIControlStateNormal];
}

- (void)onBack { [self.navigationController popViewControllerAnimated:YES]; }
- (void)onCancelTapped { [self.navigationController popViewControllerAnimated:YES]; }

- (void)onConfirmTapped {
    NSArray *ids = [self selectedIdsInStableOrder];
    if (self.onConfirmBlock) self.onConfirmBlock(ids);
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSArray<NSString *> *)selectedIdsInStableOrder {
    // 保持输出顺序与 allTeams 一致，避免 set 的无序导致上层 UI 抖动
    NSMutableArray<NSString *> *arr = [NSMutableArray array];
    for (ProfileTeamItem *t in self.allTeams) {
        if (t.teamId.length > 0 && [self.selectedIds containsObject:t.teamId]) {
            [arr addObject:t.teamId];
        }
    }
    return arr;
}

- (void)onSearchChanged {
    NSString *kw = [self.searchField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (kw.length == 0) {
        self.isSearching = NO;
        self.filteredTeams = self.allTeams;
    } else {
        self.isSearching = YES;
        NSString *lower = kw.lowercaseString;
        NSMutableArray *arr = [NSMutableArray array];
        for (ProfileTeamItem *t in self.allTeams) {
            NSString *name = NSLocalizedString(t.nameKey, nil) ?: @"";
            if ([name.lowercaseString containsString:lower] || [t.teamId containsString:lower]) {
                [arr addObject:t];
            }
        }
        self.filteredTeams = arr;
    }
    [self.collectionView reloadData];
}

#pragma mark - UICollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.filteredTeams.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AddTeamCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AddTeamCell" forIndexPath:indexPath];
    ProfileTeamItem *t = self.filteredTeams[indexPath.item];
    BOOL sel = [self.selectedIds containsObject:t.teamId];
    [cell configureWithTeam:t selected:sel];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    // 原型：3 列大图标
    CGFloat w = collectionView.bounds.size.width;
    CGFloat inset = 12;
    CGFloat spacing = 0;
    CGFloat available = w - inset * 2 - spacing * 2;
    CGFloat itemW = floor(available / 3.0);
    return CGSizeMake(itemW, 120);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    ProfileTeamItem *t = self.filteredTeams[indexPath.item];
    if ([self.selectedIds containsObject:t.teamId]) {
        [self.selectedIds removeObject:t.teamId];
    } else {
        [self.selectedIds addObject:t.teamId];
    }
    [collectionView reloadItemsAtIndexPaths:@[indexPath]];
}

@end

