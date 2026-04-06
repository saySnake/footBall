//
//  StampAlbumStampCell.m
//  footBall
//

#import "StampAlbumStampCell.h"
#import "StampAlbumModels.h"
#import "StampModels.h"
#import <SDWebImage/SDWebImage.h>

/// 图标（圆内图片）直径比外圆直径小 20pt
static const CGFloat kStampCircleIconDiameterDelta = 20;

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
        UIColor *grid = [UIColor colorWithWhite:0.88 alpha:1.0];
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
    CGFloat outer = MIN(w, h) * 0.72;
    if (outer < 2) {
        outer = 2;
    }
    _circleView.layer.cornerRadius = outer * 0.5;
    _circleView.frame = CGRectMake((w - outer) * 0.5, (h - outer) * 0.5, outer, outer);
    CGFloat iconD = MAX(0, outer - kStampCircleIconDiameterDelta);
    _iconView.layer.cornerRadius = iconD * 0.5;
    _iconView.clipsToBounds = YES;
    _iconView.frame = CGRectMake((w - iconD) * 0.5, (h - iconD) * 0.5, iconD, iconD);
    _lineRight.frame = CGRectMake(w - 0.5, 0, 0.5, h);
    _lineBottom.frame = CGRectMake(0, h - 0.5, w, 0.5);
}

- (void)configureWithItem:(StampAlbumItem *)item
              indexPath:(NSIndexPath *)indexPath
             totalCount:(NSInteger)total
            columnCount:(NSInteger)columns {
    if (!item) {
        _lineRight.hidden = YES;
        _lineBottom.hidden = YES;
        _circleView.backgroundColor = [UIColor whiteColor];
        _iconView.hidden = YES;
        return;
    }
    NSInteger cols = MAX(1, columns);
    NSInteger col = indexPath.item % cols;
    NSInteger row = indexPath.item / cols;
    NSInteger rows = total > 0 ? (total + cols - 1) / cols : 0;
    _lineRight.hidden = (col == cols - 1);
    _lineBottom.hidden = (rows > 0 && row == rows - 1);
    if (item.unlocked) {
        _circleView.backgroundColor = item.circleColor ?: [UIColor colorWithWhite:0.75 alpha:1.0];
        _circleView.layer.borderWidth = 1;
        _circleView.layer.borderColor = [UIColor colorWithWhite:0.35 alpha:0.35].CGColor;
        _iconView.hidden = NO;
        if (item.imageURL.length > 0) {
            _iconView.contentMode = UIViewContentModeScaleAspectFill;
            [_iconView sd_setImageWithURL:[NSURL URLWithString:item.imageURL] placeholderImage:nil];
        } else {
            _iconView.contentMode = UIViewContentModeScaleAspectFit;
            if (@available(iOS 15.0, *)) {
                UIImage *img = [UIImage systemImageNamed:@"sportscourt.fill"];
                _iconView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            } else {
                UIImage *img = [UIImage systemImageNamed:@"building.2.fill"];
                _iconView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            }
        }
    } else {
        _circleView.backgroundColor = [UIColor whiteColor];
        _circleView.layer.borderWidth = 1.5;
        _circleView.layer.borderColor = [UIColor colorWithWhite:0.82 alpha:1.0].CGColor;
        _iconView.hidden = YES;
        [_iconView sd_cancelCurrentImageLoad];
        _iconView.image = nil;
    }
}

static UIColor *StampRarityColor(NSString *rarity) {
    NSString *r = [rarity isKindOfClass:NSString.class] ? [(NSString *)rarity uppercaseString] : @"";
    if ([r isEqualToString:@"LEGENDARY"]) return [UIColor colorWithHexString:@"#D9B44A"];
    if ([r isEqualToString:@"EPIC"]) return [UIColor colorWithHexString:@"#8E62D9"];
    if ([r isEqualToString:@"RARE"]) return [UIColor colorWithHexString:@"#3C6FD9"];
    return [UIColor colorWithHexString:@"#7C9A8B"]; // COMMON / fallback
}

- (void)configureWithStamp:(PNStampGridItem *)stamp
                 indexPath:(NSIndexPath *)indexPath
                totalCount:(NSInteger)total
               columnCount:(NSInteger)columns {
    if (!stamp) {
        _lineRight.hidden = YES;
        _lineBottom.hidden = YES;
        _circleView.backgroundColor = [UIColor whiteColor];
        _circleView.layer.borderWidth = 0;
        _iconView.hidden = YES;
        [_iconView sd_cancelCurrentImageLoad];
        _iconView.image = nil;
        return;
    }

    NSInteger cols = MAX(1, columns);
    NSInteger col = indexPath.item % cols;
    NSInteger row = indexPath.item / cols;
    NSInteger rows = total > 0 ? (total + cols - 1) / cols : 0;
    _lineRight.hidden = (col == cols - 1);
    _lineBottom.hidden = (rows > 0 && row == rows - 1);

    BOOL unlocked = stamp.unlocked;
    if (unlocked) {
        _circleView.backgroundColor = StampRarityColor(stamp.rarity);
        _circleView.layer.borderWidth = 1;
        _circleView.layer.borderColor = [UIColor colorWithWhite:0.25 alpha:0.25].CGColor;
        _iconView.hidden = NO;
        _iconView.tintColor = [UIColor clearColor];
        _iconView.contentMode = UIViewContentModeScaleAspectFill;
        if (stamp.image.length > 0) {
            [_iconView sd_setImageWithURL:[NSURL URLWithString:stamp.image] placeholderImage:nil];
        } else {
            [_iconView sd_cancelCurrentImageLoad];
            _iconView.image = nil;
        }
        self.contentView.alpha = 1.0;
    } else {
        _circleView.backgroundColor = [UIColor whiteColor];
        _circleView.layer.borderWidth = 1.5;
        _circleView.layer.borderColor = [UIColor colorWithWhite:0.82 alpha:1.0].CGColor;
        _iconView.hidden = YES;
        [_iconView sd_cancelCurrentImageLoad];
        _iconView.image = nil;
        self.contentView.alpha = 1.0;
    }
}

@end
