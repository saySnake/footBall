//
//  PassportChartViews.m
//  footBall
//

#import "PassportChartViews.h"
#import "FontManager.h"

@interface PassportBarChartView ()
@property (nonatomic, assign) CGSize lastBarLayoutSize;
@property (nonatomic, copy) NSArray<NSNumber *> *lastBarValues;
@property (nonatomic, strong) CAShapeLayer *gridLayer;
@property (nonatomic, strong) NSMutableArray<UIView *> *barViews;
@property (nonatomic, strong) NSMutableArray<UILabel *> *valueLabels;
@property (nonatomic, strong) NSMutableArray<UILabel *> *xLabels;
@property (nonatomic, strong) NSMutableArray<UILabel *> *yLabels;
@end

@implementation PassportBarChartView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        _barWidth = 20;
        _xTitles = @[ @"在聚会", @"在球场", @"在酒吧", @"在家里", @"在外面", @"在学校", @"在公司" ];
        _gridLayer = [CAShapeLayer layer];
        _gridLayer.fillColor = [UIColor clearColor].CGColor;
        _gridLayer.strokeColor = [[UIColor colorWithRed:0.70 green:0.73 blue:0.80 alpha:1.0] colorWithAlphaComponent:0.55].CGColor;
        _gridLayer.lineWidth = 1;
        _gridLayer.lineDashPattern = @[ @4, @6 ];
        [self.layer addSublayer:_gridLayer];
        _barViews = [NSMutableArray array];
        _valueLabels = [NSMutableArray array];
        _xLabels = [NSMutableArray array];
        _yLabels = [NSMutableArray array];
    }
    return self;
}

- (void)setValues:(NSArray<NSNumber *> *)values {
    _values = [values copy];
    self.lastBarLayoutSize = CGSizeZero;
    [self setNeedsLayout];
}

- (void)setMaxValue:(CGFloat)maxValue {
    if (fabs(_maxValue - maxValue) < 0.001) return;
    _maxValue = maxValue;
    self.lastBarLayoutSize = CGSizeZero;
    [self setNeedsLayout];
}

- (void)setXTitles:(NSArray<NSString *> *)xTitles {
    _xTitles = [xTitles copy];
    self.lastBarLayoutSize = CGSizeZero;
    [self setNeedsLayout];
}

- (void)setBarWidth:(CGFloat)barWidth {
    _barWidth = barWidth;
    self.lastBarLayoutSize = CGSizeZero;
    [self setNeedsLayout];
}

