//
//  HomeViewController.m
//  footBall
//
//  Created on 2026/1/15.
//

#import "HomeViewController.h"
#import "LanguageManager.h"
#import "ThemeManager.h"
#import "SettingsViewController.h"
#import "APIManager.h"
#import "APIPathNames.h"
#import "APIError.h"
#import "RefreshPagHeader.h"
#import <Masonry/Masonry.h>
#import <DoraemonKit/DoraemonManager.h>

@interface HomeViewController ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *welcomeLabel;
@property (nonatomic, strong) UIButton *settingsButton;
@property (nonatomic, strong) UIButton *loadUserInfoButton; // 加载用户信息按钮
@property (nonatomic, strong) UILabel *userInfoLabel; // 显示用户信息
@property (nonatomic, strong) UIImageView *img;

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    
    // 提前预加载刷新头部的 PAG 文件，避免首次下拉卡顿
    [self preloadRefreshHeader];
    
    // 页面加载时自动请求用户信息（可选）
    // [self loadUserInfo];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // 在页面即将显示时再次确保文件已加载
    if (self.scrollView.mj_header) {
        RefreshPagHeader *header = (RefreshPagHeader *)self.scrollView.mj_header;
        [header ensurePagFilesLoaded];
    }
}

- (void)preloadRefreshHeader {
    // 提前创建刷新头部并预加载（在后台线程预加载文件）
    RefreshPagHeader *refreshHeader = [RefreshPagHeader headerWithRefreshingTarget:self refreshingAction:@selector(refreshData)];
    
    // 立即触发 prepare
    // 如果文件已预加载完成，会立即设置 composition
    // 如果未完成，会启动异步加载
    [refreshHeader prepare];
    
    // 设置刷新头部
    self.scrollView.mj_header = refreshHeader;
    
    // 确保文件已加载（如果预加载已完成，会立即设置）
    // 如果未完成，会在后台加载，不影响首次下拉
    [refreshHeader ensurePagFilesLoaded];
}


- (void)setupUI {
    // 设置导航栏标题
    [self setNavigationTitleKey:@"home_title"];
    
    // 添加 ScrollView 和 ContentView
    [self.view addSubview:self.scrollView];
    [self.scrollView addSubview:self.contentView];
    
    // 添加子视图到 ContentView（懒加载会自动初始化）
    [self.contentView addSubview:self.welcomeLabel];
    [self.contentView addSubview:self.settingsButton];
    [self.contentView addSubview:self.loadUserInfoButton];
    [self.contentView addSubview:self.userInfoLabel];
    [self.contentView addSubview:self.img];
    
    // 设置 ScrollView 约束
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    // 设置 ContentView 约束
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
    }];
    
    // 设置子视图约束
    [self.welcomeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.top.equalTo(self.contentView).offset(40);
        make.leading.trailing.equalTo(self.contentView).inset(20);
    }];
    
    [self.settingsButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.top.equalTo(self.welcomeLabel.mas_bottom).offset(40);
        make.width.equalTo(@200);
        make.height.equalTo(@44);
    }];
    
    [self.loadUserInfoButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.top.equalTo(self.settingsButton.mas_bottom).offset(30);
        make.width.equalTo(@200);
        make.height.equalTo(@44);
    }];
    
    [self.userInfoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.top.equalTo(self.loadUserInfoButton.mas_bottom).offset(30);
        make.leading.trailing.equalTo(self.contentView).inset(20);
        make.bottom.equalTo(self.contentView).offset(-20); // 设置底部约束，确保 ContentView 高度正确
    }];
    
    [self.img mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.top.equalTo(self.contentView).offset(50);
        make.width.height.mas_equalTo(20);
    }];
    
    // 注意：刷新头部在 viewDidLoad 中的 preloadRefreshHeader 中创建和配置
}

#pragma mark - Lazy Loading

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.backgroundColor = [UIColor clearColor];
        _scrollView.showsVerticalScrollIndicator = YES;
        _scrollView.showsHorizontalScrollIndicator = NO;
        if (@available(iOS 11.0, *)) {
            _scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return _scrollView;
}

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
        _contentView.backgroundColor = [UIColor clearColor];
    }
    return _contentView;
}

- (UILabel *)welcomeLabel {
    if (!_welcomeLabel) {
        _welcomeLabel = [[UILabel alloc] init];
        _welcomeLabel.textAlignment = NSTextAlignmentCenter;
        _welcomeLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightMedium];
        _welcomeLabel.textColor = [ThemeManager sharedManager].textColor;
        _welcomeLabel.text = L(@"welcome");
    }
    return _welcomeLabel;
}

