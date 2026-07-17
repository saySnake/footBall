//
//  StampRequest.h
//  footBall
//
//  邮票夹、分类、详情、展示/隐藏（/api/v1/stamps/*）。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface StampRequest : NSObject

+ (instancetype)shared;

/// GET `/api/v1/stamps/list` 主页已展示邮票列表；`dataObject` 为 `NSArray<PNStampAlbumItem *>`
- (void)getStampListSuccess:(nullable APISuccessBlock)success
                    failure:(nullable APIFailureBlock)failure;

/// POST `/api/v1/stamps/{stampId}/show` 展示到主页指定位置；body `{position}`
- (void)showStamp:(NSString *)stampId
         position:(NSString *)position
          success:(nullable APISuccessBlock)success
          failure:(nullable APIFailureBlock)failure;

/// POST `/api/v1/stamps/{stampId}/hide` 从主页隐藏（保留拥有关系）
- (void)hideStamp:(NSString *)stampId
          success:(nullable APISuccessBlock)success
          failure:(nullable APIFailureBlock)failure;

/// POST `/api/v1/stamps/{stampId}/replace` 更换主页展示；body `{newStampId}`
- (void)replaceStamp:(NSString *)stampId
          newStampId:(NSString *)newStampId
             success:(nullable APISuccessBlock)success
             failure:(nullable APIFailureBlock)failure;

/// POST `/api/v1/stamps/{stampId}/position` 更新展示位置；body `{position}`
- (void)updateStampPosition:(NSString *)stampId
                   position:(NSString *)position
                    success:(nullable APISuccessBlock)success
                    failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/stamps/my-stamps`；`dataObject` 为 `NSArray<PNStampCategory *>`
- (void)getMyStampsSuccess:(nullable APISuccessBlock)success
                   failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/stamps/categories/{categoryId}/stamps`；`dataObject` 为 `NSArray<PNStampAlbumItem *>`
- (void)getAllStampsInCategory:(NSString *)categoryId
                       success:(nullable APISuccessBlock)success
                       failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/stamps/selectable` 我的邮票仓库；`dataObject` 为 `NSArray<PNStampCategory *>`
- (void)getSelectableStampsSuccess:(nullable APISuccessBlock)success
                           failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/stamps/{stampId}/detail` 邮票详情（查看后清除 isNew）
- (void)getStampDetail:(NSString *)stampId
               success:(nullable APISuccessBlock)success
               failure:(nullable APIFailureBlock)failure;

@end

NS_ASSUME_NONNULL_END
