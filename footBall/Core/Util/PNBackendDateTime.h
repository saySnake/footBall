//
//  PNBackendDateTime.h
//  footBall
//
//  后端无时区墙钟时间（如 matchDate = 2026-04-25T03:00:00）约定为东八区；
//  解析为 NSDate 后，UI 展示须使用手机系统时区。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PNBackendDateTime : NSObject

/// 后端时间串 → NSDate。无时区后缀按 Asia/Shanghai；带 Z/偏移按串内时区；Unix 时间戳为绝对时间。
+ (nullable NSDate *)dateFromBackendString:(nullable NSString *)raw;

/// 展示用 formatter：已设 currentLocale + localTimeZone（可再改 dateFormat）
+ (NSDateFormatter *)displayFormatter;

@end

NS_ASSUME_NONNULL_END
