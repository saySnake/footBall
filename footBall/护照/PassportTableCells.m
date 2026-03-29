//
//  PassportTableCells.m
//  footBall
//

#import "PassportTableCells.h"
#import "PassportViewModel.h"
#import "PassportChartViews.h"
#import <Masonry/Masonry.h>

static UIColor *PCDarkCard(void) { return [UIColor colorWithRed:0.11 green:0.11 blue:0.12 alpha:1.0]; }
static UIColor *PCLightCard(void) { return [UIColor colorWithRed:0.96 green:0.96 blue:0.97 alpha:1.0]; }
static UIColor *PCGreen(void) { return [UIColor colorWithRed:0.157 green:0.365 blue:0.294 alpha:1.0]; }
static UIColor *PCHex(NSString *hex) {
    unsigned r = 0, g = 0, b = 0;
    NSScanner *sc = [NSScanner scannerWithString:hex];
    unsigned val = 0;
    if ([sc scanHexInt:&val] && hex.length >= 6) {
        r = (val >> 16) & 0xFF; g = (val >> 8) & 0xFF; b = val & 0xFF;
    }
    return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0];
}

#pragma mark - Dark stats

@implementation PassportDarkStatsCardCell {
    UIView *_card;
    UILabel *_title;
    UIStackView *_stack;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        _card = [[UIView alloc] init];
        _card.backgroundColor = PCDarkCard();
        _card.layer.cornerRadius = 16;
        [self.contentView addSubview:_card];
        _title = [[UILabel alloc] init];
        _title.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
        _title.textColor = [UIColor whiteColor];
        [_card addSubview:_title];
        _stack = [[UIStackView alloc] init];
        _stack.axis = UILayoutConstraintAxisVertical;
        _stack.spacing = 14;
        [_card addSubview:_stack];
        [_card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(6, 16, 6, 16));
        }];
        [_title mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.leading.equalTo(_card).offset(16);
            make.trailing.equalTo(_card).offset(-16);
        }];
        [_stack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_title.mas_bottom).offset(14);
            make.leading.trailing.equalTo(_card).insets(UIEdgeInsetsMake(0, 16, 0, 16));
            make.bottom.equalTo(_card).offset(-16);
        }];
    }
    return self;
}

- (void)addRowTitle:(NSString *)t value:(NSString *)v {
    UILabel *lt = [[UILabel alloc] init];
    lt.text = t;
    lt.font = [UIFont systemFontOfSize:13];
    lt.textColor = [UIColor colorWithWhite:0.65 alpha:1.0];
    UILabel *lv = [[UILabel alloc] init];
    lv.text = v;
    lv.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    lv.textColor = [UIColor whiteColor];
    lv.textAlignment = NSTextAlignmentRight;
    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[ lt, lv ]];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.distribution = UIStackViewDistributionFill;
    [lv setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [_stack addArrangedSubview:row];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    for (UIView *v in _stack.arrangedSubviews) {
        [_stack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
}

- (void)configureWithModel:(PassportViewModel *)model {
    [self prepareForReuse];
    _title.text = model.regularSeasonTitle;
    [self addRowTitle:model.avgDurationTitle value:model.avgDurationValue];
    [self addRowTitle:model.matchesYearTitle value:model.matchesYearValue];
    [self addRowTitle:model.avgGoalsMatchTitle value:model.avgGoalsMatchValue];
    [self addRowTitle:model.totalGoalsTitle value:model.totalGoalsValue];
}

@end

#pragma mark - Growth

@implementation PassportGrowthBannerCell {
    UIView *_card;
    UILabel *_head;
    UILabel *_sub;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        _card = [[UIView alloc] init];
        _card.backgroundColor = PCGreen();
        _card.layer.cornerRadius = 16;
        [self.contentView addSubview:_card];
        _head = [[UILabel alloc] init];
        _head.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
        _head.textColor = [UIColor whiteColor];
        _sub = [[UILabel alloc] init];
        _sub.font = [UIFont systemFontOfSize:12];
        _sub.textColor = [UIColor colorWithWhite:1 alpha:0.85];
        [_card addSubview:_head];
        [_card addSubview:_sub];
        [_card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(6, 16, 6, 16));
        }];
        [_head mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.leading.equalTo(_card).offset(16);
            make.trailing.equalTo(_card).offset(-16);
        }];
        [_sub mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_head.mas_bottom).offset(6);
            make.leading.trailing.equalTo(_head);
            make.bottom.equalTo(_card).offset(-16);
        }];
    }
    return self;
}

