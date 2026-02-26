//
//  LanguageTestViewController.m
//  footBall
//
//  Created on 2026/1/15.
//

#import "LanguageTestViewController.h"
#import "LanguageManager.h"
#import "ThemeManager.h"
#import <Masonry/Masonry.h>

@interface LanguageTestViewController ()

@property (nonatomic, strong) UILabel *currentLanguageLabel;
@property (nonatomic, strong) UILabel *testLabel1;
@property (nonatomic, strong) UILabel *testLabel2;
@property (nonatomic, strong) UIButton *testButton;

@end

@implementation LanguageTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setNavigationTitleKey:@"language_settings"];
    [self setupUI];
}

- (void)setupUI {
    [super setupUI];
    
    // 添加子视图（懒加载会自动初始化）
    [self.view addSubview:self.currentLanguageLabel];
    [self.view addSubview:self.testLabel1];
    [self.view addSubview:self.testLabel2];
    [self.view addSubview:self.testButton];
    
    // 设置约束
    [self.currentLanguageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(20);
        make.leading.trailing.equalTo(self.view).inset(20);
    }];
    
    [self.testLabel1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.currentLanguageLabel.mas_bottom).offset(30);
        make.leading.trailing.equalTo(self.view).inset(20);
    }];
    
    [self.testLabel2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.testLabel1.mas_bottom).offset(20);
        make.leading.trailing.equalTo(self.view).inset(20);
    }];
    
    [self.testButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.testLabel2.mas_bottom).offset(30);
        make.centerX.equalTo(self.view);
        make.width.equalTo(@200);
        make.height.equalTo(@44);
    }];
    
    [self updateLocalizedStrings];
}

#pragma mark - Lazy Loading

- (UILabel *)currentLanguageLabel {
    if (!_currentLanguageLabel) {
        _currentLanguageLabel = [[UILabel alloc] init];
        _currentLanguageLabel.textAlignment = NSTextAlignmentCenter;
        _currentLanguageLabel.font = [UIFont systemFontOfSize:16];
        _currentLanguageLabel.textColor = [ThemeManager sharedManager].textColor;
    }
    return _currentLanguageLabel;
}

- (UILabel *)testLabel1 {
    if (!_testLabel1) {
        _testLabel1 = [[UILabel alloc] init];
        _testLabel1.textAlignment = NSTextAlignmentCenter;
        _testLabel1.font = [UIFont systemFontOfSize:18];
        _testLabel1.textColor = [ThemeManager sharedManager].textColor;
    }
    return _testLabel1;
}

- (UILabel *)testLabel2 {
    if (!_testLabel2) {
        _testLabel2 = [[UILabel alloc] init];
        _testLabel2.textAlignment = NSTextAlignmentCenter;
        _testLabel2.font = [UIFont systemFontOfSize:18];
        _testLabel2.textColor = [ThemeManager sharedManager].textColor;
    }
    return _testLabel2;
}

- (UIButton *)testButton {
    if (!_testButton) {
        _testButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_testButton setTitle:L(@"ok") forState:UIControlStateNormal];
        _testButton.titleLabel.font = [UIFont systemFontOfSize:18];
        [_testButton addTarget:self action:@selector(testButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _testButton;
}

- (void)updateLocalizedStrings {
    [super updateLocalizedStrings];
    
    // 显示当前语言
    AppLanguage currentLang = [LanguageManager sharedManager].currentLanguage;
    NSString *langName = [LanguageManager displayNameForLanguage:currentLang];
    NSString *langCode = [LanguageManager sharedManager].currentLanguageCode;
    self.currentLanguageLabel.text = [NSString stringWithFormat:@"当前语言: %@ (%@)", langName, langCode];
    
    // 测试本地化字符串
    self.testLabel1.text = [NSString stringWithFormat:@"测试1: %@", L(@"welcome")];
    self.testLabel2.text = [NSString stringWithFormat:@"测试2: %@", L(@"settings_title")];
    
    [self.testButton setTitle:L(@"ok") forState:UIControlStateNormal];
    
    NSLog(@"🔄 语言测试页面已更新: welcome=%@, settings_title=%@", L(@"welcome"), L(@"settings_title"));
}

- (void)updateTheme {
    [super updateTheme];
    
    ThemeManager *themeManager = [ThemeManager sharedManager];
    self.currentLanguageLabel.textColor = themeManager.textColor;
    self.testLabel1.textColor = themeManager.textColor;
    self.testLabel2.textColor = themeManager.textColor;
}

- (void)testButtonTapped:(UIButton *)sender {
    // 测试语言切换
    AppLanguage currentLang = [LanguageManager sharedManager].currentLanguage;
    AppLanguage nextLang = (currentLang + 1) % 4;
    [[LanguageManager sharedManager] setLanguage:nextLang];
    
    [self showSuccess:[NSString stringWithFormat:@"已切换到: %@", [LanguageManager displayNameForLanguage:nextLang]]];
}

@end
