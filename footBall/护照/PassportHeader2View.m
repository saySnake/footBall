//
//  PassportHeader2View.m
//  footBall
//

#import "PassportHeader2View.h"
#import "PassportViewModel.h"
#import <Masonry/Masonry.h>

static UIColor *PassportCircleStrokeColor(void) {
    return [UIColor colorWithHexString:@"#000000"];
}

@interface PassportHeader2View ()
@property (nonatomic, assign) CGFloat circleWH;
@property (nonatomic, strong) CAShapeLayer *gridLayer;

@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *cityLabel;
@property (nonatomic, strong) UILabel *matchesLabel;
@property (nonatomic, strong) UILabel *afterLabel;

@property (nonatomic, strong) UILabel *minutesValueLabel;
@property (nonatomic, strong) UILabel *minutesUnitLabel;

@property (nonatomic, strong) UILabel *goalsValueLabel;
@property (nonatomic, strong) UILabel *goalsUnitLabel;

@property (nonatomic, strong) UILabel *citiesValueLabel;
@property (nonatomic, strong) UILabel *citiesUnitLabel;
@property (nonatomic, strong) UILabel *countriesValueLabel;
@property (nonatomic, strong) UILabel *countriesUnitLabel;

@property (nonatomic, strong) NSArray<UIView *> *iconCircles;
@property (nonatomic, strong) UILabel *yearPinkLabel;
@property (nonatomic, strong) UILabel *yearBlackLabel;
@end

@implementation PassportHeader2View

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor whiteColor];
        self.circleWH = (SCREEN_WIDTH-32) / 8.0;

        _gridLayer = [CAShapeLayer layer];
        _gridLayer.fillColor = [UIColor clearColor].CGColor;
        _gridLayer.strokeColor = PassportCircleStrokeColor().CGColor;
        _gridLayer.lineWidth = 0.5;
        [self.layer addSublayer:_gridLayer];

        [self buildContent];
        [self addLines];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (CGRectIsEmpty(self.bounds)) return;
//    [self rebuildGridLayer];
}

// MARK: - Public

- (void)configureWithModel:(PassportViewModel *)model {
    // 目前先按设计稿占位；后续按 model 字段再补全映射
    self.cityLabel.text = model.nickname.length ? model.nickname : @"上海";
}

// MARK: - UI

- (UIView *)circleContainer {
    UIView *v = [[UIView alloc] init];
    v.backgroundColor = [UIColor clearColor];
    v.layer.borderWidth = 0.5;
    v.layer.borderColor = PassportCircleStrokeColor().CGColor;
    v.layer.cornerRadius = self.circleWH / 2.0;
    v.clipsToBounds = YES;
    return v;
}

- (UILabel *)circleTextLabelWithFont:(UIFont *)font {
    UILabel *l = [[UILabel alloc] init];
    l.font = font;
    l.textColor = [UIColor colorWithHexString:@"#000000"];
    l.textAlignment = NSTextAlignmentCenter;
    l.numberOfLines = 2;
    return l;
}

