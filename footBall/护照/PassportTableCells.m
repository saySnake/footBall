//
//  PassportTableCells.m
//  footBall
//

#import "PassportTableCells.h"
#import "PassportViewModel.h"
#import "PassportChartViews.h"
#import "FontManager.h"
#import <Masonry/Masonry.h>
#import <QuartzCore/QuartzCore.h>

static UIColor *PCDarkCard(void) { return [UIColor colorWithHexString:@"#0D2122"]; }
static UIColor *PCLightCard(void) { return [UIColor colorWithHexString:@"#FEFEFE"]; }
static UIColor *PCGreen(void) { return [UIColor colorWithHexString:@"#285D4B"]; }
static UIColor *PCHex(NSString *hex) {
    unsigned r = 0, g = 0, b = 0;
    NSScanner *sc = [NSScanner scannerWithString:hex];
    unsigned val = 0;
    if ([sc scanHexInt:&val] && hex.length >= 6) {
        r = (val >> 16) & 0xFF; g = (val >> 8) & 0xFF; b = val & 0xFF;
    }
    return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0];
}

static const CGFloat kPassportAbilityValueColumnWidth = 24;
static const CGFloat kPassportAbilityBarHeight = 12;
static const CGFloat kPassportAbilityRowHeight = 25;
static const CGFloat kPassportEmotionIconSize = 24;
static const CGFloat kPassportEmotionIconTextGap = 6;
/// 与输入信息页座位选项数量一致
static const NSInteger kPassportAbilitySeatRowCount = 10;

/// 能力块左侧列宽：取当前数据里所有行标题在指定字体下排版宽度的最大值（与左侧 UILabel 一致）
static CGFloat PCAbilityMaxLabelWidthForTitles(NSArray<NSString *> *titles, UIFont *font) {
    CGFloat maxW = 0;
    for (NSString *t in titles) {
        if (![t isKindOfClass:[NSString class]] || !t.length) continue;
        CGRect r = [t boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, 40)
                                     options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                  attributes:@{ NSFontAttributeName: font }
                                     context:nil];
        maxW = MAX(maxW, ceil(CGRectGetWidth(r)));
    }
    return maxW;
}

#pragma mark - Dark stats

@implementation PassportDarkStatsCardCell {
    UIView *_headerCard;
    UILabel *_title;
    NSArray<UIView *> *_rows;
    NSArray<UILabel *> *_rowLeftLabels;
    NSArray<UILabel *> *_rowValueLabels;
    NSArray<UILabel *> *_rowUnitLabels;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.separatorInset = UIEdgeInsetsZero;
        self.layoutMargins = UIEdgeInsetsZero;
        self.preservesSuperviewLayoutMargins = NO;
        self.contentView.layoutMargins = UIEdgeInsetsZero;
        self.contentView.preservesSuperviewLayoutMargins = NO;
        _headerCard = [[UIView alloc] init];
        _headerCard.backgroundColor = [UIColor colorWithHexString:@"#18181C"];
        _headerCard.layer.cornerRadius = 24;
        _headerCard.clipsToBounds = YES;
        [self.contentView addSubview:_headerCard];
        _title = [[UILabel alloc] init];
        _title.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
        _title.textColor = [UIColor whiteColor];
        [_headerCard addSubview:_title];

        NSMutableArray<UIView *> *rows = [NSMutableArray array];
        NSMutableArray<UILabel *> *ls = [NSMutableArray array];
        NSMutableArray<UILabel *> *vs = [NSMutableArray array];
        NSMutableArray<UILabel *> *us = [NSMutableArray array];

        // 纯色（不透明），按设计稿从上到下逐渐变亮一点
        NSArray<UIColor *> *rowColors = @[
            PCHex(@"27272D"),
            PCHex(@"34343B"),
            PCHex(@"43434B"),
            PCHex(@"53535A"),
        ];
        for (NSInteger i = 0; i < rowColors.count; i++) {
            UIView *rowCard = [[UIView alloc] init];
            rowCard.backgroundColor = rowColors[i];
            rowCard.layer.cornerRadius = 24;
            rowCard.clipsToBounds = YES;
            [self.contentView addSubview:rowCard];

            UILabel *left = [[UILabel alloc] init];
            left.font = [UIFont systemFontOfSize:14];
            left.textColor = [UIColor whiteColor];
            left.numberOfLines = 1;
            [rowCard addSubview:left];

            UILabel *val = [[UILabel alloc] init];
            val.font = FontManager.sharedManager.font40Regular;
            val.textColor = [UIColor whiteColor];
            val.textAlignment = NSTextAlignmentRight;
            [rowCard addSubview:val];

            UILabel *unit = [[UILabel alloc] init];
            unit.font = [UIFont systemFontOfSize:16];
            unit.textColor = [UIColor whiteColor];
            unit.textAlignment = NSTextAlignmentLeft;
            [rowCard addSubview:unit];

            [left mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(rowCard).offset(18);
                if (rowColors.count - 1 == i) {
                    make.centerY.equalTo(rowCard);
                } else {
                    make.centerY.equalTo(rowCard).offset(-28);
                }
                make.right.lessThanOrEqualTo(val.mas_left).offset(-12);
            }];
            [unit mas_makeConstraints:^(MASConstraintMaker *make) {
                make.right.equalTo(rowCard).offset(-18);
                make.centerY.equalTo(val).offset(6);
            }];
            [val mas_makeConstraints:^(MASConstraintMaker *make) {
                make.right.equalTo(unit.mas_left).offset(-10);
                if (rowColors.count - 1 == i) {
                    make.centerY.equalTo(rowCard);
                } else {
                    make.centerY.equalTo(rowCard).offset(-28);
                }
            }];

            [rows addObject:rowCard];
            [ls addObject:left];
            [vs addObject:val];
            [us addObject:unit];
        }
        _rows = [rows copy];
        _rowLeftLabels = [ls copy];
        _rowValueLabels = [vs copy];
        _rowUnitLabels = [us copy];

        CGFloat cardH = 138.0;
        CGFloat overlap = 58.0;

        [_headerCard mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.contentView);
            make.top.equalTo(self.contentView).offset(6);
            make.height.mas_equalTo(cardH+6);
        }];
        [_title mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@30);
            make.leading.equalTo(_headerCard).offset(16);
            make.trailing.equalTo(_headerCard).offset(-16);
        }];

        UIView *prev = _headerCard;
        for (NSInteger i = 0; i < _rows.count; i++) {
            UIView *row = _rows[i];
            [row mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.right.equalTo(self.contentView);
                if (i == _rows.count-1) {
                    make.height.mas_equalTo(89);
                } else {
                    make.height.mas_equalTo(cardH);
                }
                // 从第二个开始向上叠压 21（等价于 top = prev.bottom - 21）
                make.top.equalTo(prev.mas_bottom).offset(-overlap);
                if (i == _rows.count - 1) {
                    make.bottom.equalTo(self.contentView);
                }
            }];
            prev = row;
        }
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    _title.text = nil;
}

