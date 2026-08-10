//
//  RealNameAuthViewController.m
//  footBall
//

#import "RealNameAuthViewController.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>

// Figma 1:4137「实名认证」
#define kRANavBg        [UIColor colorWithRed:13/255.0 green:33/255.0 blue:34/255.0 alpha:1.0]   // #0d2122
#define kRAPageBg       [UIColor colorWithRed:247/255.0 green:247/255.0 blue:247/255.0 alpha:1.0] // #f7f7f7
#define kRACardBg       [UIColor whiteColor]
#define kRAButtonGreen  [UIColor colorWithRed:40/255.0 green:93/255.0 blue:75/255.0 alpha:1.0]   // #285d4b
#define kRAUploadBg     [UIColor colorWithRed:244/255.0 green:244/255.0 blue:244/255.0 alpha:1.0] // #f4f4f4
#define kRASubhintColor [UIColor colorWithRed:191/255.0 green:191/255.0 blue:191/255.0 alpha:1.0] // #bfbfbf
#define kRATitleDark    [UIColor colorWithRed:53/255.0 green:53/255.0 blue:53/255.0 alpha:1.0]   // #353535
#define kRACaptionGray  [UIColor colorWithRed:90/255.0 green:90/255.0 blue:90/255.0 alpha:1.0]   // #5a5a5a
static CGFloat const kRAHeaderHeight = 240.f;
/// Figma 1:4168：白卡 top=176（与顶栏重叠 64pt，非 header 底部对齐）
static CGFloat const kRAIdCardTop = 176.f;
static CGFloat const kRAUploadH = 177.f;
/// 卡片内左右边距：屏幕 x=29 标题 → 29-15=14
static CGFloat const kRAIdCardInnerH = 14.f;
/// 标题顶距：卡片顶到「身份信息」约 16pt（229-176-53 与稿对齐）
static CGFloat const kRAIdTitleTop = 16.f;
/// 标题底到首块上传区：约 16pt（稿 53pt 标题区+间距）
static CGFloat const kRATitleToUploadGap = 16.f;
/// 灰块底到说明文案 / 说明到下一灰块：合计约 50pt（456-406）
static CGFloat const kRABoxToCaptionGap = 12.f;
static CGFloat const kRACaptionToNextUploadGap = 18.f;
static CGFloat const kRACardRadius = 6.f;
/// 占位图 camera_d 尺寸（无绿色圆底）
static CGFloat const kRACameraPlaceholderSize = 54.f;
static CGFloat const kRASubmitH = 52.f;
/// Figma 1:4182 实名认证已通过
static CGFloat const kRACompletedHeaderLeading = 14.f;  // 稿 x=14
static CGFloat const kRACompletedBelowTitle = 22.f;     // 稿 y=108，标题 y=60、h=26 → 间距约 22
static CGFloat const kRAVerifiedTitleToImage = 17.f;   // 稿 234−217
static CGFloat const kRAVerifiedImageToCaption = 10.f; // 稿 421−411
static CGFloat const kRAVerifiedCaptionToNextImage = 15.f; // 稿 461−446
static CGFloat const kRAVerifiedBackImageToCaption = 8.f;   // 稿 643−638 约 5，取 8 更易读

@interface RealNameAuthViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *content;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UILabel *hintLabel;
@property (nonatomic, strong) UILabel *subHintLabel;
@property (nonatomic, strong) UIView *idCardCard;
@property (nonatomic, strong) UILabel *idInfoTitleLabel;
@property (nonatomic, strong) UIControl *frontUploadArea;
@property (nonatomic, strong) UIImageView *frontIconView;
@property (nonatomic, strong) UILabel *frontLabel;
@property (nonatomic, strong) UIImageView *frontPreview;
@property (nonatomic, strong) UIControl *backUploadArea;
@property (nonatomic, strong) UIImageView *backIconView;
@property (nonatomic, strong) UILabel *backLabel;
@property (nonatomic, strong) UIImageView *backPreview;
@property (nonatomic, strong) UIButton *submitBtn;

