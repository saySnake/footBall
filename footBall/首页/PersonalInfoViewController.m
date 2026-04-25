//
//  PersonalInfoViewController.m
//  footBall
//

#import "PersonalInfoViewController.h"
#import "PNPickerSheetViewController.h"
#import <Masonry/Masonry.h>
#import <QuartzCore/QuartzCore.h>
#import <math.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <SDWebImage/SDWebImage.h>
#import "AuthManager.h"
#import "User.h"
#import "UserRequest.h"
#import "FileRequest.h"
#import "ColorManager.h"
#import "LoadingManager.h"

/// Figma「个人资料」1:5552 背景 #f7f7f7
#define kPIBg      [UIColor colorWithRed:247/255.0 green:247/255.0 blue:247/255.0 alpha:1.0]
#define kPICardBg  [UIColor whiteColor]
#define kPIGreen   [UIColor colorWithRed:0.157 green:0.365 blue:0.294 alpha:1.0]
#define kPILabel   [UIColor colorWithRed:79/255.0 green:79/255.0 blue:79/255.0 alpha:1.0]

static CGFloat const kPITopGradientH = 208.f;
static CGFloat const kPICardCorner = 6.f;
/// Figma 1:5552：卡片与底部按钮均为距屏幕左右 16pt（375 宽下为 w=343）；勿用 6.4%（会与稿 16 不一致）
static CGFloat const kPIFigmaHorizontalInset = 16.f;

/// 与 preferenceTags 对齐的稳定 key（与接口约定；若后端不同可再映射）
static NSArray<NSString *> *kProfileChipTagKeys(void) {
    static NSArray *keys;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        keys = @[
            @"ultras", @"fan", @"chant_leader", @"supporters", @"curve_stand",
            @"ball_kid", @"venue_staff", @"media", @"art", @"official", @"athlete"
        ];
    });
    return keys;
}

@interface PICheckOption : UIControl
@property (nonatomic, strong) UIView *circle;
@property (nonatomic, strong) UIImageView *checkView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, assign) BOOL checked;
- (instancetype)initWithTitle:(NSString *)title;
@end

@implementation PICheckOption
- (instancetype)initWithTitle:(NSString *)title {
    if (self = [super initWithFrame:CGRectZero]) {
        self.backgroundColor = [UIColor clearColor];
        _circle = [UIView new];
        _circle.layer.cornerRadius = 9;
        _circle.layer.borderWidth = 1.5;
        _circle.layer.borderColor = [UIColor colorWithWhite:0.75 alpha:1.0].CGColor;
        _circle.backgroundColor = [UIColor clearColor];
        [self addSubview:_circle];

        _checkView = [UIImageView new];
        if (@available(iOS 13.0, *)) {
            _checkView.image = [UIImage systemImageNamed:@"checkmark"];
            _checkView.tintColor = kPIGreen;
        }
        _checkView.contentMode = UIViewContentModeScaleAspectFit;
        _checkView.hidden = YES;
        [_circle addSubview:_checkView];

        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont systemFontOfSize:14];
        _titleLabel.textColor = [UIColor blackColor];
        _titleLabel.text = title;
        [self addSubview:_titleLabel];

        [_circle mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self);
            make.centerY.equalTo(self);
            make.size.mas_equalTo(CGSizeMake(18, 18));
        }];
        [_checkView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(_circle);
            make.size.mas_equalTo(CGSizeMake(10, 10));
        }];
        [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_circle.mas_trailing).offset(6);
            make.centerY.equalTo(self);
            make.trailing.equalTo(self);
        }];
    }
    return self;
}
- (void)setChecked:(BOOL)checked {
    _checked = checked;
    self.checkView.hidden = !checked;
    self.circle.layer.borderColor = (checked ? kPIGreen.CGColor : [UIColor colorWithWhite:0.75 alpha:1.0].CGColor);
}
@end

@interface PersonalInfoViewController () <UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, strong) UIView *gradientHostView;
@property (nonatomic, strong) CAGradientLayer *topGradientLayer;
@property (nonatomic, strong) UIView *navBar;
@property (nonatomic, strong) UILabel *navTitle;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *content;

@property (nonatomic, strong) UIView *avatarCard;
@property (nonatomic, strong) UILabel *avatarLeftLabel;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UIImageView *cameraBadge;

// Cards
@property (nonatomic, strong) UIView *nickCard;
@property (nonatomic, strong) UILabel *nickLeft;
@property (nonatomic, strong) UITextField *nickField;

@property (nonatomic, strong) UIView *phoneCard;
@property (nonatomic, strong) UILabel *phoneLeft;
@property (nonatomic, strong) UITextField *phoneField;

@property (nonatomic, strong) UIControl *birthCard;
@property (nonatomic, strong) UILabel *birthLeft;
@property (nonatomic, strong) UILabel *birthValue;
@property (nonatomic, strong) UIImageView *birthArrow;

@property (nonatomic, strong) UIView *genderCard;
@property (nonatomic, strong) UILabel *genderLeft;
@property (nonatomic, strong) PICheckOption *maleOption;
@property (nonatomic, strong) PICheckOption *femaleOption;

@property (nonatomic, strong) UIControl *firstCard;
@property (nonatomic, strong) UILabel *firstYearLeft;
@property (nonatomic, strong) UILabel *firstYearValue;
@property (nonatomic, strong) UIImageView *firstYearArrow;

@property (nonatomic, strong) UIView *identityCard;
@property (nonatomic, strong) UILabel *identityLeft;
@property (nonatomic, strong) UIImageView *identityArrow;

