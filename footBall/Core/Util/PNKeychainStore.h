//
//  PNKeychainStore.h
//  footBall
//
//  Keychain 封装：系统加密存储敏感字符串 / 数据。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PNKeychainStore : NSObject

+ (BOOL)setData:(NSData *)data forKey:(NSString *)key;
+ (nullable NSData *)dataForKey:(NSString *)key;

+ (BOOL)setString:(NSString *)string forKey:(NSString *)key;
+ (nullable NSString *)stringForKey:(NSString *)key;

+ (BOOL)removeItemForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
