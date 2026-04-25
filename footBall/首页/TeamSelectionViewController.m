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
@property (nonatomic, strong) UIControl *dimmingControl;
@property (nonatomic, strong) UIView *sheetView;
@property (nonatomic, assign) BOOL didPlayPresentAnimation;
@end

@implementation PassNomadWelcomeViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        // 按设计稿使用底部抽屉，不使用系统 pageSheet。
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];

    self.dimmingControl = [[UIControl alloc] init];
    self.dimmingControl.backgroundColor = [UIColor colorWithWhite:0 alpha:0.45];
    self.dimmingControl.alpha = 1.0;
    [self.view addSubview:self.dimmingControl];

    self.sheetView = [[UIView alloc] init];
    self.sheetView.backgroundColor = [ColorManager colorWithHexString:@"#F9F9F9"];
    self.sheetView.layer.cornerRadius = 24.0;
    self.sheetView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    self.sheetView.layer.masksToBounds = YES;
    [self.view addSubview:self.sheetView];

    UIView *grabberView = [[UIView alloc] init];
    grabberView.backgroundColor = [ColorManager colorWithHexString:@"#D4D4D4"];
    grabberView.layer.cornerRadius = 3.0;
    [self.sheetView addSubview:grabberView];

    // 设计图：上方为 discover 地图图（队徽与地点名）
    UIImageView *discoverImageView = [[UIImageView alloc] init];
    discoverImageView.image = [UIImage imageNamed:@"discover"];
    discoverImageView.contentMode = UIViewContentModeScaleAspectFill;
    discoverImageView.clipsToBounds = YES;
    discoverImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.sheetView addSubview:discoverImageView];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = NSLocalizedString(@"login_welcome_title", nil);
    titleLabel.font = [UIFont boldSystemFontOfSize:24];
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.sheetView addSubview:titleLabel];

    UILabel *subtitleLabel = [[UILabel alloc] init];
    subtitleLabel.text = NSLocalizedString(@"welcome_subtitle", nil);
    subtitleLabel.font = [UIFont systemFontOfSize:15];
    subtitleLabel.textColor = [UIColor darkGrayColor];
    subtitleLabel.textAlignment = NSTextAlignmentCenter;
    subtitleLabel.numberOfLines = 0;
    subtitleLabel.preferredMaxLayoutWidth = UIScreen.mainScreen.bounds.size.width - 48;
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [subtitleLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.sheetView addSubview:subtitleLabel];

    UIButton *exploreBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [exploreBtn setTitle:NSLocalizedString(@"welcome_explore_button", nil) forState:UIControlStateNormal];
    [exploreBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    exploreBtn.backgroundColor = [ColorManager sharedManager].primaryColor;
    exploreBtn.layer.cornerRadius = 26;
    exploreBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [exploreBtn addTarget:self action:@selector(exploreTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.sheetView addSubview:exploreBtn];

    [self.dimmingControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    [self.sheetView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.bottom.equalTo(self.view);
        make.height.mas_equalTo(521);
    }];

    [grabberView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.sheetView).offset(16);
        make.centerX.equalTo(self.sheetView);
        make.width.mas_equalTo(80);
        make.height.mas_equalTo(6);
    }];

    [discoverImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(grabberView.mas_bottom).offset(22);
        make.leading.equalTo(self.sheetView).offset(24);
        make.trailing.equalTo(self.sheetView).offset(-24);
        make.height.mas_equalTo(255);
    }];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(discoverImageView.mas_bottom).offset(23);
        make.leading.equalTo(self.sheetView).offset(24);
        make.trailing.equalTo(self.sheetView).offset(-24);
        make.height.mas_equalTo(28);
    }];
    [subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleLabel.mas_bottom).offset(10);
        make.leading.equalTo(self.sheetView).offset(24);
        make.trailing.equalTo(self.sheetView).offset(-24);
        make.height.mas_greaterThanOrEqualTo(36);
    }];
    [exploreBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(subtitleLabel.mas_bottom).offset(30.5);
        make.leading.equalTo(self.sheetView).offset(24);
        make.trailing.equalTo(self.sheetView).offset(-24);
        make.height.mas_equalTo(52);
        make.bottom.equalTo(self.sheetView.mas_safeAreaLayoutGuideBottom).offset(-12);
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.didPlayPresentAnimation) {
        return;
    }
    self.didPlayPresentAnimation = YES;

    [self.view layoutIfNeeded];
    self.sheetView.transform = CGAffineTransformMakeTranslation(0, 521);

    [UIView animateWithDuration:0.26
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self.sheetView.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)exploreTapped {
    [UIView animateWithDuration:0.22
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
        self.sheetView.transform = CGAffineTransformMakeTranslation(0, 521);
    } completion:^(BOOL finished) {
        if (self.onExploreBlock) self.onExploreBlock();
        [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
    }];
}