@property (nonatomic, strong) UIView *chipsContainer;
@property (nonatomic, strong)MASConstraint *chipsHeightConstraint;
@property (nonatomic, strong) NSArray<UIButton *> *chipButtons;

@property (nonatomic, strong) UIButton *saveBtn;

// Data
@property (nonatomic, strong) NSDate *birthDate;
@property (nonatomic, strong) NSDate *firstMatchDate;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, assign) BOOL avatarNeedsUpload;
/// 选完照片后立即上传，成功后缓存 objectKey，onSave 时直接使用
@property (nonatomic, copy, nullable) NSString *uploadedAvatarKey;
@end

@implementation PersonalInfoViewController

- (void)viewDidLoad {
    self.hidesBottomBarWhenPushed = YES;
    [super viewDidLoad];
    self.shouldShowNavigationBar = NO;
    self.view.backgroundColor = kPIBg;
    self.birthDate = [NSDate date];
    self.firstMatchDate = [NSDate date];
    self.avatarNeedsUpload = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadProfileFromServer];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.topGradientLayer && self.gradientHostView) {
        self.topGradientLayer.frame = self.gradientHostView.bounds;
    }
    [self layoutChips];
}

- (void)setupUI {
    self.gradientHostView = [UIView new];
    self.gradientHostView.userInteractionEnabled = NO;
    [self.view insertSubview:self.gradientHostView atIndex:0];
    [self.gradientHostView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
        make.height.mas_equalTo(kPITopGradientH);
    }];
    self.topGradientLayer = [CAGradientLayer layer];
    self.topGradientLayer.colors = @[(id)[UIColor whiteColor].CGColor, (id)kPIBg.CGColor];
    self.topGradientLayer.startPoint = CGPointMake(0.5, 0);
    self.topGradientLayer.endPoint = CGPointMake(0.5, 1);
    [self.gradientHostView.layer addSublayer:self.topGradientLayer];

    self.navBar = [UIView new];
    self.navBar.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.navBar];
    [self.navBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.leading.trailing.equalTo(self.view);
        make.height.mas_equalTo(44);
    }];

    UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *backImg = [UIImage imageNamed:@"nav_back"];
    if (!backImg) {
        backImg = [UIImage imageNamed:@"ad_left"];
    }
    if (!backImg && @available(iOS 13.0, *)) {
        backImg = [UIImage systemImageNamed:@"arrow.left"];
    }
    if (backImg) {
        [back setImage:[backImg imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        back.tintColor = [UIColor blackColor];
    }
    back.imageView.contentMode = UIViewContentModeScaleAspectFit;
    back.adjustsImageWhenHighlighted = NO;
    [back addTarget:self action:@selector(onBack) forControlEvents:UIControlEventTouchUpInside];
    [self.navBar addSubview:back];
    /// Figma：Arrow 容器 left=16、24×24（非 44 热区，避免箭头视觉比卡片更靠右）
    [back mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.navBar).offset(kPIFigmaHorizontalInset);
        make.centerY.equalTo(self.navBar);
        make.size.mas_equalTo(CGSizeMake(24, 24));
    }];

    self.navTitle = [UILabel new];
    self.navTitle.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    self.navTitle.textColor = [UIColor blackColor];
    [self.navBar addSubview:self.navTitle];
    [self.navTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.navBar);
        make.centerY.equalTo(self.navBar);
    }];

    self.saveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.saveBtn.backgroundColor = kPIGreen;
    self.saveBtn.layer.cornerRadius = 26;
    self.saveBtn.layer.shadowColor = [UIColor blackColor].CGColor;
    self.saveBtn.layer.shadowOpacity = 0.19f;
    self.saveBtn.layer.shadowOffset = CGSizeMake(0, 2);
    self.saveBtn.layer.shadowRadius = 4;
    self.saveBtn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [self.saveBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.saveBtn addTarget:self action:@selector(onSave) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.saveBtn];
    [self.saveBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.view).offset(kPIFigmaHorizontalInset);
        make.trailing.equalTo(self.view).offset(-kPIFigmaHorizontalInset);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-12);
        make.height.mas_equalTo(52);
    }];

    self.scrollView = [UIScrollView new];
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.backgroundColor = [UIColor clearColor];
    if (@available(iOS 11.0, *)) {
        self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [self.view addSubview:self.scrollView];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.navBar.mas_bottom);
        make.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(self.saveBtn.mas_top).offset(-12);
    }];

    self.content = [UIView new];
    [self.scrollView addSubview:self.content];
    [self.content mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
    }];

    // Avatar card
    self.avatarCard = [self makeCard];
    [self.content addSubview:self.avatarCard];
    [self.avatarCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.content).offset(12);
        make.leading.equalTo(self.content).offset(kPIFigmaHorizontalInset);
        make.trailing.equalTo(self.content).offset(-kPIFigmaHorizontalInset);
        make.height.mas_equalTo(110);
    }];

    self.avatarLeftLabel = [UILabel new];
    self.avatarLeftLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.avatarLeftLabel.textColor = kPILabel;
    self.avatarLeftLabel.textAlignment = NSTextAlignmentLeft;
    [self.avatarCard addSubview:self.avatarLeftLabel];
    [self.avatarLeftLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.avatarCard).offset(16);
        make.centerY.equalTo(self.avatarCard);
    }];

    self.avatarView = [UIImageView new];
    self.avatarView.layer.cornerRadius = 40;
    self.avatarView.clipsToBounds = YES;
    self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
    if (@available(iOS 13.0, *)) {
        self.avatarView.image = [UIImage systemImageNamed:@"person.crop.circle.fill"];
        self.avatarView.tintColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    }
    [self.avatarCard addSubview:self.avatarView];
    [self.avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.avatarCard).offset(-16);
        make.centerY.equalTo(self.avatarCard);
        make.size.mas_equalTo(CGSizeMake(80, 80));
    }];

    self.cameraBadge = [UIImageView new];
    self.cameraBadge.contentMode = UIViewContentModeScaleAspectFit;
    self.cameraBadge.image = [UIImage imageNamed:@"setting_photo"];
    [self.avatarCard addSubview:self.cameraBadge];
    {
        CGFloat r = 40.f;
        CGFloat d = (CGFloat)(r / sqrt(2.0));
        [self.cameraBadge mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.avatarView.mas_centerX).offset(d);
            make.centerY.equalTo(self.avatarView.mas_centerY).offset(d);
            make.size.mas_equalTo(CGSizeMake(24, 24));
        }];
    }

    UITapGestureRecognizer *avatarTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onAvatarTapped)];
    self.avatarCard.userInteractionEnabled = YES;
    [self.avatarCard addGestureRecognizer:avatarTap];

    // Tap to dismiss keyboard
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(endEditing)];
    // 不要吞掉子控件点击（否则出生日期/年份/性别点不动）
    tap.cancelsTouchesInView = NO;
    [self.scrollView addGestureRecognizer:tap];

    UIView *prev = self.avatarCard;

    // 昵称卡片（可编辑 TextField）
    self.nickCard = [self makeCard];
    [self.content addSubview:self.nickCard];
    [self.nickCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(prev.mas_bottom).offset(12);
        make.leading.trailing.equalTo(self.avatarCard);
        make.height.mas_equalTo(50);
    }];
    self.nickLeft = [self addLeftLabelToCard:self.nickCard];
    self.nickField = [self addRightTextFieldToCard:self.nickCard];
    // 昵称输入框：固定左边距为 50，右边距 16，宽度确定，避免首次成为响应者时内容显示不全
    [self.nickField mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.nickCard).offset(50);
        make.trailing.equalTo(self.nickCard).offset(-16);
        make.centerY.equalTo(self.nickCard);
    }];
    prev = self.nickCard;

    // 手机号卡片（可编辑 TextField）
    self.phoneCard = [self makeCard];
    [self.content addSubview:self.phoneCard];
    [self.phoneCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(prev.mas_bottom).offset(12);
        make.leading.trailing.equalTo(self.avatarCard);
        make.height.mas_equalTo(50);
    }];
    self.phoneLeft = [self addLeftLabelToCard:self.phoneCard];
    self.phoneField = [self addRightTextFieldToCard:self.phoneCard];
    self.phoneField.keyboardType = UIKeyboardTypePhonePad;
    self.phoneField.enabled = NO;
    prev = self.phoneCard;

    // 出生日期卡片（点击调用已有 PNPickerSheetViewController）
    self.birthCard = [self makeTapCard];
    [self.birthCard addTarget:self action:@selector(onPickBirth) forControlEvents:UIControlEventTouchUpInside];
    [self.content addSubview:self.birthCard];
    [self.birthCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(prev.mas_bottom).offset(12);
        make.leading.trailing.equalTo(self.avatarCard);
        make.height.mas_equalTo(50);
    }];
    self.birthLeft = [self addLeftLabelToCard:self.birthCard];
    self.birthValue = [self addRightValueLabelToCard:self.birthCard];
    self.birthArrow = [self addDownArrowToCard:self.birthCard];
    prev = self.birthCard;

    // 性别卡片（checkbox 单选）
    self.genderCard = [self makeCard];
    [self.content addSubview:self.genderCard];
    [self.genderCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(prev.mas_bottom).offset(12);
        make.leading.trailing.equalTo(self.avatarCard);
        make.height.mas_equalTo(50);
    }];
    self.genderLeft = [self addLeftLabelToCard:self.genderCard];
    self.maleOption = [[PICheckOption alloc] initWithTitle:@""];
    self.femaleOption = [[PICheckOption alloc] initWithTitle:@""];
    [self.maleOption addTarget:self action:@selector(onMale) forControlEvents:UIControlEventTouchUpInside];
    [self.femaleOption addTarget:self action:@selector(onFemale) forControlEvents:UIControlEventTouchUpInside];
    [self.genderCard addSubview:self.maleOption];
    [self.genderCard addSubview:self.femaleOption];
    // 按原型：右侧两项可点，固定可点击宽度，避免因为约束不足导致无交互
    [self.femaleOption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.genderCard).offset(-16);
        make.centerY.equalTo(self.genderCard);
        make.height.mas_equalTo(24);
        make.width.mas_equalTo(46);
    }];
    [self.maleOption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.femaleOption.mas_leading).offset(-18);
        make.centerY.equalTo(self.genderCard);
        make.height.equalTo(self.femaleOption);
        make.width.equalTo(self.femaleOption);
    }];
    self.maleOption.checked = YES;
    prev = self.genderCard;

    // 第一次看球年份（按原型：点击右侧下拉，调用已有 pickerview）
    self.firstCard = [self makeTapCard];
    [self.firstCard addTarget:self action:@selector(onPickFirst) forControlEvents:UIControlEventTouchUpInside];
    [self.content addSubview:self.firstCard];
    [self.firstCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(prev.mas_bottom).offset(12);
        make.leading.trailing.equalTo(self.avatarCard);
        make.height.mas_equalTo(50);
    }];
    self.firstYearLeft = [self addLeftLabelToCard:self.firstCard];
    self.firstYearValue = [self addRightValueLabelToCard:self.firstCard];
    self.firstYearArrow = [self addDownArrowToCard:self.firstCard];
    prev = self.firstCard;

    // 身份卡片（右侧箭头 + 标签多选交互）
    self.identityCard = [self makeCard];
    [self.content addSubview:self.identityCard];
    [self.identityCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(prev.mas_bottom).offset(12);
        make.leading.trailing.equalTo(self.avatarCard);
    }];
    self.identityLeft = [UILabel new];
    self.identityLeft.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    self.identityLeft.textColor = kPILabel;
    [self.identityCard addSubview:self.identityLeft];
    [self.identityLeft mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.identityCard).offset(16);
        make.top.equalTo(self.identityCard).offset(16);
    }];
    self.identityArrow = [self addRightArrowToCard:self.identityCard];
    [self.identityArrow mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.identityCard).offset(-14);
        make.centerY.equalTo(self.identityLeft);
        make.size.mas_equalTo(CGSizeMake(14, 14));
    }];

    self.chipsContainer = [UIView new];
    self.chipsContainer.backgroundColor = [UIColor clearColor];
    [self.identityCard addSubview:self.chipsContainer];
    [self.chipsContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.identityLeft.mas_bottom).offset(12);
        make.leading.equalTo(self.identityCard).offset(14);
        make.trailing.equalTo(self.identityCard).offset(-14);
    }];
    [self.chipsContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        self.chipsHeightConstraint = make.height.mas_equalTo(10);
        make.bottom.equalTo(self.identityCard).offset(-12);
    }];

    NSArray<NSString *> *chipKeys = @[
        @"profile_chip_ultras",
        @"profile_chip_fan",
        @"profile_chip_leader",
        @"profile_chip_supporters",
        @"profile_chip_curve_stand",
        @"profile_chip_ball_boy",
        @"profile_chip_staff",
        @"profile_chip_media",
        @"profile_chip_art",
        @"profile_chip_rescue",
        @"profile_chip_athlete"
    ];
    NSMutableArray *btns = [NSMutableArray array];
    for (NSInteger i = 0; i < chipKeys.count; i++) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
        b.tag = i;
        b.layer.cornerRadius = 14;
        b.layer.borderWidth = 1;
        b.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        [b setTitleColor:[UIColor colorWithWhite:0.45 alpha:1.0] forState:UIControlStateNormal];
        b.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1.0].CGColor;
        b.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1.0];
        [b addTarget:self action:@selector(onChipTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.chipsContainer addSubview:b];
        [btns addObject:b];
    }
    self.chipButtons = btns;
    // Localized chip titles set in updateLocalizedStrings
    (void)chipKeys;

    [self.identityCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.chipsContainer.mas_bottom).offset(12);
    }];

    [self.content mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.identityCard.mas_bottom).offset(24);
    }];
}

