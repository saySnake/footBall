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
/// 设计稿主浅绿文字 #AFFFE0
static UIColor *kQRMintText(void) {
    return [UIColor colorWithRed:0.686 green:1.0 blue:0.878 alpha:1.0];
}
/// 提示文字 #AAC3BD
static UIColor *kQRHintText(void) {
    return [UIColor colorWithRed:0.667 green:0.765 blue:0.741 alpha:1.0];
}
/// 卡片底色（深色半透明）
static UIColor *kQRCardFill(void) {
    return [[UIColor colorWithRed:0.082 green:0.200 blue:0.196 alpha:1.0] colorWithAlphaComponent:0.92];
}

/// 头像边长（Figma 56）
static CGFloat const kQRAvatarSide = 56.f;
static CGFloat const kQRAvatarBorderW = 2.44f;
/// 头像外圆半径（白边外沿）
static CGFloat kQRAvatarOuterRadius(void) {
    return kQRAvatarSide * 0.5f + kQRAvatarBorderW;
}
/// 卡片凹口路径半径：略大于头像外圆，半圆切入更深、更宽，凹口更醒目（仍共心于顶边中点）
static CGFloat const kQRNotchRadiusBoost = 9.f;
static CGFloat kQRNotchPathRadius(void) {
    return kQRAvatarOuterRadius() + kQRNotchRadiusBoost;
}

@interface QRCardShapeView : UIView
@property (nonatomic, strong) CAShapeLayer *shapeLayer;
@end

@implementation QRCardShapeView
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        _shapeLayer = [CAShapeLayer layer];
        _shapeLayer.fillColor = kQRCardFill().CGColor;
        [self.layer addSublayer:_shapeLayer];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect b = self.bounds;
    if (CGRectGetWidth(b) < 1 || CGRectGetHeight(b) < 1) return;

    CGFloat w = CGRectGetWidth(b);
    CGFloat h = CGRectGetHeight(b);
    CGFloat r = 28.0;
    CGFloat R = kQRNotchPathRadius();
    CGFloat cx = w * 0.5;
    CGFloat leftArc = cx - R;

    UIBezierPath *p = [UIBezierPath bezierPath];
    [p moveToPoint:CGPointMake(r, 0)];
    if (leftArc > r + 0.5) {
        [p addLineToPoint:CGPointMake(leftArc, 0)];
    }
    // 头像中心在卡片顶边中点：顶边向下凹的半圆与头像外圆共圆（Figma 574:4288）
    [p addArcWithCenter:CGPointMake(cx, 0) radius:R startAngle:M_PI endAngle:0 clockwise:NO];
    [p addLineToPoint:CGPointMake(w - r, 0)];
    [p addArcWithCenter:CGPointMake(w - r, r) radius:r startAngle:-M_PI_2 endAngle:0 clockwise:YES];
    [p addLineToPoint:CGPointMake(w, h - r)];
    [p addArcWithCenter:CGPointMake(w - r, h - r) radius:r startAngle:0 endAngle:M_PI_2 clockwise:YES];
    [p addLineToPoint:CGPointMake(r, h)];
    [p addArcWithCenter:CGPointMake(r, h - r) radius:r startAngle:M_PI_2 endAngle:M_PI clockwise:YES];
    [p addLineToPoint:CGPointMake(0, r)];
    [p addArcWithCenter:CGPointMake(r, r) radius:r startAngle:M_PI endAngle:-M_PI_2 clockwise:YES];
    [p closePath];

    self.shapeLayer.frame = b;
    self.shapeLayer.path = p.CGPath;
    self.layer.shadowPath = p.CGPath;
}
@end

