//
//  MainTabBarController.m
//  footBall
//

#import "MainTabBarController.h"
#import "HomeViewController.h"
#import "DiscoverViewController.h"
#import "LocationViewController.h"
#import "ProfileViewController.h"

static const CGFloat kPillHeight = 56.f;
static const CGFloat kPillCircleSize = 44.f;

/// Figma「我的」621:3646 底部导航条填充 #285d4b
#define kPillBgColor     [UIColor colorWithRed:40/255.0 green:93/255.0 blue:75/255.0 alpha:1.0]
#define kPillCircleDark  [UIColor colorWithRed:0.16 green:0.18 blue:0.19 alpha:1.0]   // 未选中圆底
#define kPillIconGreen   [UIColor colorWithRed:0.41 green:0.83 blue:0.43 alpha:1.0]   // 绿色图标

@interface MainTabBarController () <UITabBarControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, strong) UIView *bottomBar;
@property (nonatomic, strong) UIView *pillView;
@property (nonatomic, strong) NSArray<UIButton *> *pillButtons;
@end

@implementation MainTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];

    HomeViewController *home = [[HomeViewController alloc] init];
    UINavigationController *navHome = [[UINavigationController alloc] initWithRootViewController:home];
    navHome.tabBarItem = [[UITabBarItem alloc] initWithTitle:@""
                                                       image:nil
                                                         tag:0];

    DiscoverViewController *discover = [[DiscoverViewController alloc] init];
    UINavigationController *navDiscover = [[UINavigationController alloc] initWithRootViewController:discover];
    navDiscover.tabBarItem = [[UITabBarItem alloc] initWithTitle:@""
                                                          image:nil
                                                            tag:1];

    LocationViewController *location = [[LocationViewController alloc] init];
    UINavigationController *navLocation = [[UINavigationController alloc] initWithRootViewController:location];
    navLocation.tabBarItem = [[UITabBarItem alloc] initWithTitle:@""
                                                          image:nil
                                                            tag:2];

    ProfileViewController *profile = [[ProfileViewController alloc] init];
    UINavigationController *navProfile = [[UINavigationController alloc] initWithRootViewController:profile];
    navProfile.tabBarItem = [[UITabBarItem alloc] initWithTitle:@""
                                                          image:nil
                                                            tag:3];

    self.viewControllers = @[ navHome, navDiscover, navLocation, navProfile ];
    self.delegate = self;

    // 监听子导航控制器的页面切换，用于控制底部自定义 TabBar 的显示/隐藏
    navHome.delegate = self;
    navDiscover.delegate = self;
    navLocation.delegate = self;
    navProfile.delegate = self;

    // 方案 B：隐藏系统 TabBar，自定义底部导航条
    self.tabBar.hidden = YES;
    self.tabBar.userInteractionEnabled = NO;

    [self setupTabBarAppearance];
    [self buildPillTabBar];
    [self updatePillSelection];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // 彻底把系统 TabBar 移出可视区域，避免在部分 iOS 版本上出现第二层 TabBar
    UITabBar *tabBar = self.tabBar;
    tabBar.hidden = YES;
    tabBar.alpha = 0.0;
    CGRect frame = tabBar.frame;
    frame.origin.y = CGRectGetMaxY(self.view.bounds);
    frame.size.height = 0;
    tabBar.frame = frame;

    [self layoutPillTabBar];
}

- (void)setupTabBarAppearance {
    // 虽然隐藏了系统 TabBar，但仍统一清空其背景，避免系统层视觉干扰
    UITabBar *tabBar = self.tabBar;
    tabBar.backgroundImage = [UIImage new];
    tabBar.shadowImage = [UIImage new];
    tabBar.backgroundColor = [UIColor clearColor];
    tabBar.barTintColor = [UIColor clearColor];
    if (@available(iOS 13.0, *)) {
        UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
        [appearance configureWithTransparentBackground];
        appearance.backgroundColor = [UIColor clearColor];

        // 彻底隐藏系统标题文字
        NSDictionary *hiddenTitleAttrs = @{ NSForegroundColorAttributeName : [UIColor clearColor] };
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = hiddenTitleAttrs;
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = hiddenTitleAttrs;
        appearance.inlineLayoutAppearance.normal.titleTextAttributes = hiddenTitleAttrs;
        appearance.inlineLayoutAppearance.selected.titleTextAttributes = hiddenTitleAttrs;
        appearance.compactInlineLayoutAppearance.normal.titleTextAttributes = hiddenTitleAttrs;
        appearance.compactInlineLayoutAppearance.selected.titleTextAttributes = hiddenTitleAttrs;

        tabBar.standardAppearance = appearance;
        if (@available(iOS 15.0, *)) {
            tabBar.scrollEdgeAppearance = appearance;
        }
    }

    // 再次确保每个 item 本身也不带标题
    for (UITabBarItem *item in tabBar.items) {
        item.title = nil;
        item.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
        item.titlePositionAdjustment = UIOffsetMake(0, CGFLOAT_MAX); // 完全移出可视范围
    }
}

