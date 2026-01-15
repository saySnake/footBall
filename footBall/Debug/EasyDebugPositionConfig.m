//
//  EasyDebugPositionConfig.m
//  footBall
//
//  EasyDebug 按钮位置配置实现
//

#import "EasyDebugPositionConfig.h"

#ifdef DEBUG
#import <easydebug/EasyDebug.h>
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

// 存储自定义位置配置
static NSInteger g_customPosition = -1;
static CGFloat g_offsetX = 0;
static CGFloat g_offsetY = 0;
static CGFloat g_customX = -1;
static CGFloat g_customY = -1;
static CGFloat g_customXPercent = -1;
static CGFloat g_customYPercent = -1;

// 更新按钮位置的函数
static void updateButtonPosition(UIButton *button) {
    UIWindow *window = button.window;
    if (!window) {
        window = [UIApplication sharedApplication].keyWindow;
    }
    
    if (!window) {
        return;
    }
    
    CGFloat screenWidth = window.bounds.size.width;
    CGFloat screenHeight = window.bounds.size.height;
    CGFloat buttonWidth = button.frame.size.width;
    CGFloat buttonHeight = button.frame.size.height;
    
    CGFloat x = 0;
    CGFloat y = 0;
    
    // 如果设置了自定义坐标
    if (g_customX >= 0 && g_customY >= 0) {
        x = g_customX;
        y = g_customY;
    }
    // 如果设置了百分比
    else if (g_customXPercent >= 0 && g_customYPercent >= 0) {
        x = screenWidth * g_customXPercent;
        y = screenHeight * g_customYPercent;
    }
    // 如果设置了预设位置
    else if (g_customPosition >= 0) {
        switch (g_customPosition) {
            case 0: // 左下角（默认）
                x = screenWidth * 0.06;
                y = screenHeight - buttonHeight * 0.4;
                break;
            case 1: // 右下角
                x = screenWidth - buttonWidth - screenWidth * 0.06;
                y = screenHeight - buttonHeight * 0.4;
                break;
            case 2: // 左上角
                x = screenWidth * 0.06;
                y = buttonHeight * 0.4;
                break;
            case 3: // 右上角
                x = screenWidth - buttonWidth - screenWidth * 0.06;
                y = buttonHeight * 0.4;
                break;
            case 4: // 底部居中
                x = (screenWidth - buttonWidth) / 2.0;
                y = screenHeight - buttonHeight * 0.4;
                break;
            case 5: // 顶部居中
                x = (screenWidth - buttonWidth) / 2.0;
                y = buttonHeight * 0.4;
                break;
            case 6: // 左侧居中
                x = screenWidth * 0.06;
                y = (screenHeight - buttonHeight) / 2.0;
                break;
            case 7: // 右侧居中
                x = screenWidth - buttonWidth - screenWidth * 0.06;
                y = (screenHeight - buttonHeight) / 2.0;
                break;
            default:
                // 默认位置
                x = screenWidth * 0.06;
                y = screenHeight - buttonHeight * 0.4;
                break;
        }
        
        // 应用偏移量
        x += g_offsetX;
        y += g_offsetY;
    }
    else {
        // 使用默认位置
        x = screenWidth * 0.06;
        y = screenHeight - buttonHeight * 0.4;
    }
    
    // 确保按钮不超出屏幕
    x = MAX(0, MIN(x, screenWidth - buttonWidth));
    y = MAX(0, MIN(y, screenHeight - buttonHeight));
    
    // 设置按钮位置 - 使用 Runtime 设置 frame
    CGRect frame = button.frame;
    frame.origin = CGPointMake(x, y);
    button.frame = frame;
}

// 定时器来定期更新按钮位置
static NSTimer *g_positionUpdateTimer = nil;

// 启动位置更新定时器
static void startPositionUpdateTimer() {
    if (g_positionUpdateTimer) {
        return;
    }
    
    g_positionUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                              repeats:YES
                                                                block:^(NSTimer * _Nonnull timer) {
        // 通过反射获取 EZDDisplayer 实例
        Class displayerClass = NSClassFromString(@"EZDDisplayer");
        if (displayerClass) {
            SEL sharedSelector = NSSelectorFromString(@"shared");
            if ([displayerClass respondsToSelector:sharedSelector]) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                id displayer = [displayerClass performSelector:sharedSelector];
                if (displayer) {
                    UIButton *button = [displayer valueForKey:@"consoleEntryBtn"];
                    if (button && button.window && !button.hidden) {
                        // 检查是否需要更新位置（只在配置了自定义位置时更新）
                        if (g_customPosition >= 0 || g_customX >= 0 || g_customXPercent >= 0) {
                            updateButtonPosition(button);
                        }
                    }
                }
                #pragma clang diagnostic pop
            }
        }
    }];
}

@implementation EasyDebugPositionConfig

+ (void)configButtonPosition:(NSInteger)position 
                     offsetX:(CGFloat)offsetX 
                     offsetY:(CGFloat)offsetY {
    g_customPosition = position;
    g_offsetX = offsetX;
    g_offsetY = offsetY;
    g_customX = -1;
    g_customY = -1;
    g_customXPercent = -1;
    g_customYPercent = -1;
    
    // 启动定时器来持续更新位置
    startPositionUpdateTimer();
    
    // 立即触发一次位置更新
    [self updateButtonPositionIfNeeded];
}

+ (void)configButtonPositionWithX:(CGFloat)x y:(CGFloat)y {
    g_customX = x;
    g_customY = y;
    g_customPosition = -1;
    g_customXPercent = -1;
    g_customYPercent = -1;
    
    // 启动定时器来持续更新位置
    startPositionUpdateTimer();
    
    [self updateButtonPositionIfNeeded];
}

+ (void)configButtonPositionWithXPercent:(CGFloat)xPercent yPercent:(CGFloat)yPercent {
    g_customXPercent = xPercent;
    g_customYPercent = yPercent;
    g_customPosition = -1;
    g_customX = -1;
    g_customY = -1;
    
    // 启动定时器来持续更新位置
    startPositionUpdateTimer();
    
    [self updateButtonPositionIfNeeded];
}

+ (void)updateButtonPositionIfNeeded {
    // 通过反射获取 EZDDisplayer 实例并更新位置
    Class displayerClass = NSClassFromString(@"EZDDisplayer");
    if (displayerClass) {
        SEL sharedSelector = NSSelectorFromString(@"shared");
        if ([displayerClass respondsToSelector:sharedSelector]) {
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            id displayer = [displayerClass performSelector:sharedSelector];
            if (displayer) {
                UIButton *button = [displayer valueForKey:@"consoleEntryBtn"];
                if (button && button.window) {
                    // 直接调用更新函数
                    updateButtonPosition(button);
                }
            }
            #pragma clang diagnostic pop
        }
    }
}

@end

#endif