- (void)configureWithModel:(PassportViewModel *)model {
    _head.text = model.growthHeadline;
    _sub.text = model.growthSubtitle;
}

@end

#pragma mark - Bar chart card

@implementation PassportBarChartCardCell {
    UIView *_card;
    UILabel *_title;
    PassportBarChartView *_chart;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        _card = [[UIView alloc] init];
        _card.backgroundColor = PCLightCard();
        _card.layer.cornerRadius = 16;
        [self.contentView addSubview:_card];
        _title = [[UILabel alloc] init];
        _title.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        _title.textColor = [UIColor colorWithWhite:0.12 alpha:1.0];
        _chart = [[PassportBarChartView alloc] init];
        _chart.barColor = PCGreen();
        [_card addSubview:_title];
        [_card addSubview:_chart];
        [_card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(6, 16, 6, 16));
        }];
        [_title mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.leading.equalTo(_card).offset(16);
            make.trailing.equalTo(_card).offset(-16);
        }];
        [_chart mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_title.mas_bottom).offset(12);
            make.leading.trailing.equalTo(_card).insets(UIEdgeInsetsMake(16, 16, 16, 16));
            make.height.mas_equalTo(140);
            make.bottom.equalTo(_card).offset(-16);
        }];
    }
    return self;
}

- (void)configureWithModel:(PassportViewModel *)model {
    _title.text = model.goalTrendTitle;
    _chart.maxValue = 10;
    _chart.values = model.goalTrendValues;
}

@end

#pragma mark - Possession

@implementation PassportPossessionCardCell {
    UIView *_card;
    UILabel *_title;
    UILabel *_l1;
    UILabel *_l2;
    PassportDonutChartView *_donut;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        _card = [[UIView alloc] init];
        _card.backgroundColor = PCLightCard();
        _card.layer.cornerRadius = 16;
        [self.contentView addSubview:_card];
        _title = [[UILabel alloc] init];
        _title.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
        _title.textColor = [UIColor colorWithWhite:0.12 alpha:1.0];
        _title.numberOfLines = 2;
        _l1 = [[UILabel alloc] init];
        _l1.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
        _l1.textColor = [UIColor colorWithWhite:0.12 alpha:1.0];
        _l2 = [[UILabel alloc] init];
        _l2.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
        _l2.textColor = [UIColor colorWithWhite:0.12 alpha:1.0];
        _donut = [[PassportDonutChartView alloc] init];
        _donut.lineWidth = 14;
        [_card addSubview:_title];
        [_card addSubview:_l1];
        [_card addSubview:_l2];
        [_card addSubview:_donut];
        [_card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(6, 16, 6, 16));
        }];
        [_title mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.leading.equalTo(_card).offset(16);
            make.trailing.equalTo(_card.mas_centerX);
        }];
        [_l1 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_card).offset(16);
            make.top.equalTo(_title.mas_bottom).offset(16);
        }];
        [_l2 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_l1);
            make.top.equalTo(_l1.mas_bottom).offset(8);
            make.bottom.lessThanOrEqualTo(_card).offset(-16);
        }];
        [_donut mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(_card).offset(-16);
            make.centerY.equalTo(_card);
            make.width.height.mas_equalTo(120);
        }];
    }
    return self;
}

- (void)configureWithModel:(PassportViewModel *)model {
    _title.text = model.possessionCardTitle;
    _l1.text = model.possessionLeftLine1;
    _l2.text = model.possessionLeftLine2;
    CGFloat p = model.possessionCenterPercent;
    p = MIN(1, MAX(0, p));
    _donut.segmentRatios = @[ @(p), @(1 - p) ];
    _donut.segmentColors = @[ [UIColor colorWithRed:0.2 green:0.62 blue:0.55 alpha:1.0], [UIColor colorWithWhite:0.88 alpha:1.0] ];
    _donut.centerText = [NSString stringWithFormat:@"%.0f%%", p * 100];
}

@end

#pragma mark - Position strength

@implementation PassportPositionStrengthCell {
    UIView *_card;
    UILabel *_title;
    UIStackView *_stack;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        _card = [[UIView alloc] init];
        _card.backgroundColor = PCDarkCard();
        _card.layer.cornerRadius = 16;
        [self.contentView addSubview:_card];
        _title = [[UILabel alloc] init];
        _title.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
        _title.textColor = [UIColor whiteColor];
        _stack = [[UIStackView alloc] init];
        _stack.axis = UILayoutConstraintAxisVertical;
        _stack.spacing = 10;
        [_card addSubview:_title];
        [_card addSubview:_stack];
        [_card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(6, 16, 6, 16));
        }];
        [_title mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.leading.equalTo(_card).offset(16);
            make.trailing.equalTo(_card).offset(-16);
        }];
        [_stack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_title.mas_bottom).offset(12);
            make.leading.trailing.equalTo(_card).insets(UIEdgeInsetsMake(0, 16, 0, 16));
            make.bottom.equalTo(_card).offset(-16);
        }];
    }
    return self;
}

