//
//  HTTPResponse.m
//  footBall
//
//  Created by LWJ on 2026/3/16.
//

#import "HTTPResponse.h"
#import <YYModel/YYModel.h>

@implementation HTTPResponse

+ (NSDictionary<NSString *,id> *)modelCustomPropertyMapper {
    return @{
        @"success": @[@"success", @"ok"],
        @"errorCode": @[@"errorCode", @"code", @"status", @"errCode"],
        @"errorMessage": @[@"errorMessage", @"message", @"msg", @"errorMsg"],
        @"data": @[@"data", @"result", @"payload"],
    };
}

- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    // 当后端未显式返回 success 时，尝试从 code 推导。
    if (dic[@"success"] == nil && dic[@"ok"] == nil) {
        id code = dic[@"errorCode"] ?: dic[@"code"] ?: dic[@"status"] ?: dic[@"errCode"];
        if ([code respondsToSelector:@selector(integerValue)]) {
            NSInteger c = [code integerValue];
            self.success = (c == 0 || c == 200);
        }
    }
    return YES;
}

@end