- (void)setRowAtIndex:(NSInteger)idx left:(NSString *)leftText right:(NSString *)rightText {
    if (idx < 0 || idx >= _rowLeftLabels.count) return;
    _rowLeftLabels[idx].text = leftText ?: @"";

    NSString *trim = [rightText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trim.length == 0) {
        _rowValueLabels[idx].text = @"";
        _rowUnitLabels[idx].text = @"";
        return;
    }

    // 简单拆分：末尾汉字/字母当单位，其余当数值（适配 “8088 分钟”“3 天”“34:1”等）
    NSCharacterSet *digits = [NSCharacterSet characterSetWithCharactersInString:@"0123456789:.,/"];
    NSInteger split = trim.length;
    for (NSInteger i = trim.length - 1; i >= 0; i--) {
        unichar ch = [trim characterAtIndex:i];
        if ([digits characterIsMember:ch] || ch == ' ') {
            split = i + 1;
            break;
        }
    }
    NSString *val = [[trim substringToIndex:split] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *unit = [[trim substringFromIndex:split] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    _rowValueLabels[idx].text = val;
    _rowUnitLabels[idx].text = unit;
}

- (void)configureWithModel:(PassportViewModel *)model {
    _title.text = model.regularSeasonTitle;
    //个人2026年份 总看球时间，有年份因素限制 选中赛季认证几场的总时间 TIME 2026 SUM
    // TODO: 当前 model.avgDurationTitle/avgDurationValue 仍是占位（PassportViewModel 内写死），需按后端实际字段映射为「所选赛季总观赛时长」或「平均时长」之一。
    [self setRowAtIndex:0 left:model.avgDurationTitle right:model.avgDurationValue];
    //个人2026年份 总看球时间，有年份因素限制 选中赛季认证几场的总时间 TIME 2026 SUM time/24小时 转换成天保留三位小数. 2.312天
    // TODO: 当前用的是 matchesYearTitle/matchesYearValue（场次），与注释“时长转天”不一致；待后端字段明确后再替换。
    [self setRowAtIndex:1 left:model.matchesYearTitle right:model.matchesYearValue];
    //个人2026年份 总看球时间 工作日和周末的比例 周末和工作日看球时间需要分开记录～ 然后求比值 保留最小公约数
    // TODO: 当前用 avgGoalsMatchTitle/avgGoalsMatchValue（进球相关占位），与注释“周末/工作日比”不一致；待接口补字段或 ViewModel 补计算。
    [self setRowAtIndex:2 left:model.avgGoalsMatchTitle right:model.avgGoalsMatchValue];
    //个人2026年份 总看球时间 白天和晚上的比例 白天和晚上看球时间需要分开记录～ 然后求比值 保留最小公约数。早5点-晚5点开始的比赛 是白天看球晚5点-早5点 是晚上看球
    // TODO: 当前用 totalGoalsTitle/totalGoalsValue（进球相关占位），与注释“白天/夜晚比”不一致；待接口补字段或 ViewModel 补计算。
    [self setRowAtIndex:3 left:model.totalGoalsTitle right:model.totalGoalsValue];
}

@end

#pragma mark - Growth

@implementation PassportGrowthBannerCell {
    UIView *_card;
    UILabel *_topLine;
    UILabel *_percent;
    UILabel *_suffix;
    UILabel *_bottomLine;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        _card = [[UIView alloc] init];
        _card.backgroundColor = [UIColor colorWithHexString:@"#285D4B"];
        _card.layer.cornerRadius = 24;
        _card.clipsToBounds = YES;
        [self.contentView addSubview:_card];

        _topLine = [[UILabel alloc] init];
        _topLine.font = FontManager.sharedManager.font16Regular;
        _topLine.textColor = [UIColor whiteColor];
        _topLine.numberOfLines = 2;
        [_card addSubview:_topLine];

        _percent = [[UILabel alloc] init];
        _percent.font = FontManager.sharedManager.font75Regular;
        _percent.textColor = [UIColor whiteColor];
        _percent.text = @"--";
        [_card addSubview:_percent];

        _suffix = [[UILabel alloc] init];
        _suffix.font = [UIFont systemFontOfSize:30 weight:UIFontWeightSemibold];
        _suffix.textColor = [UIColor whiteColor];
        _suffix.text = NSLocalizedString(@"passport_growth_ok", nil);
        [_card addSubview:_suffix];

        _bottomLine = [[UILabel alloc] init];
        _bottomLine.font = FontManager.sharedManager.font11Regular;
        _bottomLine.textColor = [UIColor whiteColor];
        _bottomLine.text = @"";
        [_card addSubview:_bottomLine];

        [_card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 0, 0, 0));
        }];
        [_topLine mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_card).offset(40);
            make.left.equalTo(_card).offset(16);
            make.right.equalTo(_card).offset(-16);
        }];
        [_percent mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_topLine);
            make.top.equalTo(_topLine.mas_bottom).offset(10);
        }];
        [_suffix mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_percent.mas_right).offset(14);
            // baseline 约束在部分字体/系统版本上可能触发异常，改为更稳定的 centerY 对齐
            make.bottom.equalTo(_percent).offset(-16);
            make.right.lessThanOrEqualTo(_card).offset(-16);
        }];
        [_bottomLine mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_topLine);
            make.bottom.equalTo(_card).offset(-16);
            make.right.lessThanOrEqualTo(_card).offset(-16);
        }];
    }
    return self;
}

- (void)configureWithModel:(PassportViewModel *)model {
    _topLine.text = model.growthHeadline.length ? model.growthHeadline : @"";
    //个人2026年份 总看球总天数 除以 天（365-121睡眠天数）算出%
    // TODO: growthSubtitle 目前被复用为 percent 或底部文案，占位逻辑较随意；等后端提供“睡醒时间占比%”与“说明文案”后拆成两个字段更清晰。
    NSString *t = [model.growthSubtitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([t hasSuffix:@"%"] && t.length <= 6) {
        _percent.text = t;
    } else if (t.length > 0) {
        _bottomLine.text = t;
    }
}

@end

#pragma mark - Bar chart card

@implementation PassportBarChartCardCell {
    UIView *_card;
    UILabel *_title;
    PassportBarChartView *_chart;
    UIView *_bottomDashView;
    CAShapeLayer *_bottomDashLayer;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        _card = [[UIView alloc] init];
        _card.backgroundColor = PCLightCard();
        _card.layer.cornerRadius = 24;
        [self.contentView addSubview:_card];
        _title = [[UILabel alloc] init];
        _title.font = FontManager.sharedManager.font18Regular;
        _title.textColor = [UIColor colorWithWhite:0.12 alpha:1.0];
        _chart = [[PassportBarChartView alloc] init];
        _chart.barColor = PCGreen();
        _chart.barWidth = 20;
        [_card addSubview:_title];
        [_card addSubview:_chart];
        [_card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.leading.trailing.equalTo(self.contentView);
            make.bottom.equalTo(self.contentView).offset(-2);
        }];
        // 底部虚线
        UIView *bottomDashView = [[UIView alloc] init];
        bottomDashView.backgroundColor = [UIColor clearColor];
        _bottomDashView = bottomDashView;
        [self.contentView addSubview:bottomDashView];
        [bottomDashView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_card.mas_bottom);
            make.leading.trailing.bottom.equalTo(self.contentView);
        }];
        CAShapeLayer *dashLayer = [CAShapeLayer layer];
        dashLayer.strokeColor = [UIColor colorWithWhite:0.75 alpha:1.0].CGColor;
        dashLayer.fillColor = [UIColor clearColor].CGColor;
        dashLayer.lineWidth = 1;
        dashLayer.lineDashPattern = @[@6, @4];
        [bottomDashView.layer addSublayer:dashLayer];
        _bottomDashLayer = dashLayer;
        [_title mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.leading.equalTo(_card).offset(16);
            make.trailing.equalTo(_card).offset(-16);
        }];
        [_chart mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_card).offset(50);
            make.leading.trailing.equalTo(_card).insets(UIEdgeInsetsMake(16, 16, 16, 16));
            make.bottom.equalTo(_card).offset(-16);
        }];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (_bottomDashView && _bottomDashLayer) {
        CGFloat w = CGRectGetWidth(_bottomDashView.bounds);
        if (w > 0) {
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointMake(16, 1)];
            [path addLineToPoint:CGPointMake(w - 16, 1)];
            _bottomDashLayer.path = path.CGPath;
        }
    }
}

- (void)configureWithModel:(PassportViewModel *)model {
    _title.text = model.goalTrendTitle;
    /**
     X轴在表示地点
     Y轴表示去过的频次
     表格Y轴最大值自适应：取数据峰值，不足 10 按 10，再向上取整到 10 的倍数（如 53→60、83→90）
     最高值做高亮
     数据从信息填写得来
     */
    _chart.xTitles = (model.goalTrendXTitles.count > 0) ? model.goalTrendXTitles : _chart.xTitles;
    _chart.maxValue = [PassportBarChartView adaptiveMaxValueForValues:model.goalTrendValues];
    _chart.values = model.goalTrendValues;
}

@end

#pragma mark - Possession

