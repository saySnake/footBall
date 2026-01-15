//
//  LoadingManager.m
//  footBall
//
//  Created on 2026/1/15.
//  加载提示管理器 - 封装 MBProgressHUD，提供统一的加载提示 API
//

#import "LoadingManager.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import "LanguageManager.h"

@interface LoadingManager ()

@property (nonatomic, strong) NSMutableDictionary<NSValue *, MBProgressHUD *> *hudCache; // 缓存 HUD 实例

@end

@implementation LoadingManager

+ (instancetype)sharedManager {
    static LoadingManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LoadingManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _hudCache = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Private Methods

/// 获取视图的 key（用于缓存）
- (NSValue *)keyForView:(UIView *)view {
    return [NSValue valueWithNonretainedObject:view];
}

/// 获取或创建 HUD
- (MBProgressHUD *)hudForView:(UIView *)view {
    NSValue *key = [self keyForView:view];
    MBProgressHUD *hud = self.hudCache[key];
    
    if (!hud) {
        hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
        self.hudCache[key] = hud;
    }
    
    return hud;
}

/// 移除 HUD
- (void)removeHudForView:(UIView *)view {
    NSValue *key = [self keyForView:view];
    MBProgressHUD *hud = self.hudCache[key];
    
    if (hud) {
        [hud hideAnimated:YES];
        [self.hudCache removeObjectForKey:key];
    }
}

/// 获取 keyWindow
- (UIWindow *)keyWindow {
    UIWindow *keyWindow = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *windowScene in [UIApplication sharedApplication].connectedScenes) {
            if ([windowScene isKindOfClass:[UIWindowScene class]]) {
                for (UIWindow *window in windowScene.windows) {
                    if (window.isKeyWindow) {
                        keyWindow = window;
                        break;
                    }
                }
                if (keyWindow) break;
            }
        }
    } else {
        keyWindow = [UIApplication sharedApplication].keyWindow;
    }
    return keyWindow;
}

#pragma mark - 加载提示

- (void)showLoadingInView:(UIView *)view {
    [self showLoadingWithMessage:nil inView:view];
}

- (void)showLoadingWithMessage:(NSString *)message inView:(UIView *)view {
    if (!view) {
        NSLog(@"⚠️ LoadingManager: view 不能为 nil");
        return;
    }
    
    // 先隐藏之前的 HUD
    [self hideLoadingInView:view];
    
    MBProgressHUD *hud = [self hudForView:view];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.label.text = message ?: [LanguageManager localizedStringForKey:@"loading" comment:nil];
    hud.label.numberOfLines = 0;
}

- (void)hideLoadingInView:(UIView *)view {
    if (!view) {
        return;
    }
    
    [self removeHudForView:view];
}

- (void)hideAllLoading {
    NSArray *keys = [self.hudCache.allKeys copy];
    for (NSValue *key in keys) {
        MBProgressHUD *hud = self.hudCache[key];
        [hud hideAnimated:YES];
    }
    [self.hudCache removeAllObjects];
}

#pragma mark - 文本提示（Toast）

- (void)showSuccess:(NSString *)message inView:(UIView *)view {
    [self showText:message inView:view mode:MBProgressHUDModeCustomView iconName:@"success" duration:1.5];
}

- (void)showError:(NSString *)message inView:(UIView *)view {
    [self showText:message inView:view mode:MBProgressHUDModeCustomView iconName:@"error" duration:2.0];
}

- (void)showInfo:(NSString *)message inView:(UIView *)view {
    [self showText:message inView:view mode:MBProgressHUDModeCustomView iconName:@"info" duration:2.0];
}

- (void)showText:(NSString *)message inView:(UIView *)view {
    [self showText:message inView:view duration:2.0];
}

- (void)showText:(NSString *)message inView:(UIView *)view duration:(NSTimeInterval)duration {
    [self showText:message inView:view mode:MBProgressHUDModeText duration:duration];
}

/// 显示文本提示（内部方法）
- (void)showText:(NSString *)message inView:(UIView *)view mode:(MBProgressHUDMode)mode duration:(NSTimeInterval)duration {
    [self showText:message inView:view mode:mode iconName:nil duration:duration];
}

