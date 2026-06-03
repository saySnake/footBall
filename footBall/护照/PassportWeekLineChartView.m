//
//  PassportWeekLineChartView.m
//  footBall
//

#import "PassportWeekLineChartView.h"

static inline CGFloat PassportClampCGFloat(CGFloat x, CGFloat lo, CGFloat hi) {
    return MAX(lo, MIN(hi, x));
}

static UIBezierPath *PassportSmoothLineThroughPoints(CGPoint *pts, NSInteger count) {
    if (count < 2) return nil;
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:pts[0]];
    if (count == 2) {
        [path addLineToPoint:pts[1]];
        return path;
    }
    for (NSInteger i = 0; i < count - 1; i++) {
        CGPoint p0 = (i > 0) ? pts[i - 1] : pts[i];
        CGPoint p1 = pts[i];
        CGPoint p2 = pts[i + 1];
        CGPoint p3 = (i + 2 < count) ? pts[i + 2] : pts[i + 1];
        CGPoint cp1 = CGPointMake(p1.x + (p2.x - p0.x) / 6.0, p1.y + (p2.y - p0.y) / 6.0);
        CGPoint cp2 = CGPointMake(p2.x - (p3.x - p1.x) / 6.0, p2.y - (p3.y - p1.y) / 6.0);
        [path addCurveToPoint:p2 controlPoint1:cp1 controlPoint2:cp2];
    }
    return path;
}

@interface PassportWeekLineChartView ()
@property (nonatomic, strong) NSArray<UILabel *> *xLabels;
@property (nonatomic, strong) UIView *plotContainer;
@property (nonatomic, strong) CAShapeLayer *gridLayer;
@property (nonatomic, strong) CAShapeLayer *lineLayer;
@end

@implementation PassportWeekLineChartView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor colorWithHexString:@"#1C1D19"];
        self.layer.cornerRadius = 20;
        self.clipsToBounds = YES;

        _lineColor = [UIColor colorWithHexString:@"#56DBA6"];
        _gridColor = [[UIColor whiteColor] colorWithAlphaComponent:0.12];

        _plotContainer = [[UIView alloc] init];
        _plotContainer.backgroundColor = [UIColor clearColor];
        [self addSubview:_plotContainer];

        _gridLayer = [CAShapeLayer layer];
        _gridLayer.fillColor = [UIColor clearColor].CGColor;
        _gridLayer.strokeColor = _gridColor.CGColor;
        _gridLayer.lineWidth = 0.5;
        [_plotContainer.layer addSublayer:_gridLayer];

        _lineLayer = [CAShapeLayer layer];
        _lineLayer.fillColor = [UIColor clearColor].CGColor;
        _lineLayer.strokeColor = _lineColor.CGColor;
        _lineLayer.lineWidth = 3.5;
        _lineLayer.lineCap = kCALineCapRound;
        _lineLayer.lineJoin = kCALineJoinRound;
        [_plotContainer.layer addSublayer:_lineLayer];

        NSArray *xTitles = @[ @"日", @"一", @"二", @"三", @"四", @"五", @"六" ];
        NSMutableArray *xs = [NSMutableArray array];
        for (NSString *t in xTitles) {
            UILabel *l = [[UILabel alloc] init];
            l.text = t;
            l.font = [UIFont systemFontOfSize:9];
            l.textColor = [UIColor whiteColor];
            l.textAlignment = NSTextAlignmentCenter;
            [self addSubview:l];
            [xs addObject:l];
        }
        self.xLabels = xs;

        _weekValues = @[ @15, @32, @48, @75, @38, @62, @28 ];
    }
    return self;
}

- (void)setLineColor:(UIColor *)lineColor {
    _lineColor = lineColor;
    _lineLayer.strokeColor = lineColor.CGColor;
}

- (void)setGridColor:(UIColor *)gridColor {
    _gridColor = gridColor;
    _gridLayer.strokeColor = gridColor.CGColor;
}

- (void)setWeekValues:(NSArray<NSNumber *> *)weekValues {
    if (weekValues.count != 7) return;
    _weekValues = [weekValues copy];
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat W = CGRectGetWidth(self.bounds);
    CGFloat H = CGRectGetHeight(self.bounds);
    CGFloat leftInset = 8;
    CGFloat rightInset = 8;
    CGFloat bottomH = 20;
    CGFloat topPad = 15;
    CGFloat bottomInset = 5;

    CGFloat plotW = W - leftInset - rightInset;
    CGFloat plotH = H - topPad - bottomInset - bottomH;

    CGRect plotFrame = CGRectMake(leftInset, topPad, plotW, plotH);
    self.plotContainer.frame = plotFrame;

    CGFloat colW = plotW / 7.0;
    for (NSUInteger i = 0; i < self.xLabels.count; i++) {
        UILabel *l = self.xLabels[i];
        l.frame = CGRectMake(leftInset + i * colW, H - bottomInset - bottomH, colW, bottomH);
    }

    [self updatePlotLayersInRect:CGRectMake(0, 0, plotW, plotH)];
}

- (void)updatePlotLayersInRect:(CGRect)plotBounds {
    UIBezierPath *grid = [UIBezierPath bezierPath];

    NSArray *yVals = @[ @100, @80, @50, @20, @0 ];
    for (NSNumber *nv in yVals) {
        CGFloat v = nv.doubleValue;
        CGFloat y = (1.0 - v / 100.0) * plotBounds.size.height;
        [grid moveToPoint:CGPointMake(0, y)];
        [grid addLineToPoint:CGPointMake(plotBounds.size.width, y)];
    }

    CGFloat colW = plotBounds.size.width / 7.0;
    for (NSInteger i = 0; i <= 7; i++) {
        CGFloat x = i * colW;
        [grid moveToPoint:CGPointMake(x, 0)];
        [grid addLineToPoint:CGPointMake(x, plotBounds.size.height)];
    }
    self.gridLayer.frame = plotBounds;
    self.gridLayer.path = grid.CGPath;

    NSMutableArray<NSNumber *> *vals = [self.weekValues mutableCopy];
    if (vals.count != 7) {
        vals = [@[ @15, @32, @48, @75, @38, @62, @28 ] mutableCopy];
    }
    CGPoint pts[7];
    for (NSInteger i = 0; i < 7; i++) {
        CGFloat v = PassportClampCGFloat(vals[i].doubleValue, 0, 100);
        CGFloat x = (i + 0.5) * colW;
        CGFloat y = (1.0 - v / 100.0) * plotBounds.size.height;
        pts[i] = CGPointMake(x, y);
    }

    UIBezierPath *line = PassportSmoothLineThroughPoints(pts, 7);
    self.lineLayer.frame = plotBounds;
    self.lineLayer.path = line.CGPath;
}

@end
