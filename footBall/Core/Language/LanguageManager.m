//
//  LanguageManager.m
//  footBall
//
//  Created on 2026/1/15.
//

#import "LanguageManager.h"

NSString *const AppLanguageDidChangeNotification = @"AppLanguageDidChangeNotification";

static NSString *const kUserDefaultsLanguageKey = @"AppCurrentLanguage";

@interface LanguageManager ()

@property (nonatomic, strong) NSBundle *currentBundle;
// 在类扩展中重新声明为 readwrite，以便内部修改
@property (nonatomic, strong, readwrite, nullable) NSString *currentLanguageCode;

@end

@implementation LanguageManager

+ (instancetype)sharedManager {
    static LanguageManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LanguageManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 从UserDefaults读取保存的语言设置
        NSInteger savedLanguage = [[NSUserDefaults standardUserDefaults] integerForKey:kUserDefaultsLanguageKey];
        if (savedLanguage > 0) {
            _currentLanguage = (AppLanguage)savedLanguage;
        } else {
            _currentLanguage = AppLanguageSystem;
        }
        
        [self updateLanguageBundle];
    }
    return self;
}

- (void)setLanguage:(AppLanguage)language {
    AppLanguage oldLanguage = _currentLanguage;
    if (oldLanguage == language) {
        return;
    }
    
    _currentLanguage = language;
    
    // 保存到UserDefaults
    [[NSUserDefaults standardUserDefaults] setInteger:language forKey:kUserDefaultsLanguageKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // 更新语言包
    [self updateLanguageBundle];
    
    NSLog(@"🌐 语言切换: %@ -> %@", 
          [LanguageManager displayNameForLanguage:oldLanguage],
          [LanguageManager displayNameForLanguage:language]);
    
    // 在主线程发送通知，确保UI更新在主线程
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:AppLanguageDidChangeNotification object:nil userInfo:@{@"language": @(language)}];
    });
}

- (void)updateLanguageBundle {
    NSString *languageCode = [self languageCodeForLanguage:self.currentLanguage];
    self.currentLanguageCode = languageCode;
    
    NSString *path = [[NSBundle mainBundle] pathForResource:languageCode ofType:@"lproj"];
    if (path) {
        self.currentBundle = [NSBundle bundleWithPath:path];
        NSLog(@"✅ 语言切换成功: %@, Bundle路径: %@", languageCode, path);
    } else {
        // 如果找不到对应的语言包，尝试使用 Base.lproj（通常包含英文）
        NSString *basePath = [[NSBundle mainBundle] pathForResource:@"Base" ofType:@"lproj"];
        if (basePath && [languageCode isEqualToString:@"en"]) {
            // 如果是英文且找不到 en.lproj，使用 Base.lproj
            self.currentBundle = [NSBundle bundleWithPath:basePath];
            NSLog(@"✅ 使用 Base.lproj 作为英文语言包: %@", basePath);
        } else {
            // 否则使用主Bundle
            self.currentBundle = [NSBundle mainBundle];
            NSLog(@"⚠️ 未找到语言包: %@, 使用默认Bundle", languageCode);
        }
    }
}

- (NSString *)languageCodeForLanguage:(AppLanguage)language {
    switch (language) {
        case AppLanguageSystem: {
            // 获取系统语言
            NSArray *preferredLanguages = [NSLocale preferredLanguages];
            NSString *systemLanguage = preferredLanguages.firstObject;
            
            if ([systemLanguage hasPrefix:@"zh-Hans"]) {
                return @"zh-Hans";
            } else if ([systemLanguage hasPrefix:@"zh-Hant"] || [systemLanguage hasPrefix:@"zh-HK"] || [systemLanguage hasPrefix:@"zh-TW"]) {
                return @"zh-Hant";
            } else {
                return @"en";
            }
        }
        case AppLanguageChinese:
            return @"zh-Hans";
        case AppLanguageEnglish:
            return @"en";
        case AppLanguageTraditionalChinese:
            return @"zh-Hant";
        default:
            return @"en";
    }
}

+ (NSString *)localizedStringForKey:(NSString *)key comment:(NSString *)comment {
    LanguageManager *manager = [LanguageManager sharedManager];
    
    if (!key || key.length == 0) {
        return @"";
    }
    
    NSString *localizedString = nil;
    
    // 优先使用当前语言包
    if (manager.currentBundle) {
        // 使用 key 作为默认值，如果找不到就返回 key
        localizedString = [manager.currentBundle localizedStringForKey:key value:key table:nil];
        // 如果找到了本地化字符串且不等于key，返回它
        if (localizedString && localizedString.length > 0 && ![localizedString isEqualToString:key]) {
            return localizedString;
        }
    }
    
    // 如果当前语言包找不到，尝试从主Bundle查找
    localizedString = [[NSBundle mainBundle] localizedStringForKey:key value:key table:nil];
    if (localizedString && localizedString.length > 0 && ![localizedString isEqualToString:key]) {
        return localizedString;
    }
    
    // 如果都找不到，返回key本身（避免返回nil）
    return key ?: @"";
}

+ (NSString *)localizedStringForKey:(NSString *)key arguments:(NSArray *)arguments {
    NSString *format = [self localizedStringForKey:key comment:nil];
    
    if (arguments && arguments.count > 0) {
        return [NSString stringWithFormat:format, arguments];
    }
    
    return format;
}

+ (NSArray<NSString *> *)supportedLanguages {
    return @[@"zh-Hans", @"en", @"zh-Hant"];
}

+ (NSString *)displayNameForLanguage:(AppLanguage)language {
    // 根据当前设置的语言返回对应的显示名称
    switch (language) {
        case AppLanguageSystem:
            return L(@"language_system");
        case AppLanguageChinese:
            return L(@"language_chinese");
        case AppLanguageEnglish:
            return @"English";
        case AppLanguageTraditionalChinese:
            return L(@"language_traditional_chinese");
        default:
            return @"English";
    }
}

@end