/// 数据峰值 → Y 轴上限：至少 10，并向上取整到 10 的倍数
+ (CGFloat)adaptiveMaxValueForValues:(NSArray<NSNumber *> *)values {
    CGFloat peak = 0;
    for (NSNumber *n in values) {
        if (![n isKindOfClass:NSNumber.class]) continue;
        peak = MAX(peak, n.doubleValue);
    }
    if (peak < 10) {
        peak = 10;
    }
    return ceil(peak / 10.0) * 10.0;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.bounds.size.width <= 0 || self.bounds.size.height <= 0) return;
    if (CGSizeEqualToSize(self.lastBarLayoutSize, self.bounds.size) &&
        [self.lastBarValues isEqualToArray:self.values ?: @[]]) {
        return;
    }
    self.lastBarLayoutSize = self.bounds.size;
    self.lastBarValues = [self.values copy];

    // 清理旧视图（保留 gridLayer）
    for (UIView *v in self.subviews) { [v removeFromSuperview]; }
    [self.barViews removeAllObjects];
    [self.valueLabels removeAllObjects];
    [self.xLabels removeAllObjects];
    [self.yLabels removeAllObjects];

    if (self.values.count == 0) {
        self.gridLayer.path = nil;
        return;
    }

    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    CGFloat maxV = self.maxValue > 0 ? self.maxValue : [PassportBarChartView adaptiveMaxValueForValues:self.values];
    UIColor *c = self.barColor ?: [UIColor colorWithRed:0.2 green:0.55 blue:0.45 alpha:1.0];

    // 预留坐标轴文字空间
    CGFloat leftAxisW = 28;
    CGFloat bottomAxisH = 22;
    CGFloat topValueH = 22;
    CGFloat plotX = leftAxisW;
    CGFloat plotY = topValueH;
    CGFloat plotW = MAX(1, w - leftAxisW);
    CGFloat plotH = MAX(1, h - topValueH - bottomAxisH);

    // y 轴刻度：0～maxV 均分 5 段（共 6 个刻度）
    NSMutableArray<NSNumber *> *yTicks = [NSMutableArray arrayWithCapacity:6];
    const NSInteger ySteps = 5;
    for (NSInteger i = 0; i <= ySteps; i++) {
        CGFloat v = maxV * ((CGFloat)i / (CGFloat)ySteps);
        [yTicks addObject:@(llround(v))];
    }
    for (NSNumber *t in yTicks) {
        UILabel *yl = [[UILabel alloc] init];
        yl.font = [UIFont systemFontOfSize:10];
        yl.textColor = [UIColor colorWithWhite:0.65 alpha:1.0];
        yl.textAlignment = NSTextAlignmentLeft;
        yl.text = [t stringValue];
        [self addSubview:yl];
        [self.yLabels addObject:yl];
    }

    // 网格线
    UIBezierPath *grid = [UIBezierPath bezierPath];
    for (NSNumber *t in yTicks) {
        CGFloat v = t.doubleValue;
        CGFloat yy = plotY + (1.0 - MIN(1, MAX(0, v / maxV))) * plotH;
        [grid moveToPoint:CGPointMake(plotX, yy)];
        [grid addLineToPoint:CGPointMake(plotX + plotW, yy)];
    }
    self.gridLayer.frame = self.bounds;
    self.gridLayer.path = grid.CGPath;

    // X 方向按绘图区宽度均分 n 列，每根柱子在该列内水平居中
    NSInteger n = (NSInteger)self.values.count;
    CGFloat segmentW = plotW / MAX((CGFloat)n, 1);
    CGFloat desiredBarW = (self.barWidth > 0 ? self.barWidth : 20);
    CGFloat barW = MIN(desiredBarW, segmentW * 0.72);

    // x 轴标题（系统 10）与柱顶数值（font18Regular）
    NSArray<NSString *> *titles = nil;
    if (self.xTitles.count == n) {
        titles = self.xTitles;
    } else if (n == 7) {
        titles = @[ @"在聚会", @"在球场", @"在酒吧", @"在家里", @"在外面", @"在学校", @"在公司" ];
    } else {
        NSMutableArray *tmp = [NSMutableArray array];
        for (NSInteger i = 0; i < n; i++) { [tmp addObject:@""]; }
        titles = tmp;
    }

    NSInteger highlightIndex = -1;
    CGFloat peak = 0;
    for (NSUInteger i = 0; i < self.values.count; i++) {
        CGFloat v = self.values[i].doubleValue;
        if (v > peak) {
            peak = v;
            highlightIndex = (NSInteger)i;
        }
    }

    for (NSUInteger i = 0; i < self.values.count; i++) {
        CGFloat v = self.values[i].doubleValue;
        CGFloat ratio = MIN(1, MAX(0, v / maxV));
        CGFloat bh = MAX(4, plotH * ratio);
        CGFloat colLeft = plotX + segmentW * i;
        CGFloat x = colLeft + (segmentW - barW) * 0.5;
        CGFloat y = plotY + plotH - bh;
        BOOL highlight = (peak > 0 && (NSInteger)i == highlightIndex);

        UIView *bar = [[UIView alloc] initWithFrame:CGRectMake(x, y, barW, bh)];
        bar.backgroundColor = c;
        bar.layer.cornerRadius = 3;
        bar.alpha = highlight ? 1.0 : 0.85;
        [self addSubview:bar];
        [self.barViews addObject:bar];

        UILabel *vl = [[UILabel alloc] initWithFrame:CGRectMake(colLeft, y - 22, segmentW, 22)];
        vl.font = FontManager.sharedManager.font18Regular;
        vl.textColor = highlight ? [UIColor blackColor] : [UIColor colorWithWhite:0.5 alpha:1.0];
        vl.textAlignment = NSTextAlignmentCenter;
        vl.text = [NSString stringWithFormat:@"%ld", (long)llround(v)];
        [self addSubview:vl];
        [self.valueLabels addObject:vl];

        UILabel *xl = [[UILabel alloc] initWithFrame:CGRectMake(colLeft, plotY + plotH + 8, segmentW, 14)];
        xl.font = [UIFont systemFontOfSize:10];
        xl.textColor = [UIColor colorWithWhite:0.55 alpha:1.0];
        xl.textAlignment = NSTextAlignmentCenter;
        xl.text = titles[i];
        [self addSubview:xl];
        [self.xLabels addObject:xl];
    }

    // 布局 y 轴文字
    for (NSUInteger i = 0; i < yTicks.count; i++) {
        CGFloat v = yTicks[i].doubleValue;
        CGFloat yy = plotY + (1.0 - MIN(1, MAX(0, v / maxV))) * plotH;
        UILabel *yl = self.yLabels[i];
        yl.frame = CGRectMake(0, yy - 7, leftAxisW - 6, 14);
    }
}

