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
@end

NS_ASSUME_NONNULL_END
