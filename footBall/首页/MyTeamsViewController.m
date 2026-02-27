//
//  MyTeamsViewController.m
//  footBall
//

#import "MyTeamsViewController.h"
#import "AddTeamsViewController.h"
#import "ProfileTeamsStore.h"
#import <Masonry/Masonry.h>

#define kTeamsBg   [UIColor colorWithWhite:0.95 alpha:1.0]
#define kCardBg    [UIColor whiteColor]
#define kGreen     [UIColor colorWithRed:0.10 green:0.36 blue:0.28 alpha:1.0]

@interface MyTeamCell : UICollectionViewCell
@property (nonatomic, strong) UIView *circleBg;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIButton *removeBtn;
@property (nonatomic, copy) void (^onRemove)(void);
- (void)configureWithTeam:(ProfileTeamItem * _Nullable)team isAdd:(BOOL)isAdd;
@end

@implementation MyTeamCell
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.contentView.backgroundColor = [UIColor clearColor];
        _circleBg = [UIView new];
        _circleBg.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
        _circleBg.layer.cornerRadius = 30;
        _circleBg.clipsToBounds = YES;

        _iconView = [UIImageView new];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;

        _nameLabel = [UILabel new];
        _nameLabel.font = [UIFont systemFontOfSize:11];
        _nameLabel.textColor = [UIColor darkGrayColor];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        _nameLabel.numberOfLines = 2;

        _removeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _removeBtn.backgroundColor = [UIColor blackColor];
        _removeBtn.layer.cornerRadius = 10;
        _removeBtn.clipsToBounds = YES;
        if (@available(iOS 13.0, *)) {
            UIImage *img = [[UIImage systemImageNamed:@"xmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [_removeBtn setImage:img forState:UIControlStateNormal];
            _removeBtn.tintColor = [UIColor whiteColor];
        }
        [_removeBtn addTarget:self action:@selector(onRemoveTapped) forControlEvents:UIControlEventTouchUpInside];

        [self.contentView addSubview:_circleBg];
        [_circleBg addSubview:_iconView];
        [self.contentView addSubview:_nameLabel];
        [self.contentView addSubview:_removeBtn];

        [_circleBg mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView).offset(6);
            make.centerX.equalTo(self.contentView);
            make.size.mas_equalTo(CGSizeMake(60, 60));
        }];
        [_iconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(_circleBg);
            make.size.mas_equalTo(CGSizeMake(36, 36));
        }];
        [_removeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_circleBg).offset(-6);
            make.trailing.equalTo(_circleBg).offset(6);
            make.size.mas_equalTo(CGSizeMake(20, 20));
        }];
        [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_circleBg.mas_bottom).offset(5);
            make.leading.trailing.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 2, 0, 2));
        }];
    }
    return self;
}

- (void)onRemoveTapped {
    if (self.onRemove) self.onRemove();
}

- (void)configureWithTeam:(ProfileTeamItem * _Nullable)team isAdd:(BOOL)isAdd {
    if (isAdd) {
        self.nameLabel.text = NSLocalizedString(@"profile_add_team", nil);
        self.removeBtn.hidden = YES;
        self.circleBg.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
        if (@available(iOS 13.0, *)) {
            self.iconView.image = [UIImage systemImageNamed:@"plus"];
            self.iconView.tintColor = [UIColor colorWithWhite:0.55 alpha:1.0];
        }
        return;
    }
    self.removeBtn.hidden = NO;
    self.circleBg.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
    self.nameLabel.text = team ? NSLocalizedString(team.nameKey, nil) : @"";
    if (@available(iOS 13.0, *)) {
        self.iconView.image = [UIImage systemImageNamed:(team.iconName ?: @"circle.fill")];
        self.iconView.tintColor = team.tintColor ?: [UIColor grayColor];
    }
}
@end

@interface MyTeamsViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextFieldDelegate>
@property (nonatomic, strong) UILabel *navTitle;
@property (nonatomic, strong) UITextField *searchField;
@property (nonatomic, strong) UIView *card;
@property (nonatomic, strong) UILabel *cardTitle;
@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, strong) NSArray<ProfileTeamItem *> *followedTeams;
@property (nonatomic, strong) NSArray<ProfileTeamItem *> *filteredTeams;
@property (nonatomic, assign) BOOL isSearching;
@end