- (UIView *)capsule:(NSString *)text value:(NSInteger)v color:(UIColor *)bg {
    UIView *w = [[UIView alloc] init];
    w.backgroundColor = bg;
    w.layer.cornerRadius = 10;
    UILabel *lt = [[UILabel alloc] init];
    lt.text = text;
    lt.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    lt.textColor = [UIColor whiteColor];
    UILabel *lv = [[UILabel alloc] init];
    lv.text = [NSString stringWithFormat:@"%ld", (long)v];
    lv.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    lv.textColor = [UIColor whiteColor];
    lv.textAlignment = NSTextAlignmentRight;
    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[ lt, lv ]];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.layoutMarginsRelativeArrangement = YES;
    row.layoutMargins = UIEdgeInsetsMake(10, 14, 10, 14);
    row.distribution = UIStackViewDistributionEqualSpacing;
    [w addSubview:row];
    [row mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(w);
        make.height.mas_greaterThanOrEqualTo(44);
    }];
    return w;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    for (UIView *v in _stack.arrangedSubviews) {
        [_stack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
}

- (void)configureWithModel:(PassportViewModel *)model {
    [self prepareForReuse];
    _title.text = model.positionSectionTitle;
    UIColor *c1 = [UIColor colorWithRed:0.12 green:0.35 blue:0.28 alpha:1.0];
    UIColor *c2 = [UIColor colorWithRed:0.18 green:0.45 blue:0.36 alpha:1.0];
    UIColor *c3 = [UIColor colorWithRed:0.28 green:0.58 blue:0.48 alpha:1.0];
    [_stack addArrangedSubview:[self capsule:model.positionForwardLabel value:model.positionForward color:c1]];
    [_stack addArrangedSubview:[self capsule:model.positionMidfieldLabel value:model.positionMidfield color:c2]];
    [_stack addArrangedSubview:[self capsule:model.positionDefenderLabel value:model.positionDefender color:c3]];
}

@end

#pragma mark - Ability

@implementation PassportAbilityBlockCell {
    UIView *_card;
    UILabel *_title;
    UIStackView *_stack;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        _card = [[UIView alloc] init];
        _card.backgroundColor = PCDarkCard();
        _card.layer.cornerRadius = 16;
        [self.contentView addSubview:_card];
        _title = [[UILabel alloc] init];
        _title.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
        _title.textColor = [UIColor whiteColor];
        _stack = [[UIStackView alloc] init];
        _stack.axis = UILayoutConstraintAxisVertical;
        _stack.spacing = 10;
        [_card addSubview:_title];
        [_card addSubview:_stack];
        [_card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(6, 16, 6, 16));
        }];
        [_title mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.leading.equalTo(_card).offset(16);
            make.trailing.equalTo(_card).offset(-16);
        }];
        [_stack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_title.mas_bottom).offset(12);
            make.leading.trailing.equalTo(_card).insets(UIEdgeInsetsMake(0, 16, 0, 16));
            make.bottom.equalTo(_card).offset(-16);
        }];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    for (UIView *v in _stack.arrangedSubviews) {
        [_stack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
}

- (UIView *)abilityRow:(NSString *)name ratio:(CGFloat)r {
    UILabel *lt = [[UILabel alloc] init];
    lt.text = name;
    lt.font = [UIFont systemFontOfSize:12];
    lt.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    UIView *track = [[UIView alloc] init];
    track.backgroundColor = [UIColor colorWithWhite:0.22 alpha:1.0];
    track.layer.cornerRadius = 3;
    UIView *fill = [[UIView alloc] init];
    fill.backgroundColor = PCGreen();
    fill.layer.cornerRadius = 3;
    [track addSubview:fill];
    UILabel *lv = [[UILabel alloc] init];
    lv.text = [NSString stringWithFormat:@"%.0f", r * 100];
    lv.font = [UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightSemibold];
    lv.textColor = [UIColor whiteColor];
    lv.textAlignment = NSTextAlignmentRight;
    UIStackView *top = [[UIStackView alloc] initWithArrangedSubviews:@[ lt, lv ]];
    top.axis = UILayoutConstraintAxisHorizontal;
    [lv setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    UIStackView *col = [[UIStackView alloc] initWithArrangedSubviews:@[ top, track ]];
    col.axis = UILayoutConstraintAxisVertical;
    col.spacing = 6;
    [track mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(6);
    }];
    [fill mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.bottom.equalTo(track);
        make.width.equalTo(track).multipliedBy(MIN(1, MAX(0, r)));
    }];
    return col;
}

