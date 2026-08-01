//
//  BVIAPDebugPlugin.h
//  footBall
//
//  DoKit 自定义插件：进入「IAP 调试面板」，覆盖 App Store 内购审核测试场景。
//  仅在 DEBUG 编译， RELEASE 包不会包含任何代码（详见 .m 的 #ifdef DEBUG 包裹）。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BVIAPDebugPlugin : NSObject

@end

NS_ASSUME_NONNULL_END
