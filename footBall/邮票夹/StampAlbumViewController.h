//
//  StampAlbumViewController.h
//  footBall
//

#import "QMBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface StampAlbumViewController : QMBaseViewController
@property (nonatomic, copy) void (^didSelected)(PNStampAlbumItem *stamp);
@end

NS_ASSUME_NONNULL_END
