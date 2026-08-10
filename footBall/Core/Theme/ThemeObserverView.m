//
//  ThemeObserverView.m
//  footBall
//
//  Created on 2026/1/15.
//  主题监听视图 - 历史遗留
//
//  说明：早期实现里这个视图用于监听系统主题变化（"跟随系统"模式），
//  并把系统主题当作 App 主题广播出去，从而造成“两套夜间模式”的 bug。
//  现在主题已改为 App 内部独立开关，不响应系统主题变化，这里保留空实现
//  以兼容 SceneDelegate 的引用。
//

#import "ThemeObserverView.h"

@implementation ThemeObserverView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.hidden = YES;
        self.userInteractionEnabled = NO;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

@end