@end

@interface SelectedTeamBadgeView : UIControl
@property (nonatomic, strong) UIView *circleView;
@property (nonatomic, strong) UIImageView *logoView;
@property (nonatomic, strong) UIButton *removeButton;
@end

@implementation SelectedTeamBadgeView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.circleView = [[UIView alloc] init];
        self.circleView.backgroundColor = [UIColor whiteColor];
        self.circleView.layer.cornerRadius = 29.0;
//        self.circleView.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.06].CGColor;
//        self.circleView.layer.shadowOpacity = 1.0;
        self.circleView.layer.shadowRadius = 18.0;
//        self.circleView.layer.shadowOffset = CGSizeMake(0, 6);

        self.logoView = [[UIImageView alloc] init];
        self.logoView.contentMode = UIViewContentModeScaleAspectFit;

        self.removeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.removeButton.backgroundColor = [UIColor blackColor];
        self.removeButton.layer.cornerRadius = 7.0;
        [self.removeButton setImage:[[UIImage systemImageNamed:@"xmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        self.removeButton.tintColor = [UIColor whiteColor];
        if (@available(iOS 13.0, *)) {
            [self.removeButton setPreferredSymbolConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:8 weight:UIImageSymbolWeightBold]
                                               forImageInState:UIControlStateNormal];
        }

        [self addSubview:self.circleView];
        [self.circleView addSubview:self.logoView];
        [self addSubview:self.removeButton];

        [self.circleView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
            make.width.height.mas_equalTo(58);
        }];

        [self.logoView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.circleView);
            make.width.height.mas_equalTo(34.8);
        }];

        [self.removeButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self).offset(2);
            make.trailing.equalTo(self).offset(-1);
            make.width.height.mas_equalTo(14);
        }];
    }
    return self;
}

@end

@interface SelectedTeamsConfirmViewController : UIViewController
@property (nonatomic, copy) NSArray<Team *> *selectedTeams;
@property (nonatomic, copy) void (^onSelectionChanged)(NSArray<Team *> *teams);
@property (nonatomic, copy) void (^onConfirm)(NSArray<Team *> *teams);
@end

@interface SelectedTeamsConfirmViewController ()
@property (nonatomic, strong) UIControl *dimmingControl;
@property (nonatomic, strong) UIView *sheetView;
@property (nonatomic, strong) UIView *grabberView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *teamsStackView;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *confirmButton;
@property (nonatomic, strong) NSMutableArray<Team *> *mutableSelectedTeams;
@end

@implementation SelectedTeamsConfirmViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    self.mutableSelectedTeams = [self.selectedTeams mutableCopy] ?: [NSMutableArray array];

    self.dimmingControl = [[UIControl alloc] init];
    self.dimmingControl.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    [self.dimmingControl addTarget:self action:@selector(cancelTapped) forControlEvents:UIControlEventTouchUpInside];

    self.sheetView = [[UIView alloc] init];
    self.sheetView.backgroundColor = [ColorManager colorWithHexString:@"#f9f9f9"];
    self.sheetView.layer.cornerRadius = 24.0;
    self.sheetView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    self.sheetView.layer.masksToBounds = YES;

    self.grabberView = [[UIView alloc] init];
    self.grabberView.backgroundColor = [ColorManager colorWithHexString:@"#d4d4d4"];
    self.grabberView.layer.cornerRadius = 3.0;

    self.titleLabel = [[UILabel alloc] init];
    NSString *title = NSLocalizedString(@"team_selected_title", nil);
    if (title.length == 0 || [title isEqualToString:@"team_selected_title"]) {
        title = @"已经选的球队";
    }
    self.titleLabel.text = title;
    self.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    self.titleLabel.textColor = [ColorManager colorWithHexString:@"#353335"];

    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.backgroundColor = [ColorManager colorWithHexString:@"#f9f9f9"];
    self.scrollView.showsHorizontalScrollIndicator = NO;

    self.teamsStackView = [[UIStackView alloc] init];
    self.teamsStackView.axis = UILayoutConstraintAxisHorizontal;
    self.teamsStackView.alignment = UIStackViewAlignmentCenter;
    self.teamsStackView.backgroundColor = [ColorManager colorWithHexString:@"#f9f9f9"];
    self.teamsStackView.spacing = 13.0;

    self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.cancelButton setTitle:NSLocalizedString(@"cancel", nil) forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[ColorManager colorWithHexString:@"#272727"] forState:UIControlStateNormal];
    self.cancelButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    self.cancelButton.backgroundColor = [ColorManager colorWithHexString:@"#e2e2e2"];
    self.cancelButton.layer.cornerRadius = 26.0;
    self.cancelButton.layer.shadowColor = [ColorManager colorWithHexString:@"#CBCBCB"].CGColor;
    self.cancelButton.layer.shadowOpacity = 0.25;
    self.cancelButton.layer.shadowOffset = CGSizeMake(0, 4);
    self.cancelButton.layer.shadowRadius = 4;
    [self.cancelButton addTarget:self action:@selector(cancelTapped) forControlEvents:UIControlEventTouchUpInside];

    self.confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.confirmButton setTitle:NSLocalizedString(@"team_confirm_button", nil) forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.confirmButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    self.confirmButton.backgroundColor = [ColorManager colorWithHexString:@"#285d4b"];
    self.confirmButton.layer.cornerRadius = 26.0;
    self.confirmButton.layer.shadowColor = [ColorManager colorWithHexString:@"#CBCBCB"].CGColor;
    self.confirmButton.layer.shadowOpacity = 0.25;
    self.confirmButton.layer.shadowOffset = CGSizeMake(0, 4);
    self.confirmButton.layer.shadowRadius = 4;
    [self.confirmButton addTarget:self action:@selector(confirmTapped) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:self.dimmingControl];
    [self.view addSubview:self.sheetView];
    [self.sheetView addSubview:self.grabberView];
    [self.sheetView addSubview:self.titleLabel];
    [self.sheetView addSubview:self.scrollView];
    [self.scrollView addSubview:self.teamsStackView];
    [self.sheetView addSubview:self.cancelButton];
    [self.sheetView addSubview:self.confirmButton];

    [self.dimmingControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    [self.sheetView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(self.view);
        make.height.mas_equalTo(275);
    }];

    [self.grabberView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.sheetView).offset(16);
        make.centerX.equalTo(self.sheetView);
        make.width.mas_equalTo(80);
        make.height.mas_equalTo(6);
    }];

    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.sheetView).offset(44);
        make.leading.equalTo(self.sheetView).offset(16);
        make.trailing.lessThanOrEqualTo(self.sheetView).offset(-16);
    }];

    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(22);
        make.leading.trailing.equalTo(self.sheetView);
        make.height.mas_equalTo(58);
    }];

    // 在部分系统上会触发 "attempting to add unsupported attribute: _UIScrollViewLayoutGuide" 崩溃。
    // 这里统一使用 scrollView 本体约束，配合 stackView 自身内容宽度撑开横向滚动区域。
    [self.teamsStackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView).insets(UIEdgeInsetsMake(0, 16, 0, 16));
        make.height.equalTo(self.scrollView);
    }];

    [self.cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.sheetView).offset(16);
        make.bottom.equalTo(self.sheetView.mas_safeAreaLayoutGuideBottom).offset(-12);
        make.height.mas_equalTo(52);
    }];

    [self.confirmButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.cancelButton.mas_trailing).offset(10);
        make.trailing.equalTo(self.sheetView).offset(-16);
        make.width.equalTo(self.cancelButton);
        make.centerY.height.equalTo(self.cancelButton);
    }];

    [self refreshSelectedTeamsUI];
}

- (void)refreshSelectedTeamsUI {
    for (UIView *view in self.teamsStackView.arrangedSubviews) {
        [self.teamsStackView removeArrangedSubview:view];
        [view removeFromSuperview];
    }

    for (NSInteger idx = 0; idx < self.mutableSelectedTeams.count; idx++) {
        Team *team = self.mutableSelectedTeams[idx];
        SelectedTeamBadgeView *badge = [[SelectedTeamBadgeView alloc] initWithFrame:CGRectZero];
        [badge.logoView sd_setImageWithURL:[NSURL URLWithString:team.logo]];
        badge.removeButton.tag = idx;
        [badge.removeButton addTarget:self action:@selector(removeTeamTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.teamsStackView addArrangedSubview:badge];
        [badge mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(58);
        }];
    }
}

