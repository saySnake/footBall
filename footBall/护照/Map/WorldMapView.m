#import "WorldMapView.h"
#import <Masonry/Masonry.h>

/// 与 GeoJSON `properties.name`、业务侧中文国名对齐：去空白（含全角空格）、兼容预组合
static NSString *WMNormalizeCountryLabel(NSString *s) {
    if (![s isKindOfClass:[NSString class]] || s.length == 0) {
        return @"";
    }
    NSMutableCharacterSet *ws = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    [ws addCharactersInString:@"\u3000"];
    NSString *t = [s stringByTrimmingCharactersInSet:ws];
    if (t.length == 0) {
        return @"";
    }
    return [t precomposedStringWithCompatibilityMapping];
}

static BOOL WMStringLooksLikeISOAlpha2(NSString *s) {
    if (s.length != 2) {
        return NO;
    }
    unichar c0 = [s characterAtIndex:0];
    unichar c1 = [s characterAtIndex:1];
    BOOL a = (c0 >= 'A' && c0 <= 'Z') || (c0 >= 'a' && c0 <= 'z');
    BOOL b = (c1 >= 'A' && c1 <= 'Z') || (c1 >= 'a' && c1 <= 'z');
    return a && b;
}

@interface WorldMapView ()
@property (nonatomic, strong) UIView *visitLegendContainer;
@property (nonatomic, strong) CALayer *contentLayer;                 // 所有国家的容器
@property (nonatomic, strong) NSMutableArray<CAShapeLayer *> *countryLayers;
/// 与 countryLayers 顺序一一对应，来自 GeoJSON properties.iso（大写）
@property (nonatomic, strong) NSMutableArray<NSString *> *countryISOs;
/// 与 countryLayers 顺序一一对应，来自 GeoJSON properties.name（中文常用名）
@property (nonatomic, strong) NSMutableArray<NSString *> *countryZhNames;
/// 已解析的 GeoJSON，等布局出有效 bounds 后再 build（避免首次 load 时 bounds 为 0 画不出）
@property (nonatomic, strong, nullable) NSDictionary *geoJSONData;
@property (nonatomic, assign) CGSize lastBuiltBoundsSize;
/// 异步加载代数，避免重复 load / 页面销毁后回调写回旧数据
@property (nonatomic, assign) NSInteger geoJSONLoadGeneration;

@property (nonatomic, assign) CGFloat currentScale;
@property (nonatomic, assign) CGPoint currentTranslation;            // 以 view 坐标为基准的平移

@property (nonatomic, assign) CGPoint panStartTranslation;
@property (nonatomic, assign) CGPoint pinchAnchorInView;             // pinch 开始时锚点（view 坐标）
@property (nonatomic, assign) CGFloat pinchStartScale;
@property (nonatomic, assign) CGPoint pinchStartTranslation;

@end

@implementation WorldMapView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) { [self commonInit]; }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) { [self commonInit]; }
    return self;
}

- (void)commonInit {

    _oftenFillColor = [UIColor colorWithHexString:@"#209365"];
    _goneFillColor = [UIColor colorWithHexString:@"#56DBA6"];
    _ungoFillColor = [UIColor colorWithHexString:@"#AFFFE0"];

    _strokeColor = [UIColor colorWithWhite:0 alpha:0.3];
    _lineWidth = 0.6;
    _minZoomScale = 1.0;
    _maxZoomScale = 8.0;

    _currentScale = 1.0;
    _currentTranslation = CGPointZero;

    _countryLayers = [NSMutableArray array];
    _countryISOs = [NSMutableArray array];
    _countryZhNames = [NSMutableArray array];
    _lastBuiltBoundsSize = CGSizeMake(-1, -1);

    _contentLayer = [CALayer layer];
    _contentLayer.frame = self.bounds;
    // 重要：把地图内容画在自己的坐标系里（同 view bounds），然后整体变换 contentLayer
    [self.layer addSublayer:_contentLayer];

    [self setupGestures];
    [self setupVisitLegend];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // 注意：旋转/布局变化时，contentLayer 的基准 frame 更新，但我们保持 transform
    self.contentLayer.frame = self.bounds;
    [self rebuildMapLayersIfNeeded];
    if (self.visitLegendContainer) {
        [self bringSubviewToFront:self.visitLegendContainer];
    }
}

