//
//  SDImageManager.h
//  footBall
//
//  Created on 2026/1/15.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <SDWebImage/SDWebImage.h>

NS_ASSUME_NONNULL_BEGIN

/// 图片加载完成回调
typedef void(^SDImageLoadCompletionBlock)(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL);
/// 图片加载进度回调
typedef void(^SDImageLoadProgressBlock)(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL);

/// SDWebImage管理器 - 封装图片加载功能
@interface SDImageManager : NSObject

/// 单例
+ (instancetype)sharedManager;

/// 设置占位图（全局默认占位图）
@property (nonatomic, strong, nullable) UIImage *placeholderImage;

/// 设置失败占位图（全局默认失败占位图）
@property (nonatomic, strong, nullable) UIImage *failurePlaceholderImage;

/// 设置图片缓存配置
/// @param maxMemoryCost 内存缓存大小（字节，默认50MB）
/// @param maxDiskSize 磁盘缓存大小（字节，默认100MB）
- (void)configureCacheWithMaxMemoryCost:(NSUInteger)maxMemoryCost maxDiskSize:(NSUInteger)maxDiskSize;

/// 为UIImageView设置网络图片
/// @param imageView 图片视图
/// @param URLString 图片URL字符串
- (void)setImageForImageView:(UIImageView *)imageView withURLString:(NSString *)URLString;

/// 为UIImageView设置网络图片（带占位图）
/// @param imageView 图片视图
/// @param URLString 图片URL字符串
/// @param placeholder 占位图
- (void)setImageForImageView:(UIImageView *)imageView
              withURLString:(NSString *)URLString
                placeholder:(nullable UIImage *)placeholder;

/// 为UIImageView设置网络图片（完整参数）
/// @param imageView 图片视图
/// @param URLString 图片URL字符串
/// @param placeholder 占位图
/// @param options 加载选项
/// @param progress 进度回调
/// @param completed 完成回调
- (void)setImageForImageView:(UIImageView *)imageView
              withURLString:(NSString *)URLString
                placeholder:(nullable UIImage *)placeholder
                    options:(SDWebImageOptions)options
                   progress:(nullable SDImageLoadProgressBlock)progress
                  completed:(nullable SDImageLoadCompletionBlock)completed;

/// 为UIButton设置网络图片（正常状态）
/// @param button 按钮
/// @param URLString 图片URL字符串
/// @param state 按钮状态
- (void)setImageForButton:(UIButton *)button
           withURLString:(NSString *)URLString
                 forState:(UIControlState)state;

/// 为UIButton设置网络图片（完整参数）
/// @param button 按钮
/// @param URLString 图片URL字符串
/// @param state 按钮状态
/// @param placeholder 占位图
/// @param options 加载选项
/// @param completed 完成回调
- (void)setImageForButton:(UIButton *)button
           withURLString:(NSString *)URLString
                 forState:(UIControlState)state
              placeholder:(nullable UIImage *)placeholder
                  options:(SDWebImageOptions)options
                completed:(nullable SDImageLoadCompletionBlock)completed;

/// 预加载图片
/// @param URLString 图片URL字符串
- (void)preloadImageWithURLString:(NSString *)URLString;

/// 预加载多张图片
/// @param URLStrings 图片URL字符串数组
- (void)preloadImagesWithURLStrings:(NSArray<NSString *> *)URLStrings;

/// 下载图片（不缓存到ImageView）
/// @param URLString 图片URL字符串
/// @param progress 进度回调
/// @param completed 完成回调
- (id<SDWebImageOperation>)downloadImageWithURLString:(NSString *)URLString
                                              progress:(nullable SDImageLoadProgressBlock)progress
                                             completed:(nullable SDImageLoadCompletionBlock)completed;

/// 获取缓存中的图片
/// @param URLString 图片URL字符串
/// @param completion 完成回调
- (void)getCachedImageWithURLString:(NSString *)URLString
                          completion:(void(^)(UIImage * _Nullable image))completion;

/// 清除内存缓存
- (void)clearMemoryCache;

/// 清除磁盘缓存
/// @param completion 完成回调
- (void)clearDiskCacheWithCompletion:(nullable void(^)(void))completion;

/// 清除所有缓存
/// @param completion 完成回调
- (void)clearAllCacheWithCompletion:(nullable void(^)(void))completion;

/// 获取缓存大小
/// @param completion 完成回调（返回字节数）
- (void)getCacheSizeWithCompletion:(void(^)(NSUInteger totalSize))completion;

/// 取消图片加载
/// @param imageView 图片视图
- (void)cancelImageLoadForImageView:(UIImageView *)imageView;

/// 取消图片加载
/// @param button 按钮
- (void)cancelImageLoadForButton:(UIButton *)button;

@end

NS_ASSUME_NONNULL_END
