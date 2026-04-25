//
//  PNMatchDetailViewController.h
//  footBall
//

#import <UIKit/UIKit.h>

/// 比赛详情页（只有完成观赛信息填写并认证后才能进入）
@interface PNMatchDetailViewController : UIViewController

/// 观赛记录ID（用于请求详情数据）
@property (nonatomic, copy) NSString *recordId;
/// 比赛ID（备用）
@property (nonatomic, copy) NSString *matchId;
/// 主队名称（从 Discover 列表传入，详情加载前先显示）
@property (nonatomic, copy) NSString *homeName;
/// 客队名称（从 Discover 列表传入，详情加载前先显示）
@property (nonatomic, copy) NSString *awayName;

@end
