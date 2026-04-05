//
//  PrivacyModels.h
//  footBall
//
//  对应 PrivacySettingsVO。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PNPrivacySettings : NSObject <YYModel>
/// 护照可见性：PUBLIC / FRIENDS / PRIVATE
@property (nonatomic, copy, nullable) NSString *passportVisibility;
/// 允许陌生人加好友：0 否，1 是
@property (nonatomic, assign) NSInteger allowStrangerFriendRequest;
/// 是否可被搜索：0 否，1 是
@property (nonatomic, assign) NSInteger showInSearch;
@end

NS_ASSUME_NONNULL_END