@implementation PassportPossessionCardCell {
    UIView *_card;
    UILabel *_title;
    UILabel *_num1;
    UILabel *_desc1;
    UIView *_sepLine;
    UILabel *_num2;
    UILabel *_desc2;
    PassportDonutChartView *_donut;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        _card = [[UIView alloc] init];
        _card.backgroundColor = PCLightCard();
        _card.layer.cornerRadius = 24;
        [self.contentView addSubview:_card];
        _title = [[UILabel alloc] init];
        _title.font = FontManager.sharedManager.font18Regular;
        _title.textColor = [UIColor colorWithWhite:0.12 alpha:1.0];
        _title.numberOfLines = 2;
        _num1 = [[UILabel alloc] init];
        _num1.font = FontManager.sharedManager.font60Regular;
        _num1.textColor = [UIColor colorWithWhite:0.12 alpha:1.0];
        _desc1 = [[UILabel alloc] init];
        _desc1.font = FontManager.sharedManager.font11Regular;
        _desc1.textColor = [UIColor colorWithWhite:0.12 alpha:1.0];
        _desc1.numberOfLines = 2;
        _sepLine = [[UIView alloc] init];
        _sepLine.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1.0];
        _num2 = [[UILabel alloc] init];
        _num2.font = FontManager.sharedManager.font60Regular;
        _num2.textColor = [UIColor colorWithWhite:0.12 alpha:1.0];
        _desc2 = [[UILabel alloc] init];
        _desc2.font = FontManager.sharedManager.font11Regular;
        _desc2.textColor = [UIColor colorWithWhite:0.12 alpha:1.0];
        _desc2.numberOfLines = 2;
        _donut = [[PassportDonutChartView alloc] init];
        _donut.lineWidth = 24;
        [_card addSubview:_title];
        [_card addSubview:_num1];
        [_card addSubview:_desc1];
        [_card addSubview:_sepLine];
        [_card addSubview:_num2];
        [_card addSubview:_desc2];
        [_card addSubview:_donut];
        [_card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 0, 0, 0));
        }];
        [_title mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_card).offset(26);
            make.left.equalTo(_card).offset(16);
            make.right.equalTo(_card).offset(-16);
        }];
        [_donut mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(_card).offset(-16);
            make.centerY.equalTo(_card).offset(20);
            make.width.height.mas_equalTo(154);
        }];
        [_num1 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_card).offset(16);
            make.top.equalTo(_title.mas_bottom).offset(20);
        }];
        [_desc1 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_num1.mas_right).offset(10);
            make.bottom.equalTo(_num1).offset(-16);
            make.right.lessThanOrEqualTo(_donut.mas_left).offset(-12);
        }];
        [_sepLine mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_card).offset(16);
            make.right.equalTo(_donut.mas_left).offset(-12);
            make.top.equalTo(_num1.mas_bottom).offset(8);
            make.height.mas_equalTo(0.5);
        }];
        [_num2 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_card).offset(16);
            make.top.equalTo(_sepLine.mas_bottom).offset(8);
            make.bottom.lessThanOrEqualTo(_card).offset(-16);
        }];
        [_desc2 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_num2.mas_right).offset(10);
            make.bottom.equalTo(_num2).offset(-16);
            make.right.lessThanOrEqualTo(_donut.mas_left).offset(-12);
        }];
    }
    return self;
}

- (void)configureWithModel:(PassportViewModel *)model {
    /**
     2026单个赛季
     总共认证的场次里 包含主队的比赛里 主队胜利的场次

     胜利与 打平+失败的比值计算胜率x100%
     */
    _title.text = model.possessionCardTitle;
    _num1.text = model.possessionLeftLine1;
    NSString *winsFmt = NSLocalizedString(@"passport_possession_wins_label_format", nil);
    if (!winsFmt.length || [winsFmt isEqualToString:@"passport_possession_wins_label_format"]) {
        winsFmt = @"赢球%@次";
    }
    _desc1.text = [NSString stringWithFormat:winsFmt, model.possessionLeftLine1 ?: @""];
    _num2.text = model.possessionLeftLine2;
    NSString *rateFmt = NSLocalizedString(@"passport_possession_win_rate_label_format", nil);
    if (!rateFmt.length || [rateFmt isEqualToString:@"passport_possession_win_rate_label_format"]) {
        rateFmt = @"胜率为%@%%";
    }
    _desc2.text = [NSString stringWithFormat:rateFmt, model.possessionLeftLine2 ?: @""];
    CGFloat p = model.possessionCenterPercent;
    p = MIN(1, MAX(0, p));
    _donut.lineWidth = 24;
    _donut.showsOutsidePercentLabels = NO;
    _donut.ringInnerRadius = 0;
    _donut.ringTrackColor = nil;
    _donut.ringTrackExtraWidth = 0;
    _donut.segmentGapPoints = 0;
    _donut.segmentRatios = @[ @(p), @(1 - p) ];
    _donut.segmentColors = @[ [UIColor colorWithHexString:@"#5CB793"] , [UIColor colorWithHexString:@"#0D2122"]];
    _donut.centerText = [NSString stringWithFormat:@"%.0f%%", p * 100];
}

@end

#pragma mark - Position strength

@implementation PassportPositionStrengthCell {
    UIView *_card;
    UIView *_headerStrip;
    UILabel *_title;
    UIView *_row1;
    UIView *_row2;
    UIView *_row3;
    UILabel *_l1;
    UILabel *_v1;
    UILabel *_l2;
    UILabel *_v2;
    UILabel *_l3;
    UILabel *_v3;
    UIView *_bottomDashView;
    CAShapeLayer *_bottomDashLayer;
}

/// 叠压卡片圆角：仅顶部 / 仅底部 / 四角（iOS 11+ 用 maskedCorners）
static void PCPositionSetCorners(UIView *v, UIRectCorner corners, CGFloat r) {
    v.layer.cornerRadius = r;
    v.clipsToBounds = YES;
    if (@available(iOS 11.0, *)) {
        CACornerMask mask = 0;
        if (corners & UIRectCornerTopLeft) mask |= kCALayerMinXMinYCorner;
        if (corners & UIRectCornerTopRight) mask |= kCALayerMaxXMinYCorner;
        if (corners & UIRectCornerBottomLeft) mask |= kCALayerMinXMaxYCorner;
        if (corners & UIRectCornerBottomRight) mask |= kCALayerMaxXMaxYCorner;
        v.layer.maskedCorners = mask;
    }
}

static UIView *PCPositionRow(UILabel **outL, UILabel **outV, bool last) {
    UIView *row = [[UIView alloc] init];
    row.clipsToBounds = YES;
    UILabel *l = [[UILabel alloc] init];
    l.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    l.textColor = [UIColor blackColor];
    l.numberOfLines = 2;
    UILabel *v = [[UILabel alloc] init];
    v.font = FontManager.sharedManager.font70Regular;
    v.textAlignment = NSTextAlignmentRight;
    [row addSubview:l];
    [row addSubview:v];
    [l mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(row).offset(16);
        make.centerY.equalTo(row).offset(last?0:-13);
        make.right.lessThanOrEqualTo(v.mas_left).offset(-12);
    }];
    [v mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(row).offset(-16);
        make.centerY.equalTo(row).offset(last?0:-13);
    }];
    *outL = l;
    *outV = v;
    return row;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        _card = [[UIView alloc] init];
        _card.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_card];
        _headerStrip = [[UIView alloc] init];
        _headerStrip.backgroundColor = [UIColor colorWithHexString:@"#0D2122"];
        PCPositionSetCorners(_headerStrip, UIRectCornerTopLeft | UIRectCornerTopRight, 24);
        [_card addSubview:_headerStrip];
        _title = [[UILabel alloc] init];
        _title.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
        _title.textColor = [UIColor whiteColor];
        _title.numberOfLines = 1;
        [_headerStrip addSubview:_title];

        UILabel *l1, *v1, *l2, *v2, *l3, *v3;
        _row1 = PCPositionRow(&l1, &v1,NO);
        _l1 = l1;
        _v1 = v1;
        _row2 = PCPositionRow(&l2, &v2,NO);
        _l2 = l2;
        _v2 = v2;
        _row3 = PCPositionRow(&l3, &v3,YES);
        _l3 = l3;
        _v3 = v3;
        PCPositionSetCorners(_row1, UIRectCornerTopLeft | UIRectCornerTopRight, 24);
        PCPositionSetCorners(_row2, UIRectCornerTopLeft | UIRectCornerTopRight, 24);
        // 最后一行：仅上沿圆角，底边与容器齐平为直角
        PCPositionSetCorners(_row3, UIRectCornerTopLeft | UIRectCornerTopRight, 24);
        [_card addSubview:_row1];
        [_card addSubview:_row2];
        [_card addSubview:_row3];

        [_card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.leading.trailing.equalTo(self.contentView);
            make.bottom.equalTo(self.contentView).offset(-1);
        }];
        // 底部虚线
        UIView *bottomDashView = [[UIView alloc] init];
        bottomDashView.backgroundColor = [UIColor clearColor];
        _bottomDashView = bottomDashView;
        [self.contentView addSubview:bottomDashView];
        [bottomDashView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_card.mas_bottom);
            make.leading.trailing.bottom.equalTo(self.contentView);
        }];
        CAShapeLayer *dashLayer = [CAShapeLayer layer];
        dashLayer.strokeColor = [UIColor colorWithWhite:0.75 alpha:1.0].CGColor;
        dashLayer.fillColor = [UIColor clearColor].CGColor;
        dashLayer.lineWidth = 1;
        dashLayer.lineDashPattern = @[@6, @4];
        [bottomDashView.layer addSublayer:dashLayer];
        _bottomDashLayer = dashLayer;
        [_headerStrip mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.equalTo(_card);
            make.height.mas_equalTo(116);
        }];
        [_title mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_headerStrip).offset(36);
            make.left.equalTo(_headerStrip).offset(16);
            make.right.equalTo(_headerStrip).offset(-16);
        }];
        [_row1 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(_card);
            make.top.equalTo(_headerStrip.mas_bottom).offset(-26);
            make.height.mas_equalTo(132);
        }];
        [_row2 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(_card);
            make.top.equalTo(_row1.mas_bottom).offset(-26);
            make.height.mas_equalTo(132);
        }];
        [_row3 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(_card);
            make.top.equalTo(_row2.mas_bottom).offset(-26);
            make.bottom.equalTo(_card);
        }];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (_bottomDashView && _bottomDashLayer) {
        CGFloat w = CGRectGetWidth(_bottomDashView.bounds);
        if (w > 0) {
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointMake(16, 0)];
            [path addLineToPoint:CGPointMake(w - 16, 0)];
            _bottomDashLayer.path = path.CGPath;
        }
    }
}