- (void)configureWithModel:(PassportViewModel *)model {
    [self prepareForReuse];
    _title.text = model.abilitySectionTitle;
    for (NSDictionary *item in model.abilityItems) {
        NSString *t = item[@"title"];
        CGFloat v = [item[@"value"] doubleValue];
        [_stack addArrangedSubview:[self abilityRow:t ratio:v]];
    }
}

@end

#pragma mark - Tactical

@implementation PassportTacticalCell {
    UIView *_card;
    UILabel *_title;
    PassportDonutChartView *_donut;
    UIStackView *_legend;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        _card = [[UIView alloc] init];
        _card.backgroundColor = PCLightCard();
        _card.layer.cornerRadius = 16;
        [self.contentView addSubview:_card];
        _title = [[UILabel alloc] init];
        _title.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        _title.textColor = [UIColor colorWithWhite:0.12 alpha:1.0];
        _donut = [[PassportDonutChartView alloc] init];
        _donut.lineWidth = 20;
        _legend = [[UIStackView alloc] init];
        _legend.axis = UILayoutConstraintAxisVertical;
        _legend.spacing = 6;
        [_card addSubview:_title];
        [_card addSubview:_donut];
        [_card addSubview:_legend];
        [_card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(6, 16, 6, 16));
        }];
        [_title mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.leading.equalTo(_card).offset(16);
            make.trailing.equalTo(_card).offset(-16);
        }];
        [_donut mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_title.mas_bottom).offset(12);
            make.centerX.equalTo(_card);
            make.width.height.mas_equalTo(160);
        }];
        [_legend mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_donut.mas_bottom).offset(12);
            make.leading.trailing.equalTo(_card).insets(UIEdgeInsetsMake(0, 16, 0, 16));
            make.bottom.equalTo(_card).offset(-16);
        }];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    for (UIView *v in _legend.arrangedSubviews) {
        [_legend removeArrangedSubview:v];
        [v removeFromSuperview];
    }
}

- (void)configureWithModel:(PassportViewModel *)model {
    [self prepareForReuse];
    _title.text = model.tacticalTitle;
    NSMutableArray *ratios = [NSMutableArray array];
    NSMutableArray *colors = [NSMutableArray array];
    NSArray *cols = @[
        [UIColor colorWithRed:0.1 green:0.42 blue:0.40 alpha:1.0],
        [UIColor colorWithRed:0.2 green:0.55 blue:0.42 alpha:1.0],
        [UIColor colorWithRed:0.45 green:0.78 blue:0.62 alpha:1.0],
    ];
    NSUInteger i = 0;
    for (NSDictionary *seg in model.tacticalSegments) {
        [ratios addObject:seg[@"p"]];
        [colors addObject:cols[MIN(i, cols.count - 1)]];
        i++;
    }
    _donut.segmentRatios = ratios;
    _donut.segmentColors = colors;
    _donut.centerText = nil;
    for (NSDictionary *seg in model.tacticalSegments) {
        UILabel *l = [[UILabel alloc] init];
        CGFloat p = [seg[@"p"] doubleValue] * 100;
        l.text = [NSString stringWithFormat:@"%.0f%% · %@", p, seg[@"title"]];
        l.font = [UIFont systemFontOfSize:12];
        l.textColor = [UIColor colorWithWhite:0.25 alpha:1.0];
        [_legend addArrangedSubview:l];
    }
}

@end

#pragma mark - Metric bars

