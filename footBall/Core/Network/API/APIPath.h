//
//  APIPath.h
//  footBall
//
//  Created by LWJ on 2026/3/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface APIPath : NSObject
@property (nonatomic, strong) NSString *host;

@property (nonatomic, strong) NSString *sendCode;//发送验证码
@property (nonatomic, strong) NSString *loginPhone;//发送验证码
@property (nonatomic, strong) NSString *refreshToken;//刷新token
@property (nonatomic, strong) NSString *logout;//登出
@end

NS_ASSUME_NONNULL_END