/// 显示文本提示（内部方法，支持图标）
- (void)showText:(NSString *)message inView:(UIView *)view mode:(MBProgressHUDMode)mode iconName:(nullable NSString *)iconName {
    [self showText:message inView:view mode:mode iconName:iconName duration:2.0];
}

/// 显示文本提示（内部方法，支持图标和时长）
- (void)showText:(NSString *)message inView:(UIView *)view mode:(MBProgressHUDMode)mode iconName:(nullable NSString *)iconName duration:(NSTimeInterval)duration {
    if (!view) {
        NSLog(@"⚠️ LoadingManager: view 不能为 nil");
        return;
    }
    
    if (!message || message.length == 0) {
        return;
    }
    
    // 先隐藏之前的加载提示
    [self hideLoadingInView:view];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.mode = mode;
    hud.label.text = message;
    hud.label.numberOfLines = 0;
    hud.margin = 16.0;
    hud.removeFromSuperViewOnHide = YES;
    
    // 设置自定义图标
    if (iconName && mode == MBProgressHUDModeCustomView) {
        UIImage *icon = [self iconForName:iconName];
        if (icon) {
            UIImageView *iconView = [[UIImageView alloc] initWithImage:icon];
            iconView.contentMode = UIViewContentModeScaleAspectFit;
            iconView.frame = CGRectMake(0, 0, 48, 48);
            hud.customView = iconView;
        } else {
            // 如果没有找到图标，使用文本模式
            hud.mode = MBProgressHUDModeText;
        }
    }
    
    // 根据模式设置不同的样式
    if (mode == MBProgressHUDModeText) {
        hud.offset = CGPointMake(0, MBProgressMaxOffset);
    }
    
    // 自动隐藏
    [hud hideAnimated:YES afterDelay:duration];
}

/// 根据名称获取图标
- (nullable UIImage *)iconForName:(NSString *)iconName {
    // 先尝试从资源中加载
    UIImage *icon = [UIImage imageNamed:iconName];
    if (icon) {
        return icon;
    }
    
    // 使用系统图标（SF Symbols）
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:48 weight:UIImageSymbolWeightMedium];
        
        if ([iconName isEqualToString:@"success"]) {
            return [UIImage systemImageNamed:@"checkmark.circle.fill" withConfiguration:config];
        } else if ([iconName isEqualToString:@"error"]) {
            return [UIImage systemImageNamed:@"xmark.circle.fill" withConfiguration:config];
        } else if ([iconName isEqualToString:@"info"]) {
            return [UIImage systemImageNamed:@"info.circle.fill" withConfiguration:config];
        }
    }
    
    return nil;
}

#pragma mark - 便捷方法（使用 keyWindow）

- (void)showLoading {
    UIWindow *keyWindow = [self keyWindow];
    if (keyWindow) {
        [self showLoadingInView:keyWindow];
    }
}

- (void)showLoadingWithMessage:(NSString *)message {
    UIWindow *keyWindow = [self keyWindow];
    if (keyWindow) {
        [self showLoadingWithMessage:message inView:keyWindow];
    }
}

- (void)hideLoading {
    UIWindow *keyWindow = [self keyWindow];
    if (keyWindow) {
        [self hideLoadingInView:keyWindow];
    }
}

- (void)showSuccess:(NSString *)message {
    UIWindow *keyWindow = [self keyWindow];
    if (keyWindow) {
        [self showSuccess:message inView:keyWindow];
    }
}

- (void)showError:(NSString *)message {
    UIWindow *keyWindow = [self keyWindow];
    if (keyWindow) {
        [self showError:message inView:keyWindow];
    }
}

- (void)showInfo:(NSString *)message {
    UIWindow *keyWindow = [self keyWindow];
    if (keyWindow) {
        [self showInfo:message inView:keyWindow];
    }
}

- (void)showText:(NSString *)message {
    UIWindow *keyWindow = [self keyWindow];
    if (keyWindow) {
        [self showText:message inView:keyWindow];
    }
}

@end
