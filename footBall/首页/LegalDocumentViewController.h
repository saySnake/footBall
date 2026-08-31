//
//  LegalDocumentViewController.h
//  footBall
//

#import "QMBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

/// 应用内法律文本展示页（从 Bundle 读取 .txt）
@interface LegalDocumentViewController : QMBaseViewController

+ (instancetype)documentWithTitle:(NSString *)title resourceName:(NSString *)resourceName;

@end

NS_ASSUME_NONNULL_END
