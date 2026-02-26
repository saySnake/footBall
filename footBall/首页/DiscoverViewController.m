//
//  DiscoverViewController.m
//  footBall
//

#import "DiscoverViewController.h"
#import <Masonry/Masonry.h>

@interface DiscoverViewController ()
@property (nonatomic, strong) UILabel *tipLabel;
@end

@implementation DiscoverViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self setNavigationTitleKey:@"tab_discover"];
    self.tipLabel = [[UILabel alloc] init];
    self.tipLabel.text = NSLocalizedString(@"tab_discover", nil);
    self.tipLabel.font = [UIFont systemFontOfSize:18];
    self.tipLabel.textColor = [UIColor darkGrayColor];
    self.tipLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.tipLabel];
    [self.tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];
}

- (void)updateLocalizedStrings {
    [super updateLocalizedStrings];
    self.tipLabel.text = NSLocalizedString(@"tab_discover", nil);
}

@end
