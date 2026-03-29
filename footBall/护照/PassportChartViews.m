//
//  PassportChartViews.m
//  footBall
//

#import "PassportChartViews.h"

@interface PassportBarChartView ()
@property (nonatomic, assign) CGSize lastBarLayoutSize;
@property (nonatomic, copy) NSArray<NSNumber *> *lastBarValues;
@end

@implementation PassportBarChartView

- (void)setValues:(NSArray<NSNumber *> *)values {
    _values = [values copy];
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

    for (UIView *v in self.subviews) { [v removeFromSuperview]; }
    if (self.values.count == 0) return;
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    CGFloat gap = 6;
    CGFloat barW = (w - gap * (self.values.count - 1)) / MAX((CGFloat)self.values.count, 1);
    CGFloat maxV = self.maxValue > 0 ? self.maxValue : 10;
    UIColor *c = self.barColor ?: [UIColor colorWithRed:0.2 green:0.55 blue:0.45 alpha:1.0];
    for (NSUInteger i = 0; i < self.values.count; i++) {
        CGFloat v = self.values[i].doubleValue;
        CGFloat ratio = MIN(1, MAX(0, v / maxV));
        CGFloat bh = MAX(4, h * ratio);
        UIView *bar = [[UIView alloc] initWithFrame:CGRectMake(i * (barW + gap), h - bh, barW, bh)];
        bar.backgroundColor = c;
        bar.layer.cornerRadius = 3;
        bar.alpha = 0.5 + 0.5 * ratio;
        [self addSubview:bar];
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
