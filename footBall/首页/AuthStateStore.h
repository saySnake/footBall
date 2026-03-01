//
//  AuthStateStore.h
//  footBall
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AuthStateStore : NSObject

#pragma mark - 实名认证
+ (BOOL)isRealNameAuthCompleted;
+ (void)setRealNameAuthCompleted:(BOOL)completed;
+ (void)saveRealNameFrontImage:(nullable UIImage *)front backImage:(nullable UIImage *)back;
+ (nullable UIImage *)realNameFrontImage;
+ (nullable UIImage *)realNameBackImage;

#pragma mark - 职业认证
+ (BOOL)isProfessionalAuthCompleted;
+ (void)setProfessionalAuthCompleted:(BOOL)completed;
+ (void)saveProfessionalImages:(NSArray<UIImage *> *)images;
+ (NSArray<UIImage *> *)professionalImages;

@end

NS_ASSUME_NONNULL_END
