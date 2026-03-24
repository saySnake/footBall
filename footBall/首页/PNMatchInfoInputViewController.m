//
//  PNMatchInfoInputViewController.m
//  footBall
//

#import "PNMatchInfoInputViewController.h"
#import <Masonry/Masonry.h>
#import <IQKeyboardManager/IQKeyboardManager.h>
#import "PNPickerSheetViewController.h"
#import "ColorManager.h"

static UIColor *PNInputGreenColor(void) {
    // 统一使用 ColorManager 的主色，方便以后适配黑天/白天皮肤
    return [ColorManager sharedManager].primaryColor;
}

@interface PNMatchInfoInputViewController () <UITextViewDelegate, UITextFieldDelegate>
@property (nonatomic, strong) UIView *dimmingView;
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, strong) UIButton *emotionButton;
@property (nonatomic, strong) UIView *emotionPanel;

@property (nonatomic, strong) UITextField *matchField;
@property (nonatomic, strong) UITextField *priceField;
@property (nonatomic, strong) UIButton *dateBtn;
@property (nonatomic, strong) UIButton *timeBtn;
@property (nonatomic, strong) UITextView *commentView;
@property (nonatomic, strong) UILabel *commentCountLabel;
@property (nonatomic, strong) UILabel *commentPlaceholderLabel;

@property (nonatomic, strong) NSArray<UIButton *> *watchButtons;
@property (nonatomic, strong) NSArray<UIButton *> *seatButtons;
@property (nonatomic, strong) NSArray<UIButton *> *reasonButtons;
@property (nonatomic, strong) NSArray<UIButton *> *identityButtons;

@property (nonatomic, copy) NSString *selectedEmotion;
@property (nonatomic, copy) NSString *selectedWatchInfo;
@property (nonatomic, copy) NSString *selectedSeat;
@property (nonatomic, copy) NSString *selectedReason;
@property (nonatomic, strong) NSMutableSet<NSString *> *selectedIdentities;

// 记录进入页面前 IQKeyboardManager 的启用状态，方便恢复
@property (nonatomic, assign) BOOL iqPreviouslyEnabled;

// 比赛日期+时间，复用现有 PNPickerSheetViewController 的 selectedDate 逻辑
@property (nonatomic, strong) NSDate *selectedDate;
@end

@implementation PNMatchInfoInputViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    self.selectedIdentities = [NSMutableSet set];
    
    [self buildUI];
    [self fillDefaultValues];
    [self.emotionButton setTitle:[self.selectedEmotion stringByAppendingString:@" "] forState:UIControlStateNormal];
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
    // 默认不留额外安全区域，键盘出现时会在监听回调里动态修改 bottomInset
    UIEdgeInsets inset = self.scrollView.contentInset;
    inset.top = 0;
    // 如果当前没有键盘（或已被 keyboardWillHide 重置），保持 bottom 不变
    self.scrollView.contentInset = inset;
    self.scrollView.scrollIndicatorInsets = inset;
}

