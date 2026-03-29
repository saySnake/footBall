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
@end

@interface PassportDonutChartView : UIView
/// 0–1 segments that sum to 1, or normalized in draw
@property (nonatomic, strong) NSArray<NSNumber *> *segmentRatios;
@property (nonatomic, strong) NSArray<UIColor *> *segmentColors;
@property (nonatomic, copy, nullable) NSString *centerText;
@property (nonatomic, assign) CGFloat lineWidth;
@end

NS_ASSUME_NONNULL_END
