//
//  ProfileViewController.m
//  footBall
//

#import "ProfileViewController.h"
#import "IdentityAuthViewController.h"
#import "PersonalInfoViewController.h"
#import "SettingsViewController.h"
#import <Masonry/Masonry.h>

#define kProfileHeaderBg  [UIColor colorWithRed:0.04 green:0.14 blue:0.12 alpha:1.0]
#define kProfilePageBg    [UIColor colorWithRed:0.96 green:0.96 blue:0.96 alpha:1.0]
#define kProfileCardBg   [UIColor whiteColor]

static NSArray<NSString *> * _menuKeys(void) {
    return @[@"profile_my_info", @"profile_my_stamps", @"profile_id_verify"];
}

@interface ProfileViewController ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentWrap;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *idLabel;
@property (nonatomic, strong) NSArray<UIControl *> *menuControls;
@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.shouldShowNavigationBar = NO;
    self.view.backgroundColor = kProfilePageBg;
}

- (void)setupUI {
    self.scrollView = [UIScrollView new];
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.backgroundColor = kProfilePageBg;
    if (@available(iOS 11.0, *)) {
        self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [self.view addSubview:self.scrollView];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    self.contentWrap = [UIView new];
    [self.scrollView addSubview:self.contentWrap];
    [self.contentWrap mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
    }];

    self.headerView = [UIView new];
    self.headerView.backgroundColor = kProfileHeaderBg;
    [self.contentWrap addSubview:self.headerView];
    [self.headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.contentWrap);
        make.height.mas_equalTo(200);
    }];

    self.nameLabel = [UILabel new];
    self.nameLabel.text = @"Arisha Ireen";
    self.nameLabel.font = [UIFont boldSystemFontOfSize:20];
    self.nameLabel.textColor = [UIColor whiteColor];
    [self.headerView addSubview:self.nameLabel];
    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.headerView);
        make.top.equalTo(self.headerView).offset(80);
    }];

    self.idLabel = [UILabel new];
    self.idLabel.font = [UIFont systemFontOfSize:13];
    self.idLabel.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    [self.headerView addSubview:self.idLabel];
    [self.idLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.headerView);
        make.top.equalTo(self.nameLabel.mas_bottom).offset(6);
    }];

    UIButton *settingsBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    if (@available(iOS 13.0, *)) {
        [settingsBtn setImage:[UIImage systemImageNamed:@"gearshape"] forState:UIControlStateNormal];
    }
    [settingsBtn setTintColor:[UIColor whiteColor]];
    [settingsBtn addTarget:self action:@selector(openSettings) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView addSubview:settingsBtn];
    if (@available(iOS 11.0, *)) {
        [settingsBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(self.headerView).offset(-16);
            make.top.equalTo(self.view.mas_safeAreaLayoutGuide).offset(8);
            make.size.mas_equalTo(CGSizeMake(36, 36));
        }];
    } else {
        [settingsBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(self.headerView).offset(-16);
            make.top.equalTo(self.headerView).offset(28);
            make.size.mas_equalTo(CGSizeMake(36, 36));
        }];
    }

    UIView *prevCard = nil;
    NSMutableArray *controls = [NSMutableArray array];
    for (NSInteger i = 0; i < _menuKeys().count; i++) {
        NSString *key = _menuKeys()[i];
        UIControl *card = [UIControl new];
        card.backgroundColor = kProfileCardBg;
        card.layer.cornerRadius = 12;
        card.tag = i;
        [card addTarget:self action:@selector(onMenuTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentWrap addSubview:card];
        [card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentWrap).offset(12);
            make.trailing.equalTo(self.contentWrap).offset(-12);
            make.height.mas_equalTo(52);
            if (prevCard) make.top.equalTo(prevCard.mas_bottom).offset(10);
            else          make.top.equalTo(self.headerView.mas_bottom).offset(12);
        }];

        UILabel *lbl = [UILabel new];
        lbl.text = NSLocalizedString(key, nil);
        lbl.font = [UIFont systemFontOfSize:16];
        lbl.textColor = [UIColor blackColor];
        [card addSubview:lbl];
        [lbl mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(card).offset(16);
            make.centerY.equalTo(card);
        }];

        UIImageView *arr = [UIImageView new];
        if (@available(iOS 13.0, *)) {
            arr.image = [UIImage systemImageNamed:@"chevron.right"];
            arr.tintColor = [UIColor colorWithWhite:0.65 alpha:1.0];
        }
        [card addSubview:arr];
        [arr mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(card).offset(-14);
            make.centerY.equalTo(card);
            make.size.mas_equalTo(CGSizeMake(14, 14));
        }];

        prevCard = card;
        [controls addObject:card];
    }
    self.menuControls = [controls copy];
    [prevCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.contentWrap).offset(-20);
    }];
}

- (void)updateLocalizedStrings {
    [super updateLocalizedStrings];
    self.idLabel.text = [NSString stringWithFormat:NSLocalizedString(@"profile_id_format", @"ID : %@"), @"145477487"];
    for (NSInteger i = 0; i < self.menuControls.count && i < _menuKeys().count; i++) {
        UILabel *lbl = [self.menuControls[i].subviews firstObject];
        if ([lbl isKindOfClass:[UILabel class]]) {
            lbl.text = NSLocalizedString(_menuKeys()[i], nil);
        }
    }
}

- (void)openSettings {
    SettingsViewController *vc = [SettingsViewController new];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onMenuTapped:(UIControl *)sender {
    NSInteger idx = sender.tag;
    if (idx < 0 || idx >= (NSInteger)_menuKeys().count) return;
    NSString *key = _menuKeys()[idx];
    if ([key isEqualToString:@"profile_id_verify"]) {
        IdentityAuthViewController *vc = [IdentityAuthViewController new];
        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    } else if ([key isEqualToString:@"profile_my_info"]) {
        PersonalInfoViewController *vc = [PersonalInfoViewController new];
        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

@end
