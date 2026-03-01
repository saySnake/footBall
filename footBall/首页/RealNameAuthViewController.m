//
//  RealNameAuthViewController.m
//  footBall
//

#import "RealNameAuthViewController.h"
#import "AuthStateStore.h"
#import <Masonry/Masonry.h>

#define kRANavBg    [UIColor colorWithRed:0.114 green:0.188 blue:0.176 alpha:1.0]
#define kRAPageBg   [UIColor colorWithRed:0.965 green:0.965 blue:0.965 alpha:1.0]
#define kRACardBg   [UIColor whiteColor]
#define kRAButtonGreen [UIColor colorWithRed:0.18 green:0.424 blue:0.329 alpha:1.0]

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
    self.completed = [AuthStateStore isRealNameAuthCompleted];
    self.frontImage = [AuthStateStore realNameFrontImage];
    self.backImage = [AuthStateStore realNameBackImage];
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
        make.height.mas_equalTo(168);
    }];

    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    if (@available(iOS 13.0, *)) {
        [backBtn setImage:[UIImage systemImageNamed:@"arrow.left"] forState:UIControlStateNormal];
    }
    backBtn.tintColor = [UIColor whiteColor];
    [backBtn addTarget:self action:@selector(onBack) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView addSubview:backBtn];
    [backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.headerView).offset(16);
        make.top.equalTo(self.headerView).offset(50);
        make.size.mas_equalTo(CGSizeMake(36, 36));
    }];

    UILabel *navTitle = [UILabel new];
    navTitle.text = NSLocalizedString(@"auth_realname_nav_title", nil);
    navTitle.font = [UIFont boldSystemFontOfSize:17];
    navTitle.textColor = [UIColor whiteColor];
    [self.headerView addSubview:navTitle];
    [navTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.headerView);
        make.centerY.equalTo(backBtn);
    }];

    // 绿色区域说明：请完善证件信息、已上传信息将为您保存15天（仅未认证时显示）
    self.hintLabel = [UILabel new];
    self.hintLabel.text = NSLocalizedString(@"auth_realname_hint", nil);
    self.hintLabel.font = [UIFont boldSystemFontOfSize:17];
    self.hintLabel.textColor = [UIColor whiteColor];
    [self.headerView addSubview:self.hintLabel];
    [self.hintLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(backBtn.mas_bottom).offset(20);
        make.leading.equalTo(self.headerView).offset(20);
        make.trailing.equalTo(self.headerView).offset(-20);
    }];

    self.subHintLabel = [UILabel new];
    self.subHintLabel.text = NSLocalizedString(@"auth_realname_subhint", nil);
    self.subHintLabel.font = [UIFont systemFontOfSize:14];
    self.subHintLabel.textColor = [UIColor colorWithWhite:0.88 alpha:1.0];
    self.subHintLabel.numberOfLines = 0;
    [self.headerView addSubview:self.subHintLabel];
    [self.subHintLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.hintLabel.mas_bottom).offset(6);
        make.leading.trailing.equalTo(self.headerView).inset(20);
    }];

    // 已完成实名认证：放在绿色顶栏内（仅已认证时显示）
    self.completedHeaderLabel = [UILabel new];
    self.completedHeaderLabel.text = NSLocalizedString(@"auth_realname_completed", nil);
    self.completedHeaderLabel.font = [UIFont systemFontOfSize:15];
    self.completedHeaderLabel.textColor = [UIColor whiteColor];
    self.completedHeaderLabel.hidden = YES;
    [self.headerView addSubview:self.completedHeaderLabel];
    [self.completedHeaderLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.headerView).offset(20);
        make.top.equalTo(navTitle.mas_bottom).offset(14);
    }];

    [self buildUnverifiedUI];
    [self buildVerifiedUI];
    [self refreshState];
}

