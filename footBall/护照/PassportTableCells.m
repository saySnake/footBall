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

static const CGFloat kPassportAbilityValueColumnWidth = 24;
static const CGFloat kPassportAbilityBarHeight = 12;
static const CGFloat kPassportAbilityRowHeight = 29;

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

static void PCPossessionSplitLine(NSString *line, NSString **num, NSString **rest) {
    if (!line.length) {
        *num = @"";
        *rest = @"";
        return;
    }
    NSUInteger i = 0;
    while (i < line.length) {
        unichar ch = [line characterAtIndex:i];
        if (ch >= '0' && ch <= '9') {
            i++;
        } else {
            break;
        }
    }
    *num = [line substringToIndex:i];
    *rest = [[line substringFromIndex:i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
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
        _headerCard.backgroundColor = PCDarkCard();
        _headerCard.layer.cornerRadius = 16;
        _headerCard.clipsToBounds = YES;
        [self.contentView addSubview:_headerCard];
        _title = [[UILabel alloc] init];
        _title.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBold];
        _title.textColor = [UIColor whiteColor];
        [_headerCard addSubview:_title];

        NSMutableArray<UIView *> *rows = [NSMutableArray array];
        NSMutableArray<UILabel *> *ls = [NSMutableArray array];
        NSMutableArray<UILabel *> *vs = [NSMutableArray array];
        NSMutableArray<UILabel *> *us = [NSMutableArray array];

        // 纯色（不透明），按设计稿从上到下逐渐变亮一点
        NSArray<UIColor *> *rowColors = @[
            PCHex(@"2A2B30"),
            PCHex(@"303138"),
            PCHex(@"353742"),
            PCHex(@"3A3D4A"),
        ];
        for (NSInteger i = 0; i < rowColors.count; i++) {
            UIView *rowCard = [[UIView alloc] init];
            rowCard.backgroundColor = rowColors[i];
            rowCard.layer.cornerRadius = 18;
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
                make.centerY.equalTo(rowCard);
                make.right.lessThanOrEqualTo(val.mas_left).offset(-12);
            }];
            [unit mas_makeConstraints:^(MASConstraintMaker *make) {
                make.right.equalTo(rowCard).offset(-18);
                make.centerY.equalTo(val).offset(6);
            }];
            [val mas_makeConstraints:^(MASConstraintMaker *make) {
                make.right.equalTo(unit.mas_left).offset(-10);
                make.centerY.equalTo(rowCard);
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

        CGFloat cardH = 89.0;
        CGFloat overlap = 21.0;

        [_headerCard mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.contentView);
            make.top.equalTo(self.contentView).offset(6);
            make.height.mas_equalTo(cardH);
        }];
        [_title mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.leading.equalTo(_headerCard).offset(16);
            make.trailing.equalTo(_headerCard).offset(-16);
        }];

        UIView *prev = _headerCard;
        for (NSInteger i = 0; i < _rows.count; i++) {
            UIView *row = _rows[i];
            [row mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.right.equalTo(self.contentView);
                make.height.mas_equalTo(cardH);
                // 从第二个开始向上叠压 21（等价于 top = prev.bottom - 21）
                make.top.equalTo(prev.mas_bottom).offset(-overlap);
                if (i == _rows.count - 1) {
                    make.bottom.equalTo(self.contentView).offset(-6);
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
    [self setRowAtIndex:0 left:model.avgDurationTitle right:model.avgDurationValue];
    [self setRowAtIndex:1 left:model.matchesYearTitle right:model.matchesYearValue];
    [self setRowAtIndex:2 left:model.avgGoalsMatchTitle right:model.avgGoalsMatchValue];
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
        _card.backgroundColor = PCGreen();
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
        _percent.text = @"0%";
        [_card addSubview:_percent];

        _suffix = [[UILabel alloc] init];
        _suffix.font = [UIFont systemFontOfSize:30 weight:UIFontWeightSemibold];
        _suffix.textColor = [UIColor whiteColor];
        _suffix.text = @"都在看球";
        [_card addSubview:_suffix];

        _bottomLine = [[UILabel alloc] init];
        _bottomLine.font = FontManager.sharedManager.font11Regular;
        _bottomLine.textColor = [UIColor whiteColor];
        _bottomLine.text = @"睡眠按8小时为例";
        [_card addSubview:_bottomLine];

        [_card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(6, 0, 6, 0));
        }];
        [_topLine mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_card).offset(16);
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
            make.centerY.equalTo(_percent).offset(-6);
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
    // growthHeadline 作为第一行；percent 与后缀先用 subtitle 里占位（后续可用 model 字段扩展）
    _topLine.text = model.growthHeadline.length ? model.growthHeadline : @"2025年睡醒时间里的";
    // 如果 subtitle 里形如 "0%"，则填充 percent；否则保持默认
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
        _title.font = FontManager.sharedManager.font18Regular;
        _title.textColor = [UIColor colorWithWhite:0.12 alpha:1.0];
        _chart = [[PassportBarChartView alloc] init];
        _chart.barColor = PCGreen();
        _chart.barWidth = 20;
        [_card addSubview:_title];
        [_card addSubview:_chart];
        [_card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(6, 0, 6, 0));
        }];
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

