//
//  RefreshPagHeader.m
//  footBall
//
//  Created by 张玮 on 2026/1/15.
//

#import "RefreshPagHeader.h"
#import "PagFilePreloader.h"
#import <libpag/PAGView.h>
#import <QuartzCore/QuartzCore.h>
#define BALLOON_GIF_DURATION 0.15

@interface RefreshPagHeader()
/**
 PAG显示视图
 */
@property (strong, nonatomic) PAGView* beginPagView;
@property (strong, nonatomic) PAGView* endPagView;

/**
 PAG资源文件（缓存，避免重复加载）
 */
@property (strong, nonatomic) PAGFile* beginPagFile;
@property (strong, nonatomic) PAGFile* endPagFile;

/**
 是否已初始化 PAG 文件
 */
@property (nonatomic, assign) BOOL pagFilesLoaded;

/**
 是否正在异步加载
 */
@property (nonatomic, assign) BOOL isLoadingPagFiles;

/**
 是否已设置 composition 到视图
 */
@property (nonatomic, assign) BOOL compositionSet;

/**
 * 是否已完成预热（确保第一次播放时不会掉帧）
 */
@property (nonatomic, assign) BOOL isWarmedUp;

/**
 上一次的 frame，用于避免重复设置
 */
@property (nonatomic, assign) CGRect lastPagFrame;

/**
 标签是否已隐藏
 */
@property (nonatomic, assign) BOOL labelsHidden;

@end

static NSString * const kBegainName = @"loading_1";
static NSString * const kEndName = @"loading_1";

@implementation RefreshPagHeader

#pragma mark - 实现父类的方法
- (void)prepare {
    [super prepare];
    
    // 确保刷新头部背景透明
    self.backgroundColor = [UIColor clearColor];
    
    // 初始化标志位
    self.compositionSet = NO;
    self.isWarmedUp = NO;
    self.labelsHidden = NO;
    self.lastPagFrame = CGRectZero;
    
    // 彻底禁用标签（不仅是隐藏，还能减少 MJRefresh 内部的计算）
    self.stateLabel.hidden = YES;
    self.lastUpdatedTimeLabel.hidden = YES;
    // 强制 MJRefresh 不去布局这些标签
    self.stateLabel.autoresizingMask = UIViewAutoresizingNone;
    self.lastUpdatedTimeLabel.autoresizingMask = UIViewAutoresizingNone;
    self.labelsHidden = YES;
    
    // 初始化 PAG 视图（先创建视图，延迟加载文件）
    self.beginPagView = [[PAGView alloc] init];
    self.beginPagView.hidden = YES;
    // 设置背景色为透明，避免黑色背景 bug
    self.beginPagView.backgroundColor = [UIColor clearColor];
    // 设置 layer 属性以支持透明背景
    self.beginPagView.layer.opaque = NO;
    self.beginPagView.layer.backgroundColor = [UIColor clearColor].CGColor;
    // 开启缓存提高性能
    [self.beginPagView setCacheEnabled:YES];
    // 优化渲染性能：确保使用 GPU 硬件加速
    self.beginPagView.layer.shouldRasterize = NO; // 禁用光栅化，PAGView 使用 GPU 直接渲染
    // 注意：drawsAsynchronously 可能不适合 PAGView，因为 PAGView 有自己的渲染机制
    [self addSubview:self.beginPagView];
    
    self.endPagView = [[PAGView alloc] init];
    self.endPagView.hidden = YES;
    // 设置背景色为透明，避免黑色背景 bug
    self.endPagView.backgroundColor = [UIColor clearColor];
    self.endPagView.layer.opaque = NO;
    self.endPagView.layer.backgroundColor = [UIColor clearColor].CGColor;
    [self.endPagView setCacheEnabled:YES];
    // 优化渲染性能
    self.endPagView.layer.shouldRasterize = NO;
    [self addSubview:self.endPagView];
    
    // 尝试立即从预加载器获取文件（如果已预加载完成）
    PagFilePreloader *preloader = [PagFilePreloader sharedPreloader];
    PAGFile *beginFile = [preloader getPagFile:kBegainName];
    PAGFile *endFile = [preloader getPagFile:kEndName];
    
    if (beginFile && endFile) {
        [self setupPagWithBeginFile:beginFile endFile:endFile];
    } else {
        // 文件未预加载，启动异步加载
        [self loadPagFilesAsync];
    }
}