- (void)configureWithModel:(PassportViewModel *)model {
    _title.text = model.positionSectionTitle;
    //在2026年（所选时间）下  认证的场次 共覆盖几个球场就是多少球场 例如2026年小明去过 看过100场北京国安主场 但只看过北京国安主场 那么球场还是=1 因为就是北京工人体育场
    _l1.text = model.positionForwardLabel;
    _v1.text = [NSString stringWithFormat:@"%ld", (long)model.positionForward];
    //在2026年（所选时间）下  认证的场次 共覆盖几个城市就是多少城市 例如2026年小明去过 看过100场北京国安主场 但只看过北京国安主场 那么城市还是=1 因为就是北京
    _l2.text = model.positionMidfieldLabel;
    _v2.text = [NSString stringWithFormat:@"%ld", (long)model.positionMidfield];
    //在2026年（所选时间）下 认证的场次 共覆盖几个国家就是多少国家 例如2026年小明去过 看过100场中超 但只看过中超 那么国家还是=1 因为就是中国
    _l3.text = model.positionDefenderLabel;
    _v3.text = [NSString stringWithFormat:@"%ld", (long)model.positionDefender];
    // TODO: positionForward/Midfield/Defender 当前是“位置强度”占位数据（PassportViewModel 写死），与注释“球场/城市/国家去重统计”不一致；待接口字段明确后替换为 yearStadiumCount/yearCityCount/yearCountryCount 等。

    _row1.backgroundColor = PCHex(@"285D4B");
    _v1.textColor = PCHex(@"62D486");
    _row2.backgroundColor = PCHex(@"5CB793");
    _v2.textColor = PCHex(@"215040");
    _row3.backgroundColor = PCHex(@"62D486");
    _v3.textColor = PCHex(@"285D4B");
}

@end

#pragma mark - Ability

@implementation PassportAbilityBlockCell {
    UIView *_card;
    UILabel *_title;
    UILabel *_subtitle;
    UIStackView *_rowStack;
    NSMutableArray<UIView *> *_tracks;
    NSMutableArray<UIView *> *_fills;
    NSMutableArray<UILabel *> *_leftLabels;
    NSMutableArray<UILabel *> *_rightLabels;
}

static NSAttributedString *PCAbilitySummaryAttributed(CGFloat level) {
    FontManager *fm = [FontManager sharedManager];
    NSString *prefix = NSLocalizedString(@"passport_ability_avg_prefix", nil) ?: @"我平均在 ";
    NSString *num = [NSString stringWithFormat:@"%.2f", level];
    NSString *suffix = NSLocalizedString(@"passport_ability_avg_suffix", nil) ?: @" 层比赛观赏";
    UIColor *muted = [UIColor colorWithWhite:0.45 alpha:1.0];
    UIColor *numColor = [UIColor colorWithWhite:0.12 alpha:1.0];
    NSMutableAttributedString *m = [[NSMutableAttributedString alloc] init];
    [m appendAttributedString:[[NSAttributedString alloc] initWithString:prefix attributes:@{
        NSFontAttributeName: fm.font14Regular,
        NSForegroundColorAttributeName: muted,
    }]];
    [m appendAttributedString:[[NSAttributedString alloc] initWithString:num attributes:@{
        NSFontAttributeName: fm.font24Regular,
        NSForegroundColorAttributeName: numColor,
    }]];
    [m appendAttributedString:[[NSAttributedString alloc] initWithString:suffix attributes:@{
        NSFontAttributeName: fm.font14Regular,
        NSForegroundColorAttributeName: muted,
    }]];
    return m;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        _card = [[UIView alloc] init];
        _card.backgroundColor = PCLightCard();
        _card.layer.cornerRadius = 24;
        _card.clipsToBounds = YES;
        [self.contentView addSubview:_card];
        _title = [[UILabel alloc] init];
        _title.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
        _title.textColor = [UIColor colorWithWhite:0.12 alpha:1.0];
        _title.numberOfLines = 1;
        _subtitle = [[UILabel alloc] init];
        _subtitle.numberOfLines = 1;
        _rowStack = [[UIStackView alloc] init];
        _rowStack.axis = UILayoutConstraintAxisVertical;
        _rowStack.spacing = 0;
        _tracks = [NSMutableArray array];
        _fills = [NSMutableArray array];
        _leftLabels = [NSMutableArray array];
        _rightLabels = [NSMutableArray array];
        FontManager *fm = [FontManager sharedManager];
        UIColor *labelGray = [UIColor colorWithWhite:0.45 alpha:1.0];
        for (NSInteger i = 0; i < kPassportAbilitySeatRowCount; i++) {
            UIView *row = [[UIView alloc] init];
            UILabel *left = [[UILabel alloc] init];
            left.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
            left.textColor = labelGray;
            left.numberOfLines = 1;
            left.lineBreakMode = NSLineBreakByTruncatingTail;
            UILabel *right = [[UILabel alloc] init];
            right.font = fm.font18Regular;
            right.textColor = [UIColor colorWithWhite:0.12 alpha:1.0];
            right.textAlignment = NSTextAlignmentRight;
            right.numberOfLines = 1;
            UIView *track = [[UIView alloc] init];
            track.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1.0];
            track.layer.cornerRadius = 6;
            track.clipsToBounds = YES;
            UIView *fill = [[UIView alloc] init];
            fill.backgroundColor = PCGreen();
            fill.layer.cornerRadius = 6;
            fill.clipsToBounds = YES;
            [track addSubview:fill];
            [_tracks addObject:track];
            [_fills addObject:fill];
            [_leftLabels addObject:left];
            [_rightLabels addObject:right];
            [row addSubview:left];
            [row addSubview:track];
            [row addSubview:right];
            [left mas_makeConstraints:^(MASConstraintMaker *make) {
                make.leading.centerY.equalTo(row);
                if (i == 0) {
                    make.width.mas_equalTo(1);
                }
            }];
            [right mas_makeConstraints:^(MASConstraintMaker *make) {
                make.trailing.centerY.equalTo(row);
                make.width.mas_equalTo(kPassportAbilityValueColumnWidth);
            }];
            [track mas_makeConstraints:^(MASConstraintMaker *make) {
                make.leading.equalTo(left.mas_trailing).offset(8);
                make.trailing.equalTo(right.mas_leading).offset(-8);
                make.top.equalTo(row).offset((kPassportAbilityRowHeight - kPassportAbilityBarHeight) / 2.0);
                make.height.mas_equalTo(kPassportAbilityBarHeight);
            }];
            [fill mas_makeConstraints:^(MASConstraintMaker *make) {
                make.leading.top.bottom.equalTo(track);
                make.width.equalTo(track).multipliedBy(0);
            }];
            [row mas_makeConstraints:^(MASConstraintMaker *make) {
                make.height.mas_equalTo(kPassportAbilityRowHeight);
            }];
            [_rowStack addArrangedSubview:row];
        }
        // 等宽约束需在各行都已挂到 _rowStack 上之后再添加，否则无共同父视图会 crash
        for (NSInteger i = 1; i < kPassportAbilitySeatRowCount; i++) {
            UILabel *left = _leftLabels[i];
            [left mas_makeConstraints:^(MASConstraintMaker *make) {
                make.width.equalTo(_leftLabels[0]);
            }];
        }
        [_card addSubview:_title];
        [_card addSubview:_subtitle];
        [_card addSubview:_rowStack];
        [_card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView);
        }];
        [_title mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_card).offset(30);
            make.left.equalTo(_card).offset(16);
            make.trailing.equalTo(_card).offset(-16);
        }];
        [_subtitle mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_title.mas_bottom).offset(2);
            make.leading.trailing.equalTo(_title);
        }];
        [_rowStack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_subtitle.mas_bottom).offset(25);
            make.leading.trailing.equalTo(_card).insets(UIEdgeInsetsMake(0, 16, 0, 16));
