//
//  LegalDocumentCache.m
//  footBall
//

#import "LegalDocumentCache.h"

@implementation LegalDocumentCache

+ (NSMutableDictionary<NSString *, NSString *> *)cache {
    static NSMutableDictionary<NSString *, NSString *> *store;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [NSMutableDictionary dictionary];
    });
    return store;
}

+ (dispatch_queue_t)ioQueue {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.nomad.football.legal.cache", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

+ (nullable NSString *)loadTextFromBundleForResource:(NSString *)resourceName {
    if (resourceName.length == 0) return nil;
    NSBundle *bundle = NSBundle.mainBundle;
    NSArray<NSString *> *subdirs = @[ @"Resources/Legal", @"Legal" ];
    for (NSString *subdir in subdirs) {
        NSString *path = [bundle pathForResource:resourceName ofType:@"txt" inDirectory:subdir];
        if (path.length) {
            NSString *text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
            if (text.length) return text;
        }
    }
    NSString *path = [bundle pathForResource:resourceName ofType:@"txt"];
    if (path.length) {
        return [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    }
    return nil;
}

+ (nullable NSString *)textForResource:(NSString *)resourceName {
    if (resourceName.length == 0) return nil;
    NSString *cached = self.cache[resourceName];
    if (cached.length) return cached;
    NSString *text = [self loadTextFromBundleForResource:resourceName];
    if (text.length) self.cache[resourceName] = text;
    return text;
}

+ (void)preloadResources:(NSArray<NSString *> *)resourceNames {
    if (resourceNames.count == 0) return;
    dispatch_async(self.ioQueue, ^{
        for (NSString *name in resourceNames) {
            if (name.length == 0 || self.cache[name].length) continue;
            NSString *text = [self loadTextFromBundleForResource:name];
            if (text.length) self.cache[name] = text;
        }
    });
}

@end