@end

@implementation PassportDonutChartView

/// 用“径向分割线”模拟扇区间隙：线宽就是 gapPt，因此从内到外宽度一致（不会出现外宽内窄的楔形间隙）。
static void PassportDonutStrokeRadialGap(CGContextRef _Nonnull ctx,
                                         CGPoint c,
                                         CGFloat rInner,
                                         CGFloat rOuter,
                                         CGFloat angle,
                                         CGFloat gapPt,
                                         CGColorRef _Nonnull color) {
    if (gapPt <= 0 || rOuter <= rInner) return;
    CGPoint p0 = CGPointMake(c.x + cos(angle) * rInner, c.y + sin(angle) * rInner);
    CGPoint p1 = CGPointMake(c.x + cos(angle) * rOuter, c.y + sin(angle) * rOuter);
    CGContextSaveGState(ctx);
    CGContextSetStrokeColorWithColor(ctx, color);
    CGContextSetLineWidth(ctx, gapPt);
    CGContextSetLineCap(ctx, kCGLineCapButt);
    CGContextMoveToPoint(ctx, p0.x, p0.y);
    CGContextAddLineToPoint(ctx, p1.x, p1.y);
    CGContextStrokePath(ctx);
    CGContextRestoreGState(ctx);
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        _lineWidth = 24;
        _ringInnerRadius = 0;
        _ringTrackExtraWidth = 0;
        _segmentGapPoints = 0;
        _showsOutsidePercentLabels = NO;
        _outsidePercentLabelColor = [UIColor whiteColor];
    }
    return self;
}

- (void)setRingTrackColor:(UIColor *)ringTrackColor {
    _ringTrackColor = ringTrackColor;
    [self setNeedsDisplay];
}

- (void)setRingTrackExtraWidth:(CGFloat)ringTrackExtraWidth {
    _ringTrackExtraWidth = ringTrackExtraWidth;
    [self setNeedsDisplay];
}

- (void)setSegmentGapPoints:(CGFloat)segmentGapPoints {
    _segmentGapPoints = segmentGapPoints;
    [self setNeedsDisplay];
}

- (void)setRingInnerRadius:(CGFloat)ringInnerRadius {
    _ringInnerRadius = ringInnerRadius;
    [self setNeedsDisplay];
}

- (void)setLineWidth:(CGFloat)lineWidth {
    _lineWidth = lineWidth;
    [self setNeedsDisplay];
}

- (void)setShowsOutsidePercentLabels:(BOOL)showsOutsidePercentLabels {
    _showsOutsidePercentLabels = showsOutsidePercentLabels;
    [self setNeedsDisplay];
}

- (void)setOutsidePercentLabelColor:(UIColor *)outsidePercentLabelColor {
    _outsidePercentLabelColor = outsidePercentLabelColor ?: [UIColor whiteColor];
    [self setNeedsDisplay];
}

- (void)setSegmentRatios:(NSArray<NSNumber *> *)segmentRatios {
    _segmentRatios = [segmentRatios copy];
    [self setNeedsDisplay];
}

