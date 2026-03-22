//
//  MatchRequest.m
//  footBall
//
//  Created by LWJ on 2026/3/22.
//

#import "MatchRequest.h"

@implementation MatchRequest
- (void)getFeaturesMatchsSuccess:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    [[APIManager sharedManager] GET:APIPathValueMatchFeatured parameters:nil headers:nil success:^(HTTPResponse * _Nullable responseObject) {
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
