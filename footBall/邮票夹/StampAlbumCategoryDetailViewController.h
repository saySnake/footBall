//
//  StampAlbumCategoryDetailViewController.h
//  footBall
//

#import "QMBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

/// 邮票夹某分类「查看更多」：3 列网格全屏页（顶栏标题与邮票夹主页一致）
@interface StampAlbumCategoryDetailViewController : QMBaseViewController

@property (nonatomic, copy) void (^didSelected)(PNStampAlbumItem *stamp);

/// 某分类下全部邮票（接口：`/api/v1/stamps/categories/{categoryId}/stamps`）
- (instancetype)initWithCategoryId:(NSString *)categoryId categoryName:(nullable NSString *)categoryName;

@end

NS_ASSUME_NONNULL_END
