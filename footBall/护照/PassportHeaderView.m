//
//  PassportHeaderView.m
//  footBall
//

#import "PassportHeaderView.h"
#import "PassportViewModel.h"
#import "PassportWeekLineChartView.h"
#import "PassportHeader2View.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>
#import "WorldMapView.h"
#import "DashView.h"

static NSString *PassportHeaderSafeStatAt(NSArray<NSString *> *arr, NSUInteger i, NSString *fallback) {
    if (![arr isKindOfClass:[NSArray class]] || i >= arr.count) {
        return fallback ?: @"";
    }
    NSString *s = arr[i];
    return [s isKindOfClass:[NSString class]] ? s : (fallback ?: @"");
}

@interface PassportHeaderView (){
    CGFloat _circleLblWH;
}
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong) UIView *userInfoView; // 用户信息 头像昵称来自于 我的-个人信息页面
@property (nonatomic, strong) UIView *lineChartView;
@property (nonatomic, strong) UIView *rygCardView;//在2026年（所选时间）下  认证的场次 共看到了多少张红牌 多少张黄牌 多少场干净的没有牌的比赛 注意单位区别
@property (nonatomic, strong) UIView *globalMapView;
@property (nonatomic, strong) UIView *moneyView;//在2026年（所选时间）下  认证的场次 共花了多少钱2026总花费=2026消费记录总和+2026所有比赛门票钱
@property (nonatomic, strong) UIView *totalWatchTimeView;
@property (nonatomic, strong) UIView *nothingView;
@property (nonatomic, strong) PassportHeader2View *passportHeader2View;
//在2026年（所选时间）下  认证的场次 去了多少个国家
//对应的国家会被点亮
//0场是最浅色
//1-5场第二个颜色
//5-10场第三个颜色
//10-19场一个颜色
//20场+ 一个颜色
@property (nonatomic, strong) WorldMapView *worldMapView;
@property (nonatomic, strong) UILabel *moneyAmountLabel;

@property (nonatomic, strong) UILabel *idLabel;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *redCardLabel;
@property (nonatomic, strong) UILabel *yellowCardLabel;
@property (nonatomic, strong) UILabel *greenCardLabel;

@end

@implementation PassportHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        _circleLblWH = (SCREEN_WIDTH - 32) / 8.0;

        self.contentView = UIView.new;
        self.contentView.backgroundColor = [UIColor colorWithHexString:@"#FEFEFE"];
        self.contentView.layer.cornerRadius = 16;
        self.contentView.clipsToBounds = YES;
        [self addSubview:self.contentView];
        [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];

        self.topView = UIView.new;
        self.topView.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.topView];
        [self.topView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView).offset(16);
            make.left.equalTo(self.contentView).offset(16);
            make.right.equalTo(self.contentView).offset(-16);
            make.height.equalTo(@(_circleLblWH * 5));
        }];

        self.userInfoView = [self _userInfoView];
        [self.topView addSubview:self.userInfoView];
        self.lineChartView = [self _lineChartView];
        [self.topView addSubview:self.lineChartView];
        self.rygCardView = [self _rygCardView];
        [self.topView addSubview:self.rygCardView];
        self.globalMapView = [self _globalMapView];
        [self.topView addSubview:self.globalMapView];
        self.moneyView = [self _moneyView];
        [self.topView addSubview:self.moneyView];
        self.totalWatchTimeView = [self _totalWatchTimeView];
        [self.topView addSubview:self.totalWatchTimeView];
        self.nothingView = [self _nothingView];
        [self.topView addSubview:self.nothingView];

        [self addLines];

        UIImageView *sepMid = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"passport_header_sep"]];
        sepMid.contentMode = UIViewContentModeScaleToFill;
        [self.contentView addSubview:sepMid];
        UIView *sepFallbackLine = nil;
        if (!sepMid.image) {
            sepFallbackLine = [[UIView alloc] init];
            sepFallbackLine.backgroundColor = [UIColor colorWithHexString:@"#E0E0E0"];
            [self.contentView addSubview:sepFallbackLine];
        }
        DashView *sepMidDash = [[DashView alloc] init];
        sepMidDash.lineColor = [UIColor colorWithHexString:@"#E0E0E0"];
        [self.contentView addSubview:sepMidDash];

        self.passportHeader2View = [[PassportHeader2View alloc] initWithFrame:CGRectZero];
        self.passportHeader2View.userInteractionEnabled = YES;
        UITapGestureRecognizer *header2Tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handlePassportHeader2Tap)];
        [self.passportHeader2View addGestureRecognizer:header2Tap];
        [self.contentView addSubview:self.passportHeader2View];

        UIImageView *sepBottom = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"passport_header_sep"]];
        sepBottom.contentMode = UIViewContentModeScaleToFill;
        [self.contentView addSubview:sepBottom];
        UIView *sepBottomFallbackLine = nil;
        if (!sepBottom.image) {
            sepBottomFallbackLine = [[UIView alloc] init];
            sepBottomFallbackLine.backgroundColor = [UIColor colorWithHexString:@"#E0E0E0"];
            [self.contentView addSubview:sepBottomFallbackLine];
        }

