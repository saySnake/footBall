//
//  StampUnlockPopupViewController.h
//  footBall
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface StampUnlockPopupViewController : UIViewController

/// 点击任一方案或「查看更多选择」后的回调（弹窗会先 dismiss，再回调）。
/// initialPlanIndex: 0=月度, 1=赛季(年), 2=终身(永久), 3=创始人
@property (nonatomic, copy, nullable) void (^onConfirm)(NSInteger initialPlanIndex);

/// 可选：自定义标题/描述（不传则使用默认文案）。
@property (nonatomic, copy, nullable) NSString *dialogTitleText;
@property (nonatomic, copy, nullable) NSString *dialogDescText;

@end

NS_ASSUME_NONNULL_END