- (void)layoutChips {
    if (self.chipButtons.count == 0) return;
    CGFloat maxW = self.chipsContainer.bounds.size.width;
    if (maxW <= 0) return;

    CGFloat x = 0;
    CGFloat y = 0;
    CGFloat h = 28;
    CGFloat gapX = 10;
    CGFloat gapY = 10;

    for (UIButton *b in self.chipButtons) {
        NSString *t = [b titleForState:UIControlStateNormal] ?: @"";
        CGSize sz = [t sizeWithAttributes:@{NSFontAttributeName: b.titleLabel.font}];
        CGFloat w = MIN(maxW, ceil(sz.width) + 22);
        if (x + w > maxW) {
            x = 0;
            y += h + gapY;
        }
        b.frame = CGRectMake(x, y, w, h);
        x += w + gapX;
    }
    CGFloat totalH = y + h;
    self.chipsHeightConstraint.offset = totalH;
}

- (UIView *)makeCard {
    UIView *v = [UIView new];
    v.backgroundColor = kPICardBg;
    v.layer.cornerRadius = kPICardCorner;
    v.clipsToBounds = YES;
    return v;
}

// Helpers for cards
- (UIControl *)makeTapCard {
    UIControl *c = [UIControl new];
    c.backgroundColor = kPICardBg;
    c.layer.cornerRadius = kPICardCorner;
    c.clipsToBounds = YES;
    return c;
}

