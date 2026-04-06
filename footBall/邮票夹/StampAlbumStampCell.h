//
//  StampAlbumStampCell.h
//  footBall
//

#import <UIKit/UIKit.h>

@class StampAlbumItem;

NS_ASSUME_NONNULL_BEGIN

@interface StampAlbumStampCell : UICollectionViewCell

/// 邮票格：`columns` 用于网格线（最后一列/行不画外侧线）
- (void)configureWithItem:(nullable StampAlbumItem *)item
              indexPath:(NSIndexPath *)indexPath
             totalCount:(NSInteger)total
            columnCount:(NSInteger)columns;

/// 邮票格（接口模型）：用于「某分类下全部邮票」网格页
- (void)configureWithStamp:(nullable PNStampGridItem *)stamp
                 indexPath:(NSIndexPath *)indexPath
                totalCount:(NSInteger)total
               columnCount:(NSInteger)columns;

@end

NS_ASSUME_NONNULL_END