//            make.bottom.equalTo(_card).offset(-16);
        }];
    }
    return self;
}

- (void)configureWithModel:(PassportViewModel *)model {
    _title.text = model.abilitySectionTitle;
    /**
     把看台类型 归类为层高 求该赛季总平均层数
     规则：
     内场=0层；1层=1层；2层=2层；3层=3层；4层=4层；
     包厢=2.5层；VIP看台=1.5层
     其余内容不计入统计
     */
    _subtitle.attributedText = PCAbilitySummaryAttributed(model.abilityAverageLevel);
    
    
    /**
     在2026年（所选时间）下 认证的场次 共覆去过多少个线下观赛类型的比赛 他们坐在那里？ 数据从填报信息得来
     X轴表示去过的频次
     Y轴是看台类型
     表格X轴 最大值需要自适应，例如最高Y值是83 那么表格最高值是100
     表格X轴 最大值需要自适应，例如最高Y值是53 那么表格最高值是60
     */
    NSArray<NSDictionary *> *items = model.abilityItems ?: @[];
    NSInteger maxV = 0;
    for (NSDictionary *item in items) {
        NSInteger v = [item[@"value"] integerValue];
        if (v > maxV) maxV = v;
    }
    UIFont *labelFont = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    NSMutableArray<NSString *> *titleStrings = [NSMutableArray array];
    for (NSDictionary *item in items) {
        id t = item[@"title"];
        if ([t isKindOfClass:[NSString class]] && [(NSString *)t length]) {
            [titleStrings addObject:(NSString *)t];
        }
    }
    CGFloat labelColW = PCAbilityMaxLabelWidthForTitles(titleStrings, labelFont);
    if (labelColW < 1) labelColW = 1;
    [_leftLabels[0] mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(labelColW);
    }];
    NSInteger rowCount = kPassportAbilitySeatRowCount;
    for (NSInteger i = 0; i < rowCount; i++) {
        UILabel *left = _leftLabels[i];
        UILabel *right = _rightLabels[i];
        UIView *track = _tracks[i];
        UIView *fill = _fills[i];
        if (i < (NSInteger)items.count) {
            NSDictionary *item = items[i];
            left.text = item[@"title"];
            NSInteger v = [item[@"value"] integerValue];
            right.text = [NSString stringWithFormat:@"%ld", (long)v];
            CGFloat ratio = (maxV > 0) ? (CGFloat)v / (CGFloat)maxV : 0;
            ratio = MIN(1, MAX(0, ratio));
            [fill mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.leading.top.bottom.equalTo(track);
                make.width.equalTo(track).multipliedBy(ratio);
            }];
        } else {
            left.text = @"";
            right.text = @"";
            [fill mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.leading.top.bottom.equalTo(track);
                make.width.equalTo(track).multipliedBy(0);
            }];
        }
    }
}

@end

static NSAttributedString *PCTacticalIdentitySubtitle(NSInteger count) {
    FontManager *fm = [FontManager sharedManager];
    NSString *prefix = NSLocalizedString(@"passport_tactical_identity_sub_prefix", nil) ?: @"我以 ";
    NSString *num = [NSString stringWithFormat:@"%ld", (long)count];
    NSString *suffix = NSLocalizedString(@"passport_tactical_identity_sub_suffix", nil) ?: @" 种身份看比赛";
    UIColor *muted = [UIColor colorWithWhite:0.72 alpha:1.0];
    UIColor *numColor = [UIColor whiteColor];
    NSMutableAttributedString *m = [[NSMutableAttributedString alloc] init];
    [m appendAttributedString:[[NSAttributedString alloc] initWithString:prefix attributes:@{
        NSFontAttributeName: fm.font14Regular,
        NSForegroundColorAttributeName: muted,
    }]];
    [m appendAttributedString:[[NSAttributedString alloc] initWithString:num attributes:@{
        NSFontAttributeName: fm.font18Regular,
        NSForegroundColorAttributeName: numColor,
    }]];
    [m appendAttributedString:[[NSAttributedString alloc] initWithString:suffix attributes:@{
        NSFontAttributeName: fm.font14Regular,
        NSForegroundColorAttributeName: muted,
    }]];
    return m;
}

#pragma mark - Tactical

static CGFloat PCTacticalLegendRowHeight(void) {
    // dot 16 + gap 6 + 14pt 标签约 1~2 行
    return 62.0;
}

/// 观赛身份环图色板（多于色数时循环使用，避免挤成同一色）
static NSArray<UIColor *> *PCTacticalIdentityPalette(void) {
    static NSArray<UIColor *> *colors;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray<NSString *> *hexes = @[
            @"#CCFFDC", @"#62D486", @"#5CB793", @"#3D8B7A", @"#285D4B", @"#1B3C3E",
            @"#A8E6C3", @"#7BC99A", @"#4AA882", @"#2E6B5C", @"#0F2E30", @"#8FD4A8",
            @"#B8F0D0", @"#45B38A", @"#1F4A42", @"#6ED4A0", @"#347A68", @"#0A2426",
            @"#9ADDBC", @"#58C49A",
        ];
        NSMutableArray<UIColor *> *arr = [NSMutableArray arrayWithCapacity:hexes.count];
        for (NSString *h in hexes) {
            [arr addObject:[UIColor colorWithHexString:h]];
        }
        colors = [arr copy];
    });
    return colors;
}

static UIColor *PCTacticalIdentityColorAtIndex(NSUInteger index) {
    NSArray<UIColor *> *cols = PCTacticalIdentityPalette();
    if (cols.count == 0) {
        return [UIColor colorWithHexString:@"#5CB793"];
    }
    return cols[index % cols.count];
}

@implementation PassportTacticalCell {
    UIView *_card;
    UILabel *_title;
    UILabel *_subtitle;
    PassportDonutChartView *_donut;
    /// 纵向：每行最多 3 个图例（UIStackView horizontal）
    UIStackView *_legendOuterStack;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        _card = [[UIView alloc] init];
        _card.backgroundColor = PCHex(@"0D2122");
        _card.layer.cornerRadius = 24;
        _card.clipsToBounds = YES;
        [self.contentView addSubview:_card];
        _title = [[UILabel alloc] init];
        _title.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
        _title.textColor = [UIColor whiteColor];
        _title.numberOfLines = 1;
        _subtitle = [[UILabel alloc] init];
        _subtitle.numberOfLines = 1;
        _donut = [[PassportDonutChartView alloc] init];
        _donut.lineWidth = 40;
        _donut.ringInnerRadius = 40;
        _donut.showsOutsidePercentLabels = YES;
        _donut.outsidePercentLabelColor = [UIColor whiteColor];
        _legendOuterStack = [[UIStackView alloc] init];
        _legendOuterStack.axis = UILayoutConstraintAxisVertical;
        _legendOuterStack.spacing = 16;
        _legendOuterStack.alignment = UIStackViewAlignmentFill;
        [_card addSubview:_title];
        [_card addSubview:_subtitle];
        [_card addSubview:_donut];
        [_card addSubview:_legendOuterStack];
        [_card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 0, 0, 0));
        }];
        [_title mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_card).offset(30);
            make.leading.equalTo(_card).offset(16);
            make.trailing.equalTo(_card).offset(-16);
        }];
        [_subtitle mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_title.mas_bottom).offset(10);
            make.leading.trailing.equalTo(_title);
        }];
        [_donut mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_subtitle.mas_bottom).offset(12);
            make.centerX.equalTo(_card);
            make.height.mas_equalTo(260);
            make.width.mas_equalTo(_card);
        }];
        [_legendOuterStack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_donut.mas_bottom).offset(12);
            make.leading.trailing.equalTo(_card).insets(UIEdgeInsetsMake(0, 30, 0, 30));
            make.bottom.equalTo(_card).offset(-16);
        }];
    }
    return self;
}

