#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class TeamIcon;

@interface PNPassport : NSObject <YYModel>
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *nickname;
@property (nonatomic, copy) NSString *avatar;
@property (nonatomic, copy) NSString *city;
@property (nonatomic, copy) NSString *passportCode;
@property (nonatomic, strong) NSArray<TeamIcon *> *followedTeams;
@property (nonatomic, assign) NSInteger yearTotalMatches;
@property (nonatomic, assign) NSInteger yearTotalWatchTime;
@property (nonatomic, copy) NSString *yearSpending;
@end

NS_ASSUME_NONNULL_END
