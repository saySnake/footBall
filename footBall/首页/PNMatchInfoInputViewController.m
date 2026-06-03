//
//  PNMatchInfoInputViewController.m
//  footBall
//

#import "PNMatchInfoInputViewController.h"
#import <Masonry/Masonry.h>
#import <IQKeyboardManager/IQKeyboardManager.h>
#import "PNPickerSheetViewController.h"
#import "ColorManager.h"
#import "MatchRequest.h"
#import "MatchRecordModels.h"
#import "LoadingManager.h"
#import "APIError.h"

static UIColor *PNInputGreenColor(void) {
    // 统一使用 ColorManager 的主色，方便以后适配黑天/白天皮肤
    return [ColorManager sharedManager].primaryColor;
}

static UIColor *PNInputFieldBgColor(void) {
    return [UIColor colorWithRed:0.965 green:0.965 blue:0.965 alpha:1.0]; // #F6F6F6
}

static UIColor *PNInputPlaceholderColor(void) {
    return [UIColor colorWithRed:0.435 green:0.435 blue:0.435 alpha:1.0]; // #6F6F6F
}

static UIColor *PNInputPillTextColor(void) {
    return [UIColor colorWithRed:0.435 green:0.435 blue:0.435 alpha:1.0];
}

static CGFloat PNInputSectionSpacing(void) {
    return 20.0;
}

static const NSInteger kPNMaxViewingIdentityCount = 6;

NSString * const PNMatchRecordDidUpdateNotification = @"PNMatchRecordDidUpdateNotification";

static NSSet<NSString *> *PNSeatAllowedWatchLocations(void) {
    static NSSet<NSString *> *set;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        set = [NSSet setWithObjects:@"在现场", @"在球场", nil];
    });
    return set;
}

@interface PNMatchInfoInputViewController () <UITextViewDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIView *dimmingView;
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIView *dragDismissHitArea;
@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, assign) CGFloat cardDismissThreshold;
@property (nonatomic, assign) BOOL didPrepareInitialOffscreen;
@property (nonatomic, assign) BOOL didSchedulePresentAnimation;
@property (nonatomic, assign) BOOL didRunPresentAnimation;

@property (nonatomic, strong) UIButton *emotionButton;
@property (nonatomic, strong) UIView *emotionPanel;
@property (nonatomic, strong) UIImageView *emotionButtonIconView;
@property (nonatomic, strong) UIImageView *emotionButtonArrowView;
@property (nonatomic, copy) NSString *selectedEmotionName;

@property (nonatomic, strong) UITextField *matchField;
@property (nonatomic, strong) UITextField *priceField;
@property (nonatomic, strong) UIButton *dateBtn;
@property (nonatomic, strong) UIButton *timeBtn;
@property (nonatomic, strong) UITextView *commentView;
@property (nonatomic, strong) UILabel *commentCountLabel;
@property (nonatomic, strong) UILabel *commentPlaceholderLabel;

@property (nonatomic, strong) NSArray<UIButton *> *watchButtons;
@property (nonatomic, strong) UILabel *seatTitleLabel;
@property (nonatomic, strong) NSArray<UIButton *> *seatButtons;
@property (nonatomic, strong) NSArray<UIButton *> *reasonButtons;
@property (nonatomic, strong) NSArray<UIButton *> *identityButtons;

@property (nonatomic, copy) NSString *selectedEmotion;
@property (nonatomic, copy) NSString *selectedWatchInfo;
@property (nonatomic, copy) NSString *selectedSeat;
@property (nonatomic, copy) NSString *selectedReason;
@property (nonatomic, strong) NSMutableSet<NSString *> *selectedIdentities;

@property (nonatomic, strong) UILabel *headerTitleLabel;

// 记录进入页面前 IQKeyboardManager 的启用状态，方便恢复
@property (nonatomic, assign) BOOL iqPreviouslyEnabled;

// 比赛日期+时间，复用现有 PNPickerSheetViewController 的 selectedDate 逻辑
@property (nonatomic, strong) NSDate *selectedDate;
@end

@implementation PNMatchInfoInputViewController

static CGFloat PNMatchInfoDimBaseAlpha(void) {
    return 1.0;
}

- (void)pn_applyPillButton:(UIButton *)button selected:(BOOL)selected {
    button.selected = selected;
    button.layer.borderWidth = selected ? 1 : 0;
    button.layer.borderColor = selected ? PNInputGreenColor().CGColor : UIColor.clearColor.CGColor;
    button.backgroundColor = selected ? [UIColor whiteColor] : PNInputFieldBgColor();
    button.titleLabel.font = [UIFont systemFontOfSize:12 weight:(selected ? UIFontWeightMedium : UIFontWeightRegular)];
    [button setTitleColor:(selected ? PNInputGreenColor() : PNInputPillTextColor()) forState:UIControlStateNormal];
}

- (NSArray<NSDictionary<NSString *, NSString *> *> *)pn_emotionOptionsData {
    static NSArray<NSDictionary<NSString *, NSString *> *> *options = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = @[
            @{ @"name": @"兴奋", @"emoji": @"🤩", @"icon": @"team_ex" },
            @{ @"name": @"激动", @"emoji": @"🥳", @"icon": @"team_ji" },
            @{ @"name": @"希望", @"emoji": @"🤗", @"icon": @"team_hop" },
            @{ @"name": @"遗憾", @"emoji": @"😩", @"icon": @"team_ku" },
            @{ @"name": @"平静", @"emoji": @"😎", @"icon": @"team_ping" },
            @{ @"name": @"失望", @"emoji": @"😤", @"icon": @"team_shi" },
            @{ @"name": @"暴躁", @"emoji": @"😡", @"icon": @"team_angry" }
        ];
    });
    return options;
}

- (nullable NSDictionary<NSString *, NSString *> *)pn_emotionOptionForValue:(NSString *)value {
    NSString *v = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (v.length == 0) {
        return nil;
    }
    for (NSDictionary<NSString *, NSString *> *opt in [self pn_emotionOptionsData]) {
        NSString *name = opt[@"name"] ?: @"";
        NSString *emoji = opt[@"emoji"] ?: @"";
        NSString *legacy = [NSString stringWithFormat:@"%@ %@", name, emoji];
        if ([v isEqualToString:name] ||
            [v isEqualToString:emoji] ||
            [v isEqualToString:legacy] ||
            [v containsString:emoji]) {
            return opt;
        }
    }
    return nil;
}