- (void)removeTeamTapped:(UIButton *)sender {
    NSInteger index = sender.tag;
    if (index < 0 || index >= self.mutableSelectedTeams.count) {
        return;
    }
    [self.mutableSelectedTeams removeObjectAtIndex:index];
    if (self.onSelectionChanged) {
        self.onSelectionChanged([self.mutableSelectedTeams copy]);
    }
    if (self.mutableSelectedTeams.count == 0) {
        [self dismissViewControllerAnimated:NO completion:nil];
        return;
    }
    [self refreshSelectedTeamsUI];
}

- (void)cancelTapped {
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)confirmTapped {
    NSArray<Team *> *teams = [self.mutableSelectedTeams copy];
    [self dismissViewControllerAnimated:NO completion:^{
        if (self.onConfirm) {
            self.onConfirm(teams);
        }
    }];
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
        _shadowContainerView.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.12].CGColor;
        _shadowContainerView.layer.shadowOpacity = 0.4;
        _shadowContainerView.layer.shadowRadius = 12;
        _shadowContainerView.layer.shadowOffset = CGSizeMake(0, 5);
        
        // 内层：白底圆形容器，裁剪为圆（与设计图一致）
        _circleBackgroundView = [[UIView alloc] init];
        _circleBackgroundView.backgroundColor = [UIColor whiteColor];
        _circleBackgroundView.layer.masksToBounds = YES;
        
        _logoView = [[UIImageView alloc] init];
        _logoView.contentMode = UIViewContentModeScaleAspectFit;
        
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont systemFontOfSize:14];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        _nameLabel.textColor = [ColorManager colorWithHexString:@"#353335"];
        
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
            make.width.height.mas_equalTo(90);
        }];
        
        [_circleBackgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.shadowContainerView);
        }];
        
        [_logoView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.circleBackgroundView);
            make.width.height.mas_equalTo(50);
        }];
        
        [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.shadowContainerView.mas_bottom).offset(8);
            make.leading.trailing.equalTo(self.contentView).inset(4);
            make.bottom.equalTo(self.contentView);
        }];
        
        // 对勾在圆形右上角，略微压住绿色描边
        [_checkmarkView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.shadowContainerView);
            make.trailing.equalTo(self.shadowContainerView);
            make.width.height.mas_equalTo(20);
        }];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.shadowContainerView.bounds.size.width;
    if (!isfinite(w) || w <= 0) {
        w = 90.0; // 与约束一致，保证首次展示即为圆
    }
    CGFloat radius = w / 2.0;
    self.shadowContainerView.layer.cornerRadius = radius; // 阴影形状为圆
    self.circleBackgroundView.layer.cornerRadius = radius; // 白底裁剪为圆
}

@end