/// 左下角：圆点 + 文案（经常去 / 已去过 / 还未去），不拦截手势
- (void)setupVisitLegend {
    UIView *container = [[UIView alloc] init];
    container.userInteractionEnabled = NO;
    container.backgroundColor = [UIColor clearColor];
    [self addSubview:container];
    self.visitLegendContainer = container;

    UIStackView *vertical = [[UIStackView alloc] init];
    vertical.axis = UILayoutConstraintAxisVertical;
    vertical.spacing = 2;
    vertical.alignment = UIStackViewAlignmentLeading;

    [vertical addArrangedSubview:[self mapLegendRowWithFillColor:self.oftenFillColor textKey:@"map_legend_often" fallback:@"经常去"]];
    [vertical addArrangedSubview:[self mapLegendRowWithFillColor:self.goneFillColor textKey:@"map_legend_visited" fallback:@"已去过"]];
    [vertical addArrangedSubview:[self mapLegendRowWithFillColor:self.ungoFillColor textKey:@"map_legend_not_yet" fallback:@"还未去"]];

    [container addSubview:vertical];
    [vertical mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(container);
    }];

    [container mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self).offset(2);
        make.bottom.equalTo(self).offset(-10);
    }];

}

- (UIStackView *)mapLegendRowWithFillColor:(UIColor *)color textKey:(NSString *)key fallback:(NSString *)fallback {
    UIView *dot = [[UIView alloc] init];
    dot.backgroundColor = color;
    CGFloat diameter = 4;
    dot.layer.cornerRadius = diameter / 2.0;
    dot.clipsToBounds = YES;
    [dot mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(diameter);
    }];

    UILabel *label = [[UILabel alloc] init];
    NSString *t = NSLocalizedString(key, nil);
    if ([t isEqualToString:key] || t.length == 0) t = fallback;
    label.text = t;
    label.font = [UIFont systemFontOfSize:6];
    label.textColor = [UIColor blackColor];

    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[ dot, label ]];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.spacing = 8;
    row.alignment = UIStackViewAlignmentCenter;
    return row;
}

#pragma mark - Public

- (void)loadGeoJSON {
    [self.countryLayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    [self.countryLayers removeAllObjects];
    [self.countryISOs removeAllObjects];
    [self.countryZhNames removeAllObjects];
    self.geoJSONData = nil;
    self.lastBuiltBoundsSize = CGSizeMake(-1, -1);

    NSInteger generation = ++self.geoJSONLoadGeneration;
    NSString *name = @"world-zh";
    NSString *ext = @"json";

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSURL *url = [[NSBundle mainBundle] URLForResource:name withExtension:ext];
        if (!url) {
            NSLog(@"WorldMapView: cannot find %@.%@ in bundle", name, ext);
            return;
        }

        NSData *data = [NSData dataWithContentsOfURL:url];
        if (!data) {
            NSLog(@"WorldMapView: failed to read %@.%@", name, ext);
            return;
        }

        NSError *err = nil;
        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
        if (err || ![json isKindOfClass:[NSDictionary class]]) {
            NSLog(@"WorldMapView: invalid geojson: %@", err);
            return;
        }

        NSDictionary *geoJSON = (NSDictionary *)json;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (generation != self.geoJSONLoadGeneration) {
                return;
            }
            self.geoJSONData = geoJSON;
            [self rebuildMapLayersIfNeeded];
        });
    });
}