@interface MyQRCodeViewController ()
@property (nonatomic, strong) UILabel *navTitleLabel;
@property (nonatomic, strong) UIView *navBar;
@property (nonatomic, strong) UIView *bgOverlayView;
@property (nonatomic, strong) CAGradientLayer *bgGradient;
@property (nonatomic, strong) QRCardShapeView *cardView;
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

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.bgOverlayView && self.bgGradient) {
        self.bgGradient.frame = self.bgOverlayView.bounds;
    }
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

    // 背景叠加渐变（近似设计稿的暗绿光感）
    self.bgOverlayView = [UIView new];
    self.bgOverlayView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.bgOverlayView];
    [self.bgOverlayView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    self.bgGradient = [CAGradientLayer layer];
    self.bgGradient.colors = @[
        (id)[UIColor colorWithRed:0.04 green:0.24 blue:0.20 alpha:1.0].CGColor,
        (id)kQRPageBg().CGColor
    ];
    self.bgGradient.startPoint = CGPointMake(0.8, 0.0);
    self.bgGradient.endPoint = CGPointMake(0.2, 1.0);
    self.bgGradient.opacity = 0.55;
    [self.bgOverlayView.layer addSublayer:self.bgGradient];

    self.navBar = [UIView new];
    self.navBar.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.navBar];

    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImage *backIcon = [[UIImage imageNamed:@"nav_back"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    if (!backIcon) {
        backIcon = [UIImage imageNamed:@"ad_left"];
    }
    if (!backIcon && @available(iOS 13.0, *)) {
        backIcon = [[UIImage systemImageNamed:@"arrow.left"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    [backBtn setImage:backIcon forState:UIControlStateNormal];
    backBtn.tintColor = [UIColor whiteColor];
    [backBtn addTarget:self action:@selector(onBack) forControlEvents:UIControlEventTouchUpInside];
    [self.navBar addSubview:backBtn];

    self.navTitleLabel = [UILabel new];
    self.navTitleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    self.navTitleLabel.textColor = [UIColor whiteColor];
    self.navTitleLabel.text = NSLocalizedString(@"community_my_qrcode", nil);
    [self.navBar addSubview:self.navTitleLabel];

    [backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.navBar).offset(16);
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(22);
        make.size.mas_equalTo(CGSizeMake(24, 24));
    }];
    [self.navTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.navBar);
        make.centerY.equalTo(backBtn);
    }];
    [self.navBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(backBtn.mas_bottom).offset(16);
    }];

    self.cardView = [QRCardShapeView new];
    self.cardView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.cardView.layer.shadowOpacity = 0.34;
    self.cardView.layer.shadowOffset = CGSizeMake(0, 12);
    self.cardView.layer.shadowRadius = 32;
    [self.view addSubview:self.cardView];

    self.avatarView = [UIImageView new];
    self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarView.layer.cornerRadius = kQRAvatarSide * 0.5f;
    self.avatarView.clipsToBounds = YES;
    self.avatarView.layer.borderWidth = kQRAvatarBorderW;
    self.avatarView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.avatarView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.06];
    if (@available(iOS 13.0, *)) {
        self.avatarView.image = [UIImage systemImageNamed:@"person.crop.circle.fill"];
        self.avatarView.tintColor = [UIColor colorWithWhite:0.75 alpha:1.0];
    }
    [self.view addSubview:self.avatarView];
    [self.view bringSubviewToFront:self.avatarView];

    [self.avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.navBar.mas_bottom).offset(40);
        make.size.mas_equalTo(CGSizeMake(kQRAvatarSide, kQRAvatarSide));
    }];
    [self.cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        // 卡片顶边穿过头像中心：头像一半在卡片上方，凹口圆弧与头像下缘贴合（574:4288）
        make.top.equalTo(self.avatarView.mas_centerY);
        make.centerX.equalTo(self.view);
        make.width.mas_equalTo(327);
        make.height.mas_equalTo(438);
    }];

    self.nameLabel = [UILabel new];
    self.nameLabel.font = [UIFont systemFontOfSize:32 weight:UIFontWeightSemibold];
    self.nameLabel.textColor = kQRMintText();
    self.nameLabel.textAlignment = NSTextAlignmentCenter;
    [self.cardView addSubview:self.nameLabel];
    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        // 凹口最深处约 R，文案从圆弧下缘留白（对齐 Figma 用户信息区）
        make.top.equalTo(self.cardView).offset(ceil(kQRNotchPathRadius()) + 20);
        make.leading.equalTo(self.cardView).offset(16);
        make.trailing.equalTo(self.cardView).offset(-16);
    }];

    self.idLabel = [UILabel new];
    self.idLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightRegular];
    self.idLabel.textColor = kQRMintText();
    self.idLabel.textAlignment = NSTextAlignmentCenter;
    [self.cardView addSubview:self.idLabel];
    [self.idLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.nameLabel.mas_bottom).offset(6);
        make.centerX.equalTo(self.cardView);
    }];

    self.qrImageView = [UIImageView new];
    self.qrImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.qrImageView.backgroundColor = [UIColor clearColor];
    [self.cardView addSubview:self.qrImageView];
    [self.qrImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.idLabel.mas_bottom).offset(24);
        make.centerX.equalTo(self.cardView);
        make.size.mas_equalTo(CGSizeMake(228, 228));
    }];

    self.hintLabel = [UILabel new];
    self.hintLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    self.hintLabel.textColor = kQRHintText();
    self.hintLabel.textAlignment = NSTextAlignmentCenter;
    self.hintLabel.numberOfLines = 2;
    [self.cardView addSubview:self.hintLabel];
    [self.hintLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.qrImageView.mas_bottom).offset(16);
        make.leading.equalTo(self.cardView).offset(16);
        make.trailing.equalTo(self.cardView).offset(-16);
        make.bottom.equalTo(self.cardView).offset(-24);
    }];

    self.saveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.saveBtn.backgroundColor = kQRBrandGreen();
    self.saveBtn.layer.cornerRadius = 26;
    self.saveBtn.layer.shadowColor = [UIColor blackColor].CGColor;
    self.saveBtn.layer.shadowOpacity = 0.19f;
    self.saveBtn.layer.shadowOffset = CGSizeMake(0, 2);
    self.saveBtn.layer.shadowRadius = 4;
    self.saveBtn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [self.saveBtn setTitleColor:kQRMintText() forState:UIControlStateNormal];
    [self.saveBtn addTarget:self action:@selector(onPrimaryAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.saveBtn];
    [self.saveBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.cardView.mas_bottom).offset(22);
        make.leading.equalTo(self.view).offset(24);
        make.trailing.equalTo(self.view).offset(-24);
        make.height.mas_equalTo(52);
        make.bottom.lessThanOrEqualTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-24);
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
    [self.saveBtn setTitle:NSLocalizedString(@"community_qrcode_add_friend", nil) forState:UIControlStateNormal];
}

- (void)onBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onPrimaryAction {
    // 设计稿为「立即添加好友」：此处分享二维码卡片截图，便于对方扫码添加
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

    UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:@[snapshot] applicationActivities:nil];
    if (avc.popoverPresentationController) {
        avc.popoverPresentationController.sourceView = self.saveBtn;
        avc.popoverPresentationController.sourceRect = self.saveBtn.bounds;
    }
    [self presentViewController:avc animated:YES completion:nil];
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
    
    // 将二维码着色为设计稿的浅绿
    CIFilter *color = [CIFilter filterWithName:@"CIFalseColor"];
    [color setValue:scaled forKey:kCIInputImageKey];
    [color setValue:[CIColor colorWithRed:0.686 green:1.0 blue:0.878 alpha:1.0] forKey:@"inputColor0"];
    [color setValue:[CIColor colorWithRed:0 green:0 blue:0 alpha:0] forKey:@"inputColor1"];
    CIImage *colored = color.outputImage ?: scaled;

    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [context createCGImage:colored fromRect:colored.extent];
    UIImage *result = cgImage ? [UIImage imageWithCGImage:cgImage scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp] : nil;
    if (cgImage) CGImageRelease(cgImage);
    return result;
}

@end