/// 统一配置 PAG 视图并进行预热
- (void)setupPagWithBeginFile:(PAGFile *)beginFile endFile:(PAGFile *)endFile {
    if (self.compositionSet) {
        self.isLoadingPagFiles = NO;
        return;
    }
    
    self.beginPagFile = beginFile;
    self.endPagFile = endFile;
    self.pagFilesLoaded = YES;
    self.isLoadingPagFiles = NO;
    
    if (self.beginPagView) {
        [self.beginPagView setComposition:beginFile];
        [self.beginPagView setRepeatCount:0];
        
        // 关键优化：进行充分的 GPU 预热，避免第一次播放时卡顿
        // 1. 立即同步刷新第一帧，初始化 GPU 渲染环境（同步执行，确保完成）
        [self.beginPagView play];
        
        // 2. 同步预热关键帧（确保在播放前完成）
        // 预渲染更多关键帧，让 GPU 充分预热（编译着色器、加载纹理等）
        // 增加到每10%一帧，共11帧，确保充分预热
        NSArray<NSNumber *> *progressValues = @[@0.0, @0.1, @0.2, @0.3, @0.4, @0.5, @0.6, @0.7, @0.8, @0.9, @1.0];
        for (NSNumber *progress in progressValues) {
            [self.beginPagView setProgress:progress.floatValue];
            [self.beginPagView play];
        }
        // 重置到开始位置，准备播放
        [self.beginPagView setProgress:0.0];
        [self.beginPagView play];
        
        // 3. 标记已预热完成
        self.isWarmedUp = YES;
    }
    if (self.endPagView) {
        [self.endPagView setComposition:endFile];
        [self.endPagView setRepeatCount:1];
        [self.endPagView play];
        
        // 同样预热 endPagView（也增加帧数，确保流畅）
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray<NSNumber *> *progressValues = @[@0.0, @0.2, @0.4, @0.6, @0.8, @1.0];
            for (NSNumber *progress in progressValues) {
                [self.endPagView setProgress:progress.floatValue];
                [self.endPagView play];
            }
            [self.endPagView setProgress:0.0];
            [self.endPagView play];
        });
    }
    
    self.compositionSet = YES;
}

/// 异步加载 PAG 文件
- (void)loadPagFilesAsync {
    if (self.pagFilesLoaded || self.isLoadingPagFiles) {
        return;
    }
    
    self.isLoadingPagFiles = YES;
    
    // 优先从预加载器获取（如果已预加载）
    PagFilePreloader *preloader = [PagFilePreloader sharedPreloader];
    PAGFile *beginFile = [preloader getPagFile:kBegainName];
    PAGFile *endFile = [preloader getPagFile:kEndName];
    
    // 如果预加载器中有，直接使用（同步，但不耗时）
    if (beginFile && endFile) {
        self.beginPagFile = beginFile;
        self.endPagFile = endFile;
        self.pagFilesLoaded = YES;
        self.isLoadingPagFiles = NO;
        
        // 立即设置到视图并进行预热
        if (self.beginPagView) {
            [self.beginPagView setComposition:beginFile];
            [self.beginPagView setRepeatCount:0];
            // 立即进行同步预热（增加到更多帧）
            [self.beginPagView play];
            NSArray<NSNumber *> *progressValues = @[@0.0, @0.1, @0.2, @0.3, @0.4, @0.5, @0.6, @0.7, @0.8, @0.9, @1.0];
            for (NSNumber *progress in progressValues) {
                [self.beginPagView setProgress:progress.floatValue];
                [self.beginPagView play];
            }
            [self.beginPagView setProgress:0.0];
            [self.beginPagView play];
            self.isWarmedUp = YES;
        }
        if (self.endPagView) {
            [self.endPagView setComposition:endFile];
            [self.endPagView setRepeatCount:1];
            [self.endPagView play];
        }
        self.compositionSet = YES;
        return;
    }
    
    // 如果预加载器中没有，在后台线程加载
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSString *beginPath = [self resourcePath:kBegainName];
        NSString *endPath = [self resourcePath:kEndName];
        
        // 在 block 内部重新声明变量（避免 __block 问题）
        PAGFile *loadedBeginFile = beginFile;
        PAGFile *loadedEndFile = endFile;
        
        // 尝试从预加载器获取（可能在加载中）
        if (!loadedBeginFile) {
            loadedBeginFile = [preloader getPagFile:kBegainName];
        }
        if (!loadedEndFile) {
            loadedEndFile = [preloader getPagFile:kEndName];
        }
        
        // 如果还是没有，直接加载
        if (!loadedBeginFile && beginPath) {
            loadedBeginFile = [PAGFile Load:beginPath];
        }
        if (!loadedEndFile && endPath) {
            loadedEndFile = [PAGFile Load:endPath];
        }
        
        // 使用局部变量
        PAGFile *finalBeginFile = loadedBeginFile;
        PAGFile *finalEndFile = loadedEndFile;
        
        // 回到主线程设置
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setupPagWithBeginFile:finalBeginFile endFile:finalEndFile];
            
            // 如果当前正在刷新状态，立即开始播放
            if (self.state == MJRefreshStateRefreshing && self.beginPagView) {
                self.beginPagView.hidden = NO;
                [self.beginPagView play];
            }
        });
    });
}

