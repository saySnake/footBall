//
//  ThemeObserverView.m
//  footBall
//
//  Created on 2026/1/15.
//  主题监听视图 - 用于全局监听系统主题变化
//

#import "ThemeObserverView.h"
#import "ThemeManager.h"

@implementation ThemeObserverView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.hidden = NO; // 必须可见才能接收 traitCollection 变化
        self.alpha = 0.0; // 但设置为完全透明
        self.userInteractionEnabled = NO;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    // 检测系统主题变化（iOS 13+）
    if (@available(iOS 13.0, *)) {
        if (previousTraitCollection && 
            [previousTraitCollection hasDifferentColorAppearanceComparedToTraitCollection:self.traitCollection]) {
            // 系统主题发生了变化
            UIUserInterfaceStyle previousStyle = previousTraitCollection.userInterfaceStyle;
            UIUserInterfaceStyle currentStyle = self.traitCollection.userInterfaceStyle;
            
            NSLog(@"🎨 检测到系统主题变化: %@ -> %@", 
                  previousStyle == UIUserInterfaceStyleDark ? @"Dark" : @"Light",
                  currentStyle == UIUserInterfaceStyleDark ? @"Dark" : @"Light");
            
            ThemeManager *themeManager = [ThemeManager sharedManager];
            if (themeManager.currentTheme == AppThemeAuto) {
                // 如果当前主题是跟随系统，触发主题更新通知
                NSLog(@"✅ 当前主题设置为跟随系统，触发主题更新");
                [themeManager handleSystemThemeChange];
            } else {
                NSLog(@"⚠️ 当前主题不是跟随系统模式，不更新");
            }
        }
    }
}

@end