- (UILabel *)addLeftLabelToCard:(UIView *)card {
    UILabel *l = [UILabel new];
    l.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    l.textColor = kPILabel;
    [card addSubview:l];
    [l mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(card).offset(16);
        make.centerY.equalTo(card);
    }];
    return l;
}

- (UILabel *)addRightValueLabelToCard:(UIView *)card {
    UILabel *v = [UILabel new];
    v.font = [UIFont systemFontOfSize:14];
    v.textColor = [UIColor blackColor];
    v.textAlignment = NSTextAlignmentRight;
    [card addSubview:v];
    [v mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(card).offset(-34);
        make.centerY.equalTo(card);
        make.leading.greaterThanOrEqualTo(card).offset(120);
    }];
    return v;
}

- (UITextField *)addRightTextFieldToCard:(UIView *)card {
    UITextField *f = [UITextField new];
    f.font = [UIFont systemFontOfSize:14];
    f.textColor = [UIColor blackColor];
    f.textAlignment = NSTextAlignmentRight;
    f.delegate = self;
    f.clearButtonMode = UITextFieldViewModeWhileEditing;
    [card addSubview:f];
    [f mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(card).offset(-16);
        make.centerY.equalTo(card);
        make.leading.greaterThanOrEqualTo(card).offset(120);
    }];
    return f;
}