- (void)configureWithModel:(PassportViewModel *)model {
    _title.text = model.goalTrendTitle;
    _chart.maxValue = 100;
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
        _card.layer.cornerRadius = 16;
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
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(6, 0, 6, 0));
        }];
        [_title mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_card).offset(16);
            make.left.equalTo(_card).offset(16);
            make.right.equalTo(_card).offset(-16);
        }];
        [_donut mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(_card).offset(-16);
            make.centerY.equalTo(_card);
            make.width.height.mas_equalTo(154);
        }];
        [_num1 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_card).offset(16);
            make.top.equalTo(_title.mas_bottom).offset(20);
        }];
        [_desc1 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_num1.mas_right).offset(10);
            make.centerY.equalTo(_num1);
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
            make.centerY.equalTo(_num2);
            make.right.lessThanOrEqualTo(_donut.mas_left).offset(-12);
        }];
    }
    return self;
}

- (void)configureWithModel:(PassportViewModel *)model {
    _title.text = model.possessionCardTitle;
    NSString *n1, *r1, *n2, *r2;
    PCPossessionSplitLine(model.possessionLeftLine1, &n1, &r1);
    PCPossessionSplitLine(model.possessionLeftLine2, &n2, &r2);
    _num1.text = n1; _desc1.text = r1;
    _num2.text = n2; _desc2.text = r2;
    CGFloat p = model.possessionCenterPercent;
    p = MIN(1, MAX(0, p));
    _donut.lineWidth = 24;
    _donut.showsOutsidePercentLabels = NO;
    _donut.ringInnerRadius = 0;
    _donut.ringTrackColor = nil;
    _donut.ringTrackExtraWidth = 0;
    _donut.segmentGapPoints = 0;
    _donut.segmentRatios = @[ @(p), @(1 - p) ];
    _donut.segmentColors = @[ [UIColor colorWithRed:0.2 green:0.62 blue:0.55 alpha:1.0], [UIColor colorWithWhite:0.18 alpha:1.0] ];
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

static UIView *PCPositionRow(UILabel **outL, UILabel **outV) {
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
        make.centerY.equalTo(row);
        make.right.lessThanOrEqualTo(v.mas_left).offset(-12);
    }];
    [v mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(row).offset(-16);
        make.centerY.equalTo(row);
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
        _headerStrip.backgroundColor = PCDarkCard();
        PCPositionSetCorners(_headerStrip, UIRectCornerTopLeft | UIRectCornerTopRight, 20);
        [_card addSubview:_headerStrip];
        _title = [[UILabel alloc] init];
        _title.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
        _title.textColor = [UIColor whiteColor];
        _title.numberOfLines = 1;
        [_headerStrip addSubview:_title];

        UILabel *l1, *v1, *l2, *v2, *l3, *v3;
        _row1 = PCPositionRow(&l1, &v1);
        _l1 = l1;
        _v1 = v1;
        _row2 = PCPositionRow(&l2, &v2);
        _l2 = l2;
        _v2 = v2;
        _row3 = PCPositionRow(&l3, &v3);
        _l3 = l3;
        _v3 = v3;
        PCPositionSetCorners(_row1, UIRectCornerTopLeft | UIRectCornerTopRight, 20);
        PCPositionSetCorners(_row2, UIRectCornerTopLeft | UIRectCornerTopRight, 20);
        // 最后一行：仅上沿圆角，底边与容器齐平为直角
        PCPositionSetCorners(_row3, UIRectCornerTopLeft | UIRectCornerTopRight, 20);
        [_card addSubview:_row1];
        [_card addSubview:_row2];
        [_card addSubview:_row3];

        [_card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(6, 0, 6, 0));
        }];
        [_headerStrip mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.equalTo(_card);
            make.height.mas_equalTo(89);
        }];
        [_title mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_headerStrip).offset(16);
            make.left.equalTo(_headerStrip).offset(16);
            make.right.equalTo(_headerStrip).offset(-16);
        }];
        [_row1 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(_card);
            make.top.equalTo(_headerStrip.mas_bottom).offset(-21);
            make.height.mas_equalTo(123);
        }];
        [_row2 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(_card);
            make.top.equalTo(_row1.mas_bottom).offset(-21);
            make.height.mas_equalTo(123);
        }];
        [_row3 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(_card);
            make.top.equalTo(_row2.mas_bottom).offset(-21);
            make.height.mas_equalTo(106);
            make.bottom.equalTo(_card);
        }];
    }
    return self;
}

