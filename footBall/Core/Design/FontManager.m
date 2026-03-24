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

- (UIFont *)font14Bold {
    return [UIFont boldSystemFontOfSize:14.0];
}

- (UIFont *)font16Bold {
    return [UIFont boldSystemFontOfSize:16.0];
}

- (UIFont *)font18Bold {
    return [UIFont boldSystemFontOfSize:18.0];
}

- (UIFont *)font20Bold {
    return [UIFont boldSystemFontOfSize:20.0];
}

- (UIFont *)font22Bold {
    return [UIFont boldSystemFontOfSize:22.0];
}

- (UIFont *)font24Bold {
    return [UIFont boldSystemFontOfSize:24.0];
}

- (UIFont *)font26Bold {
    return [UIFont boldSystemFontOfSize:26.0];
}

- (UIFont *)font28Bold {
    return [UIFont boldSystemFontOfSize:28.0f];
}

- (UIFont *)font30Bold {
    return [UIFont boldSystemFontOfSize:30.0f];
}

- (UIFont *)font32Bold {
    return [UIFont boldSystemFontOfSize:32.0f];
}

- (UIFont *)font34Bold {
    return [UIFont boldSystemFontOfSize:34.0f];
}

- (UIFont *)font36Bold {
    return [UIFont boldSystemFontOfSize:36.0f];
}

- (UIFont *)font38Bold {
    return [UIFont boldSystemFontOfSize:38.0f];
}

- (UIFont *)font36Regular {
    return [UIFont fontWithName:@"NeueRegular" size:36.0f];
}

- (UIFont *)font34Regular {
    return [UIFont fontWithName:@"NeueRegular" size:34.0f];
}

- (UIFont *)font32Regular {
    return [UIFont fontWithName:@"NeueRegular" size:32.0f];
}

- (UIFont *)font30Regular {
    return [UIFont fontWithName:@"NeueRegular" size:30.0f];
}

- (UIFont *)font28Regular {
    return [UIFont fontWithName:@"NeueRegular" size:28.0f];
}

- (UIFont *)font26Regular {
    return [UIFont fontWithName:@"NeueRegular" size:26.0f];
}

- (UIFont *)font24Regular {
    return [UIFont fontWithName:@"NeueRegular" size:24.0f];
}

- (UIFont *)font22Regular {
    return [UIFont fontWithName:@"NeueRegular" size:22.0f];
}

- (UIFont *)font20Regular {
    return [UIFont fontWithName:@"NeueRegular" size:20.0f];
}

- (UIFont *)font18Regular {
    return [UIFont fontWithName:@"NeueRegular" size:18.0f];
}

- (UIFont *)font16Regular {
    return [UIFont fontWithName:@"NeueRegular" size:16.0f];
}

- (UIFont *)font14Regular {
    return [UIFont fontWithName:@"NeueRegular" size:14.0f];
}

- (UIFont *)font12Regular {
    return [UIFont fontWithName:@"NeueRegular" size:12.0f];
}

- (UIFont *)font10Regular {
    return [UIFont fontWithName:@"NeueRegular" size:10.0f];
}

- (UIFont *)font30 {
    return [UIFont systemFontOfSize:30];
}

- (UIFont *)font28 {
    return [UIFont systemFontOfSize:28];
}

- (UIFont *)font26 {
    return [UIFont systemFontOfSize:26];
}

- (UIFont *)font24 {
    return [UIFont systemFontOfSize:24];
}

- (UIFont *)font22 {
    return [UIFont systemFontOfSize:22];
}

- (UIFont *)font20 {
    return [UIFont systemFontOfSize:20];
}

- (UIFont *)font18 {
    return [UIFont systemFontOfSize:18];
}

- (UIFont *)font16 {
    return [UIFont systemFontOfSize:16];
}

- (UIFont *)font14 {
    return [UIFont systemFontOfSize:14];
}

- (UIFont *)font12 {
    return [UIFont systemFontOfSize:12];
}

- (UIFont *)font10 {
    return [UIFont systemFontOfSize:10];
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
