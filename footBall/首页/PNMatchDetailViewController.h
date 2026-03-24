//
//  PNMatchDetailViewController.h
//  footBall
//

#import <UIKit/UIKit.h>

/// 比赛详情页（只有完成观赛信息填写并认证后才能进入）
@interface PNMatchDetailViewController : UIViewController

/// 比赛ID（用于请求详情）
@property (nonatomic, copy) NSString *matchId;
/// 主队名称（从 Discover 列表传入）
@property (nonatomic, copy) NSString *homeName;
/// 客队名称（从 Discover 列表传入）
@property (nonatomic, copy) NSString *awayName;

@end