- (void)buildContent {
    CGFloat wh = self.circleWH;

    // 头像（左上第一个圆）
    UIView *avatarCircle = [self circleContainer];
    [self addSubview:avatarCircle];
    _avatarView = [[UIImageView alloc] init];
    _avatarView.contentMode = UIViewContentModeScaleAspectFill;
    _avatarView.clipsToBounds = YES;
    _avatarView.layer.cornerRadius = wh / 2.0;
    [avatarCircle addSubview:_avatarView];
    [_avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(avatarCircle);
    }];
    //占位 第二个
    UIView *emptyCircle2 = [self circleContainer];
    [self addSubview:emptyCircle2];

    // 城市（第二个圆，靠上）
    UIView *cityCircle = [self circleContainer];
    [self addSubview:cityCircle];
    _cityLabel = [self circleTextLabelWithFont:[UIFont systemFontOfSize:16 weight:UIFontWeightBold]];
    _cityLabel.numberOfLines = 1;
    _cityLabel.text = @"上海";
    [cityCircle addSubview:_cityLabel];
    [_cityLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(cityCircle);
    }];

    UIView *emptyCircle4 = [self circleContainer];
    [self addSubview:emptyCircle4];
    UIView *emptyCircle5 = [self circleContainer];
    [self addSubview:emptyCircle5];
    UIView *emptyCircle6 = [self circleContainer];
    [self addSubview:emptyCircle6];
    UIView *emptyCircle7 = [self circleContainer];
    [self addSubview:emptyCircle7];
    UIView *emptyCircle8 = [self circleContainer];
    [self addSubview:emptyCircle8];

    NSArray *firstRowItems = @[avatarCircle,emptyCircle2,cityCircle,emptyCircle4,emptyCircle5,emptyCircle6,emptyCircle7,emptyCircle8];
    for (int i=0; i<firstRowItems.count; i++) {
        UIView *view = firstRowItems[i];
        [view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self);
            make.width.height.equalTo(@(wh));
            make.centerX.equalTo(self).multipliedBy((2*i+1)/8.0);
        }];
    }
    
    
    // “11 场”（左侧第二行）
    UIView *matchesCircle = [self circleContainer];
    [self addSubview:matchesCircle];
    [matchesCircle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self);
        make.top.equalTo(self).offset(wh);
        make.width.mas_equalTo(wh*2);
        make.height.equalTo(@(wh));
    }];
    _matchesLabel = [self circleTextLabelWithFont:FontManager.sharedManager.font26Regular];
    _matchesLabel.text = @"11";
    [matchesCircle addSubview:_matchesLabel];
    [_matchesLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(matchesCircle);
    }];
    UILabel *matchesUnitLabel = UILabel.new;
    matchesUnitLabel.text = @"场";
    matchesUnitLabel.font = [UIFont systemFontOfSize:10];
    matchesUnitLabel.textColor = [UIColor colorWithHexString:@"#131313"];
    [matchesCircle addSubview:matchesUnitLabel];
    [matchesUnitLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_matchesLabel.mas_right);
        make.bottom.equalTo(_matchesLabel).offset(-5);
    }];

    // “05 后”（第二行第二个圆）
    UIView *afterCircle = [self circleContainer];
    [self addSubview:afterCircle];
    [afterCircle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(matchesCircle.mas_right);
        make.top.equalTo(self).offset(wh);
        make.width.height.mas_equalTo(wh);
    }];
    _afterLabel = [self circleTextLabelWithFont:FontManager.sharedManager.font24Regular];
    _afterLabel.text = @"05";
    [afterCircle addSubview:_afterLabel];
    [_afterLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(afterCircle);
    }];
    UILabel *afterUnitLabel = UILabel.new;
    afterUnitLabel.text = @"后";
    afterUnitLabel.font = [UIFont systemFontOfSize:10];
    afterUnitLabel.textColor = [UIColor colorWithHexString:@"#131313"];
    [afterCircle addSubview:afterUnitLabel];
    [afterUnitLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_afterLabel.mas_right);
        make.bottom.equalTo(_afterLabel).offset(-5);
    }];

    // 2个空白占位
    UIView *empty2Circle3 = [self circleContainer];
    [self addSubview:empty2Circle3];
    UIView *empty2Circle4 = [self circleContainer];
    [self addSubview:empty2Circle4];
    [empty2Circle3 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(afterCircle.mas_right);
        make.top.equalTo(self).offset(wh);
        make.width.height.mas_equalTo(wh);
    }];
    [empty2Circle4 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(empty2Circle3.mas_right);
        make.top.equalTo(self).offset(wh);
        make.width.height.mas_equalTo(wh);
    }];

    // 绿色长条 “9500 分钟” （第三行，跨 3 个圆）
    UIView *minutesPill = [[UIView alloc] init];
    minutesPill.backgroundColor = [UIColor colorWithHexString:@"#5CB793"];
    minutesPill.layer.cornerRadius = wh / 2.0;
    minutesPill.clipsToBounds = YES;
    [self addSubview:minutesPill];
    [minutesPill mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self);
        make.top.equalTo(self).offset(wh * 2);
        make.height.mas_equalTo(wh);
        make.width.mas_equalTo(wh * 3);
    }];
    _minutesValueLabel = [[UILabel alloc] init];
    _minutesValueLabel.font = FontManager.sharedManager.font26Regular;
    _minutesValueLabel.textColor = [UIColor blackColor];
    _minutesValueLabel.text = @"9500";
    [minutesPill addSubview:_minutesValueLabel];
    _minutesUnitLabel = [[UILabel alloc] init];
    _minutesUnitLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
    _minutesUnitLabel.textColor = [UIColor blackColor];
    _minutesUnitLabel.text = @"分钟";
    [minutesPill addSubview:_minutesUnitLabel];
    [_minutesValueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(minutesPill);
        make.centerX.equalTo(minutesPill).offset(-10);
    }];
    [_minutesUnitLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_minutesValueLabel.mas_right).offset(2);
        make.bottom.equalTo(_minutesValueLabel).offset(-5);
    }];

    // 白色胶囊 “30 球” （第三行，居中偏右一个）
    UIView *goalsPill = [[UIView alloc] init];
    goalsPill.backgroundColor = [UIColor whiteColor];
    goalsPill.layer.borderWidth = 0.5;
    goalsPill.layer.borderColor = PassportCircleStrokeColor().CGColor;
    goalsPill.layer.cornerRadius = wh / 2.0;
    goalsPill.clipsToBounds = YES;
    [self addSubview:goalsPill];
    [goalsPill mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(wh * 3);
        make.top.equalTo(minutesPill);
        make.height.mas_equalTo(wh);
        make.width.mas_equalTo(wh * 2);
    }];
    _goalsValueLabel = [[UILabel alloc] init];
    _goalsValueLabel.font = FontManager.sharedManager.font26Regular;
    _goalsValueLabel.textColor = [UIColor blackColor];
    _goalsValueLabel.text = @"30";
    [goalsPill addSubview:_goalsValueLabel];
    _goalsUnitLabel = [[UILabel alloc] init];
    _goalsUnitLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
    _goalsUnitLabel.textColor = [UIColor blackColor];
    _goalsUnitLabel.text = @"球";
    [goalsPill addSubview:_goalsUnitLabel];
    [_goalsValueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(goalsPill);
        make.centerX.equalTo(goalsPill).offset(-8);
    }];
    [_goalsUnitLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_goalsValueLabel.mas_right).offset(2);
        make.bottom.equalTo(_goalsValueLabel).offset(-5);
    }];

    // 右侧两列统计（“20 城市”“6 国家”）
    UIView *citiesCircle = [self circleContainer];
    [self addSubview:citiesCircle];
    [citiesCircle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-wh * 2);
        make.top.equalTo(self).offset(wh);
        make.height.mas_equalTo(wh*2);
        make.width.mas_equalTo(wh);
    }];
    _citiesValueLabel = [self circleTextLabelWithFont:FontManager.sharedManager.font26Regular];
    _citiesValueLabel.text = @"20";
    _citiesValueLabel.numberOfLines = 1;
    [citiesCircle addSubview:_citiesValueLabel];
    _citiesUnitLabel = [[UILabel alloc] init];
    _citiesUnitLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
    _citiesUnitLabel.textColor = [UIColor blackColor];
    _citiesUnitLabel.text = @"城市";
    [citiesCircle addSubview:_citiesUnitLabel];
    [_citiesValueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(citiesCircle);
        make.centerY.equalTo(citiesCircle).offset(-6);
    }];
    [_citiesUnitLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(citiesCircle);
        make.top.equalTo(_citiesValueLabel.mas_bottom).offset(-2);
    }];

    UIView *countriesCircle = [self circleContainer];
    [self addSubview:countriesCircle];
    [countriesCircle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-wh);
        make.top.equalTo(self).offset(wh);
        make.height.mas_equalTo(wh*2);
        make.width.mas_equalTo(wh);
    }];
    _countriesValueLabel = [self circleTextLabelWithFont:FontManager.sharedManager.font26Regular];
    _countriesValueLabel.text = @"6";
    _countriesValueLabel.numberOfLines = 1;
    [countriesCircle addSubview:_countriesValueLabel];
    _countriesUnitLabel = [[UILabel alloc] init];
    _countriesUnitLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
    _countriesUnitLabel.textColor = [UIColor blackColor];
    _countriesUnitLabel.text = @"国家";
    [countriesCircle addSubview:_countriesUnitLabel];
    [_countriesValueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(countriesCircle);
        make.centerY.equalTo(countriesCircle).offset(-6);
    }];
    [_countriesUnitLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(countriesCircle);
        make.top.equalTo(_countriesValueLabel.mas_bottom).offset(-2);
    }];
    // 国家右边两个展位
    UIView *rightPlaceholder1 = [self circleContainer];
    [self addSubview:rightPlaceholder1];
    UIView *rightPlaceholder2 = [self circleContainer];
    [self addSubview:rightPlaceholder2];
    [rightPlaceholder1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self);
        make.width.height.equalTo(@(wh));
        make.top.equalTo(countriesCircle.mas_top);
    }];
    [rightPlaceholder2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self);
        make.width.height.equalTo(@(wh));
        make.top.equalTo(rightPlaceholder1.mas_bottom);
    }];
    // 第四排占位
    for (int i=0; i<8; i++) {
        UIView *c = [self circleContainer];
        [self addSubview:c];
        [c mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self).offset(wh*3);
            make.width.height.equalTo(@(wh));
            make.centerX.equalTo(self).multipliedBy((2*i+1)/8.0);
        }];
    }
    

    
    // 底部一排圆形按钮（设计稿 8 个，其中最后两个为年份）
    NSMutableArray *icons = [NSMutableArray array];
    for (NSInteger i = 0; i < 8; i++) {
        UIView *c = [self circleContainer];
        [self addSubview:c];
        [c mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(wh * i);
            make.bottom.equalTo(self);
            make.width.height.mas_equalTo(wh);
        }];
        [icons addObject:c];
    }
    self.iconCircles = icons;

    // 给前 5 个放占位图标（如果你有资源名，后面直接替换 imageNamed）
    NSArray<NSString *> *iconNames = @[ @"passport_icon_1", @"passport_icon_2", @"passport_icon_3", @"passport_icon_4", @"passport_icon_5" ];
    for (NSInteger i = 0; i < MIN(5, self.iconCircles.count); i++) {
        UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:iconNames[i]]];
        iv.contentMode = UIViewContentModeScaleAspectFit;
        [self.iconCircles[i] addSubview:iv];
        [iv mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.iconCircles[i]);
            make.width.height.mas_equalTo(wh * 0.55);
        }];
    }

    // 第 6、7 个：年份圆
    UIView *yearPink = self.iconCircles[6];
    yearPink.backgroundColor = [UIColor colorWithHexString:@"#F4B6CD"];
    yearPink.layer.borderWidth = 0;
    _yearPinkLabel = [[UILabel alloc] init];
    _yearPinkLabel.font = FontManager.sharedManager.font20Regular;
    _yearPinkLabel.textColor = [UIColor whiteColor];
    _yearPinkLabel.textAlignment = NSTextAlignmentCenter;
    _yearPinkLabel.text = @"2026";
    [yearPink addSubview:_yearPinkLabel];
    [_yearPinkLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(yearPink);
    }];

    UIView *yearBlack = self.iconCircles[7];
    yearBlack.backgroundColor = [UIColor blackColor];
    yearBlack.layer.borderWidth = 0;
    _yearBlackLabel = [[UILabel alloc] init];
    _yearBlackLabel.font = FontManager.sharedManager.font20Regular;
    _yearBlackLabel.textColor = [UIColor whiteColor];
    _yearBlackLabel.textAlignment = NSTextAlignmentCenter;
    _yearBlackLabel.text = @"2026";
    [yearBlack addSubview:_yearBlackLabel];
    [_yearBlackLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(yearBlack);
    }];
}

