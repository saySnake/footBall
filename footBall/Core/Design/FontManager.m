//
//  FontManager.m
//  footBall
//
//  Created on 2026/1/15.
//

#import "FontManager.h"
#import <CoreText/CoreText.h>

static NSString *FontManagerNeuePostScriptName(void) {
    static NSString *name = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *path = [[NSBundle mainBundle] pathForResource:@"NeueRegular" ofType:@"ttf"];
        if (path.length == 0) {
            // 字体文件未打包进 App（需要把 NeueRegular.ttf 加入 Copy Bundle Resources）
            name = @"NeueRegular";
            return;
        }

        NSURL *url = [NSURL fileURLWithPath:path];
        CFErrorRef error = NULL;
        CTFontManagerRegisterFontsForURL((__bridge CFURLRef)url, kCTFontManagerScopeProcess, &error);
        if (error) {
            CFRelease(error);
            name = @"NeueRegular";
            return;
        }

        NSArray *descriptors = CFBridgingRelease(CTFontManagerCreateFontDescriptorsFromURL((__bridge CFURLRef)url));
        NSDictionary *attrs = descriptors.firstObject ? [descriptors.firstObject fontAttributes] : nil;
        NSString *psName = attrs[(__bridge NSString *)kCTFontNameAttribute];
        name = psName.length ? psName : @"NeueRegular";
    });
    return name;
}

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
        // 触发字体注册（确保后续 fontWithName 可用）
        (void)FontManagerNeuePostScriptName();
    }
    return self;
}

- (UIFont *)neueFontOfSize:(CGFloat)size fallbackWeight:(UIFontWeight)weight {
    UIFont *f = [UIFont fontWithName:FontManagerNeuePostScriptName() size:size];
    if (f) return f;
    // 兼容少量字体内部名不一致的情况
    f = [UIFont fontWithName:@"NeueRegular" size:size];
    if (f) return f;
    f = [UIFont fontWithName:@"Neue-Regular" size:size];
    if (f) return f;
    return [UIFont systemFontOfSize:size weight:weight];
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
    return [self neueFontOfSize:36.0f fallbackWeight:UIFontWeightRegular];
}

- (UIFont *)font34Regular {
    return [self neueFontOfSize:34.0f fallbackWeight:UIFontWeightRegular];
}

- (UIFont *)font32Regular {
    return [self neueFontOfSize:32.0f fallbackWeight:UIFontWeightRegular];
}

- (UIFont *)font30Regular {
    return [self neueFontOfSize:30.0f fallbackWeight:UIFontWeightRegular];
}

- (UIFont *)font28Regular {
    return [self neueFontOfSize:28.0f fallbackWeight:UIFontWeightRegular];
}

- (UIFont *)font26Regular {
    return [self neueFontOfSize:26.0f fallbackWeight:UIFontWeightRegular];
}

- (UIFont *)font24Regular {
    return [self neueFontOfSize:24.0f fallbackWeight:UIFontWeightRegular];
}

- (UIFont *)font22Regular {
    return [self neueFontOfSize:22.0f fallbackWeight:UIFontWeightRegular];
}

- (UIFont *)font20Regular {
    return [self neueFontOfSize:20.0f fallbackWeight:UIFontWeightRegular];
}

- (UIFont *)font18Regular {
    return [self neueFontOfSize:18.0f fallbackWeight:UIFontWeightRegular];
}

- (UIFont *)font16Regular {
    return [self neueFontOfSize:16.0f fallbackWeight:UIFontWeightRegular];
}

- (UIFont *)font14Regular {
    return [self neueFontOfSize:14.0f fallbackWeight:UIFontWeightRegular];
}

- (UIFont *)font12Regular {
    return [self neueFontOfSize:12.0f fallbackWeight:UIFontWeightRegular];
}

- (UIFont *)font10Regular {
    return [self neueFontOfSize:10.0f fallbackWeight:UIFontWeightRegular];
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
