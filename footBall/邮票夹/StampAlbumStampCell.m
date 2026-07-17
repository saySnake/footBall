//
//  StampAlbumStampCell.m
//  footBall
//

#import "StampAlbumStampCell.h"
#import "StampModels.h"
#import <SDWebImage/SDWebImage.h>

/// 与十宫格线一致
static UIColor *StampAlbumGridBorderColor(void) {
    return [UIColor colorWithWhite:0.88 alpha:1.0];
}
static const CGFloat kStampAlbumGridBorderWidth = 0.5;

@interface StampAlbumStampCell ()
@property (nonatomic, strong) UIView *circleView;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UIView *lineRight;
@property (nonatomic, strong) UIView *lineBottom;
@end

@implementation StampAlbumStampCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.contentView.backgroundColor = [UIColor whiteColor];
        _circleView = [[UIView alloc] init];
        _circleView.clipsToBounds = YES;
        [self.contentView addSubview:_circleView];
        _iconView = [[UIImageView alloc] init];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        _iconView.tintColor = [UIColor whiteColor];
        [self.contentView addSubview:_iconView];
        UIColor *grid = StampAlbumGridBorderColor();
        _lineRight = [[UIView alloc] init];
        _lineRight.backgroundColor = grid;
        _lineBottom = [[UIView alloc] init];
        _lineBottom.backgroundColor = grid;
        [self.contentView addSubview:_lineRight];
        [self.contentView addSubview:_lineBottom];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = CGRectGetWidth(self.bounds);
    CGFloat h = CGRectGetHeight(self.bounds);
    CGFloat outer = MIN(w, h);
    if (outer < 2) {
        outer = 2;
    }
    _circleView.layer.cornerRadius = outer * 0.5;
    _circleView.frame = CGRectMake((w - outer) * 0.5, (h - outer) * 0.5, outer, outer);
    // 略小于外圆，露出边框（与宫格线同宽）
    CGFloat iconD = MAX(0, outer - kStampAlbumGridBorderWidth * 2);
    _iconView.layer.cornerRadius = iconD * 0.5;
    _iconView.clipsToBounds = YES;
    _iconView.frame = CGRectMake((w - iconD) * 0.5, (h - iconD) * 0.5, iconD, iconD);
    _lineRight.frame = CGRectMake(w - kStampAlbumGridBorderWidth, 0, kStampAlbumGridBorderWidth, h);
    _lineBottom.frame = CGRectMake(0, h - kStampAlbumGridBorderWidth, w, kStampAlbumGridBorderWidth);
}

- (void)configureWithStampItem:(PNStampAlbumItem *)item
              indexPath:(NSIndexPath *)indexPath
             totalCount:(NSInteger)total
            columnCount:(NSInteger)columns {
    NSInteger cols = MAX(1, columns);
    NSInteger col = indexPath.item % cols;
    NSInteger row = indexPath.item / cols;
    NSInteger rows = total > 0 ? (total + cols - 1) / cols : 0;
    _lineRight.hidden = (col == cols - 1);
    _lineBottom.hidden = (rows > 0 && row == rows - 1);

    BOOL emptySlot = !item || ![item.stampId isKindOfClass:NSString.class] || item.stampId.length == 0;
    _circleView.backgroundColor = [UIColor whiteColor];
    _circleView.layer.borderWidth = kStampAlbumGridBorderWidth;
    _circleView.layer.borderColor = StampAlbumGridBorderColor().CGColor;
    if (emptySlot) {
        _iconView.hidden = YES;
        _iconView.image = nil;
        _iconView.layer.borderWidth = 0;
        return;
    }

//    _circleView.backgroundColor = StampRarityColor(item.rarity);
    _iconView.hidden = NO;
    _iconView.layer.borderWidth = 0;
    if (item.image.length > 0) {
        _iconView.contentMode = UIViewContentModeScaleAspectFill;
        [_iconView sd_setImageWithURL:[NSURL URLWithString:item.image] placeholderImage:nil];
    } else {
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        if (@available(iOS 15.0, *)) {
            UIImage *img = [UIImage systemImageNamed:@"photo"];
            _iconView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        } else {
            _iconView.image = nil;
        }
    }
}

//static UIColor *StampRarityColor(NSString *rarity) {
//    NSString *r = [rarity isKindOfClass:NSString.class] ? [(NSString *)rarity uppercaseString] : @"";
//    if ([r isEqualToString:@"LEGENDARY"]) return [UIColor colorWithHexString:@"#D9B44A"];
//    if ([r isEqualToString:@"EPIC"]) return [UIColor colorWithHexString:@"#8E62D9"];
//    if ([r isEqualToString:@"RARE"]) return [UIColor colorWithHexString:@"#3C6FD9"];
//    return [UIColor colorWithHexString:@"#7C9A8B"]; // COMMON / fallback
//}

@end
