//
//  Team.h
//  footBall
//
//  Created by LWJ on 2026/3/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface TeamIcon : NSObject <YYModel>
@property (nonatomic, strong) NSString *teamId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *logo;
@end
@interface Team : TeamIcon
@property (nonatomic, strong) NSString *nameEn;
@property (nonatomic, strong) NSString *country;
@property (nonatomic, strong) NSString *leagueId;
@property (nonatomic, strong) NSString *followerCount;
@end
@interface TeamDetail : Team
@property (nonatomic, strong) NSString *leagueName;
@property (nonatomic, assign) BOOL followed;
@end
NS_ASSUME_NONNULL_END
