//
//  PNBackendDateTime.m
//  footBall
//

#import "PNBackendDateTime.h"

@implementation PNBackendDateTime

/// 单例 NSISO8601DateFormatter（含毫秒），避免每个 cell 都新建
+ (NSISO8601DateFormatter *)isoFormatterWithFractional {
    static NSISO8601DateFormatter *fmt;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fmt = [[NSISO8601DateFormatter alloc] init];
        fmt.formatOptions = NSISO8601DateFormatWithInternetDateTime | NSISO8601DateFormatWithFractionalSeconds;
    });
    return fmt;
}

/// 单例 NSISO8601DateFormatter（无毫秒），避免每个 cell 都新建
+ (NSISO8601DateFormatter *)isoFormatterPlain {
    static NSISO8601DateFormatter *fmt;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fmt = [[NSISO8601DateFormatter alloc] init];
        fmt.formatOptions = NSISO8601DateFormatWithInternetDateTime;
    });
    return fmt;
}

/// NSDateFormatter 用 en_US_POSIX 锁定，避免 12/24 小时切换与本地化影响（QA1480）
+ (NSDateFormatter *)sharedZonedFormatter {
    static NSDateFormatter *fmt;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fmt = [[NSDateFormatter alloc] init];
        fmt.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        fmt.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
        fmt.timeZone = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
    });
    return fmt;
}

+ (NSDateFormatter *)sharedNaiveFormatter {
    static NSDateFormatter *fmt;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fmt = [[NSDateFormatter alloc] init];
        fmt.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        fmt.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
        // 无时区墙钟统一按后端约定的 Asia/Shanghai 处理
        NSTimeZone *shanghai = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
        fmt.timeZone = shanghai ?: [NSTimeZone timeZoneForSecondsFromGMT:8 * 3600];
    });
    return fmt;
}

/// 候选格式串表（仅在调试期一次性构造，避免每次 cell 都 alloc NSArray）
+ (NSArray<NSString *> *)zonedFormatStrings {
    static NSArray<NSString *> *formats;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formats = @[
            @"yyyy-MM-dd'T'HH:mm:ssZ",
            @"yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            @"yyyy-MM-dd'T'HH:mm:ssXXX",
            @"yyyy-MM-dd'T'HH:mm:ss.SSSXXX",
            @"yyyy-MM-dd'T'HH:mm:ss'Z'",
            @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
        ];
    });
    return formats;
}

+ (NSArray<NSString *> *)naiveFormatStrings {
    static NSArray<NSString *> *formats;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formats = @[
            @"yyyy-MM-dd'T'HH:mm:ss.SSS",
            @"yyyy-MM-dd'T'HH:mm:ss",
            @"yyyy-MM-dd'T'HH:mm",
            @"yyyy-MM-dd HH:mm:ss.SSS",
            @"yyyy-MM-dd HH:mm:ss",
            @"yyyy-MM-dd HH:mm",
            @"yyyy/MM/dd HH:mm:ss",
            @"yyyy/MM/dd HH:mm",
            @"yyyy-MM-dd",
        ];
    });
    return formats;
}

+ (nullable NSDate *)dateFromBackendString:(nullable NSString *)raw {
    if (raw.length == 0) return nil;
    NSString *s = [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (s.length == 0) return nil;

    BOOL allDigits = YES;
    for (NSUInteger i = 0; i < s.length; i++) {
        unichar ch = [s characterAtIndex:i];
        if (ch < '0' || ch > '9') {
            allDigits = NO;
            break;
        }
    }
    if (allDigits && s.length >= 10) {
        long long n = [s longLongValue];
        // 13 位纯数字视作毫秒时间戳（如 1700000000000）
        if (s.length == 13 && n > 1000000000000LL) {
            return [NSDate dateWithTimeIntervalSince1970:n / 1000.0];
        }
        // 10/11/12 位纯数字视作秒时间戳（标准是 10 位，但留 11/12 位兜底防止后端返回非标准长度时漏解析）
        // 注意：14 位（如 20240115120000）是 yyyyMMddHHmmss 业务日期串，不在此列，会落到后面格式化解析
        if (s.length >= 10 && s.length <= 12 && n > 1000000000LL) {
            return [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)n];
        }
    }
    if ([s containsString:@"."]) {
        NSScanner *scanner = [NSScanner scannerWithString:s];
        double v = 0;
        if ([scanner scanDouble:&v] && scanner.atEnd && v > 1e9) {
            if (v > 1e12) {
                return [NSDate dateWithTimeIntervalSince1970:v / 1000.0];
            }
            return [NSDate dateWithTimeIntervalSince1970:v];
        }
    }

    // 带时区的 ISO（含 Z / 偏移）—— 使用缓存的 formatter，避免每次 cell 都 alloc
    NSDate *d = [[self isoFormatterWithFractional] dateFromString:s];
    if (d) return d;
    d = [[self isoFormatterPlain] dateFromString:s];
    if (d) return d;

    // 复用单例 formatter，仅切换 dateFormat（不再每次 alloc + 试每种 locale）
    NSDateFormatter *fmt = [self sharedZonedFormatter];
    for (NSString *format in [self zonedFormatStrings]) {
        fmt.dateFormat = format;
        d = [fmt dateFromString:s];
        if (d) return d;
    }

    // 无时区墙钟：后端约定 UTC+8（Asia/Shanghai）
    fmt = [self sharedNaiveFormatter];
    for (NSString *format in [self naiveFormatStrings]) {
        fmt.dateFormat = format;
        d = [fmt dateFromString:s];
        if (d) return d;
    }
    return nil;
}

+ (NSDateFormatter *)displayFormatter {
    static NSDateFormatter *fmt;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fmt = [[NSDateFormatter alloc] init];
        fmt.locale = [NSLocale currentLocale];
        fmt.timeZone = [NSTimeZone localTimeZone];
    });
    return fmt;
}

@end
