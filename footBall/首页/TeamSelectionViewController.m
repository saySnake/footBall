//
//  TeamSelectionViewController.m
//  footBall
//

#import "TeamSelectionViewController.h"
#import "MainTabBarController.h"
#import <Masonry/Masonry.h>
#import <math.h>
#import "LoadingManager.h"

/// 选择球队确认后展示的「欢迎来到 Pass Nomad」中间页，点击「立即探索」后执行 onExploreBlock 并关闭
@interface PassNomadWelcomeViewController : UIViewController
@property (nonatomic, copy) void (^onExploreBlock)(void);
@end

@implementation PassNomadWelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.layer.cornerRadius = 10;
    self.view.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    self.view.layer.masksToBounds = YES;
    self.modalPresentationStyle = UIModalPresentationPageSheet;
    self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    if (@available(iOS 15.0, *)) {
        UISheetPresentationController *sheet = self.sheetPresentationController;
        if (sheet) {
            sheet.detents = @[ [UISheetPresentationControllerDetent mediumDetent], [UISheetPresentationControllerDetent largeDetent] ];
            sheet.prefersGrabberVisible = YES;
        }
    }

    // 设计图：上方为 discover 地图图（队徽与地点名）
    UIImageView *discoverImageView = [[UIImageView alloc] init];
    discoverImageView.image = [UIImage imageNamed:@"discover"];
    discoverImageView.contentMode = UIViewContentModeScaleAspectFill;
    discoverImageView.clipsToBounds = YES;
    discoverImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:discoverImageView];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = NSLocalizedString(@"login_welcome_title", nil);
    titleLabel.font = [UIFont boldSystemFontOfSize:24];
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:titleLabel];

    UILabel *subtitleLabel = [[UILabel alloc] init];
    subtitleLabel.text = NSLocalizedString(@"welcome_subtitle", nil);
    subtitleLabel.font = [UIFont systemFontOfSize:15];
    subtitleLabel.textColor = [UIColor darkGrayColor];
    subtitleLabel.textAlignment = NSTextAlignmentCenter;
    subtitleLabel.numberOfLines = 0;
    subtitleLabel.preferredMaxLayoutWidth = UIScreen.mainScreen.bounds.size.width - 48;
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [subtitleLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.view addSubview:subtitleLabel];

    UIButton *exploreBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [exploreBtn setTitle:NSLocalizedString(@"welcome_explore_button", nil) forState:UIControlStateNormal];
    [exploreBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    exploreBtn.backgroundColor = [ColorManager sharedManager].primaryColor;
    exploreBtn.layer.cornerRadius = 26;
    exploreBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [exploreBtn addTarget:self action:@selector(exploreTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:exploreBtn];

    [discoverImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(38);
        make.leading.equalTo(self.view).offset(24);
        make.trailing.equalTo(self.view).offset(-24);
        make.height.mas_equalTo(255);
    }];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(discoverImageView.mas_bottom).offset(23);
        make.leading.equalTo(self.view).offset(24);
        make.trailing.equalTo(self.view).offset(-24);
        make.height.mas_equalTo(28);
    }];
    [subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleLabel.mas_bottom).offset(10);
        make.leading.equalTo(self.view).offset(24);
        make.trailing.equalTo(self.view).offset(-24);
        make.height.mas_greaterThanOrEqualTo(36);
    }];
    [exploreBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(subtitleLabel.mas_bottom).offset(30.5);
        make.leading.equalTo(self.view).offset(24);
        make.trailing.equalTo(self.view).offset(-24);
        make.height.mas_equalTo(52);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-42);
    }];
}

