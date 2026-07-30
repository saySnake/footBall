//
//  PassportTableCells.h
//  footBall
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PassportViewModel;

@interface PassportDarkStatsCardCell : UITableViewCell
- (void)configureWithModel:(PassportViewModel *)model;
@end

@interface PassportGrowthBannerCell : UITableViewCell
- (void)configureWithModel:(PassportViewModel *)model;
@end

@interface PassportBarChartCardCell : UITableViewCell
- (void)configureWithModel:(PassportViewModel *)model;
@end

@interface PassportPossessionCardCell : UITableViewCell
- (void)configureWithModel:(PassportViewModel *)model;
@end

@interface PassportPositionStrengthCell : UITableViewCell
- (void)configureWithModel:(PassportViewModel *)model;
@end

@interface PassportAbilityBlockCell : UITableViewCell
- (void)configureWithModel:(PassportViewModel *)model;
@end

@interface PassportTacticalCell : UITableViewCell
+ (CGFloat)preferredHeightForSegmentCount:(NSUInteger)count;
- (void)configureWithModel:(PassportViewModel *)model;
@end

@interface PassportMetricBarsCell : UITableViewCell
- (void)configureWithModel:(PassportViewModel *)model;
@end

@interface PassportOutcomeCell : UITableViewCell
- (void)configureWithModel:(PassportViewModel *)model;
@end

/// 护照图表加载失败时的分区空状态（避免刷成 0 被误认为真实数据）
@interface PassportChartEmptyStateCell : UITableViewCell
- (void)configureWithTitle:(NSString *)title;
@end

NS_ASSUME_NONNULL_END