/// bounds 有效且尺寸变化时才重建路径（首次布局前 bounds 为 0 时无法投影）
- (void)rebuildMapLayersIfNeeded {
    if (!self.geoJSONData) return;

    CGFloat w = CGRectGetWidth(self.bounds);
    CGFloat h = CGRectGetHeight(self.bounds);
    if (w < 1 || h < 1) return;

    BOOL sameSize = (fabs(w - self.lastBuiltBoundsSize.width) < 0.5 && fabs(h - self.lastBuiltBoundsSize.height) < 0.5);
    if (sameSize && self.countryLayers.count > 0) return;

    self.lastBuiltBoundsSize = CGSizeMake(w, h);

    [self.countryLayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    [self.countryLayers removeAllObjects];
    [self.countryISOs removeAllObjects];
    [self.countryZhNames removeAllObjects];

    [self buildLayersFromGeoJSON:self.geoJSONData];
    [self applyTransformClamped:YES];
}

- (void)reload {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self reload]; });
        return;
    }
    [self applyFillColorsToCountryLayers];
}

/// 仅更新已有 shapeLayer 的 fillColor，不重建路径
- (void)applyFillColorsToCountryLayers {
    NSUInteger n = self.countryLayers.count;
    if (n == 0 || n != self.countryISOs.count || n != self.countryZhNames.count) {
        return;
    }
    for (NSUInteger i = 0; i < n; i++) {
        CAShapeLayer *layer = self.countryLayers[i];
        NSString *iso = self.countryISOs[i];
        NSString *zh = self.countryZhNames[i];
        layer.fillColor = [self fillColorForISO:iso chineseName:zh].CGColor;
    }
}

#pragma mark - Build layers

- (void)buildLayersFromGeoJSON:(NSDictionary *)geojson {
    NSArray *features = geojson[@"features"];
    if (![features isKindOfClass:[NSArray class]]) return;

    CGRect rect = self.bounds;

    for (NSDictionary *feat in features) {
        if (![feat isKindOfClass:[NSDictionary class]]) continue;

        NSDictionary *geom = feat[@"geometry"];
        if (![geom isKindOfClass:[NSDictionary class]]) continue;

        NSString *type = geom[@"type"];
        id coords = geom[@"coordinates"];
        if (![coords isKindOfClass:[NSArray class]]) continue;

        UIBezierPath *countryPath = [UIBezierPath bezierPath];

        if ([type isEqualToString:@"Polygon"]) {
            [self appendPolygon:coords toPath:countryPath inRect:rect];
        } else if ([type isEqualToString:@"MultiPolygon"]) {
            for (id poly in (NSArray *)coords) {
                [self appendPolygon:poly toPath:countryPath inRect:rect];
            }
        } else {
            continue;
        }

        if (countryPath.isEmpty) continue;

        NSString *isoCode = [self isoCodeFromFeature:feat];
        NSString *zhName = [self chineseNameFromFeature:feat];

        CAShapeLayer *layer = [CAShapeLayer layer];
        layer.frame = rect;
        layer.path = countryPath.CGPath;
        layer.contentsScale = [UIScreen mainScreen].scale;

        layer.strokeColor = self.strokeColor.CGColor;
        layer.lineWidth = self.lineWidth;
        layer.fillColor = [self fillColorForISO:isoCode chineseName:zhName].CGColor;
        layer.lineJoin = kCALineJoinRound;
        layer.lineCap = kCALineCapRound;

        [self.contentLayer addSublayer:layer];
        [self.countryLayers addObject:layer];
        [self.countryISOs addObject:isoCode ?: @""];
        [self.countryZhNames addObject:zhName ?: @""];
    }
}

- (NSString *)chineseNameFromFeature:(NSDictionary *)feature {
    NSDictionary *props = feature[@"properties"];
    if (![props isKindOfClass:[NSDictionary class]]) {
        return @"";
    }
    id v = props[@"name"];
    if (![v isKindOfClass:[NSString class]]) {
        return @"";
    }
    return WMNormalizeCountryLabel((NSString *)v);
}