- (void)buildUnverifiedUI {
    // 身份信息白卡：仅含「身份信息」标题 + 两个上传区，置于绿底与白底交界，顶部与绿底略微重叠
    self.idCardCard = [UIView new];
    self.idCardCard.backgroundColor = kRACardBg;
    self.idCardCard.layer.cornerRadius = 12;
    self.idCardCard.layer.shadowColor = [UIColor blackColor].CGColor;
    self.idCardCard.layer.shadowOpacity = 0.08;
    self.idCardCard.layer.shadowOffset = CGSizeMake(0, 2);
    self.idCardCard.layer.shadowRadius = 10;
    [self.content addSubview:self.idCardCard];
    [self.idCardCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView.mas_bottom).offset(-16);
        make.leading.equalTo(self.content).offset(12);
        make.trailing.equalTo(self.content).offset(-12);
    }];

    self.idInfoTitleLabel = [UILabel new];
    self.idInfoTitleLabel.text = NSLocalizedString(@"auth_id_info_title", nil);
    self.idInfoTitleLabel.font = [UIFont boldSystemFontOfSize:16];
    self.idInfoTitleLabel.textColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
    [self.idCardCard addSubview:self.idInfoTitleLabel];
    [self.idInfoTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.equalTo(self.idCardCard).offset(20);
        make.trailing.lessThanOrEqualTo(self.idCardCard).offset(-20);
    }];

    CGFloat smallCardH = 100;
    self.frontUploadArea = [UIControl new];
    self.frontUploadArea.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    self.frontUploadArea.layer.cornerRadius = 12;
    [self.frontUploadArea addTarget:self action:@selector(onTapFrontUpload) forControlEvents:UIControlEventTouchUpInside];
    [self.idCardCard addSubview:self.frontUploadArea];
    [self.frontUploadArea mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.idInfoTitleLabel.mas_bottom).offset(16);
        make.leading.trailing.equalTo(self.idCardCard).inset(20);
        make.height.mas_equalTo(smallCardH);
    }];

    UIView *frontCircle = [UIView new];
    frontCircle.backgroundColor = kRAButtonGreen;
    frontCircle.layer.cornerRadius = 32;
    [self.frontUploadArea addSubview:frontCircle];
    [frontCircle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.frontUploadArea);
        make.centerY.equalTo(self.frontUploadArea);
        make.size.mas_equalTo(CGSizeMake(64, 64));
    }];
    self.frontIconView = [UIImageView new];
    if (@available(iOS 13.0, *)) {
        self.frontIconView.image = [UIImage systemImageNamed:@"camera.fill"];
        self.frontIconView.tintColor = [UIColor whiteColor];
    }
    self.frontIconView.contentMode = UIViewContentModeScaleAspectFit;
    [frontCircle addSubview:self.frontIconView];
    [self.frontIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(frontCircle);
        make.size.mas_equalTo(CGSizeMake(28, 28));
    }];
    self.frontPreview = [UIImageView new];
    self.frontPreview.contentMode = UIViewContentModeScaleAspectFill;
    self.frontPreview.clipsToBounds = YES;
    self.frontPreview.layer.cornerRadius = 8;
    self.frontPreview.hidden = YES;
    [self.frontUploadArea addSubview:self.frontPreview];
    [self.frontPreview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.frontUploadArea).inset(8);
    }];

    self.frontLabel = [UILabel new];
    self.frontLabel.text = NSLocalizedString(@"auth_id_front_label", nil);
    self.frontLabel.font = [UIFont systemFontOfSize:14];
    self.frontLabel.textColor = [UIColor colorWithRed:0.45 green:0.45 blue:0.45 alpha:1.0];
    self.frontLabel.textAlignment = NSTextAlignmentCenter;
    [self.idCardCard addSubview:self.frontLabel];
    [self.frontLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.frontUploadArea.mas_bottom).offset(8);
        make.centerX.equalTo(self.idCardCard);
    }];

    self.backUploadArea = [UIControl new];
    self.backUploadArea.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    self.backUploadArea.layer.cornerRadius = 12;
    [self.backUploadArea addTarget:self action:@selector(onTapBackUpload) forControlEvents:UIControlEventTouchUpInside];
    [self.idCardCard addSubview:self.backUploadArea];
    [self.backUploadArea mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.frontLabel.mas_bottom).offset(16);
        make.leading.trailing.equalTo(self.idCardCard).inset(20);
        make.height.mas_equalTo(smallCardH);
    }];

    UIView *backCircle = [UIView new];
    backCircle.backgroundColor = kRAButtonGreen;
    backCircle.layer.cornerRadius = 32;
    [self.backUploadArea addSubview:backCircle];
    [backCircle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.backUploadArea);
        make.centerY.equalTo(self.backUploadArea);
        make.size.mas_equalTo(CGSizeMake(64, 64));
    }];
    self.backIconView = [UIImageView new];
    if (@available(iOS 13.0, *)) {
        self.backIconView.image = [UIImage systemImageNamed:@"camera.fill"];
        self.backIconView.tintColor = [UIColor whiteColor];
    }
    self.backIconView.contentMode = UIViewContentModeScaleAspectFit;
    [backCircle addSubview:self.backIconView];
    [self.backIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(backCircle);
        make.size.mas_equalTo(CGSizeMake(28, 28));
    }];
    self.backPreview = [UIImageView new];
    self.backPreview.contentMode = UIViewContentModeScaleAspectFill;
    self.backPreview.clipsToBounds = YES;
    self.backPreview.layer.cornerRadius = 8;
    self.backPreview.hidden = YES;
    [self.backUploadArea addSubview:self.backPreview];
    [self.backPreview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.backUploadArea).inset(8);
    }];

    self.backLabel = [UILabel new];
    self.backLabel.text = NSLocalizedString(@"auth_id_back_label", nil);
    self.backLabel.font = [UIFont systemFontOfSize:14];
    self.backLabel.textColor = [UIColor colorWithRed:0.45 green:0.45 blue:0.45 alpha:1.0];
    self.backLabel.textAlignment = NSTextAlignmentCenter;
    [self.idCardCard addSubview:self.backLabel];
    [self.backLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.backUploadArea.mas_bottom).offset(8);
        make.centerX.equalTo(self.idCardCard);
        make.bottom.equalTo(self.idCardCard).offset(-20);
    }];

    self.submitBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    self.submitBtn.backgroundColor = kRAButtonGreen;
    self.submitBtn.layer.cornerRadius = 25;
    [self.submitBtn setTitle:NSLocalizedString(@"auth_submit_now", nil) forState:UIControlStateNormal];
    [self.submitBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.submitBtn.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
    [self.submitBtn addTarget:self action:@selector(onSubmit) forControlEvents:UIControlEventTouchUpInside];
    [self.content addSubview:self.submitBtn];
    [self.submitBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.idCardCard.mas_bottom).offset(24);
        make.leading.equalTo(self.content).offset(12);
        make.trailing.equalTo(self.content).offset(-12);
        make.height.mas_equalTo(50);
    }];
}

