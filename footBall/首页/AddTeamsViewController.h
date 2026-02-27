//
//  AddTeamsViewController.h
//  footBall
//

#import "QMBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface AddTeamsViewController : QMBaseViewController
@property (nonatomic, strong) NSArray<NSString *> *preselectedTeamIds;
@property (nonatomic, copy) void (^onConfirmBlock)(NSArray<NSString *> *teamIds);
@end

NS_ASSUME_NONNULL_END

