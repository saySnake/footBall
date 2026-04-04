//
//  StampDashView.h
//  footBall
//
//  邮票齿孔式横向虚线：重复竖向圆角胶囊（非沿路径的 line dash）。
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface StampDashView : UIView

/// 胶囊填充色，默认 #DBDBDB
@property (nonatomic, strong) UIColor *stampColor;

/// 单粒胶囊高度相对视图高度的比例（0~1），默认 0.88
@property (nonatomic, assign) CGFloat capsuleHeightFactor;

/// 胶囊高度 / 宽度，约 2～2.5，默认 2.25
@property (nonatomic, assign) CGFloat capsuleAspect;

/// 间隙宽度 = 胶囊宽度 × 该系数，默认 1（与胶囊宽度约 1:1）
@property (nonatomic, assign) CGFloat gapToWidthRatio;

@end

NS_ASSUME_NONNULL_END