- (void)pn_applyEmotionOption:(NSDictionary<NSString *, NSString *> *)option {
    NSString *name = option[@"name"] ?: @"";
    NSString *emoji = option[@"emoji"] ?: @"";
    NSString *iconName = option[@"icon"] ?: @"";
    self.selectedEmotionName = name;
    self.selectedEmotion = emoji;
    [self.emotionButton setTitle:(name.length > 0 ? name : @"选择情绪") forState:UIControlStateNormal];
    UIImage *icon = [UIImage imageNamed:iconName];
    self.emotionButtonIconView.image = icon ?: [UIImage imageNamed:@"team_ex"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    self.selectedIdentities = [NSMutableSet set];
    
    [self buildUI];
    [self loadInitialFormData];
}

- (void)dismissWithCardAnimation {
    UIView *card = self.cardView;
    if (!card) {
        [self dismissViewControllerAnimated:NO completion:nil];
        return;
    }
    [self.view endEditing:YES];
    self.dimmingView.userInteractionEnabled = NO;
    [self.view layoutIfNeeded];
    CGFloat h = CGRectGetHeight(card.bounds);
    if (h < 1) {
        h = 600;
    }
    [UIView animateWithDuration:0.18 animations:^{
        card.transform = CGAffineTransformMakeTranslation(0, h + 40);
        self.dimmingView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }];
}

- (void)onCardPan:(UIPanGestureRecognizer *)gr {
    UIView *card = self.cardView;
    if (!card) { return; }

    CGPoint t = [gr translationInView:self.view];
    CGFloat dy = MAX(0, t.y);

    if (gr.state == UIGestureRecognizerStateBegan) {
        [self.view endEditing:YES];
        CGFloat h = CGRectGetHeight(card.bounds);
        if (h < 1) {
            [card layoutIfNeeded];
            h = CGRectGetHeight(card.bounds);
        }
        if (h < 1) {
            h = 520;
        }
        self.cardDismissThreshold = h / 3.0;
    }

    if (gr.state == UIGestureRecognizerStateChanged) {
        card.transform = CGAffineTransformMakeTranslation(0, dy);
        CGFloat baseAlpha = PNMatchInfoDimBaseAlpha();
        CGFloat p = self.cardDismissThreshold > 0 ? MIN(1, dy / self.cardDismissThreshold) : 0;
        CGFloat a = baseAlpha * (1 - 0.9 * p);
        self.dimmingView.alpha = a;
        self.dimmingView.userInteractionEnabled = (a > 0.02);
        return;
    }

    if (gr.state == UIGestureRecognizerStateEnded || gr.state == UIGestureRecognizerStateCancelled) {
        BOOL shouldDismiss = (dy > self.cardDismissThreshold);
        if (shouldDismiss) {
            [self dismissWithCardAnimation];
        } else {
            [UIView animateWithDuration:0.22
                                  delay:0
                 usingSpringWithDamping:0.92
                  initialSpringVelocity:0.0
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                card.transform = CGAffineTransformIdentity;
                self.dimmingView.alpha = PNMatchInfoDimBaseAlpha();
            } completion:^(BOOL finished) {
                self.dimmingView.userInteractionEnabled = YES;
            }];
        }
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    // 顶部小拖动条区域需要和 scrollView 的纵向滚动手势共存
    if (otherGestureRecognizer == self.scrollView.panGestureRecognizer) {
        return YES;
    }
    return NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 关闭 IQKeyboardManager 对本页面的自动滚动和工具条干预
    IQKeyboardManager *manager = [IQKeyboardManager sharedManager];
    self.iqPreviouslyEnabled = manager.enable;
    manager.enable = NO;
    manager.enableAutoToolbar = NO;

    // 监听键盘，手动调整 scrollView，避免比赛感想被遮挡
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onKeyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onKeyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // 恢复 IQKeyboardManager 全局状态，避免影响其他页面
    IQKeyboardManager *manager = [IQKeyboardManager sharedManager];
    manager.enable = self.iqPreviouslyEnabled;
    manager.enableAutoToolbar = YES;

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

// dealloc 中无需再处理 IQKeyboardManager，已经在 viewWillDisappear 恢复

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    // 入场动画：首次 layout 后把卡片放到屏幕外，再下一轮 runloop 上弹，避免首帧闪烁/透明遮罩挡触摸
    if (!self.didRunPresentAnimation && self.cardView && self.dimmingView && self.scrollView) {
        if (!self.didPrepareInitialOffscreen) {
            self.didPrepareInitialOffscreen = YES;
            [self.view layoutIfNeeded];

            CGFloat h = CGRectGetHeight(self.cardView.bounds);
            if (h < 1) {
                h = 520;
            }
            self.cardView.transform = CGAffineTransformMakeTranslation(0, h + 40);
            self.dimmingView.alpha = 0.0;
            self.dimmingView.userInteractionEnabled = NO;

            __weak typeof(self) weakSelf = self;
            if (!self.didSchedulePresentAnimation) {
                self.didSchedulePresentAnimation = YES;
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(weakSelf) self = weakSelf;
                    if (!self || self.didRunPresentAnimation) {
                        return;
                    }
                    self.didRunPresentAnimation = YES;
                    [UIView animateWithDuration:0.26
                                          delay:0
                         usingSpringWithDamping:0.9
                          initialSpringVelocity:0.6
                                        options:UIViewAnimationOptionCurveEaseOut
                                     animations:^{
                        self.cardView.transform = CGAffineTransformIdentity;
                        self.dimmingView.alpha = PNMatchInfoDimBaseAlpha();
                    } completion:^(BOOL finished) {
                        self.dimmingView.userInteractionEnabled = YES;
                    }];
                });
            }
        }
    }

    // 默认不留额外安全区域，键盘出现时会在监听回调里动态修改 bottomInset
    UIEdgeInsets inset = self.scrollView.contentInset;
    inset.top = 0;
    // 如果当前没有键盘（或已被 keyboardWillHide 重置），保持 bottom 不变
    self.scrollView.contentInset = inset;
    self.scrollView.scrollIndicatorInsets = inset;
}

