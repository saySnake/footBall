#import "ExpenseModels.h"

@implementation PNExpense
+ (NSDictionary<NSString *,id> *)modelCustomPropertyMapper {
    return @{@"expenseId": @[@"id", @"expenseId"],
             @"userId": @"userId",
             @"matchRecordId": @"matchRecordId"};
}
@end

@implementation PNExpensePage
+ (NSDictionary<NSString *,id> *)modelContainerPropertyGenericClass {
    return @{@"list": PNExpense.class};
}
@end

@implementation PNExpenseSummary
@end
