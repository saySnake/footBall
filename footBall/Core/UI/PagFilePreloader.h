//
//  PagFilePreloader.h
//  footBall
//
//  Created on 2026/1/15.
//  PAG 文件预加载管理器 - 在应用启动时预加载，避免首次使用时卡顿
//

#import <Foundation/Foundation.h>

@class PAGFile;

NS_ASSUME_NONNULL_BEGIN

/// PAG 文件预加载管理器
@interface PagFilePreloader : NSObject

/// 单例
+ (instancetype)sharedPreloader;

/// 预加载 PAG 文件（异步，不阻塞主线程）
/// @param fileName 文件名（不含扩展名）
- (void)preloadPagFile:(NSString *)fileName;

/// 获取已加载的 PAG 文件
/// @param fileName 文件名（不含扩展名）
/// @return PAGFile 对象，如果未加载则返回 nil
- (nullable PAGFile *)getPagFile:(NSString *)fileName;

/// 检查文件是否已加载
/// @param fileName 文件名（不含扩展名）
/// @return 是否已加载
- (BOOL)isPagFileLoaded:(NSString *)fileName;

/// 预加载刷新头部所需的 PAG 文件
- (void)preloadRefreshHeaderFiles;

@end

NS_ASSUME_NONNULL_END
