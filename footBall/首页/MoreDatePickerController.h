//
//  MoreDatePickerController.h
//  footBall
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 日历样式的日期选择弹窗（选择时间），可用于更多比赛、消费记录等页面
@interface MoreDatePickerController : UIViewController

@property (nonatomic, strong, nullable) NSDate *selectedDate;
@property (nonatomic, copy, nullable) void (^onConfirm)(NSDate *date);

@end

NS_ASSUME_NONNULL_END
