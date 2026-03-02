//
//  PersonalInfoViewController.m
//  footBall
//

#import "PersonalInfoViewController.h"
#import "PNPickerSheetViewController.h"
#import <Masonry/Masonry.h>

#define kPIBg      [UIColor colorWithWhite:0.95 alpha:1.0]
#define kPICardBg  [UIColor whiteColor]
#define kPIGreen   [UIColor colorWithRed:0.10 green:0.36 blue:0.28 alpha:1.0]

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
@property (nonatomic, strong) UIView *navBar;
@property (nonatomic, strong) UILabel *navTitle;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *content;

@property (nonatomic, strong) UIView *avatarCard;
@property (nonatomic, strong) UILabel *avatarLeftLabel;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UIView *cameraBadge;

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
@end

@implementation PersonalInfoViewController

- (void)viewDidLoad {
    self.hidesBottomBarWhenPushed = YES;
    [super viewDidLoad];
    self.shouldShowNavigationBar = NO;
    self.view.backgroundColor = kPIBg;

    // Fake data
    self.birthDate = [NSDate dateWithTimeIntervalSince1970: (NSTimeInterval) 628214400]; // 1990-12-03 (UTC-ish)
    self.firstMatchDate = self.birthDate;

    [self loadLocalAvatar];
}

- (void)setupUI {
    // Nav
    self.navBar = [UIView new];
    self.navBar.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.navBar];
    [self.navBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
        make.height.mas_equalTo(88);
    }];

    UIButton *back = [UIButton buttonWithType:UIButtonTypeSystem];
    if (@available(iOS 13.0, *)) {
        [back setImage:[UIImage systemImageNamed:@"arrow.left"] forState:UIControlStateNormal];
    }
    back.tintColor = [UIColor blackColor];
    [back addTarget:self action:@selector(onBack) forControlEvents:UIControlEventTouchUpInside];
    [self.navBar addSubview:back];
    [back mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.navBar).offset(12);
        make.bottom.equalTo(self.navBar).offset(-10);
        make.size.mas_equalTo(CGSizeMake(36, 36));
    }];

    self.navTitle = [UILabel new];
    self.navTitle.font = [UIFont boldSystemFontOfSize:17];
    self.navTitle.textColor = [UIColor blackColor];
    [self.navBar addSubview:self.navTitle];
    [self.navTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.navBar);
        make.centerY.equalTo(back);
    }];

    // Scroll
    self.scrollView = [UIScrollView new];
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.backgroundColor = kPIBg;
    if (@available(iOS 11.0, *)) {
        self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [self.view addSubview:self.scrollView];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.navBar.mas_bottom);
        make.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];

    self.content = [UIView new];
    [self.scrollView addSubview:self.content];
    [self.content mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
    }];

    // Save button (fixed bottom)
    self.saveBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    self.saveBtn.backgroundColor = kPIGreen;
    self.saveBtn.layer.cornerRadius = 22;
    self.saveBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [self.saveBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.saveBtn addTarget:self action:@selector(onSave) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.saveBtn];
    [self.saveBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.view).offset(20);
        make.trailing.equalTo(self.view).offset(-20);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-10);
        make.height.mas_equalTo(44);
    }];

    // Make content bottom above saveBtn
    [self.content mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.scrollView).offset(-80);
    }];

    // Avatar card
    self.avatarCard = [self makeCard];
    [self.content addSubview:self.avatarCard];
    [self.avatarCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.content).offset(12);
        make.leading.equalTo(self.content).offset(12);
        make.trailing.equalTo(self.content).offset(-12);
        make.height.mas_equalTo(70);
    }];

    self.avatarLeftLabel = [UILabel new];
    self.avatarLeftLabel.font = [UIFont systemFontOfSize:14];
    self.avatarLeftLabel.textColor = [UIColor darkGrayColor];
    self.avatarLeftLabel.textAlignment = NSTextAlignmentLeft;
    [self.avatarCard addSubview:self.avatarLeftLabel];
    [self.avatarLeftLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.avatarCard).offset(16);
        make.centerY.equalTo(self.avatarCard);
    }];

    self.avatarView = [UIImageView new];
    self.avatarView.layer.cornerRadius = 26;
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
        make.size.mas_equalTo(CGSizeMake(52, 52));
    }];

    self.cameraBadge = [UIView new];
    self.cameraBadge.backgroundColor = [UIColor blackColor];
    self.cameraBadge.layer.cornerRadius = 10;
    self.cameraBadge.clipsToBounds = YES;
    [self.avatarCard addSubview:self.cameraBadge];
    [self.cameraBadge mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.avatarView).offset(2);
        make.bottom.equalTo(self.avatarView).offset(2);
        make.size.mas_equalTo(CGSizeMake(20, 20));
    }];
    UIImageView *cam = [UIImageView new];
    if (@available(iOS 13.0, *)) {
        cam.image = [UIImage systemImageNamed:@"camera.fill"];
        cam.tintColor = [UIColor whiteColor];
    }
    cam.contentMode = UIViewContentModeScaleAspectFit;
    [self.cameraBadge addSubview:cam];
    [cam mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.cameraBadge);
        make.size.mas_equalTo(CGSizeMake(12, 12));
    }];

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
        make.top.equalTo(prev.mas_bottom).offset(10);
        make.leading.trailing.equalTo(self.avatarCard);
        make.height.mas_equalTo(52);
    }];
    self.nickLeft = [self addLeftLabelToCard:self.nickCard];
    self.nickField = [self addRightTextFieldToCard:self.nickCard];
    self.nickField.text = @"Arisha Ireen";
    prev = self.nickCard;

    // 手机号卡片（可编辑 TextField）
    self.phoneCard = [self makeCard];
    [self.content addSubview:self.phoneCard];
    [self.phoneCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(prev.mas_bottom).offset(10);
        make.leading.trailing.equalTo(self.avatarCard);
        make.height.mas_equalTo(52);
    }];
    self.phoneLeft = [self addLeftLabelToCard:self.phoneCard];
    self.phoneField = [self addRightTextFieldToCard:self.phoneCard];
    self.phoneField.text = @"135 6090 8897";
    self.phoneField.keyboardType = UIKeyboardTypePhonePad;
    prev = self.phoneCard;

    // 出生日期卡片（点击调用已有 PNPickerSheetViewController）
    self.birthCard = [self makeTapCard];
    [self.birthCard addTarget:self action:@selector(onPickBirth) forControlEvents:UIControlEventTouchUpInside];
    [self.content addSubview:self.birthCard];
    [self.birthCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(prev.mas_bottom).offset(10);
        make.leading.trailing.equalTo(self.avatarCard);
        make.height.mas_equalTo(52);
    }];
    self.birthLeft = [self addLeftLabelToCard:self.birthCard];
    self.birthValue = [self addRightValueLabelToCard:self.birthCard];
    self.birthArrow = [self addDownArrowToCard:self.birthCard];
    prev = self.birthCard;

    // 性别卡片（checkbox 单选）
    self.genderCard = [self makeCard];
    [self.content addSubview:self.genderCard];
    [self.genderCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(prev.mas_bottom).offset(10);
        make.leading.trailing.equalTo(self.avatarCard);
        make.height.mas_equalTo(52);
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
        make.top.equalTo(prev.mas_bottom).offset(10);
        make.leading.trailing.equalTo(self.avatarCard);
        make.height.mas_equalTo(52);
    }];
    self.firstYearLeft = [self addLeftLabelToCard:self.firstCard];
    self.firstYearValue = [self addRightValueLabelToCard:self.firstCard];
    self.firstYearArrow = [self addDownArrowToCard:self.firstCard];
    prev = self.firstCard;

    // 身份卡片（右侧箭头 + 标签多选交互）
    self.identityCard = [self makeCard];
    [self.content addSubview:self.identityCard];
    [self.identityCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(prev.mas_bottom).offset(10);
        make.leading.trailing.equalTo(self.avatarCard);
    }];
    self.identityLeft = [UILabel new];
    self.identityLeft.font = [UIFont systemFontOfSize:14];
    self.identityLeft.textColor = [UIColor darkGrayColor];
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
    // 选中“媒体记者”
    if (self.chipButtons.count > 7) {
        [self setChipSelected:self.chipButtons[7] selected:YES];
    }

    // Localized chip titles set in updateLocalizedStrings
    (void)chipKeys;

    // Identity card height由 chipsContainer 决定
    [self.identityCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.chipsContainer.mas_bottom).offset(12);
    }];

    // content bottom
    [self.identityCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.lessThanOrEqualTo(self.content).offset(-20);
    }];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutChips];
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
    v.layer.cornerRadius = 12;
    v.clipsToBounds = YES;
    return v;
}

