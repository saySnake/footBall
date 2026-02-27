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
/// 可选：自定义年份范围（仅 PNPickerSheetModeDate 生效）。默认 0 表示使用内部的近年范围。
@property (nonatomic, assign) NSInteger minYear;
@property (nonatomic, assign) NSInteger maxYear;

@end

NS_ASSUME_NONNULL_END

