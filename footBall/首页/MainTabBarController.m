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

#define kPillBgColor     [UIColor colorWithRed:0.05 green:0.12 blue:0.11 alpha:1.0]   // 导航条深色背景
#define kPillCircleDark  [UIColor colorWithRed:0.16 green:0.18 blue:0.19 alpha:1.0]   // 未选中圆底
#define kPillIconGreen   [UIColor colorWithRed:0.41 green:0.83 blue:0.43 alpha:1.0]   // 绿色图标

@interface MainTabBarController ()
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

    [self setupTabBarAppearance];
    [self buildPillTabBar];
    [self updatePillSelection];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutPillTabBar];
}

- (void)setupTabBarAppearance {
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

    UITabBar *tabBar = self.tabBar;
    UIView *pill = [[UIView alloc] initWithFrame:CGRectZero];
    pill.backgroundColor = kPillBgColor;
    pill.layer.cornerRadius = kPillHeight / 2.f;
    pill.layer.masksToBounds = YES;
    [tabBar addSubview:pill];
    self.pillView = pill;

    NSMutableArray<UIButton *> *buttons = [NSMutableArray array];
    NSArray<NSString *> *iconNames = @[ @"house", @"bolt.fill", @"safari", @"quote.bubble" ];
    for (NSInteger i = 0; i < iconNames.count; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.tag = i;
        UIImage *img = [self imageWithSystemName:iconNames[i]];
        if (img && @available(iOS 13.0, *)) {
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

    UITabBar *tabBar = self.tabBar;
    CGFloat barW = tabBar.bounds.size.width;
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
    // 整体向上微调
    CGFloat pillY = tabBar.bounds.size.height - kPillHeight - 17.f;
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
}

- (UIImage *)imageWithSystemName:(NSString *)name {
    if (@available(iOS 13.0, *)) {
        return [UIImage systemImageNamed:name];
    }
    return nil;
}

@end