- (void)buildUI {
    UIView *dim = [[UIView alloc] init];
    dim.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    dim.alpha = 0.0;
    dim.userInteractionEnabled = NO;
    [self.view addSubview:dim];
    self.dimmingView = dim;
    [dim mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    UITapGestureRecognizer *bgTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDismiss)];
    bgTap.cancelsTouchesInView = YES;
    [dim addGestureRecognizer:bgTap];
    
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [UIColor whiteColor];
    card.layer.cornerRadius = 24;
    card.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    card.layer.masksToBounds = YES;
    [self.view addSubview:card];
    self.cardView = card;
    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.bottom.equalTo(self.view);
        if (@available(iOS 11.0, *)) {
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(40);
        } else {
            make.top.equalTo(self.view).offset(40);
        }
    }];
    
    UIView *handle = [[UIView alloc] init];
    handle.backgroundColor = [UIColor colorWithRed:0.831 green:0.831 blue:0.831 alpha:1.0];
    handle.layer.cornerRadius = 2.5;
    [card addSubview:handle];
    [handle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(card).offset(8);
        make.centerX.equalTo(card);
        make.width.mas_equalTo(84);
        make.height.mas_equalTo(5);
    }];
    {
        UIPanGestureRecognizer *handlePan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onCardPan:)];
        handlePan.maximumNumberOfTouches = 1;
        handlePan.delegate = self;
        [handle addGestureRecognizer:handlePan];
    }
    
    UILabel *title = [[UILabel alloc] init];
    title.text = @"输入信息";
    title.font = [UIFont boldSystemFontOfSize:18];
    title.textAlignment = NSTextAlignmentCenter;
    [card addSubview:title];
    self.headerTitleLabel = title;
    [title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(handle.mas_bottom).offset(12);
        make.centerX.equalTo(card);
    }];
    
    // 使用 Custom 类型避免系统蓝色高亮背景
    UIButton *emotionBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [emotionBtn setTitle:@"选择情绪" forState:UIControlStateNormal];
    [emotionBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    emotionBtn.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
    emotionBtn.backgroundColor = PNInputFieldBgColor();
    emotionBtn.layer.cornerRadius = 16;
    emotionBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    emotionBtn.contentEdgeInsets = UIEdgeInsetsMake(0, 38, 0, 20);
    // 去掉高亮时的系统效果
    emotionBtn.adjustsImageWhenHighlighted = NO;
    emotionBtn.showsTouchWhenHighlighted = NO;
    [emotionBtn addTarget:self action:@selector(onEmotionButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:emotionBtn];
    self.emotionButton = emotionBtn;
    UIImageView *emotionIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"team_ex"]];
    emotionIconView.contentMode = UIViewContentModeScaleAspectFit;
    [emotionBtn addSubview:emotionIconView];
    self.emotionButtonIconView = emotionIconView;
    [emotionIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(emotionBtn).offset(10);
        make.centerY.equalTo(emotionBtn);
        make.width.height.mas_equalTo(24);
    }];
    UIImageView *emotionArrowView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"team_down"]];
    if (!emotionArrowView.image && @available(iOS 13.0, *)) {
        emotionArrowView.image = [UIImage systemImageNamed:@"chevron.down"];
        emotionArrowView.tintColor = [UIColor colorWithWhite:0.45 alpha:1.0];
    }
    emotionArrowView.contentMode = UIViewContentModeScaleAspectFit;
    [emotionBtn addSubview:emotionArrowView];
    self.emotionButtonArrowView = emotionArrowView;
    [emotionArrowView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(emotionBtn).offset(-8);
        make.centerY.equalTo(emotionBtn);
        make.width.height.mas_equalTo(10);
    }];
    [emotionBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(title);
        make.trailing.equalTo(card).offset(-16);
        make.height.mas_equalTo(32);
        make.width.mas_equalTo(84);
    }];
    
    // 情绪面板先添加（在底层），scroll 后添加（在上层），保证默认时 scroll 可正常滑动
    UIView *emotionPanel = [[UIView alloc] init];
    emotionPanel.backgroundColor = [UIColor whiteColor];
    emotionPanel.layer.cornerRadius = 12;
    emotionPanel.layer.shadowColor = [UIColor colorWithRed:0.78 green:0.78 blue:0.78 alpha:1.0].CGColor;
    emotionPanel.layer.shadowOpacity = 0.25;
    emotionPanel.layer.shadowOffset = CGSizeMake(0, 4);
    emotionPanel.layer.shadowRadius = 7.9;
    emotionPanel.hidden = YES;
    [card addSubview:emotionPanel];
    self.emotionPanel = emotionPanel;
    [emotionPanel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(emotionBtn.mas_bottom).offset(8);
        make.trailing.equalTo(emotionBtn);
        make.width.mas_equalTo(254);
    }];
    
    NSArray<NSDictionary<NSString *, NSString *> *> *emotionOptions = [self pn_emotionOptionsData];
    NSMutableArray<UIControl *> *emotionOptionViews = [NSMutableArray array];
    const NSInteger columns = 4;
    for (NSUInteger idx = 0; idx < emotionOptions.count; idx++) {
        NSDictionary<NSString *, NSString *> *option = emotionOptions[idx];
        UIControl *optionView = [[UIControl alloc] init];
        optionView.tag = (NSInteger)idx;
        [optionView addTarget:self action:@selector(onEmotionOptionTapped:) forControlEvents:UIControlEventTouchUpInside];
        [emotionPanel addSubview:optionView];
        [emotionOptionViews addObject:optionView];
        NSInteger row = (NSInteger)idx / columns;
        NSInteger col = (NSInteger)idx % columns;
        [optionView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(46);
            make.height.mas_equalTo(60);
            if (col == 0) {
                make.leading.equalTo(emotionPanel).offset(16);
            } else {
                UIControl *prev = emotionOptionViews[idx - 1];
                make.leading.equalTo(prev.mas_trailing).offset(15);
            }
            if (row == 0) {
                make.top.equalTo(emotionPanel).offset(12);
            } else {
                UIControl *prevRowFirst = emotionOptionViews[(row - 1) * columns];
                make.top.equalTo(prevRowFirst).offset(72);
            }
        }];
        
        UIView *iconBg = [[UIView alloc] init];
        iconBg.backgroundColor = PNInputFieldBgColor();
        iconBg.layer.cornerRadius = 20;
        [optionView addSubview:iconBg];
        [iconBg mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.leading.equalTo(optionView);
            make.width.height.mas_equalTo(40);
        }];
        
        UIImageView *iconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:(option[@"icon"] ?: @"")]];
        iconView.contentMode = UIViewContentModeScaleAspectFit;
        [iconBg addSubview:iconView];
        [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(iconBg);
            make.width.height.mas_equalTo(24);
        }];
        
        UILabel *nameLabel = [[UILabel alloc] init];
        nameLabel.text = option[@"name"];
        nameLabel.textColor = [UIColor blackColor];
        nameLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
        nameLabel.textAlignment = NSTextAlignmentCenter;
        [optionView addSubview:nameLabel];
        [nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(iconBg.mas_bottom).offset(8);
            make.centerX.equalTo(iconBg);
        }];
    }
    UIControl *lastEmotionBtn = [emotionOptionViews lastObject];
    [emotionPanel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(lastEmotionBtn.mas_bottom).offset(12);
    }];

    // 底部透明手势区：保持顶部拖动条视觉尺寸不变，用底部区域承接下拉关闭手势，避免与 scrollView 抢手势
    UIView *hit = [[UIView alloc] init];
    hit.backgroundColor = UIColor.clearColor;
    [card addSubview:hit];
    self.dragDismissHitArea = hit;
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onCardPan:)];
    pan.maximumNumberOfTouches = 1;
    pan.delegate = self;
    [hit addGestureRecognizer:pan];
    [hit mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(card);
        // 不再占用底部可视高度，避免出现底部白色留白
        make.height.mas_equalTo(0);
        make.bottom.equalTo(card);
    }];
    
    // scroll 在 emotionPanel 之后添加，位于上层，保证默认可滑动
    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.showsVerticalScrollIndicator = YES;
    scroll.alwaysBounceVertical = YES;
    scroll.delaysContentTouches = NO;
    if (@available(iOS 11.0, *)) {
        scroll.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [card addSubview:scroll];
    self.scrollView = scroll;
    [scroll mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(title.mas_bottom).offset(14);
        make.leading.trailing.equalTo(card);
        // 让滚动区域延伸到卡片底部，避免被“底部手势区”截短
        make.bottom.equalTo(card);
    }];
    [card bringSubviewToFront:hit];
    
    UIView *content = [[UIView alloc] init];
    [scroll addSubview:content];
    if (@available(iOS 11.0, *)) {
        // 使用 contentLayoutGuide 确保 contentSize 正确，底部内容可滚动
        [content.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor].active = YES;
        [content.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor].active = YES;
        [content.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor].active = YES;
        [content.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor].active = YES;
    } else {
        [content mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.leading.trailing.equalTo(scroll);
            make.width.equalTo(scroll);
        }];
    }
    
    // 比赛输入（content 直接从这里开始，不依赖 emotionPanel）
    UILabel *matchTitle = [[UILabel alloc] init];
    matchTitle.text = @"比赛";
    matchTitle.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [content addSubview:matchTitle];
    [matchTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(content).offset(0);
        make.leading.equalTo(content).offset(16);
    }];
    
    UITextField *matchField = [[UITextField alloc] init];
    matchField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"请输入" attributes:@{
        NSForegroundColorAttributeName: PNInputPlaceholderColor(),
        NSFontAttributeName: [UIFont systemFontOfSize:14 weight:UIFontWeightMedium]
    }];
    matchField.font = [UIFont systemFontOfSize:14];
    matchField.borderStyle = UITextBorderStyleNone;
    matchField.backgroundColor = PNInputFieldBgColor();
    matchField.layer.cornerRadius = 8;
    matchField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 1)];
    matchField.leftViewMode = UITextFieldViewModeAlways;
    // 键盘为默认文字键盘，Return 为「完成」，方便收起键盘
    matchField.keyboardType = UIKeyboardTypeDefault;
    matchField.returnKeyType = UIReturnKeyDone;
    matchField.delegate = self;
    // 去掉键盘上方的 3 个快捷按钮（上一项/下一项/完成 等）
    if (@available(iOS 9.0, *)) {
        UITextInputAssistantItem *item = matchField.inputAssistantItem;
        item.leadingBarButtonGroups = @[];
        item.trailingBarButtonGroups = @[];
    }
    [content addSubview:matchField];
    self.matchField = matchField;
    [matchField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(matchTitle.mas_bottom).offset(8);
        make.leading.equalTo(content).offset(16);
        make.trailing.equalTo(content).offset(-16);
        make.height.mas_equalTo(50);
    }];
    
    // 观赛信息
    UILabel *watchTitle = [[UILabel alloc] init];
    watchTitle.text = @"观赛信息";
    watchTitle.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [content addSubview:watchTitle];
    [watchTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(matchField.mas_bottom).offset(PNInputSectionSpacing());
        make.leading.equalTo(content).offset(16);
    }];
    
    NSArray *watchOptions = @[ @"在现场", @"在球场", @"在酒吧", @"在家里", @"在外面", @"在学校", @"在公司" ];
    self.watchButtons = [self addPillButtonsWithTitles:watchOptions
                                             multiSelect:NO
                                                toParent:content
                                              topAnchor:watchTitle.mas_bottom];
    
    // 座位（仅观赛地点为「在现场」「在球场」时可选）
    UILabel *seatTitle = [[UILabel alloc] init];
    seatTitle.text = @"座位";
    seatTitle.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    self.seatTitleLabel = seatTitle;
    [content addSubview:seatTitle];
    [seatTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(((UIButton *)self.watchButtons.lastObject).mas_bottom).offset(PNInputSectionSpacing());
        make.leading.equalTo(content).offset(16);
    }];
    
    NSArray *seatOptions = @[ @"主席台", @"VIP看台", @"包厢", @"看台区", @"场边", @"山顶", @"短边", @"球门后", @"曲线看台", @"角旗区" ];
    self.seatButtons = [self addPillButtonsWithTitles:seatOptions
                                           multiSelect:NO
                                              toParent:content
                                            topAnchor:seatTitle.mas_bottom];
    
    // 观赛身份（多选）
    UILabel *idTitle = [[UILabel alloc] init];
    idTitle.text = @"观赛身份（多选）";
    idTitle.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [content addSubview:idTitle];
    [idTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(((UIButton *)self.seatButtons.lastObject).mas_bottom).offset(PNInputSectionSpacing());
        make.leading.equalTo(content).offset(16);
    }];
    
    NSArray *idOptions = @[ @"ULTRAS球迷", @"球迷", @"领喊", @"Supporters", @"曲线看台球迷", @"旗手", @"鼓手", @"场馆保障", @"媒体记者", @"文字记者", @"教练组", @"运动员", @"联赛组委会", @"导播", @"包厢VIP", @"赛事官员", @"俱乐部投资人", @"球童", @"医护人员", @"安保" ];
    self.identityButtons = [self addPillButtonsWithTitles:idOptions
                                               multiSelect:YES
                                                  toParent:content
                                                topAnchor:idTitle.mas_bottom];
    
    // 看球原因
    UILabel *reasonTitle = [[UILabel alloc] init];
    reasonTitle.text = @"看球原因";
    reasonTitle.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [content addSubview:reasonTitle];
    [reasonTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(((UIButton *)self.identityButtons.lastObject).mas_bottom).offset(PNInputSectionSpacing());
        make.leading.equalTo(content).offset(16);
    }];
    
    NSArray *reasonOptions = @[ @"球迷", @"散客", @"商务", @"家属陪同" ];
    self.reasonButtons = [self addPillButtonsWithTitles:reasonOptions
                                             multiSelect:NO
                                                toParent:content
                                              topAnchor:reasonTitle.mas_bottom];
    
    // 售票价格
    UILabel *priceTitle = [[UILabel alloc] init];
    priceTitle.text = @"售票价格";
    priceTitle.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [content addSubview:priceTitle];
    [priceTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(((UIButton *)self.reasonButtons.lastObject).mas_bottom).offset(PNInputSectionSpacing());
        make.leading.equalTo(content).offset(16);
    }];
    
    UITextField *priceField = [[UITextField alloc] init];
    priceField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"请输入价格" attributes:@{
        NSForegroundColorAttributeName: PNInputPlaceholderColor(),
        NSFontAttributeName: [UIFont systemFontOfSize:14 weight:UIFontWeightMedium]
    }];
    priceField.font = [UIFont systemFontOfSize:14];
    priceField.borderStyle = UITextBorderStyleNone;
    priceField.backgroundColor = PNInputFieldBgColor();
    priceField.layer.cornerRadius = 8;
    priceField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 1)];
    priceField.leftViewMode = UITextFieldViewModeAlways;
    priceField.keyboardType = UIKeyboardTypeDecimalPad;
    // 数字键盘没有「完成」，增加一个工具栏按钮用于收起键盘
    UIToolbar *priceToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 44)];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:@"完成"
                                                             style:UIBarButtonItemStyleDone
                                                            target:self
                                                            action:@selector(onPriceDoneTapped)];
    priceToolbar.items = @[flex, done];
    priceField.inputAccessoryView = priceToolbar;
    if (@available(iOS 9.0, *)) {
        UITextInputAssistantItem *item = priceField.inputAssistantItem;
        item.leadingBarButtonGroups = @[];
        item.trailingBarButtonGroups = @[];
    }
    [content addSubview:priceField];
    self.priceField = priceField;
    [priceField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(priceTitle.mas_bottom).offset(8);
        make.leading.trailing.height.equalTo(matchField);
    }];
    
    // 比赛日期 + 时间（设计图：两个独立标签，两个并排按钮式输入框）
    UILabel *dateTitle = [[UILabel alloc] init];
    dateTitle.text = @"比赛日期";
    dateTitle.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [content addSubview:dateTitle];
    [dateTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(priceField.mas_bottom).offset(PNInputSectionSpacing());
        make.leading.equalTo(content).offset(16);
    }];
    UILabel *timeTitle = [[UILabel alloc] init];
    timeTitle.text = @"时间";
    timeTitle.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [content addSubview:timeTitle];
    [timeTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(dateTitle);
        make.leading.equalTo(content.mas_centerX).offset(2);
    }];
    
    UIButton *dateBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    dateBtn.backgroundColor = PNInputFieldBgColor();
    dateBtn.layer.cornerRadius = 8;
    [dateBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    dateBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [dateBtn addTarget:self action:@selector(onPickDate) forControlEvents:UIControlEventTouchUpInside];
    [content addSubview:dateBtn];
    self.dateBtn = dateBtn;
    
    UIButton *timeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    timeBtn.backgroundColor = PNInputFieldBgColor();
    timeBtn.layer.cornerRadius = 8;
    [timeBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    timeBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [timeBtn addTarget:self action:@selector(onPickTime) forControlEvents:UIControlEventTouchUpInside];
    [content addSubview:timeBtn];
    self.timeBtn = timeBtn;
    
    [dateBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(dateTitle.mas_bottom).offset(8);
        make.leading.equalTo(content).offset(16);
        make.trailing.equalTo(content.mas_centerX).offset(-5.5);
        make.height.mas_equalTo(50);
    }];
    [timeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(dateBtn);
        make.leading.equalTo(content.mas_centerX).offset(5.5);
        make.trailing.equalTo(content).offset(-16);
        make.height.equalTo(dateBtn);
    }];
    
    // 比赛感想
    UILabel *commentTitle = [[UILabel alloc] init];
    commentTitle.text = @"比赛感想";
    commentTitle.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [content addSubview:commentTitle];
    [commentTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(timeBtn.mas_bottom).offset(PNInputSectionSpacing());
        make.leading.equalTo(content).offset(16);
    }];
    
    UITextView *commentView = [[UITextView alloc] init];
    commentView.font = [UIFont systemFontOfSize:14];
    commentView.delegate = self;
    commentView.backgroundColor = PNInputFieldBgColor();
    commentView.layer.cornerRadius = 8;
    // 光标与占位文字保持同一起点（左边距统一为 8，去掉内部 padding）
    commentView.textContainerInset = UIEdgeInsetsMake(8, 8, 28, 8);
    commentView.textContainer.lineFragmentPadding = 0;
    // 使用默认文字键盘，通过 return 收起键盘
    commentView.keyboardType = UIKeyboardTypeDefault;
    if (@available(iOS 9.0, *)) {
        UITextInputAssistantItem *item = commentView.inputAssistantItem;
        item.leadingBarButtonGroups = @[];
        item.trailingBarButtonGroups = @[];
    }
    [content addSubview:commentView];
    self.commentView = commentView;
    UILabel *commentCount = [[UILabel alloc] init];
    commentCount.text = @"0/200";
    commentCount.font = [UIFont systemFontOfSize:12];
    commentCount.textColor = PNInputPlaceholderColor();
    [content addSubview:commentCount];
    self.commentCountLabel = commentCount;
    [commentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(commentTitle.mas_bottom).offset(8);
        make.leading.equalTo(content).offset(16);
        make.trailing.equalTo(content).offset(-16);
        make.height.mas_equalTo(97);
    }];
    [commentCount mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(commentView).offset(-12);
        make.bottom.equalTo(commentView).offset(-10);
    }];
    UILabel *ph = [[UILabel alloc] init];
    ph.text = @"请输入比赛心情~";
    ph.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    ph.textColor = PNInputPlaceholderColor();
    [content addSubview:ph];
    self.commentPlaceholderLabel = ph;
    [ph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(commentView).offset(12);
        make.top.equalTo(commentView).offset(13);
    }];
    
    UIButton *confirmBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [confirmBtn setTitle:@"确认" forState:UIControlStateNormal];
    [confirmBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    confirmBtn.backgroundColor = PNInputGreenColor();
    confirmBtn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    // 保持严格半圆：cornerRadius = height / 2
    confirmBtn.layer.cornerRadius = 26;
    confirmBtn.layer.shadowColor = [UIColor colorWithWhite:0 alpha:1.0].CGColor;
    confirmBtn.layer.shadowOpacity = 0.19;
    confirmBtn.layer.shadowOffset = CGSizeMake(0, 2);
    confirmBtn.layer.shadowRadius = 4;
    confirmBtn.layer.masksToBounds = NO;
    [confirmBtn addTarget:self action:@selector(onConfirmTapped) forControlEvents:UIControlEventTouchUpInside];
    [content addSubview:confirmBtn];
    [confirmBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(commentView.mas_bottom).offset(20);
        // Figma 设计为左右 24 间距，按钮更窄
        make.leading.equalTo(content).offset(24);
        make.trailing.equalTo(content).offset(-24);
        make.height.mas_equalTo(52);
    }];
    // 用确认按钮底部撑开 content 高度，使 scrollView 的 contentSize 正确，可滚动到底
    [content mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(confirmBtn.mas_bottom).offset(22);
    }];
    if (@available(iOS 11.0, *)) {
        [scroll.contentLayoutGuide.bottomAnchor constraintEqualToAnchor:content.bottomAnchor].active = YES;
    }
}