@property (nonatomic, strong) UILabel *completedHeaderLabel;
@property (nonatomic, strong) UIView *readOnlyCard;
@property (nonatomic, strong) UILabel *readOnlyTitleLabel;
@property (nonatomic, strong) UILabel *readOnlyInfoLabel;
@property (nonatomic, strong) UILabel *frontDisplayLabel;
@property (nonatomic, strong) UIImageView *frontDisplayImage;
@property (nonatomic, strong) UILabel *backDisplayLabel;
@property (nonatomic, strong) UIImageView *backDisplayImage;

@property (nonatomic, assign) BOOL completed;
@property (nonatomic, strong) UIImage *frontImage;
@property (nonatomic, strong) UIImage *backImage;
@property (nonatomic, assign) NSInteger currentUploadSlot; // 0 front, 1 back
@end

@implementation RealNameAuthViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hidesBottomBarWhenPushed = YES;
    self.shouldShowNavigationBar = NO;
    self.view.backgroundColor = kRAPageBg;
    self.frontImage = nil;
    self.backImage = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    __weak typeof(self) weakSelf = self;
    [[VerificationRequest shared] fetchStatusSuccess:^(HTTPResponse * _Nullable responseObject) {
        [[VerificationRequest shared] fetchRealnameInfoSuccess:^(HTTPResponse * _Nullable responseObject) {
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            [self refreshState];
        } failure:^(NSError * _Nonnull error) {
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            [self refreshState];
        }];
    } failure:^(NSError * _Nonnull error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [self refreshState];
    }];
}

- (void)setupUI {
    if (@available(iOS 11.0, *)) {
        self.scrollView = [UIScrollView new];
        self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
        self.scrollView = [UIScrollView new];
    }
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.backgroundColor = kRAPageBg;
    [self.view addSubview:self.scrollView];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    self.content = [UIView new];
    [self.scrollView addSubview:self.content];

    self.headerView = [UIView new];
    self.headerView.backgroundColor = kRANavBg;
    [self.content addSubview:self.headerView];
    [self.headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.content);
        make.height.mas_equalTo(kRAHeaderHeight);
    }];

    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImage *adLeft = [UIImage imageNamed:@"ad_left"];
    UIImage *backImg = adLeft ?: [UIImage imageNamed:@"nav_back"];
    if (!backImg && @available(iOS 13.0, *)) {
        backImg = [UIImage systemImageNamed:@"arrow.left"];
    }
    if (backImg) {
        [backBtn setImage:[backImg imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        backBtn.tintColor = [UIColor whiteColor];
    }
    backBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [backBtn addTarget:self action:@selector(onBack) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView addSubview:backBtn];
    [backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.headerView).offset(16);
        if (@available(iOS 11.0, *)) {
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(17);
        } else {
            make.top.equalTo(self.headerView).offset(37);
        }
        make.size.mas_equalTo(CGSizeMake(24, 24));
    }];

    UILabel *navTitle = [UILabel new];
    navTitle.text = NSLocalizedString(@"auth_realname_nav_title", nil);
    navTitle.font = [UIFont boldSystemFontOfSize:18];
    navTitle.textColor = [UIColor whiteColor];
    [self.headerView addSubview:navTitle];
    [navTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.headerView);
        make.centerY.equalTo(backBtn);
    }];

    // 绿色区域说明：请完善证件信息、已上传信息将为您保存15天（仅未认证时显示）
    self.hintLabel = [UILabel new];
    self.hintLabel.text = NSLocalizedString(@"auth_realname_hint", nil);
    self.hintLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    self.hintLabel.textColor = [UIColor whiteColor];
    [self.headerView addSubview:self.hintLabel];
    [self.hintLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(backBtn.mas_bottom).offset(24);
        make.leading.equalTo(self.headerView).offset(15);
        make.trailing.equalTo(self.headerView).offset(-15);
    }];

    self.subHintLabel = [UILabel new];
    self.subHintLabel.text = NSLocalizedString(@"auth_realname_subhint", nil);
    self.subHintLabel.font = [UIFont systemFontOfSize:13];
    self.subHintLabel.textColor = kRASubhintColor;
    self.subHintLabel.numberOfLines = 0;
    [self.headerView addSubview:self.subHintLabel];
    [self.subHintLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.hintLabel.mas_bottom).offset(8);
        make.leading.equalTo(self.headerView).offset(14);
        make.trailing.equalTo(self.headerView).offset(-14);
    }];

    // 已完成实名认证：Figma 1:4209/1:4210（仅已认证时显示）
    self.completedHeaderLabel = [UILabel new];
    self.completedHeaderLabel.text = NSLocalizedString(@"auth_realname_completed", nil);
    self.completedHeaderLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    self.completedHeaderLabel.textColor = [UIColor whiteColor];
    self.completedHeaderLabel.numberOfLines = 0;
    self.completedHeaderLabel.hidden = YES;
    [self.headerView addSubview:self.completedHeaderLabel];
    [self.completedHeaderLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.headerView).offset(kRACompletedHeaderLeading);
        make.trailing.lessThanOrEqualTo(self.headerView).offset(-14);
        make.top.equalTo(navTitle.mas_bottom).offset(kRACompletedBelowTitle);
    }];

    [self buildUnverifiedUI];
    [self buildVerifiedUI];
    [self refreshState];
}

