//
//  User.h
//  footBall
//
//  Created by LWJ on 2026/3/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface User : NSObject

@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSString *refreshToken;
@property (nonatomic, strong) NSString *nickname;
@property (nonatomic, strong) NSString *avatar;
@property (nonatomic, assign) NSInteger expiresIn;
@property (nonatomic, assign) BOOL isNewUser;
@property (nonatomic, assign) NSInteger onboardingCompleted;

@end

NS_ASSUME_NONNULL_END
