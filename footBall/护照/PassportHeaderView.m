//
//  PassportHeaderView.m
//  footBall
//

#import "PassportHeaderView.h"
#import "PassportViewModel.h"
#import "PassportWeekLineChartView.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>
#import "WorldMapView.h"
static UIColor *PassportGreen(void) {
    return [UIColor colorWithRed:0.157 green:0.365 blue:0.294 alpha:1.0];
}

@interface PassportHeaderView (){
    CGFloat _circleLblWH;
}
@property (nonatomic, strong) UILabel *idLabel;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *redCardLabel;
@property (nonatomic, strong) UILabel *yellowCardLabel;
@property (nonatomic, strong) UILabel *greenCardLabel;

@end

@implementation PassportHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor whiteColor];
        _circleLblWH = (frame.size.width == 0 ? SCREEN_WIDTH : frame.size.width)/8;
        UIView *userInfoView = [self userInfoView];
        [self addSubview:userInfoView];
        UIView *lineChartView = [self lineChartView];
        [self addSubview:lineChartView];
        UIView *rygCardView = [self rygCardView];
        [self addSubview:rygCardView];
        UIView *globalMapView = [self globalMapView];
        [self addSubview:globalMapView];
        UIView *moneyView = [self moneyView];
        [self addSubview:moneyView];
        UIView *scoresView = [self scoresView];
        [self addSubview:scoresView];
        UIView *nothingView = [self nothingView];
        [self addSubview:nothingView];

        //P<<COOPER<<HELEN<<<<<<<<<COOPER<<<<<=
        UIImageView *footer = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"passport_header_sep"]];
        [self addSubview:footer];

        
        
        [userInfoView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.equalTo(self);
            make.height.equalTo(@(_circleLblWH*2));
//            make.width.equalTo(@(171));
        }];
        [lineChartView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self);
            make.height.equalTo(@(_circleLblWH*2));
            make.width.equalTo(@(_circleLblWH*3));
            make.left.equalTo(userInfoView.mas_right);
            make.right.equalTo(rygCardView.mas_left);
        }];
        [rygCardView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.right.equalTo(self);
            make.width.equalTo(@(_circleLblWH));
            make.height.equalTo(@(_circleLblWH*3));
        }];
        [nothingView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(@(_circleLblWH*3));
            make.right.equalTo(rygCardView.mas_left);
            make.left.equalTo(lineChartView);
            make.height.equalTo(@(_circleLblWH));
            make.top.equalTo(lineChartView.mas_bottom);
        }];
        [moneyView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self);
            make.top.equalTo(nothingView.mas_bottom);
            make.height.equalTo(@(_circleLblWH));
            make.left.equalTo(nothingView);
        }];
        [globalMapView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self);
            make.height.equalTo(@(_circleLblWH*2));
            make.top.equalTo(userInfoView.mas_bottom);
            make.right.equalTo(userInfoView);
        }];
        [scoresView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self);
            make.top.equalTo(globalMapView.mas_bottom);
            make.height.equalTo(@(_circleLblWH));
        }];
        
        [footer mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self);
            make.top.equalTo(scoresView.mas_bottom).offset(2);
            make.bottom.equalTo(self);
        }];
        
        
    }
    return self;
}
- (UIView *)userInfoView {
    UIView *view = UIView.new;
    view.layer.borderColor = [UIColor colorWithHexString:@"#000000"].CGColor;
    view.layer.borderWidth = 0.5;
    view.layer.cornerRadius = 20;
    view.backgroundColor = [UIColor colorWithHexString:@"#E6E6E6"];
    
    UILabel *idlbl = UILabel.new;
    idlbl.font = FontManager.sharedManager.font16Regular;
    idlbl.textColor = [UIColor colorWithHexString:@"#34343B"];
    [view addSubview:idlbl];
    self.idLabel = idlbl;
    
    UILabel *namelbl = UILabel.new;
    namelbl.font = FontManager.sharedManager.font16Bold;
    namelbl.textColor = [UIColor colorWithHexString:@"#285D4B"];
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
- (UIView *)lineChartView {
    PassportWeekLineChartView *view = [[PassportWeekLineChartView alloc] init];
    return view;
}
- (UIView *)rygCardView {
    UIView *view = UIView.new;
    self.redCardLabel = UILabel.new;
    self.redCardLabel.backgroundColor = [UIColor colorWithHexString:@"#CD5150"];
    self.redCardLabel.font = FontManager.sharedManager.font26;
    self.redCardLabel.textColor = [UIColor colorWithHexString:@"#000000"];
    self.redCardLabel.textAlignment = NSTextAlignmentCenter;
    self.redCardLabel.layer.cornerRadius = _circleLblWH/2;
    self.redCardLabel.clipsToBounds = YES;
    [view addSubview:self.redCardLabel];
    self.yellowCardLabel = UILabel.new;
    self.yellowCardLabel.backgroundColor = [UIColor colorWithHexString:@"#F7E05C"];
    self.yellowCardLabel.font = FontManager.sharedManager.font26;
    self.yellowCardLabel.textColor = [UIColor colorWithHexString:@"#000000"];
    self.yellowCardLabel.textAlignment = NSTextAlignmentCenter;
    self.yellowCardLabel.layer.cornerRadius = _circleLblWH/2;
    self.yellowCardLabel.clipsToBounds = YES;
    [view addSubview:self.yellowCardLabel];
    self.greenCardLabel = UILabel.new;
    self.greenCardLabel.backgroundColor = [UIColor colorWithHexString:@"#5CB793"];
    self.greenCardLabel.font = FontManager.sharedManager.font26;
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

- (UIView *)globalMapView {
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
    map.oftenCountries = @[ @"CN", @"JP" ];
    map.goneCountries = @[ @"US", @"GB" ];
    map.ungoCountries = @[ @"FR", @"DE" ];
    [map reload];

    return view;
}
- (UIView *)moneyView {
    UIView *view = UIView.new;
    view.layer.borderColor = [UIColor colorWithHexString:@"#000000"].CGColor;
    view.layer.borderWidth = 0.5;
    view.layer.cornerRadius = 20;
    view.backgroundColor = [UIColor colorWithHexString:@"#FFFFFF"];
    UILabel *unitLbl = UILabel.new;
    unitLbl.font = FontManager.sharedManager.font10;
    unitLbl.textColor = [UIColor colorWithHexString:@"#787878"];
    unitLbl.text = @"RMB";
    [view addSubview:unitLbl];
    UILabel *amountLbl = UILabel.new;
    amountLbl.font = FontManager.sharedManager.font30Regular;
    amountLbl.textColor = [UIColor colorWithHexString:@"#060606"];
    amountLbl.text = @"999,999.99";
    [view addSubview:amountLbl];

    [unitLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(view).offset(-15);
        make.right.equalTo(view).offset(-20);
    }];
    [amountLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(unitLbl.mas_left).offset(-2);
        make.bottom.equalTo(unitLbl).offset(2);
    }];
    return view;
}
- (UIView *)scoresView {
    UIView *view = UIView.new;
    for (int i=0; i<8; i++) {
        UILabel *lbl = [self cicrleLabel];
        lbl.tag = 0xFF+i;
        [view addSubview:lbl];
        [lbl mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(view);
            make.width.height.mas_equalTo(_circleLblWH);
            make.centerX.equalTo(view).multipliedBy((2*i+1)/8.0);
        }];
    }
    return view;
}
- (UIView *)nothingView {
    UIView *view = UIView.new;
    for (int i=0; i<3; i++) {
        UILabel *lbl = [self cicrleLabel];
        [view addSubview:lbl];
        [lbl mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(view);
            make.width.height.mas_equalTo(_circleLblWH);
            make.centerX.equalTo(view).multipliedBy((2*i+1)/3.0);
        }];
    }
    return view;
}
- (UILabel *)cicrleLabel{
    UILabel *lbl = UILabel.new;
    lbl.font = FontManager.sharedManager.font26;
    lbl.textColor = [UIColor colorWithHexString:@"#000000"];
    lbl.textAlignment = NSTextAlignmentCenter;
    lbl.layer.cornerRadius = _circleLblWH/2;
    lbl.clipsToBounds = YES;
    lbl.layer.borderColor = [UIColor colorWithHexString:@"#000000"].CGColor;
    lbl.layer.borderWidth = 0.5;
    return lbl;
}
- (void)configureWithModel:(PassportViewModel *)model {
}

@end