- (void)buildUnverifiedUI {
    // 身份信息白卡：仅含「身份信息」标题 + 两个上传区，置于绿底与白底交界，顶部与绿底略微重叠
    self.idCardCard = [UIView new];
    self.idCardCard.backgroundColor = kRACardBg;
    self.idCardCard.layer.cornerRadius = kRACardRadius;
    self.idCardCard.layer.shadowColor = [UIColor blackColor].CGColor;
    self.idCardCard.layer.shadowOpacity = 0.08;
    self.idCardCard.layer.shadowOffset = CGSizeMake(0, 2);
    self.idCardCard.layer.shadowRadius = 10;
    [self.content addSubview:self.idCardCard];
    [self.idCardCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.content).offset(kRAIdCardTop);
        make.leading.equalTo(self.content).offset(15);
        make.trailing.equalTo(self.content).offset(-15);
    }];

    self.idInfoTitleLabel = [UILabel new];
    self.idInfoTitleLabel.text = NSLocalizedString(@"auth_id_info_title", nil);
    self.idInfoTitleLabel.font = [UIFont boldSystemFontOfSize:16];
    self.idInfoTitleLabel.textColor = kRATitleDark;
    [self.idCardCard addSubview:self.idInfoTitleLabel];
    [self.idInfoTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.idCardCard).offset(kRAIdTitleTop);
        make.leading.equalTo(self.idCardCard).offset(kRAIdCardInnerH);
        make.trailing.lessThanOrEqualTo(self.idCardCard).offset(-kRAIdCardInnerH);
    }];

    CGFloat smallCardH = kRAUploadH;
    self.frontUploadArea = [UIControl new];
    self.frontUploadArea.backgroundColor = kRAUploadBg;
    self.frontUploadArea.layer.cornerRadius = kRACardRadius;
    [self.frontUploadArea addTarget:self action:@selector(onTapFrontUpload) forControlEvents:UIControlEventTouchUpInside];
    [self.idCardCard addSubview:self.frontUploadArea];
    [self.frontUploadArea mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.idInfoTitleLabel.mas_bottom).offset(kRATitleToUploadGap);
        make.leading.trailing.equalTo(self.idCardCard).inset(17);
        make.height.mas_equalTo(smallCardH);
    }];

    self.frontIconView = [UIImageView new];
    self.frontIconView.contentMode = UIViewContentModeScaleAspectFit;
    UIImage *frontCam = [UIImage imageNamed:@"camera_d"];
    if (!frontCam) frontCam = [UIImage imageNamed:@"camera_upload"];
    if (!frontCam && @available(iOS 13.0, *)) {
        frontCam = [[UIImage systemImageNamed:@"camera.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.frontIconView.tintColor = kRATitleDark;
    }
    self.frontIconView.image = frontCam;
    [self.frontUploadArea addSubview:self.frontIconView];
    [self.frontIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.frontUploadArea);
        make.centerY.equalTo(self.frontUploadArea);
        make.size.mas_equalTo(CGSizeMake(kRACameraPlaceholderSize, kRACameraPlaceholderSize));
    }];
    self.frontPreview = [UIImageView new];
    self.frontPreview.contentMode = UIViewContentModeScaleAspectFill;
    self.frontPreview.clipsToBounds = YES;
    self.frontPreview.layer.cornerRadius = kRACardRadius;
    self.frontPreview.hidden = YES;
    [self.frontUploadArea addSubview:self.frontPreview];
    [self.frontPreview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.frontUploadArea).inset(8);
    }];

    self.frontLabel = [UILabel new];
    self.frontLabel.text = NSLocalizedString(@"auth_id_front_label", nil);
    self.frontLabel.font = [UIFont systemFontOfSize:14];
    self.frontLabel.textColor = kRACaptionGray;
    self.frontLabel.textAlignment = NSTextAlignmentCenter;
    self.frontLabel.numberOfLines = 0;
    [self.idCardCard addSubview:self.frontLabel];
    [self.frontLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.frontUploadArea.mas_bottom).offset(kRABoxToCaptionGap);
        make.leading.equalTo(self.idCardCard).offset(17);
        make.trailing.equalTo(self.idCardCard).offset(-17);
    }];

    self.backUploadArea = [UIControl new];
    self.backUploadArea.backgroundColor = kRAUploadBg;
    self.backUploadArea.layer.cornerRadius = kRACardRadius;
    [self.backUploadArea addTarget:self action:@selector(onTapBackUpload) forControlEvents:UIControlEventTouchUpInside];
    [self.idCardCard addSubview:self.backUploadArea];
    [self.backUploadArea mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.frontLabel.mas_bottom).offset(kRACaptionToNextUploadGap);
        make.leading.trailing.equalTo(self.idCardCard).inset(17);
        make.height.mas_equalTo(smallCardH);
    }];

    self.backIconView = [UIImageView new];
    self.backIconView.contentMode = UIViewContentModeScaleAspectFit;
    UIImage *backCam = [UIImage imageNamed:@"camera_d"];
    if (!backCam) backCam = [UIImage imageNamed:@"camera_upload"];
    if (!backCam && @available(iOS 13.0, *)) {
        backCam = [[UIImage systemImageNamed:@"camera.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.backIconView.tintColor = kRATitleDark;
    }
    self.backIconView.image = backCam;
    [self.backUploadArea addSubview:self.backIconView];
    [self.backIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.backUploadArea);
        make.centerY.equalTo(self.backUploadArea);
        make.size.mas_equalTo(CGSizeMake(kRACameraPlaceholderSize, kRACameraPlaceholderSize));
    }];
    self.backPreview = [UIImageView new];
    self.backPreview.contentMode = UIViewContentModeScaleAspectFill;
    self.backPreview.clipsToBounds = YES;
    self.backPreview.layer.cornerRadius = kRACardRadius;
    self.backPreview.hidden = YES;
    [self.backUploadArea addSubview:self.backPreview];
    [self.backPreview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.backUploadArea).inset(8);
    }];

    self.backLabel = [UILabel new];
    self.backLabel.text = NSLocalizedString(@"auth_id_back_label", nil);
    self.backLabel.font = [UIFont systemFontOfSize:14];
    self.backLabel.textColor = kRACaptionGray;
    self.backLabel.textAlignment = NSTextAlignmentCenter;
    self.backLabel.numberOfLines = 0;
    [self.idCardCard addSubview:self.backLabel];
    [self.backLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.backUploadArea.mas_bottom).offset(kRABoxToCaptionGap);
        make.leading.equalTo(self.idCardCard).offset(17);
        make.trailing.equalTo(self.idCardCard).offset(-17);
        make.bottom.equalTo(self.idCardCard).offset(-16);
    }];

    self.submitBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    self.submitBtn.backgroundColor = kRAButtonGreen;
    self.submitBtn.layer.cornerRadius = kRASubmitH * 0.5f;
    self.submitBtn.layer.shadowColor = [UIColor blackColor].CGColor;
    self.submitBtn.layer.shadowOpacity = 0.19f;
    self.submitBtn.layer.shadowOffset = CGSizeMake(0, 2);
    self.submitBtn.layer.shadowRadius = 2;
    [self.submitBtn setTitle:NSLocalizedString(@"auth_submit_now", nil) forState:UIControlStateNormal];
    [self.submitBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.submitBtn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [self.submitBtn addTarget:self action:@selector(onSubmit) forControlEvents:UIControlEventTouchUpInside];
    [self.content addSubview:self.submitBtn];
    [self.submitBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.idCardCard.mas_bottom).offset(24);
        make.leading.equalTo(self.content).offset(15);
        make.trailing.equalTo(self.content).offset(-15);
        make.height.mas_equalTo(kRASubmitH);
    }];
}

