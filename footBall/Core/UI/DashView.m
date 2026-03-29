//
//  DashView.m
//  footBall
//
//  Created by LWJ on 2026/3/29.
//

#import "DashView.h"

@implementation DashView
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _lineColor=[UIColor colorWithWhite:181/255.f alpha:1];
        _lineWidth=5.f;
        self.backgroundColor=[UIColor clearColor];
    }
    return self;
}
-(void)setLineColor:(UIColor *)lineColor{
    _lineColor=lineColor;
    [self setNeedsDisplay];
}
-(void)setLineWidth:(CGFloat)lineWidth{
    _lineWidth=lineWidth;
    [self setNeedsDisplay];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    //设置虚线颜色
    CGContextSetStrokeColorWithColor(currentContext, _lineColor.CGColor);
    //设置虚线宽度
    CGContextSetLineWidth(currentContext, self.height);
    //设置虚线绘制起点
    CGContextMoveToPoint(currentContext, 0, self.height/2);
    //设置虚线绘制终点
    CGContextAddLineToPoint(currentContext, self.frame.size.width,self.height/2);
    //设置虚线排列的宽度间隔:下面的arr中的数字表示先绘制3个点再绘制1个点
    CGFloat arr[] = {5,2};
    //下面最后一个参数“2”代表排列的个数。
    CGContextSetLineDash(currentContext, 0, arr, 2);
    CGContextDrawPath(currentContext, kCGPathStroke);
    
}

@end