- (void)buildVerifiedUI {
    // 已认证：白卡置于绿底与白底交界，顶部与绿色底栏略微重叠；卡内仅 身份信息 + 正面图片 + 徽章面照片
    self.readOnlyCard = [UIView new];
    self.readOnlyCard.backgroundColor = kRACardBg;
    self.readOnlyCard.layer.cornerRadius = 12;
    self.readOnlyCard.layer.shadowColor = [UIColor blackColor].CGColor;
    self.readOnlyCard.layer.shadowOpacity = 0.08;
    self.readOnlyCard.layer.shadowOffset = CGSizeMake(0, 2);
    self.readOnlyCard.layer.shadowRadius = 10;
    [self.content addSubview:self.readOnlyCard];
    [self.readOnlyCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView.mas_bottom).offset(-16);
        make.leading.equalTo(self.content).offset(12);
        make.trailing.equalTo(self.content).offset(-12);
    }];

    self.readOnlyTitleLabel = [UILabel new];
    self.readOnlyTitleLabel.text = NSLocalizedString(@"auth_id_info_title", nil);
    self.readOnlyTitleLabel.font = [UIFont boldSystemFontOfSize:16];
    self.readOnlyTitleLabel.textColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
    [self.readOnlyCard addSubview:self.readOnlyTitleLabel];
    [self.readOnlyTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.equalTo(self.readOnlyCard).offset(20);
        make.trailing.lessThanOrEqualTo(self.readOnlyCard).offset(-20);
    }];

    // 身份信息下面就是照片：第一张图 → 正面图片（文案在第一个图片下方）→ 第二张图 → 徽章面照片（文案在第二张图片下方）
    self.frontDisplayImage = [UIImageView new];
    self.frontDisplayImage.contentMode = UIViewContentModeScaleAspectFit;
    self.frontDisplayImage.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    self.frontDisplayImage.layer.cornerRadius = 8;
    self.frontDisplayImage.clipsToBounds = YES;
    [self.readOnlyCard addSubview:self.frontDisplayImage];
    [self.frontDisplayImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.readOnlyTitleLabel.mas_bottom).offset(12);
        make.leading.trailing.equalTo(self.readOnlyCard).inset(20);
        make.height.mas_equalTo(140);
    }];

    self.frontDisplayLabel = [UILabel new];
    self.frontDisplayLabel.text = NSLocalizedString(@"auth_id_front_display", nil);
    self.frontDisplayLabel.font = [UIFont systemFontOfSize:14];
    self.frontDisplayLabel.textColor = [UIColor colorWithRed:0.35 green:0.35 blue:0.35 alpha:1.0];
    self.frontDisplayLabel.textAlignment = NSTextAlignmentCenter;
    [self.readOnlyCard addSubview:self.frontDisplayLabel];
    [self.frontDisplayLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.frontDisplayImage.mas_bottom).offset(8);
        make.centerX.equalTo(self.readOnlyCard);
    }];

    self.backDisplayImage = [UIImageView new];
    self.backDisplayImage.contentMode = UIViewContentModeScaleAspectFit;
    self.backDisplayImage.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    self.backDisplayImage.layer.cornerRadius = 8;
    self.backDisplayImage.clipsToBounds = YES;
    [self.readOnlyCard addSubview:self.backDisplayImage];
    [self.backDisplayImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.frontDisplayLabel.mas_bottom).offset(16);
        make.leading.trailing.equalTo(self.readOnlyCard).inset(20);
        make.height.mas_equalTo(140);
    }];

    self.backDisplayLabel = [UILabel new];
    self.backDisplayLabel.text = NSLocalizedString(@"auth_id_back_display", nil);
    self.backDisplayLabel.font = [UIFont systemFontOfSize:14];
    self.backDisplayLabel.textColor = [UIColor colorWithRed:0.35 green:0.35 blue:0.35 alpha:1.0];
    self.backDisplayLabel.textAlignment = NSTextAlignmentCenter;
    [self.readOnlyCard addSubview:self.backDisplayLabel];
    [self.backDisplayLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.backDisplayImage.mas_bottom).offset(8);
        make.centerX.equalTo(self.readOnlyCard);
        make.bottom.equalTo(self.readOnlyCard).offset(-20);
    }];
}

- (void)refreshState {
    self.completed = [AuthStateStore isRealNameAuthCompleted];
    self.frontImage = [AuthStateStore realNameFrontImage];
    self.backImage = [AuthStateStore realNameBackImage];

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
        self.frontPreview.hidden = (self.frontImage == nil);
        self.backPreview.image = self.backImage;
        self.backPreview.hidden = (self.backImage == nil);
    } else {
        self.frontDisplayImage.image = self.frontImage;
        self.backDisplayImage.image = self.backImage;
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
    } else {
        self.backImage = img;
        self.backPreview.image = img;
        self.backPreview.hidden = NO;
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)onSubmit {
    if (!self.frontImage || !self.backImage) {
        [self showError:NSLocalizedString(@"auth_please_upload_both", nil)];
        return;
    }
    [AuthStateStore saveRealNameFrontImage:self.frontImage backImage:self.backImage];
    [AuthStateStore setRealNameAuthCompleted:YES];
    [self showSuccess:NSLocalizedString(@"auth_realname_success", nil)];
    __weak typeof(self) w = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [w refreshState];
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