- (void)buildVerifiedUI {
    // 已认证：Figma 1:4182，白卡 y=176、w=343、h=509，与未认证同一套水平边距
    self.readOnlyCard = [UIView new];
    self.readOnlyCard.backgroundColor = kRACardBg;
    self.readOnlyCard.layer.cornerRadius = kRACardRadius;
    self.readOnlyCard.layer.shadowColor = [UIColor blackColor].CGColor;
    self.readOnlyCard.layer.shadowOpacity = 0.08;
    self.readOnlyCard.layer.shadowOffset = CGSizeMake(0, 2);
    self.readOnlyCard.layer.shadowRadius = 10;
    [self.content addSubview:self.readOnlyCard];
    [self.readOnlyCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.content).offset(kRAIdCardTop);
        make.leading.equalTo(self.content).offset(15);
        make.trailing.equalTo(self.content).offset(-15);
    }];

    self.readOnlyTitleLabel = [UILabel new];
    self.readOnlyTitleLabel.text = NSLocalizedString(@"auth_id_info_title", nil);
    /// 稿 1:4213 Small Label 12px
    self.readOnlyTitleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    self.readOnlyTitleLabel.textColor = kRATitleDark;
    [self.readOnlyCard addSubview:self.readOnlyTitleLabel];
    [self.readOnlyTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.readOnlyCard).offset(kRAIdTitleTop);
        make.leading.equalTo(self.readOnlyCard).offset(kRAIdCardInnerH);
        make.trailing.lessThanOrEqualTo(self.readOnlyCard).offset(-kRAIdCardInnerH);
    }];

    // 身份信息下面：图 → 12px 说明 → 图 → 说明（间距与 1:4214–1:4217 一致）
    self.frontDisplayImage = [UIImageView new];
    self.frontDisplayImage.contentMode = UIViewContentModeScaleAspectFit;
    self.frontDisplayImage.backgroundColor = kRAUploadBg;
    self.frontDisplayImage.layer.cornerRadius = kRACardRadius;
    self.frontDisplayImage.clipsToBounds = YES;
    [self.readOnlyCard addSubview:self.frontDisplayImage];
    [self.frontDisplayImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.readOnlyTitleLabel.mas_bottom).offset(kRAVerifiedTitleToImage);
        make.leading.trailing.equalTo(self.readOnlyCard).inset(17);
        make.height.mas_equalTo(kRAUploadH);
    }];

    self.frontDisplayLabel = [UILabel new];
    self.frontDisplayLabel.text = NSLocalizedString(@"auth_id_front_display", nil);
    self.frontDisplayLabel.font = [UIFont systemFontOfSize:12];
    self.frontDisplayLabel.textColor = kRACaptionGray;
    self.frontDisplayLabel.textAlignment = NSTextAlignmentCenter;
    self.frontDisplayLabel.numberOfLines = 0;
    [self.readOnlyCard addSubview:self.frontDisplayLabel];
    [self.frontDisplayLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.frontDisplayImage.mas_bottom).offset(kRAVerifiedImageToCaption);
        make.leading.equalTo(self.readOnlyCard).offset(17);
        make.trailing.equalTo(self.readOnlyCard).offset(-17);
    }];

    self.backDisplayImage = [UIImageView new];
    self.backDisplayImage.contentMode = UIViewContentModeScaleAspectFit;
    self.backDisplayImage.backgroundColor = kRAUploadBg;
    self.backDisplayImage.layer.cornerRadius = kRACardRadius;
    self.backDisplayImage.clipsToBounds = YES;
    [self.readOnlyCard addSubview:self.backDisplayImage];
    [self.backDisplayImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.frontDisplayLabel.mas_bottom).offset(kRAVerifiedCaptionToNextImage);
        make.leading.trailing.equalTo(self.readOnlyCard).inset(17);
        make.height.mas_equalTo(kRAUploadH);
    }];

    self.backDisplayLabel = [UILabel new];
    self.backDisplayLabel.text = NSLocalizedString(@"auth_id_back_display", nil);
    self.backDisplayLabel.font = [UIFont systemFontOfSize:12];
    self.backDisplayLabel.textColor = kRACaptionGray;
    self.backDisplayLabel.textAlignment = NSTextAlignmentCenter;
    self.backDisplayLabel.numberOfLines = 0;
    [self.readOnlyCard addSubview:self.backDisplayLabel];
    [self.backDisplayLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.backDisplayImage.mas_bottom).offset(kRAVerifiedBackImageToCaption);
        make.leading.equalTo(self.readOnlyCard).offset(17);
        make.trailing.equalTo(self.readOnlyCard).offset(-17);
        make.bottom.equalTo(self.readOnlyCard).offset(-16);
    }];
}