- (void)exploreTapped {
    if (self.onExploreBlock) self.onExploreBlock();
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end

@interface TeamCell : UICollectionViewCell
@property (nonatomic, strong) UIView *shadowContainerView;  // 仅负责阴影，圆角以产生圆形阴影
@property (nonatomic, strong) UIView *circleBackgroundView; // 白底圆形容器，masksToBounds 裁剪为圆
@property (nonatomic, strong) UIImageView *logoView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIImageView *checkmarkView;
@end

@implementation TeamCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = [UIColor clearColor];
        
        // 外层：只负责圆形阴影，不裁剪子视图
        _shadowContainerView = [[UIView alloc] init];
        _shadowContainerView.backgroundColor = [UIColor clearColor];
        _shadowContainerView.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.08].CGColor;
        _shadowContainerView.layer.shadowOpacity = 1.0;
        _shadowContainerView.layer.shadowRadius = 8;
        _shadowContainerView.layer.shadowOffset = CGSizeMake(0, 4);
        
        // 内层：白底圆形容器，裁剪为圆（与设计图一致）
        _circleBackgroundView = [[UIView alloc] init];
        _circleBackgroundView.backgroundColor = [UIColor whiteColor];
        _circleBackgroundView.layer.masksToBounds = YES;
        
        _logoView = [[UIImageView alloc] init];
        _logoView.contentMode = UIViewContentModeScaleAspectFit;
        
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont systemFontOfSize:12];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        
        _checkmarkView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"checkmark.circle.fill"]];
        _checkmarkView.tintColor = [ColorManager sharedManager].primaryColor;
        _checkmarkView.hidden = YES;
        
        [self.contentView addSubview:_shadowContainerView];
        [_shadowContainerView addSubview:_circleBackgroundView];
        [_circleBackgroundView addSubview:_logoView];
        [self.contentView addSubview:_nameLabel];
        [self.contentView addSubview:_checkmarkView];
        
        [_shadowContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView);
            make.centerX.equalTo(self.contentView);
            make.width.height.mas_equalTo(72);
        }];
        
        [_circleBackgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.shadowContainerView);
        }];
        
        [_logoView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.circleBackgroundView);
            make.width.height.mas_equalTo(40);
        }];
        
        [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.shadowContainerView.mas_bottom).offset(8);
            make.leading.trailing.equalTo(self.contentView).inset(4);
            make.bottom.equalTo(self.contentView);
        }];
        
        // 对勾在圆形右上角，略微压住绿色描边
        [_checkmarkView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.shadowContainerView).offset(-4);
            make.trailing.equalTo(self.shadowContainerView).offset(4);
            make.width.height.mas_equalTo(20);
        }];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.shadowContainerView.bounds.size.width;
    if (!isfinite(w) || w <= 0) {
        w = 72.0; // 与约束一致，保证首次展示即为圆
    }
    CGFloat radius = w / 2.0;
    self.shadowContainerView.layer.cornerRadius = radius; // 阴影形状为圆
    self.circleBackgroundView.layer.cornerRadius = radius; // 白底裁剪为圆
}

@end

@interface TeamSelectionViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UISearchBarDelegate>

@property (nonatomic, strong) UILabel *pageTitleLabel;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIButton *confirmButton;

@property (nonatomic, strong) NSArray<Team *> *allTeams;
@property (nonatomic, strong) NSArray<Team *> *filteredTeams;
@property (nonatomic, strong) NSMutableArray<Team *> *selectedTeams;

@end

@implementation TeamSelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    // 标题放在页面内容区左对齐，不用导航栏标题；不显示返回按钮
    self.navigationItem.title = nil;
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.hidesBackButton = YES;
    
    [self buildData];
    [self setupUI];
}

