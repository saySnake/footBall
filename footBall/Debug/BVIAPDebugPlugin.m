//
//  BVIAPDebugPlugin.m
//  footBall
//
//  DoKit 自定义插件入口：点击后 push 出 IAP 调试面板。
//

#ifdef DEBUG

#import "BVIAPDebugPlugin.h"
#import "BVIAPDebugViewController.h"
@import DoraemonKit;

@interface BVIAPDebugPlugin () <DoraemonPluginProtocol>
@end

@implementation BVIAPDebugPlugin

- (void)pluginDidLoad {
    BVIAPDebugViewController *vc = [[BVIAPDebugViewController alloc] init];
    [[DoraemonHomeWindow shareInstance].nav pushViewController:vc animated:YES];
}

@end

#else

@implementation BVIAPDebugPlugin
@end

#endif