- (void)refreshState {
    NSString *status = [VerificationRequest shared].cachedVerificationStatus.realnameStatus ?: @"";
    NSString *u = [status uppercaseString];
    BOOL approvedByAPI = [u isEqualToString:@"APPROVED"] || [u isEqualToString:@"VERIFIED"] || [u isEqualToString:@"PASSED"];
    self.completed = approvedByAPI;

    BOOL showUnverified = !self.completed;
    self.headerView.hidden = NO;
    self.hintLabel.hidden = !showUnverified;
    self.subHintLabel.hidden = !showUnverified;
    self.completedHeaderLabel.hidden = showUnverified;
    self.idCardCard.hidden = !showUnverified;
    self.submitBtn.hidden = !showUnverified;

    self.readOnlyCard.hidden = showUnverified;

    if (showUnverified) {
        self.frontPreview.image = self.frontImage;
        BOOL hasFront = (self.frontImage != nil);
        self.frontPreview.hidden = !hasFront;
        self.frontIconView.hidden = hasFront;
        self.backPreview.image = self.backImage;
        BOOL hasBack = (self.backImage != nil);
        self.backPreview.hidden = !hasBack;
        self.backIconView.hidden = hasBack;
    } else {
        NSString *frontUrlStr = [VerificationRequest shared].cachedRealnameFrontUrl;
        NSString *backUrlStr = [VerificationRequest shared].cachedRealnameBackUrl;
        NSURL *frontURL = frontUrlStr.length > 0 ? [NSURL URLWithString:frontUrlStr] : nil;
        NSURL *backURL = backUrlStr.length > 0 ? [NSURL URLWithString:backUrlStr] : nil;
        [self.frontDisplayImage sd_setImageWithURL:frontURL placeholderImage:nil];
        [self.backDisplayImage sd_setImageWithURL:backURL placeholderImage:nil];
    }

    [self.content mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
        if (showUnverified)
            make.bottom.equalTo(self.submitBtn.mas_bottom).offset(40);
        else
            make.bottom.equalTo(self.readOnlyCard.mas_bottom).offset(40);
    }];
}

