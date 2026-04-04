//
//  PassportSheetsViewController.h
//  footBall
//

#import "QMBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class PassportViewModel;

/// 护照页点击 PassportHeader2View 进入：首卡复用 PassportHeader2View，下方为邮票张占位
@interface PassportSheetsViewController : QMBaseViewController

- (instancetype)initWithViewModel:(PassportViewModel *)viewModel year:(NSInteger)year;

@end

NS_ASSUME_NONNULL_END
