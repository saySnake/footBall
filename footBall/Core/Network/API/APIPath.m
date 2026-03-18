//
//  APIPath.m
//  footBall
//
//  Created by LWJ on 2026/3/14.
//

#import "APIPath.h"

@implementation APIPath
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.host = @"https://112.126.56.42";
        [self setupURL];
    }
    return self;
}
- (void)setupURL{
    self.sendCode = [NSString stringWithFormat:@"%@/api/v1/auth/send-code",self.host];
    self.loginPhone = [NSString stringWithFormat:@"%@/api/v1/auth/login/phone",self.host];
    self.refreshToken = [NSString stringWithFormat:@"%@/api/v1/auth/refresh",self.host];
    self.logout = [NSString stringWithFormat:@"%@/api/v1/auth/logout",self.host];
}
@end
