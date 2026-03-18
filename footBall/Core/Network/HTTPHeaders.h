//
//  HTTPHeaders.h
//  footBall
//
//  Created by LWJ on 2026/3/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HTTPHeaders : NSObject
+ (NSDictionary *)commonHeaders;
+ (void)setupRequestSerializer:(AFHTTPRequestSerializer *)serializer;
@end

NS_ASSUME_NONNULL_END
