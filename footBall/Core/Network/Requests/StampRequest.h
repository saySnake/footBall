//
//  StampRequest.h
//  footBall
//
//  邮票夹、分类、详情、展示位置（/api/v1/stamps/*）。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface StampRequest : NSObject

+ (instancetype)shared;
/// TODO: 等后端实现后再对齐，替换为真实path
/// GET `/api/v1/stamps/list` 主页邮票列表 （新），所有已添加到主页的邮票列表
- (void)getStampListSuccess:(nullable APISuccessBlock)success
                          failure:(nullable APIFailureBlock)failure;

/// TODO: 等后端实现后再对齐，替换为真实path
/// POST  `/api/v1/stamps/{stampId}` 添加主页邮票
- (void)addStamp:(NSString *)stampId position:(NSString *)position
            success:(nullable APISuccessBlock)success
            failure:(nullable APIFailureBlock)failure;

/// TODO: 等后端实现后再对齐，替换为真实path
/// PUT  `/api/v1/stamps/{stampId}` 更新主页邮票
- (void)updateOldStamp:(NSString *)stampId newStamp:(NSString *)newStampId
            success:(nullable APISuccessBlock)success
            failure:(nullable APIFailureBlock)failure;

/// TODO: 等后端实现后再对齐，替换为真实path
/// DELETE `/api/v1/stamps/{stampId}` 添加/删除主页邮票
- (void)deleteStamp:(NSString *)stampId
            success:(nullable APISuccessBlock)success
            failure:(nullable APIFailureBlock)failure;
/// GET `/api/v1/stamps/my-stamps` 已认证邮票（每分类最多10个）；`dataObject` 为 `NSArray<PNStampCategory *>`
- (void)getMyStampsSuccess:(nullable APISuccessBlock)success
                   failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/stamps/categories/{categoryId}/stamps` 获取某分类下已认证邮票（全量）；`dataObject` 为 `NSArray<PNStampAlbumItem *>`
- (void)getAllStampsInCategory:(NSString *)categoryId
                       success:(nullable APISuccessBlock)success
                       failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/stamps/selectable` 可选择邮票（按分类分组）；`dataObject` 为 `NSArray<PNStampCategory *>`
- (void)getSelectableStampsSuccess:(nullable APISuccessBlock)success
                           failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/stamps/{stampId}/detail` 邮票详情（图片、描述、获取日期、解锁条件、稀有度）
- (void)getStampDetail:(NSString *)stampId
               success:(nullable APISuccessBlock)success
               failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/stamps/quota` 邮票配额信息（已认证场次、已选邮票数、是否可添加、会员状态）
- (void)getStampQuotaSuccess:(nullable APISuccessBlock)success
                     failure:(nullable APIFailureBlock)failure;

/// POST `/api/v1/stamps/select/{stampId}` 用户选择添加邮票；position 可选，格式 "1,5"
- (void)selectStamp:(NSString *)stampId
           position:(nullable NSString *)position
            success:(nullable APISuccessBlock)success
            failure:(nullable APIFailureBlock)failure;

/// PUT `/api/v1/stamps/{stampId}/position` 更新邮票位置
- (void)updateStampPosition:(NSString *)stampId
                   position:(NSString *)position
                    success:(nullable APISuccessBlock)success
                    failure:(nullable APIFailureBlock)failure;


@end

NS_ASSUME_NONNULL_END