- (void)configureWithModel:(PassportViewModel *)model {
    _title.text = model.positionSectionTitle;
    _l1.text = model.positionForwardLabel;
    _v1.text = [NSString stringWithFormat:@"%ld", (long)model.positionForward];
    _l2.text = model.positionMidfieldLabel;
    _v2.text = [NSString stringWithFormat:@"%ld", (long)model.positionMidfield];
    _l3.text = model.positionDefenderLabel;
    _v3.text = [NSString stringWithFormat:@"%ld", (long)model.positionDefender];

    _row1.backgroundColor = PCHex(@"1F3D2E");
    _v1.textColor = PCHex(@"A8E6CF");
    _row2.backgroundColor = PCHex(@"4A6B5C");
    _v2.textColor = PCHex(@"1A2420");
    _row3.backgroundColor = PCHex(@"5CB793");
    _v3.textColor = PCHex(@"1A2420");
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
        _card.layer.cornerRadius = 16;
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
        for (NSInteger i = 0; i < 14; i++) {
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
        for (NSInteger i = 1; i < 14; i++) {
            UILabel *left = _leftLabels[i];
            [left mas_makeConstraints:^(MASConstraintMaker *make) {
                make.width.equalTo(_leftLabels[0]);
            }];
        }
        [_card addSubview:_title];
        [_card addSubview:_subtitle];
        [_card addSubview:_rowStack];
        [_card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(6, 0, 6, 0));
        }];
        [_title mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.leading.equalTo(_card).offset(16);
            make.trailing.equalTo(_card).offset(-16);
        }];
        [_subtitle mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_title.mas_bottom).offset(8);
            make.leading.trailing.equalTo(_title);
        }];
        [_rowStack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_subtitle.mas_bottom).offset(12);
            make.leading.trailing.equalTo(_card).insets(UIEdgeInsetsMake(0, 16, 0, 16));
            make.bottom.equalTo(_card).offset(-16);
        }];
    }
    return self;
}

