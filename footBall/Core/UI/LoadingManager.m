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

// 用 NSMapTable 弱引用 view 作 key：view dealloc 时条目自动失效，避免 dangling 残留；
// 同时也避免循环引用（HUD 强持有 view，cache 再强持有 view 会形成 cache↔view 环）。
@property (nonatomic, strong) NSMapTable<UIView *, MBProgressHUD *> *hudCache;

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
        // keyOptions 弱引用、valueOptions 强引用：HUD 由 cache 持有，view dealloc 后条目自动清理
        _hudCache = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsWeakMemory valueOptions:NSPointerFunctionsStrongMemory];
    }
    return self;
}

#pragma mark - Private Methods

/// 获取或创建 HUD
- (MBProgressHUD *)hudForView:(UIView *)view {
    MBProgressHUD *hud = [self.hudCache objectForKey:view];

    if (!hud) {
        hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
        [self.hudCache setObject:hud forKey:view];
    }

    return hud;
}

/// 移除 HUD
- (void)removeHudForView:(UIView *)view {
    MBProgressHUD *hud = [self.hudCache objectForKey:view];

    if (hud) {
        [hud hideAnimated:YES];
        [self.hudCache removeObjectForKey:view];
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
    // NSMapTable 用 keyEnumerator 遍历所有 key（UIView *），逐个移除 HUD
    NSEnumerator<UIView *> *keys = [self.hudCache keyEnumerator];
    for (UIView *key in keys) {
        MBProgressHUD *hud = [self.hudCache objectForKey:key];
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

- (void)showCenteredText:(NSString *)message inView:(UIView *)view {
    [self showText:message inView:view mode:MBProgressHUDModeText iconName:nil duration:2.0 centered:YES];
}

/// 显示文本提示（内部方法）
- (void)showText:(NSString *)message inView:(UIView *)view mode:(MBProgressHUDMode)mode duration:(NSTimeInterval)duration {
    [self showText:message inView:view mode:mode iconName:nil duration:duration centered:NO];
}

/// 显示文本提示（内部方法，支持图标）
- (void)showText:(NSString *)message inView:(UIView *)view mode:(MBProgressHUDMode)mode iconName:(nullable NSString *)iconName {
    [self showText:message inView:view mode:mode iconName:iconName duration:2.0 centered:NO];
}

/// 显示文本提示（内部方法，支持图标和时长）
- (void)showText:(NSString *)message inView:(UIView *)view mode:(MBProgressHUDMode)mode iconName:(nullable NSString *)iconName duration:(NSTimeInterval)duration {
    [self showText:message inView:view mode:mode iconName:iconName duration:duration centered:NO];
}

- (void)showText:(NSString *)message inView:(UIView *)view mode:(MBProgressHUDMode)mode iconName:(nullable NSString *)iconName duration:(NSTimeInterval)duration centered:(BOOL)centered {
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
        hud.offset = centered ? CGPointZero : CGPointMake(0, MBProgressMaxOffset);
    }
    
    // 自动隐藏
    [hud hideAnimated:YES afterDelay:duration];
}

/// 根据名称获取图标
- (nullable UIImage *)iconForName:(NSString *)iconName {
    // success/error/info 优先使用系统图标（避免项目资源图尺寸不规整导致观感“变形”）
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

    // 其它名称再从资源中加载
    UIImage *icon = [UIImage imageNamed:iconName];
    if (icon) {
        return icon;
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
