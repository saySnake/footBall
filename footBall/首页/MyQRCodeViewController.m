//
//  MyQRCodeViewController.m
//  footBall
//

#import "MyQRCodeViewController.h"
#import <Masonry/Masonry.h>
#import <CoreImage/CoreImage.h>
#import "ColorManager.h"

#define kQRGreen   [ColorManager sharedManager].primaryColor
#define kQRBgColor [ColorManager sharedManager].primaryDarkColor

@interface MyQRCodeViewController ()
@property (nonatomic, strong) UILabel *navTitleLabel;
@property (nonatomic, strong) UIView  *cardView;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *idLabel;
@property (nonatomic, strong) UIImageView *qrImageView;
@property (nonatomic, strong) UILabel *hintLabel;
@property (nonatomic, strong) UIButton *saveBtn;
@end

@implementation MyQRCodeViewController

- (void)viewDidLoad {
    self.hidesBottomBarWhenPushed = YES;
    [super viewDidLoad];
    self.shouldShowNavigationBar = NO;
    self.view.backgroundColor = kQRBgColor;
}

- (void)setupUI {
    // 顶部导航栏
    UIView *navBar = [UIView new];
    navBar.backgroundColor = [UIColor clearColor];
    [self.view addSubview:navBar];
    [navBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
        make.height.mas_equalTo(88);
    }];

    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    if (@available(iOS 13.0, *)) {
        [backBtn setImage:[UIImage systemImageNamed:@"arrow.left"] forState:UIControlStateNormal];
    }
    backBtn.tintColor = [UIColor whiteColor];
    [backBtn addTarget:self action:@selector(onBack) forControlEvents:UIControlEventTouchUpInside];
    [navBar addSubview:backBtn];
    [backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(navBar).offset(16);
        make.bottom.equalTo(navBar).offset(-12);
        make.size.mas_equalTo(CGSizeMake(32, 32));
    }];

    self.navTitleLabel = [UILabel new];
    self.navTitleLabel.font = [UIFont boldSystemFontOfSize:17];
    self.navTitleLabel.textColor = [UIColor whiteColor];
    [navBar addSubview:self.navTitleLabel];
    [self.navTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(navBar);
        make.centerY.equalTo(backBtn);
    }];

    // 白色卡片
    self.cardView = [UIView new];
    self.cardView.backgroundColor = [UIColor whiteColor];
    self.cardView.layer.cornerRadius = 20;
    self.cardView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.cardView.layer.shadowOpacity = 0.15;
    self.cardView.layer.shadowOffset = CGSizeMake(0, 4);
    self.cardView.layer.shadowRadius = 12;
    [self.view addSubview:self.cardView];
    [self.cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(navBar.mas_bottom).offset(24);
        make.leading.equalTo(self.view).offset(24);
        make.trailing.equalTo(self.view).offset(-24);
    }];

    // 头像（带彩色渐变边框环）
    UIView *avatarRing = [UIView new];
    avatarRing.layer.cornerRadius = 36;
    avatarRing.clipsToBounds = YES;
    // 渐变边框用 CAGradientLayer
    CAGradientLayer *grad = [CAGradientLayer layer];
    grad.colors = @[
        (__bridge id)[UIColor colorWithRed:0.36 green:0.20 blue:0.90 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:0.20 green:0.60 blue:0.95 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:0.95 green:0.40 blue:0.20 alpha:1.0].CGColor,
    ];
    grad.startPoint = CGPointMake(0, 0);
    grad.endPoint   = CGPointMake(1, 1);
    grad.frame = CGRectMake(0, 0, 72, 72);
    [avatarRing.layer addSublayer:grad];
    [self.cardView addSubview:avatarRing];
    [avatarRing mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.cardView).offset(24);
        make.centerX.equalTo(self.cardView);
        make.size.mas_equalTo(CGSizeMake(72, 72));
    }];

    self.avatarView = [UIImageView new];
    self.avatarView.layer.cornerRadius = 31;
    self.avatarView.clipsToBounds = YES;
    self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
    if (@available(iOS 13.0, *)) {
        self.avatarView.image = [UIImage systemImageNamed:@"person.crop.circle.fill"];
        self.avatarView.tintColor = [UIColor colorWithRed:0.55 green:0.40 blue:0.85 alpha:1.0];
    }
    [avatarRing addSubview:self.avatarView];
    [self.avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(avatarRing);
        make.size.mas_equalTo(CGSizeMake(62, 62));
    }];

    // 姓名
    self.nameLabel = [UILabel new];
    self.nameLabel.font = [UIFont boldSystemFontOfSize:17];
    self.nameLabel.textColor = [UIColor blackColor];
    self.nameLabel.text = @"Arisha Ireen";
    self.nameLabel.textAlignment = NSTextAlignmentCenter;
    [self.cardView addSubview:self.nameLabel];
    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(avatarRing.mas_bottom).offset(12);
        make.centerX.equalTo(self.cardView);
        make.leading.trailing.equalTo(self.cardView).insets(UIEdgeInsetsMake(0, 12, 0, 12));
    }];

    // ID
    self.idLabel = [UILabel new];
    self.idLabel.font = [UIFont systemFontOfSize:13];
    self.idLabel.textColor = [UIColor grayColor];
    self.idLabel.text = @"ID：145477487";
    self.idLabel.textAlignment = NSTextAlignmentCenter;
    [self.cardView addSubview:self.idLabel];
    [self.idLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.nameLabel.mas_bottom).offset(4);
        make.centerX.equalTo(self.cardView);
    }];

    // 二维码图片
    self.qrImageView = [UIImageView new];
    self.qrImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.qrImageView.image = [self generateQRCodeWithString:@"footballapp://user/145477487" size:180];
    [self.cardView addSubview:self.qrImageView];
    [self.qrImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.idLabel.mas_bottom).offset(20);
        make.centerX.equalTo(self.cardView);
        make.size.mas_equalTo(CGSizeMake(180, 180));
    }];

    // 提示文字
    self.hintLabel = [UILabel new];
    self.hintLabel.font = [UIFont systemFontOfSize:13];
    self.hintLabel.textColor = [UIColor grayColor];
    self.hintLabel.textAlignment = NSTextAlignmentCenter;
    [self.cardView addSubview:self.hintLabel];
    [self.hintLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.qrImageView.mas_bottom).offset(16);
        make.centerX.equalTo(self.cardView);
        make.bottom.equalTo(self.cardView).offset(-24);
    }];

    // 保存图片按钮
    self.saveBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    self.saveBtn.backgroundColor = kQRGreen;
    self.saveBtn.layer.cornerRadius = 22;
    self.saveBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [self.saveBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.saveBtn addTarget:self action:@selector(onSave) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.saveBtn];
    [self.saveBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.cardView.mas_bottom).offset(32);
        make.leading.equalTo(self.view).offset(24);
        make.trailing.equalTo(self.view).offset(-24);
        make.height.mas_equalTo(44);
        make.bottom.lessThanOrEqualTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-24);
    }];
}