- (UIImageView *)addDownArrowToCard:(UIView *)card {
    UIImageView *img = [UIImageView new];
    img.contentMode = UIViewContentModeScaleAspectFit;
    img.image = [UIImage imageNamed:@"setting_down"];
    [card addSubview:img];
    [img mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(card).offset(-14);
        make.centerY.equalTo(card);
        make.size.mas_equalTo(CGSizeMake(14, 14));
    }];
    return img;
}

- (UIImageView *)addRightArrowToCard:(UIView *)card {
    UIImageView *img = [UIImageView new];
    img.contentMode = UIViewContentModeScaleAspectFit;
    img.image = [UIImage imageNamed:@"setting_right"];
    [card addSubview:img];
    [img mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(card).offset(-14);
        make.centerY.equalTo(card);
        make.size.mas_equalTo(CGSizeMake(14, 14));
    }];
    return img;
}

- (void)setChipSelected:(UIButton *)b selected:(BOOL)selected {
    if (selected) {
        b.backgroundColor = [UIColor colorWithRed:0.90 green:0.96 blue:0.94 alpha:1.0];
        b.layer.borderColor = kPIGreen.CGColor;
        [b setTitleColor:kPIGreen forState:UIControlStateNormal];
    } else {
        b.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1.0];
        b.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1.0].CGColor;
        [b setTitleColor:[UIColor colorWithWhite:0.45 alpha:1.0] forState:UIControlStateNormal];
    }
}

- (void)onChipTapped:(UIButton *)sender {
    // 多选：单个 toggle
    BOOL isSelected = CGColorEqualToColor(sender.layer.borderColor, kPIGreen.CGColor);
    [self setChipSelected:sender selected:!isSelected];
}

- (void)onMale { self.maleOption.checked = YES; self.femaleOption.checked = NO; }
- (void)onFemale { self.maleOption.checked = NO; self.femaleOption.checked = YES; }

- (void)endEditing { [self.view endEditing:YES]; }

- (void)reloadProfileFromServer {
    if (!AuthManager.sharedManager.isLoggedIn) return;
    __weak typeof(self) weakSelf = self;
    [[UserRequest shared] getLoginUserInfoSuccess:^(HTTPResponse * _Nullable responseObject) {
        UserProfile *p = [responseObject.dataObject isKindOfClass:[UserProfile class]] ? responseObject.dataObject : AuthManager.sharedManager.user.profile;
        [weakSelf applyUserProfile:p];
    } failure:^(NSError * _Nonnull error) {
        NSString *msg = error.localizedDescription.length ? error.localizedDescription : NSLocalizedString(@"profile_save_fail", nil);
        [weakSelf showToast:msg];
    }];
}

- (nullable NSDate *)dateFromAPIBirthString:(NSString *)s {
    if (s.length == 0) return nil;
    NSDateFormatter *f = [[NSDateFormatter alloc] init];
    f.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    NSArray<NSString *> *fmts = @[ @"yyyy-MM-dd", @"yyyy-MM-dd'T'HH:mm:ss.SSSZ", @"yyyy/MM/dd" ];
    for (NSString *fmt in fmts) {
        f.dateFormat = fmt;
        NSDate *d = [f dateFromString:s];
        if (d) return d;
    }
    return nil;
}

- (void)applyUserProfile:(UserProfile *)p {
    if (!p) return;
    self.nickField.text = p.nickname ?: @"";
    NSString *ph = p.phone;
    if (ph.length == 0) ph = AuthManager.sharedManager.user.phone;
    self.phoneField.text = ph ?: @"";

    NSDate *bd = [self dateFromAPIBirthString:p.birthDate];
    if (bd) self.birthDate = bd;
    self.birthValue.text = [self formatDate:self.birthDate ?: [NSDate date]];

    if (p.gender == UserGenderMale) {
        self.maleOption.checked = YES;
        self.femaleOption.checked = NO;
    } else if (p.gender == UserGenderFemale) {
        self.maleOption.checked = NO;
        self.femaleOption.checked = YES;
    }

    if (p.firstWatchYear.length) {
        NSDate *fd = [self dateFromAPIBirthString:p.firstWatchYear];
        if (!fd && p.firstWatchYear.length >= 4) {
            NSInteger y = [[p.firstWatchYear substringToIndex:4] integerValue];
            if (y > 1900) {
                NSDateComponents *c = [[NSDateComponents alloc] init];
                c.calendar = [NSCalendar currentCalendar];
                c.year = (NSInteger)y;
                c.month = 1;
                c.day = 1;
                fd = c.date;
            }
        }
        if (fd) self.firstMatchDate = fd;
    }
    self.firstYearValue.text = [self formatDate:self.firstMatchDate ?: [NSDate date]];

    NSArray *tags = [p.preferenceTags isKindOfClass:[NSArray class]] ? p.preferenceTags : @[];
    NSArray<NSString *> *keys = kProfileChipTagKeys();
    for (NSInteger i = 0; i < (NSInteger)self.chipButtons.count && i < (NSInteger)keys.count; i++) {
        NSString *key = keys[i];
        BOOL on = NO;
        for (id o in tags) {
            if ([o isKindOfClass:[NSString class]] && [key caseInsensitiveCompare:(NSString *)o] == NSOrderedSame) {
                on = YES;
                break;
            }
        }
        [self setChipSelected:self.chipButtons[i] selected:on];
    }
    if (tags.count == 0 && self.chipButtons.count > 7) {
        [self setChipSelected:self.chipButtons[1] selected:YES];
        [self setChipSelected:self.chipButtons[7] selected:YES];
    }
    [self layoutChips];

    if (p.avatar.length > 0) {
        NSURL *url = [NSURL URLWithString:p.avatar];
        __weak typeof(self) weakSelf = self;
        [self.avatarView sd_setImageWithURL:url placeholderImage:self.avatarView.image completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            if (image) weakSelf.avatarNeedsUpload = NO;
        }];
    } else {
        if (@available(iOS 13.0, *)) {
            self.avatarView.image = [UIImage systemImageNamed:@"person.crop.circle.fill"];
            self.avatarView.tintColor = [UIColor colorWithWhite:0.6 alpha:1.0];
        }
    }
}

