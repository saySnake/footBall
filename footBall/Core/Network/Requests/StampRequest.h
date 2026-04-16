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
/// TODO: 等后端实现
/// GET  `/api/v1/stamps/categories`  获取已认证的邮票分类，每个分类返回最多10个邮票
- (void)getStampsCategoriesSuccess:(nullable APISuccessBlock)success
                           failure:(nullable APIFailureBlock)failure;

/// TODO: 等后端实现
/// GET  `/api/v1/stamps/categories/{categoryId}/all`  获取已认证的邮票分类，每个分类返回最多10个邮票
- (void)getAllStampsInCategory:(NSString *)categoryId
                       success:(nullable APISuccessBlock)success
                       failure:(nullable APIFailureBlock)failure;

@end

NS_ASSUME_NONNULL_END
