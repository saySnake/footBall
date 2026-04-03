//
//  PassportChartViews.h
//  footBall
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PassportBarChartView : UIView
@property (nonatomic, strong) NSArray<NSNumber *> *values;
@property (nonatomic, assign) CGFloat maxValue;
@property (nonatomic, strong) UIColor *barColor;
/// x 轴标题（与 values 一一对应），默认是“在现场/在酒吧/在球场/在家里/在外面/在学校/在公司”
@property (nonatomic, copy) NSArray<NSString *> *xTitles;
/// 固定柱宽，设计稿为 20
@property (nonatomic, assign) CGFloat barWidth;
@end

@interface PassportDonutChartView : UIView
/// 0–1 segments that sum to 1, or normalized in draw
@property (nonatomic, strong) NSArray<NSNumber *> *segmentRatios;
@property (nonatomic, strong) NSArray<UIColor *> *segmentColors;
@property (nonatomic, copy, nullable) NSString *centerText;
@property (nonatomic, assign) CGFloat lineWidth;
/// 圆环内孔半径（pt）。0 表示按 bounds 自动算中心线半径；>0 时中心线半径 = ringInnerRadius + lineWidth/2
@property (nonatomic, assign) CGFloat ringInnerRadius;
/// 整圈底色（如战术环 #1B3C3E）；nil 时不绘制
@property (nonatomic, strong, nullable) UIColor *ringTrackColor;
/// 底色环描边相对 `lineWidth` 多出的宽度（pt），例如 10 表示底色总宽为 lineWidth+10
@property (nonatomic, assign) CGFloat ringTrackExtraWidth;
/// 相邻彩色扇形之间沿弧长的间隔（pt），0 表示无间隔
@property (nonatomic, assign) CGFloat segmentGapPoints;
/// 在环外绘制百分比与引导线（系统 24 Bold）
@property (nonatomic, assign) BOOL showsOutsidePercentLabels;
@property (nonatomic, strong) UIColor *outsidePercentLabelColor;
@end

NS_ASSUME_NONNULL_END
