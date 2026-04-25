//
//  PassportSheetsViewController.h
//  footBall
//

#import "QMBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class PassportViewModel;

/// 邮票主页
@interface PassportSheetsViewController : QMBaseViewController

- (instancetype)initWithViewModel:(PassportViewModel *)viewModel year:(NSInteger)year;

/// 查看他人邮票时传入对方 userId；nil 或空字符串表示查看自己
@property (nonatomic, copy, nullable) NSString *targetUserId;
/// 查看他人邮票时显示的昵称（用于导航栏标题）
@property (nonatomic, copy, nullable) NSString *targetNickname;

@end

NS_ASSUME_NONNULL_END