// MARK: - Grid

- (void)rebuildGridLayer {
    CGFloat wh = self.circleWH;
    CGFloat W = CGRectGetWidth(self.bounds);
    CGFloat H = CGRectGetHeight(self.bounds);

    NSInteger cols = (NSInteger)ceil(W / wh);
    NSInteger rows = (NSInteger)ceil(H / wh);

    UIBezierPath *p = [UIBezierPath bezierPath];
    for (NSInteger r = 0; r <= rows; r++) {
        for (NSInteger c = 0; c <= cols; c++) {
            CGFloat x = c * wh;
            CGFloat y = r * wh;
            CGRect rect = CGRectMake(x, y, wh, wh);
            [p appendPath:[UIBezierPath bezierPathWithOvalInRect:rect]];
        }
    }
    self.gridLayer.frame = self.bounds;
    self.gridLayer.path = p.CGPath;
}
- (UIView *)newLine {
    UIView *line = UIView.new;
    line.backgroundColor = [UIColor colorWithHexString:@"#000000"];
    return line;
}

- (void)addLines{
    CGFloat wh = self.circleWH;
    UIView *leftLine = [self newLine];
    [self addSubview:leftLine];
    [leftLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@0.25);
        make.left.equalTo(self);
        make.top.equalTo(@(wh));
        make.bottom.equalTo(@(0));
    }];

    UIView *topLine = [self newLine];
    [self addSubview:topLine];
    [topLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@0.25);
        make.top.equalTo(self);
        make.left.equalTo(@(0));
        make.right.equalTo(@(0));
    }];


    // 内部view之间的水平线
    UIView *subHorLine1= [self newLine];
    [self addSubview:subHorLine1];
    [subHorLine1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@0.25);
        make.top.equalTo(@(wh));
        make.left.equalTo(self);
        make.right.equalTo(self);
    }];

    UIView *subHorLine2= [self newLine];
    [self addSubview:subHorLine2];
    [subHorLine2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@0.25);
        make.top.equalTo(subHorLine1.mas_bottom).offset(wh);
        make.left.equalTo(self);
        make.right.equalTo(self).offset(-3*wh);
    }];

    UIView *subHorLine3= [self newLine];
    [self addSubview:subHorLine3];
    [subHorLine3 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@0.25);
        make.top.equalTo(subHorLine2.mas_bottom).offset(wh);
        make.left.equalTo(self);
        make.right.equalTo(self);
    }];
    UIView *subHorLine4= [self newLine];
    [self addSubview:subHorLine4];
    [subHorLine4 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@0.25);
        make.top.equalTo(subHorLine3.mas_bottom).offset(wh);
        make.left.equalTo(self);
        make.right.equalTo(self);
    }];

    
    // 内部view之间的垂直线
}


@end

