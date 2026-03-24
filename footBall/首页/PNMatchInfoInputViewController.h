//
//  PNMatchInfoInputViewController.h
//  footBall
//

#import <UIKit/UIKit.h>

/// 观赛信息输入弹层（底部卡片）
@interface PNMatchInfoInputViewController : UIViewController

/// 主队名称（用于上方“比赛”占位）
@property (nonatomic, copy) NSString *homeName;
/// 客队名称
@property (nonatomic, copy) NSString *awayName;

/// 完成输入后的回调（仅用于通知上层即可，具体数据暂不持久化）
@property (nonatomic, copy) void (^completion)(void);

@end

