//
//  PassportWeekLineChartView.h
//  footBall
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 护照头部周折线图：深色底、绿线、下 X 轴（日～六）
@interface PassportWeekLineChartView : UIView

/// 周一至周日共 7 个值，范围 0～100；默认有演示数据
@property (nonatomic, copy) NSArray<NSNumber *> *weekValues;

/// 折线颜色（默认亮绿）
@property (nonatomic, strong) UIColor *lineColor;
/// 网格线颜色
@property (nonatomic, strong) UIColor *gridColor;

@end

NS_ASSUME_NONNULL_END
