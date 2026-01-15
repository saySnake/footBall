//
//  SDImageManager.m
//  footBall
//
//  Created on 2026/1/15.
//

#import "SDImageManager.h"

@interface SDImageManager ()

@property (nonatomic, strong) SDImageCache *imageCache;
@property (nonatomic, strong) SDWebImageManager *imageManager;

@end

@implementation SDImageManager

+ (instancetype)sharedManager {
    static SDImageManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SDImageManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _imageCache = [SDImageCache sharedImageCache];
        _imageManager = [SDWebImageManager sharedManager];
        _placeholderImage = nil;
        _failurePlaceholderImage = nil;
    }
    return self;
}

- (void)configureCacheWithMaxMemoryCost:(NSUInteger)maxMemoryCost maxDiskSize:(NSUInteger)maxDiskSize {
    self.imageCache.config.maxMemoryCost = maxMemoryCost;
    self.imageCache.config.maxDiskSize = maxDiskSize;
}

- (void)setImageForImageView:(UIImageView *)imageView withURLString:(NSString *)URLString {
    [self setImageForImageView:imageView
                 withURLString:URLString
                   placeholder:self.placeholderImage];
}

- (void)setImageForImageView:(UIImageView *)imageView
              withURLString:(NSString *)URLString
                placeholder:(UIImage *)placeholder {
    [self setImageForImageView:imageView
                 withURLString:URLString
                   placeholder:placeholder
                       options:SDWebImageRetryFailed
                      progress:nil
                     completed:nil];
}

- (void)setImageForImageView:(UIImageView *)imageView
              withURLString:(NSString *)URLString
                placeholder:(UIImage *)placeholder
                    options:(SDWebImageOptions)options
                   progress:(SDImageLoadProgressBlock)progress
                  completed:(SDImageLoadCompletionBlock)completed {
    
    NSURL *url = nil;
    if ([URLString isKindOfClass:[NSString class]] && URLString.length > 0) {
        url = [NSURL URLWithString:URLString];
    }
    
    if (!url) {
        if (completed) {
            NSError *error = [NSError errorWithDomain:@"SDImageManager"
                                                  code:-1
                                              userInfo:@{NSLocalizedDescriptionKey: @"无效的图片URL"}];
            completed(nil, error, SDImageCacheTypeNone, nil);
        }
        return;
    }
    
    // 设置占位图
    UIImage *placeHolderImage = placeholder ?: self.placeholderImage;
    
    // 进度回调转换
    SDWebImageDownloaderProgressBlock progressBlock = nil;
    if (progress) {
        progressBlock = ^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
            if (progress) {
                progress(receivedSize, expectedSize, targetURL);
            }
        };
    }
    
    // 完成回调转换
    SDExternalCompletionBlock completionBlock = nil;
    if (completed) {
        completionBlock = ^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            if (completed) {
                completed(image, error, cacheType, imageURL);
            }
        };
    }
    
    [imageView sd_setImageWithURL:url
                  placeholderImage:placeHolderImage
                           options:options
                          progress:progressBlock
                         completed:completionBlock];
}

- (void)setImageForButton:(UIButton *)button
           withURLString:(NSString *)URLString
                 forState:(UIControlState)state {
    [self setImageForButton:button
              withURLString:URLString
                    forState:state
                 placeholder:self.placeholderImage
                     options:SDWebImageRetryFailed
                   completed:nil];
}

- (void)setImageForButton:(UIButton *)button
           withURLString:(NSString *)URLString
                 forState:(UIControlState)state
              placeholder:(UIImage *)placeholder
                  options:(SDWebImageOptions)options
                completed:(SDImageLoadCompletionBlock)completed {
    
    NSURL *url = nil;
    if ([URLString isKindOfClass:[NSString class]] && URLString.length > 0) {
        url = [NSURL URLWithString:URLString];
    }
    
    if (!url) {
        if (completed) {
            NSError *error = [NSError errorWithDomain:@"SDImageManager"
                                                  code:-1
                                              userInfo:@{NSLocalizedDescriptionKey: @"无效的图片URL"}];
            completed(nil, error, SDImageCacheTypeNone, nil);
        }
        return;
    }
    
    UIImage *placeHolderImage = placeholder ?: self.placeholderImage;
    
    SDExternalCompletionBlock completionBlock = nil;
    if (completed) {
        completionBlock = ^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            if (completed) {
                completed(image, error, cacheType, imageURL);
            }
        };
    }
    
    [button sd_setImageWithURL:url
                      forState:state
              placeholderImage:placeHolderImage
                       options:options
                     completed:completionBlock];
}

