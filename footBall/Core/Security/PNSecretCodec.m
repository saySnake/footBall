//
//  PNSecretCodec.m
//  footBall
//

#import "PNSecretCodec.h"

static const uint8_t kPNXORMask = 0xA5;

/// XOR 种子（与 kPNXORMask 异或后拼接为解码密钥）
static const uint8_t kPNXORSeedEnc[] = {
    0xF5, 0xC4, 0xD6, 0xD6, 0xEB, 0xCA, 0xC8, 0xC4, 0xC1, 0xE3,
    0xCA, 0xCA, 0xD1, 0xC7, 0xC4, 0xC9, 0xC9, 0x97, 0x95, 0x97, 0x93
};

static NSString *PNXORSeedKey(void) {
    NSUInteger len = sizeof(kPNXORSeedEnc);
    NSMutableString *key = [NSMutableString stringWithCapacity:len];
    for (NSUInteger i = 0; i < len; i++) {
        unichar c = (unichar)(kPNXORSeedEnc[i] ^ kPNXORMask);
        [key appendFormat:@"%C", c];
    }
    return [key copy];
}

@implementation PNSecretCodec

+ (NSString *)decodeXORBytes:(const uint8_t *)bytes length:(NSUInteger)length {
    if (!bytes || length == 0) {
        return @"";
    }
    NSString *seed = PNXORSeedKey();
    NSUInteger seedLen = seed.length;
    if (seedLen == 0) {
        return @"";
    }
    NSMutableString *plain = [NSMutableString stringWithCapacity:length];
    for (NSUInteger i = 0; i < length; i++) {
        unichar c = (unichar)(bytes[i] ^ [seed characterAtIndex:(i % seedLen)]);
        [plain appendFormat:@"%C", c];
    }
    return [plain copy];
}

@end