+ (CGFloat)preferredHeightForSegmentCount:(NSUInteger)count {
    static const CGFloat kTop = 30.0;
    static const CGFloat kTitle = 22.0;
    static const CGFloat kTitleSubtitleGap = 10.0;
    static const CGFloat kSubtitle = 20.0;
    static const CGFloat kSubtitleDonutGap = 12.0;
    static const CGFloat kDonut = 260.0;
    static const CGFloat kDonutLegendGap = 12.0;
    static const CGFloat kLegendRowSpacing = 16.0;
    static const CGFloat kBottom = 16.0;

    NSUInteger legendRows = count == 0 ? 0 : (count + 2) / 3;
    CGFloat legendHeight = 0;
    if (legendRows > 0) {
        CGFloat rowH = PCTacticalLegendRowHeight();
        legendHeight = legendRows * rowH + (legendRows - 1) * kLegendRowSpacing;
    }
    return kTop + kTitle + kTitleSubtitleGap + kSubtitle + kSubtitleDonutGap + kDonut + kDonutLegendGap + legendHeight + kBottom;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    for (UIView *v in _legendOuterStack.arrangedSubviews) {
        [_legendOuterStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
}

- (void)configureWithModel:(PassportViewModel *)model {
    [self prepareForReuse];
    _title.text = model.tacticalTitle;
    _subtitle.attributedText = PCTacticalIdentitySubtitle(model.tacticalIdentityCount);
    
    // 环形图数据已在 ViewModel 收成「前 5 + 其他」；色板按扇区索引取色
    NSMutableArray *ratios = [NSMutableArray array];
    NSMutableArray *colors = [NSMutableArray array];
    NSUInteger i = 0;
    for (NSDictionary *seg in model.tacticalSegments) {
        [ratios addObject:seg[@"p"] ?: @0];
        [colors addObject:PCTacticalIdentityColorAtIndex(i)];
        i++;
    }
    _donut.lineWidth = 40;
    _donut.ringInnerRadius = 40;
    _donut.segmentRatios = ratios;
    _donut.segmentColors = colors;
    _donut.centerText = nil;
    _donut.showsOutsidePercentLabels = YES;
    _donut.outsidePercentLabelColor = [UIColor whiteColor];
    _donut.ringTrackColor = PCHex(@"1B3C3E");
    _donut.ringTrackExtraWidth = 10;
    _donut.segmentGapPoints = 5;

    // 观赛身份图例：每行 3 个
    UIFont *legFont = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    NSArray<NSDictionary *> *segs = model.tacticalSegments ?: @[];
    NSUInteger nSeg = segs.count;
    for (NSUInteger rowStart = 0; rowStart < nSeg; rowStart += 3) {
        UIStackView *rowStack = [[UIStackView alloc] init];
        rowStack.axis = UILayoutConstraintAxisHorizontal;
        rowStack.spacing = 8;
        rowStack.distribution = UIStackViewDistributionFillEqually;
        rowStack.alignment = UIStackViewAlignmentFill;
        for (NSUInteger k = 0; k < 3 && rowStart + k < nSeg; k++) {
            NSUInteger i = rowStart + k;
            NSDictionary *seg = segs[i];
            UIView *cell = [[UIView alloc] init];
            UIView *dot = [[UIView alloc] init];
            dot.backgroundColor = PCTacticalIdentityColorAtIndex(i);
            dot.layer.cornerRadius = 8;
            dot.clipsToBounds = YES;
            UILabel *l = [[UILabel alloc] init];
            l.text = [NSString stringWithFormat:@"%@", seg[@"title"] ?: @""];
            l.font = legFont;
            l.textColor = [UIColor colorWithWhite:1 alpha:0.75];
            l.textAlignment = NSTextAlignmentLeft;
            l.numberOfLines = 0;
            [cell addSubview:dot];
            [cell addSubview:l];
            [dot mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.leading.equalTo(cell);
                make.width.height.mas_equalTo(16);
            }];
            [l mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(dot.mas_bottom).offset(6);
                make.leading.trailing.bottom.equalTo(cell);
            }];
            [rowStack addArrangedSubview:cell];
        }
        [_legendOuterStack addArrangedSubview:rowStack];
    }
}

@end

/// 情绪条：左标签 + 仅绿色进度（无灰底）+ 分数紧跟进度末端；ratio = value/max
@interface PCMetricEmotionRowView : UIView
@property (nonatomic, strong, readonly) UIImageView *iconView;
@property (nonatomic, strong, readonly) UILabel *leftLabel;
@property (nonatomic, strong, readonly) UILabel *scoreLabel;
@property (nonatomic, assign) CGFloat labelColumnWidth;
@property (nonatomic, assign) CGFloat ratio;
@end

@interface PCMetricEmotionRowView ()
@property (nonatomic, strong) UIView *fillBar;
@end

@implementation PCMetricEmotionRowView

