//
//  TeamSelectionViewController.m
//  footBall
//

#import "TeamSelectionViewController.h"
#import "HomeViewController.h"
#import <Masonry/Masonry.h>
#import <math.h>

@interface TeamModel : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *logoName;
@end

@implementation TeamModel
@end

@interface TeamCell : UICollectionViewCell
@property (nonatomic, strong) UIView *circleBackgroundView;
@property (nonatomic, strong) UIImageView *logoView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIImageView *checkmarkView;
@end

@implementation TeamCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = [UIColor clearColor];
        
        _circleBackgroundView = [[UIView alloc] init];
        _circleBackgroundView.backgroundColor = [UIColor whiteColor];
        _circleBackgroundView.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.08].CGColor;
        _circleBackgroundView.layer.shadowOpacity = 1.0;
        _circleBackgroundView.layer.shadowRadius = 8;
        _circleBackgroundView.layer.shadowOffset = CGSizeMake(0, 4);
        
        _logoView = [[UIImageView alloc] init];
        _logoView.contentMode = UIViewContentModeScaleAspectFit;
        
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont systemFontOfSize:12];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        
        _checkmarkView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"checkmark.circle.fill"]];
        _checkmarkView.tintColor = [UIColor colorWithRed:0.10 green:0.36 blue:0.28 alpha:1.0];
        _checkmarkView.hidden = YES;
        
        [self.contentView addSubview:_circleBackgroundView];
        [_circleBackgroundView addSubview:_logoView];
        [self.contentView addSubview:_nameLabel];
        [self.contentView addSubview:_checkmarkView];
        
        [_circleBackgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView);
            make.centerX.equalTo(self.contentView);
            make.width.height.mas_equalTo(72);
        }];
        
        [_logoView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.circleBackgroundView);
            make.width.height.mas_equalTo(40);
        }];
        
        [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.circleBackgroundView.mas_bottom).offset(8);
            make.leading.trailing.equalTo(self.contentView).inset(4);
            make.bottom.equalTo(self.contentView);
        }];
        
        // 对勾在圆形右上角，略微压住绿色描边
        [_checkmarkView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.circleBackgroundView).offset(-4);
            make.trailing.equalTo(self.circleBackgroundView).offset(4);
            make.width.height.mas_equalTo(20);
        }];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.circleBackgroundView.bounds.size.width;
    if (!isfinite(w) || w <= 0) {
        self.circleBackgroundView.layer.cornerRadius = 0;
    } else {
        self.circleBackgroundView.layer.cornerRadius = w / 2.0;
    }
}

@end

@interface TeamSelectionViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UISearchBarDelegate>

@property (nonatomic, strong) UILabel *pageTitleLabel;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIButton *skipButton;
@property (nonatomic, strong) UIButton *confirmButton;

@property (nonatomic, strong) NSArray<TeamModel *> *allTeams;
@property (nonatomic, strong) NSArray<TeamModel *> *filteredTeams;
@property (nonatomic, strong) NSMutableArray<TeamModel *> *selectedTeams;