- (NSString *)isoCodeFromFeature:(NSDictionary *)feature {
    NSDictionary *props = feature[@"properties"];
    if (![props isKindOfClass:[NSDictionary class]]) return @"";
    id v = props[@"iso"];
    if (![v isKindOfClass:[NSString class]]) return @"";
    NSString *s = [(NSString *)v stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return [s uppercaseString];
}

/// 优先级：经常去 > 已去过 > 未去；按 **ISO 两字母** 或 **中文名**（与 GeoJSON `name` 一致）匹配
- (UIColor *)fillColorForISO:(NSString *)iso chineseName:(NSString *)zh {
    NSString *isoKey = [iso length] ? [iso uppercaseString] : @"";
    NSString *zhKey = WMNormalizeCountryLabel(zh);

    NSSet *often = [self normalizedCountryTokenSetFromArray:self.oftenCountries];
    NSSet *gone = [self normalizedCountryTokenSetFromArray:self.goneCountries];
    NSSet *ungo = [self normalizedCountryTokenSetFromArray:self.ungoCountries];

    BOOL hitOften = (isoKey.length && [often containsObject:isoKey]) || (zhKey.length && [often containsObject:zhKey]);
    BOOL hitGone = (isoKey.length && [gone containsObject:isoKey]) || (zhKey.length && [gone containsObject:zhKey]);
    BOOL hitUngo = (isoKey.length && [ungo containsObject:isoKey]) || (zhKey.length && [ungo containsObject:zhKey]);

    if (hitOften) {
        return self.oftenFillColor;
    }
    if (hitGone) {
        return self.goneFillColor;
    }
    if (hitUngo) {
        return self.ungoFillColor;
    }
    return self.ungoFillColor;
}

- (NSSet<NSString *> *)normalizedCountryTokenSetFromArray:(NSArray *)arr {
    if (![arr isKindOfClass:[NSArray class]] || arr.count == 0) {
        return [NSSet set];
    }
    NSMutableSet<NSString *> *set = [NSMutableSet setWithCapacity:arr.count];
    for (id o in arr) {
        if (![o isKindOfClass:[NSString class]]) {
            continue;
        }
        NSString *raw = WMNormalizeCountryLabel((NSString *)o);
        if (!raw.length) {
            continue;
        }
        if (WMStringLooksLikeISOAlpha2(raw)) {
            [set addObject:[raw uppercaseString]];
        } else {
            [set addObject:raw];
        }
    }
    return [set copy];
}

#pragma mark - GeoJSON helpers

/// Polygon: [ [ring], [hole], ... ]
- (void)appendPolygon:(id)polygonCoords toPath:(UIBezierPath *)path inRect:(CGRect)rect {
    if (![polygonCoords isKindOfClass:[NSArray class]]) return;

    for (id ring in (NSArray *)polygonCoords) {
        if (![ring isKindOfClass:[NSArray class]]) continue;
        NSArray *pts = (NSArray *)ring;
        if (pts.count < 2) continue;

        BOOL didMove = NO;
        CGPoint first = CGPointZero;

        for (id p in pts) {
            if (![p isKindOfClass:[NSArray class]]) continue;
            NSArray *pair = (NSArray *)p;
            if (pair.count < 2) continue;

            double lon = [pair[0] doubleValue];
            double lat = [pair[1] doubleValue];
            CGPoint xy = [self projectLon:lon lat:lat inRect:rect];

            if (!didMove) {
                [path moveToPoint:xy];
                first = xy;
                didMove = YES;
            } else {
                [path addLineToPoint:xy];
            }
        }

        if (didMove) [path addLineToPoint:first];
    }

    // 让填充正确：多子路径时使用 even-odd
    path.usesEvenOddFillRule = YES;
}

#pragma mark - Projection (Equirectangular)

- (CGPoint)projectLon:(double)lon lat:(double)lat inRect:(CGRect)rect {
    double x = (lon + 180.0) / 360.0;   // 0..1
    double y = (90.0 - lat) / 180.0;    // 0..1
    return CGPointMake(rect.origin.x + x * rect.size.width,
                       rect.origin.y + y * rect.size.height);
}

#pragma mark - Gestures

- (void)setupGestures {
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
    pan.maximumNumberOfTouches = 2;
    [self addGestureRecognizer:pan];

    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(onPinch:)];
    [self addGestureRecognizer:pinch];

    // 让 pinch 和 pan 同时工作更自然
    pan.cancelsTouchesInView = NO;
    pinch.cancelsTouchesInView = NO;
}

