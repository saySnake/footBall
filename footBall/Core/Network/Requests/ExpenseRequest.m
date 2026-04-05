//
//  ExpenseRequest.m
//  footBall
//
//  写操作成功时尝试将 data 转为 PNExpense，失败则回退为原始 data。
//

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

- (void)createExpenseWithBody:(NSDictionary *)body success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (![body isKindOfClass:NSDictionary.class] || body.count == 0) {
        if (failure) failure([NSError errorWithDomain:@"ExpenseRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"请求体不能为空" }]);
        return;
    }
    [[APIManager sharedManager] POST:APIPathValueExpenses parameters:body headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            PNExpense *exp = [PNExpense yy_modelWithJSON:responseObject.data];
            responseObject.dataObject = exp ?: responseObject.data;
            if (success) success(responseObject);
        } else {
            if (failure) failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

- (void)updateExpense:(NSString *)expenseId body:(NSDictionary *)body success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (expenseId.length == 0) {
        if (failure) failure([NSError errorWithDomain:@"ExpenseRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"消费记录ID不能为空" }]);
        return;
    }
    if (![body isKindOfClass:NSDictionary.class]) {
        if (failure) failure([NSError errorWithDomain:@"ExpenseRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"请求体无效" }]);
        return;
    }
    [[APIManager sharedManager] PUT:APIPathValueExpensesDetail(expenseId) parameters:body headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            PNExpense *exp = [PNExpense yy_modelWithJSON:responseObject.data];
            responseObject.dataObject = exp ?: responseObject.data;
            if (success) success(responseObject);
        } else {
            if (failure) failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

- (void)deleteExpense:(NSString *)expenseId success:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    if (expenseId.length == 0) {
        if (failure) failure([NSError errorWithDomain:@"ExpenseRequestErrorDomain" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"消费记录ID不能为空" }]);
        return;
    }
    [[APIManager sharedManager] DELETE:APIPathValueExpensesDetail(expenseId) parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
        if (responseObject.success) {
            responseObject.dataObject = responseObject.data;
            if (success) success(responseObject);
        } else {
            if (failure) failure([APIError errorWithResponse:responseObject]);
        }
    } failure:^(NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

@end