- (void)configureWithModel:(PassportViewModel *)model {
    _title.text = model.abilitySectionTitle;
    _subtitle.attributedText = PCAbilitySummaryAttributed(model.abilityAverageLevel);
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
    for (NSInteger i = 0; i < 14; i++) {
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

@implementation PassportTacticalCell {
    UIView *_card;
    UILabel *_title;
    UILabel *_subtitle;
    PassportDonutChartView *_donut;
    UIStackView *_legendRow;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        _card = [[UIView alloc] init];
        _card.backgroundColor = PCHex(@"0D2122");
        _card.layer.cornerRadius = 16;
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
        _legendRow = [[UIStackView alloc] init];
        _legendRow.axis = UILayoutConstraintAxisHorizontal;
        _legendRow.spacing = 8;
        _legendRow.distribution = UIStackViewDistributionFillEqually;
        _legendRow.alignment = UIStackViewAlignmentFill;
        [_card addSubview:_title];
        [_card addSubview:_subtitle];
        [_card addSubview:_donut];
        [_card addSubview:_legendRow];
        [_card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(6, 0, 6, 0));
        }];
        [_title mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.leading.equalTo(_card).offset(16);
            make.trailing.equalTo(_card).offset(-16);
        }];
        [_subtitle mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_title.mas_bottom).offset(8);
            make.leading.trailing.equalTo(_title);
        }];
        [_donut mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_subtitle.mas_bottom).offset(12);
            make.centerX.equalTo(_card);
            make.width.height.mas_equalTo(260);
        }];
        [_legendRow mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_donut.mas_bottom).offset(12);
            make.leading.trailing.equalTo(_card).insets(UIEdgeInsetsMake(0, 16, 0, 16));
            make.bottom.equalTo(_card).offset(-16);
        }];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    for (UIView *v in _legendRow.arrangedSubviews) {
        [_legendRow removeArrangedSubview:v];
        [v removeFromSuperview];
    }
}

- (void)configureWithModel:(PassportViewModel *)model {
    [self prepareForReuse];
    _title.text = model.tacticalTitle;
    _subtitle.attributedText = PCTacticalIdentitySubtitle(model.tacticalIdentityCount);
    NSMutableArray *ratios = [NSMutableArray array];
    NSArray<UIColor *> *cols = @[
        [UIColor colorWithRed:0.12 green:0.42 blue:0.38 alpha:1.0],
        [UIColor colorWithRed:0.50 green:0.82 blue:0.65 alpha:1.0],
        [UIColor colorWithRed:0.25 green:0.58 blue:0.48 alpha:1.0],
    ];
    NSMutableArray *colors = [NSMutableArray array];
    NSUInteger i = 0;
    for (NSDictionary *seg in model.tacticalSegments) {
        [ratios addObject:seg[@"p"] ?: @0];
        [colors addObject:cols[MIN(i, cols.count - 1)]];
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

    UIFont *legFont = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];

    i = 0;
    for (NSDictionary *seg in model.tacticalSegments) {
        UIView *cell = [[UIView alloc] init];
        UIView *dot = [[UIView alloc] init];
        dot.backgroundColor = cols[MIN(i, cols.count - 1)];
        dot.layer.cornerRadius = 4;
        dot.clipsToBounds = YES;
        UILabel *l = [[UILabel alloc] init];
        l.text = [NSString stringWithFormat:@"%@", seg[@"title"] ?: @""];
        l.font = legFont;
        l.textColor = [UIColor colorWithWhite:0.88 alpha:1.0];
        l.textAlignment = NSTextAlignmentLeft;
        l.numberOfLines = 0;
        [cell addSubview:dot];
        [cell addSubview:l];
        [dot mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.leading.equalTo(cell);
            make.width.height.mas_equalTo(8);
        }];
        [l mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(dot.mas_bottom).offset(6);
            make.leading.trailing.bottom.equalTo(cell);
        }];
        [_legendRow addArrangedSubview:cell];
        i++;
    }
}

@end

