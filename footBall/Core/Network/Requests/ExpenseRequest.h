#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ExpenseRequest : NSObject
+ (instancetype)shared;
/// 查询消费记录列表
- (void)getExpensesWithMonth:(nullable NSString *)month
                        page:(NSInteger)page
                    pageSize:(NSInteger)pageSize
                     success:(nullable APISuccessBlock)success
                     failure:(nullable APIFailureBlock)failure;
/// 获取消费汇总统计
- (void)getExpenseSummaryWithMonth:(nullable NSString *)month
                           success:(nullable APISuccessBlock)success
                           failure:(nullable APIFailureBlock)failure;
@end

NS_ASSUME_NONNULL_END
