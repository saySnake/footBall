#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WorldMapView : UIView

@property (nonatomic, strong) UIColor *strokeColor;     // 默认深灰
@property (nonatomic, assign) CGFloat lineWidth;        // 默认 0.6
@property (nonatomic, assign) CGFloat minZoomScale;     // 默认 1.0
@property (nonatomic, assign) CGFloat maxZoomScale;     // 默认 8.0

@property (nonatomic, strong) UIColor *oftenFillColor;     // 经常去的填充色
@property (nonatomic, strong) UIColor *goneFillColor;     // 已经去过的填充色
@property (nonatomic, strong) UIColor *ungoFillColor;     // 没去过的填充色

/// 经常去 / 已去过 / 未去：元素为 **中文国家名**（与 bundle 内 `world-zh.json` 的 `properties.name` 一致），也兼容两字母 **ISO**（如 CN、US）
@property (nonatomic, strong) NSArray *oftenCountries;
@property (nonatomic, strong) NSArray *goneCountries;
@property (nonatomic, strong) NSArray *ungoCountries;

/// 加载并绘制 GeoJSON
- (void)loadGeoJSON;

/// 在异步赋值 oftenCountries / goneCountries / ungoCountries 后调用，重绘各国填充色（可在任意线程调用，内部切回主线程）
- (void)reload;

@end

NS_ASSUME_NONNULL_END
