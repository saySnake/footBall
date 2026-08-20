//
//  LanguageManager.m
//  footBall
//
//  Created on 2026/1/15.
//

#import "LanguageManager.h"
#import <objc/runtime.h>

// 下方 LanguageManager (ForceChineseTemp) category 提供的临时方法，前向声明供 NSBundle category 使用
@interface LanguageManager (ForceChineseTemp)
+ (NSBundle *)fc_temp_zhHansBundle;
@end

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
        // ⚠️ 临时：强制简体中文，不读取用户设置、不跟随系统。
        // 原因：英文 / 繁中语言文件尚未校对完成，统一显示中文。
        // 待所有语言文件校对完成后，恢复为下方注释中的原逻辑即可。
        _currentLanguage = AppLanguageChinese;
        [self updateLanguageBundle];

        // 原逻辑（恢复时启用）：
        // NSInteger savedLanguage = [[NSUserDefaults standardUserDefaults] integerForKey:kUserDefaultsLanguageKey];
        // if (savedLanguage > 0) {
        //     _currentLanguage = (AppLanguage)savedLanguage;
        // } else {
        //     _currentLanguage = AppLanguageSystem;
        // }
        // [self updateLanguageBundle];
    }
    return self;
}

- (void)setLanguage:(AppLanguage)language {
    // ⚠️ 临时：拦截一切切换请求，统一中文。
    // 待语言文件校对完成后删除此 if 块，恢复用户可切换。
    if (language != AppLanguageChinese) {
        NSLog(@"🌐 语言切换被拦截（临时统一中文）：请求=%@，已忽略。",
              [LanguageManager displayNameForLanguage:language]);
        language = AppLanguageChinese;
    }

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
    return [self stringWithFormat:format arguments:arguments];
}

+ (NSString *)stringWithFormat:(NSString *)format arguments:(NSArray *)arguments {
    if (!arguments || arguments.count == 0) {
        return format;
    }
    switch (arguments.count) {
        case 1: return [NSString stringWithFormat:format, arguments[0]];
        case 2: return [NSString stringWithFormat:format, arguments[0], arguments[1]];
        case 3: return [NSString stringWithFormat:format, arguments[0], arguments[1], arguments[2]];
        case 4: return [NSString stringWithFormat:format, arguments[0], arguments[1], arguments[2], arguments[3]];
        case 5: return [NSString stringWithFormat:format, arguments[0], arguments[1], arguments[2], arguments[3], arguments[4]];
        default: return format;
    }
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

// ============================================================================
// ⚠️ 临时：强制所有 NSLocalizedString 走 zh-Hans 语言包（当次启动立即生效）。
// 原因：全 App 约五百处 NSLocalizedString 直接跟随系统语言，英文/繁中系统下
// 整个界面显示英文（英文语言文件尚未校对完成）。LanguageManager 的 L() 宏
// 已强制中文，但覆盖不到这些调用点；main.m 写 AppleLanguages 对当次启动无效。
// 原理：方法交换后，任何 NSBundle 的本地化查询都转发到 zh-Hans.lproj 对应包。
// 待语言文件校对完成后，删除下面两个 category 即可恢复"跟随系统语言"。
// ============================================================================
@implementation NSBundle (ForceChinese)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method original = class_getInstanceMethod(self, @selector(localizedStringForKey:value:table:));
        Method swizzled = class_getInstanceMethod(self, @selector(fc_temp_localizedStringForKey:value:table:));
        if (original && swizzled) {
            method_exchangeImplementations(original, swizzled);
        }
    });
}

- (NSString *)fc_temp_localizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName {
    NSBundle *zh = [LanguageManager fc_temp_zhHansBundle];
    // 已是 zh-Hans 包时按原逻辑走（方法已交换，此调用即原始实现），避免死循环
    if (self == zh) {
        return [self fc_temp_localizedStringForKey:key value:value table:tableName];
    }

    // 其余包（主包/en/zh-Hant/Base 等）一律改查 zh-Hans 包；
    // 注意主包本身在英文系统下也会返回英文，所以主包同样要重定向
    NSString *result = [zh fc_temp_localizedStringForKey:key value:value table:tableName];
    if (result.length > 0 && ![result isEqualToString:key]) {
        return result;
    }
    // zh-Hans 包里也找不到（key 只存在于其他语言文件），回退查原包
    result = [self fc_temp_localizedStringForKey:key value:value table:tableName];
    if (result.length > 0 && ![result isEqualToString:key]) {
        return result;
    }
    return value ?: key;
}

@end

@implementation LanguageManager (ForceChineseTemp)

+ (NSBundle *)fc_temp_zhHansBundle {
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *path = [[NSBundle mainBundle] pathForResource:@"zh-Hans" ofType:@"lproj"];
        bundle = path ? [NSBundle bundleWithPath:path] : [NSBundle mainBundle];
    });
    bundle = bundle ?: [NSBundle mainBundle];
    return bundle;
}

@end
