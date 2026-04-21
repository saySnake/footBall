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

/// 观赛记录 ID；非空时走 `PUT /match-records/{id}` 并先拉详情填充表单
@property (nonatomic, copy, nullable) NSString *recordId;
/// 比赛 ID；创建记录时（`recordId` 为空）必填，对应后端 `CreateMatchRecordReq.matchId`
@property (nonatomic, copy, nullable) NSString *matchId;
/// 手动录入且无 `matchId` 时与 `matchName` 一起使用（可选）
@property (nonatomic, copy, nullable) NSString *stadiumName;

/// 创建或更新成功后回调；返回服务端观赛记录 ID（更新时为当前 recordId）
@property (nonatomic, copy, nullable) void (^completion)(NSString * _Nullable recordId);

@end