/// 确保 PAG 文件已加载（非阻塞方法）
- (void)ensurePagFilesLoaded {
    // 如果已经加载，直接返回
    if (self.pagFilesLoaded) {
        // 确保文件已设置到视图（只在未设置时设置一次）
        if (!self.compositionSet) {
            if (self.beginPagFile && self.beginPagView) {
                [self.beginPagView setComposition:self.beginPagFile];
                [self.beginPagView setRepeatCount:0];
            }
            if (self.endPagFile && self.endPagView) {
                [self.endPagView setComposition:self.endPagFile];
                [self.endPagView setRepeatCount:1];
            }
            self.compositionSet = YES;
        }
        return;
    }
    
    // 尝试从预加载器获取（同步，快速）
    PagFilePreloader *preloader = [PagFilePreloader sharedPreloader];
    PAGFile *beginFile = [preloader getPagFile:kBegainName];
    PAGFile *endFile = [preloader getPagFile:kEndName];
    
    if (beginFile && endFile) {
        [self setupPagWithBeginFile:beginFile endFile:endFile];
        return;
    }
    
    if (!self.compositionSet && self.beginPagFile && self.endPagFile) {
        [self setupPagWithBeginFile:self.beginPagFile endFile:self.endPagFile];
    }
    
    // 如果正在加载，等待加载完成（不阻塞）
    if (self.isLoadingPagFiles) {
        return;
    }
    
    // 如果还没开始加载，触发异步加载
    [self loadPagFilesAsync];
}

- (void)setPullingPercent:(CGFloat)pullingPercent {
    [super setPullingPercent:pullingPercent];
    
    // 下拉过程中完全不做任何操作，避免任何性能开销
    // 所有初始化、布局和动画都在 prepare、placeSubviews 和 setState 中处理
    // 确保下拉过程尽可能流畅
}

- (void)placeSubviews {
    [super placeSubviews];
    
    // 更新 PAG 视图的位置（居中显示）
    static const CGFloat pagW = 90.0f;
    static const CGFloat pagH = 40.0f;
    
    CGFloat width = self.mj_w;
    CGFloat height = self.mj_h;
    if (width <= 0) width = [UIScreen mainScreen].bounds.size.width;
    
    CGRect pagFrame = CGRectMake((width - pagW) * 0.5f, (height - pagH) * 0.5f, pagW, pagH);
    
    // 只有当 frame 发生变化时才更新（优化性能）
    // 在状态转换时避免不必要的布局更新，减少掉帧
    if (!CGRectEqualToRect(pagFrame, self.lastPagFrame)) {
        // 使用 CATransaction 批量更新，减少重绘次数
        [CATransaction begin];
        [CATransaction setDisableActions:YES]; // 禁用隐式动画，避免掉帧
        self.beginPagView.frame = pagFrame;
        self.endPagView.frame = pagFrame;
        [CATransaction commit];
        self.lastPagFrame = pagFrame;
    }
}

