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

    // 柱宽固定 20；居中分布
    CGFloat barW = (self.barWidth > 0 ? self.barWidth : 20);
    NSInteger n = (NSInteger)self.values.count;
    CGFloat gap = 6;
    CGFloat totalW = n * barW + (n - 1) * gap;
    if (totalW > plotW) {
        gap = MAX(2, (plotW - n * barW) / MAX(n - 1, 1));
        totalW = n * barW + (n - 1) * gap;
    }
    CGFloat startX = plotX + (plotW - totalW) * 0.5;

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
        CGFloat x = startX + i * (barW + gap);
        CGFloat y = plotY + plotH - bh;

        UIView *bar = [[UIView alloc] initWithFrame:CGRectMake(x, y, barW, bh)];
        bar.backgroundColor = c;
        bar.layer.cornerRadius = 3;
        bar.alpha = (i == 3 ? 1.0 : 0.85); // 让第 4 根更亮，接近设计稿强调
        [self addSubview:bar];
        [self.barViews addObject:bar];

        UILabel *vl = [[UILabel alloc] initWithFrame:CGRectMake(x - 12, y - 22, barW + 24, 22)];
        vl.font = FontManager.sharedManager.font18Regular;
        vl.textColor = (i == 3 ? [UIColor blackColor] : [UIColor colorWithWhite:0.5 alpha:1.0]);
        vl.textAlignment = NSTextAlignmentCenter;
        vl.text = [NSString stringWithFormat:@"%ld", (long)llround(v)];
        [self addSubview:vl];
        [self.valueLabels addObject:vl];

        UILabel *xl = [[UILabel alloc] initWithFrame:CGRectMake(x - 24, plotY + plotH + 8, barW + 48, 14)];
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
        _lineWidth = 18;
    }
    return self;
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
    CGFloat r = MIN(rect.size.width, rect.size.height) * 0.5f - self.lineWidth * 0.5f;
    CGFloat lw = self.lineWidth;
    CGFloat start = -M_PI_2;
    if (self.segmentRatios.count > 0 && self.segmentColors.count == self.segmentRatios.count) {
        for (NSUInteger i = 0; i < self.segmentRatios.count; i++) {
            CGFloat t = self.segmentRatios[i].doubleValue;
            CGFloat sweep = (CGFloat)(2 * M_PI * t);
            UIBezierPath *p = [UIBezierPath bezierPathWithArcCenter:c radius:r startAngle:start endAngle:start + sweep clockwise:YES];
            [self.segmentColors[i] setStroke];
            p.lineWidth = lw;
            p.lineCapStyle = kCGLineCapButt;
            [p stroke];
            start += sweep;
        }
    } else {
        UIBezierPath *track = [UIBezierPath bezierPathWithArcCenter:c radius:r startAngle:0 endAngle:(CGFloat)(2 * M_PI) clockwise:YES];
        [[UIColor colorWithWhite:0.9 alpha:1] setStroke];
        track.lineWidth = lw;
        [track stroke];
    }
    if (self.centerText.length) {
        NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
        ps.alignment = NSTextAlignmentCenter;
        NSDictionary *attr = @{
            NSFontAttributeName: [UIFont systemFontOfSize:18 weight:UIFontWeightBold],
            NSForegroundColorAttributeName: [UIColor colorWithWhite:0.15 alpha:1],
            NSParagraphStyleAttributeName: ps
        };
        CGSize sz = [self.centerText boundingRectWithSize:CGSizeMake(rect.size.width - 8, 80) options:NSStringDrawingUsesLineFragmentOrigin attributes:attr context:nil].size;
        [self.centerText drawInRect:CGRectMake(4, CGRectGetMidY(rect) - sz.height * 0.5f, rect.size.width - 8, sz.height) withAttributes:attr];
    }
}

@end