- (void)onPan:(UIPanGestureRecognizer *)gr {
    if (gr.state == UIGestureRecognizerStateBegan) {
        self.panStartTranslation = self.currentTranslation;
    }

    CGPoint delta = [gr translationInView:self];
    self.currentTranslation = CGPointMake(self.panStartTranslation.x + delta.x,
                                          self.panStartTranslation.y + delta.y);
    [self applyTransformClamped:YES];
}

- (void)onPinch:(UIPinchGestureRecognizer *)gr {
    if (gr.state == UIGestureRecognizerStateBegan) {
        self.pinchStartScale = self.currentScale;
        self.pinchStartTranslation = self.currentTranslation;
        self.pinchAnchorInView = [gr locationInView:self];
    }

    CGFloat newScale = self.pinchStartScale * gr.scale;
    newScale = MAX(self.minZoomScale, MIN(self.maxZoomScale, newScale));

    // 关键：围绕 pinchAnchor 缩放（保持锚点在屏幕位置不动）
    // currentTranslation 负责把 contentLayer 移到正确位置
    // 推导：T' = A - (A - T) * (S'/S)
    CGFloat ratio = (self.pinchStartScale > 0.0) ? (newScale / self.pinchStartScale) : 1.0;
    CGPoint A = self.pinchAnchorInView;
    CGPoint T0 = self.pinchStartTranslation;

    CGPoint T1 = CGPointMake(A.x - (A.x - T0.x) * ratio,
                             A.y - (A.y - T0.y) * ratio);

    self.currentScale = newScale;
    self.currentTranslation = T1;

    [self applyTransformClamped:YES];
}

#pragma mark - Transform / clamping

- (void)applyTransformClamped:(BOOL)clamp {
    if (clamp) {
        self.currentScale = MAX(self.minZoomScale, MIN(self.maxZoomScale, self.currentScale));
        self.currentTranslation = [self clampedTranslationForScale:self.currentScale translation:self.currentTranslation];
    }

    CATransform3D t = CATransform3DIdentity;
    // 先平移再缩放（对 contentLayer 生效）
    t = CATransform3DTranslate(t, self.currentTranslation.x, self.currentTranslation.y, 0);
    t = CATransform3DScale(t, self.currentScale, self.currentScale, 1);
    self.contentLayer.transform = t;
}

/// 限制拖拽范围：缩放后按内容溢出计算，可拖至边缘
- (CGPoint)clampedTranslationForScale:(CGFloat)scale translation:(CGPoint)translation {
    CGSize viewSize = self.bounds.size;
    if (viewSize.width < 1 || viewSize.height < 1) {
        return translation;
    }

    CGSize scaled = CGSizeMake(viewSize.width * scale, viewSize.height * scale);
    CGPoint base = CGPointMake((viewSize.width - scaled.width) / 2.0,
                               (viewSize.height - scaled.height) / 2.0);

    CGFloat overflowX = MAX(0, (scaled.width - viewSize.width) / 2.0);
    CGFloat overflowY = MAX(0, (scaled.height - viewSize.height) / 2.0);

    CGFloat minX = base.x - overflowX;
    CGFloat maxX = base.x + overflowX;
    CGFloat minY = base.y - overflowY;
    CGFloat maxY = base.y + overflowY;

    if (scaled.width <= viewSize.width) { minX = maxX = base.x; }
    if (scaled.height <= viewSize.height) { minY = maxY = base.y; }

    CGFloat x = MIN(MAX(translation.x, minX), maxX);
    CGFloat y = MIN(MAX(translation.y, minY), maxY);
    return CGPointMake(x, y);
}

@end
