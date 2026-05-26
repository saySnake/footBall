//
//  VerifyCodeViewController.h
//  footBall
//
//  输入短信验证码界面。
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, VerifyCodePurpose) {
    VerifyCodePurposeLogin = 0,
    /// 注销账号：校验短信验证码后调用 `/api/v1/auth/account/deactivate`
    VerifyCodePurposeDeactivateAccount,
};

@interface VerifyCodeViewController : UIViewController

@property (nonatomic, copy) NSString *phoneNumber;
@property (nonatomic, assign) VerifyCodePurpose purpose;

@end

NS_ASSUME_NONNULL_END