- (void)buildData {
//    NSMutableArray *arr = [NSMutableArray array];
//    NSArray *names = @[
//        NSLocalizedString(@"team_name_manutd", nil),
//        NSLocalizedString(@"team_name_liverpool", nil),
//        NSLocalizedString(@"team_name_chelsea", nil),
//        NSLocalizedString(@"team_name_arsenal", nil),
//        NSLocalizedString(@"team_name_mancity", nil),
//        NSLocalizedString(@"team_name_spurs", nil),
//        NSLocalizedString(@"team_name_brentford", nil),
//        NSLocalizedString(@"team_name_wolves", nil),
//        NSLocalizedString(@"team_name_brighton", nil)
//    ];
//    for (NSString *name in names) {
//        TeamModel *m = [TeamModel new];
//        m.name = name;
//        m.logoName = @"team_placeholder";
//        [arr addObject:m];
//    }
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [TeamsRequest.shared searchTeams:@"" leagueId:nil page:1 pageSize:20 success:^(HTTPResponse <NSArray<Team*>*>* _Nullable responseObject) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        self.allTeams = responseObject.dataObject;
        self.filteredTeams = responseObject.dataObject;
        self.selectedTeams = [NSMutableArray array];
        [self.collectionView reloadData];
    } failure:^(NSError * _Nonnull error) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [QMUITips showError:error.localizedDescription];
    }];
}

- (void)setupUI {
    // 页面内标题：请选择你喜欢的球队，左对齐、加粗
    self.pageTitleLabel = [[UILabel alloc] init];
    self.pageTitleLabel.text = NSLocalizedString(@"team_select_title", nil);
    self.pageTitleLabel.font = [UIFont boldSystemFontOfSize:22];
    self.pageTitleLabel.textColor = [UIColor blackColor];
    self.pageTitleLabel.textAlignment = NSTextAlignmentLeft;
    
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.placeholder = NSLocalizedString(@"team_search_placeholder", nil);
    self.searchBar.delegate = self;
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.backgroundImage = [UIImage new];
    // 设计图：搜索框为浅灰色圆角（与 MyTeams/AddTeams 搜索区 0.92 一致）
    if (@available(iOS 13.0, *)) {
        UITextField *textField = self.searchBar.searchTextField;
        textField.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
        textField.layer.cornerRadius = 20.0;
        textField.layer.masksToBounds = YES;
        textField.font = [UIFont systemFontOfSize:14];
    }
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    CGFloat totalWidth = UIScreen.mainScreen.bounds.size.width;
    CGFloat horizontalInset = 24.0;
    CGFloat interItemSpacing = 24.0;
    CGFloat itemWidth = (totalWidth - horizontalInset * 2 - interItemSpacing * 2) / 3.0;
    layout.itemSize = CGSizeMake(itemWidth, 104);
    layout.minimumLineSpacing = 24;
    layout.minimumInteritemSpacing = interItemSpacing;
    layout.sectionInset = UIEdgeInsetsMake(24, horizontalInset, 24, horizontalInset);
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self.collectionView registerClass:[TeamCell class] forCellWithReuseIdentifier:@"TeamCell"];
    
    self.confirmButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.confirmButton setTitle:NSLocalizedString(@"team_confirm_button", nil) forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.confirmButton.backgroundColor = [ColorManager sharedManager].primaryColor;
    self.confirmButton.layer.cornerRadius = 26;
    [self.confirmButton addTarget:self action:@selector(confirmTapped) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.pageTitleLabel];
    [self.view addSubview:self.searchBar];
    [self.view addSubview:self.collectionView];
    [self.view addSubview:self.confirmButton];
    
    [self.pageTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(16);
        make.leading.equalTo(self.view).offset(24);
        make.trailing.equalTo(self.view).offset(-24);
    }];
    
    [self.searchBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.pageTitleLabel.mas_bottom).offset(16);
        make.leading.trailing.equalTo(self.view).inset(24);
        make.height.mas_equalTo(44);
    }];
    
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.searchBar.mas_bottom).offset(12);
        make.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(self.confirmButton.mas_top).offset(-16);
    }];
    
    [self.confirmButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.view).offset(24);
        make.trailing.equalTo(self.view).offset(-24);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-16);
        make.height.mas_equalTo(52);
    }];
}