- (instancetype)initWithLabelColumnWidth:(CGFloat)lw ratio:(CGFloat)ratio {
    if (self = [super initWithFrame:CGRectZero]) {
        _labelColumnWidth = lw;
        _ratio = MIN(1, MAX(0, ratio));
        self.backgroundColor = [UIColor clearColor];
        _iconView = [[UIImageView alloc] init];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        _leftLabel = [[UILabel alloc] init];
        _leftLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
        _leftLabel.textColor = [UIColor colorWithWhite:0.45 alpha:1.0];
        _leftLabel.numberOfLines = 1;
        _leftLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        UIView *fill = [[UIView alloc] init];
        fill.backgroundColor = PCGreen();
        fill.layer.cornerRadius = 6;
        fill.clipsToBounds = YES;
        self.fillBar = fill;
        _scoreLabel = [[UILabel alloc] init];
        _scoreLabel.font = [FontManager sharedManager].font18Regular;
        _scoreLabel.textColor = [UIColor colorWithWhite:0.12 alpha:1.0];
        _scoreLabel.numberOfLines = 1;
        [self addSubview:_iconView];
        [self addSubview:_leftLabel];
        [self addSubview:self.fillBar];
        [self addSubview:_scoreLabel];
        _iconView.translatesAutoresizingMaskIntoConstraints = YES;
        _leftLabel.translatesAutoresizingMaskIntoConstraints = YES;
        self.fillBar.translatesAutoresizingMaskIntoConstraints = YES;
        _scoreLabel.translatesAutoresizingMaskIntoConstraints = YES;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat rowW = CGRectGetWidth(self.bounds);
    CGFloat rowH = CGRectGetHeight(self.bounds);
    CGFloat leftW = self.labelColumnWidth;
    NSDictionary *scoreAttrs = @{ NSFontAttributeName: self.scoreLabel.font };
    CGSize scoreSz = [self.scoreLabel.text boundingRectWithSize:CGSizeMake(200, 40)
                                                         options:NSStringDrawingUsesLineFragmentOrigin
                                                      attributes:scoreAttrs
                                                         context:nil].size;
    scoreSz.width = ceil(scoreSz.width);
    scoreSz.height = ceil(MAX(scoreSz.height, 20));
    static const CGFloat gap = 8;
    CGFloat avail = rowW - leftW - scoreSz.width - 2 * gap;
    if (avail < 0) {
        avail = 0;
    }
    CGFloat fillW = avail * self.ratio;
    CGFloat yBar = (rowH - kPassportAbilityBarHeight) / 2.0;
    CGFloat yScore = (rowH - scoreSz.height) / 2.0;
    CGFloat iconY = (rowH - kPassportEmotionIconSize) / 2.0;
    self.iconView.frame = CGRectMake(0, iconY, kPassportEmotionIconSize, kPassportEmotionIconSize);
    CGFloat textX = kPassportEmotionIconSize + kPassportEmotionIconTextGap;
    CGFloat textW = MAX(0, leftW - textX);
    self.leftLabel.frame = CGRectMake(textX, 0, textW, rowH);
    self.fillBar.frame = CGRectMake(leftW + gap, yBar, fillW, kPassportAbilityBarHeight);
    self.scoreLabel.frame = CGRectMake(leftW + gap + fillW + gap, yScore, scoreSz.width, scoreSz.height);
}

@end

#pragma mark - Metric bars

@implementation PassportMetricBarsCell {
    UIView *_card;
    UIView *_headerRow;
    UILabel *_bigNumber;
    UILabel *_asideLine1;
    UILabel *_asideLine2;
    UILabel *_prompt;
    UIStackView *_stack;
    UIView *_bottomDashView;
    CAShapeLayer *_bottomDashLayer;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        _card = [[UIView alloc] init];
        _card.backgroundColor = PCLightCard();
        _card.layer.cornerRadius = 24;
        _card.clipsToBounds = YES;
        [self.contentView addSubview:_card];
        _headerRow = [[UIView alloc] init];
        _bigNumber = [[UILabel alloc] init];
        _bigNumber.font = [UIFont systemFontOfSize:90 weight:UIFontWeightRegular];
        _bigNumber.textColor = [UIColor colorWithWhite:0.12 alpha:1.0];
        _bigNumber.numberOfLines = 1;
        _asideLine1 = [[UILabel alloc] init];
        _asideLine1.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        _asideLine1.textColor = [UIColor colorWithWhite:0 alpha:1.0];
        _asideLine1.numberOfLines = 1;
        _asideLine2 = [[UILabel alloc] init];
        _asideLine2.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        _asideLine2.textColor = [UIColor colorWithWhite:0 alpha:1.0];
        _asideLine2.numberOfLines = 1;
        UIStackView *asideStack = [[UIStackView alloc] initWithArrangedSubviews:@[ _asideLine1, _asideLine2 ]];
        asideStack.axis = UILayoutConstraintAxisVertical;
        asideStack.spacing = 2;
        _prompt = [[UILabel alloc] init];
        _prompt.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        _prompt.textColor = [UIColor colorWithWhite:0 alpha:1.0];
        _prompt.numberOfLines = 1;
        _stack = [[UIStackView alloc] init];
        _stack.axis = UILayoutConstraintAxisVertical;
        _stack.spacing = 0;
        [_headerRow addSubview:_bigNumber];
        [_headerRow addSubview:asideStack];
        [_card addSubview:_headerRow];
        [_card addSubview:_prompt];
        [_card addSubview:_stack];
        [_card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.leading.trailing.equalTo(self.contentView);
            make.bottom.equalTo(self.contentView).offset(-2);
        }];

        // 底部虚线区域（card 底部到 cell 底部之间，居中画虚线）
        UIView *bottomDashView = [[UIView alloc] init];
        bottomDashView.backgroundColor = [UIColor clearColor];
        _bottomDashView = bottomDashView;
        [self.contentView addSubview:bottomDashView];
        [bottomDashView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_card.mas_bottom);
            make.leading.trailing.bottom.equalTo(self.contentView);
        }];
        CAShapeLayer *dashLayer = [CAShapeLayer layer];
        dashLayer.strokeColor = [UIColor colorWithWhite:0.75 alpha:1.0].CGColor;
        dashLayer.fillColor = [UIColor clearColor].CGColor;
        dashLayer.lineWidth = 1;
        dashLayer.lineDashPattern = @[@6, @4];
        [bottomDashView.layer addSublayer:dashLayer];
        _bottomDashLayer = dashLayer;

        [_headerRow mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_card).offset(16);
            make.leading.equalTo(_card).offset(16);
            make.trailing.equalTo(_card).offset(-16);
        }];
        [_bigNumber mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.top.bottom.equalTo(_headerRow);
        }];
        [asideStack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_bigNumber.mas_trailing).offset(12);
            make.bottom.equalTo(_bigNumber).offset(-26);
            make.trailing.lessThanOrEqualTo(_headerRow);
        }];
        [_prompt mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_headerRow.mas_bottom).offset(10);
            make.leading.equalTo(_card).offset(16);
            make.trailing.equalTo(_card).offset(-16);
        }];
        [_stack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_prompt.mas_bottom).offset(12);
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

- (void)layoutSubviews {
    [super layoutSubviews];
    if (_bottomDashView && _bottomDashLayer) {
        CGFloat w = CGRectGetWidth(_bottomDashView.bounds);
        if (w > 0) {
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointMake(16, 1)];
            [path addLineToPoint:CGPointMake(w - 16, 1)];
            _bottomDashLayer.path = path.CGPath;
        }
    }
}

- (void)configureWithModel:(PassportViewModel *)model {
    [self prepareForReuse];
    // 7 种情绪，与输入信息页一致
    _bigNumber.text = [NSString stringWithFormat:@"%ld", (long)model.metricEmotionCount];
    _asideLine1.text = @"我出现了";
    _asideLine2.text = [NSString stringWithFormat:@"种赛后情绪"];
    _prompt.text = model.metricBarsPrompt;
    
    /**
     X轴表示心情的频次
     Y轴是心情类型
     表格X轴 最大值需要自适应，例如最高Y值是83 那么表格最高值是100
     表格X轴 最大值需要自适应，例如最高Y值是53 那么表格最高值是60
     */
    NSArray<NSDictionary *> *items = model.recentMetricBars ?: @[];
    NSInteger maxV = 0;
    for (NSDictionary *item in items) {
        NSInteger v = [item[@"value"] integerValue];
        if (v > maxV) maxV = v;
    }
    UIFont *labelFont = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    NSMutableArray<NSString *> *titles = [NSMutableArray array];
    for (NSDictionary *item in items) {
        id t = item[@"title"];
        if ([t isKindOfClass:[NSString class]] && [(NSString *)t length]) {
            [titles addObject:(NSString *)t];
        }
    }
    CGFloat textColW = PCAbilityMaxLabelWidthForTitles(titles, labelFont);
    CGFloat labelColW = kPassportEmotionIconSize + kPassportEmotionIconTextGap + textColW;
    if (labelColW < 1) labelColW = 1;
    for (NSDictionary *item in items) {
        NSInteger val = [item[@"value"] integerValue];
        CGFloat ratio = (maxV > 0) ? (CGFloat)val / (CGFloat)maxV : 0;
        ratio = MIN(1, MAX(0, ratio));
        PCMetricEmotionRowView *row = [[PCMetricEmotionRowView alloc] initWithLabelColumnWidth:labelColW ratio:ratio];
        row.leftLabel.text = [NSString stringWithFormat:@"%@", item[@"title"] ?: @""];
        row.leftLabel.font = labelFont;
        NSString *iconName = [item[@"icon"] isKindOfClass:[NSString class]] ? item[@"icon"] : @"";
        row.iconView.image = iconName.length ? [UIImage imageNamed:iconName] : nil;
        row.scoreLabel.text = [NSString stringWithFormat:@"%ld", (long)val];
        [row mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(kPassportAbilityRowHeight);
        }];
        [_stack addArrangedSubview:row];
    }
}

@end

#pragma mark - Outcome

static UIView *PCOutcomeLegendItemView(NSString *title, NSString *numStr, UIColor *dotColor) {
    UIView *wrap = [[UIView alloc] init];
    UIStackView *row = [[UIStackView alloc] init];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.spacing = 6;
    row.alignment = UIStackViewAlignmentCenter;
    UIView *dot = [[UIView alloc] init];
    dot.backgroundColor = dotColor;
    dot.layer.cornerRadius = 4;
    dot.clipsToBounds = YES;
    [dot mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(8);
    }];
    UILabel *lab = [[UILabel alloc] init];
    lab.text = title ?: @"";
    lab.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    lab.textColor = [UIColor colorWithWhite:0.45 alpha:1.0];
    lab.numberOfLines = 2;
    [lab setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    UILabel *num = [[UILabel alloc] init];
    num.text = numStr ?: @"";
    num.font = [FontManager sharedManager].font30Regular;
    num.textColor = [UIColor colorWithWhite:0.12 alpha:1.0];
    num.textAlignment = NSTextAlignmentLeft;
    [num setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [row addArrangedSubview:dot];
    [row addArrangedSubview:lab];
    [row addArrangedSubview:num];
    [wrap addSubview:row];
    [row mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(wrap);
    }];
    return wrap;
}

