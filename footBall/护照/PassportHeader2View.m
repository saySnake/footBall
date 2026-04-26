//
//  PassportHeader2View.m
//  footBall
//

#import "PassportHeader2View.h"
#import "PassportViewModel.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>

static UIColor *PassportCircleStrokeColor(void) {
    return [UIColor colorWithHexString:@"#000000"];
}

@interface PassportHeader2View ()
@property (nonatomic, assign) CGFloat circleWH;
@property (nonatomic, strong) CAShapeLayer *gridLayer;

@property (nonatomic, strong) UIImageView *avatarView;//用户信息 头像昵称来自于 我的-个人信息页面
@property (nonatomic, strong) UILabel *cityLabel;////用户信息 头像昵称来自于 我的-个人信息页面
@property (nonatomic, strong) NSArray<UIView *> *teamIconCircles;

@property (nonatomic, strong) UILabel *matchesLabel;//个人2026年份总观看场次，有年份因素限制 选中赛季 认证几场的场次 game number 2026 SUM
@property (nonatomic, strong) UILabel *matchesUnitLabel;
@property (nonatomic, strong) UILabel *afterLabel;
@property (nonatomic, strong) UILabel *afterUnitLabel;

@property (nonatomic, strong) UILabel *minutesValueLabel;//个人2026年总时间，有年份因素限制 选中赛季几场的总时间 TIME 2026 SUM
@property (nonatomic, strong) UILabel *minutesUnitLabel;

@property (nonatomic, strong) UILabel *goalsValueLabel;//个人2026年份总进球见证，有年份因素限制 选中赛季 认证几场的总进球 GOAL 2026 SUM
@property (nonatomic, strong) UILabel *goalsUnitLabel;

//在2026年（所选时间）下  认证的场次 共覆盖几个城市就是多少城市 例如2026年小明去过 看过100场北京国安主场 但只看过北京国安主场 那么城市还是=1 因为就是北京
@property (nonatomic, strong) UILabel *citiesValueLabel;
@property (nonatomic, strong) UILabel *citiesUnitLabel;
//在2026年（所选时间）下 认证的场次 共覆盖几个国家就是多少国家 例如2026年小明去过 看过100场中超 但只看过中超 那么国家还是=1 因为就是中国
@property (nonatomic, strong) UILabel *countriesValueLabel;
@property (nonatomic, strong) UILabel *countriesUnitLabel;

@property (nonatomic, strong) NSArray<UIView *> *iconCircles;
@property (nonatomic, strong) UILabel *countRedLabel;
@property (nonatomic, strong) UILabel *yearPinkLabel;
@property (nonatomic, strong) UILabel *yearBlackLabel;
@end

