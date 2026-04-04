//
//  StampAlbumCategoryViewController.h
//  footBall
//

#import "QMBaseViewController.h"

@class StampAlbumItem;

NS_ASSUME_NONNULL_BEGIN

/// 邮票夹某分类「查看更多」：3 列网格全屏页（顶栏标题与邮票夹主页一致）
@interface StampAlbumCategoryViewController : QMBaseViewController

- (instancetype)initWithItems:(NSArray<StampAlbumItem *> *)items;

@end

NS_ASSUME_NONNULL_END