@implementation PassportMetricBarsCell {
    UIView *_card;
    UILabel *_title;
    UILabel *_sub;
    UIStackView *_stack;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        _card = [[UIView alloc] init];
        _card.backgroundColor = PCLightCard();
        _card.layer.cornerRadius = 16;
        [self.contentView addSubview:_card];
        _title = [[UILabel alloc] init];
        _title.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
        _title.textColor = [UIColor colorWithWhite:0.12 alpha:1.0];
        _sub = [[UILabel alloc] init];
        _sub.font = [UIFont systemFontOfSize:11];
        _sub.textColor = [UIColor colorWithWhite:0.45 alpha:1.0];
        _stack = [[UIStackView alloc] init];
        _stack.axis = UILayoutConstraintAxisVertical;
        _stack.spacing = 12;
        [_card addSubview:_title];
        [_card addSubview:_sub];
        [_card addSubview:_stack];
        [_card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(6, 16, 6, 16));
        }];
        [_title mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.leading.equalTo(_card).offset(16);
            make.trailing.equalTo(_card).offset(-16);
        }];
        [_sub mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_title.mas_bottom).offset(4);
            make.leading.trailing.equalTo(_title);
        }];
        [_stack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_sub.mas_bottom).offset(12);
            make.leading.trailing.equalTo(_card).insets(UIEdgeInsetsMake(0, 16, 0, 16));
            make.bottom.equalTo(_card).offset(-16);
        }];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    for (UIView *v in _stack.arrangedSubviews) {
        [_stack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
}

- (void)configureWithModel:(PassportViewModel *)model {
    [self prepareForReuse];
    _title.text = model.recentGoalsTitle;
    _sub.text = model.recentGoalsSubtitle;
    for (NSDictionary *item in model.recentMetricBars) {
        [_stack addArrangedSubview:[self row:item[@"title"] ratio:[item[@"v"] doubleValue]]];
    }
}

- (UIView *)row:(NSString *)t ratio:(CGFloat)r {
    UILabel *lt = [[UILabel alloc] init];
    lt.text = t;
    lt.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    lt.textColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    UIView *track = [[UIView alloc] init];
    track.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    track.layer.cornerRadius = 3;
    UIView *fill = [[UIView alloc] init];
    fill.backgroundColor = PCGreen();
    fill.layer.cornerRadius = 3;
    [track addSubview:fill];
    [fill mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.bottom.equalTo(track);
        make.width.equalTo(track).multipliedBy(MIN(1, MAX(0, r)));
    }];
    [track mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(8);
    }];
    UIStackView *col = [[UIStackView alloc] initWithArrangedSubviews:@[ lt, track ]];
    col.axis = UILayoutConstraintAxisVertical;
    col.spacing = 6;
    return col;
}

@end

#pragma mark - Outcome

@implementation PassportOutcomeCell {
    UIView *_card;
    UILabel *_title;
    PassportDonutChartView *_donut;
    UIStackView *_legend;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        _card = [[UIView alloc] init];
        _card.backgroundColor = PCLightCard();
        _card.layer.cornerRadius = 16;
        [self.contentView addSubview:_card];
        _title = [[UILabel alloc] init];
        _title.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        _title.textColor = [UIColor colorWithWhite:0.12 alpha:1.0];
        _donut = [[PassportDonutChartView alloc] init];
        _donut.lineWidth = 18;
        _legend = [[UIStackView alloc] init];
        _legend.axis = UILayoutConstraintAxisVertical;
        _legend.spacing = 4;
        [_card addSubview:_title];
        [_card addSubview:_donut];
        [_card addSubview:_legend];
        [_card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(6, 16, 6, 16));
        }];
        [_title mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.leading.equalTo(_card).offset(16);
            make.trailing.equalTo(_card).offset(-16);
        }];
        [_donut mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_title.mas_bottom).offset(12);
            make.centerX.equalTo(_card);
            make.width.height.mas_equalTo(140);
        }];
        [_legend mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_donut.mas_bottom).offset(12);
            make.leading.trailing.equalTo(_card).insets(UIEdgeInsetsMake(0, 16, 0, 16));
            make.bottom.equalTo(_card).offset(-16);
        }];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    for (UIView *v in _legend.arrangedSubviews) {
        [_legend removeArrangedSubview:v];
        [v removeFromSuperview];
    }
}

- (void)configureWithModel:(PassportViewModel *)model {
    [self prepareForReuse];
    _title.text = model.outcomeTitle;
    CGFloat p = MIN(1, MAX(0, model.outcomeCenterPercent));
    _donut.segmentRatios = @[ @(p), @(1 - p) ];
    _donut.segmentColors = @[ PCGreen(), [UIColor colorWithWhite:0.88 alpha:1.0] ];
    _donut.centerText = [NSString stringWithFormat:@"%.0f%%", p * 100];
    for (NSDictionary *leg in model.outcomeLegend) {
        UILabel *l = [[UILabel alloc] init];
        l.text = [NSString stringWithFormat:@"%@  %@", leg[@"t"], leg[@"n"]];
        l.font = [UIFont systemFontOfSize:12];
        l.textColor = PCHex([NSString stringWithFormat:@"%@", leg[@"h"] ?: @""]);
        [_legend addArrangedSubview:l];
    }
}

@end
