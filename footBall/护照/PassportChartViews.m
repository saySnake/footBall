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
        _xTitles = @[ @"在现场", @"在酒吧", @"在球场", @"在家里", @"在外面", @"在学校", @"在公司" ];
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
    [self setNeedsLayout];
}

- (void)setXTitles:(NSArray<NSString *> *)xTitles {
    _xTitles = [xTitles copy];
    [self setNeedsLayout];
}

- (void)setBarWidth:(CGFloat)barWidth {
    _barWidth = barWidth;
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.bounds.size.width <= 0 || self.bounds.size.height <= 0) return;
    if (CGSizeEqualToSize(self.lastBarLayoutSize, self.bounds.size) &&
        [self.lastBarValues isEqualToArray:self.values]) {
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
    CGFloat maxV = self.maxValue > 0 ? self.maxValue : 100;
    UIColor *c = self.barColor ?: [UIColor colorWithRed:0.2 green:0.55 blue:0.45 alpha:1.0];

    // 预留坐标轴文字空间
    CGFloat leftAxisW = 28;
    CGFloat bottomAxisH = 22;
    CGFloat topValueH = 22;
    CGFloat plotX = leftAxisW;
    CGFloat plotY = topValueH;
    CGFloat plotW = MAX(1, w - leftAxisW);
    CGFloat plotH = MAX(1, h - topValueH - bottomAxisH);

    // y 轴刻度（系统 10）
    // 设计稿：0～100，按 20 等分
    NSArray<NSNumber *> *yTicks = @[ @0, @20, @40, @60, @80, @100 ];
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
        titles = @[ @"在现场", @"在酒吧", @"在球场", @"在家里", @"在外面", @"在学校", @"在公司" ];
    } else {
        NSMutableArray *tmp = [NSMutableArray array];
        for (NSInteger i = 0; i < n; i++) { [tmp addObject:@""]; }
        titles = tmp;
    }

    for (NSUInteger i = 0; i < self.values.count; i++) {
        CGFloat v = self.values[i].doubleValue;
        CGFloat ratio = MIN(1, MAX(0, v / maxV));
        CGFloat bh = MAX(4, plotH * ratio);
        CGFloat colLeft = plotX + segmentW * i;
        CGFloat x = colLeft + (segmentW - barW) * 0.5;
        CGFloat y = plotY + plotH - bh;

        UIView *bar = [[UIView alloc] initWithFrame:CGRectMake(x, y, barW, bh)];
        bar.backgroundColor = c;
        bar.layer.cornerRadius = 3;
        bar.alpha = (i == 3 ? 1.0 : 0.85); // 让第 4 根更亮，接近设计稿强调
        [self addSubview:bar];
        [self.barViews addObject:bar];

        UILabel *vl = [[UILabel alloc] initWithFrame:CGRectMake(colLeft, y - 22, segmentW, 22)];
        vl.font = FontManager.sharedManager.font18Regular;
        vl.textColor = (i == 3 ? [UIColor blackColor] : [UIColor colorWithWhite:0.5 alpha:1.0]);
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
    CGFloat outsideReserve = self.showsOutsidePercentLabels ? 36.0f : 0.0f;
    CGFloat trackStroke = lw;
    if (self.ringTrackColor && self.ringTrackExtraWidth > 0) {
        trackStroke = lw + self.ringTrackExtraWidth;
    }
    CGFloat r;
    if (self.ringInnerRadius > 0) {
        r = self.ringInnerRadius + lw * 0.5f;
    } else {
        r = half - trackStroke * 0.5f - outsideReserve;
        if (r < 8.0f) r = 8.0f;
    }
    CGFloat start = -M_PI_2;
    if (self.segmentRatios.count > 0 && self.segmentColors.count == self.segmentRatios.count) {
        if (self.ringTrackColor) {
            UIBezierPath *baseTrack = [UIBezierPath bezierPathWithArcCenter:c radius:r startAngle:0 endAngle:(CGFloat)(2 * M_PI) clockwise:YES];
            [self.ringTrackColor setStroke];
            baseTrack.lineWidth = trackStroke;
            baseTrack.lineCapStyle = kCGLineCapButt;
            [baseTrack stroke];
        }
        NSUInteger n = self.segmentRatios.count;
        CGFloat gapPt = MAX(0, self.segmentGapPoints);
        CGFloat gapAngle = (r > 1.0f && gapPt > 0) ? (gapPt / r) : 0;
        CGFloat totalGapAngle = gapAngle * (CGFloat)n;
        CGFloat availableAngle = (CGFloat)(2 * M_PI) - totalGapAngle;
        if (availableAngle < 0.01f) {
            availableAngle = (CGFloat)(2 * M_PI);
            gapAngle = 0;
        }
        for (NSUInteger i = 0; i < n; i++) {
            CGFloat t = self.segmentRatios[i].doubleValue;
            CGFloat sweep = t * availableAngle;
            UIBezierPath *p = [UIBezierPath bezierPathWithArcCenter:c radius:r startAngle:start endAngle:start + sweep clockwise:YES];
            [self.segmentColors[i] setStroke];
            p.lineWidth = lw;
            p.lineCapStyle = kCGLineCapButt;
            [p stroke];
            start += sweep;
            if (gapAngle > 0) {
                start += gapAngle;
            }
        }
    } else {
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
            // Web 扇形图常见 labelLine：圆环外缘 → 径向第一段 → 水平第二段接到文字边缘（无竖线）
            CGFloat L1 = 20.0f;
            CGPoint tip = CGPointMake(c.x + cos(mid) * rOuter, c.y + sin(mid) * rOuter);
            CGPoint p1 = CGPointMake(c.x + cos(mid) * (rOuter + L1), c.y + sin(mid) * (rOuter + L1));
            CGFloat hy = p1.y;
            BOOL rightSide = cos(mid) >= 0.0;
            CGFloat edgePad = 4.0f;
            CGFloat horizGap = 10.0f;
            CGFloat minX = 2.0f;
            CGFloat maxX = CGRectGetWidth(rect) - 2.0f;
            CGRect tr;
            CGFloat pEndX = p1.x;
            if (rightSide) {
                CGFloat tx = MAX(p1.x + horizGap, c.x + rOuter + L1 + 6.0f);
                tx = MIN(tx, maxX - textSize.width);
                tr = CGRectMake(tx, hy - textSize.height * 0.5f, textSize.width, textSize.height);
                pEndX = CGRectGetMinX(tr) - edgePad;
                if (pEndX <= p1.x) {
                    pEndX = p1.x + 2.0f;
                }
            } else {
                CGFloat tx = p1.x - horizGap - textSize.width;
                tx = MAX(tx, minX);
                tr = CGRectMake(tx, hy - textSize.height * 0.5f, textSize.width, textSize.height);
                pEndX = CGRectGetMaxX(tr) + edgePad;
                if (pEndX >= p1.x) {
                    pEndX = p1.x - 2.0f;
                }
            }
            CGFloat inset = 2.0f;
            if (CGRectGetMinY(tr) < inset) {
                tr.origin.y = inset;
            }
            if (CGRectGetMaxY(tr) > CGRectGetHeight(rect) - inset) {
                tr.origin.y = CGRectGetHeight(rect) - inset - textSize.height;
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