- (void)buildUI {
    UIView *dim = [[UIView alloc] init];
    dim.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.35];
    [self.view addSubview:dim];
    self.dimmingView = dim;
    [dim mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [dim addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDismiss)]];
    
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [UIColor whiteColor];
    card.layer.cornerRadius = 18;
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
    handle.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1.0];
    handle.layer.cornerRadius = 2;
    [card addSubview:handle];
    [handle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(card).offset(8);
        make.centerX.equalTo(card);
        make.width.mas_equalTo(40);
        make.height.mas_equalTo(4);
    }];
    
    UILabel *title = [[UILabel alloc] init];
    title.text = @"输入信息";
    title.font = [UIFont boldSystemFontOfSize:18];
    title.textAlignment = NSTextAlignmentCenter;
    [card addSubview:title];
    [title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(handle.mas_bottom).offset(10);
        make.centerX.equalTo(card);
    }];
    
    // 使用 Custom 类型避免系统蓝色高亮背景
    UIButton *emotionBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [emotionBtn setTitle:@"选择情绪 " forState:UIControlStateNormal];
    [emotionBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    emotionBtn.titleLabel.font = [UIFont systemFontOfSize:13];
    emotionBtn.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    emotionBtn.layer.cornerRadius = 16;
    if (@available(iOS 13.0, *)) {
        UIImage *chevron = [UIImage systemImageNamed:@"chevron.down"];
        if (chevron) {
            [emotionBtn setImage:[chevron imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
            emotionBtn.tintColor = [UIColor darkGrayColor];
            emotionBtn.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
            emotionBtn.imageEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 0);
        }
    }
    // 去掉高亮时的系统效果
    emotionBtn.adjustsImageWhenHighlighted = NO;
    emotionBtn.showsTouchWhenHighlighted = NO;
    [emotionBtn addTarget:self action:@selector(onEmotionButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:emotionBtn];
    self.emotionButton = emotionBtn;
    [emotionBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(title);
        make.trailing.equalTo(card).offset(-16);
        make.height.mas_equalTo(32);
        make.width.mas_greaterThanOrEqualTo(100);
    }];
    
    // 情绪面板先添加（在底层），scroll 后添加（在上层），保证默认时 scroll 可正常滑动
    UIView *emotionPanel = [[UIView alloc] init];
    emotionPanel.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1.0];
    emotionPanel.layer.cornerRadius = 12;
    emotionPanel.layer.shadowColor = [UIColor blackColor].CGColor;
    emotionPanel.layer.shadowOpacity = 0.12;
    emotionPanel.layer.shadowOffset = CGSizeMake(0, 4);
    emotionPanel.layer.shadowRadius = 8;
    emotionPanel.hidden = YES;
    [card addSubview:emotionPanel];
    self.emotionPanel = emotionPanel;
    [emotionPanel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(title.mas_bottom).offset(8);
        make.leading.equalTo(card).offset(18);
        make.trailing.equalTo(card).offset(-18);
    }];
    
    NSArray<NSString *> *emotions = @[ @"兴奋 🤩", @"激动 🥳", @"希望 🤗", @"遗憾 😩",
                                       @"平静 😎", @"失望 😤", @"暴躁 😡" ];
    NSMutableArray *emotionButtons = [NSMutableArray array];
    int columns = 4;
    for (NSUInteger idx = 0; idx < emotions.count; idx++) {
        // 使用 Custom 类型，避免系统点击时出现蓝色高亮背景
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitle:emotions[idx] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:12];
        btn.backgroundColor = [UIColor whiteColor];
        btn.layer.cornerRadius = 10;
        btn.adjustsImageWhenHighlighted = NO;
        btn.showsTouchWhenHighlighted = NO;
        btn.tag = (NSInteger)idx;
        [btn addTarget:self action:@selector(onEmotionOptionTapped:) forControlEvents:UIControlEventTouchUpInside];
        [emotionPanel addSubview:btn];
        [emotionButtons addObject:btn];
        
        int row = (int)(idx / columns);
        int col = (int)(idx % columns);
        [btn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(32);
            if (row == 0) {
                make.top.equalTo(emotionPanel).offset(12);
            } else {
                UIButton *prevRowBtn = emotionButtons[(row - 1) * columns + col];
                make.top.equalTo(prevRowBtn.mas_bottom).offset(8);
            }
            if (col == 0) {
                make.leading.equalTo(emotionPanel).offset(8);
            } else {
                UIButton *prevBtn = emotionButtons[idx - 1];
                make.leading.equalTo(prevBtn.mas_trailing).offset(8);
                make.width.equalTo(prevBtn);
            }
            if (col == columns - 1) {
                make.trailing.equalTo(emotionPanel).offset(-8);
            }
        }];
    }
    UIButton *lastEmotionBtn = [emotionButtons lastObject];
    [emotionPanel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(lastEmotionBtn.mas_bottom).offset(12);
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
        make.top.equalTo(title.mas_bottom).offset(8);
        make.leading.trailing.equalTo(card);
        // 设计要求底部完全贴合，不再预留额外白色区域
        if (@available(iOS 11.0, *)) {
            make.bottom.equalTo(card.mas_bottom);
        } else {
            make.bottom.equalTo(card);
        }
    }];
    
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
    matchTitle.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    [content addSubview:matchTitle];
    [matchTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(content).offset(0);
        make.leading.equalTo(content).offset(18);
    }];
    
    UITextField *matchField = [[UITextField alloc] init];
    matchField.placeholder = @"请输入";
    matchField.font = [UIFont systemFontOfSize:14];
    matchField.borderStyle = UITextBorderStyleNone;
    matchField.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    matchField.layer.cornerRadius = 8;
    matchField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 1)];
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
        make.leading.equalTo(content).offset(18);
        make.trailing.equalTo(content).offset(-18);
        make.height.mas_equalTo(44);
    }];
    
    // 观赛信息
    UILabel *watchTitle = [[UILabel alloc] init];
    watchTitle.text = @"观赛信息";
    watchTitle.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    [content addSubview:watchTitle];
    [watchTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(matchField.mas_bottom).offset(18);
        make.leading.equalTo(content).offset(18);
    }];
    
    NSArray *watchOptions = @[ @"在现场", @"在球场", @"在酒吧", @"在家里", @"在外面", @"在学校", @"在公司" ];
    self.watchButtons = [self addPillButtonsWithTitles:watchOptions
                                             multiSelect:NO
                                                toParent:content
                                              topAnchor:watchTitle.mas_bottom];
    
    // 座位
    UILabel *seatTitle = [[UILabel alloc] init];
    seatTitle.text = @"座位";
    seatTitle.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    [content addSubview:seatTitle];
    [seatTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(((UIButton *)self.watchButtons.lastObject).mas_bottom).offset(18);
        make.leading.equalTo(content).offset(18);
    }];
    
    NSArray *seatOptions = @[ @"主席台", @"VIP看台", @"包厢", @"看台区", @"场边", @"山顶", @"短边", @"球门后", @"曲线看台", @"角旗区" ];
    self.seatButtons = [self addPillButtonsWithTitles:seatOptions
                                           multiSelect:NO
                                              toParent:content
                                            topAnchor:seatTitle.mas_bottom];
    
    // 观赛身份（多选）
    UILabel *idTitle = [[UILabel alloc] init];
    idTitle.text = @"观赛身份（多选）";
    idTitle.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    [content addSubview:idTitle];
    [idTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(((UIButton *)self.seatButtons.lastObject).mas_bottom).offset(18);
        make.leading.equalTo(content).offset(18);
    }];
    
    NSArray *idOptions = @[ @"ULTRAS球迷", @"球迷", @"领喊", @"Supporters", @"曲线看台球迷", @"旗手", @"鼓手", @"场馆保障", @"媒体记者", @"文字记者", @"教练组", @"运动员", @"联赛组委会", @"导播", @"包厢VIP", @"赛事官员", @"俱乐部投资人", @"球童", @"医护人员", @"安保" ];
    self.identityButtons = [self addPillButtonsWithTitles:idOptions
                                               multiSelect:YES
                                                  toParent:content
                                                topAnchor:idTitle.mas_bottom];
    
    // 看球原因
    UILabel *reasonTitle = [[UILabel alloc] init];
    reasonTitle.text = @"看球原因";
    reasonTitle.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    [content addSubview:reasonTitle];
    [reasonTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(((UIButton *)self.identityButtons.lastObject).mas_bottom).offset(18);
        make.leading.equalTo(content).offset(18);
    }];
    
    NSArray *reasonOptions = @[ @"球迷", @"散客", @"商务", @"家属陪同" ];
    self.reasonButtons = [self addPillButtonsWithTitles:reasonOptions
                                             multiSelect:NO
                                                toParent:content
                                              topAnchor:reasonTitle.mas_bottom];
    
    // 售票价格
    UILabel *priceTitle = [[UILabel alloc] init];
    priceTitle.text = @"售票价格";
    priceTitle.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    [content addSubview:priceTitle];
    [priceTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(((UIButton *)self.reasonButtons.lastObject).mas_bottom).offset(18);
        make.leading.equalTo(content).offset(18);
    }];
    
    UITextField *priceField = [[UITextField alloc] init];
    priceField.placeholder = @"请输入价格";
    priceField.font = [UIFont systemFontOfSize:14];
    priceField.borderStyle = UITextBorderStyleNone;
    priceField.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    priceField.layer.cornerRadius = 8;
    priceField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 1)];
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
    dateTitle.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    [content addSubview:dateTitle];
    [dateTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(priceField.mas_bottom).offset(18);
        make.leading.equalTo(content).offset(18);
    }];
    UILabel *timeTitle = [[UILabel alloc] init];
    timeTitle.text = @"时间";
    timeTitle.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    [content addSubview:timeTitle];
    [timeTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(dateTitle);
        make.leading.equalTo(content.mas_centerX).offset(10);
    }];
    
    UIButton *dateBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    dateBtn.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    dateBtn.layer.cornerRadius = 8;
    [dateBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    dateBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [dateBtn addTarget:self action:@selector(onPickDate) forControlEvents:UIControlEventTouchUpInside];
    [content addSubview:dateBtn];
    self.dateBtn = dateBtn;
    
    UIButton *timeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    timeBtn.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    timeBtn.layer.cornerRadius = 8;
    [timeBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    timeBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [timeBtn addTarget:self action:@selector(onPickTime) forControlEvents:UIControlEventTouchUpInside];
    [content addSubview:timeBtn];
    self.timeBtn = timeBtn;
    
    [dateBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(dateTitle.mas_bottom).offset(8);
        make.leading.equalTo(content).offset(18);
        make.trailing.equalTo(content.mas_centerX).offset(-8);
        make.height.mas_equalTo(44);
    }];
    [timeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(dateBtn);
        make.leading.equalTo(content.mas_centerX).offset(8);
        make.trailing.equalTo(content).offset(-18);
        make.height.equalTo(dateBtn);
    }];
    
    // 比赛感想
    UILabel *commentTitle = [[UILabel alloc] init];
    commentTitle.text = @"比赛感想";
    commentTitle.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    [content addSubview:commentTitle];
    [commentTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(timeBtn.mas_bottom).offset(18);
        make.leading.equalTo(content).offset(18);
    }];
    
    UITextView *commentView = [[UITextView alloc] init];
    commentView.font = [UIFont systemFontOfSize:14];
    commentView.delegate = self;
    commentView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
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
    commentCount.textColor = [UIColor lightGrayColor];
    [content addSubview:commentCount];
    self.commentCountLabel = commentCount;
    [commentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(commentTitle.mas_bottom).offset(8);
        make.leading.equalTo(content).offset(18);
        make.trailing.equalTo(content).offset(-18);
        make.height.mas_equalTo(100);
    }];
    [commentCount mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(commentView).offset(-8);
        make.bottom.equalTo(commentView).offset(-8);
    }];
    UILabel *ph = [[UILabel alloc] init];
    ph.text = @"请输入比赛心情~";
    ph.font = [UIFont systemFontOfSize:14];
    ph.textColor = [UIColor lightGrayColor];
    [content addSubview:ph];
    self.commentPlaceholderLabel = ph;
    [ph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(commentView).offset(8);
        make.top.equalTo(commentView).offset(8);
    }];
    
    UIButton *confirmBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [confirmBtn setTitle:@"确认" forState:UIControlStateNormal];
    [confirmBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    confirmBtn.backgroundColor = PNInputGreenColor();
    confirmBtn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    confirmBtn.layer.cornerRadius = 26;
    [confirmBtn addTarget:self action:@selector(onConfirmTapped) forControlEvents:UIControlEventTouchUpInside];
    [content addSubview:confirmBtn];
    [confirmBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(commentView.mas_bottom).offset(24);
        make.leading.equalTo(content).offset(18);
        make.trailing.equalTo(content).offset(-18);
        make.height.mas_equalTo(44);
    }];
    // 用确认按钮底部撑开 content 高度，使 scrollView 的 contentSize 正确，可滚动到底
    [content mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(confirmBtn.mas_bottom).offset(20);
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
        btn.titleLabel.font = [UIFont systemFontOfSize:12];
        btn.contentEdgeInsets = UIEdgeInsetsMake(6, 12, 6, 12);
        // 与设计图一致：未选中为圆角胶囊灰底，选中为白底绿色描边文字
        btn.layer.cornerRadius = 16;
        btn.layer.borderWidth = 1;
        btn.layer.borderColor = [UIColor colorWithWhite:0.82 alpha:1.0].CGColor;
        [btn setTitleColor:[UIColor colorWithWhite:0.4 alpha:1.0] forState:UIControlStateNormal];
        btn.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0];
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
            make.height.mas_equalTo(32);
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
    self.selectedEmotion = @"兴奋 🤩";
    self.selectedWatchInfo = @"在球场";
    self.selectedSeat = @"VIP看台";
    self.selectedReason = @"球迷";
    [self.selectedIdentities addObject:@"球迷"];
    [self.selectedIdentities addObject:@"媒体记者"];
    
    self.priceField.text = @"55.5";
    self.selectedDate = [NSDate date];
    [self refreshDateTimeButtons];
    self.commentView.text = @"";

    UIColor *unselBorder = [UIColor colorWithWhite:0.82 alpha:1.0];
    UIColor *unselText = [UIColor colorWithWhite:0.4 alpha:1.0];
    UIColor *unselBg = [UIColor colorWithWhite:0.96 alpha:1.0];
    // 选中样式：白底 + 绿色描边 + 绿色文字
    UIColor *selBorder = PNInputGreenColor();
    UIColor *selText = PNInputGreenColor();
    for (UIButton *b in self.watchButtons) {
        BOOL sel = [b.titleLabel.text isEqualToString:self.selectedWatchInfo];
        b.selected = sel;
        b.layer.borderWidth = 1;
        b.layer.borderColor = sel ? selBorder.CGColor : unselBorder.CGColor;
        b.backgroundColor = sel ? [UIColor whiteColor] : unselBg;
        [b setTitleColor:(sel ? selText : unselText) forState:UIControlStateNormal];
    }
    for (UIButton *b in self.seatButtons) {
        BOOL sel = [b.titleLabel.text isEqualToString:self.selectedSeat];
        b.selected = sel;
        b.layer.borderWidth = 1;
        b.layer.borderColor = sel ? selBorder.CGColor : unselBorder.CGColor;
        b.backgroundColor = sel ? [UIColor whiteColor] : unselBg;
        [b setTitleColor:(sel ? selText : unselText) forState:UIControlStateNormal];
    }
    for (UIButton *b in self.reasonButtons) {
        BOOL sel = [b.titleLabel.text isEqualToString:self.selectedReason];
        b.selected = sel;
        b.layer.borderWidth = 1;
        b.layer.borderColor = sel ? selBorder.CGColor : unselBorder.CGColor;
        b.backgroundColor = sel ? [UIColor whiteColor] : unselBg;
        [b setTitleColor:(sel ? selText : unselText) forState:UIControlStateNormal];
    }
    for (UIButton *b in self.identityButtons) {
        BOOL sel = [self.selectedIdentities containsObject:b.titleLabel.text];
        b.selected = sel;
        b.layer.borderWidth = 1;
        b.layer.borderColor = sel ? selBorder.CGColor : unselBorder.CGColor;
        b.backgroundColor = sel ? [UIColor whiteColor] : unselBg;
        [b setTitleColor:(sel ? selText : unselText) forState:UIControlStateNormal];
    }
    [self updateCommentCountLabel];
}

