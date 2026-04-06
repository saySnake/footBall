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
@property (nonatomic, strong) UIView *userInfoView;
@property (nonatomic, strong) UIView *lineChartView;
@property (nonatomic, strong) UIView *rygCardView;
@property (nonatomic, strong) UIView *globalMapView;
@property (nonatomic, strong) UIView *moneyView;
@property (nonatomic, strong) UIView *scoresView;
@property (nonatomic, strong) UIView *nothingView;
@property (nonatomic, strong) PassportHeader2View *passportHeader2View;
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
        self.scoresView = [self _scoresView];
        [self.topView addSubview:self.scoresView];
        self.nothingView = [self _nothingView];
        [self.topView addSubview:self.nothingView];

        [self addLines];

//        UIImageView *footer = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"passport_header_sep"]];
//        [self.contentView addSubview:footer];
        DashView *dashLine = [[DashView alloc] init];
        dashLine.lineColor = [UIColor colorWithHexString:@"#E0E0E0"];
        [self.contentView addSubview:dashLine];

        self.passportHeader2View = [[PassportHeader2View alloc] initWithFrame:CGRectZero];
        self.passportHeader2View.userInteractionEnabled = YES;
        UITapGestureRecognizer *header2Tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handlePassportHeader2Tap)];
        [self.passportHeader2View addGestureRecognizer:header2Tap];
        [self.contentView addSubview:self.passportHeader2View];

//        UIImageView *footer2 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"passport_header_sep"]];
//        [self.contentView addSubview:footer2];

        [self.userInfoView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.equalTo(self.topView);
            make.height.equalTo(@(_circleLblWH * 2));
        }];
        [self.lineChartView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.topView);
            make.height.equalTo(@(_circleLblWH * 2));
            make.width.equalTo(@(_circleLblWH * 3));
            make.left.equalTo(self.userInfoView.mas_right);
            make.right.equalTo(self.rygCardView.mas_left).offset(-0.25);
        }];
        [self.rygCardView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.right.equalTo(self.topView);
            make.width.equalTo(@(_circleLblWH-0.25));
            make.height.equalTo(@(_circleLblWH * 3));
        }];
        [self.nothingView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(@(_circleLblWH * 3));
            make.right.equalTo(self.rygCardView.mas_left).offset(-0.25);
            make.left.equalTo(self.lineChartView);
            make.height.equalTo(@(_circleLblWH));
            make.top.equalTo(self.lineChartView.mas_bottom).offset(-0.25);
        }];
        [self.moneyView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.topView);
            make.top.equalTo(self.nothingView.mas_bottom);
            make.height.equalTo(@(_circleLblWH));
            make.left.equalTo(self.nothingView);
        }];
        [self.globalMapView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.topView);
            make.height.equalTo(@(_circleLblWH * 2));
            make.top.equalTo(self.userInfoView.mas_bottom).offset(0.25);
            make.right.equalTo(self.userInfoView);
        }];
        [self.scoresView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.topView);
            make.top.equalTo(self.globalMapView.mas_bottom);
            make.height.equalTo(@(_circleLblWH));
        }];

//        [footer mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.left.right.equalTo(self.topView);
//            make.top.equalTo(self.topView.mas_bottom).offset(2);
//        }];
        [dashLine mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.contentView);
            make.top.equalTo(self.topView.mas_bottom).offset(10);
            make.height.equalTo(@1);
        }];
        [self.passportHeader2View mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.topView);
            make.top.equalTo(dashLine.mas_bottom).offset(10);
            make.height.mas_equalTo(_circleLblWH * 5);
            make.bottom.equalTo(self.contentView).offset(-16);
        }];
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

    [idlbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@20);
        make.top.equalTo(view.mas_centerY);
    }];
    [namelbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(idlbl);
        make.top.equalTo(idlbl.mas_bottom);
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
- (UIView *)_scoresView {
    UIView *view = UIView.new;
    for (int i=0; i<8; i++) {
        UILabel *lbl = [self _cicrleLabel];
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
    // 防御：避免某些情况下子视图尚未创建导致 Masonry equalTo(nil) 崩溃
    UIView *globalMapView = self.globalMapView ?: self.topView;
    UIView *rygCardView = self.rygCardView ?: self.topView;
    UIView *nothingView = self.nothingView ?: self.topView;
    UIView *userInfoView = self.userInfoView ?: self.topView;
    UIView *scoresView = self.scoresView ?: self.topView;
    UIView *moneyView = self.moneyView ?: self.topView;

    UIView *leftLine = [self newLine];
    [self.topView addSubview:leftLine];
    [leftLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@0.25);
        make.left.equalTo(self.topView);
        make.top.equalTo(@0);
        make.bottom.equalTo(@(0));
    }];
    UIView *rightLine = [self newLine];
    [self.topView addSubview:rightLine];
    [rightLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@0.25);
        make.right.equalTo(self.topView);
        make.top.equalTo(@(0));
        make.bottom.equalTo(@(0));
    }];

    UIView *topLine = [self newLine];
    [self.topView addSubview:topLine];
    [topLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@0.25);
        make.top.equalTo(self.topView);
        make.left.equalTo(@(0));
        make.right.equalTo(@(0));
    }];

    UIView *bottomLine = [self newLine];
    [self.topView addSubview:bottomLine];
    [bottomLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@0.25);
        make.bottom.equalTo(self.topView);
        make.left.equalTo(@(0));
        make.right.equalTo(@(0));
    }];

    // 内部view之间的水平线
    UIView *subHorLine1= [self newLine];
    [self.topView addSubview:subHorLine1];
    [subHorLine1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@0.3);
        make.top.equalTo(userInfoView.mas_bottom);
        make.left.equalTo(self.topView);
        make.right.equalTo(rygCardView.mas_left);
    }];

    UIView *subHorLine2= [self newLine];
    [self.topView addSubview:subHorLine2];
    [subHorLine2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@0.25);
        make.top.equalTo(nothingView.mas_bottom);
        make.left.equalTo(globalMapView.mas_right);
        make.right.equalTo(self.topView);
    }];

    UIView *subHorLine3= [self newLine];
    [self.topView addSubview:subHorLine3];
    [subHorLine3 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@0.25);
        make.top.equalTo(globalMapView.mas_bottom);
        make.left.equalTo(self.topView);
        make.right.equalTo(self.topView);
    }];

    // 内部view之间的垂直线
    UIView *subVerLine1= [self newLine];
    [self.topView addSubview:subVerLine1];
    [subVerLine1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@0.25);
        make.left.equalTo(userInfoView.mas_right);
        make.top.equalTo(self.topView);
        make.bottom.equalTo(scoresView.mas_top);
    }];

    UIView *subVerLine2= [self newLine];
    [self.topView addSubview:subVerLine2];
    [subVerLine2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@0.25);
        make.top.equalTo(self.topView);
        make.bottom.equalTo(moneyView.mas_top);
        make.right.equalTo(rygCardView.mas_left);
    }];
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
        self.worldMapView.ungoCountries = @[];
        [self.worldMapView reload];
    }


    //TODO:总得分
    for (int i = 0; i < 8; i++) {
        UILabel *lbl = [self.scoresView viewWithTag:0xFF + i];
        if ([lbl isKindOfClass:[UILabel class]]) {
            lbl.text = PassportHeaderSafeStatAt(model.headerBottomStatTexts, (NSUInteger)i, @"—");
        }
    }
}

- (void)handlePassportHeader2Tap {
    if (self.onPassportHeader2Tap) {
        self.onPassportHeader2Tap();
    }
}

@end