- (void)setState:(MJRefreshState)state{
    // MJRefreshCheckState 宏会自动定义 oldState 变量
    MJRefreshCheckState
    
    switch (state) {
        case MJRefreshStateWillRefresh:
            // 关键优化：在即将刷新时提前进行预热和准备，避免进入刷新状态时掉帧
            // 确保文件已加载
            [self ensurePagFilesLoaded];
            
            // 提前进行预热，确保进入刷新状态时 GPU 已就绪
            if (self.beginPagView && self.beginPagFile && self.compositionSet) {
                // 如果还未预热，立即进行同步预热
                if (!self.isWarmedUp) {
                    NSArray<NSNumber *> *progressValues = @[@0.0, @0.1, @0.2, @0.3, @0.4, @0.5, @0.6, @0.7, @0.8, @0.9, @1.0];
                    for (NSNumber *progress in progressValues) {
                        [self.beginPagView setProgress:progress.floatValue];
                        [self.beginPagView play];
                    }
                    [self.beginPagView setProgress:0.0];
                    [self.beginPagView play];
                    self.isWarmedUp = YES;
                } else {
                    // 即使已预热，也快速刷新一帧确保 GPU 状态就绪
                    [self.beginPagView play];
                }
            }
            break;
        case MJRefreshStatePulling:
        case MJRefreshStateRefreshing:
            // 确保文件已加载（在需要播放动画前）
            [self ensurePagFilesLoaded];
            
            //开始动画
            if (self.beginPagView && self.beginPagFile) {
                self.beginPagView.hidden = NO;
                
                // 关键优化：确保在播放前已完成预热
                if (!self.isWarmedUp && self.compositionSet) {
                    // 如果预热未完成，立即进行同步预热（确保不掉帧）
                    // 增加到更多帧，确保充分预热
                    NSArray<NSNumber *> *progressValues = @[@0.0, @0.1, @0.2, @0.3, @0.4, @0.5, @0.6, @0.7, @0.8, @0.9, @1.0];
                    for (NSNumber *progress in progressValues) {
                        [self.beginPagView setProgress:progress.floatValue];
                        [self.beginPagView play];
                    }
                    [self.beginPagView setProgress:0.0];
                    [self.beginPagView play];
                    self.isWarmedUp = YES;
                } else if (self.compositionSet) {
                    // 即使已预热，也快速刷新一帧确保 GPU 状态就绪
                    self.endPagView.hidden = YES;
                    [self.endPagView stop];
                    self.beginPagView.hidden = NO;
                    [self.beginPagView play];
                }
                
                [self.beginPagView play];
            } else if (self.beginPagView) {
                // 文件未加载，触发加载并等待
                [self loadPagFilesAsync];
                // 延迟一点再尝试播放（不阻塞）
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (self.beginPagFile && self.beginPagView) {
                        self.beginPagView.hidden = NO;
                        // 播放前进行同步预热（增加到更多帧）
                        if (!self.isWarmedUp) {
                            NSArray<NSNumber *> *progressValues = @[@0.0, @0.1, @0.2, @0.3, @0.4, @0.5, @0.6, @0.7, @0.8, @0.9, @1.0];
                            for (NSNumber *progress in progressValues) {
                                [self.beginPagView setProgress:progress.floatValue];
                                [self.beginPagView play];
                            }
                            [self.beginPagView setProgress:0.0];
                            [self.beginPagView play];
                            self.isWarmedUp = YES;
                        } else {
                            [self.beginPagView play];
                        }
                        [self.beginPagView play];
                    }
                });
            }
            if (self.endPagView) {
                self.endPagView.hidden = YES;
                [self.endPagView stop];
            }
            break;
        case MJRefreshStateIdle:
            if (oldState == MJRefreshStateRefreshing && state == MJRefreshStateIdle) {
                //刷新完成，播放结束动画
                if (self.beginPagView) {
                    self.beginPagView.hidden = YES;
                    [self.beginPagView stop];
                }
                if (self.endPagView && self.endPagFile) {
                    self.endPagView.hidden = NO;
                    [self.endPagView play];
                }
            } else {
                //停止动画
                if (self.beginPagView) {
                    self.beginPagView.hidden = YES;
                    [self.beginPagView stop];
                }
                if (self.endPagView) {
                    self.endPagView.hidden = YES;
                    [self.endPagView stop];
                }
            }
            break;
        default:
            break;
    }
    [super setState:state];
}

- (void)endRefreshing {
    // 播放结束动画
    if (self.state == MJRefreshStateRefreshing) {
        self.beginPagView.hidden = YES;
        [self.beginPagView stop];
        self.endPagView.hidden = NO;
        [self.endPagView play];
        
        // 等待动画播放完成后再结束刷新
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [super endRefreshing];
        });
    } else {
        [super endRefreshing];
    }
}


- (NSString*)resourcePath:(NSString *)name {
    return [[NSBundle mainBundle] pathForResource:name ofType:@"pag"];
}
@end
