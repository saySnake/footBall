//
//  ExpenseRequest.h
//  footBall
//
//  观赛消费记录：列表、汇总、增删改（/api/v1/expenses/*）。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ExpenseRequest : NSObject

+ (instancetype)shared;

/// GET `/api/v1/expenses` — 消费列表分页；`month` 如 `yyyy-MM`；`date` 如 `yyyy-MM-dd`（可选，依后端是否支持）；`dataObject` 为 `PNExpensePage`
- (void)getExpensesWithMonth:(nullable NSString *)month
                         date:(nullable NSString *)dateString
                         page:(NSInteger)page
                     pageSize:(NSInteger)pageSize
                      success:(nullable APISuccessBlock)success
                      failure:(nullable APIFailureBlock)failure;

/// GET `/api/v1/expenses/summary` — 月度汇总；`dataObject` 为 `PNExpenseSummary`
- (void)getExpenseSummaryWithMonth:(nullable NSString *)month
                           success:(nullable APISuccessBlock)success
                           failure:(nullable APIFailureBlock)failure;

/// POST `/api/v1/expenses` — 新增消费；body 与 `PNExpense` / 后端字段对齐；成功时尽量解析为 `PNExpense`
- (void)createExpenseWithBody:(NSDictionary *)body
                      success:(nullable APISuccessBlock)success
                      failure:(nullable APIFailureBlock)failure;

/// PUT `/api/v1/expenses/{expenseId}` — 更新消费记录
- (void)updateExpense:(NSString *)expenseId
                 body:(NSDictionary *)body
              success:(nullable APISuccessBlock)success
              failure:(nullable APIFailureBlock)failure;

/// DELETE `/api/v1/expenses/{expenseId}` — 删除消费记录
- (void)deleteExpense:(NSString *)expenseId
              success:(nullable APISuccessBlock)success
              failure:(nullable APIFailureBlock)failure;

@end

NS_ASSUME_NONNULL_END
