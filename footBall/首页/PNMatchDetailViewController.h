//
//  PNMatchDetailViewController.h
//  footBall
//

#import <UIKit/UIKit.h>

/// 比赛详情页（只有完成观赛信息填写并认证后才能进入，数据暂为假数据）
@interface PNMatchDetailViewController : UIViewController

/// 主队名称（从 Discover 假数据传入）
@property (nonatomic, copy) NSString *homeName;
/// 客队名称（从 Discover 假数据传入）
@property (nonatomic, copy) NSString *awayName;

@end


