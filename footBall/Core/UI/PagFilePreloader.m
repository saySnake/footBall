//
//  PagFilePreloader.m
//  footBall
//
//  Created on 2026/1/15.
//  PAG 文件预加载管理器 - 在应用启动时预加载，避免首次使用时卡顿
//

#import "PagFilePreloader.h"
#import <libpag/PAGView.h>

@interface PagFilePreloader ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, PAGFile *> *pagFileCache;
@property (nonatomic, strong) dispatch_queue_t preloadQueue;

@end

@implementation PagFilePreloader

+ (instancetype)sharedPreloader {
    static PagFilePreloader *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PagFilePreloader alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _pagFileCache = [NSMutableDictionary dictionary];
        // 创建专用的预加载队列
        _preloadQueue = dispatch_queue_create("com.football.pag.preload", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)preloadPagFile:(NSString *)fileName {
    if (!fileName || fileName.length == 0) {
        return;
    }
    
    // 如果已经加载，直接返回
    if ([self isPagFileLoaded:fileName]) {
        return;
    }
    
    // 使用高优先级队列，确保尽快加载
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSString *filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"pag"];
        if (filePath) {
            // 在后台线程加载文件（PAGFile.Load 是线程安全的）
            PAGFile *pagFile = [PAGFile Load:filePath];
            if (pagFile) {
                // 回到主线程缓存（确保线程安全）
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.pagFileCache[fileName] = pagFile;
                    NSLog(@"✅ PAG 文件预加载成功: %@", fileName);
                });
            } else {
                NSLog(@"⚠️ PAG 文件加载失败: %@.pag", fileName);
            }
        } else {
            NSLog(@"⚠️ PAG 文件不存在: %@.pag", fileName);
        }
    });
}

- (nullable PAGFile *)getPagFile:(NSString *)fileName {
    if (!fileName || fileName.length == 0) {
        return nil;
    }
    
    return self.pagFileCache[fileName];
}

- (BOOL)isPagFileLoaded:(NSString *)fileName {
    if (!fileName || fileName.length == 0) {
        return NO;
    }
    
    return self.pagFileCache[fileName] != nil;
}

- (void)preloadRefreshHeaderFiles {
    // 预加载刷新头部所需的文件
    [self preloadPagFile:@"loading_1"];
    [self preloadPagFile:@"loading_1"];
}

@end
