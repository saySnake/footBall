//
//  BVAPPDebugTool.m
//  Bhex
//
//  Created by DZSB-001968 on 6.12.23.
//  Copyright © 2023 Bhex. All rights reserved.
//

#import "BVAPPDebugTool.h"
#ifdef DEBUG
@import DoraemonKit;
#if __has_include(<MLeaksFinder/MLeaksFinder.h>)
@import MLeaksFinder;
#endif
#import <objc/runtime.h>
#import "BVAPPEnvironmentHostManager.h"
#import "ColorManager.h"
#import <Masonry/Masonry.h>

@implementation BVAPPDebugTool

+ (void)setup {
    // 确保在主线程执行
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setup];
        });
        return;
    }
    
    // 延迟初始化，确保 window 已经完全创建并显示
    // 这对于使用 SceneDelegate 的项目很重要
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 检查是否有可用的 window
        UIWindow *keyWindow = nil;
        if (@available(iOS 13.0, *)) {
            // iOS 13+ 使用 SceneDelegate
            NSArray<UIWindowScene *> *windowScenes = [UIApplication sharedApplication].connectedScenes.allObjects;
            for (UIWindowScene *scene in windowScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]]) {
                    for (UIWindow *window in scene.windows) {
                        if (window.isKeyWindow) {
                            keyWindow = window;
                            break;
                        }
                    }
                    if (keyWindow) break;
                }
            }
        } else {
            // iOS 12 及以下
            keyWindow = [UIApplication sharedApplication].keyWindow;
        }
        
        if (!keyWindow) {
            NSLog(@"⚠️ 未找到 keyWindow，再次延迟初始化 DoKit");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self setup];
            });
            return;
        }
        
        NSLog(@"✅ 找到 keyWindow，开始安装 DoKit");
        
        // 安装 DoKit
        [[DoraemonManager shareInstance] install];
        NSLog(@"✅ DoKit 已安装");
        
        // 延迟配置自定义插件和样式（确保 DoKit 完全初始化）
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // 移除不用的
            [[DoraemonManager shareInstance] removePluginWithPluginType:DoraemonManagerPluginType_DoraemonMockPlugin];
            [[DoraemonManager shareInstance] removePluginWithPluginType:DoraemonManagerPluginType_DoraemonHealthPlugin];
            [[DoraemonManager shareInstance] removePluginWithPluginType:DoraemonManagerPluginType_DoraemonFileSyncPlugin];
            [[DoraemonManager shareInstance] removePluginWithPluginType:DoraemonManagerPluginType_DoraemonWeexLogPlugin];        
            [[DoraemonManager shareInstance] removePluginWithPluginType:DoraemonManagerPluginType_DoraemonWeexStoragePlugin];
            [[DoraemonManager shareInstance] removePluginWithPluginType:DoraemonManagerPluginType_DoraemonWeexInfoPlugin];
            [[DoraemonManager shareInstance] removePluginWithPluginType:DoraemonManagerPluginType_DoraemonWeexDevToolPlugin];
            // 添加要用的
            [[DoraemonManager shareInstance] addPluginWithTitle:@"切换环境" icon:@"doraemon_default" desc:@"切换app环境" pluginName:@"BVDebugNetworkSwitchPlugin" atModule:@"业务专区"];
            
            [[DoraemonManager shareInstance] addPluginWithTitle:@"内存检测弹窗" icon:@"doraemon_default" desc:@"检查内存泄露,循环引用" pluginName:@"BVDebugMemoryLeakPlugin" atModule:@"业务专区"];
        
            [BVAPPDebugTool setupCustomLogoStyle];
        });
    });
}

+ (void)setupCustomLogoStyle {
    DoraemonEntryWindow *logoWindow = [[DoraemonManager shareInstance] valueForKey:@"entryWindow"];
    UIButton *button = [logoWindow valueForKey:@"entryBtn"];
    [button setImage:nil forState:UIControlStateNormal];
    
    // 使用 ColorManager 创建颜色
    logoWindow.backgroundColor = [ColorManager colorWithHexString:@"#000000" alpha:0.7];
    
    // 使用 frame.size.width 获取宽度
    CGFloat windowWidth = logoWindow.frame.size.width;
    logoWindow.layer.cornerRadius = windowWidth / 2;
    logoWindow.layer.borderWidth = 4;
    logoWindow.layer.borderColor = UIColor.greenColor.CGColor;
    logoWindow.clipsToBounds = YES;
    
    UILabel *label = [UILabel new];
    [label sizeToFit];
    label.textColor = UIColor.whiteColor;
    // 使用系统字体
    label.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [logoWindow addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(logoWindow);
    }];
    label.text = [BVAPPEnvironmentHostManager shareInstance].currentSelected.displayName;
}

@end

#endif
