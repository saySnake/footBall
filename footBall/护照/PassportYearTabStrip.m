//
//  PassportYearTabStrip.m
//  footBall
//

#import "PassportYearTabStrip.h"
#import <Masonry/Masonry.h>

@interface PassportYearTabStrip ()
@property (nonatomic, strong) UIStackView *stack;
@property (nonatomic, strong) NSArray<NSNumber *> *years;
@property (nonatomic, strong) NSMutableArray<UIButton *> *buttons;
@end

@implementation PassportYearTabStrip

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        _buttons = [NSMutableArray array];
        _stack = [[UIStackView alloc] init];
        _stack.axis = UILayoutConstraintAxisHorizontal;
        _stack.spacing = 8;
        _stack.distribution = UIStackViewDistributionFillEqually;
        _stack.alignment = UIStackViewAlignmentFill;
        [self addSubview:_stack];
        [_stack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self).insets(UIEdgeInsetsMake(8, 16, 8, 16));
        }];
    }
    return self;
}

- (void)setYears:(NSArray<NSNumber *> *)years selectedYear:(NSInteger)year {
    _years = [years copy];
    _selectedYear = year;
    for (UIView *v in _stack.arrangedSubviews) {
        [_stack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    [_buttons removeAllObjects];
    for (NSNumber *yn in years) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
        NSInteger yv = yn.integerValue;
        NSString *fmt = NSLocalizedString(@"passport_year_tab_format", nil) ?: @"%ld年";
        [b setTitle:[NSString stringWithFormat:fmt, (long)yv] forState:UIControlStateNormal];
        b.tag = yv;
        b.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        b.titleLabel.adjustsFontSizeToFitWidth = YES;
        b.titleLabel.minimumScaleFactor = 0.7;
        b.titleLabel.textAlignment = NSTextAlignmentCenter;
        b.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        [b setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [b setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [b addTarget:self action:@selector(onTap:) forControlEvents:UIControlEventTouchUpInside];
        [_stack addArrangedSubview:b];
        [_buttons addObject:b];
    }
    [self updateSelection];
}

- (void)onTap:(UIButton *)sender {
    self.selectedYear = sender.tag;
    [self updateSelection];
    if (self.onYearChanged) self.onYearChanged(self.selectedYear);
}

- (void)updateSelection {
    for (UIButton *b in _buttons) {
        BOOL on = b.tag == self.selectedYear;
        [b setTitleColor:on ? [UIColor colorWithHexString:@"#333333"] : [UIColor colorWithHexString:@"#999999"] forState:UIControlStateNormal];
        b.titleLabel.font = on ? FontManager.sharedManager.font18Regular : FontManager.sharedManager.font14Regular;
    }
}

@end
