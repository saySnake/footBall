//
//  EasyDebugPositionConfig.h
//  footBall
//
//  EasyDebug 按钮位置配置
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * EasyDebug 按钮位置配置
 * 用于自定义 EasyDebug 入口按钮在屏幕上的位置
 */
@interface EasyDebugPositionConfig : NSObject

/**
 * 配置按钮位置
 * 
 * @param position 位置枚举：
 *   - 0: 左下角（默认）
 *   - 1: 右下角
 *   - 2: 左上角
 *   - 3: 右上角
 *   - 4: 底部居中
 *   - 5: 顶部居中
 *   - 6: 左侧居中
 *   - 7: 右侧居中
 * 
 * @param offsetX X 轴偏移量（正数向右，负数向左）
 * @param offsetY Y 轴偏移量（正数向下，负数向上）
 */
+ (void)configButtonPosition:(NSInteger)position 
                     offsetX:(CGFloat)offsetX 
                     offsetY:(CGFloat)offsetY;

/**
 * 使用自定义坐标配置按钮位置
 * 
 * @param x X 坐标（相对于屏幕）
 * @param y Y 坐标（相对于屏幕）
 */
+ (void)configButtonPositionWithX:(CGFloat)x y:(CGFloat)y;

/**
 * 使用百分比配置按钮位置
 * 
 * @param xPercent X 坐标百分比（0.0 - 1.0，0.0 为左侧，1.0 为右侧）
 * @param yPercent Y 坐标百分比（0.0 - 1.0，0.0 为顶部，1.0 为底部）
 */
+ (void)configButtonPositionWithXPercent:(CGFloat)xPercent yPercent:(CGFloat)yPercent;

@end

NS_ASSUME_NONNULL_END
