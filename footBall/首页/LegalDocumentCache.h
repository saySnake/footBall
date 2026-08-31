//
//  LegalDocumentCache.h
//  footBall
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Bundle 法律文档内存缓存，避免点击协议链接时在主线程读盘、排版。
@interface LegalDocumentCache : NSObject

+ (nullable NSString *)textForResource:(NSString *)resourceName;
+ (void)preloadResources:(NSArray<NSString *> *)resourceNames;

@end

NS_ASSUME_NONNULL_END
