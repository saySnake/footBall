//
//  PassportYearTabStrip.h
//  footBall
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PassportYearTabStrip : UIView
@property (nonatomic, assign) NSInteger selectedYear;
@property (nonatomic, copy, nullable) void (^onYearChanged)(NSInteger year);
- (void)setYears:(NSArray<NSNumber *> *)years selectedYear:(NSInteger)year;
@end

NS_ASSUME_NONNULL_END