- (void)setSegmentColors:(NSArray<UIColor *> *)segmentColors {
    _segmentColors = [segmentColors copy];
    [self setNeedsDisplay];
}

- (void)setCenterText:(NSString *)centerText {
    _centerText = [centerText copy];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGPoint c = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    CGFloat half = MIN(rect.size.width, rect.size.height) * 0.5f;
    CGFloat lw = self.lineWidth;
    // 如果需要画“环外百分比+引导线”，必须给外侧留出空间，否则文字容易被 view 裁切或与折线重叠。
    CGFloat outsideReserve = self.showsOutsidePercentLabels ? 56.0f : 0.0f;
    CGFloat trackStroke = lw;
    if (self.ringTrackColor && self.ringTrackExtraWidth > 0) {
        // 轨道底色可以比彩色环更粗（视觉上像托底），所以半径计算要按更粗的 trackStroke 预留。
        trackStroke = lw + self.ringTrackExtraWidth;
    }
    CGFloat r;
    if (self.ringInnerRadius > 0) {
        // ringInnerRadius 表示“内孔半径”；圆弧是 stroke 画的，中心线半径 = inner + lw/2
        r = self.ringInnerRadius + lw * 0.5f;
    } else {
        // 自动适配：用内切圆半径 half，减去 stroke 外扩的 1/2，再减去环外 label 的预留。
        r = half - trackStroke * 0.5f - outsideReserve;
        if (r < 8.0f) r = 8.0f;
    }
    // 彩色环的内/外边界半径（用于间隙填充的“带状区域”）
    CGFloat rInnerStroke = r - lw * 0.5f;
    CGFloat rOuterStroke = r + lw * 0.5f;
    // 从 12 点方向开始绘制，更符合常见环图习惯（iOS 0 在 3 点方向）
    CGFloat start = -M_PI_2;
    if (self.segmentRatios.count > 0 && self.segmentColors.count == self.segmentRatios.count) {
        if (self.ringTrackColor) {
            // 先画整圈底色轨道（track），再在其上画彩色分段和间隙
            UIBezierPath *baseTrack = [UIBezierPath bezierPathWithArcCenter:c radius:r startAngle:0 endAngle:(CGFloat)(2 * M_PI) clockwise:YES];
            [self.ringTrackColor setStroke];
            baseTrack.lineWidth = trackStroke;
            baseTrack.lineCapStyle = kCGLineCapButt;
            [baseTrack stroke];
        }
        NSUInteger n = self.segmentRatios.count;
        CGFloat gapPt = MAX(0, self.segmentGapPoints);

        // 1) 先把 ratios 归一到整圈（保证所有段拼成 360°，便于“分割线”稳定落在每个边界）
        double sum = 0.0;
        for (NSNumber *v in self.segmentRatios) { sum += MAX(0.0, v.doubleValue); }
        if (sum <= 0.0) sum = 1.0;

        // 2) 画彩色圆弧，并记录每段结束角（用于画分割线）
        // 注意：分割线要画在“段与段的边界”上；对于 n 段，一共有 n 条边界线：
        // - 起始角 start0（最后一段与第一段的分界）
        // - 以及前 n-1 段的结束角（第 i 段与第 i+1 段的分界）
        // 最后一段结束角理论上等于 start0 + 2π，与起始角重合，不再重复画。
        CGFloat start0 = start;
        NSMutableArray<NSNumber *> *endAngles = [NSMutableArray arrayWithCapacity:n];
        for (NSUInteger i = 0; i < n; i++) {
            CGFloat t = MAX(0.0, self.segmentRatios[i].doubleValue);
            CGFloat sweep = (CGFloat)((t / sum) * (2.0 * M_PI));
            UIBezierPath *p = [UIBezierPath bezierPathWithArcCenter:c radius:r startAngle:start endAngle:start + sweep clockwise:YES];
            [self.segmentColors[i] setStroke];
            p.lineWidth = lw;
            p.lineCapStyle = kCGLineCapButt;
            [p stroke];
            start += sweep;
            [endAngles addObject:@(start)];
        }

        // 3) 在每个边界角画一条“径向分割线”作为间隙（线宽=gapPt，内外视觉宽度一致）
        if (gapPt > 0 && rInnerStroke > 1.0f && rOuterStroke > rInnerStroke + 0.5f) {
            UIColor *gapColor = self.ringTrackColor ?: [UIColor colorWithWhite:0.9 alpha:1];
            // 先画起始边界（最后一段与第一段的分界）
            PassportDonutStrokeRadialGap(ctx, c, rInnerStroke, rOuterStroke, start0, gapPt, gapColor.CGColor);
            // 再画前 n-1 段的结束边界
            for (NSUInteger i = 0; i + 1 < endAngles.count; i++) {
                CGFloat a = endAngles[i].doubleValue;
                PassportDonutStrokeRadialGap(ctx, c, rInnerStroke, rOuterStroke, a, gapPt, gapColor.CGColor);
            }
        }
    } else {
        // 数据不足时的兜底：画一圈浅灰（或 track）
        UIBezierPath *track = [UIBezierPath bezierPathWithArcCenter:c radius:r startAngle:0 endAngle:(CGFloat)(2 * M_PI) clockwise:YES];
        [[UIColor colorWithWhite:0.9 alpha:1] setStroke];
        track.lineWidth = self.ringTrackColor ? trackStroke : lw;
        [track stroke];
    }
    if (self.showsOutsidePercentLabels && self.segmentRatios.count > 0 && self.segmentColors.count == self.segmentRatios.count) {
        UIFont *pf = [UIFont systemFontOfSize:24 weight:UIFontWeightBold];
        UIColor *tc = self.outsidePercentLabelColor ?: [UIColor whiteColor];
        NSDictionary *attrs = @{ NSFontAttributeName: pf, NSForegroundColorAttributeName: tc };
        CGFloat rOuter = r + lw * 0.5f;
        NSUInteger n = self.segmentRatios.count;
        CGFloat gapPt = MAX(0, self.segmentGapPoints);
        CGFloat gapAngle = (r > 1.0f && gapPt > 0) ? (gapPt / r) : 0;
        CGFloat totalGapAngle = gapAngle * (CGFloat)n;
        CGFloat availableAngle = (CGFloat)(2 * M_PI) - totalGapAngle;
        if (availableAngle < 0.01f) {
            availableAngle = (CGFloat)(2 * M_PI);
            gapAngle = 0;
        }
        start = -M_PI_2;
        for (NSUInteger i = 0; i < self.segmentRatios.count; i++) {
            CGFloat t = self.segmentRatios[i].doubleValue;
            CGFloat sweep = t * availableAngle;
            CGFloat mid = start + sweep * 0.5f;
            NSString *pct = [NSString stringWithFormat:@"%.0f%%", t * 100];
            CGSize textSize = [pct boundingRectWithSize:CGSizeMake(200, 40)
                                                 options:NSStringDrawingUsesLineFragmentOrigin
                                              attributes:attrs
                                                 context:nil].size;
            textSize.width = ceil(textSize.width);
            textSize.height = ceil(textSize.height);
            // 常见 labelLine：圆环外缘 tip → 径向第一段到 p1 → 水平第二段接到文字边缘（不画竖线）。
            // 注意：文字框 tr 最终会被屏幕边界夹紧，所以“线连哪一边”不能只用 cos(mid) 判断，
            // 必须在 tr 最终确定后，按 tr 相对 p1 的实际位置决定连接到文字左缘/右缘。
            CGFloat L1 = 26.0f;
            CGPoint tip = CGPointMake(c.x + cos(mid) * rOuter, c.y + sin(mid) * rOuter);
            CGPoint p1 = CGPointMake(c.x + cos(mid) * (rOuter + L1), c.y + sin(mid) * (rOuter + L1));
            CGFloat hy = p1.y;
            BOOL preferRight = cos(mid) >= 0.0;
            CGFloat edgePad = 12.0f;
            CGFloat horizGap = 16.0f;
            CGFloat minX = 2.0f;
            CGFloat maxX = CGRectGetWidth(rect) - 2.0f;
            CGRect tr;
            if (preferRight) {
                CGFloat tx = MAX(p1.x + horizGap, c.x + rOuter + L1 + 14.0f);
                tx = MIN(tx, maxX - textSize.width);
                tr = CGRectMake(tx, hy - textSize.height * 0.5f, textSize.width, textSize.height);
            } else {
                CGFloat tx = p1.x - horizGap - textSize.width;
                tx = MAX(tx, minX);
                tr = CGRectMake(tx, hy - textSize.height * 0.5f, textSize.width, textSize.height);
            }
            CGFloat inset = 2.0f;
            if (CGRectGetMinY(tr) < inset) {
                tr.origin.y = inset;
            }
            if (CGRectGetMaxY(tr) > CGRectGetHeight(rect) - inset) {
                tr.origin.y = CGRectGetHeight(rect) - inset - textSize.height;
            }
            // 计算水平折线段终点 pEndX：
            // 需求：左侧文字应连接到文字 rect 的 maxX；右侧文字应连接到文字 rect 的 minX。
            // 这里“左/右侧”按文字框 tr 相对拐点 p1 的实际位置判断（tr 会被屏幕边界夹紧，所以不能只看 cos(mid)）。
            CGFloat tl = CGRectGetMinX(tr);
            CGFloat tright = CGRectGetMaxX(tr);
            CGFloat pEndX;
            const CGFloat lineJoinSlop = 2.0f;
            if (tl >= p1.x - 0.5f) {
                // 文字在拐点右侧：连接到文字左边缘（rect minX）
                pEndX = tl;
                if (pEndX <= p1.x + lineJoinSlop) {
                    pEndX = p1.x + lineJoinSlop;
                }
            } else if (tright <= p1.x + 0.5f) {
                // 文字在拐点左侧：连接到文字右边缘（rect maxX）
                pEndX = tright;
                if (pEndX >= p1.x - lineJoinSlop) {
                    pEndX = p1.x - lineJoinSlop;
                }
            } else {
                // 文字跨过拐点：连接到离 p1 更近的那条边（仍遵循 minX/maxX 规则）
                if (fabs(tl - p1.x) < fabs(tright - p1.x)) {
                    pEndX = tl;
                    if (pEndX <= p1.x + lineJoinSlop) {
                        pEndX = p1.x + lineJoinSlop;
                    }
                } else {
                    pEndX = tright;
                    if (pEndX >= p1.x - lineJoinSlop) {
                        pEndX = p1.x - lineJoinSlop;
                    }
                }
            }
            CGContextSaveGState(ctx);
            CGContextSetStrokeColorWithColor(ctx, [[UIColor colorWithHexString:@"#CCFFDC"] CGColor]);
            CGContextSetLineWidth(ctx, 2);
            CGContextMoveToPoint(ctx, tip.x, tip.y);
            CGContextAddLineToPoint(ctx, p1.x, p1.y);
            CGContextAddLineToPoint(ctx, pEndX, hy);
            CGContextStrokePath(ctx);
            CGContextRestoreGState(ctx);
            [pct drawInRect:tr withAttributes:attrs];
            start += sweep;
            if (gapAngle > 0) {
                start += gapAngle;
            }
        }
    }
    if (self.centerText.length) {
        // 圆心数字（如“85%”等）直接居中绘制；宽度按 view 裁剪留一点边距
        NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
        ps.alignment = NSTextAlignmentCenter;
        NSDictionary *attr = @{
            NSFontAttributeName: FontManager.sharedManager.font40Regular,
            NSForegroundColorAttributeName: [UIColor colorWithWhite:0.15 alpha:1],
            NSParagraphStyleAttributeName: ps
        };
        CGSize sz = [self.centerText boundingRectWithSize:CGSizeMake(rect.size.width - 8, 80) options:NSStringDrawingUsesLineFragmentOrigin attributes:attr context:nil].size;
        [self.centerText drawInRect:CGRectMake(4, CGRectGetMidY(rect) - sz.height * 0.5f, rect.size.width - 8, sz.height) withAttributes:attr];
    }
}

@end
