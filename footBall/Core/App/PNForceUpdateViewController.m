//
//  PNForceUpdateViewController.m
//  footBall
//

#import "PNForceUpdateViewController.h"
#import "PNAppVersionInfo.h"
#import <Masonry/Masonry.h>

@interface PNForceUpdateViewController ()

@property (nonatomic, strong) PNAppVersionInfo *info;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIButton *updateButton;

@end

@implementation PNForceUpdateViewController

- (instancetype)initWithVersionInfo:(PNAppVersionInfo *)info {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _info = info;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.051 green:0.129 blue:0.133 alpha:1.0];
    if (@available(iOS 13.0, *)) {
        self.modalInPresentation = YES;
    }

    _titleLabel = [UILabel new];
    _titleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightSemibold];
    _titleLabel.textColor = UIColor.whiteColor;
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.numberOfLines = 0;
    _titleLabel.text = self.info.updateTitle.length > 0
        ? self.info.updateTitle
        : NSLocalizedString(@"force_update_title", nil);
    [self.view addSubview:_titleLabel];

    _messageLabel = [UILabel new];
    _messageLabel.font = [UIFont systemFontOfSize:15];
    _messageLabel.textColor = [UIColor colorWithWhite:0.85 alpha:1.0];
    _messageLabel.textAlignment = NSTextAlignmentCenter;
    _messageLabel.numberOfLines = 0;
    _messageLabel.text = self.info.updateMessage.length > 0
        ? self.info.updateMessage
        : NSLocalizedString(@"force_update_message", nil);
    [self.view addSubview:_messageLabel];

    _updateButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _updateButton.backgroundColor = [UIColor colorWithRed:0.298 green:0.851 blue:0.392 alpha:1.0];
    _updateButton.layer.cornerRadius = 8;
    [_updateButton setTitle:(NSLocalizedString(@"force_update_button", nil) ?: @"立即更新") forState:UIControlStateNormal];
    [_updateButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    _updateButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    [_updateButton addTarget:self action:@selector(onUpdateTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_updateButton];

    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.leading.greaterThanOrEqualTo(self.view).offset(32);
        make.trailing.lessThanOrEqualTo(self.view).offset(-32);
        make.centerY.equalTo(self.view).offset(-60);
    }];
    [_messageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(16);
        make.leading.trailing.equalTo(_titleLabel);
    }];
    [_updateButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.messageLabel.mas_bottom).offset(32);
        make.centerX.equalTo(self.view);
        make.width.mas_equalTo(240);
        make.height.mas_equalTo(48);
    }];
}

- (void)onUpdateTapped {
    NSString *urlString = self.info.storeUrl;
    if (urlString.length == 0) {
        // 未配置商店链接时至少给出反馈，避免按钮无响应
        NSString *msg = NSLocalizedString(@"force_update_no_store_url", nil);
        if (msg.length == 0 || [msg isEqualToString:@"force_update_no_store_url"]) {
            msg = @"暂未配置更新地址，请前往 App Store 搜索更新";
        }
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                       message:msg
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) ?: @"好的"
                                                  style:UIAlertActionStyleDefault
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) return;
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
}

@end