- (NSArray<UIButton *> *)addPillButtonsWithTitles:(NSArray<NSString *> *)titles
                                      multiSelect:(BOOL)multiSelect
                                         toParent:(UIView *)parent
                                       topAnchor:(MASConstraint *)topAnchor {
    NSMutableArray<UIButton *> *buttons = [NSMutableArray array];
    CGFloat padding = 16.0;              // 左右间距 16
    CGFloat spacing = 8.0;               // 标签之间间距 8
    // 用屏幕宽度近似 card 宽度，确保右侧至少保留 16 间距：
    // 当前行已用宽度（含左侧 16） <= 屏幕宽度 - 16
    CGFloat maxLineWidth = UIScreen.mainScreen.bounds.size.width - padding;
    
    __block UIButton *rowFirstButton = nil;      // 当前行第一个按钮
    __block UIButton *prevInRow = nil;           // 当前行上一个按钮
    __block UIButton *prevRowFirstButton = nil;  // 上一行第一个按钮
    __block CGFloat currentLineWidth = 0;        // 当前行已占用宽度（不含右侧 padding）
    
    for (NSInteger i = 0; i < titles.count; i++) {
        // 使用 Custom 类型，完全去掉系统点击高亮背景
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitle:titles[i] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
        btn.contentEdgeInsets = UIEdgeInsetsMake(0, 14, 0, 14);
        // 与设计图一致：未选中为圆角胶囊灰底，选中为白底绿色描边文字
        btn.layer.cornerRadius = 15;
        btn.layer.borderWidth = 0;
        btn.layer.borderColor = UIColor.clearColor.CGColor;
        [btn setTitleColor:PNInputPillTextColor() forState:UIControlStateNormal];
        btn.backgroundColor = PNInputFieldBgColor();
        btn.adjustsImageWhenHighlighted = NO;
        btn.showsTouchWhenHighlighted = NO;
        btn.tag = multiSelect ? 1 : 0;
        [btn addTarget:self action:@selector(onPillTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        [parent addSubview:btn];
        [buttons addObject:btn];
        
        // 预估该按钮自身所需宽度（文字 + 内边距）
        CGSize titleSize = [titles[i] boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, 20)
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                attributes:@{NSFontAttributeName: btn.titleLabel.font}
                                                   context:nil].size;
        CGFloat buttonWidth = ceil(titleSize.width) + btn.contentEdgeInsets.left + btn.contentEdgeInsets.right;
        
        BOOL isFirstInRow = (rowFirstButton == nil);
        CGFloat requiredWidthIfInCurrentRow;
        if (isFirstInRow) {
            // 行首：左边 padding + 按钮宽度
            requiredWidthIfInCurrentRow = padding + buttonWidth;
        } else {
            // 行内：已占宽度 + 间距 + 按钮宽度
            requiredWidthIfInCurrentRow = currentLineWidth + spacing + buttonWidth;
        }
        
        // 如果放在当前行会超出可用宽度，则换到下一行
        if (!isFirstInRow && requiredWidthIfInCurrentRow > maxLineWidth) {
            prevRowFirstButton = rowFirstButton;
            rowFirstButton = nil;
            prevInRow = nil;
            currentLineWidth = 0;
            isFirstInRow = YES;
        }
        
        [btn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(30);
            if (rowFirstButton == nil) {
                // 新行行首
                rowFirstButton = btn;
                if (prevRowFirstButton == nil) {
                    // 第一行：top 相对传入的 topAnchor
                    make.top.equalTo(topAnchor).offset(10);
                } else {
                    // 其他行：top 相对上一行的首个按钮
                    make.top.equalTo(prevRowFirstButton.mas_bottom).offset(8);
                }
                // 行首：左侧 16
                make.leading.equalTo(parent).offset(padding);
            } else {
                // 同一行后续：与上一列对齐
                make.centerY.equalTo(rowFirstButton);
                make.leading.equalTo(prevInRow.mas_trailing).offset(spacing);
            }
        }];
        
        // 更新行内状态
        if (rowFirstButton == btn) {
            currentLineWidth = padding + buttonWidth;
        } else {
            currentLineWidth += spacing + buttonWidth;
        }
        prevInRow = btn;
    }
    return buttons;
}

