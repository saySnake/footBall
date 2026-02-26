//
//  ProfileViewController.m
//  footBall
//

#import "ProfileViewController.h"
#import "SettingsViewController.h"
#import <Masonry/Masonry.h>

@interface ProfileViewController ()
@property (nonatomic, strong) UILabel *tipLabel;
@property (nonatomic, strong) UIButton *settingsButton;
@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self setNavigationTitleKey:@"tab_profile"];
    self.tipLabel = [[UILabel alloc] init];
    self.tipLabel.text = NSLocalizedString(@"tab_profile", nil);
    self.tipLabel.font = [UIFont systemFontOfSize:18];
    self.tipLabel.textColor = [UIColor darkGrayColor];
    self.tipLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.tipLabel];
    self.settingsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.settingsButton setTitle:NSLocalizedString(@"settings_title", nil) forState:UIControlStateNormal];
    [self.settingsButton addTarget:self action:@selector(openSettings) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.settingsButton];
    [self.tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.centerY.equalTo(self.view).offset(-30);
    }];
    [self.settingsButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.tipLabel.mas_bottom).offset(24);
    }];
}

- (void)openSettings {
    SettingsViewController *vc = [[SettingsViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)updateLocalizedStrings {
    [super updateLocalizedStrings];
    self.tipLabel.text = NSLocalizedString(@"tab_profile", nil);
    [self.settingsButton setTitle:NSLocalizedString(@"settings_title", nil) forState:UIControlStateNormal];
}

@end