/// 情绪条：左标签 + 仅绿色进度（无灰底）+ 分数紧跟进度末端；ratio = value/max
@interface PCMetricEmotionRowView : UIView
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
        [self addSubview:_leftLabel];
        [self addSubview:self.fillBar];
        [self addSubview:_scoreLabel];
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
    self.leftLabel.frame = CGRectMake(0, 0, leftW, rowH);
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
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        _card = [[UIView alloc] init];
        _card.backgroundColor = PCLightCard();
        _card.layer.cornerRadius = 16;
        _card.clipsToBounds = YES;
        [self.contentView addSubview:_card];
        _headerRow = [[UIView alloc] init];
        _bigNumber = [[UILabel alloc] init];
        _bigNumber.font = [UIFont systemFontOfSize:90 weight:UIFontWeightRegular];
        _bigNumber.textColor = [UIColor colorWithWhite:0.12 alpha:1.0];
        _bigNumber.numberOfLines = 1;
        _asideLine1 = [[UILabel alloc] init];
        _asideLine1.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
        _asideLine1.textColor = [UIColor colorWithWhite:0.12 alpha:1.0];
        _asideLine1.numberOfLines = 1;
        _asideLine2 = [[UILabel alloc] init];
        _asideLine2.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
        _asideLine2.textColor = [UIColor colorWithWhite:0.12 alpha:1.0];
        _asideLine2.numberOfLines = 1;
        UIStackView *asideStack = [[UIStackView alloc] initWithArrangedSubviews:@[ _asideLine1, _asideLine2 ]];
        asideStack.axis = UILayoutConstraintAxisVertical;
        asideStack.spacing = 2;
        _prompt = [[UILabel alloc] init];
        _prompt.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        _prompt.textColor = [UIColor colorWithWhite:0.12 alpha:1.0];
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
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(6, 0, 6, 0));
        }];
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
            make.centerY.equalTo(_bigNumber);
            make.trailing.lessThanOrEqualTo(_headerRow);
        }];
        [_prompt mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_headerRow.mas_bottom).offset(12);
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

- (void)configureWithModel:(PassportViewModel *)model {
    [self prepareForReuse];
    _bigNumber.text = [NSString stringWithFormat:@"%ld", (long)model.metricEmotionCount];
    _asideLine1.text = model.metricHeaderAsideLine1;
    _asideLine2.text = model.metricHeaderAsideLine2;
    _prompt.text = model.metricBarsPrompt;
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
    CGFloat labelColW = PCAbilityMaxLabelWidthForTitles(titles, labelFont);
    if (labelColW < 1) labelColW = 1;
    for (NSDictionary *item in items) {
        NSInteger val = [item[@"value"] integerValue];
        CGFloat ratio = (maxV > 0) ? (CGFloat)val / (CGFloat)maxV : 0;
        ratio = MIN(1, MAX(0, ratio));
        PCMetricEmotionRowView *row = [[PCMetricEmotionRowView alloc] initWithLabelColumnWidth:labelColW ratio:ratio];
        row.leftLabel.text = [NSString stringWithFormat:@"%@", item[@"title"] ?: @""];
        row.leftLabel.font = labelFont;
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
        _title.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
        _title.textColor = [UIColor colorWithWhite:0.12 alpha:1.0];
        _donut = [[PassportDonutChartView alloc] init];
        _donut.lineWidth = 40;
        _legend = [[UIStackView alloc] init];
        _legend.axis = UILayoutConstraintAxisVertical;
        _legend.spacing = 12;
        [_card addSubview:_title];
        [_card addSubview:_donut];
        [_card addSubview:_legend];
        [_card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(6, 0, 6, 0));
        }];
        [_title mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.leading.equalTo(_card).offset(16);
            make.trailing.equalTo(_card).offset(-16);
        }];
        [_donut mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_title.mas_bottom).offset(12);
            make.centerX.equalTo(_card);
            make.width.height.mas_equalTo(199);
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
    for (NSUInteger i = 0; i < legs.count; i++) {
        NSDictionary *leg = legs[i];
        double v = [vals[i] doubleValue];
        [ratios addObject:@(sum > 0 ? v / sum : 0)];
        [segColors addObject:PCHex([NSString stringWithFormat:@"%@", leg[@"h"] ?: @"000000"])];
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