@property (nonatomic, strong) UIView *bottomSheet;

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
    NSMutableArray *arr = [NSMutableArray array];
    NSArray *names = @[
        NSLocalizedString(@"team_name_manutd", nil),
        NSLocalizedString(@"team_name_liverpool", nil),
        NSLocalizedString(@"team_name_chelsea", nil),
        NSLocalizedString(@"team_name_arsenal", nil),
        NSLocalizedString(@"team_name_mancity", nil),
        NSLocalizedString(@"team_name_spurs", nil),
        NSLocalizedString(@"team_name_brentford", nil),
        NSLocalizedString(@"team_name_wolves", nil),
        NSLocalizedString(@"team_name_brighton", nil)
    ];
    for (NSString *name in names) {
        TeamModel *m = [TeamModel new];
        m.name = name;
        m.logoName = @"team_placeholder";
        [arr addObject:m];
    }
    self.allTeams = arr;
    self.filteredTeams = arr;
    self.selectedTeams = [NSMutableArray array];
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
    // 设计图：搜索框为浅灰色圆角
    if (@available(iOS 13.0, *)) {
        UITextField *textField = self.searchBar.searchTextField;
        textField.backgroundColor = [UIColor colorWithWhite:0.90 alpha:1.0];
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
    
    self.skipButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.skipButton setTitle:NSLocalizedString(@"team_skip_button", nil) forState:UIControlStateNormal];
    [self.skipButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    self.skipButton.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    self.skipButton.layer.cornerRadius = 22;
    [self.skipButton addTarget:self action:@selector(skipTapped) forControlEvents:UIControlEventTouchUpInside];
    
    self.confirmButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.confirmButton setTitle:NSLocalizedString(@"team_confirm_button", nil) forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.confirmButton.backgroundColor = [UIColor colorWithRed:0.10 green:0.36 blue:0.28 alpha:1.0];
    self.confirmButton.layer.cornerRadius = 22;
    [self.confirmButton addTarget:self action:@selector(confirmTapped) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.pageTitleLabel];
    [self.view addSubview:self.searchBar];
    [self.view addSubview:self.collectionView];
    [self.view addSubview:self.skipButton];
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
        make.bottom.equalTo(self.skipButton.mas_top).offset(-16);
    }];
    
    [self.skipButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.view).offset(24);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-16);
        make.height.mas_equalTo(44);
        make.width.equalTo(self.view.mas_width).multipliedBy(0.4);
    }];
    
    [self.confirmButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.view).offset(-24);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-16);
        make.height.mas_equalTo(44);
        make.width.equalTo(self.view.mas_width).multipliedBy(0.4);
    }];
}

#pragma mark - Collection

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.filteredTeams.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TeamCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TeamCell" forIndexPath:indexPath];
    TeamModel *m = self.filteredTeams[indexPath.item];
    cell.nameLabel.text = m.name;
    cell.logoView.image = [UIImage imageNamed:m.logoName];
    BOOL selected = [self.selectedTeams containsObject:m];
    cell.checkmarkView.hidden = !selected;
    // 按设计图：选中 = 圆形加粗绿色描边；未选中 = 圆形细浅灰描边
    UIColor *greenColor = [UIColor colorWithRed:0.10 green:0.36 blue:0.28 alpha:1.0];
    UIColor *lightGrayColor = [UIColor colorWithWhite:0.85 alpha:1.0];
    cell.circleBackgroundView.layer.borderWidth = selected ? 3.0 : 1.0;
    cell.circleBackgroundView.layer.borderColor = selected ? greenColor.CGColor : lightGrayColor.CGColor;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    TeamModel *m = self.filteredTeams[indexPath.item];
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
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(TeamModel *evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
            return [evaluatedObject.name containsString:searchText];
        }];
        self.filteredTeams = [self.allTeams filteredArrayUsingPredicate:predicate];
    }
    [self.collectionView reloadData];
}

#pragma mark - Actions

- (void)skipTapped {
    [self goToHome];
}

- (void)confirmTapped {
    if (self.selectedTeams.count == 0) {
        // 未选择任何球队，使用简单提示弹层
        [self showBottomSheetWithMessage:NSLocalizedString(@"team_message_none_selected", nil)];
    } else {
        // 已选择球队，展示可编辑的底部弹层
        [self showSelectedTeamsSheet];
    }
}

