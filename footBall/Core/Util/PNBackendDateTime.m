//
//  PNBackendDateTime.m
//  footBall
//

#import "PNBackendDateTime.h"

@implementation PNBackendDateTime

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
        // 14 位纯数字（如 20240115120000）是 yyyyMMddHHmmss 业务日期串，不是时间戳，
        // 不能按毫秒/秒处理；只有 10 或 13 位的纯数字才视作时间戳
        if (s.length == 13 && n > 1000000000000LL) {
            return [NSDate dateWithTimeIntervalSince1970:n / 1000.0];
        }
        if (s.length == 10 && n > 1000000000LL) {
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

    // 带时区的 ISO（含 Z / 偏移）
    if (@available(iOS 11.0, *)) {
        NSISO8601DateFormatter *iso = [[NSISO8601DateFormatter alloc] init];
        iso.formatOptions = NSISO8601DateFormatWithInternetDateTime | NSISO8601DateFormatWithFractionalSeconds;
        NSDate *d = [iso dateFromString:s];
        if (d) return d;
        iso.formatOptions = NSISO8601DateFormatWithInternetDateTime;
        d = [iso dateFromString:s];
        if (d) return d;
    }

    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.locale = [NSLocale localeWithLocaleIdentifier:@"zh_CN"];

    NSArray<NSString *> *zonedFormats = @[
        @"yyyy-MM-dd'T'HH:mm:ssZ",
        @"yyyy-MM-dd'T'HH:mm:ss.SSSZ",
        @"yyyy-MM-dd'T'HH:mm:ssXXX",
        @"yyyy-MM-dd'T'HH:mm:ss.SSSXXX",
        @"yyyy-MM-dd'T'HH:mm:ss'Z'",
        @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
    ];
    for (NSString *format in zonedFormats) {
        fmt.dateFormat = format;
        fmt.timeZone = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
        NSDate *date = [fmt dateFromString:s];
        if (date) return date;
    }

    // 无时区墙钟：后端约定 UTC+8（Asia/Shanghai）
    NSTimeZone *shanghai = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"]
        ?: [NSTimeZone timeZoneForSecondsFromGMT:8 * 3600];
    fmt.timeZone = shanghai;
    NSArray<NSString *> *naiveFormats = @[
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
    for (NSString *format in naiveFormats) {
        fmt.dateFormat = format;
        NSDate *date = [fmt dateFromString:s];
        if (date) return date;
    }
    return nil;
}

+ (NSDateFormatter *)displayFormatter {
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.locale = [NSLocale currentLocale];
    fmt.timeZone = [NSTimeZone localTimeZone];
    return fmt;
}

@end