- (void)buildPillTabBar {
    if (self.pillView) return;

    // 自定义底部容器，固定在安全区域上方
    if (!self.bottomBar) {
        UIView *bar = [[UIView alloc] initWithFrame:CGRectZero];
        bar.backgroundColor = [UIColor clearColor];
        [self.view addSubview:bar];
        self.bottomBar = bar;

        // 使用 Auto Layout 约束到底部安全区域
        bar.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [bar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            [bar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
            [bar.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
            [bar.heightAnchor constraintEqualToConstant:kPillHeight + 16.f] // 上下各 8 间距
        ]];
    }

    UIView *pill = [[UIView alloc] initWithFrame:CGRectZero];
    pill.backgroundColor = kPillBgColor;
    pill.layer.cornerRadius = kPillHeight / 2.f;
    pill.layer.masksToBounds = YES;
    [self.bottomBar addSubview:pill];
    self.pillView = pill;

    NSMutableArray<UIButton *> *buttons = [NSMutableArray array];
    NSArray<NSString *> *iconNames = @[ @"tab_home", @"tab_home2", @"tab_home3", @"tab_home4" ];
    for (NSInteger i = 0; i < iconNames.count; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.tag = i;
        UIImage *img = [UIImage imageNamed:iconNames[i]];
        if (@available(iOS 13.0, *)){
            img = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }
        [btn setImage:img forState:UIControlStateNormal];
        btn.tintColor = kPillIconGreen;
        btn.backgroundColor = kPillCircleDark;
        btn.layer.cornerRadius = kPillCircleSize / 2.f;
        btn.layer.masksToBounds = YES;
        [btn addTarget:self action:@selector(onPillButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [pill addSubview:btn];
        [buttons addObject:btn];
    }
    self.pillButtons = [buttons copy];
}

- (void)layoutPillTabBar {
    if (!self.pillView || self.pillButtons.count == 0) return;

    UIView *bar = self.bottomBar;
    if (!bar) return;

    CGFloat barW = bar.bounds.size.width;
    NSInteger count = self.pillButtons.count;
    if (count <= 0) return;

    // 按设计图固定宽度排布：圆之间 16，左右各 12 留白
    CGFloat spacing = 16.f;
    CGFloat horizontalPadding = 12.f;
    CGFloat pillWidth = count * kPillCircleSize + (count - 1) * spacing + horizontalPadding * 2.f;
    if (pillWidth > barW - 40.f) {
        pillWidth = barW - 40.f;
    }
    CGFloat pillX = (barW - pillWidth) / 2.f;
    // 在自定义底部容器内垂直居中 pill
    CGFloat pillY = (bar.bounds.size.height - kPillHeight) / 2.f;
    self.pillView.frame = CGRectMake(pillX, pillY, pillWidth, kPillHeight);

    // 在 pillView 内部均匀排布 4 个圆形按钮
    CGFloat startX = horizontalPadding;
    CGFloat centerYInPill = kPillHeight / 2.f;
    for (NSInteger i = 0; i < count; i++) {
        UIButton *btn = self.pillButtons[i];
        CGFloat localX = startX + kPillCircleSize / 2.f + i * (kPillCircleSize + spacing);
        btn.bounds = CGRectMake(0, 0, kPillCircleSize, kPillCircleSize);
        btn.center = CGPointMake(localX, centerYInPill);
    }
}

- (void)onPillButtonTapped:(UIButton *)sender {
    NSInteger index = sender.tag;
    if (index >= 0 && index < self.viewControllers.count) {
        self.selectedIndex = index;
        [self updatePillSelection];
    }
}

- (void)updatePillSelection {
    for (NSInteger i = 0; i < self.pillButtons.count; i++) {
        UIButton *btn = self.pillButtons[i];
        BOOL selected = (i == self.selectedIndex);
        if (selected) {
            btn.backgroundColor = [UIColor whiteColor];
            btn.tintColor = [UIColor blackColor];
        } else {
            btn.backgroundColor = kPillCircleDark;
            btn.tintColor = kPillIconGreen;
        }
    }
}

#pragma mark - UITabBarControllerDelegate

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    [self updatePillSelection];
    [self updateBottomBarHiddenForController:viewController];
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController
       willShowViewController:(UIViewController *)viewController
                     animated:(BOOL)animated {
    // 根据即将显示的 VC 决定是否隐藏底部栏（传 viewController 而不是 nav，否则拿到的是旧 topVC）
    [self updateBottomBarHiddenForController:viewController];
}

#pragma mark - BottomBar Visibility

- (void)updateBottomBarHiddenForController:(UIViewController *)vc {
    // 规则：当当前可见控制器（或其顶层）设置了 hidesBottomBarWhenPushed=YES 时，隐藏自定义底部导航条
    UIViewController *target = vc;
    if ([vc isKindOfClass:[UINavigationController class]]) {
        target = ((UINavigationController *)vc).topViewController ?: vc;
    }
    BOOL shouldHide = target.hidesBottomBarWhenPushed;
    self.bottomBar.hidden = shouldHide;
    self.bottomBar.userInteractionEnabled = !shouldHide;
}

- (UIImage *)imageWithSystemName:(NSString *)name {
    if (@available(iOS 13.0, *)) {
        return [UIImage systemImageNamed:name];
    }
    return nil;
}

@end