//        UIImageView *footer2 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"passport_header_sep"]];
//        [self.contentView addSubview:footer2];

        CGFloat h = _circleLblWH;

        [self.userInfoView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.equalTo(self.topView);
            make.width.mas_equalTo(h * 4);
            make.height.mas_equalTo(h * 2);
        }];
        [self.lineChartView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.topView).offset(h * 4);
            make.top.equalTo(self.topView);
            make.width.mas_equalTo(h * 3);
            make.height.mas_equalTo(h * 2);
        }];
        [self.rygCardView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.topView).offset(h * 7);
            make.top.equalTo(self.topView);
            make.width.mas_equalTo(h);
            make.height.mas_equalTo(h * 3);
        }];
        [self.globalMapView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.topView);
            make.top.equalTo(self.topView).offset(h * 2);
            make.width.mas_equalTo(h * 4);
            make.height.mas_equalTo(h * 2);
        }];
        [self.nothingView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.topView).offset(h * 4);
            make.top.equalTo(self.topView).offset(h * 2);
            make.width.mas_equalTo(h * 3);
            make.height.mas_equalTo(h);
        }];
        [self.moneyView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.topView).offset(h * 4);
            make.top.equalTo(self.topView).offset(h * 3);
            make.width.mas_equalTo(h * 4);
            make.height.mas_equalTo(h);
        }];
        [self.totalWatchTimeView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.topView);
            make.top.equalTo(self.topView).offset(h * 4);
            make.height.mas_equalTo(h);
        }];

        [sepMid mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.topView.mas_bottom).offset(2);
            make.height.mas_equalTo(10);
            make.leading.trailing.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 10, 0, 10));
        }];
        if (sepFallbackLine) {
            [sepFallbackLine mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.topView.mas_bottom).offset(14);
                make.leading.trailing.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 10, 0, 10));
                make.height.mas_equalTo(1);
            }];
        }
        [sepMidDash mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(sepMid.mas_bottom).offset(2);
            make.leading.trailing.equalTo(self.contentView);
            make.height.mas_equalTo(1);
        }];
        [self.passportHeader2View mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.topView);
            make.top.equalTo(sepMidDash.mas_bottom).offset(7);
            make.height.mas_equalTo(_circleLblWH * 5);
        }];
        [sepBottom mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.passportHeader2View.mas_bottom).offset(3);
            make.height.mas_equalTo(10);
            make.leading.trailing.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 10, 0, 10));
            make.bottom.equalTo(self.contentView).offset(-16);
        }];
        if (sepBottomFallbackLine) {
            [sepBottomFallbackLine mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.passportHeader2View.mas_bottom).offset(15);
                make.leading.trailing.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 10, 0, 10));
                make.height.mas_equalTo(1);
                make.bottom.equalTo(self.contentView).offset(-16);
            }];
        }