- (void)showSelectedTeamsSheet {
    if (self.bottomSheet.superview) {
        [self.bottomSheet removeFromSuperview];
    }
    
    // 半透明遮罩
    UIView *overlay = [[UIView alloc] init];
    overlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.35];
    
    // 底部白色圆角弹层
    UIView *sheet = [[UIView alloc] init];
    sheet.backgroundColor = [UIColor whiteColor];
    sheet.layer.cornerRadius = 16;
    sheet.layer.masksToBounds = YES;
    
    // 顶部拖拽指示条
    UIView *handleView = [[UIView alloc] init];
    handleView.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1.0];
    handleView.layer.cornerRadius = 2.0;
    
    UILabel *label = [[UILabel alloc] init];
    label.text = NSLocalizedString(@"team_message_selected", nil);
    label.font = [UIFont boldSystemFontOfSize:16];
    label.textColor = [UIColor blackColor];
    
    UIScrollView *scroll = [[UIScrollView alloc] init];
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisHorizontal;
    stack.spacing = 12;
    
    // 选中球队的小圆图标，可删除
    [self.selectedTeams enumerateObjectsUsingBlock:^(TeamModel *m, NSUInteger idx, BOOL *stop) {
        UIView *chipContainer = [[UIView alloc] init];
        chipContainer.backgroundColor = [UIColor clearColor];
        
        UIView *circle = [[UIView alloc] init];
        circle.backgroundColor = [UIColor whiteColor];
        circle.layer.cornerRadius = 24;
        circle.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.08].CGColor;
        circle.layer.shadowOpacity = 1.0;
        circle.layer.shadowRadius = 6;
        circle.layer.shadowOffset = CGSizeMake(0, 3);
        
        UIImageView *logoView = [[UIImageView alloc] init];
        logoView.contentMode = UIViewContentModeScaleAspectFit;
        logoView.image = [UIImage imageNamed:m.logoName];
        
        UIButton *removeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        if (@available(iOS 13.0, *)) {
            UIImage *xImage = [UIImage systemImageNamed:@"xmark.circle.fill"];
            [removeBtn setImage:xImage forState:UIControlStateNormal];
        } else {
            [removeBtn setTitle:@"✕" forState:UIControlStateNormal];
        }
        removeBtn.tintColor = [UIColor darkGrayColor];
        removeBtn.backgroundColor = [UIColor clearColor];
        removeBtn.tag = (NSInteger)idx;
        [removeBtn addTarget:self action:@selector(sheetRemoveTeamTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        [chipContainer addSubview:circle];
        [circle addSubview:logoView];
        [chipContainer addSubview:removeBtn];
        [stack addArrangedSubview:chipContainer];
        
        [chipContainer mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(60);
        }];
        
        [circle mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(chipContainer);
            make.width.height.mas_equalTo(48);
        }];
        
        [logoView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(circle);
            make.width.height.mas_equalTo(36);
        }];
        
        [removeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(20);
            make.top.equalTo(circle.mas_top).offset(-6);
            make.trailing.equalTo(circle.mas_trailing).offset(6);
        }];
    }];
    
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [cancelBtn setTitle:NSLocalizedString(@"cancel", nil) forState:UIControlStateNormal];
    [cancelBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    cancelBtn.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    cancelBtn.layer.cornerRadius = 22;
    [cancelBtn addTarget:self action:@selector(hideBottomSheet) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *okBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [okBtn setTitle:NSLocalizedString(@"confirm", nil) forState:UIControlStateNormal];
    [okBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    okBtn.backgroundColor = [UIColor colorWithRed:0.10 green:0.36 blue:0.28 alpha:1.0];
    okBtn.layer.cornerRadius = 22;
    [okBtn addTarget:self action:@selector(goToHome) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:overlay];
    [overlay addSubview:sheet];
    [sheet addSubview:handleView];
    [sheet addSubview:label];
    [sheet addSubview:scroll];
    [sheet addSubview:cancelBtn];
    [sheet addSubview:okBtn];
    [scroll addSubview:stack];
    
    self.bottomSheet = overlay;
    
    [overlay mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    [sheet mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(overlay);
        make.bottom.equalTo(overlay.mas_safeAreaLayoutGuideBottom);
        make.height.mas_equalTo(275);
    }];
    
    [handleView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(sheet).offset(8);
        make.centerX.equalTo(sheet);
        make.width.mas_equalTo(36);
        make.height.mas_equalTo(4);
    }];
    
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(handleView.mas_bottom).offset(12);
        make.leading.trailing.equalTo(sheet).inset(24);
    }];
    
    [scroll mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(label.mas_bottom).offset(12);
        make.leading.trailing.equalTo(sheet);
        make.height.mas_equalTo(60);
    }];
    
    [stack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(scroll).inset(16);
        make.height.equalTo(scroll).offset(-32);
    }];
    
    [cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(scroll.mas_bottom).offset(12);
        make.leading.equalTo(sheet).offset(24);
        make.height.mas_equalTo(44);
        make.bottom.equalTo(sheet).offset(-24);
        make.width.equalTo(sheet.mas_width).multipliedBy(0.4);
    }];
    
    [okBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(scroll.mas_bottom).offset(12);
        make.trailing.equalTo(sheet).offset(-24);
        make.height.mas_equalTo(44);
        make.bottom.equalTo(sheet).offset(-24);
        make.width.equalTo(sheet.mas_width).multipliedBy(0.4);
    }];
}