- (void)onDismiss {
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)onEmotionButtonTapped {
    self.emotionPanel.hidden = !self.emotionPanel.hidden;
    if (!self.emotionPanel.hidden) {
        [self.cardView bringSubviewToFront:self.emotionPanel];
    }
}

- (void)onEmotionOptionTapped:(UIButton *)sender {
    NSString *title = sender.titleLabel.text ?: @"";
    self.selectedEmotion = title;
    [self.emotionButton setTitle:[title stringByAppendingString:@" "] forState:UIControlStateNormal];
    if (@available(iOS 13.0, *)) {
        UIImage *chevron = [UIImage systemImageNamed:@"chevron.down"];
        if (chevron) [self.emotionButton setImage:[chevron imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
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
        sender.selected = !sender.selected;
        if (sender.selected) {
            sender.layer.borderWidth = 1;
            sender.layer.borderColor = PNInputGreenColor().CGColor;
            sender.backgroundColor = [UIColor whiteColor];
            [sender setTitleColor:PNInputGreenColor() forState:UIControlStateNormal];
            [self.selectedIdentities addObject:title];
        } else {
            sender.layer.borderWidth = 1;
            sender.layer.borderColor = [UIColor colorWithWhite:0.82 alpha:1.0].CGColor;
            sender.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0];
            [sender setTitleColor:[UIColor colorWithWhite:0.4 alpha:1.0] forState:UIControlStateNormal];
            [self.selectedIdentities removeObject:title];
        }
    } else {
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
            if (b == sender) {
                b.selected = YES;
                b.layer.borderWidth = 1;
                b.layer.borderColor = PNInputGreenColor().CGColor;
                b.backgroundColor = [UIColor whiteColor];
                [b setTitleColor:PNInputGreenColor() forState:UIControlStateNormal];
            } else {
                b.selected = NO;
                b.layer.borderWidth = 1;
                b.layer.borderColor = [UIColor colorWithWhite:0.82 alpha:1.0].CGColor;
                b.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0];
                [b setTitleColor:[UIColor colorWithWhite:0.4 alpha:1.0] forState:UIControlStateNormal];
            }
        }
    }
}

- (void)onConfirmTapped {
    // 当前仅回传完成状态，具体字段提交由上层接口接入时处理
    if (self.completion) {
        self.completion();
    }
    [self dismissViewControllerAnimated:NO completion:nil];
}

@end

