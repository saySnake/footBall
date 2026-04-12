#import "QMBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

/// 会员中心（含月度/赛季/终身/创始人四种方案）
@interface MembershipCenterViewController : QMBaseViewController

/// 默认 0（月度通行证）；可在跳转前设置对应 Figma 场景
@property (nonatomic, assign) NSInteger initialPlanIndex;

@end

NS_ASSUME_NONNULL_END

