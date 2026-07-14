//
//  PNCommonAlertViewController.m
//  footBall
//

#import "PNCommonAlertViewController.h"
#import <Masonry/Masonry.h>
#import "ColorManager.h"

#define kAlertGreen [ColorManager sharedManager].primaryColor

@interface PNCommonAlertViewController ()
@property (nonatomic, strong) UIView *dimmingView;
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIButton *cancelBtn;
@property (nonatomic, strong) UIButton *confirmBtn;
@end

@implementation PNCommonAlertViewController

- (instancetype)init {
    if (self = [super init]) {
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        _alertTitle = @"";
        _message = @"";
        _cancelTitle = NSLocalizedString(@"cancel", nil) ?: @"取消";
        _confirmTitle = NSLocalizedString(@"confirm", nil) ?: @"确认";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];

    UIView *dim = [UIView new];
    dim.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.35];
    [self.view addSubview:dim];
    self.dimmingView = dim;
    [dim mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self.view); }];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapDim)];
    [dim addGestureRecognizer:tap];

    UIView *card = [UIView new];
    card.backgroundColor = [UIColor whiteColor];
    card.layer.cornerRadius = 14;
    card.clipsToBounds = YES;
    [self.view addSubview:card];
    self.cardView = card;
    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.leading.greaterThanOrEqualTo(self.view).offset(48);
        make.trailing.lessThanOrEqualTo(self.view).offset(-48);
        make.width.mas_equalTo(280);
    }];

    self.titleLabel = [UILabel new];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    self.titleLabel.textColor = [UIColor blackColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.text = self.alertTitle;
    [card addSubview:self.titleLabel];

    self.messageLabel = [UILabel new];
    self.messageLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    // 设计稿正文为主题绿
    self.messageLabel.textColor = kAlertGreen;
    self.messageLabel.textAlignment = NSTextAlignmentCenter;
    self.messageLabel.numberOfLines = 0;
    self.messageLabel.text = self.message;
    [card addSubview:self.messageLabel];

    self.cancelBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    self.cancelBtn.backgroundColor = [UIColor colorWithWhite:0.93 alpha:1.0];
    self.cancelBtn.layer.cornerRadius = 18;
    self.cancelBtn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    [self.cancelBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.cancelBtn setTitle:self.cancelTitle forState:UIControlStateNormal];
    [self.cancelBtn addTarget:self action:@selector(onCancelTapped) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:self.cancelBtn];

    self.confirmBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    // 设计稿确认钮统一为主题绿；destructive 保留红色能力但业务按设计可不启用
    self.confirmBtn.backgroundColor = self.confirmDestructive
        ? [UIColor colorWithRed:0.92 green:0.26 blue:0.21 alpha:1.0]
        : kAlertGreen;
    self.confirmBtn.layer.cornerRadius = 18;
    self.confirmBtn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    [self.confirmBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.confirmBtn setTitle:self.confirmTitle forState:UIControlStateNormal];
    [self.confirmBtn addTarget:self action:@selector(onConfirmTapped) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:self.confirmBtn];

    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(card).offset(22);
        make.leading.trailing.equalTo(card).insets(UIEdgeInsetsMake(0, 16, 0, 16));
    }];
    [self.messageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(14);
        make.leading.trailing.equalTo(card).insets(UIEdgeInsetsMake(0, 20, 0, 20));
    }];
    [self.cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.messageLabel.mas_bottom).offset(20);
        make.leading.equalTo(card).offset(20);
        make.height.mas_equalTo(36);
        make.bottom.equalTo(card).offset(-20);
        make.trailing.equalTo(card.mas_centerX).offset(-8);
    }];
    [self.confirmBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.height.bottom.equalTo(self.cancelBtn);
        make.leading.equalTo(card.mas_centerX).offset(8);
        make.trailing.equalTo(card).offset(-20);
    }];
}

- (void)onTapDim {
    [self onCancelTapped];
}

- (void)onCancelTapped {
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.onCancel) self.onCancel();
    }];
}

- (void)onConfirmTapped {
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.onConfirm) self.onConfirm();
    }];
}

@end