// Helpers for cards
- (UIControl *)makeTapCard {
    UIControl *c = [UIControl new];
    c.backgroundColor = kPICardBg;
    c.layer.cornerRadius = 12;
    c.clipsToBounds = YES;
    return c;
}

- (UILabel *)addLeftLabelToCard:(UIView *)card {
    UILabel *l = [UILabel new];
    l.font = [UIFont systemFontOfSize:14];
    l.textColor = [UIColor darkGrayColor];
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
    if (@available(iOS 13.0, *)) {
        img.image = [UIImage systemImageNamed:@"chevron.down"];
        img.tintColor = [UIColor colorWithWhite:0.65 alpha:1.0];
    }
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
    if (@available(iOS 13.0, *)) {
        img.image = [UIImage systemImageNamed:@"chevron.right"];
        img.tintColor = [UIColor colorWithWhite:0.65 alpha:1.0];
    }
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
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (!image) return;

    self.avatarView.image = image;
    [self saveAvatarToLocal:image];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (NSString *)avatarLocalPath {
    NSString *docs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    return [docs stringByAppendingPathComponent:@"user_avatar.jpg"];
}

- (void)saveAvatarToLocal:(UIImage *)image {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CGFloat maxSide = 512;
        UIImage *resized = image;
        if (image.size.width > maxSide || image.size.height > maxSide) {
            CGFloat scale = maxSide / MAX(image.size.width, image.size.height);
            CGSize newSize = CGSizeMake(image.size.width * scale, image.size.height * scale);
            UIGraphicsBeginImageContextWithOptions(newSize, NO, 1.0);
            [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
            resized = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
        NSData *data = UIImageJPEGRepresentation(resized, 0.85);
        [data writeToFile:[self avatarLocalPath] atomically:YES];
    });
}

- (void)loadLocalAvatar {
    NSString *path = [self avatarLocalPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        UIImage *saved = [UIImage imageWithContentsOfFile:path];
        if (saved) {
            self.avatarView.image = saved;
        }
    }
}

- (void)onBack { [self.navigationController popViewControllerAnimated:YES]; }

- (void)onSave { [self showToast:NSLocalizedString(@"profile_save_success", nil)]; }

- (void)showToast:(NSString *)message {
    UILabel *toast = [UILabel new];
    toast.text = message;
    toast.font = [UIFont systemFontOfSize:14];
    toast.textColor = [UIColor whiteColor];
    toast.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
    toast.textAlignment = NSTextAlignmentCenter;
    toast.layer.cornerRadius = 16;
    toast.clipsToBounds = YES;
    [self.view addSubview:toast];
    [toast mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.saveBtn.mas_top).offset(-14);
        make.height.mas_equalTo(36);
        make.leading.greaterThanOrEqualTo(self.view).offset(40);
        make.trailing.lessThanOrEqualTo(self.view).offset(-40);
    }];
    toast.alpha = 0;
    [UIView animateWithDuration:0.25 animations:^{ toast.alpha = 1; } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.25 animations:^{ toast.alpha = 0; } completion:^(BOOL done) {
                [toast removeFromSuperview];
            }];
        });
    }];
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

