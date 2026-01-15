//
//  FontManager.m
//  footBall
//
//  Created on 2026/1/15.
//

#import "FontManager.h"

@implementation FontManager

+ (instancetype)sharedManager {
    static FontManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FontManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 初始化字体（懒加载）
    }
    return self;
}

#pragma mark - 字体属性（按大小命名）

- (UIFont *)font34Bold {
    return [UIFont systemFontOfSize:34 weight:UIFontWeightBold];
}

- (UIFont *)font28Bold {
    return [UIFont systemFontOfSize:28 weight:UIFontWeightBold];
}

- (UIFont *)font22Semibold {
    return [UIFont systemFontOfSize:22 weight:UIFontWeightSemibold];
}

- (UIFont *)font18Semibold {
    return [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
}

- (UIFont *)font17Regular {
    return [UIFont systemFontOfSize:17 weight:UIFontWeightRegular];
}

- (UIFont *)font17Medium {
    return [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
}

- (UIFont *)font17Semibold {
    return [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
}

- (UIFont *)font17Bold {
    return [UIFont systemFontOfSize:17 weight:UIFontWeightBold];
}

- (UIFont *)font16Medium {
    return [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
}

- (UIFont *)font15Regular {
    return [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
}

- (UIFont *)font14Medium {
    return [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
}

- (UIFont *)font13Regular {
    return [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
}

- (UIFont *)font12Regular {
    return [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
}

#pragma mark - 便捷方法

+ (UIFont *)fontOfSize:(CGFloat)size {
    return [UIFont systemFontOfSize:size weight:UIFontWeightRegular];
}

+ (UIFont *)fontOfSize:(CGFloat)size weight:(UIFontWeight)weight {
    return [UIFont systemFontOfSize:size weight:weight];
}

+ (UIFont *)boldFontOfSize:(CGFloat)size {
    return [UIFont systemFontOfSize:size weight:UIFontWeightBold];
}

+ (UIFont *)mediumFontOfSize:(CGFloat)size {
    return [UIFont systemFontOfSize:size weight:UIFontWeightMedium];
}

@end
