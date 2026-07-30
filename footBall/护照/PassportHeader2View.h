//
//  PassportHeader2View.h
//  footBall
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PassportViewModel;

@interface PassportHeader2View : UIView

- (void)configureWithModel:(PassportViewModel *)model;
/// 接口失败：统计位显示「--」，避免 0 被当成真实数据
- (void)applyLoadFailedEmptyAppearance;

@end

NS_ASSUME_NONNULL_END