- (UIButton *)settingsButton {
    if (!_settingsButton) {
        _settingsButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_settingsButton setTitle:L(@"settings_title")
                          forState:UIControlStateNormal];
        _settingsButton.titleLabel.font = [UIFont systemFontOfSize:18];
        [_settingsButton addTarget:self action:@selector(settingsButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _settingsButton;
}

- (UIImageView *)img {
    if (!_img) {
        _img = [[UIImageView alloc] init];
        _img.image = [UIImage themeImageNamed:@"1"];
    }
    return _img;
}
- (void)updateLocalizedStrings {
    [super updateLocalizedStrings];
    
    self.welcomeLabel.text = L(@"welcome");
    [self.settingsButton setTitle:L(@"settings_title")
                         forState:UIControlStateNormal];
}

- (void)updateTheme {
    [super updateTheme];
    
    self.welcomeLabel.textColor = [ThemeManager sharedManager].textColor;
    
    // 更新图片
    UIImage *newImage = [UIImage themeImageNamed:@"1"];
    self.img.image = newImage;
}

- (void)settingsButtonTapped:(UIButton *)sender {
    SettingsViewController *settingsVC = [[SettingsViewController alloc] init];
    [self.navigationController pushViewController:settingsVC animated:YES];
}

#pragma mark - Lazy Loading (Additional)

- (UIButton *)loadUserInfoButton {
    if (!_loadUserInfoButton) {
        _loadUserInfoButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_loadUserInfoButton setTitle:@"加载用户信息" forState:UIControlStateNormal];
        _loadUserInfoButton.titleLabel.font = [UIFont systemFontOfSize:16];
        _loadUserInfoButton.backgroundColor = [UIColor systemBlueColor];
        [_loadUserInfoButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _loadUserInfoButton.layer.cornerRadius = 8;
        [_loadUserInfoButton addTarget:self 
                                action:@selector(loadUserInfoButtonTapped:) 
                      forControlEvents:UIControlEventTouchUpInside];
    }
    return _loadUserInfoButton;
}

- (UILabel *)userInfoLabel {
    if (!_userInfoLabel) {
        _userInfoLabel = [[UILabel alloc] init];
        _userInfoLabel.textAlignment = NSTextAlignmentCenter;
        _userInfoLabel.font = [UIFont systemFontOfSize:14];
        _userInfoLabel.textColor = [ThemeManager sharedManager].textColor;
        _userInfoLabel.numberOfLines = 0;
        _userInfoLabel.text = @"点击按钮加载用户信息";
    }
    return _userInfoLabel;
}

#pragma mark - Refresh

/// 下拉刷新数据
- (void)refreshData {
    NSLog(@"🔄 开始下拉刷新");
    
    // 刷新用户信息
    [self loadUserInfo];
}

#pragma mark - Network Requests

/// 加载用户信息按钮点击事件
- (void)loadUserInfoButtonTapped:(UIButton *)sender {
    [self loadUserInfo];
}

/// 请求用户信息接口
- (void)loadUserInfo {
    // 显示加载提示
    [[LoadingManager sharedManager] showLoadingWithMessage:@"加载中..." inView:self.view];
    
    // 使用路径名称常量发起请求（推荐方式）
    [[APIManager sharedManager] GETWithPathName:APIPathNameUser
                                        subPath:nil  // 如果需要子路径，如：@"/profile"
                                     parameters:nil  // 请求参数，如：@{@"userId": @"123"}
                                        headers:nil  // 请求头，如：@{@"Authorization": @"Bearer token"}
                                        success:^(id responseObject) {
        // 隐藏加载提示
        [[LoadingManager sharedManager] hideLoadingInView:self.view];
        
        // 结束下拉刷新
        [self.scrollView.mj_header endRefreshing];
        
        // 处理成功响应
        [self handleUserInfoSuccess:responseObject];
        
    } failure:^(NSError *error) {
//        // 隐藏加载提示
        [[LoadingManager sharedManager] hideLoadingInView:self.view];
        
        // 结束下拉刷新
        [self.scrollView.mj_header endRefreshing];
        
        // 处理错误
//        [self handleUserInfoError:error];
    }];
}

/// 请求用户资料接口（带子路径示例）
- (void)loadUserProfile {
    // 显示加载提示
    [[LoadingManager sharedManager] showLoadingWithMessage:@"加载用户资料..." inView:self.view];
    
    // 使用路径名称 + 子路径
    [[APIManager sharedManager] GETWithPathName:APIPathNameUser
                                        subPath:@"/profile"  // 子路径
                                     parameters:nil
                                        headers:nil
                                        success:^(id responseObject) {
        [[LoadingManager sharedManager] hideLoadingInView:self.view];
        [self handleUserProfileSuccess:responseObject];
        
    } failure:^(NSError *error) {
        [[LoadingManager sharedManager] hideLoadingInView:self.view];
        [self handleUserInfoError:error];
    }];
}

/// 请求用户列表接口（带参数示例）
- (void)loadUserList {
    // 显示加载提示
    [[LoadingManager sharedManager] showLoadingWithMessage:@"加载用户列表..." inView:self.view];
    
    // 使用路径名称 + 参数
    NSDictionary *parameters = @{
        @"page": @1,
        @"pageSize": @20,
        @"keyword": @""
    };
    
    [[APIManager sharedManager] GETWithPathName:APIPathNameUserList
                                        subPath:nil
                                     parameters:parameters
                                        headers:nil
                                        success:^(id responseObject) {
        [[LoadingManager sharedManager] hideLoadingInView:self.view];
        [self handleUserListSuccess:responseObject];
        
    } failure:^(NSError *error) {
        [[LoadingManager sharedManager] hideLoadingInView:self.view];
        [self handleUserInfoError:error];
    }];
}

/// 处理用户信息请求成功
- (void)handleUserInfoSuccess:(id)responseObject {
    // 解析响应数据
    if ([responseObject isKindOfClass:[NSDictionary class]]) {
        NSDictionary *data = responseObject;
        
        // 更新UI
        NSString *userInfoText = [NSString stringWithFormat:@"用户信息加载成功\n%@", 
                                  [self formatUserInfo:data]];
        self.userInfoLabel.text = userInfoText;
        self.userInfoLabel.textColor = [UIColor systemGreenColor];
        
        NSLog(@"✅ 用户信息加载成功: %@", data);
    } else {
        self.userInfoLabel.text = @"响应数据格式错误";
        self.userInfoLabel.textColor = [UIColor systemRedColor];
    }
}

/// 处理用户资料请求成功
- (void)handleUserProfileSuccess:(id)responseObject {
    if ([responseObject isKindOfClass:[NSDictionary class]]) {
        NSDictionary *data = responseObject;
        NSString *profileText = [NSString stringWithFormat:@"用户资料\n%@", 
                                 [self formatUserInfo:data]];
        self.userInfoLabel.text = profileText;
        self.userInfoLabel.textColor = [UIColor systemGreenColor];
    }
}

/// 处理用户列表请求成功
- (void)handleUserListSuccess:(id)responseObject {
    if ([responseObject isKindOfClass:[NSDictionary class]]) {
        NSDictionary *data = responseObject;
        NSArray *userList = data[@"list"] ?: data[@"data"] ?: @[];
        NSString *listText = [NSString stringWithFormat:@"用户列表（共 %ld 条）", 
                              (long)userList.count];
        self.userInfoLabel.text = listText;
        self.userInfoLabel.textColor = [UIColor systemGreenColor];
    }
}

/// 处理用户信息请求错误
- (void)handleUserInfoError:(NSError *)error {
    // error 已经是 APIError 类型
    APIError *apiError = (APIError *)error;
    
    // 根据错误类型显示不同的提示
    NSString *errorMessage = nil;
    UIColor *errorColor = [UIColor systemRedColor];
    
    if ([apiError isAuthenticationError]) {
        // 认证错误：需要重新登录
        errorMessage = @"登录已过期，请重新登录";
        // 可以在这里跳转到登录页面
        // [self navigateToLogin];
        
    } else if ([apiError isNetworkError]) {
        // 网络错误
        if (apiError.retryCount > 0) {
            errorMessage = [NSString stringWithFormat:@"网络错误，已重试 %ld 次", 
                           (long)apiError.retryCount];
        } else {
            errorMessage = @"网络连接失败，请检查网络设置";
        }
        
    } else if ([apiError isServerError]) {
        // 服务器错误
        errorMessage = apiError.businessMessage ?: @"服务器错误，请稍后重试";
        
    } else {
        // 其他错误
        errorMessage = apiError.businessMessage ?: apiError.localizedDescription ?: @"请求失败";
    }
    
    // 更新UI
    self.userInfoLabel.text = errorMessage;
    self.userInfoLabel.textColor = errorColor;
    
    // 显示错误提示
    [[LoadingManager sharedManager] showError:errorMessage inView:self.view];
    
    NSLog(@"❌ 用户信息加载失败: %@ (重试次数: %ld)", 
          errorMessage, 
          (long)apiError.retryCount);
}

/// 格式化用户信息显示
- (NSString *)formatUserInfo:(NSDictionary *)userInfo {
    NSMutableString *formatted = [NSMutableString string];
    
    if (userInfo[@"id"]) {
        [formatted appendFormat:@"ID: %@\n", userInfo[@"id"]];
    }
    if (userInfo[@"name"]) {
        [formatted appendFormat:@"姓名: %@\n", userInfo[@"name"]];
    }
    if (userInfo[@"email"]) {
        [formatted appendFormat:@"邮箱: %@\n", userInfo[@"email"]];
    }
    if (userInfo[@"avatar"]) {
        [formatted appendFormat:@"头像: %@\n", userInfo[@"avatar"]];
    }
    
    if (formatted.length == 0) {
        return [userInfo description];
    }
    
    return formatted;
}

@end