@implementation PassportHeader2View

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor whiteColor];
        if (frame.size.width > 0) {
            self.circleWH = (frame.size.width-32) / 8.0;
        } else {
            self.circleWH = (SCREEN_WIDTH-32) / 8.0;
        }

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
    if (!model) {
        return;
    }

    NSURL *avURL = model.avatarURL.length ? [NSURL URLWithString:model.avatarURL] : nil;
    UIImage *avPh = nil;
    if (@available(iOS 13.0, *)) {
        avPh = [[UIImage systemImageNamed:@"person.crop.circle.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    self.avatarView.tintColor = [UIColor colorWithHexString:@"#9E9E9E"];
    self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
    __weak typeof(self) weakSelf = self;
    [self.avatarView sd_setImageWithURL:avURL placeholderImage:avPh completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (!image || error) {
            return;
        }
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        strongSelf.avatarView.tintColor = [UIColor clearColor];
        strongSelf.avatarView.contentMode = UIViewContentModeScaleAspectFill;
    }];

    self.cityLabel.text = model.userCity.length ? model.userCity : @"—-";

    self.matchesLabel.text = [NSString stringWithFormat:@"%ld", (long)MAX(0, model.header2YearMatchCount)];
    NSString *matchUnit = NSLocalizedString(@"passport_unit_matches", nil);
    if (!matchUnit.length || [matchUnit isEqualToString:@"passport_unit_matches"]) {
        matchUnit = @"场";
    }
    self.matchesUnitLabel.text = matchUnit;

    BOOL hasGen = model.header2GenerationMainText.length > 0;
    self.afterLabel.text = hasGen ? model.header2GenerationMainText : @"—";
    NSString *genSuffix = NSLocalizedString(@"passport_unit_generation_suffix", nil);
    if (!genSuffix.length || [genSuffix isEqualToString:@"passport_unit_generation_suffix"]) {
        genSuffix = @"后";
    }
    self.afterUnitLabel.text = genSuffix;
    self.afterUnitLabel.hidden = !(hasGen && model.header2GenerationHasHouSuffix);

    self.minutesValueLabel.text = [NSString stringWithFormat:@"%ld", (long)MAX(0, model.header2YearWatchMinutes)];
    NSString *minUnit = NSLocalizedString(@"passport_unit_minutes_short", nil);
    if (!minUnit.length || [minUnit isEqualToString:@"passport_unit_minutes_short"]) {
        minUnit = @"分钟";
    }
    self.minutesUnitLabel.text = minUnit;

    self.goalsValueLabel.text = [NSString stringWithFormat:@"%ld", (long)MAX(0, model.header2YearGoals)];
    NSString *goalUnit = NSLocalizedString(@"passport_unit_goals", nil);
    if (!goalUnit.length || [goalUnit isEqualToString:@"passport_unit_goals"]) {
        goalUnit = @"球";
    }
    self.goalsUnitLabel.text = goalUnit;

    self.citiesValueLabel.text = [NSString stringWithFormat:@"%ld", (long)MAX(0, model.header2CityCount)];
    NSString *cityUnit = NSLocalizedString(@"passport_unit_cities", nil);
    if (!cityUnit.length || [cityUnit isEqualToString:@"passport_unit_cities"]) {
        cityUnit = @"城市";
    }
    self.citiesUnitLabel.text = cityUnit;

    self.countriesValueLabel.text = [NSString stringWithFormat:@"%ld", (long)MAX(0, model.header2CountryCount)];
    NSString *countryUnit = NSLocalizedString(@"passport_unit_countries", nil);
    if (!countryUnit.length || [countryUnit isEqualToString:@"passport_unit_countries"]) {
        countryUnit = @"国家";
    }
    self.countriesUnitLabel.text = countryUnit;

    NSString *yearStr = [NSString stringWithFormat:@"%ld", (long)model.displayYear];
    self.yearPinkLabel.text = yearStr;
    self.yearBlackLabel.text = yearStr;

    NSArray<NSString *> *urls = model.header2FollowedTeamLogoURLs;
    for (NSInteger i = 0; i < MIN(5, (NSInteger)self.teamIconCircles.count); i++) {
        UIView *circle = self.teamIconCircles[i];
        UIImageView *iv = (UIImageView *)[circle viewWithTag:0xFF];
        if (!iv) {
            continue;
        }
        NSString *u = (urls && i < (NSInteger)urls.count) ? urls[(NSUInteger)i] : nil;
        if (u.length) {
            [iv sd_setImageWithURL:[NSURL URLWithString:u]];
        } else {
            [iv sd_cancelCurrentImageLoad];
            iv.image = nil;
        }
    }
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
    self.teamIconCircles = @[emptyCircle4,emptyCircle5,emptyCircle6,emptyCircle7,emptyCircle8];
    
    NSArray *firstRowItems = [@[avatarCircle,emptyCircle2,cityCircle] arrayByAddingObjectsFromArray:self.teamIconCircles];
    for (int i=0; i<firstRowItems.count; i++) {
        UIView *view = firstRowItems[i];
        [view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self);
            make.width.height.equalTo(@(wh));
            make.centerX.equalTo(self).multipliedBy((2*i+1)/8.0);
        }];
        if ([self.teamIconCircles containsObject:view]) {
            UIImageView *iv = [[UIImageView alloc] init];
            iv.tag = 0xFF;
            iv.contentMode = UIViewContentModeScaleAspectFit;
            [view addSubview:iv];
            [iv mas_makeConstraints:^(MASConstraintMaker *make) {
                make.center.equalTo(view);
                make.width.height.equalTo(view).multipliedBy(0.707);//圆内切正方形宽高
            }];
        }
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
    matchesUnitLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    matchesUnitLabel.textColor = [UIColor colorWithHexString:@"#090909"];
    [matchesCircle addSubview:matchesUnitLabel];
    self.matchesUnitLabel = matchesUnitLabel;
    [matchesUnitLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_matchesLabel.mas_right).offset(2);
        make.bottom.equalTo(_matchesLabel).offset(-6);
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
        make.centerY.equalTo(afterCircle);
        make.centerX.equalTo(afterCircle).offset(-6);
    }];
    UILabel *afterUnitLabel = UILabel.new;
    afterUnitLabel.text = @"后";
    afterUnitLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    afterUnitLabel.textColor = [UIColor colorWithHexString:@"#090909"];
    [afterCircle addSubview:afterUnitLabel];
    self.afterUnitLabel = afterUnitLabel;
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
    _minutesUnitLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    _minutesUnitLabel.textColor = [UIColor colorWithHexString:@"#090909"];
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
    _goalsUnitLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    _goalsUnitLabel.textColor = [UIColor colorWithHexString:@"#090909"];
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
    _citiesUnitLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    _citiesUnitLabel.textColor = [UIColor colorWithHexString:@"#090909"];
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
    _countriesUnitLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    _countriesUnitLabel.textColor = [UIColor colorWithHexString:@"#090909"];
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
    NSArray *bottomItemBgColors=@[@"#F5001F",@"#000000",@"#8E17A8",@"#00938F",@"#960060",@"",@"#FEB7DF",@"#000000"];
    for (NSInteger i = 0; i < bottomItemBgColors.count; i++) {
        UIView *c = [self circleContainer];
        NSString *colorHex = bottomItemBgColors[i];
        if (colorHex.length > 0) {
            c.backgroundColor = [UIColor colorWithHexString:bottomItemBgColors[i]];
        }
        [self addSubview:c];
        [c mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(wh * i);
            make.bottom.equalTo(self);
            make.width.height.mas_equalTo(wh);
        }];
        [icons addObject:c];
    }
    self.iconCircles = icons;
    // 第1个 数量
    UIView *countRed = self.iconCircles[0];
    self.countRedLabel = [[UILabel alloc] init];
    _countRedLabel.font = FontManager.sharedManager.font22Regular;
    _countRedLabel.textColor = [UIColor whiteColor];
    _countRedLabel.textAlignment = NSTextAlignmentCenter;
    _countRedLabel.text = @"5000";
    [countRed addSubview:_countRedLabel];
    [_countRedLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(countRed);
    }];

    // 给前 2-5 个放占位图标（如果你有资源名，后面直接替换 imageNamed）
    NSArray<NSString *> *iconNames = @[ @"", @"passport_icon_2", @"passport_icon_3", @"passport_icon_4", @"passport_icon_5" ];
    for (NSInteger i = 1; i < MIN(5, self.iconCircles.count); i++) {
        UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:iconNames[i]]];
        iv.contentMode = UIViewContentModeScaleAspectFit;
        [self.iconCircles[i] addSubview:iv];
        [iv mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.iconCircles[i]);
