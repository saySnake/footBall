//
//  User.m
//  footBall
//
//  Created by LWJ on 2026/3/15.
//

#import "User.h"

@implementation User
+(instancetype)shared {
    static User *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = User.alloc.init;
    });
    return instance;
}
@end
