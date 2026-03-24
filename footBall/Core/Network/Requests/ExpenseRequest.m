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
            PNExpensePage *pageModel = [PNExpensePage yy_modelWithJSON:responseObject.data];
            if (!pageModel && [responseObject.data isKindOfClass:NSArray.class]) {
                pageModel = [PNExpensePage new];
                pageModel.list = [NSArray yy_modelArrayWithClass:PNExpense.class json:responseObject.data];
            }
            responseObject.dataObject = pageModel;
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
            PNExpenseSummary *summary = [PNExpenseSummary yy_modelWithJSON:responseObject.data];
            responseObject.dataObject = summary;
            success(responseObject);
        } else {
            failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];
}
@end
