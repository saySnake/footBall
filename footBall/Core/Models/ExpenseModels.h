#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PNExpense : NSObject <YYModel>
@property (nonatomic, copy) NSString *expenseId;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *matchRecordId;
@property (nonatomic, copy) NSString *itemName;
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
@property (nonatomic, copy) NSString *monthlyAverage;
@end

NS_ASSUME_NONNULL_END
