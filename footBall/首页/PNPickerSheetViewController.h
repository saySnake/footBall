//
//  PNPickerSheetViewController.h
//  footBall
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PNPickerSheetMode) {
    PNPickerSheetModeDate,
    PNPickerSheetModeTime,
};

@interface PNPickerSheetViewController : UIViewController

@property (nonatomic, assign) PNPickerSheetMode mode;
@property (nonatomic, strong, nullable) NSDate *selectedDate; // date 或 time 都用它承载
@property (nonatomic, copy, nullable) void (^onConfirm)(NSDate *date);

@end

NS_ASSUME_NONNULL_END

