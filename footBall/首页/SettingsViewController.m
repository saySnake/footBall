//
//  SettingsViewController.m
//  footBall
//
//  Created on 2026/1/15.
//

#import "SettingsViewController.h"
#import "LanguageManager.h"
#import "ThemeManager.h"
#import <Masonry/Masonry.h>

@interface SettingsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSArray<NSString *> *> *dataSource;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    [self setupDataSource];
}

- (void)setupUI {
    [self setNavigationTitleKey:@"settings_title"];
    
    // 添加子视图（懒加载会自动初始化）
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

#pragma mark - Lazy Loading

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.backgroundColor = [ThemeManager sharedManager].backgroundColor;
    }
    return _tableView;
}

- (void)setupDataSource {
    self.dataSource = @[
        @[@"language_settings"],
        @[@"theme_settings"],
        @[@"about"]
    ];
}

- (void)updateLocalizedStrings {
    [super updateLocalizedStrings];
    [self.tableView reloadData];
}

- (void)updateTheme {
    [super updateTheme];
    self.tableView.backgroundColor = [ThemeManager sharedManager].backgroundColor;
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.dataSource.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"SettingsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
    }
    
    NSString *key = self.dataSource[indexPath.section][indexPath.row];
    cell.textLabel.text = [LanguageManager localizedStringForKey:key comment:nil];
    cell.textLabel.textColor = [ThemeManager sharedManager].textColor;
    cell.backgroundColor = [ThemeManager sharedManager].backgroundColor;
    
    // 显示当前设置
    if ([key isEqualToString:@"language_settings"]) {
        AppLanguage currentLanguage = [LanguageManager sharedManager].currentLanguage;
        cell.detailTextLabel.text = [LanguageManager displayNameForLanguage:currentLanguage];
    } else if ([key isEqualToString:@"theme_settings"]) {
        AppTheme currentTheme = [ThemeManager sharedManager].currentTheme;
        NSString *themeName = @"";
        switch (currentTheme) {
            case AppThemeLight:
                themeName = L(@"theme_light");
                break;
            case AppThemeDark:
                themeName = L(@"theme_dark");
                break;
            case AppThemeAuto:
                themeName = L(@"theme_auto");
                break;
        }
        cell.detailTextLabel.text = themeName;
    }
    
    cell.detailTextLabel.textColor = [ThemeManager sharedManager].secondaryTextColor;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *key = self.dataSource[indexPath.section][indexPath.row];
    
    if ([key isEqualToString:@"language_settings"]) {
        [self showLanguageSelector];
    } else if ([key isEqualToString:@"theme_settings"]) {
        [self showThemeSelector];
    } else if ([key isEqualToString:@"about"]) {
        [self showAbout];
    }
}

- (void)showLanguageSelector {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[LanguageManager localizedStringForKey:@"language_settings" comment:nil]
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    NSArray<NSNumber *> *languages = @[@(AppLanguageSystem), @(AppLanguageChinese), @(AppLanguageEnglish), @(AppLanguageTraditionalChinese)];
    
    for (NSNumber *langNum in languages) {
        AppLanguage lang = [langNum integerValue];
        NSString *title = [LanguageManager displayNameForLanguage:lang];
        
        // 标记当前选中的语言
        if (lang == [LanguageManager sharedManager].currentLanguage) {
            title = [NSString stringWithFormat:@"✓ %@", title];
        }
        
        UIAlertAction *action = [UIAlertAction actionWithTitle:title
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * _Nonnull action) {
            // 设置语言
            [[LanguageManager sharedManager] setLanguage:lang];
            
            // 刷新当前页面
            [self.tableView reloadData];
            
            // 刷新导航栏标题
            [self setNavigationTitleKey:@"settings_title"];
            
            // 提示用户可能需要重启应用（某些系统级文本）
            NSLog(@"语言已切换为: %@", [LanguageManager displayNameForLanguage:lang]);
        }];
        
        [alert addAction:action];
    }
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[LanguageManager localizedStringForKey:@"cancel" comment:nil]
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showThemeSelector {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:L(@"theme_settings")
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    NSArray<NSArray *> *themes = @[
        @[L(@"theme_auto"), @(AppThemeAuto)],
        @[L(@"theme_light"), @(AppThemeLight)],
        @[L(@"theme_dark"), @(AppThemeDark)]
    ];
    
    for (NSArray *theme in themes) {
        NSString *title = theme[0];
        AppTheme themeType = [theme[1] integerValue];
        
        // 标记当前选中的主题
        if (themeType == [ThemeManager sharedManager].currentTheme) {
            title = [NSString stringWithFormat:@"✓ %@", title];
        }
        
        UIAlertAction *action = [UIAlertAction actionWithTitle:title
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * _Nonnull action) {
            [[ThemeManager sharedManager] setTheme:themeType];
            [self.tableView reloadData];
        }];
        
        [alert addAction:action];
    }
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:L(@"cancel")
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showAbout {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[LanguageManager localizedStringForKey:@"about" comment:nil]
                                                                   message:@"FootBall Shell App\n\n支持多语言和换肤功能"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:[LanguageManager localizedStringForKey:@"ok" comment:nil]
                                                        style:UIAlertActionStyleDefault
                                                      handler:nil];
    [alert addAction:okAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

@end
