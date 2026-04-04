//
//  MyQRCodeViewController.m
//  footBall
//

#import "MyQRCodeViewController.h"
#import <Masonry/Masonry.h>
#import <CoreImage/CoreImage.h>
#import <SDWebImage/SDWebImage.h>
#import "AuthManager.h"
#import "UserRequest.h"

/// 与社区页一致的深色背景 #0D2122
static UIColor *kQRPageBg(void) {
    return [UIColor colorWithRed:0.051 green:0.129 blue:0.133 alpha:1.0];
}
/// 品牌绿 #285D4B
static UIColor *kQRBrandGreen(void) {
    return [UIColor colorWithRed:0.157 green:0.365 blue:0.294 alpha:1.0];
}
static UIColor *kQRSecondaryText(void) {
    return [UIColor colorWithRed:0.612 green:0.643 blue:0.671 alpha:1.0];
}

@interface MyQRCodeViewController ()
@property (nonatomic, strong) UILabel *navTitleLabel;
@property (nonatomic, strong) UIView *navBar;
@property (nonatomic, strong) UIView *cardView;
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
    self.view.backgroundColor = kQRPageBg();
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    __weak typeof(self) weakSelf = self;
    [UserRequest.shared getUserQRCodeSuccess:^(HTTPResponse * _Nullable responseObject) {
        [weakSelf applyProfileToQRImage];
    } failure:^(NSError * _Nonnull error) {
        [weakSelf applyProfileToQRImage];
    }];
}

- (void)setupUI {
    self.view.backgroundColor = kQRPageBg();

    self.navBar = [UIView new];
    self.navBar.backgroundColor = kQRPageBg();
    [self.view addSubview:self.navBar];

    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImage *backIcon = [UIImage imageNamed:@"ad_left"];
    if (!backIcon && @available(iOS 13.0, *)) {
        backIcon = [UIImage systemImageNamed:@"arrow.left"];
    }
    [backBtn setImage:backIcon forState:UIControlStateNormal];
    backBtn.tintColor = [UIColor whiteColor];
    [backBtn addTarget:self action:@selector(onBack) forControlEvents:UIControlEventTouchUpInside];
    [self.navBar addSubview:backBtn];

    self.navTitleLabel = [UILabel new];
    self.navTitleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    self.navTitleLabel.textColor = [UIColor whiteColor];
    self.navTitleLabel.text = NSLocalizedString(@"community_my_qrcode", nil);
    [self.navBar addSubview:self.navTitleLabel];

    [backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.navBar).offset(12);
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(8);
        make.size.mas_equalTo(CGSizeMake(32, 32));
    }];
    [self.navTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.navBar);
        make.centerY.equalTo(backBtn);
    }];
    [self.navBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(backBtn.mas_bottom).offset(12);
    }];

    self.cardView = [UIView new];
    self.cardView.backgroundColor = [UIColor whiteColor];
    self.cardView.layer.cornerRadius = 16;
    self.cardView.layer.masksToBounds = NO;
    self.cardView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.cardView.layer.shadowOpacity = 0.08;
    self.cardView.layer.shadowOffset = CGSizeMake(0, 4);
    self.cardView.layer.shadowRadius = 16;
    [self.view addSubview:self.cardView];

    self.avatarView = [UIImageView new];
    self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarView.layer.cornerRadius = 50;
    self.avatarView.clipsToBounds = YES;
    self.avatarView.layer.borderWidth = 3;
    self.avatarView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.avatarView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    if (@available(iOS 13.0, *)) {
        self.avatarView.image = [UIImage systemImageNamed:@"person.crop.circle.fill"];
        self.avatarView.tintColor = [UIColor colorWithWhite:0.75 alpha:1.0];
    }
    [self.view addSubview:self.avatarView];
    [self.view bringSubviewToFront:self.avatarView];

    [self.avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.navTitleLabel.mas_bottom).offset(65);
        make.size.mas_equalTo(CGSizeMake(100, 100));
    }];
    [self.cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.avatarView.mas_centerY);
        make.leading.equalTo(self.view).offset(20);
        make.trailing.equalTo(self.view).offset(-20);
    }];

    self.nameLabel = [UILabel new];
    self.nameLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    self.nameLabel.textColor = [UIColor blackColor];
    self.nameLabel.textAlignment = NSTextAlignmentCenter;
    [self.cardView addSubview:self.nameLabel];
    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.avatarView.mas_bottom).offset(12);
        make.leading.equalTo(self.cardView).offset(16);
        make.trailing.equalTo(self.cardView).offset(-16);
    }];

    self.idLabel = [UILabel new];
    self.idLabel.font = [UIFont systemFontOfSize:13];
    self.idLabel.textColor = [UIColor blackColor];
    self.idLabel.textAlignment = NSTextAlignmentCenter;
    [self.cardView addSubview:self.idLabel];
    [self.idLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.nameLabel.mas_bottom).offset(6);
        make.centerX.equalTo(self.cardView);
    }];

    self.qrImageView = [UIImageView new];
    self.qrImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.qrImageView.backgroundColor = [UIColor whiteColor];
    [self.cardView addSubview:self.qrImageView];
    [self.qrImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.idLabel.mas_bottom).offset(24);
        make.centerX.equalTo(self.cardView);
        make.size.mas_equalTo(CGSizeMake(228, 228));
    }];

    self.hintLabel = [UILabel new];
    self.hintLabel.font = [FontManager fontOfSize:14];
    self.hintLabel.textColor = [UIColor blackColor];
    self.hintLabel.textAlignment = NSTextAlignmentCenter;
    self.hintLabel.numberOfLines = 2;
    [self.cardView addSubview:self.hintLabel];
    [self.hintLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.qrImageView.mas_bottom).offset(20);
        make.leading.equalTo(self.cardView).offset(16);
        make.trailing.equalTo(self.cardView).offset(-16);
        make.bottom.equalTo(self.cardView).offset(-24);
    }];

    self.saveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.saveBtn.backgroundColor = kQRBrandGreen();
    self.saveBtn.layer.cornerRadius = 22;
    self.saveBtn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [self.saveBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.saveBtn addTarget:self action:@selector(onSave) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.saveBtn];
    [self.saveBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.cardView.mas_bottom).offset(67);
        make.leading.equalTo(self.view).offset(24);
        make.trailing.equalTo(self.view).offset(-24);
        make.height.mas_equalTo(44);
        make.bottom.lessThanOrEqualTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-20);
    }];

    [self applyProfileToUI];
}

