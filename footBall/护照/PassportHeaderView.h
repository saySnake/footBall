//
//  PassportHeaderView.h
//  footBall
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PassportViewModel;

@interface PassportHeaderView : UIView
- (void)configureWithModel:(PassportViewModel *)model;
@end

NS_ASSUME_NONNULL_END
