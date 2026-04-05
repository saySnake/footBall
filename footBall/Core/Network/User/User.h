//
//  User.h
//  footBall
//
//  Created by LWJ on 2026/3/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class UserProfile;
@interface User : NSObject <YYModel>

@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSString *refreshToken;
@property (nonatomic, strong) NSString *nickname;
/// 登录等接口可能在根节点返回手机号（与 profile.phone 二选一或并存）
@property (nonatomic, strong, nullable) NSString *phone;
@property (nonatomic, strong) NSString *avatar;
@property (nonatomic, assign) NSInteger expiresIn;
@property (nonatomic, assign) BOOL isNewUser;
@property (nonatomic, assign) BOOL onboardingCompleted;

@property (nonatomic, strong, nullable) UserProfile *profile;

@end

typedef NS_ENUM(NSUInteger, UserGender) {
    UserGenderUnknow, /// 未知
    UserGenderMale, /// 男
    UserGenderFemale, /// 女
};

@interface UserProfile : NSObject
/// 用户ID
@property (nonatomic, strong) NSString *userId;
/// 昵称
@property (nonatomic, strong) NSString *nickname;
/// 手机号（接口返回，部分环境字段名为 mobile）
@property (nonatomic, strong, nullable) NSString *phone;
/// 头像URL
@property (nonatomic, strong) NSString *avatar;
/// 性别: 0-未知, 1-男, 2-女
@property (nonatomic, assign) UserGender gender;
/// 出生日期
@property (nonatomic, strong) NSString *birthDate;
/// 星座（自动计算）
@property (nonatomic, strong) NSString *zodiac;
/// 世代标签（60后/70后/80后/90后/95后/00后/05后）
@property (nonatomic, strong) NSString *generationTag;
/// 个人简介
@property (nonatomic, strong) NSString *bio;
/// 所在城市
@property (nonatomic, strong) NSString *city;
/// 护照代号（用户DIY）
@property (nonatomic, strong) NSString *passportCode;
/// 第一次看球年份
@property (nonatomic, strong) NSString *firstWatchYear;
/// 主队ID
@property (nonatomic, strong) NSString *primaryTeamId;
/// 国家队主队ID
@property (nonatomic, strong) NSString *nationalTeamId;
/// 观赛偏好标签
@property (nonatomic, strong) NSArray <NSString *> *preferenceTags;
/// 二维码URL
@property (nonatomic, strong) NSString *qrCode;
/// 最后在线时间
@property (nonatomic, strong) NSString *lastOnlineTime;
/// 引导完成状态: 0-否, 1-是
@property (nonatomic, assign) BOOL onboardingCompleted;

@end

NS_ASSUME_NONNULL_END
