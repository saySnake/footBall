#import "ExpenseRequest.h"

@implementation ExpenseRequest
+ (instancetype)shared {
    static ExpenseRequest *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = ExpenseRequest.alloc.init;
    });
    return instance;
}

- (void)getExpensesWithMonth:(NSString *)month page:(NSInteger)page pageSize:(NSInteger)pageSize success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    NSMutableDictionary *params = NSMutableDictionary.dictionary;
    if (month.length > 0) {
        params[@"month"] = month;
    }
    params[@"pageNum"] = @(MAX(page, 1));
    params[@"pageSize"] = @(MAX(pageSize, 1));
    [[APIManager sharedManager] GET:APIPathValueExpenses parameters:params headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            NSArray *list = responseObject.data[@"list"];
            if (![list isKindOfClass:NSArray.class]) {
                list = [responseObject.data isKindOfClass:NSArray.class] ? responseObject.data : @[];
            }
            responseObject.dataObject = list;
            success(responseObject);
        } else {
            failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];
}

- (void)getExpenseSummaryWithMonth:(NSString *)month success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    NSMutableDictionary *params = NSMutableDictionary.dictionary;
    if (month.length > 0) {
        params[@"month"] = month;
    }
    [[APIManager sharedManager] GET:APIPathValueExpensesSummary parameters:params headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            success(responseObject);
        } else {
            failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];
}
@end