@interface TeamSelectionViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) UILabel *pageTitleLabel;
@property (nonatomic, strong) UIView *searchContainerView;
@property (nonatomic, strong) UIImageView *searchIconView;
@property (nonatomic, strong) UITextField *searchTextField;
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
    self.pageTitleLabel.font = [UIFont boldSystemFontOfSize:24];
    self.pageTitleLabel.textColor = [UIColor blackColor];
    self.pageTitleLabel.textAlignment = NSTextAlignmentLeft;
    
    self.searchContainerView = [[UIView alloc] init];
    self.searchContainerView.backgroundColor = [ColorManager colorWithHexString:@"#f7f6f6"];
    self.searchContainerView.layer.cornerRadius = 18.0;
    self.searchContainerView.layer.masksToBounds = YES;

    UIImage *searchImage = [[UIImage imageNamed:@"search_icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.searchIconView = [[UIImageView alloc] initWithImage:searchImage];
    self.searchIconView.tintColor = [ColorManager colorWithHexString:@"#595959"];
    self.searchIconView.contentMode = UIViewContentModeScaleAspectFit;

    self.searchTextField = [[UITextField alloc] init];
    self.searchTextField.delegate = self;
    self.searchTextField.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    self.searchTextField.textColor = [ColorManager colorWithHexString:@"#353335"];
    self.searchTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.searchTextField.returnKeyType = UIReturnKeySearch;
    self.searchTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"team_search_placeholder", nil)
                                                                                attributes:@{
        NSForegroundColorAttributeName: [ColorManager colorWithHexString:@"#595959"],
        NSFontAttributeName: [UIFont systemFontOfSize:12 weight:UIFontWeightRegular]
    }];
    [self.searchTextField addTarget:self action:@selector(searchTextDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    CGFloat totalWidth = UIScreen.mainScreen.bounds.size.width;
    CGFloat horizontalInset = 24.0;
    CGFloat itemWidth = 90.0;
    CGFloat interItemSpacing = floor((totalWidth - horizontalInset * 2 - itemWidth * 3) / 2.0);
    layout.itemSize = CGSizeMake(itemWidth, 115);
    layout.minimumLineSpacing = 16;
    layout.minimumInteritemSpacing = interItemSpacing;
    layout.sectionInset = UIEdgeInsetsMake(24, horizontalInset, 24, horizontalInset);
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self.collectionView registerClass:[TeamCell class] forCellWithReuseIdentifier:@"TeamCell"];
    
    self.confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.confirmButton setTitle:NSLocalizedString(@"team_confirm_button", nil) forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.confirmButton.backgroundColor = [ColorManager sharedManager].primaryColor;
    self.confirmButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    self.confirmButton.layer.cornerRadius = 26;
    self.confirmButton.layer.shadowColor = [ColorManager colorWithHexString:@"#CBCBCB"].CGColor;
    self.confirmButton.layer.shadowOpacity = 0.25;
    self.confirmButton.layer.shadowOffset = CGSizeMake(0, 4);
    self.confirmButton.layer.shadowRadius = 4;
    [self.confirmButton addTarget:self action:@selector(confirmTapped) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.pageTitleLabel];
    [self.view addSubview:self.searchContainerView];
    [self.searchContainerView addSubview:self.searchIconView];
    [self.searchContainerView addSubview:self.searchTextField];
    [self.view addSubview:self.collectionView];
    [self.view addSubview:self.confirmButton];
    
    [self.pageTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(0);
        make.leading.equalTo(self.view).offset(24);
        make.trailing.equalTo(self.view).offset(-24);
    }];
    
    [self.searchContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.pageTitleLabel.mas_bottom).offset(20);
        make.leading.trailing.equalTo(self.view).inset(24);
        make.height.mas_equalTo(36);
    }];

    [self.searchIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.searchContainerView).offset(12);
        make.centerY.equalTo(self.searchContainerView);
        make.width.height.mas_equalTo(16);
    }];

    [self.searchTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.searchIconView.mas_trailing).offset(8);
        make.trailing.equalTo(self.searchContainerView).offset(-12);
        make.top.bottom.equalTo(self.searchContainerView);
    }];
    
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.searchContainerView.mas_bottom).offset(24);
        make.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];
    
    [self.confirmButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.width.mas_equalTo(168);
        make.bottom.equalTo(self.view).offset(-35);
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
    cell.circleBackgroundView.layer.borderWidth = 1.0;
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

- (void)searchTextDidChange:(UITextField *)textField {
    NSString *searchText = textField.text ?: @"";
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

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Actions

- (void)confirmTapped {
    if (self.selectedTeams.count == 0) {
        NSString *msg = NSLocalizedString(@"team_select_required", nil);
        if (msg.length == 0 || [msg hasPrefix:@"team_"]) msg = @"请至少选择一个喜欢的球队";
        [[LoadingManager sharedManager] showError:msg inView:self.view];
        return;
    }

    SelectedTeamsConfirmViewController *confirmVC = [[SelectedTeamsConfirmViewController alloc] init];
    confirmVC.selectedTeams = [self.selectedTeams copy];
    __weak typeof(self) wself = self;
    confirmVC.onSelectionChanged = ^(NSArray<Team *> *teams) {
        __strong typeof(wself) self = wself;
        if (!self) return;
        self.selectedTeams = [teams mutableCopy];
        [self.collectionView reloadData];
    };
    confirmVC.onConfirm = ^(NSArray<Team *> *teams) {
        __strong typeof(wself) self = wself;
        if (!self) return;
        self.selectedTeams = [teams mutableCopy];
        [self.collectionView reloadData];
        [self submitSelectedTeams];
    };
    [self presentViewController:confirmVC animated:NO completion:nil];
}

- (void)submitSelectedTeams {
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
        [wself presentViewController:welcomeVC animated:NO completion:nil];
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