//            make.width.height.mas_equalTo(wh * 0.55);
        }];
    }

    // 第 6、7 个：年份圆
    UIView *yearPink = self.iconCircles[6];
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
    CGFloat lineW = 0.5;

    // 外框（下半部分也统一有边）
    UIView *leftLine = [self newLine];
    [self addSubview:leftLine];
    [leftLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(lineW);
        make.left.top.bottom.equalTo(self);
    }];

    UIView *rightLine = [self newLine];
    [self addSubview:rightLine];
    [rightLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(lineW);
        make.right.top.bottom.equalTo(self);
    }];

    UIView *topLine = [self newLine];
    [self addSubview:topLine];
    [topLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(lineW);
        make.top.left.right.equalTo(self);
    }];

    UIView *bottomLine = [self newLine];
    [self addSubview:bottomLine];
    [bottomLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(lineW);
        make.bottom.left.right.equalTo(self);
    }];

    // 水平分隔线：按胶囊跨度分段，避免穿过跨行胶囊
    UIView *h1 = [self newLine]; // y=1h（整行）
    [self addSubview:h1];
    [h1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(lineW);
        make.top.equalTo(self).offset(wh);
        make.left.right.equalTo(self);
    }];

    // 顶排 8 个圆之间的竖线（只覆盖 y=0~1h）
    for (int col = 1; col <= 7; col++) {
        UIView *vTop = [self newLine];
        [self addSubview:vTop];
        [vTop mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(lineW);
            make.left.equalTo(self).offset(wh * col);
            make.top.equalTo(self);
            make.height.mas_equalTo(wh);
        }];
    }

    UIView *h2Left = [self newLine]; // y=2h（左侧到第5列）
    [self addSubview:h2Left];
    [h2Left mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(lineW);
        make.top.equalTo(self).offset(wh * 2);
        make.left.equalTo(self);
        make.right.equalTo(self).offset(-wh * 3);
    }];

    UIView *h2Right = [self newLine]; // y=2h（最右第8列占位）
    [self addSubview:h2Right];
    [h2Right mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(lineW);
        make.top.equalTo(self).offset(wh * 2);
        make.left.equalTo(self).offset(wh * 7);
        make.right.equalTo(self);
    }];

    UIView *h3 = [self newLine]; // y=3h（整行）
    [self addSubview:h3];
    [h3 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(lineW);
        make.top.equalTo(self).offset(wh * 3);
        make.left.right.equalTo(self);
    }];

    UIView *h4 = [self newLine]; // y=4h（整行）
    [self addSubview:h4];
    [h4 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(lineW);
        make.top.equalTo(self).offset(wh * 4);
        make.left.right.equalTo(self);
    }];

    // 竖向分隔线：逐段补齐每个胶囊之间
    // x=1h（第三行左侧为跨列胶囊，不穿过该行；从 y=3h 往下）
    UIView *v1 = [self newLine];
    [self addSubview:v1];
    [v1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(lineW);
        make.left.equalTo(self).offset(wh);
        make.top.equalTo(self).offset(wh * 3);
        make.bottom.equalTo(self);
    }];

    // x=2h（第三行左侧为跨列胶囊，分段绘制：y=1~2 与 y=3~5）
    UIView *v2Top = [self newLine];
    [self addSubview:v2Top];
    [v2Top mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(lineW);
        make.left.equalTo(self).offset(wh * 2);
        make.top.equalTo(self).offset(wh);
        make.height.mas_equalTo(wh);
    }];
    UIView *v2Bottom = [self newLine];
    [self addSubview:v2Bottom];
    [v2Bottom mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(lineW);
        make.left.equalTo(self).offset(wh * 2);
        make.top.equalTo(self).offset(wh * 3);
        make.bottom.equalTo(self);
    }];

    // x=3h（第三行为胶囊，分段绘制：y=1~2 与 y=3~5）
    UIView *v3Top = [self newLine];
    [self addSubview:v3Top];
    [v3Top mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(lineW);
        make.left.equalTo(self).offset(wh * 3);
        make.top.equalTo(self).offset(wh);
        make.height.mas_equalTo(wh);
    }];
    UIView *v3Bottom = [self newLine];
    [self addSubview:v3Bottom];
    [v3Bottom mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(lineW);
        make.left.equalTo(self).offset(wh * 3);
        make.top.equalTo(self).offset(wh * 3);
        make.bottom.equalTo(self);
    }];

    // x=4h（第三行为胶囊，分段绘制：y=1~2 与 y=3~5）
    UIView *v4Top = [self newLine];
    [self addSubview:v4Top];
    [v4Top mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(lineW);
        make.left.equalTo(self).offset(wh * 4);
        make.top.equalTo(self).offset(wh);
        make.height.mas_equalTo(wh);
    }];
    UIView *v4Bottom = [self newLine];
    [self addSubview:v4Bottom];
    [v4Bottom mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(lineW);
        make.left.equalTo(self).offset(wh * 4);
        make.top.equalTo(self).offset(wh * 3);
        make.bottom.equalTo(self);
    }];

    // x=5h（从 y=1h 往下，补齐第二排第4个胶囊右边界竖线）
    UIView *v5 = [self newLine];
    [self addSubview:v5];
    [v5 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(lineW);
        make.left.equalTo(self).offset(wh * 5);
        make.top.equalTo(self).offset(wh);
        make.bottom.equalTo(self);
    }];

    // x=6h（从 y=1h 往下）
    UIView *v6 = [self newLine];
    [self addSubview:v6];
    [v6 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(lineW);
        make.left.equalTo(self).offset(wh * 6);
        make.top.equalTo(self).offset(wh);
        make.bottom.equalTo(self);
    }];

    // x=7h（从 y=1h 往下）
    UIView *v7 = [self newLine];
    [self addSubview:v7];
    [v7 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(lineW);
        make.left.equalTo(self).offset(wh * 7);
        make.top.equalTo(self).offset(wh);
        make.bottom.equalTo(self);
    }];
}


@end

