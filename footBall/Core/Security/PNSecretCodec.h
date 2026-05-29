//
//  PNSecretCodec.h
//  footBall
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 运行时还原 XOR 混淆后的字节串（仅用于避免密钥以明文出现在源码/二进制字符串表中）。
@interface PNSecretCodec : NSObject

+ (NSString *)decodeXORBytes:(const uint8_t *)bytes length:(NSUInteger)length;

@end

NS_ASSUME_NONNULL_END