//        [footer2 mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.left.right.equalTo(self.passportHeader2View);
//            make.top.equalTo(self.passportHeader2View.mas_bottom).offset(2);
//            make.bottom.equalTo(self.contentView).offset(-16);
//        }];
    }
    return self;
}
- (UIView *)_userInfoView {
    UIView *view = UIView.new;
//    view.layer.borderColor = [UIColor colorWithHexString:@"#000000"].CGColor;
//    view.layer.borderWidth = 0.5;
    view.layer.cornerRadius = 20;
    view.backgroundColor = [UIColor colorWithHexString:@"#0D2122"];
    
    UILabel *idlbl = UILabel.new;
    idlbl.font = FontManager.sharedManager.font16Regular;
    idlbl.textColor = [UIColor colorWithHexString:@"#FFFFFF"];
    [view addSubview:idlbl];
    self.idLabel = idlbl;
    
    UILabel *namelbl = UILabel.new;
    namelbl.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    namelbl.textColor = [UIColor colorWithHexString:@"#FFFFFF"];
    [view addSubview:namelbl];
    self.nameLabel = namelbl;
    [namelbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(idlbl);
        make.bottom.equalTo(view.mas_bottom).offset(-16);
    }];

    [idlbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@20);
        make.bottom.equalTo(namelbl.mas_top);
    }];

    return view;
}
- (UIView *)_lineChartView {
    PassportWeekLineChartView *view = [[PassportWeekLineChartView alloc] init];
    view.lineColor = [UIColor colorWithHexString:@"#FAD908"];
    return view;
}
- (UIView *)_rygCardView {
    UIView *view = UIView.new;
    self.redCardLabel = UILabel.new;
    self.redCardLabel.backgroundColor = [UIColor colorWithHexString:@"#FE0201"];
    self.redCardLabel.font = FontManager.sharedManager.font26Regular;
    self.redCardLabel.textColor = [UIColor colorWithHexString:@"#000000"];
    self.redCardLabel.textAlignment = NSTextAlignmentCenter;
    self.redCardLabel.layer.cornerRadius = _circleLblWH/2;
    self.redCardLabel.clipsToBounds = YES;
    [view addSubview:self.redCardLabel];
    self.yellowCardLabel = UILabel.new;
    self.yellowCardLabel.backgroundColor = [UIColor colorWithHexString:@"#FDD803"];
    self.yellowCardLabel.font = FontManager.sharedManager.font26Regular;
    self.yellowCardLabel.textColor = [UIColor colorWithHexString:@"#000000"];
    self.yellowCardLabel.textAlignment = NSTextAlignmentCenter;
    self.yellowCardLabel.layer.cornerRadius = _circleLblWH/2;
    self.yellowCardLabel.clipsToBounds = YES;
    [view addSubview:self.yellowCardLabel];
    self.greenCardLabel = UILabel.new;
    self.greenCardLabel.backgroundColor = [UIColor colorWithHexString:@"#03BA0A"];
    self.greenCardLabel.font = FontManager.sharedManager.font26Regular;
    self.greenCardLabel.textColor = [UIColor colorWithHexString:@"#000000"];
    self.greenCardLabel.textAlignment = NSTextAlignmentCenter;
    self.greenCardLabel.layer.cornerRadius = _circleLblWH/2;
    self.greenCardLabel.clipsToBounds = YES;
    [view addSubview:self.greenCardLabel];
    // 注意：此时 view 尚未 add 到 PassportHeaderView，子视图只能相对局部容器 view 约束，不能用 self
    [self.redCardLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(view);
        make.width.height.mas_equalTo(_circleLblWH);
        make.centerX.equalTo(view);
    }];
    [self.yellowCardLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(view);
        make.width.height.mas_equalTo(_circleLblWH);
    }];
    [self.greenCardLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(view);
        make.width.height.mas_equalTo(_circleLblWH);
        make.centerX.equalTo(view);
    }];
    return view;
}