- (void)onBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onTapFrontUpload {
    self.currentUploadSlot = 0;
    [self presentImagePicker];
}

- (void)onTapBackUpload {
    self.currentUploadSlot = 1;
    [self presentImagePicker];
}

- (void)presentImagePicker {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    picker.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    UIImage *img = info[UIImagePickerControllerOriginalImage];
    if (self.currentUploadSlot == 0) {
        self.frontImage = img;
        self.frontPreview.image = img;
        self.frontPreview.hidden = NO;
        self.frontIconView.hidden = YES;
    } else {
        self.backImage = img;
        self.backPreview.image = img;
        self.backPreview.hidden = NO;
        self.backIconView.hidden = YES;
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)onSubmit {
    if (self.completed) return;
    if (!self.frontImage || !self.backImage) {
        [self showError:NSLocalizedString(@"auth_please_upload_both", nil)];
        return;
    }
    [self showLoading];
    __weak typeof(self) weakSelf = self;
    UIImage *frontImage = self.frontImage;
    UIImage *backImage = self.backImage;
    // JPEG 编码是 CPU 密集型操作，必须放到后台队列，否则主线程冻结会触发 watchdog (0x8badf00d)
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSData *frontJPEG = UIImageJPEGRepresentation(frontImage, 0.85);
        NSData *backJPEG = UIImageJPEGRepresentation(backImage, 0.85);
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            if (frontJPEG.length == 0 || backJPEG.length == 0) {
                [self hideLoading];
                [self showError:NSLocalizedString(@"auth_please_upload_both", nil)];
                return;
            }
            [[FileRequest shared] uploadImage:frontJPEG type:ImageObjectTypeIDCard success:^(HTTPResponse * _Nullable r1) {
                NSString *frontUrl = [r1.dataObject isKindOfClass:[NSString class]] ? r1.dataObject : nil;
                if (frontUrl.length == 0) {
                    __strong typeof(weakSelf) self = weakSelf;
                    if (!self) return;
                    [self hideLoading];
                    [self showError:NSLocalizedString(@"auth_please_upload_both", nil)];
                    return;
                }
                [[FileRequest shared] uploadImage:backJPEG type:ImageObjectTypeIDCard success:^(HTTPResponse * _Nullable r2) {
                    NSString *backUrl = [r2.dataObject isKindOfClass:[NSString class]] ? r2.dataObject : nil;
                    if (backUrl.length == 0) {
                        __strong typeof(weakSelf) self = weakSelf;
                        if (!self) return;
                        [self hideLoading];
                        [self showError:NSLocalizedString(@"auth_please_upload_both", nil)];
                        return;
                    }
                    [[VerificationRequest shared] submitRealnameWithFrontUrl:frontUrl backUrl:backUrl success:^(HTTPResponse * _Nullable responseObject) {
                        __strong typeof(weakSelf) self = weakSelf;
                        if (!self) return;
                        void (^finishFlow)(void) = ^{
                            [self hideLoading];
                            [self showSuccess:NSLocalizedString(@"auth_realname_success", nil)];
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                [self.navigationController popViewControllerAnimated:YES];
                            });
                        };
                        [[VerificationRequest shared] fetchStatusSuccess:^(HTTPResponse * _Nullable responseObject) {
                            finishFlow();
                        } failure:^(NSError * _Nonnull error) {
                            finishFlow();
                        }];
                    } failure:^(NSError * _Nonnull error) {
                        __strong typeof(weakSelf) self = weakSelf;
                        if (!self) return;
                        [self hideLoading];
                        [self showError:error.localizedDescription.length ? error.localizedDescription : NSLocalizedString(@"profile_save_fail", nil)];
                    }];
                } failure:^(NSError * _Nonnull error) {
                    __strong typeof(weakSelf) self = weakSelf;
                    if (!self) return;
                    [self hideLoading];
                    [self showError:error.localizedDescription.length ? error.localizedDescription : NSLocalizedString(@"profile_save_fail", nil)];
                }];
            } failure:^(NSError * _Nonnull error) {
                __strong typeof(weakSelf) self = weakSelf;
                if (!self) return;
                [self hideLoading];
                [self showError:error.localizedDescription.length ? error.localizedDescription : NSLocalizedString(@"profile_save_fail", nil)];
            }];
        });
    });
}

- (void)updateLocalizedStrings {
    [super updateLocalizedStrings];
    self.hintLabel.text = NSLocalizedString(@"auth_realname_hint", nil);
    self.subHintLabel.text = NSLocalizedString(@"auth_realname_subhint", nil);
    self.idInfoTitleLabel.text = NSLocalizedString(@"auth_id_info_title", nil);
    self.frontLabel.text = NSLocalizedString(@"auth_id_front_label", nil);
    self.backLabel.text = NSLocalizedString(@"auth_id_back_label", nil);
    [self.submitBtn setTitle:NSLocalizedString(@"auth_submit_now", nil) forState:UIControlStateNormal];
    self.completedHeaderLabel.text = NSLocalizedString(@"auth_realname_completed", nil);
    self.readOnlyTitleLabel.text = NSLocalizedString(@"auth_id_info_title", nil);
    self.frontDisplayLabel.text = NSLocalizedString(@"auth_id_front_display", nil);
    self.backDisplayLabel.text = NSLocalizedString(@"auth_id_back_display", nil);
}

@end
