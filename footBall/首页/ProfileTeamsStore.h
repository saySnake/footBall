//
//  ProfileTeamsStore.h
//  footBall
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProfileTeamItem : NSObject
@property (nonatomic, copy) NSString *teamId;      // stable id for storage
@property (nonatomic, copy) NSString *nameKey;     // Localizable key for name
@property (nonatomic, copy) NSString *iconName;    // SF Symbol name (fake image)
@property (nonatomic, strong) UIColor *tintColor;
@end

@interface ProfileTeamsStore : NSObject

+ (NSArray<ProfileTeamItem *> *)allTeams;
+ (NSArray<NSString *> *)defaultFollowedTeamIds;

+ (NSArray<NSString *> *)loadFollowedTeamIds;
+ (void)saveFollowedTeamIds:(NSArray<NSString *> *)teamIds;

+ (NSArray<ProfileTeamItem *> *)teamsForIds:(NSArray<NSString *> *)teamIds;

@end

NS_ASSUME_NONNULL_END

