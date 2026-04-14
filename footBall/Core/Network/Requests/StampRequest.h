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
/// GET `/api/v1/stamps/list` 主页邮票列表 （新），所有已添加到主页的邮票列表
- (void)getStampListSuccess:(nullable APISuccessBlock)success
                          failure:(nullable APIFailureBlock)failure;


/// GET `/api/v1/stamps/collection` — 邮票夹主页（分类+预览等）；`dataObject` 为原始 `data`
- (void)getStampCollectionSuccess:(nullable APISuccessBlock)success
                          failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/stamps/categories` — 动态分类列表
- (void)getStampCategoriesSuccess:(nullable APISuccessBlock)success
                           failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/stamps/categories/{categoryId}/all`
/// - 预期：某分类下全部邮票（网格，数组）
/// - 兼容：后端若暂返回分类列表（id/name/icon/sortOrder），会解析为 `NSArray<PNStampCategory *>`
- (void)getAllStampsInCategory:(NSString *)categoryId
                       success:(nullable APISuccessBlock)success
                       failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/stamps/{stampId}` — 邮票详情
- (void)getStampDetail:(NSString *)stampId
               success:(nullable APISuccessBlock)success
               failure:(nullable APIFailureBlock)failure;

/// PUT `/api/v1/stamps/display` — 更新展示位置（长按编辑等）；body 与后端约定一致
- (void)updateStampDisplayWithBody:(NSDictionary *)body
                           success:(nullable APISuccessBlock)success
                           failure:(nullable APIFailureBlock)failure;

@end

NS_ASSUME_NONNULL_END