@implementation PassportOutcomeCell {
    UIView *_card;
    UILabel *_title;
    PassportDonutChartView *_donut;
    UIStackView *_legend;
    UIView *_dashedLineView;
    CAShapeLayer *_dashLayer;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        _card = [[UIView alloc] init];
        _card.backgroundColor = PCLightCard();
        _card.layer.cornerRadius = 24;
        [self.contentView addSubview:_card];

        [_card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView);
        }];
        _title = [[UILabel alloc] init];
        _title.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
        _title.textColor = [UIColor colorWithWhite:0 alpha:1.0];
        _donut = [[PassportDonutChartView alloc] init];
        _donut.lineWidth = 40;
        _legend = [[UIStackView alloc] init];
        _legend.axis = UILayoutConstraintAxisVertical;
        _legend.spacing = 12;
        [_card addSubview:_title];
        [_card addSubview:_donut];
        [_card addSubview:_legend];
        [_title mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_card).offset(30);
            make.leading.equalTo(_card).offset(16);
            make.trailing.equalTo(_card).offset(-16);
        }];
        [_donut mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_title.mas_bottom).offset(30);
            make.centerX.equalTo(_card);
            make.width.height.mas_equalTo(199);
        }];
        [_legend mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_donut.mas_bottom).offset(12);
            make.leading.trailing.equalTo(_card).insets(UIEdgeInsetsMake(0, 26, 0, 26));
//            make.bottom.equalTo(_card).offset(-16);
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

- (void)layoutSubviews {
    [super layoutSubviews];
    if (_dashedLineView && _dashLayer) {
        CGFloat w = CGRectGetWidth(_dashedLineView.bounds);
        if (w > 0) {
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointMake(16, 16)];
            [path addLineToPoint:CGPointMake(w - 16, 16)];
            _dashLayer.path = path.CGPath;
        }
    }
}

- (void)configureWithModel:(PassportViewModel *)model {
    [self prepareForReuse];
    _title.text = model.outcomeTitle;
    /**
     在2026赛季 以最多3种 线上看球的情况
     打开又关掉 说明比赛没意思 主队没赢
     关掉又打开 说明中间办事去了 活着犯贱接着看
     or 完整看
     */
    CGFloat p = MIN(1, MAX(0, model.outcomeCenterPercent));
    _donut.lineWidth = 40;
    _donut.showsOutsidePercentLabels = NO;
    _donut.ringInnerRadius = 0;
    _donut.ringTrackColor = nil;
    _donut.ringTrackExtraWidth = 0;
    _donut.segmentGapPoints = 0;
    NSArray<NSDictionary *> *legs = model.outcomeLegend ?: @[];
    NSMutableArray<NSNumber *> *ratios = [NSMutableArray array];
    NSMutableArray<UIColor *> *segColors = [NSMutableArray array];
    CGFloat sum = 0;
    NSMutableArray<NSNumber *> *vals = [NSMutableArray array];
    for (NSDictionary *leg in legs) {
        double v = 0;
        id nv = leg[@"n"];
        if ([nv isKindOfClass:[NSNumber class]]) {
            v = [(NSNumber *)nv doubleValue];
        } else {
            v = [NSString stringWithFormat:@"%@", nv ?: @"0"].doubleValue;
        }
        [vals addObject:@(v)];
        sum += v;
    }
    BOOL allZeroWeights = (sum < 1e-9 && legs.count > 0);
    for (NSUInteger i = 0; i < legs.count; i++) {
        NSDictionary *leg = legs[i];
        double v = [vals[i] doubleValue];
        double r = 0;
        if (allZeroWeights) {
            // 全 0 空态：不画均分扇区（否则中心 0% 与四份彩色圆环自相矛盾），
            // 由下方统一替换为灰色空环
            r = 0;
        } else {
            r = sum > 0 ? v / sum : 0;
        }
        [ratios addObject:@(r)];
        [segColors addObject:PCHex([NSString stringWithFormat:@"%@", leg[@"h"] ?: @"000000"])];
    }
    if (allZeroWeights) {
        // 空数据：灰色空环 + 中心 0%
        [ratios removeAllObjects];
        [segColors removeAllObjects];
        [ratios addObject:@(1.0)];
        [segColors addObject:[UIColor colorWithWhite:0.88 alpha:1.0]];
    }
    if (ratios.count == 0) {
        [ratios addObjectsFromArray:@[ @(p), @(1 - p) ]];
        [segColors addObjectsFromArray:@[ PCGreen(), [UIColor colorWithWhite:0.88 alpha:1.0] ]];
    }
    _donut.segmentRatios = ratios;
    _donut.segmentColors = segColors;
    _donut.centerText = [NSString stringWithFormat:@"%.0f%%", p * 100];
    for (NSUInteger i = 0; i < legs.count; i += 2) {
        UIStackView *row = [[UIStackView alloc] init];
        row.axis = UILayoutConstraintAxisHorizontal;
        row.spacing = 8;
        row.distribution = UIStackViewDistributionFillEqually;
        NSDictionary *a = legs[i];
        NSString *na = [NSString stringWithFormat:@"%@", a[@"n"] ?: @""];
        UIView *left = PCOutcomeLegendItemView([NSString stringWithFormat:@"%@", a[@"t"] ?: @""], na, PCHex([NSString stringWithFormat:@"%@", a[@"h"] ?: @"000000"]));
        if (i + 1 < legs.count) {
            NSDictionary *b = legs[i + 1];
            NSString *nb = [NSString stringWithFormat:@"%@", b[@"n"] ?: @""];
            UIView *right = PCOutcomeLegendItemView([NSString stringWithFormat:@"%@", b[@"t"] ?: @""], nb, PCHex([NSString stringWithFormat:@"%@", b[@"h"] ?: @"000000"]));
            [row addArrangedSubview:left];
            [row addArrangedSubview:right];
        } else {
            [row addArrangedSubview:left];
            [row addArrangedSubview:[[UIView alloc] init]];
        }
        [_legend addArrangedSubview:row];
    }
}

@end

#pragma mark - Chart load-failed empty

@implementation PassportChartEmptyStateCell {
    UIView *_card;
    UILabel *_titleLabel;
    UILabel *_hintLabel;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];

        _card = [[UIView alloc] init];
        _card.backgroundColor = PCLightCard();
        _card.layer.cornerRadius = 24;
        _card.clipsToBounds = YES;
        [self.contentView addSubview:_card];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = FontManager.sharedManager.font18Regular;
        _titleLabel.textColor = [UIColor colorWithWhite:0.12 alpha:1.0];
        _titleLabel.numberOfLines = 1;
        [_card addSubview:_titleLabel];

        _hintLabel = [[UILabel alloc] init];
        _hintLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
        _hintLabel.textColor = [UIColor colorWithWhite:0.55 alpha:1.0];
        _hintLabel.textAlignment = NSTextAlignmentCenter;
        _hintLabel.numberOfLines = 0;
        [_card addSubview:_hintLabel];

        [_card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 0, 8, 0));
            make.height.mas_equalTo(160);
        }];
        [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.leading.equalTo(_card).offset(16);
            make.trailing.equalTo(_card).offset(-16);
        }];
        [_hintLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(_card).offset(8);
            make.leading.equalTo(_card).offset(24);
            make.trailing.equalTo(_card).offset(-24);
        }];
    }
    return self;
}

- (void)configureWithTitle:(NSString *)title {
    _titleLabel.text = title.length ? title : @"";
    NSString *hint = NSLocalizedString(@"passport_chart_load_failed", nil);
    if (!hint.length || [hint isEqualToString:@"passport_chart_load_failed"]) {
        hint = @"加载失败，下拉或点击刷新重试";
    }
    _hintLabel.text = hint;
}

@end