@implementation MyTeamsViewController

- (void)viewDidLoad {
    self.hidesBottomBarWhenPushed = YES;
    [super viewDidLoad];
    self.shouldShowNavigationBar = NO;
    self.view.backgroundColor = kTeamsBg;
    [self reloadData];
}

- (void)reloadData {
    NSArray *ids = [ProfileTeamsStore loadFollowedTeamIds];
    self.followedTeams = [ProfileTeamsStore teamsForIds:ids];
    self.filteredTeams = self.followedTeams;
    self.isSearching = NO;
    [self.collectionView reloadData];
}

- (void)setupUI {
    // Nav bar
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

    // Card
    self.card = [UIView new];
    self.card.backgroundColor = kCardBg;
    self.card.layer.cornerRadius = 12;
    self.card.clipsToBounds = YES;
    [self.view addSubview:self.card];
    [self.card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(searchPill.mas_bottom).offset(12);
        make.leading.equalTo(self.view).offset(12);
        make.trailing.equalTo(self.view).offset(-12);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-12);
    }];

    self.cardTitle = [UILabel new];
    self.cardTitle.font = [UIFont boldSystemFontOfSize:15];
    self.cardTitle.textColor = [UIColor blackColor];
    [self.card addSubview:self.cardTitle];
    [self.cardTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.card).offset(14);
        make.leading.equalTo(self.card).offset(14);
    }];

    UICollectionViewFlowLayout *fl = [UICollectionViewFlowLayout new];
    fl.minimumInteritemSpacing = 0;
    fl.minimumLineSpacing = 0;
    fl.sectionInset = UIEdgeInsetsMake(10, 6, 12, 6);

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
    self.searchField.placeholder = NSLocalizedString(@"profile_team_search_placeholder", nil);
}

- (void)onBack { [self.navigationController popViewControllerAnimated:YES]; }

- (void)onSearchChanged {
    NSString *kw = [self.searchField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (kw.length == 0) {
        self.isSearching = NO;
        self.filteredTeams = self.followedTeams;
    } else {
        self.isSearching = YES;
        NSString *lower = kw.lowercaseString;
        NSMutableArray *arr = [NSMutableArray array];
        for (ProfileTeamItem *t in self.followedTeams) {
            NSString *name = NSLocalizedString(t.nameKey, nil) ?: @"";
            if ([name.lowercaseString containsString:lower] || [t.teamId containsString:lower]) {
                [arr addObject:t];
            }
        }
        self.filteredTeams = arr;
    }
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
    ProfileTeamItem *t = isAdd ? nil : self.filteredTeams[indexPath.item];
    __weak typeof(self) weakSelf = self;
    cell.onRemove = ^{
        if (!t) return;
        NSMutableArray *ids = [[ProfileTeamsStore loadFollowedTeamIds] mutableCopy];
        [ids removeObject:t.teamId];
        [ProfileTeamsStore saveFollowedTeamIds:ids];
        [weakSelf reloadData];
    };
    [cell configureWithTeam:t isAdd:isAdd];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    // 原型：4 列
    CGFloat w = collectionView.bounds.size.width;
    NSInteger col = 4;
    CGFloat itemW = floor(w / col);
    return CGSizeMake(itemW, 102);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isSearching) return;
    NSInteger count = self.filteredTeams.count;
    if (indexPath.item == count) {
        AddTeamsViewController *vc = [AddTeamsViewController new];
        vc.hidesBottomBarWhenPushed = YES;
        vc.preselectedTeamIds = [ProfileTeamsStore loadFollowedTeamIds];
        __weak typeof(self) weakSelf = self;
        vc.onConfirmBlock = ^(NSArray<NSString *> *teamIds) {
            [ProfileTeamsStore saveFollowedTeamIds:teamIds];
            [weakSelf reloadData];
        };
        [self.navigationController pushViewController:vc animated:YES];
    }
}

@end