- (void)sheetRemoveTeamTapped:(UIButton *)sender {
    NSInteger index = sender.tag;
    if (index >= 0 && index < (NSInteger)self.selectedTeams.count) {
        TeamModel *m = self.selectedTeams[(NSUInteger)index];
        [self.selectedTeams removeObject:m];
        [self.collectionView reloadData];
        if (self.selectedTeams.count == 0) {
            [self hideBottomSheet];
        } else {
            [self showSelectedTeamsSheet];
        }
    }
}

/// 未选择任何球队时的简单提示弹层
- (void)showBottomSheetWithMessage:(NSString *)title {
    if (self.bottomSheet.superview) {
        [self.bottomSheet removeFromSuperview];
    }
    
    UIView *sheet = [[UIView alloc] init];
    sheet.backgroundColor = [UIColor whiteColor];
    sheet.layer.cornerRadius = 16;
    
    UILabel *label = [[UILabel alloc] init];
    label.text = title;
    label.font = [UIFont boldSystemFontOfSize:16];
    label.textColor = [UIColor blackColor];
    
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [cancelBtn setTitle:NSLocalizedString(@"cancel", nil) forState:UIControlStateNormal];
    [cancelBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    cancelBtn.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    cancelBtn.layer.cornerRadius = 22;
    [cancelBtn addTarget:self action:@selector(hideBottomSheet) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *okBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [okBtn setTitle:NSLocalizedString(@"confirm", nil) forState:UIControlStateNormal];
    [okBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    okBtn.backgroundColor = [UIColor colorWithRed:0.10 green:0.36 blue:0.28 alpha:1.0];
    okBtn.layer.cornerRadius = 22;
    [okBtn addTarget:self action:@selector(hideBottomSheet) forControlEvents:UIControlEventTouchUpInside];
    
    [sheet addSubview:label];
    [sheet addSubview:cancelBtn];
    [sheet addSubview:okBtn];
    [self.view addSubview:sheet];
    
    self.bottomSheet = sheet;
    
    [sheet mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
    }];
    
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(sheet).offset(24);
        make.leading.trailing.equalTo(sheet).inset(24);
    }];
    
    [cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(label.mas_bottom).offset(20);
        make.leading.equalTo(sheet).offset(24);
        make.height.mas_equalTo(44);
        make.bottom.equalTo(sheet).offset(-16);
        make.width.equalTo(sheet.mas_width).multipliedBy(0.4);
    }];
    
    [okBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(label.mas_bottom).offset(20);
        make.trailing.equalTo(sheet).offset(-24);
        make.height.mas_equalTo(44);
        make.bottom.equalTo(sheet).offset(-16);
        make.width.equalTo(sheet.mas_width).multipliedBy(0.4);
    }];
}

- (void)hideBottomSheet {
    [self.bottomSheet removeFromSuperview];
    self.bottomSheet = nil;
}

- (void)goToHome {
    HomeViewController *homeVC = [[HomeViewController alloc] init];
    UINavigationController *nav = self.navigationController;
    if (nav) {
        [nav setViewControllers:@[homeVC] animated:YES];
    } else {
        [self presentViewController:homeVC animated:YES completion:nil];
    }
}

@end