- (void)fillDefaultValues {
    // 比赛名默认填充当前对阵
    if (self.homeName.length > 0 && self.awayName.length > 0) {
        self.matchField.text = [NSString stringWithFormat:@"%@ VS %@", self.homeName, self.awayName];
    }
    NSDictionary<NSString *, NSString *> *defaultEmotion = [[self pn_emotionOptionsData] firstObject];
    [self pn_applyEmotionOption:defaultEmotion];
    self.selectedWatchInfo = @"在球场";
    self.selectedSeat = @"VIP看台";
    self.selectedReason = @"球迷";
    [self.selectedIdentities removeAllObjects];
    [self.selectedIdentities addObject:@"球迷"];
    [self.selectedIdentities addObject:@"媒体记者"];
    
    self.priceField.text = @"";
    self.selectedDate = [NSDate date];
    [self refreshDateTimeButtons];
    self.commentView.text = @"";

    [self pn_refreshPillButtonsFromSelection];
    [self updateCommentCountLabel];
}

- (BOOL)pn_isSeatSelectionAllowed {
    NSString *loc = [self.selectedWatchInfo stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return loc.length > 0 && [PNSeatAllowedWatchLocations() containsObject:loc];
}

- (void)pn_updateSeatSectionAvailability {
    BOOL allowed = [self pn_isSeatSelectionAllowed];
    self.seatTitleLabel.alpha = allowed ? 1.0 : 0.45;
    if (!allowed) {
        self.selectedSeat = @"";
    }
    for (UIButton *b in self.seatButtons) {
        b.enabled = allowed;
        b.userInteractionEnabled = allowed;
        if (!allowed) {
            [self pn_applyPillButton:b selected:NO];
        }
    }
}

- (void)pn_trimIdentitiesToMaxCount {
    if (self.selectedIdentities.count <= kPNMaxViewingIdentityCount) {
        return;
    }
    NSMutableOrderedSet<NSString *> *keep = [NSMutableOrderedSet orderedSet];
    for (UIButton *b in self.identityButtons) {
        NSString *title = b.titleLabel.text ?: @"";
        if (title.length == 0 || ![self.selectedIdentities containsObject:title]) {
            continue;
        }
        [keep addObject:title];
        if (keep.count >= kPNMaxViewingIdentityCount) {
            break;
        }
    }
    [self.selectedIdentities setSet:[keep set]];
}

- (void)loadInitialFormData {
    if (self.recordId.length > 0) {
        self.headerTitleLabel.text = @"编辑信息";
        [[LoadingManager sharedManager] showLoadingInView:self.view];
        __weak typeof(self) weakSelf = self;
        [[MatchRequest shared] getMatchRecordDetail:self.recordId success:^(HTTPResponse * _Nullable responseObject) {
            [[LoadingManager sharedManager] hideLoadingInView:weakSelf.view];
            PNMatchRecordDetail *detail = nil;
            if ([responseObject.dataObject isKindOfClass:PNMatchRecordDetail.class]) {
                detail = responseObject.dataObject;
            } else if ([responseObject.data isKindOfClass:NSDictionary.class]) {
                detail = [PNMatchRecordDetail yy_modelWithJSON:responseObject.data];
            }
            if (detail) {
                [weakSelf applyFromDetail:detail];
            } else {
                [weakSelf fillDefaultValues];
                [[LoadingManager sharedManager] showError:@"加载观赛记录失败" inView:weakSelf.view];
            }
        } failure:^(NSError * _Nonnull error) {
            [[LoadingManager sharedManager] hideLoadingInView:weakSelf.view];
            [weakSelf fillDefaultValues];
            NSString *msg = error.localizedDescription ?: @"网络错误";
            if ([error isKindOfClass:[APIError class]]) {
                APIError *ae = (APIError *)error;
                if (ae.businessMessage.length > 0) {
                    msg = ae.businessMessage;
                }
            }
            [[LoadingManager sharedManager] showError:msg inView:weakSelf.view];
        }];
    } else {
        self.headerTitleLabel.text = @"输入信息";
        [self fillDefaultValues];
    }
}

- (void)applyFromDetail:(PNMatchRecordDetail *)detail {
    if (detail.matchName.length > 0) {
        self.matchField.text = detail.matchName;
    } else if (detail.homeTeamName.length > 0 && detail.awayTeamName.length > 0) {
        self.matchField.text = [NSString stringWithFormat:@"%@ VS %@", detail.homeTeamName, detail.awayTeamName];
    } else if (self.homeName.length > 0 && self.awayName.length > 0) {
        self.matchField.text = [NSString stringWithFormat:@"%@ VS %@", self.homeName, self.awayName];
    }

    self.selectedWatchInfo = [self pn_serverValueOrFallback:self.watchButtons serverValue:detail.viewingLocation fallback:@"在球场"];
    self.selectedSeat = [self pn_serverValueOrFallback:self.seatButtons serverValue:detail.standType fallback:@"VIP看台"];
    self.selectedReason = [self pn_serverValueOrFallback:self.reasonButtons serverValue:detail.watchReason fallback:@"球迷"];

    [self.selectedIdentities removeAllObjects];
    for (NSString *ident in detail.viewingIdentities) {
        if ([ident isKindOfClass:NSString.class] && ident.length > 0) {
            [self.selectedIdentities addObject:ident];
        }
    }
    if (self.selectedIdentities.count == 0) {
        [self.selectedIdentities addObject:@"球迷"];
    }
    [self pn_trimIdentitiesToMaxCount];
    if (![self pn_isSeatSelectionAllowed]) {
        self.selectedSeat = @"";
    }

    if (detail.ticketPrice.length > 0) {
        self.priceField.text = detail.ticketPrice;
    } else {
        self.priceField.text = @"0";
    }

    NSDate *kick = [self pn_dateFromBackendDateTime:detail.matchDateTime];
    if (!kick) {
        kick = [self pn_dateFromBackendDateTime:detail.matchDate];
    }
    self.selectedDate = kick ?: [NSDate date];
    [self refreshDateTimeButtons];

    NSDictionary<NSString *, NSString *> *emotionOpt = [self pn_emotionOptionForValue:detail.postMatchEmotion];
    if (!emotionOpt) {
        emotionOpt = [[self pn_emotionOptionsData] firstObject];
    }
    [self pn_applyEmotionOption:emotionOpt];

    self.commentView.text = detail.notes ?: @"";
    [self pn_refreshPillButtonsFromSelection];
    [self updateCommentCountLabel];
}

/// 若服务端文案与本地 pill 文案一致则采用，否则用默认 fallback
- (NSString *)pn_serverValueOrFallback:(NSArray<UIButton *> *)buttons serverValue:(NSString *)server fallback:(NSString *)fallback {
    NSString *s = server ?: @"";
    for (UIButton *b in buttons) {
        if ([b.titleLabel.text isEqualToString:s]) {
            return s;
        }
    }
    return fallback ?: @"";
}

- (nullable NSDate *)pn_dateFromBackendDateTime:(NSString *)s {
    if (s.length == 0) {
        return nil;
    }
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    fmt.timeZone = [NSTimeZone localTimeZone];
    NSArray<NSString *> *formats = @[
        @"yyyy-MM-dd'T'HH:mm:ss",
        @"yyyy-MM-dd'T'HH:mm:ss.SSS",
        @"yyyy-MM-dd HH:mm:ss",
        @"yyyy-MM-dd"
    ];
    for (NSString *f in formats) {
        fmt.dateFormat = f;
        NSDate *d = [fmt dateFromString:s];
        if (d) {
            return d;
        }
    }
    if (@available(iOS 11.0, *)) {
        NSISO8601DateFormatter *iso = [[NSISO8601DateFormatter alloc] init];
        iso.formatOptions = NSISO8601DateFormatWithInternetDateTime;
        return [iso dateFromString:s];
    }
    return nil;
}

- (void)pn_refreshPillButtonsFromSelection {
    for (UIButton *b in self.watchButtons) {
        BOOL sel = [b.titleLabel.text isEqualToString:self.selectedWatchInfo];
        [self pn_applyPillButton:b selected:sel];
    }
    for (UIButton *b in self.seatButtons) {
        BOOL sel = [b.titleLabel.text isEqualToString:self.selectedSeat];
        [self pn_applyPillButton:b selected:sel];
    }
    for (UIButton *b in self.reasonButtons) {
        BOOL sel = [b.titleLabel.text isEqualToString:self.selectedReason];
        [self pn_applyPillButton:b selected:sel];
    }
    for (UIButton *b in self.identityButtons) {
        BOOL sel = [self.selectedIdentities containsObject:b.titleLabel.text];
        [self pn_applyPillButton:b selected:sel];
    }
    [self pn_updateSeatSectionAvailability];
}

- (NSString *)pn_isoMatchDateTimeString {
    NSDate *date = self.selectedDate ?: [NSDate date];
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    fmt.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    fmt.timeZone = [NSTimeZone localTimeZone];
    fmt.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss";
    return [fmt stringFromDate:date];
}

- (NSMutableDictionary *)pn_matchRecordBodyMutable {
    NSMutableDictionary *m = [NSMutableDictionary dictionary];
    NSString *mn = [self.matchField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (mn.length > 0) {
        m[@"matchName"] = mn;
    }
    NSString *sn = [self.stadiumName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (sn.length > 0) {
        m[@"stadiumName"] = sn;
    }
    long long mid = [self.matchId longLongValue];
    if (self.matchId.length > 0 && mid > 0) {
        m[@"matchId"] = @(mid);
    }
    m[@"viewingLocation"] = self.selectedWatchInfo ?: @"";
    m[@"standType"] = self.selectedSeat ?: @"";
    // 当前页面只有一组座位选择，先同步到 seatLocation，满足后端完整字段
    m[@"seatLocation"] = self.selectedSeat ?: @"";
    m[@"viewingIdentities"] = self.selectedIdentities.count > 0 ? [self.selectedIdentities allObjects] : @[];
    m[@"onlineViewingMethods"] = @[];
    m[@"watchReason"] = self.selectedReason ?: @"";
    m[@"ticketPrice"] = @([self.priceField.text ?: @"0" doubleValue]);
    m[@"matchDateTime"] = [self pn_isoMatchDateTimeString];
    m[@"postMatchEmotion"] = self.selectedEmotion ?: @"";
    m[@"notes"] = self.commentView.text ?: @"";
    m[@"photoUrls"] = @[];
    return m;
}

- (NSString *)pn_recordIdFromResponseObject:(HTTPResponse *)response {
    id data = response.dataObject ?: response.data;
    if ([data isKindOfClass:NSDictionary.class]) {
        NSDictionary *dict = (NSDictionary *)data;
        id rid = dict[@"recordId"] ?: dict[@"id"];
        if ([rid isKindOfClass:NSString.class]) {
            return (NSString *)rid;
        }
        if ([rid isKindOfClass:NSNumber.class]) {
            return [(NSNumber *)rid stringValue];
        }
    }
    return @"";
}

- (BOOL)pn_validateBeforeSubmit:(NSString *__autoreleasing *)outMessage {
    NSString *matchText = [self.matchField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (matchText.length == 0) {
        if (outMessage) {
            *outMessage = @"请填写比赛名称";
        }
        return NO;
    }
    long long mid = [self.matchId longLongValue];
    BOOL hasMatchId = (self.matchId.length > 0 && mid > 0);
    if (self.recordId.length == 0 && !hasMatchId) {
        NSString *st = [self.stadiumName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (st.length == 0) {
            if (outMessage) {
                *outMessage = @"缺少比赛 ID 时，请填写球场名称";
            }
            return NO;
        }
    }
    if (self.selectedEmotion.length == 0) {
        if (outMessage) {
            *outMessage = @"请选择赛后情绪";
        }
        return NO;
    }
    return YES;
}

- (void)onConfirmTapped {
    [self.view endEditing:YES];
    NSString *errMsg = nil;
    if (![self pn_validateBeforeSubmit:&errMsg]) {
        [[LoadingManager sharedManager] showText:errMsg inView:self.view];
        return;
    }

    NSDictionary *body = [self pn_matchRecordBodyMutable];
    BOOL isUpdate = (self.recordId.length > 0);

    [[LoadingManager sharedManager] showLoadingInView:self.view];
    __weak typeof(self) weakSelf = self;
    if (isUpdate) {
        [[MatchRequest shared] updateMatchRecord:self.recordId body:body success:^(HTTPResponse * _Nullable responseObject) {
            [[LoadingManager sharedManager] hideLoadingInView:weakSelf.view];
            [[NSNotificationCenter defaultCenter] postNotificationName:PNMatchRecordDidUpdateNotification object:nil];
            if (weakSelf.completion) {
                weakSelf.completion(weakSelf.recordId);
            }
            [weakSelf dismissWithCardAnimation];
        } failure:^(NSError * _Nonnull error) {
            [[LoadingManager sharedManager] hideLoadingInView:weakSelf.view];
            NSString *msg = error.localizedDescription ?: @"保存失败";
            if ([error isKindOfClass:[APIError class]]) {
                APIError *ae = (APIError *)error;
                if (ae.businessMessage.length > 0) {
                    msg = ae.businessMessage;
                }
            }
            [[LoadingManager sharedManager] showError:msg inView:weakSelf.view];
        }];
    } else {
        [[MatchRequest shared] createMatchRecordWithBody:body success:^(HTTPResponse * _Nullable responseObject) {
            [[LoadingManager sharedManager] hideLoadingInView:weakSelf.view];
            NSString *newRecordId = [weakSelf pn_recordIdFromResponseObject:responseObject];
            if (newRecordId.length > 0) {
                weakSelf.recordId = newRecordId;
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:PNMatchRecordDidUpdateNotification object:nil];
            if (weakSelf.completion) {
                weakSelf.completion(newRecordId);
            }
            [weakSelf dismissWithCardAnimation];
        } failure:^(NSError * _Nonnull error) {
            [[LoadingManager sharedManager] hideLoadingInView:weakSelf.view];
            NSString *msg = error.localizedDescription ?: @"创建失败";
            if ([error isKindOfClass:[APIError class]]) {
                APIError *ae = (APIError *)error;
                if (ae.businessMessage.length > 0) {
                    msg = ae.businessMessage;
                }
            }
            [[LoadingManager sharedManager] showError:msg inView:weakSelf.view];
        }];
    }
}

- (void)onDismiss {
    [self dismissWithCardAnimation];
}

- (void)onEmotionButtonTapped {
    self.emotionPanel.hidden = !self.emotionPanel.hidden;
    if (!self.emotionPanel.hidden) {
        [self.cardView bringSubviewToFront:self.emotionPanel];
        // 情绪面板会盖住底部透明手势区，需把底部条重新提到最前才能继续下拉关闭
        if (self.dragDismissHitArea) {
            [self.cardView bringSubviewToFront:self.dragDismissHitArea];
        }
    }
}

- (void)onEmotionOptionTapped:(UIControl *)sender {
    NSInteger idx = sender.tag;
    NSArray<NSDictionary<NSString *, NSString *> *> *options = [self pn_emotionOptionsData];
    if (idx >= 0 && idx < (NSInteger)options.count) {
        [self pn_applyEmotionOption:options[idx]];
    }
    self.emotionPanel.hidden = YES;
}

- (void)updateCommentCountLabel {
    NSUInteger len = self.commentView.text.length;
    if (len > 200) {
        self.commentView.text = [self.commentView.text substringToIndex:200];
        len = 200;
    }
    self.commentCountLabel.text = [NSString stringWithFormat:@"%lu/200", (unsigned long)len];
    self.commentPlaceholderLabel.hidden = (len > 0);
}

- (void)textViewDidChange:(UITextView *)textView {
    if (textView != self.commentView) return;
    [self updateCommentCountLabel];
}

- (BOOL)textView:(UITextView *)textView
shouldChangeTextInRange:(NSRange)range
 replacementText:(NSString *)text {
    // 比赛感想：按下 return 直接收起键盘，而不是换行
    if (textView == self.commentView && [text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.matchField) {
        [textField resignFirstResponder];
        return YES;
    }
    return NO;
}

- (void)onPriceDoneTapped {
    [self.priceField resignFirstResponder];
}

- (void)onCommentDoneTapped {
    [self.commentView resignFirstResponder];
}

- (void)refreshDateTimeButtons {
    NSDate *date = self.selectedDate ?: [NSDate date];
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    cal.timeZone = [NSTimeZone localTimeZone];
    NSDateComponents *c = [cal components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute fromDate:date];
    NSString *dateStr = [NSString stringWithFormat:@"%ld年%02ld月%02ld日", (long)c.year, (long)c.month, (long)c.day];
    NSString *timeStr = [NSString stringWithFormat:@"%02ld:%02ld", (long)c.hour, (long)c.minute];
    [self.dateBtn setTitle:dateStr forState:UIControlStateNormal];
    [self.timeBtn setTitle:timeStr forState:UIControlStateNormal];
}

- (void)onPickDate {
    [self.view endEditing:YES];
    PNPickerSheetViewController *sheet = [PNPickerSheetViewController new];
    sheet.mode = PNPickerSheetModeDate;
    sheet.selectedDate = self.selectedDate ?: [NSDate date];
    sheet.modalPresentationStyle = UIModalPresentationOverFullScreen;
    __weak typeof(self) weakSelf = self;
    sheet.onConfirm = ^(NSDate *date) {
        weakSelf.selectedDate = date;
        [weakSelf refreshDateTimeButtons];
    };
    [self presentViewController:sheet animated:NO completion:nil];
}

- (void)onPickTime {
    [self.view endEditing:YES];
    PNPickerSheetViewController *sheet = [PNPickerSheetViewController new];
    sheet.mode = PNPickerSheetModeTime;
    sheet.selectedDate = self.selectedDate ?: [NSDate date];
    sheet.modalPresentationStyle = UIModalPresentationOverFullScreen;
    __weak typeof(self) weakSelf = self;
    sheet.onConfirm = ^(NSDate *date) {
        weakSelf.selectedDate = date;
        [weakSelf refreshDateTimeButtons];
    };
    [self presentViewController:sheet animated:NO completion:nil];
}

#pragma mark - 键盘处理

- (void)onKeyboardWillShow:(NSNotification *)note {
    NSDictionary *userInfo = note.userInfo;
    CGRect kbFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect kbInView = [self.view convertRect:kbFrame fromView:nil];
    
    CGFloat overlap = CGRectGetMaxY(self.view.bounds) - CGRectGetMinY(kbInView);
    if (overlap < 0) overlap = 0;
    
    UIEdgeInsets inset = self.scrollView.contentInset;
    inset.bottom = overlap;
    self.scrollView.contentInset = inset;
    self.scrollView.scrollIndicatorInsets = inset;
    
    // 如果当前正在编辑比赛感想或价格，让对应区域滚到可见
    if ([self.commentView isFirstResponder]) {
        [self.scrollView scrollRectToVisible:CGRectInset(self.commentView.frame, 0, -20) animated:YES];
    } else if ([self.priceField isFirstResponder]) {
        [self.scrollView scrollRectToVisible:CGRectInset(self.priceField.frame, 0, -20) animated:YES];
    }
}

- (void)onKeyboardWillHide:(NSNotification *)note {
    UIEdgeInsets inset = self.scrollView.contentInset;
    inset.bottom = 0;
    self.scrollView.contentInset = inset;
    self.scrollView.scrollIndicatorInsets = inset;
}

- (void)onPillTapped:(UIButton *)sender {
    BOOL multi = [self.identityButtons containsObject:sender];
    NSString *title = sender.titleLabel.text ?: @"";
    if (multi) {
        if (!sender.selected && self.selectedIdentities.count >= kPNMaxViewingIdentityCount) {
            [[LoadingManager sharedManager] showError:@"观赛身份最多选择6种" inView:self.view];
            return;
        }
        sender.selected = !sender.selected;
        if (sender.selected) {
            [self pn_applyPillButton:sender selected:YES];
            [self.selectedIdentities addObject:title];
        } else {
            [self pn_applyPillButton:sender selected:NO];
            [self.selectedIdentities removeObject:title];
        }
        return;
    }
    if ([self.seatButtons containsObject:sender] && ![self pn_isSeatSelectionAllowed]) {
        return;
    }
    NSArray<UIButton *> *group = nil;
    if ([self.watchButtons containsObject:sender]) {
        group = self.watchButtons;
        self.selectedWatchInfo = title;
    } else if ([self.seatButtons containsObject:sender]) {
        group = self.seatButtons;
        self.selectedSeat = title;
    } else if ([self.reasonButtons containsObject:sender]) {
        group = self.reasonButtons;
        self.selectedReason = title;
    }
    for (UIButton *b in group) {
        [self pn_applyPillButton:b selected:(b == sender)];
    }
    if ([self.watchButtons containsObject:sender]) {
        [self pn_updateSeatSectionAvailability];
        [self pn_refreshPillButtonsFromSelection];
    }
}

@end

