//
//  PNCommonAlertViewController.h
//  footBall
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PNCommonAlertViewController : UIViewController

@property (nonatomic, copy) NSString *alertTitle;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *cancelTitle;
@property (nonatomic, copy) NSString *confirmTitle;
/// 为 YES 时确认按钮使用红色警示样式（设计稿删除账户等为绿色确认，默认 NO）
@property (nonatomic, assign) BOOL confirmDestructive;
@property (nonatomic, copy, nullable) void (^onCancel)(void);
@property (nonatomic, copy, nullable) void (^onConfirm)(void);

@end

NS_ASSUME_NONNULL_END