- (UIView *)_globalMapView {
    UIView *view = UIView.new;
    view.layer.borderColor = [UIColor colorWithHexString:@"#000000"].CGColor;
    view.layer.borderWidth = 0.5;
    view.layer.cornerRadius = 20;
    view.backgroundColor = [UIColor colorWithHexString:@"#FFFFFF"];
    WorldMapView *map = [[WorldMapView alloc] init];
    map.strokeColor = [UIColor colorWithWhite:0 alpha:0];
    map.lineWidth = 0.5;
    map.minZoomScale = 1.0;
    map.maxZoomScale = 10.0;
    [view addSubview:map];
    [map loadGeoJSON];
    [map mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsMake(5, 10, 5, 10));
    }];
    self.worldMapView = map;

    return view;
}
- (UIView *)_moneyView {
    UIView *view = UIView.new;
    view.layer.borderColor = [UIColor colorWithHexString:@"#000000"].CGColor;
    view.layer.borderWidth = 0.5;
    view.layer.cornerRadius = _circleLblWH/2;
    view.backgroundColor = [UIColor colorWithHexString:@"#FFFFFF"];
    UILabel *unitLbl = UILabel.new;
    unitLbl.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
    unitLbl.textColor = [UIColor colorWithHexString:@"#000000"];
    unitLbl.text = @"人民币";
    [view addSubview:unitLbl];
    UILabel *amountLbl = UILabel.new;
    amountLbl.font = FontManager.sharedManager.font26Regular;
    amountLbl.textColor = [UIColor colorWithHexString:@"#060606"];
    amountLbl.text = @"999,999.99";
    [view addSubview:amountLbl];
    self.moneyAmountLabel = amountLbl;

    [unitLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(view).offset(-12);
        make.right.equalTo(view).offset(-25);
    }];
    [amountLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(unitLbl.mas_left).offset(-2);
        make.bottom.equalTo(unitLbl).offset(5);
    }];
    return view;
}
- (UIView *)_totalWatchTimeView {
    UIView *view = UIView.new;
    for (int i=0; i<8; i++) {
        UILabel *lbl = [self _cicrleLabel];
        lbl.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
        lbl.tag = 0xFF+i;
        [view addSubview:lbl];
        [lbl mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(view);
            make.width.height.mas_equalTo(_circleLblWH);
            make.centerX.equalTo(view).multipliedBy((2*i+1)/8.0);
        }];
        if (i>0) {
            UIView *line = [self newLine];
            [view addSubview:line];
            [line mas_makeConstraints:^(MASConstraintMaker *make) {
                make.height.equalTo(view);
                make.top.bottom.equalTo(view);
                make.width.equalTo(@0.25);
                make.right.equalTo(lbl.mas_left);
            }];
        }
    }
    return view;
}
- (UIView *)_nothingView {
    UIView *view = UIView.new;
    for (int i=0; i<3; i++) {
        UILabel *lbl = [self _cicrleLabel];
        lbl.tag = 0x300 + i;
        [view addSubview:lbl];
        [lbl mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(view);
            make.width.height.mas_equalTo(_circleLblWH);
            make.centerX.equalTo(view).multipliedBy((2*i+1)/3.0);
        }];
    }
    // 金钱胶囊上方 3 个圆：补齐 2 条分隔竖线，保证每个圆之间都可见
    for (int col = 1; col <= 2; col++) {
        UIView *line = [self newLine];
        [view addSubview:line];
        [line mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(view);
            make.width.equalTo(@0.5);
            make.left.equalTo(view).offset(_circleLblWH * col);
        }];
    }
    return view;
}
- (UILabel *)_cicrleLabel{
    UILabel *lbl = UILabel.new;
    lbl.font = FontManager.sharedManager.font26Regular;
    lbl.textColor = [UIColor colorWithHexString:@"#000000"];
    lbl.textAlignment = NSTextAlignmentCenter;
    lbl.layer.cornerRadius = _circleLblWH/2;
    lbl.clipsToBounds = YES;
    lbl.layer.borderColor = [UIColor colorWithHexString:@"#000000"].CGColor;
    lbl.layer.borderWidth = 0.5;
    return lbl;
}

- (UIView *)newLine {
    UIView *line = UIView.new;
    line.backgroundColor = [UIColor colorWithHexString:@"#000000"];
    return line;
}

- (void)addLines{
    // 网格：8列×5行，h = _circleLblWH
    // 行0-1: userInfo(4列) | lineChart(3列) | rygCard(1列)
    // 行2:   globalMap(4列) | nothingView(3列)
    // 行3:   globalMap(4列) | moneyView(4列)
    // 行4:   totalWatchTimeView(8列)
    CGFloat h = _circleLblWH;

    // ── 外框 ──
    UIView *leftLine = [self newLine];
    [self.topView addSubview:leftLine];
    [leftLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@0.5);
        make.left.top.bottom.equalTo(self.topView);
    }];
    UIView *rightLine = [self newLine];
    [self.topView addSubview:rightLine];
    [rightLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@0.5);
        make.right.top.bottom.equalTo(self.topView);
    }];
    UIView *topLine = [self newLine];
    [self.topView addSubview:topLine];
    [topLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@0.5);
        make.top.left.right.equalTo(self.topView);
    }];
    UIView *bottomLine = [self newLine];
    [self.topView addSubview:bottomLine];
    [bottomLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@0.5);
        make.bottom.left.right.equalTo(self.topView);
    }];

    // ── 竖线A: x=4h, y=0~4h（userInfo/globalMap 右边） ──
    UIView *verLineA = [self newLine];
    [self.topView addSubview:verLineA];
    [verLineA mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@0.5);
        make.left.equalTo(self.topView).offset(h * 4);
        make.top.equalTo(self.topView);
        make.height.equalTo(@(h * 4));
    }];

    // ── 竖线B: x=7h, y=0~3h（rygCard 左边，只到rygCard底部） ──
    UIView *verLineB = [self newLine];
    [self.topView addSubview:verLineB];
    [verLineB mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@0.5);
        make.right.equalTo(self.topView).offset(-h);
        make.top.equalTo(self.topView);
        make.height.equalTo(@(h * 3));
    }];

    // ── 横线1: y=2h, 到竖线B（不进入最右红黄绿列） ──
    UIView *horLine1 = [self newLine];
    [self.topView addSubview:horLine1];
    [horLine1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@0.5);
        make.top.equalTo(self.topView).offset(h * 2);
        make.left.equalTo(self.topView);
        make.right.equalTo(self.topView).offset(-h);
    }];

    // ── 横线2: y=3h, 从竖线A贯穿到最右边（位于金钱胶囊上方） ──
    UIView *horLine_yg = [self newLine];
    [self.topView addSubview:horLine_yg];
    [horLine_yg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@0.5);
        make.top.equalTo(self.topView).offset(h * 3);
        make.left.equalTo(self.topView).offset(h * 4);
        make.right.equalTo(self.topView);
    }];

    // ── 横线3: y=4h, 全宽（行3 底部） ──
    UIView *horLine2 = [self newLine];
    [self.topView addSubview:horLine2];
    [horLine2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@0.5);
        make.top.equalTo(self.topView).offset(h * 4);
        make.left.right.equalTo(self.topView);
    }];

    // ── totalWatchTimeView（行4）内部竖线：列1~7各一条 ──
    // _totalWatchTimeView 内部已有 i>0 的竖线，但用 centerX.multipliedBy 定位
    // 这里在 topView 层面补充，确保每列都有线
    for (int col = 1; col <= 7; col++) {
        UIView *vl = [self newLine];
        [self.topView addSubview:vl];
        CGFloat xOffset = h * col;
        [vl mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(@0.5);
            make.left.equalTo(self.topView).offset(xOffset);
            make.top.equalTo(self.topView).offset(h * 4);
            make.height.equalTo(@(h));
        }];
    }
}

