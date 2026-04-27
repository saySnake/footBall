//
//  StampUnlockPopupViewController.m
//  footBall
//

#import "StampUnlockPopupViewController.h"
#import <Masonry/Masonry.h>

static UIColor *PNOverlayColor(void) {
    return [UIColor colorWithWhite:0 alpha:0.25];
}

static UIColor *PNMint(void) {
    return [UIColor colorWithRed:83/255.0 green:204/255.0 blue:158/255.0 alpha:1.0];
}

@interface StampUnlockPopupViewController ()
@property (nonatomic, strong) UIControl *overlayView;
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) UIControl *planLifetime;
@property (nonatomic, strong) UIControl *planYear;
@property (nonatomic, strong) UIControl *planMonth;
@property (nonatomic, strong) UIButton *moreButton;
@end

@implementation StampUnlockPopupViewController

- (instancetype)init {
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;

    self.overlayView = [[UIControl alloc] init];
    self.overlayView.backgroundColor = PNOverlayColor();
    [self.overlayView addTarget:self action:@selector(onTapOverlay) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.overlayView];

    self.cardView = [[UIView alloc] init];
    self.cardView.backgroundColor = [UIColor colorWithWhite:0.07 alpha:0.98];
    self.cardView.layer.cornerRadius = 24;
    self.cardView.clipsToBounds = YES;
    [self.view addSubview:self.cardView];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.textColor = UIColor.whiteColor;
    self.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.numberOfLines = 1;
    [self.cardView addSubview:self.titleLabel];

    self.descLabel = [[UILabel alloc] init];
    self.descLabel.textColor = [UIColor colorWithWhite:0.70 alpha:1.0];
    self.descLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    self.descLabel.textAlignment = NSTextAlignmentCenter;
    self.descLabel.numberOfLines = 0;
    [self.cardView addSubview:self.descLabel];

    self.planLifetime = [self buildPlanCardWithIcon:@"stamp_vip_forever"
                                             title:@"终身典藏"
                                          subTitle:nil
                                        subSubTitle:@"成就邮票边框"
                                             price:@"748"
                                       planIndexTag:2];
    self.planYear = [self buildPlanCardWithIcon:@"stamp_vip_annual"
                                         title:@"会员订阅"
                                      subTitle:@"连续包年"
                                    subSubTitle:@"超多特殊权益"
                                         price:@"268"
                                   planIndexTag:1];
    self.planMonth = [self buildPlanCardWithIcon:@"stamp_vip_month"
                                          title:@"会员订阅"
                                       subTitle:@"连续包月"
                                     subSubTitle:@"每天仅需 ¥1.1"
                                          price:@"33"
                                    planIndexTag:0];
    [self.cardView addSubview:self.planLifetime];
    [self.cardView addSubview:self.planYear];
    [self.cardView addSubview:self.planMonth];

    self.moreButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.moreButton.backgroundColor = [UIColor colorWithHexString:@"#53CC9E"];
    self.moreButton.layer.cornerRadius = 17.5;
    self.moreButton.clipsToBounds = YES;
    [self.moreButton setTitleColor:[UIColor colorWithHexString:@"#FFFFFF"] forState:UIControlStateNormal];
    self.moreButton.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    [self.moreButton setTitle:@"查看更多选择" forState:UIControlStateNormal];
    [self.moreButton addTarget:self action:@selector(onMoreChoices) forControlEvents:UIControlEventTouchUpInside];
    [self.cardView addSubview:self.moreButton];

    [self.overlayView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    CGFloat cardW = MIN(344, UIScreen.mainScreen.bounds.size.width - 40);
    [self.cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.width.mas_equalTo(cardW);
    }];

    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.cardView).offset(26);
        make.leading.equalTo(self.cardView).offset(20);
        make.trailing.equalTo(self.cardView).offset(-20);
    }];

    [self.descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(10);
        make.leading.equalTo(self.cardView).offset(20);
        make.trailing.equalTo(self.cardView).offset(-20);
    }];

    [self.planLifetime mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.descLabel.mas_bottom).offset(18);
        make.leading.equalTo(self.cardView).offset(18);
        make.trailing.equalTo(self.cardView).offset(-18);
        make.height.mas_equalTo(141);
    }];
    [self.planYear mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.planLifetime.mas_bottom).offset(14);
        make.leading.trailing.height.equalTo(self.planLifetime);
    }];
    [self.planMonth mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.planYear.mas_bottom).offset(14);
        make.leading.trailing.height.equalTo(self.planLifetime);
    }];
    [self.moreButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.planMonth.mas_bottom).offset(16);
        make.leading.equalTo(self.cardView).offset(28);
        make.trailing.equalTo(self.cardView).offset(-28);
        make.height.mas_equalTo(35);
        make.bottom.equalTo(self.cardView).offset(-18);
    }];

    [self applyTexts];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 入场动效：卡片从稍下方弹起
    self.overlayView.alpha = 0;
    self.cardView.alpha = 0;
    self.cardView.transform = CGAffineTransformMakeTranslation(0, 14);
    [UIView animateWithDuration:0.22 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.overlayView.alpha = 1;
        self.cardView.alpha = 1;
        self.cardView.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)setDialogTitleText:(NSString *)dialogTitleText {
    _dialogTitleText = [dialogTitleText copy];
    if (self.isViewLoaded) [self applyTexts];
}