- (void)preloadImageWithURLString:(NSString *)URLString {
    NSURL *url = nil;
    if ([URLString isKindOfClass:[NSString class]] && URLString.length > 0) {
        url = [NSURL URLWithString:URLString];
    }
    
    if (url) {
        [self.imageManager loadImageWithURL:url
                                     options:SDWebImageHighPriority
                                    progress:nil
                                   completed:nil];
    }
}

- (void)preloadImagesWithURLStrings:(NSArray<NSString *> *)URLStrings {
    for (NSString *URLString in URLStrings) {
        [self preloadImageWithURLString:URLString];
    }
}

- (id<SDWebImageOperation>)downloadImageWithURLString:(NSString *)URLString
                                              progress:(SDImageLoadProgressBlock)progress
                                             completed:(SDImageLoadCompletionBlock)completed {
    NSURL *url = nil;
    if ([URLString isKindOfClass:[NSString class]] && URLString.length > 0) {
        url = [NSURL URLWithString:URLString];
    }
    
    if (!url) {
        if (completed) {
            NSError *error = [NSError errorWithDomain:@"SDImageManager"
                                                  code:-1
                                              userInfo:@{NSLocalizedDescriptionKey: @"无效的图片URL"}];
            completed(nil, error, SDImageCacheTypeNone, nil);
        }
        return nil;
    }
    
    SDWebImageDownloaderProgressBlock progressBlock = nil;
    if (progress) {
        progressBlock = ^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
            if (progress) {
                progress(receivedSize, expectedSize, targetURL);
            }
        };
    }
    
    SDInternalCompletionBlock completionBlock = nil;
    if (completed) {
        completionBlock = ^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            if (completed) {
                completed(image, error, cacheType, imageURL);
            }
        };
    }
    
    return [self.imageManager loadImageWithURL:url
                                         options:SDWebImageHighPriority
                                        progress:progressBlock
                                       completed:completionBlock];
}

- (void)getCachedImageWithURLString:(NSString *)URLString
                          completion:(void(^)(UIImage * _Nullable image))completion {
    NSURL *url = nil;
    if ([URLString isKindOfClass:[NSString class]] && URLString.length > 0) {
        url = [NSURL URLWithString:URLString];
    }
    
    if (!url) {
        if (completion) {
            completion(nil);
        }
        return;
    }
    
    [self.imageCache queryImageForKey:url.absoluteString
                               options:0
                               context:nil
                            completion:^(UIImage * _Nullable image, NSData * _Nullable data, SDImageCacheType cacheType) {
        if (completion) {
            completion(image);
        }
    }];
}

- (void)clearMemoryCache {
    [self.imageCache clearMemory];
}

- (void)clearDiskCacheWithCompletion:(void(^)(void))completion {
    [self.imageCache clearDiskOnCompletion:completion];
}

- (void)clearAllCacheWithCompletion:(void(^)(void))completion {
    [self.imageCache clearMemory];
    [self.imageCache clearDiskOnCompletion:completion];
}

- (void)getCacheSizeWithCompletion:(void(^)(NSUInteger totalSize))completion {
    [self.imageCache calculateSizeWithCompletionBlock:^(NSUInteger fileCount, NSUInteger totalSize) {
        if (completion) {
            completion(totalSize);
        }
    }];
}

- (void)cancelImageLoadForImageView:(UIImageView *)imageView {
    [imageView sd_cancelCurrentImageLoad];
}

- (void)cancelImageLoadForButton:(UIButton *)button {
    [button sd_cancelImageLoadForState:UIControlStateNormal];
}

@end
