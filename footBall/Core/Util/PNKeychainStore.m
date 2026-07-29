//
//  PNKeychainStore.m
//  footBall
//

#import "PNKeychainStore.h"
#import <Security/Security.h>

@implementation PNKeychainStore

+ (NSString *)serviceName {
    static NSString *service;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
        service = bundleId.length ? [bundleId stringByAppendingString:@".keychain"] : @"footBall.keychain";
    });
    return service;
}

+ (NSMutableDictionary *)baseQueryForKey:(NSString *)key {
    return [@{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: [self serviceName],
        (__bridge id)kSecAttrAccount: key ?: @"",
    } mutableCopy];
}

+ (BOOL)setData:(NSData *)data forKey:(NSString *)key {
    if (!key.length || !data) {
        return NO;
    }

    NSMutableDictionary *query = [self baseQueryForKey:key];
    SecItemDelete((__bridge CFDictionaryRef)query);

    query[(__bridge id)kSecValueData] = data;
    query[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly;

    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    if (status != errSecSuccess) {
        NSLog(@"PNKeychainStore: SecItemAdd failed (%d) for key %@", (int)status, key);
        return NO;
    }
    return YES;
}

+ (nullable NSData *)dataForKey:(NSString *)key {
    if (!key.length) {
        return nil;
    }

    NSMutableDictionary *query = [self baseQueryForKey:key];
    query[(__bridge id)kSecReturnData] = @YES;
    query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;

    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    if (status != errSecSuccess || !result) {
        return nil;
    }
    return (__bridge_transfer NSData *)result;
}

+ (BOOL)setString:(NSString *)string forKey:(NSString *)key {
    if (!string) {
        return [self removeItemForKey:key];
    }
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    return [self setData:data forKey:key];
}

+ (nullable NSString *)stringForKey:(NSString *)key {
    NSData *data = [self dataForKey:key];
    if (!data.length) {
        return nil;
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (BOOL)removeItemForKey:(NSString *)key {
    if (!key.length) {
        return NO;
    }
    NSMutableDictionary *query = [self baseQueryForKey:key];
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
    return (status == errSecSuccess || status == errSecItemNotFound);
}

@end
