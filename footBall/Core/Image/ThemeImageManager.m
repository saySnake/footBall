//
//  ThemeImageManager.m
//  footBall
//
//  Created on 2026/1/15.
//

#import "ThemeImageManager.h"
#import "ThemeManager.h"

@implementation ThemeImageManager

+ (instancetype)sharedManager {
    static ThemeImageManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ThemeImageManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 监听主题变化通知
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleThemeChange:)
                                                     name:AppThemeDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleThemeChange:(NSNotification *)notification {
    // 主题变化时，可以执行一些操作
    // 例如：清理图片缓存、通知视图更新等
}

#pragma mark - Public Methods

- (nullable UIImage *)imageNamed:(NSString *)imageName {
    if (!imageName || imageName.length == 0) {
        return nil;
    }
    
    // 获取当前主题
    ThemeManager *themeManager = [ThemeManager sharedManager];
    BOOL isDarkMode = [themeManager actualTheme] == AppThemeDark;
    
    return [self imageNamed:imageName darkMode:isDarkMode];
}

- (nullable UIImage *)imageNamed:(NSString *)imageName darkMode:(BOOL)isDarkMode {
    return [self imageNamed:imageName bundle:nil darkMode:isDarkMode];
}

- (nullable UIImage *)imageNamed:(NSString *)imageName bundle:(nullable NSBundle *)bundle darkMode:(BOOL)isDarkMode {
    if (!imageName || imageName.length == 0) {
        return nil;
    }
    
    // 获取完整的图片名称（根据主题添加后缀）
    NSString *fullImageName = [[self class] imageNameForTheme:imageName darkMode:isDarkMode];
    
    // 使用指定的 Bundle，如果为 nil 则使用 mainBundle
    NSBundle *targetBundle = bundle ?: [NSBundle mainBundle];
    
    // 加载图片
    UIImage *image = [UIImage imageNamed:fullImageName inBundle:targetBundle compatibleWithTraitCollection:nil];
    
    // 如果夜间模式的图片不存在，尝试加载白天模式的图片（降级处理）
    if (!image && isDarkMode) {
        NSString *lightImageName = [[self class] imageNameForTheme:imageName darkMode:NO];
        image = [UIImage imageNamed:lightImageName inBundle:targetBundle compatibleWithTraitCollection:nil];
    }
    
    return image;
}

+ (NSString *)imageNameForTheme:(NSString *)imageName darkMode:(BOOL)isDarkMode {
    if (!imageName || imageName.length == 0) {
        return imageName;
    }
    
    // 如果已经是夜间模式图片名称，直接返回
    if ([imageName hasSuffix:@"_night"]) {
        return imageName;
    }
    
    // 如果是夜间模式，添加 _night 后缀
    if (isDarkMode) {
        // 处理文件扩展名
        NSString *nameWithoutExtension = imageName;
        NSString *extension = @"";
        
        NSRange dotRange = [imageName rangeOfString:@"." options:NSBackwardsSearch];
        if (dotRange.location != NSNotFound) {
            nameWithoutExtension = [imageName substringToIndex:dotRange.location];
            extension = [imageName substringFromIndex:dotRange.location];
        }
        
        return [NSString stringWithFormat:@"%@_night%@", nameWithoutExtension, extension];
    }
    
    // 白天模式，直接返回原名称
    return imageName;
}

- (BOOL)imageExists:(NSString *)imageName {
    if (!imageName || imageName.length == 0) {
        return NO;
    }
    
    ThemeManager *themeManager = [ThemeManager sharedManager];
    BOOL isDarkMode = [themeManager actualTheme] == AppThemeDark;
    
    return [self imageExists:imageName darkMode:isDarkMode];
}

- (BOOL)imageExists:(NSString *)imageName darkMode:(BOOL)isDarkMode {
    if (!imageName || imageName.length == 0) {
        return NO;
    }
    
    NSString *fullImageName = [[self class] imageNameForTheme:imageName darkMode:isDarkMode];
    
    // 检查图片是否存在
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:fullImageName ofType:nil];
    if (imagePath) {
        return YES;
    }
    
    // 如果夜间模式图片不存在，检查白天模式图片是否存在
    if (isDarkMode) {
        NSString *lightImageName = [[self class] imageNameForTheme:imageName darkMode:NO];
        NSString *lightImagePath = [[NSBundle mainBundle] pathForResource:lightImageName ofType:nil];
        return lightImagePath != nil;
    }
    
    return NO;
}

@end