- (UserProfile *)buildProfileForSave {
    UserProfile *cur = AuthManager.sharedManager.user.profile;
    UserProfile *p = nil;
    if (cur) {
        NSDictionary *json = [cur yy_modelToJSONObject];
        if ([json isKindOfClass:[NSDictionary class]]) {
            p = [UserProfile yy_modelWithJSON:json];
        }
    }
    if (!p) p = [[UserProfile alloc] init];

    p.nickname = [self.nickField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    p.phone = self.phoneField.text;

    p.gender = self.maleOption.checked ? UserGenderMale : UserGenderFemale;

    NSDateFormatter *apiFmt = [[NSDateFormatter alloc] init];
    apiFmt.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    apiFmt.dateFormat = @"yyyy-MM-dd";
    p.birthDate = [apiFmt stringFromDate:self.birthDate ?: [NSDate date]];

    NSInteger y = [[NSCalendar currentCalendar] component:NSCalendarUnitYear fromDate:self.firstMatchDate ?: [NSDate date]];
    p.firstWatchYear = [NSString stringWithFormat:@"%ld", (long)y];

    NSMutableArray<NSString *> *tags = [NSMutableArray array];
    NSArray<NSString *> *keys = kProfileChipTagKeys();
    for (NSInteger i = 0; i < (NSInteger)self.chipButtons.count && i < (NSInteger)keys.count; i++) {
        UIButton *b = self.chipButtons[i];
        BOOL sel = CGColorEqualToColor(b.layer.borderColor, kPIGreen.CGColor);
        if (sel) [tags addObject:keys[i]];
    }
    p.preferenceTags = [tags copy];

    return p;
}

- (NSString *)formatDate:(NSDate *)date {
    if (!self.dateFormatter) self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.locale = [NSLocale currentLocale];
    NSString *fmt = NSLocalizedString(@"profile_date_format", nil);
    if (fmt.length == 0 || [fmt hasPrefix:@"profile_"]) {
        fmt = @"yyyy年M月d日";
    }
    self.dateFormatter.dateFormat = fmt;
    return [self.dateFormatter stringFromDate:date];
}

- (void)onPickBirth {
    [self.view endEditing:YES];
    PNPickerSheetViewController *sheet = [PNPickerSheetViewController new];
    sheet.mode = PNPickerSheetModeDate;
    sheet.selectedDate = self.birthDate ?: [NSDate date];
    sheet.minYear = 1950;
    sheet.maxYear = [[NSCalendar currentCalendar] component:NSCalendarUnitYear fromDate:[NSDate date]];
    sheet.modalPresentationStyle = UIModalPresentationOverFullScreen;
    __weak typeof(self) weakSelf = self;
    sheet.onConfirm = ^(NSDate *date) {
        weakSelf.birthDate = date;
        weakSelf.birthValue.text = [weakSelf formatDate:date];
    };
    [self presentViewController:sheet animated:NO completion:nil];
}

- (void)onPickFirst {
    [self.view endEditing:YES];
    PNPickerSheetViewController *sheet = [PNPickerSheetViewController new];
    sheet.mode = PNPickerSheetModeDate;
    sheet.selectedDate = self.firstMatchDate ?: [NSDate date];
    sheet.minYear = 1950;
    sheet.maxYear = [[NSCalendar currentCalendar] component:NSCalendarUnitYear fromDate:[NSDate date]] + 2;
    sheet.modalPresentationStyle = UIModalPresentationOverFullScreen;
    __weak typeof(self) weakSelf = self;
    sheet.onConfirm = ^(NSDate *date) {
        weakSelf.firstMatchDate = date;
        weakSelf.firstYearValue.text = [weakSelf formatDate:date];
    };
    [self presentViewController:sheet animated:NO completion:nil];
}

#pragma mark - Avatar

- (void)onAvatarTapped {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;

    [sheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"profile_avatar_camera", @"拍照") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [weakSelf openImagePickerWithSource:UIImagePickerControllerSourceTypeCamera];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"profile_avatar_album", @"从相册选择") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [weakSelf openImagePickerWithSource:UIImagePickerControllerSourceTypePhotoLibrary];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"cancel", @"取消") style:UIAlertActionStyleCancel handler:nil]];

    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)openImagePickerWithSource:(UIImagePickerControllerSourceType)source {
    if (![UIImagePickerController isSourceTypeAvailable:source]) {
        [self showToast:NSLocalizedString(@"profile_avatar_unavailable", @"该功能不可用")];
        return;
    }
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = source;
    picker.allowsEditing = YES;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    UIImage *image = info[UIImagePickerControllerEditedImage] ?: info[UIImagePickerControllerOriginalImage];
    NSLog(@"[AvatarDebug] picker finished, editedImage=%@, originalImage=%@, image=%@",
          info[UIImagePickerControllerEditedImage] ? @"YES" : @"nil",
          info[UIImagePickerControllerOriginalImage] ? @"YES" : @"nil",
          image ? [NSString stringWithFormat:@"%.0fx%.0f", image.size.width, image.size.height] : @"nil");
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (!image) return;

    self.avatarView.image = image;
    self.avatarNeedsUpload = YES;
    NSLog(@"[AvatarDebug] avatarNeedsUpload set to YES, image size=%.0fx%.0f", image.size.width, image.size.height);
    // 选完照片立即上传，不等用户点保存
    [self uploadAvatarImage:image];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)uploadAvatarImage:(UIImage *)image {
    NSData *jpeg = UIImageJPEGRepresentation(image, 0.85);
    if (jpeg.length == 0) {
        NSData *png = UIImagePNGRepresentation(image);
        if (png.length > 0) {
            jpeg = UIImageJPEGRepresentation([UIImage imageWithData:png], 0.85);
        }
    }
    if (jpeg.length == 0) {
        NSLog(@"[AvatarDebug] uploadAvatarImage: jpeg data empty, skip");
        return;
    }
    NSLog(@"[AvatarDebug] uploadAvatarImage: start upload, jpegLength=%lu", (unsigned long)jpeg.length);
    // 显示上传中提示
    [[LoadingManager sharedManager] showLoadingInView:self.view];
    __weak typeof(self) weakSelf = self;
    [[FileRequest shared] uploadImage:jpeg type:ImageObjectTypeProfile success:^(HTTPResponse * _Nullable responseObject) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        NSString *key = [responseObject.dataObject isKindOfClass:[NSString class]] ? responseObject.dataObject : nil;
        NSLog(@"[AvatarDebug] uploadAvatarImage: success, key=%@", key ?: @"nil");
        [[LoadingManager sharedManager] hideLoadingInView:self.view];
        if (key.length > 0) {
            self.uploadedAvatarKey = key;
            self.avatarNeedsUpload = NO; // 已上传，onSave 时直接用缓存的 key
        } else {
            [[LoadingManager sharedManager] showError:@"头像上传失败，请重试" inView:self.view];
        }
    } failure:^(NSError * _Nonnull error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        NSLog(@"[AvatarDebug] uploadAvatarImage: failed, error=%@", error);
        [[LoadingManager sharedManager] hideLoadingInView:self.view];
        [[LoadingManager sharedManager] showError:@"头像上传失败，请重试" inView:self.view];
        // 上传失败，保留 avatarNeedsUpload=YES，onSave 时重试
    }];
}

