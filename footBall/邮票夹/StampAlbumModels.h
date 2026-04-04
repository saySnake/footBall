//
//  StampAlbumModels.h
//  footBall
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface StampAlbumItem : NSObject
@property (nonatomic, assign) BOOL unlocked;
@property (nonatomic, strong) UIColor *circleColor;
@end

@interface StampAlbumSectionModel : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSArray<StampAlbumItem *> *items;
@end

NS_ASSUME_NONNULL_END
