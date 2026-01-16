//
//  UINavigationController+NavigationBar.m
//  footBall
//
//  Created on 2026/1/15.
//  UINavigationController 导航栏扩展 - 提供便捷的导航栏配置方法
//

#import "UINavigationController+NavigationBar.h"

@implementation UINavigationController (NavigationBar)

#pragma mark - 便捷配置方法

- (void)applyDefaultNavigationBarStyle {
    [[NavigationBarManager sharedManager] applyDefaultStyleToNavigationBar:self.navigationBar];
}

- (void)applyNavigationBarStyle:(NavigationBarConfig *)config {
    [[NavigationBarManager sharedManager] applyStyle:config toNavigationBar:self.navigationBar];
}

- (void)setNavigationBarTitle:(NSString *)title
                     withFont:(UIFont *)font
                        color:(UIColor *)color {
    [[NavigationBarManager sharedManager] setTitle:title
                                  forNavigationBar:self.navigationBar
                                          withFont:font
                                             color:color];
}

- (void)setNavigationBarBackgroundColor:(UIColor *)backgroundColor
                         backgroundImage:(UIImage *)backgroundImage
                             translucent:(BOOL)translucent {
    [[NavigationBarManager sharedManager] setBackgroundColor:backgroundColor
                                              backgroundImage:backgroundImage
                                                   translucent:translucent
                                             forNavigationBar:self.navigationBar];
}

- (void)setNavigationBarTintColor:(UIColor *)tintColor {
    [[NavigationBarManager sharedManager] setTintColor:tintColor forNavigationBar:self.navigationBar];
}

- (void)setNavigationBarShadowHidden:(BOOL)hideShadow
                           shadowColor:(UIColor *)shadowColor {
    [[NavigationBarManager sharedManager] setShadowHidden:hideShadow
                                                shadowColor:shadowColor
                                          forNavigationBar:self.navigationBar];
}

- (void)resetNavigationBarStyle {
    [[NavigationBarManager sharedManager] resetNavigationBar:self.navigationBar];
}

#pragma mark - 适配信息

- (CGFloat)adaptiveNavigationBarHeight {
    return [NavigationBarManager adaptiveNavigationBarHeightForNavigationController:self];
}

- (CGFloat)safeAreaTopHeight {
    return [NavigationBarManager safeAreaTopHeightForNavigationController:self];
}

- (BOOL)isLandscape {
    UIViewController *topViewController = self.topViewController;
    return [NavigationBarManager isLandscapeForViewController:topViewController];
}

@end