- (void)onBack { [self.navigationController popViewControllerAnimated:YES]; }

- (void)onSave {
    if (!AuthManager.sharedManager.isLoggedIn) {
        [self showToast:@"请先登录"];
        return;
    }
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    UserProfile *p = [self buildProfileForSave];
    __weak typeof(self) weakSelf = self;

    void (^putProfile)(void) = ^{
        void (^afterSaveOK)(void) = ^{
            // 不直接用 p.avatar（可能是 objectKey），等服务端返回签名 URL 后再更新本地
            [[UserRequest shared] getLoginUserInfoSuccess:^(HTTPResponse * _Nullable r2) {
                // getLoginUserInfoSuccess 内部已更新 AuthManager.sharedManager.user.profile
                if (p.nickname.length > 0) {
                    AuthManager.sharedManager.user.nickname = p.nickname;
                }
                if (p.phone.length > 0) {
                    AuthManager.sharedManager.user.phone = p.phone;
                }
                [AuthManager.sharedManager saveUser];
                [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
                weakSelf.avatarNeedsUpload = NO;
                [weakSelf.navigationController popViewControllerAnimated:YES];
                [[LoadingManager sharedManager] showSuccess:NSLocalizedString(@"profile_save_success", nil)];
            } failure:^(NSError * _Nonnull error) {
                // 拉取失败时用本地数据兜底，但 avatar 保留原来的签名 URL
                UserProfile *cur = AuthManager.sharedManager.user.profile;
                if (cur) {
                    cur.nickname = p.nickname;
                    cur.gender = p.gender;
                    cur.birthDate = p.birthDate;
                    cur.firstWatchYear = p.firstWatchYear;
                    cur.preferenceTags = p.preferenceTags;
                    // 不覆盖 cur.avatar，保留原来的签名 URL
                }
                if (p.nickname.length > 0) AuthManager.sharedManager.user.nickname = p.nickname;
                if (p.phone.length > 0) AuthManager.sharedManager.user.phone = p.phone;
                [AuthManager.sharedManager saveUser];
                [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
                weakSelf.avatarNeedsUpload = NO;
                [weakSelf.navigationController popViewControllerAnimated:YES];
                [[LoadingManager sharedManager] showSuccess:NSLocalizedString(@"profile_save_success", nil)];
            }];
        };
        [[UserRequest shared] updateUserInfo:p success:^(HTTPResponse * _Nullable responseObject) {
            afterSaveOK();
        } failure:^(NSError * _Nonnull error) {
            [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
            NSString *msg = error.localizedDescription.length ? error.localizedDescription : NSLocalizedString(@"profile_save_fail", @"保存失败");
            [[LoadingManager sharedManager] showError:msg inView:weakSelf.view];
        }];
    };

    if (self.uploadedAvatarKey.length > 0) {
        // 已提前上传成功，直接用缓存的 objectKey
        NSLog(@"[AvatarDebug] onSave: using cached uploadedAvatarKey=%@", self.uploadedAvatarKey);
        p.avatar = self.uploadedAvatarKey;
        putProfile();
        return;
    }

    if (self.avatarNeedsUpload) {
        UIImage *avatarImage = self.avatarView.image;
        NSData *jpeg = UIImageJPEGRepresentation(avatarImage, 0.85);
        NSLog(@"[AvatarDebug] onSave: avatarNeedsUpload=YES, image=%@, jpegLength=%lu",
              avatarImage ? [NSString stringWithFormat:@"%.0fx%.0f", avatarImage.size.width, avatarImage.size.height] : @"nil",
              (unsigned long)jpeg.length);
        // 如果 JPEG 转换失败，尝试 PNG 再转 JPEG
        if (jpeg.length == 0 && avatarImage) {
            NSData *png = UIImagePNGRepresentation(avatarImage);
            if (png.length > 0) {
                UIImage *fromPNG = [UIImage imageWithData:png];
                jpeg = UIImageJPEGRepresentation(fromPNG, 0.85);
            }
            NSLog(@"[AvatarDebug] PNG fallback jpegLength=%lu", (unsigned long)jpeg.length);
        }
        if (jpeg.length > 0) {
            NSLog(@"[AvatarDebug] starting OSS upload, jpegLength=%lu", (unsigned long)jpeg.length);
            [[FileRequest shared] uploadImage:jpeg type:ImageObjectTypeProfile success:^(HTTPResponse * _Nullable responseObject) {
                NSString *url = [responseObject.dataObject isKindOfClass:[NSString class]] ? responseObject.dataObject : nil;
                NSLog(@"[AvatarDebug] OSS upload success, url=%@", url ?: @"nil");
                if (url.length == 0) {
                    [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
                    [[LoadingManager sharedManager] showError:NSLocalizedString(@"profile_avatar_upload_fail", nil) ?: @"头像上传失败，请重试" inView:weakSelf.view];
                    return;
                }
                p.avatar = url;
                putProfile();
            } failure:^(NSError * _Nonnull error) {
                NSLog(@"[AvatarDebug] OSS upload failed: %@", error);
                [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
                NSString *msg = error.localizedDescription.length ? error.localizedDescription : (NSLocalizedString(@"profile_avatar_upload_fail", nil) ?: @"头像上传失败，请重试");
                [[LoadingManager sharedManager] showError:msg inView:weakSelf.view];
            }];
            return;
        } else {
            // 图片数据为空，提示用户重新选择
            [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
            [[LoadingManager sharedManager] showError:@"头像图片无效，请重新选择" inView:weakSelf.view];
            return;
        }
    }
    NSLog(@"[AvatarDebug] onSave: avatarNeedsUpload=NO, skip upload");
    putProfile();
}

- (void)showToast:(NSString *)message {
    if (message.length == 0) return;
    [[LoadingManager sharedManager] showText:message];
}

- (void)updateLocalizedStrings {
    [super updateLocalizedStrings];
    self.navTitle.text = NSLocalizedString(@"profile_personal_title", nil);
    self.avatarLeftLabel.text = NSLocalizedString(@"profile_upload_avatar", nil);

    self.nickLeft.text = NSLocalizedString(@"profile_nickname", nil);
    self.phoneLeft.text = NSLocalizedString(@"profile_phone", nil);
    self.birthLeft.text = NSLocalizedString(@"profile_birthdate", nil);
    self.genderLeft.text = NSLocalizedString(@"profile_gender", nil);
    self.firstYearLeft.text = NSLocalizedString(@"profile_first_match_year", nil);
    self.identityLeft.text = NSLocalizedString(@"profile_identity", nil);

    self.maleOption.titleLabel.text = NSLocalizedString(@"profile_gender_male", nil);
    self.femaleOption.titleLabel.text = NSLocalizedString(@"profile_gender_female", nil);

    [self.saveBtn setTitle:NSLocalizedString(@"profile_save", nil) forState:UIControlStateNormal];

    NSArray<NSString *> *chipTitles = @[
        NSLocalizedString(@"profile_chip_ultras", nil),
        NSLocalizedString(@"profile_chip_fan", nil),
        NSLocalizedString(@"profile_chip_leader", nil),
        NSLocalizedString(@"profile_chip_supporters", nil),
        NSLocalizedString(@"profile_chip_curve_stand", nil),
        NSLocalizedString(@"profile_chip_ball_boy", nil),
        NSLocalizedString(@"profile_chip_staff", nil),
        NSLocalizedString(@"profile_chip_media", nil),
        NSLocalizedString(@"profile_chip_art", nil),
        NSLocalizedString(@"profile_chip_rescue", nil),
        NSLocalizedString(@"profile_chip_athlete", nil),
    ];
    for (NSInteger i = 0; i < self.chipButtons.count && i < chipTitles.count; i++) {
        [self.chipButtons[i] setTitle:chipTitles[i] forState:UIControlStateNormal];
    }
    [self layoutChips];

    // Refresh date labels
    self.birthValue.text = [self formatDate:self.birthDate ?: [NSDate date]];
    self.firstYearValue.text = [self formatDate:self.firstMatchDate ?: [NSDate date]];
}

@end

