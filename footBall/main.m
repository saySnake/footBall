//
//  main.m
//  footBall
//
//  Created by 张玮 on 2026/1/15.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

int main(int argc, char * argv[]) {
    NSString * appDelegateClassName;
    @autoreleasepool {
        // ⚠️ 临时：强制 App 使用简体中文，不跟随手机系统语言。
        // 原因：英文 / 繁中语言文件尚未校对完成，统一显示中文。
        // 待所有语言文件校对完成后，删除下面 4 行即可恢复"跟随系统语言"。
        [[NSUserDefaults standardUserDefaults] setObject:@[@"zh-Hans"]
                                                  forKey:@"AppleLanguages"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
