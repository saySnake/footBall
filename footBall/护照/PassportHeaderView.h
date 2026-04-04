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
@end

NS_ASSUME_NONNULL_END