- (void)updateLocalizedStrings {
    [super updateLocalizedStrings];
    self.navTitleLabel.text = NSLocalizedString(@"community_my_qrcode", nil);
    self.hintLabel.text = NSLocalizedString(@"community_qrcode_hint", nil);
    [self.saveBtn setTitle:NSLocalizedString(@"community_qrcode_save", nil) forState:UIControlStateNormal];
}

- (void)onBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onSave {
    // 将卡片截图保存到相册
    UIGraphicsBeginImageContextWithOptions(self.cardView.bounds.size, NO, [UIScreen mainScreen].scale);
    [self.cardView drawViewHierarchyInRect:self.cardView.bounds afterScreenUpdates:YES];
    UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    if (snapshot) {
        UIImageWriteToSavedPhotosAlbum(snapshot, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    }
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    NSString *msg = error ? NSLocalizedString(@"community_qrcode_save_fail", nil) : NSLocalizedString(@"community_qrcode_save_success", nil);
    [self showToast:msg];
}

- (void)showToast:(NSString *)message {
    UILabel *toast = [UILabel new];
    toast.text = message;
    toast.font = [UIFont systemFontOfSize:14];
    toast.textColor = [UIColor whiteColor];
    toast.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
    toast.textAlignment = NSTextAlignmentCenter;
    toast.layer.cornerRadius = 16;
    toast.clipsToBounds = YES;
    [self.view addSubview:toast];
    [toast mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-40);
        make.height.mas_equalTo(36);
        make.width.greaterThanOrEqualTo(@120);
        make.leading.greaterThanOrEqualTo(self.view).offset(40);
        make.trailing.lessThanOrEqualTo(self.view).offset(-40);
    }];
    toast.alpha = 0;
    [UIView animateWithDuration:0.3 animations:^{ toast.alpha = 1; } completion:^(BOOL f) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.3 animations:^{ toast.alpha = 0; } completion:^(BOOL done) {
                [toast removeFromSuperview];
            }];
        });
    }];
}

// 生成二维码
- (UIImage *)generateQRCodeWithString:(NSString *)string size:(CGFloat)size {
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [filter setValue:data forKey:@"inputMessage"];
    [filter setValue:@"M" forKey:@"inputCorrectionLevel"];
    CIImage *ciImage = filter.outputImage;
    if (!ciImage) return nil;
    CGRect extent = CGRectIntegral(ciImage.extent);
    CGFloat scale = MIN(size / CGRectGetWidth(extent), size / CGRectGetHeight(extent));
    CIImage *scaled = [ciImage imageByApplyingTransform:CGAffineTransformMakeScale(scale, scale)];
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [context createCGImage:scaled fromRect:scaled.extent];
    UIImage *result = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    return result;
}

@end
