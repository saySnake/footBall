//
//  RefreshPagHeader.h
//  footBall
//
//  Created by 张玮 on 2026/1/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RefreshPagHeader : MJRefreshStateHeader

/// 确保 PAG 文件已加载（非阻塞方法，用于预加载）
- (void)ensurePagFilesLoaded;

@end

NS_ASSUME_NONNULL_END
