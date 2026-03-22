//
//  Team.h
//  footBall
//
//  Created by LWJ on 2026/3/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Team : NSObject <YYModel>
@property (nonatomic, strong) NSString *teamId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *nameEn;
@property (nonatomic, strong) NSString *logo;
@property (nonatomic, strong) NSString *country;
@property (nonatomic, strong) NSString *leagueId;
@property (nonatomic, strong) NSString *followerCount;
/// 详情接口才有的字段
@property (nonatomic, strong) NSString *leagueName;
@property (nonatomic, assign) BOOL followed;
@end

NS_ASSUME_NONNULL_END
