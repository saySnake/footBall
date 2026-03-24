#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProfileRequest : NSObject
+ (instancetype)shared;
/// 获取当前用户护照数据
- (void)getMyPassportWithYear:(nullable NSString *)year
                      success:(nullable APISuccessBlock)success
                      failure:(nullable APIFailureBlock)failure;
/// 获取我的统计数据
- (void)getMyStatisticsWithPeriod:(nullable NSString *)period
                          success:(nullable APISuccessBlock)success
                          failure:(nullable APIFailureBlock)failure;
/// 排行榜
- (void)getLeaderboardWithPeriod:(nullable NSString *)period
                            page:(NSInteger)page
                        pageSize:(NSInteger)pageSize
                         success:(nullable APISuccessBlock)success
                         failure:(nullable APIFailureBlock)failure;
@end

NS_ASSUME_NONNULL_END
