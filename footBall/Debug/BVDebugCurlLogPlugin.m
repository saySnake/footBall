//
//  BVDebugCurlLogPlugin.m
//  footBall
//

#ifdef DEBUG

#import "BVDebugCurlLogPlugin.h"
#import "APICurlLogInterceptor.h"

@implementation BVDebugCurlLogPlugin

- (void)pluginDidLoad {
    APICurlLogInterceptor *interceptor = [APICurlLogInterceptor shared];
    interceptor.enabled = !interceptor.enabled;

    NSString *status = interceptor.enabled ? @"已开启 ✅" : @"已关闭 ❌";
    NSString *msg = [NSString stringWithFormat:@"curl 日志 %@", status];

    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"curl 日志"
                                                                      message:msg
                                                               preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];

        UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
        while (root.presentedViewController) {
            root = root.presentedViewController;
        }
        [root presentViewController:alert animated:YES completion:nil];
    });
}

@end

#endif
