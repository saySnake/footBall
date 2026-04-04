//
//  StampDashView.m
//  footBall
//

#import "StampDashView.h"

@implementation StampDashView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.backgroundColor = [UIColor clearColor];
    self.opaque = NO;
    _stampColor = [UIColor colorWithHexString:@"#DBDBDB"];
    _capsuleHeightFactor = 0.88;
    _capsuleAspect = 2.25;
    _gapToWidthRatio = 1.0;
}

- (void)setStampColor:(UIColor *)stampColor {
    _stampColor = stampColor ?: [UIColor colorWithHexString:@"#DBDBDB"];
    [self setNeedsDisplay];
}

- (void)setCapsuleHeightFactor:(CGFloat)capsuleHeightFactor {
    _capsuleHeightFactor = MAX(0.1, MIN(1.0, capsuleHeightFactor));
    [self setNeedsDisplay];
}

- (void)setCapsuleAspect:(CGFloat)capsuleAspect {
    _capsuleAspect = MAX(1.2, MIN(3.0, capsuleAspect));
    [self setNeedsDisplay];
}

- (void)setGapToWidthRatio:(CGFloat)gapToWidthRatio {
    _gapToWidthRatio = MAX(0.0, gapToWidthRatio);
    [self setNeedsDisplay];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    CGFloat W = CGRectGetWidth(rect);
    CGFloat H = CGRectGetHeight(rect);
    if (W < 0.5 || H < 0.5) {
        return;
    }

    CGFloat capsuleH = H * self.capsuleHeightFactor;
    CGFloat aspect = self.capsuleAspect;
    CGFloat capsuleW = capsuleH / aspect;
    CGFloat gap = capsuleW * self.gapToWidthRatio;
    CGFloat step = capsuleW + gap;
    if (step < 0.5) {
        return;
    }

    NSInteger n = (NSInteger)floor((W + gap + 0.001) / step);
    if (n < 1) {
        capsuleW = MIN(W * 0.35, capsuleW);
        capsuleH = capsuleW * aspect;
        if (capsuleH > H * 0.95) {
            capsuleH = H * 0.95;
            capsuleW = capsuleH / aspect;
        }
        gap = capsuleW * self.gapToWidthRatio;
        step = capsuleW + gap;
        n = (NSInteger)floor((W + gap + 0.001) / step);
        if (n < 1) {
            n = 1;
        }
    }

    CGFloat totalW = (CGFloat)n * capsuleW + (CGFloat)MAX(0, n - 1) * gap;
    CGFloat startX = floor((W - totalW) * 0.5);
    CGFloat y = floor((H - capsuleH) * 0.5);

    UIBezierPath *path = [UIBezierPath bezierPath];
    CGFloat corner = capsuleW * 0.5;
    for (NSInteger i = 0; i < n; i++) {
        CGFloat x = startX + (CGFloat)i * step;
        CGRect r = CGRectMake(x, y, capsuleW, capsuleH);
        UIBezierPath *pill = [UIBezierPath bezierPathWithRoundedRect:r cornerRadius:corner];
        [path appendPath:pill];
    }

    [self.stampColor setFill];
    [path fill];
}

@end
