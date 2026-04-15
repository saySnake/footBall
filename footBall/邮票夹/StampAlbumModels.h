//
//  StampAlbumModels.h
//  footBall
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "StampModels.h"

NS_ASSUME_NONNULL_BEGIN

@interface StampAlbumItem : NSObject
@property (nonatomic, assign) BOOL unlocked;
@property (nonatomic, strong) UIColor *circleColor;
@property (nonatomic, copy, nullable) NSString *imageURL;
@property (nonatomic, copy, nullable) NSString *rarity;
@property (nonatomic, assign) BOOL isNew;
/// 选择邮票时需要回传给业务层的原始对象（来自 `/api/v1/stamps/collection`）
@property (nonatomic, strong, nullable) PNStampAlbumItem *rawStamp;
@end

@interface StampAlbumSectionModel : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSArray<StampAlbumItem *> *items;
@end

NS_ASSUME_NONNULL_END
