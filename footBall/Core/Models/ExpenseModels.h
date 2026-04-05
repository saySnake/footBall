//
//  ExpenseModels.h
//  footBall
//
//  观赛花费记录、分页与汇总。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PNExpense : NSObject <YYModel>
@property (nonatomic, copy) NSString *expenseId;
@property (nonatomic, copy) NSString *userId;
/// 关联的观赛记录 ID
@property (nonatomic, copy) NSString *matchRecordId;
/// 花费项目名称
@property (nonatomic, copy) NSString *itemName;
/// 金额（字符串，与接口一致）
@property (nonatomic, copy) NSString *amount;
@property (nonatomic, strong) NSArray<NSString *> *photos;
@property (nonatomic, copy) NSString *expenseDate;
@property (nonatomic, copy) NSString *createTime;
@end

@interface PNExpensePage : NSObject <YYModel>
@property (nonatomic, strong) NSArray<PNExpense *> *list;
@property (nonatomic, assign) NSInteger pageNum;
@property (nonatomic, assign) NSInteger pageSize;
@property (nonatomic, assign) NSInteger total;
@end

@interface PNExpenseSummary : NSObject <YYModel>
@property (nonatomic, copy) NSString *totalAmount;
/// 月均花费
@property (nonatomic, copy) NSString *monthlyAverage;
@end

NS_ASSUME_NONNULL_END
