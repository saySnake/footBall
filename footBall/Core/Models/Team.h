//
//  Team.h
//  footBall
//
//  Created by LWJ on 2026/3/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 球队简要（ID、名称、队徽）
@interface TeamIcon : NSObject <YYModel>
@property (nonatomic, strong) NSString *teamId;
/// 球队简称/显示名
@property (nonatomic, strong) NSString *name;
/// 队徽 URL
@property (nonatomic, strong) NSString *logo;
@end

@interface Team : TeamIcon
/// 英文名称
@property (nonatomic, strong) NSString *nameEn;
@property (nonatomic, strong) NSString *country;
@property (nonatomic, strong) NSString *leagueId;
@property (nonatomic, strong) NSString *followerCount;
@end

@interface TeamDetail : Team
/// 联赛名称
@property (nonatomic, strong) NSString *leagueName;
/// 当前用户是否已关注
@property (nonatomic, assign) BOOL followed;
@end

NS_ASSUME_NONNULL_END