#pragma mark - Collection

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.filteredTeams.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TeamCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TeamCell" forIndexPath:indexPath];
    Team *m = self.filteredTeams[indexPath.item];
    cell.nameLabel.text = m.name;
    [cell.logoView sd_setImageWithURL:[NSURL URLWithString:m.logo]];
    BOOL selected = [self.selectedTeams containsObject:m];
    cell.checkmarkView.hidden = !selected;
    // 按设计图：选中 = 圆形加粗绿色描边；未选中 = 圆形细浅灰描边（描边在圆形容器上）
    UIColor *greenColor = [ColorManager sharedManager].primaryColor;
    UIColor *lightGrayColor = [UIColor colorWithWhite:0.85 alpha:1.0];
    cell.circleBackgroundView.layer.borderWidth = selected ? 3.0 : 1.0;
    cell.circleBackgroundView.layer.borderColor = selected ? greenColor.CGColor : lightGrayColor.CGColor;
    [cell setNeedsLayout];
    [cell layoutIfNeeded]; // 确保圆角已应用再显示
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    Team *m = self.filteredTeams[indexPath.item];
    if ([self.selectedTeams containsObject:m]) {
        [self.selectedTeams removeObject:m];
    } else {
        [self.selectedTeams addObject:m];
    }
    [collectionView reloadItemsAtIndexPaths:@[indexPath]];
}

#pragma mark - Search

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText.length == 0) {
        self.filteredTeams = self.allTeams;
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(Team *evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
            return [evaluatedObject.name containsString:searchText];
        }];
        self.filteredTeams = [self.allTeams filteredArrayUsingPredicate:predicate];
    }
    [self.collectionView reloadData];
}

#pragma mark - Actions

- (void)confirmTapped {
    if (self.selectedTeams.count == 0) {
        NSString *msg = NSLocalizedString(@"team_select_required", nil);
        if (msg.length == 0 || [msg hasPrefix:@"team_"]) msg = @"请至少选择一个喜欢的球队";
        [[LoadingManager sharedManager] showError:msg inView:self.view];
        return;
    }

    NSArray *teamIds = [self.selectedTeams qmui_mapWithBlock:^id _Nonnull(Team * _Nonnull item, NSInteger index) {
        return item.teamId ?: @"";
    }];
    NSMutableArray<NSString *> *validIds = [NSMutableArray array];
    for (NSString *tid in teamIds) {
        if ([tid isKindOfClass:NSString.class] && tid.length > 0) [validIds addObject:tid];
    }
    if (validIds.count == 0) {
        NSString *msg = NSLocalizedString(@"team_select_required", nil);
        if (msg.length == 0 || [msg hasPrefix:@"team_"]) msg = @"请至少选择一个喜欢的球队";
        [[LoadingManager sharedManager] showError:msg inView:self.view];
        return;
    }

    // 对接真实接口：新手引导批量关注球队 + 完成新手引导
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    __weak typeof(self) wself = self;
    [TeamsRequest.shared onboardingFollows:validIds success:^(HTTPResponse * _Nullable responseObject) {
        [MBProgressHUD hideHUDForView:wself.view animated:YES];
        [UserRequest.shared completeNewUserOnboardingSuccess:nil failure:nil];
        PassNomadWelcomeViewController *welcomeVC = [[PassNomadWelcomeViewController alloc] init];
        welcomeVC.onExploreBlock = ^{
            [wself goToHome];
        };
        [wself presentViewController:welcomeVC animated:YES completion:nil];
    } failure:^(NSError * _Nonnull error) {
        [MBProgressHUD hideHUDForView:wself.view animated:YES];
        NSString *msg = error.localizedDescription ?: @"";
        if (msg.length == 0) msg = NSLocalizedString(@"network_error", nil) ?: @"请求失败";
        [[LoadingManager sharedManager] showError:msg inView:wself.view];
    }];
}

- (void)goToHome {
    MainTabBarController *tabBar = [[MainTabBarController alloc] init];
    UIWindow *window = self.view.window ?: [UIApplication sharedApplication].windows.firstObject;
    if (window) {
        window.rootViewController = tabBar;
    } else {
        [self presentViewController:tabBar animated:YES completion:nil];
    }
}

@end

