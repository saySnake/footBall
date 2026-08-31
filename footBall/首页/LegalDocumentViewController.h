//
//  LegalDocumentViewController.h
//  footBall
//

#import "QMBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

/// 应用内法律文本展示页（从 Bundle 读取 .txt，内容预缓存）
@interface LegalDocumentViewController : QMBaseViewController

@property (nonatomic, copy, nullable) NSString *preloadedText;

+ (instancetype)documentWithTitle:(NSString *)title resourceName:(NSString *)resourceName;

@end

NS_ASSUME_NONNULL_END
