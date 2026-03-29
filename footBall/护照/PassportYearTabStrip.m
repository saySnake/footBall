//
//  PassportYearTabStrip.m
//  footBall
//

#import "PassportYearTabStrip.h"
#import <Masonry/Masonry.h>

@interface PassportYearTabStrip ()
@property (nonatomic, strong) UIScrollView *scroll;
@property (nonatomic, strong) UIStackView *stack;
@property (nonatomic, strong) NSArray<NSNumber *> *years;
@property (nonatomic, strong) NSMutableArray<UIButton *> *buttons;
@end

@implementation PassportYearTabStrip

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        _buttons = [NSMutableArray array];
        _scroll = [[UIScrollView alloc] init];
        _scroll.showsHorizontalScrollIndicator = NO;
        [self addSubview:_scroll];
        _stack = [[UIStackView alloc] init];
        _stack.axis = UILayoutConstraintAxisHorizontal;
        _stack.spacing = 20;
        _stack.alignment = UIStackViewAlignmentCenter;
        [_scroll addSubview:_stack];
        [_scroll mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
        [_stack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(_scroll).insets(UIEdgeInsetsMake(8, 16, 8, 16));
            make.height.equalTo(_scroll);
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
        [b setTitleColor:on ? [UIColor whiteColor] : [UIColor colorWithWhite:1 alpha:0.45] forState:UIControlStateNormal];
        b.titleLabel.font = [UIFont systemFontOfSize:14 weight:on ? UIFontWeightSemibold : UIFontWeightMedium];
    }
}

@end
