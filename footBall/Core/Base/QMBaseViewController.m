//
//  QMBaseViewController.m
//  footBall
//
//  Created on 2026/1/15.
//

#import "QMBaseViewController.h"
#import "LanguageManager.h"
#import "ThemeManager.h"
#import "NavigationBarManager.h"
#import "UINavigationController+NavigationBar.h"
#import <MBProgressHUD/MBProgressHUD.h>

@interface QMBaseViewController ()

@property (nonatomic, strong) MBProgressHUD *hud;
// 注意：enableEmptyView 已在主接口中声明，这里不需要重复声明

@end

@implementation QMBaseViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.shouldShowNavigationBar = YES;
    self.enableEmptyView = NO;
    
    // 监听语言变化
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleLanguageChange:)
                                                 name:AppLanguageDidChangeNotification
                                               object:nil];
    
    // 监听主题变化
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleThemeChange:)
                                                 name:AppThemeDidChangeNotification
                                               object:nil];
    
    [self setupUI];
    [self updateLocalizedStrings];
    [self updateTheme];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // QMUI 导航栏控制
    if ([self.navigationController isKindOfClass:[QMUINavigationController class]]) {
        QMUINavigationController *navController = (QMUINavigationController *)self.navigationController;
        navController.navigationBarHidden = !self.shouldShowNavigationBar;
    } else {
        [self.navigationController setNavigationBarHidden:!self.shouldShowNavigationBar animated:animated];
    }
    
    // 应用导航栏样式（每次出现时应用，确保主题切换后样式正确）
    if (self.shouldShowNavigationBar && self.navigationController) {
        [self.navigationController applyDefaultNavigationBarStyle];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 统一为所有 push 页面开启系统左滑返回（含自定义导航栏页面）
    if (self.navigationController && self.navigationController.viewControllers.count > 1) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        self.navigationController.interactivePopGestureRecognizer.delegate = nil;
    }
}

#pragma mark - QMUIEmptyView

- (void)showEmptyView {
    if (!self.enableEmptyView) {
        return;
    }
    
    // 显示空状态视图（使用默认内容）
    [self showEmptyViewWithImage:nil title:@"" detailText:nil buttonTitle:nil buttonAction:nil];
}

- (void)hideEmptyView {
    // 隐藏空状态视图
    if (self.emptyView) {
        self.emptyView.hidden = YES;
    }
}

- (void)showEmptyViewWithImage:(UIImage *)image
                          title:(NSString *)title
                     detailText:(NSString *)detailText
                    buttonTitle:(NSString *)buttonTitle
                    buttonAction:(SEL)buttonAction {
    if (!self.enableEmptyView) {
        self.enableEmptyView = YES;
    }
    
    // QMUICommonViewController 的 emptyView 是只读属性，会在首次访问时自动创建
    // 直接操作 emptyView 的属性来显示内容
    QMUIEmptyView *emptyView = self.emptyView;
    if (!emptyView) {
        // 如果 emptyView 不存在，先访问一次让它自动创建
        emptyView = self.emptyView;
    }
    
    if (emptyView) {
        emptyView.hidden = NO;
        emptyView.imageView.image = image;
        emptyView.textLabel.text = title ?: @"";
        emptyView.detailTextLabel.text = detailText;
        
        if (buttonTitle && buttonAction) {
            [emptyView.actionButton setTitle:buttonTitle forState:UIControlStateNormal];
            [emptyView.actionButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [emptyView.actionButton addTarget:self action:buttonAction forControlEvents:UIControlEventTouchUpInside];
            emptyView.actionButton.hidden = NO;
        } else {
            emptyView.actionButton.hidden = YES;
        }
        
        [self.view bringSubviewToFront:emptyView];
    }
}

#pragma mark - Navigation

- (void)setNavigationTitleKey:(NSString *)titleKey {
    _navigationTitleKey = titleKey;
    self.navigationTitle = [LanguageManager localizedStringForKey:titleKey comment:nil];
    self.title = self.navigationTitle;
}

- (void)setNavigationTitle:(NSString *)navigationTitle {
    _navigationTitle = navigationTitle;
    _navigationTitleKey = nil; // 清除key，因为使用的是直接设置的标题
    self.title = navigationTitle;
}

#pragma mark - Loading & Toast

- (void)showLoading {
    [self hideLoading];
    
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.mode = MBProgressHUDModeIndeterminate;
    self.hud.label.text = [LanguageManager localizedStringForKey:@"loading" comment:nil];
}

- (void)hideLoading {
    if (self.hud) {
        [self.hud hideAnimated:YES];
        self.hud = nil;
    }
}

- (void)showError:(NSString *)message {
    [self hideLoading];
    
    // 使用 QMUI 的 Toast
    [QMUITips showError:message inView:self.view hideAfterDelay:2.0];
}

- (void)showSuccess:(NSString *)message {
    [self hideLoading];
    
    // 使用 QMUI 的 Toast
    [QMUITips showSucceed:message inView:self.view hideAfterDelay:1.5];
}

#pragma mark - Notification Handlers

- (void)handleLanguageChange:(NSNotification *)notification {
    // 在主线程更新UI
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateLocalizedStrings];
        
        // 更新导航栏标题
        if (self.navigationTitle) {
            self.title = self.navigationTitle;
        }
    });
}

- (void)handleThemeChange:(NSNotification *)notification {
    // 确保在主线程更新UI
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"📢 QMBaseViewController: 收到主题变化通知");
        [self updateTheme];
    });
}

#pragma mark - Trait Collection Changes

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];

    // 主题由 ThemeManager.nightMode 单一开关控制，且 window.overrideUserInterfaceStyle
    // 已被锁定，系统主题变化不会影响 App 内部主题，因此这里不需要任何处理。
}

#pragma mark - Override Methods

- (void)setupUI {
    // 子类重写
    self.view.backgroundColor = [ThemeManager sharedManager].backgroundColor;
    
    // 使用导航栏管理器统一配置导航栏样式
    if (self.shouldShowNavigationBar && self.navigationController) {
        [self.navigationController applyDefaultNavigationBarStyle];
    }
}

- (void)updateLocalizedStrings {
    // 子类重写，更新界面文本
    
    // 如果设置了 navigationTitleKey，重新本地化导航栏标题
    if (self.navigationTitleKey) {
        self.navigationTitle = [LanguageManager localizedStringForKey:self.navigationTitleKey comment:nil];
        self.title = self.navigationTitle;
    } else if (self.navigationTitle) {
        // 如果没有key，直接使用存储的标题
        self.title = self.navigationTitle;
    }
}

- (void)updateTheme {
    // 子类重写，更新主题样式
    ThemeManager *themeManager = [ThemeManager sharedManager];
    self.view.backgroundColor = themeManager.backgroundColor;
    
    // 使用导航栏管理器更新导航栏样式（适配主题切换）
    if (self.shouldShowNavigationBar && self.navigationController) {
        [self.navigationController applyDefaultNavigationBarStyle];
    }
    
    // 更新空状态视图样式
    if (self.emptyView) {
        self.emptyView.textLabel.textColor = themeManager.textColor;
        self.emptyView.detailTextLabel.textColor = themeManager.secondaryTextColor;
    }
}

#pragma mark - QMUICommonViewController

- (BOOL)shouldCustomizeNavigationBarTransitionIfHideable {
    return YES;
}

- (BOOL)preferredNavigationBarHidden {
    return !self.shouldShowNavigationBar;
}

@end
