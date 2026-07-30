//
//  PassportHeaderView.h
//  footBall
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PassportViewModel;

@interface PassportHeaderView : UIView

/// 底部 `PassportHeader2View` 区域点击（进入集邮册等子页）
@property (nonatomic, copy, nullable) void (^onPassportHeader2Tap)(void);

- (void)configureWithModel:(PassportViewModel *)model;
/// 接口失败空态：数字用「--」，图表清空，避免显示 0 被当成真实观赛数据
- (void)applyLoadFailedEmptyAppearance;
@end

NS_ASSUME_NONNULL_END
