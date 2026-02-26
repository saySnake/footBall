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
        tabBar.standardAppearance = appearance;
        if (@available(iOS 15.0, *)) {
            tabBar.scrollEdgeAppearance = appearance;
        }
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
    CGFloat pillWidth = 4 * kPillCircleSize + 3 * 16.f + 24.f; // 左右各 12 间距，圆之间 16
    if (pillWidth > barW - 20) {
        pillWidth = barW - 20;
    }
    CGFloat pillX = (barW - pillWidth) / 2.f;
    // 整体向上微调 5px
    CGFloat pillY = tabBar.bounds.size.height - kPillHeight - 17.f;
    self.pillView.frame = CGRectMake(pillX, pillY, pillWidth, kPillHeight);

    CGFloat startX = 12.f;
    CGFloat centerY = kPillHeight / 2.f;
    for (NSInteger i = 0; i < self.pillButtons.count; i++) {
        UIButton *btn = self.pillButtons[i];
        CGFloat cx = startX + kPillCircleSize / 2.f + i * (kPillCircleSize + 16.f);
        btn.bounds = CGRectMake(0, 0, kPillCircleSize, kPillCircleSize);
        btn.center = CGPointMake(cx, centerY);
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
