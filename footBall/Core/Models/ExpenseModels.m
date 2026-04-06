#import "ExpenseModels.h"

@implementation PNExpense
+ (NSDictionary<NSString *,id> *)modelCustomPropertyMapper {
    return @{@"expenseId": @[@"id", @"expenseId"],
             @"userId": @[@"userId", @"uid"],
             @"matchRecordId": @[@"matchRecordId", @"matchId"],
             @"itemName": @[@"itemName", @"title", @"name", @"item", @"remark", @"description"],
             @"amount": @[@"amount", @"money", @"price", @"totalAmount"],
             @"expenseDate": @[@"expenseDate", @"date", @"consumeDate", @"bizDate"],
             @"createTime": @[@"createTime", @"createdAt", @"gmtCreate", @"createTimeStr"],
             @"photos": @[@"photos", @"photoUrls", @"images"],
             @"logoUrl": @[@"logoUrl", @"logo", @"teamLogo", @"iconUrl", @"coverUrl", @"imageUrl"]};
}
@end

@implementation PNExpensePage
+ (NSDictionary<NSString *,id> *)modelCustomPropertyMapper {
    return @{@"list": @[@"list", @"records", @"rows", @"items", @"content"],
             @"pageNum": @[@"pageNum", @"current", @"page", @"pageNo"],
             @"pageSize": @[@"pageSize", @"size", @"limit"],
             @"total": @[@"total", @"count", @"totalCount"]};
}
+ (NSDictionary<NSString *,id> *)modelContainerPropertyGenericClass {
    return @{@"list": PNExpense.class};
}
@end

@implementation PNExpenseSummary
@end