- (void)applyProfileToUI {
    UserProfile *p = AuthManager.sharedManager.user.profile;
    self.nameLabel.text = p.nickname.length > 0 ? p.nickname : @"-";
    self.idLabel.text = [NSString stringWithFormat:NSLocalizedString(@"profile_id_format", nil), p.userId.length > 0 ? p.userId : @"-"];
    NSURL *avURL = p.avatar.length > 0 ? [NSURL URLWithString:p.avatar] : nil;
    UIImage *placeholder = (@available(iOS 13.0, *)) ? [UIImage systemImageNamed:@"person.crop.circle.fill"] : nil;
    __weak typeof(self) weakSelf = self;
    [self.avatarView sd_setImageWithURL:avURL placeholderImage:placeholder completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (!image && @available(iOS 13.0, *)) {
            weakSelf.avatarView.tintColor = [UIColor colorWithWhite:0.75 alpha:1.0];
            weakSelf.avatarView.contentMode = UIViewContentModeCenter;
        } else {
            weakSelf.avatarView.tintColor = nil;
            weakSelf.avatarView.contentMode = UIViewContentModeScaleAspectFill;
        }
    }];
    [self applyProfileToQRImage];
}

- (void)applyProfileToQRImage {
    UserProfile *p = AuthManager.sharedManager.user.profile;
    NSString *payload = p.qrCode.length > 0 ? p.qrCode : [NSString stringWithFormat:@"footballapp://user/%@", p.userId ?: @""];
    if (payload.length == 0) {
        payload = @"footballapp://user";
    }
    self.qrImageView.image = [self generateQRCodeWithString:payload size:200];
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
    [self.view layoutIfNeeded];
    CGRect cardBounds = self.cardView.bounds;
    if (cardBounds.size.width < 1.0 || cardBounds.size.height < 1.0) {
        [self showToast:NSLocalizedString(@"community_qrcode_save_fail", nil)];
        return;
    }

    UIGraphicsBeginImageContextWithOptions(cardBounds.size, NO, [UIScreen mainScreen].scale);
    [self.cardView drawViewHierarchyInRect:cardBounds afterScreenUpdates:YES];
    UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    if (!snapshot) {
        [self showToast:NSLocalizedString(@"community_qrcode_save_fail", nil)];
        return;
    }

    UIImageWriteToSavedPhotosAlbum(snapshot, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
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
    toast.backgroundColor = [UIColor colorWithWhite:0 alpha:0.72];
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