- (void)configureWithModel:(PassportViewModel *)model {
    [self.passportHeader2View configureWithModel:model];
    if (!model) {
        return;
    }
    
    self.idLabel.text = model.headerPassportCodeLine.length ? model.headerPassportCodeLine : @"NO.0088";
    self.nameLabel.text = model.nickname.length ? model.nickname : @"";
    
    if ([self.lineChartView isKindOfClass:[PassportWeekLineChartView class]]) {
        PassportWeekLineChartView *chart = (PassportWeekLineChartView *)self.lineChartView;
        if (model.headerWeekLineValues.count == 7) {
            chart.weekValues = model.headerWeekLineValues;
        }
    }
    
    self.redCardLabel.text = [NSString stringWithFormat:@"%ld", (long)model.headerRedCards];
    self.yellowCardLabel.text = [NSString stringWithFormat:@"%ld", (long)model.headerYellowCards];
    self.greenCardLabel.text = [NSString stringWithFormat:@"%ld", (long)model.headerCleanMatches];
    
    if (self.moneyAmountLabel) {
        self.moneyAmountLabel.text = model.headerSpendingAmountText.length ? model.headerSpendingAmountText : @"0.00";
    }
    
    if (self.worldMapView) {
        self.worldMapView.oftenCountries = model.headerMapOftenISOs ?: @[];
        self.worldMapView.goneCountries = model.headerMapGoneISOs ?: @[];
        self.worldMapView.ungoCountries = model.headerMapUngoISOs ?: @[];
        [self.worldMapView reload];
    }
    
    
    // 所选赛季总观赛时长：来自 PassportViewModel.totalWatchTimeTexts（按位拆分，末位为“分”）
    // totalWatchTimeView 固定 8 个圆，做右对齐展示：不足则前面留空，超出则截取末尾 8 位
    NSArray<NSString *> *twt = model.totalWatchTimeTexts ?: @[];
    if (![twt isKindOfClass:NSArray.class]) {
        twt = @[];
    }
    NSInteger slots = 8;
    NSInteger count = (NSInteger)twt.count;
    NSInteger startIndexInSlots = MAX(0, slots - count);
    NSInteger startIndexInTexts = MAX(0, count - slots);
    for (NSInteger i = 0; i < slots; i++) {
        UILabel *lbl = (UILabel *)[self.totalWatchTimeView viewWithTag:0xFF + i];
        if (![lbl isKindOfClass:UILabel.class]) {
            continue;
        }
        NSInteger textIdx = (i - startIndexInSlots) + startIndexInTexts;
        if (textIdx >= 0 && textIdx < count) {
            id v = twt[(NSUInteger)textIdx];
            lbl.text = [v isKindOfClass:NSString.class] ? (NSString *)v : [NSString stringWithFormat:@"%@", v];
        } else {
            lbl.text = @"";
        }
    }
    
}

- (void)handlePassportHeader2Tap {
    if (self.onPassportHeader2Tap) {
        self.onPassportHeader2Tap();
    }
}

@end