- (void)setDialogDescText:(NSString *)dialogDescText {
    _dialogDescText = [dialogDescText copy];
    if (self.isViewLoaded) [self applyTexts];
}

- (void)applyTexts {
    self.titleLabel.text = self.dialogTitleText.length
    ? self.dialogTitleText
    : @"邮票未解锁";

    self.descLabel.text = self.dialogDescText.length
    ? self.dialogDescText
    : @"升级会员以解锁该邮票";
}

- (void)onTapOverlay {
    [self dismissAnimated:nil];
}

- (void)onClose {
    [self dismissAnimated:nil];
}

- (void)dismissAnimated:(void (^ _Nullable)(void))completion {
    [UIView animateWithDuration:0.18 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.overlayView.alpha = 0;
        self.cardView.alpha = 0;
        self.cardView.transform = CGAffineTransformMakeTranslation(0, 10);
    } completion:^(__unused BOOL finished) {
        [self dismissViewControllerAnimated:NO completion:completion];
    }];
}

- (UIControl *)buildPlanCardWithIcon:(NSString *)fallbackAsset
                              title:(NSString *)title
                           subTitle:(NSString *)subTitle
                            subSubTitle:(NSString *)subSubTitle
                              price:(NSString *)price
                        planIndexTag:(NSInteger)planIndex {
    UIControl *wrap = [[UIControl alloc] init];
    wrap.tag = planIndex;
    wrap.layer.cornerRadius = 16;
    wrap.clipsToBounds = YES;
    [wrap addTarget:self action:@selector(onTapPlan:) forControlEvents:UIControlEventTouchUpInside];

    CAGradientLayer *g = [CAGradientLayer layer];
    g.name = @"pn.plan.bg";
    g.colors = @[
        (id)[UIColor colorWithRed:0.17 green:0.40 blue:0.33 alpha:0.95].CGColor,
        (id)[UIColor colorWithRed:0.42 green:0.64 blue:0.58 alpha:0.95].CGColor
    ];
    g.startPoint = CGPointMake(0, 0.5);
    g.endPoint = CGPointMake(1, 0.5);
    [wrap.layer insertSublayer:g atIndex:0];

    UIImageView *icon = [[UIImageView alloc] init];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    icon.tintColor = [UIColor colorWithWhite:0.88 alpha:1.0];
    UIImage *img = [UIImage imageNamed:fallbackAsset];
    icon.image = img;
    [wrap addSubview:icon];

    UILabel *t = [[UILabel alloc] init];
    t.textColor = UIColor.whiteColor;
    t.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    t.text = title;
    [wrap addSubview:t];

    UILabel *sub = [[UILabel alloc] init];
    sub.textColor = [UIColor colorWithHexString:@"#FFFFFF"];
    sub.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    sub.text = subTitle;
    [wrap addSubview:sub];
    
    UILabel *subSub = [[UILabel alloc] init];
    subSub.textColor = [UIColor colorWithHexString:@"#93DDC4"];
    subSub.font = FontManager.sharedManager.font13Regular;
    subSub.numberOfLines = 2;
    subSub.text = subSubTitle;
    [wrap addSubview:subSub];

    UILabel *currency = [[UILabel alloc] init];
    currency.textColor = UIColor.whiteColor;
    currency.font = FontManager.sharedManager.font25Regular;
    currency.text = @"¥";
    [wrap addSubview:currency];

    UILabel *p = [[UILabel alloc] init];
    p.textColor = UIColor.whiteColor;
    p.font = FontManager.sharedManager.font72Regular;
    p.text = price;
    [wrap addSubview:p];

    [icon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(wrap).offset(16);
        make.top.equalTo(wrap).offset(16);
        make.width.height.mas_equalTo(22);
    }];
    [t mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(icon.mas_trailing).offset(8);
        make.centerY.equalTo(icon);
        make.trailing.lessThanOrEqualTo(p.mas_leading).offset(-10);
    }];
    [sub mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(icon);
        make.top.equalTo(icon.mas_bottom).offset(10);
        make.trailing.lessThanOrEqualTo(p.mas_leading).offset(-10);
    }];
    [subSub mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(icon);
        make.top.equalTo(sub.mas_bottom).offset(2);
        make.trailing.lessThanOrEqualTo(p.mas_leading).offset(-10);
    }];

    [p mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(wrap).offset(-18);
        make.bottom.equalTo(wrap).offset(-2);
    }];
    [currency mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(p.mas_leading).offset(-4);
        make.bottom.equalTo(p.mas_bottom).offset(-14);
    }];

    return wrap;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    for (UIControl *v in @[self.planLifetime, self.planYear, self.planMonth]) {
        if (![v isKindOfClass:UIControl.class]) continue;
        for (CALayer *ly in v.layer.sublayers) {
            if ([ly.name isEqualToString:@"pn.plan.bg"]) {
                ly.frame = v.bounds;
            }
        }
    }
}

- (void)onTapPlan:(UIControl *)sender {
    NSInteger idx = sender.tag;
    __weak typeof(self) weakSelf = self;
    [self dismissAnimated:^{
        if (weakSelf.onConfirm) {
            weakSelf.onConfirm(idx);
        }
    }];
}

- (void)onMoreChoices {
    __weak typeof(self) weakSelf = self;
    [self dismissAnimated:^{
        if (weakSelf.onConfirm) {
            weakSelf.onConfirm(0);
        }
    }];
}

@end

