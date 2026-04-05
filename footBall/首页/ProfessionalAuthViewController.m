//
//  ProfessionalAuthViewController.m
//  footBall
//

#import "ProfessionalAuthViewController.h"
#import "AuthStateStore.h"
#import <Masonry/Masonry.h>

// Figma 1:6314「职业认证」
#define kPANavBg       [UIColor colorWithRed:13/255.0 green:33/255.0 blue:34/255.0 alpha:1.0]   // #0d2122
#define kPAPageBg      [UIColor colorWithRed:247/255.0 green:247/255.0 blue:247/255.0 alpha:1.0] // #f7f7f7
#define kPACardBg      [UIColor whiteColor]
#define kPAButtonGreen [UIColor colorWithRed:40/255.0 green:93/255.0 blue:75/255.0 alpha:1.0]   // #285d4b
#define kPASubHintGray [UIColor colorWithRed:191/255.0 green:191/255.0 blue:191/255.0 alpha:1.0] // #bfbfbf
#define kPAPhotoPlaceholderBg [UIColor colorWithRed:244/255.0 green:244/255.0 blue:244/255.0 alpha:1.0] // #f4f4f4
#define kPATextWorkTitle [UIColor colorWithRed:53/255.0 green:53/255.0 blue:53/255.0 alpha:1.0] // #353535

static CGFloat const kPAHeaderHeight = 240.f;
static CGFloat const kPAWorkCardTop = 176.f;
static CGFloat const kPAWorkCardSideInset = 16.f;
static CGFloat const kPAWorkCardInnerInset = 13.f;
static CGFloat const kPAGridInteritem = 15.f;
static CGFloat const kPAGridLineSpacing = 18.f;
/// 稿中单元约 150×206
static CGFloat const kPACellRefW = 150.f;
static CGFloat const kPACellRefH = 206.f;

/// Figma 1:4218「职业认证」已完成态
static CGFloat const kPACompletedHeaderLeading = 15.f;   // 稿 x=15
static CGFloat const kPACompletedBelowTitle = 22.f;      // 稿 y=108，与标题间距约 22
static CGFloat const kPAVerifiedTitleTop = 16.f;         // 192−176
static CGFloat const kPAVerifiedTitleLeading = 14.f;     // 30−16
static CGFloat const kPAVerifiedTitleToImage = 17.f;     // 234−217（标题约 25 高）
static CGFloat const kPAVerifiedImageInset = 17.f;       // 33−16
static CGFloat const kPAVerifiedImageH = 428.f;          // 稿单张展示区域高
static CGFloat const kPAVerifiedCardBottomInset = 23.f;  // 685−662

static const NSInteger kMaxProfessionalImages = 4;

static CGSize kPAGridCellSizeForScreen(void) {
    CGFloat screenW = CGRectGetWidth([UIScreen mainScreen].bounds);
    CGFloat cardW = screenW - kPAWorkCardSideInset * 2;
    CGFloat inner = cardW - kPAWorkCardInnerInset * 2 - kPAGridInteritem;
    CGFloat cellW = inner / 2.0;
    CGFloat cellH = cellW * kPACellRefH / kPACellRefW;
    return CGSizeMake(cellW, cellH);
}

@interface ProfessionalAuthViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *content;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UILabel *hintLabel;
@property (nonatomic, strong) UILabel *subHintLabel;
@property (nonatomic, strong) UIView *workCard;
@property (nonatomic, strong) UILabel *workTitleLabel;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIButton *submitBtn;

@property (nonatomic, strong) UILabel *completedHeaderLabel;
@property (nonatomic, strong) UIView *readOnlyCard;
@property (nonatomic, strong) UILabel *readOnlyTitleLabel;
@property (nonatomic, strong) UIImageView *readOnlyImageView;

@property (nonatomic, assign) BOOL completed;
@property (nonatomic, strong) NSMutableArray<UIImage *> *uploadedImages;
@property (nonatomic, assign) NSInteger pickingIndex;
@end

@implementation ProfessionalAuthViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hidesBottomBarWhenPushed = YES;
    self.shouldShowNavigationBar = NO;
    self.view.backgroundColor = kPAPageBg;
    self.completed = [AuthStateStore isProfessionalAuthCompleted];
    self.uploadedImages = [NSMutableArray arrayWithArray:[AuthStateStore professionalImages]];
}

- (void)setupUI {
    if (@available(iOS 11.0, *)) {
        self.scrollView = [UIScrollView new];
        self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
        self.scrollView = [UIScrollView new];
    }
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.backgroundColor = kPAPageBg;
    [self.view addSubview:self.scrollView];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    self.content = [UIView new];
    [self.scrollView addSubview:self.content];

    self.headerView = [UIView new];
    self.headerView.backgroundColor = kPANavBg;
    [self.content addSubview:self.headerView];
    [self.headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.content);
        make.height.mas_equalTo(kPAHeaderHeight);
    }];

    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *adLeft = [UIImage imageNamed:@"ad_left"];
    UIImage *backImg = adLeft ?: [UIImage imageNamed:@"nav_back"];
    if (!backImg && @available(iOS 13.0, *)) {
        backImg = [UIImage systemImageNamed:@"arrow.left"];
    }
    if (backImg) {
        [backBtn setImage:[backImg imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        backBtn.tintColor = [UIColor whiteColor];
    }
    backBtn.adjustsImageWhenHighlighted = NO;
    [backBtn addTarget:self action:@selector(onBack) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView addSubview:backBtn];
    static CGFloat const kBackHit = 44.f;
    static CGFloat const kBackVisual = 24.f;
    CGFloat backInset = (kBackHit - kBackVisual) / 2.f;
    backBtn.imageEdgeInsets = UIEdgeInsetsMake(backInset, 0, backInset, 0);
    backBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11.0, *)) {
            make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft).offset(14);
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(17);
        } else {
            make.left.equalTo(self.headerView).offset(14);
            make.top.equalTo(self.mas_topLayoutGuide).offset(17);
        }
        make.size.mas_equalTo(CGSizeMake(kBackHit, kBackHit));
    }];

    UILabel *navTitle = [UILabel new];
    navTitle.text = NSLocalizedString(@"auth_professional_nav_title", nil);
    navTitle.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    navTitle.textColor = [UIColor whiteColor];
    [self.headerView addSubview:navTitle];
    [navTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.headerView);
        make.centerY.equalTo(backBtn);
    }];

    self.hintLabel = [UILabel new];
    self.hintLabel.text = NSLocalizedString(@"auth_professional_hint", nil);
    self.hintLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    self.hintLabel.textColor = [UIColor whiteColor];
    self.hintLabel.numberOfLines = 0;
    [self.headerView addSubview:self.hintLabel];
    [self.hintLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(backBtn.mas_bottom).offset(23);
        if (@available(iOS 11.0, *)) {
            make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft).offset(14);
            make.right.equalTo(self.view.mas_safeAreaLayoutGuideRight).offset(-14);
        } else {
            make.left.equalTo(self.headerView).offset(14);
            make.right.equalTo(self.headerView).offset(-14);
        }
    }];

    self.subHintLabel = [UILabel new];
    self.subHintLabel.text = NSLocalizedString(@"auth_professional_subhint", nil);
    self.subHintLabel.font = [UIFont systemFontOfSize:13];
    self.subHintLabel.textColor = kPASubHintGray;
    self.subHintLabel.numberOfLines = 0;
    [self.headerView addSubview:self.subHintLabel];
    [self.subHintLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.hintLabel.mas_bottom).offset(9);
        if (@available(iOS 11.0, *)) {
            make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft).offset(14);
            make.right.equalTo(self.view.mas_safeAreaLayoutGuideRight).offset(-14);
        } else {
            make.left.equalTo(self.headerView).offset(14);
            make.right.equalTo(self.headerView).offset(-14);
        }
    }];

    // 已完成职业认证：Figma 1:4246（仅已认证时显示）
    self.completedHeaderLabel = [UILabel new];
    self.completedHeaderLabel.text = NSLocalizedString(@"auth_professional_completed", nil);
    self.completedHeaderLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    self.completedHeaderLabel.textColor = [UIColor whiteColor];
    self.completedHeaderLabel.numberOfLines = 0;
    self.completedHeaderLabel.hidden = YES;
    [self.headerView addSubview:self.completedHeaderLabel];
    [self.completedHeaderLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11.0, *)) {
            make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft).offset(kPACompletedHeaderLeading);
            make.right.lessThanOrEqualTo(self.view.mas_safeAreaLayoutGuideRight).offset(-14);
        } else {
            make.left.equalTo(self.headerView).offset(kPACompletedHeaderLeading);
            make.right.lessThanOrEqualTo(self.headerView).offset(-14);
        }
        make.top.equalTo(navTitle.mas_bottom).offset(kPACompletedBelowTitle);
    }];

    [self buildUnverifiedUI];
    [self buildVerifiedUI];
    [self refreshState];
}

- (void)buildUnverifiedUI {
    self.workCard = [UIView new];
    self.workCard.backgroundColor = kPACardBg;
    self.workCard.layer.cornerRadius = 6;
    self.workCard.layer.shadowColor = [UIColor blackColor].CGColor;
    self.workCard.layer.shadowOpacity = 0.08;
    self.workCard.layer.shadowOffset = CGSizeMake(0, 2);
    self.workCard.layer.shadowRadius = 8;
    [self.content addSubview:self.workCard];
    [self.workCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.content).offset(kPAWorkCardTop);
        make.leading.equalTo(self.content).offset(kPAWorkCardSideInset);
        make.trailing.equalTo(self.content).offset(-kPAWorkCardSideInset);
    }];

    self.workTitleLabel = [UILabel new];
    self.workTitleLabel.text = NSLocalizedString(@"auth_work_cert_title", nil);
    self.workTitleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    self.workTitleLabel.textColor = kPATextWorkTitle;
    [self.workCard addSubview:self.workTitleLabel];
    [self.workTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.workCard).offset(16);
        make.leading.equalTo(self.workCard).offset(kPAWorkCardInnerInset);
        make.trailing.lessThanOrEqualTo(self.workCard).offset(-kPAWorkCardInnerInset);
    }];

    CGSize cellSz = kPAGridCellSizeForScreen();
    CGFloat gridH = cellSz.height * 2 + kPAGridLineSpacing;

    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.minimumInteritemSpacing = kPAGridInteritem;
    layout.minimumLineSpacing = kPAGridLineSpacing;
    layout.sectionInset = UIEdgeInsetsZero;
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.scrollEnabled = NO;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    [self.workCard addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.workTitleLabel.mas_bottom).offset(12);
        make.leading.equalTo(self.workCard).offset(kPAWorkCardInnerInset);
        make.trailing.equalTo(self.workCard).offset(-kPAWorkCardInnerInset);
        make.height.mas_equalTo(gridH);
        make.bottom.equalTo(self.workCard).offset(-20);
    }];

    self.submitBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.submitBtn.backgroundColor = kPAButtonGreen;
    self.submitBtn.layer.cornerRadius = 26;
    self.submitBtn.layer.shadowColor = [UIColor blackColor].CGColor;
    self.submitBtn.layer.shadowOpacity = 0.19f;
    self.submitBtn.layer.shadowOffset = CGSizeMake(0, 2);
    self.submitBtn.layer.shadowRadius = 4;
    [self.submitBtn setTitle:NSLocalizedString(@"auth_submit_now", nil) forState:UIControlStateNormal];
    [self.submitBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.submitBtn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [self.submitBtn addTarget:self action:@selector(onSubmit) forControlEvents:UIControlEventTouchUpInside];
    [self.content addSubview:self.submitBtn];
    [self.submitBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.workCard.mas_bottom).offset(24);
        make.leading.equalTo(self.content).offset(24);
        make.trailing.equalTo(self.content).offset(-24);
        make.height.mas_equalTo(52);
    }];
}

- (void)buildVerifiedUI {
    // Figma 1:4248/1:4250：白卡 343×509，单张作品区 310×428
    self.readOnlyCard = [UIView new];
    self.readOnlyCard.backgroundColor = kPACardBg;
    self.readOnlyCard.layer.cornerRadius = 6;
    self.readOnlyCard.layer.shadowColor = [UIColor blackColor].CGColor;
    self.readOnlyCard.layer.shadowOpacity = 0.08;
    self.readOnlyCard.layer.shadowOffset = CGSizeMake(0, 2);
    self.readOnlyCard.layer.shadowRadius = 8;
    [self.content addSubview:self.readOnlyCard];
    [self.readOnlyCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.content).offset(kPAWorkCardTop);
        make.leading.equalTo(self.content).offset(kPAWorkCardSideInset);
        make.trailing.equalTo(self.content).offset(-kPAWorkCardSideInset);
    }];

    self.readOnlyTitleLabel = [UILabel new];
    self.readOnlyTitleLabel.text = NSLocalizedString(@"auth_work_cert_title", nil);
    /// 稿 1:4249 Small Label 12px
    self.readOnlyTitleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    self.readOnlyTitleLabel.textColor = kPATextWorkTitle;
    [self.readOnlyCard addSubview:self.readOnlyTitleLabel];
    [self.readOnlyTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.readOnlyCard).offset(kPAVerifiedTitleTop);
        make.leading.equalTo(self.readOnlyCard).offset(kPAVerifiedTitleLeading);
        make.trailing.lessThanOrEqualTo(self.readOnlyCard).offset(-kPAVerifiedTitleLeading);
    }];

    self.readOnlyImageView = [UIImageView new];
    self.readOnlyImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.readOnlyImageView.backgroundColor = kPAPhotoPlaceholderBg;
    self.readOnlyImageView.layer.cornerRadius = 6;
    self.readOnlyImageView.clipsToBounds = YES;
    [self.readOnlyCard addSubview:self.readOnlyImageView];
    [self.readOnlyImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.readOnlyTitleLabel.mas_bottom).offset(kPAVerifiedTitleToImage);
        make.leading.equalTo(self.readOnlyCard).offset(kPAVerifiedImageInset);
        make.trailing.equalTo(self.readOnlyCard).offset(-kPAVerifiedImageInset);
        make.height.mas_equalTo(kPAVerifiedImageH);
        make.bottom.equalTo(self.readOnlyCard).offset(-kPAVerifiedCardBottomInset);
    }];
}

- (void)refreshState {
    self.completed = [AuthStateStore isProfessionalAuthCompleted];
    [self.uploadedImages setArray:[AuthStateStore professionalImages]];

    BOOL showUnverified = !self.completed;
    self.hintLabel.hidden = !showUnverified;
    self.subHintLabel.hidden = !showUnverified;
    self.workCard.hidden = !showUnverified;
    self.collectionView.hidden = !showUnverified;
    self.submitBtn.hidden = !showUnverified;

    self.readOnlyCard.hidden = showUnverified;
    self.completedHeaderLabel.hidden = showUnverified;

    if (showUnverified) {
        [self.collectionView reloadData];
    } else {
        NSArray<UIImage *> *imgs = [AuthStateStore professionalImages];
        self.readOnlyImageView.image = imgs.firstObject;
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

#pragma mark - UICollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return kMaxProfessionalImages;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    for (UIView *v in cell.contentView.subviews) [v removeFromSuperview];
    cell.contentView.layer.cornerRadius = 6;
    cell.contentView.clipsToBounds = YES;

    if (indexPath.item < (NSInteger)self.uploadedImages.count) {
        cell.contentView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
        UIImageView *iv = [UIImageView new];
        iv.contentMode = UIViewContentModeScaleAspectFill;
        iv.clipsToBounds = YES;
        iv.image = self.uploadedImages[indexPath.item];
        [cell.contentView addSubview:iv];
        [iv mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(cell.contentView);
        }];
    } else {
        cell.contentView.backgroundColor = kPAPhotoPlaceholderBg;
        UIImageView *cam = [UIImageView new];
        cam.contentMode = UIViewContentModeScaleAspectFit;
        UIImage *camImg = [UIImage imageNamed:@"camera_d"];
        if (!camImg) camImg = [UIImage imageNamed:@"camera_upload"];
        if (!camImg && @available(iOS 13.0, *)) {
            camImg = [[UIImage systemImageNamed:@"camera.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cam.tintColor = kPAButtonGreen;
        }
        cam.image = camImg;
        [cell.contentView addSubview:cam];
        [cam mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(cell.contentView);
            make.size.mas_equalTo(CGSizeMake(32, 32));
        }];
    }
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return kPAGridCellSizeForScreen();
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == (NSInteger)self.uploadedImages.count && self.uploadedImages.count < kMaxProfessionalImages) {
        self.pickingIndex = indexPath.item;
        [self presentImagePicker];
    }
}

- (void)onBack {
    [self.navigationController popViewControllerAnimated:YES];
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
    if (img && self.pickingIndex <= (NSInteger)self.uploadedImages.count) {
        [self.uploadedImages insertObject:img atIndex:(NSUInteger)self.pickingIndex];
        [self.collectionView reloadData];
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)onSubmit {
    if (self.completed) return;
    if (self.uploadedImages.count == 0) {
        [self showError:NSLocalizedString(@"auth_please_upload_work_cert", nil)];
        return;
    }
    [self showLoading];
    NSMutableArray<NSString *> *urls = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;
    __block void (^uploadNext)(NSUInteger);
    uploadNext = ^(NSUInteger idx) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        if (idx >= self.uploadedImages.count) {
            [[VerificationRequest shared] submitProfessionalWithImageUrls:[urls copy] success:^(HTTPResponse * _Nullable responseObject) {
                __strong typeof(weakSelf) self2 = weakSelf;
                if (!self2) return;
                void (^applyLocalAndFinish)(void) = ^{
                    [self2 hideLoading];
                    [AuthStateStore saveProfessionalImages:[self2.uploadedImages copy]];
                    [AuthStateStore setProfessionalAuthCompleted:YES];
                    [self2 showSuccess:NSLocalizedString(@"auth_professional_success", nil)];
                    __weak typeof(self2) w = self2;
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [w refreshState];
                    });
                };
                [[UserRequest shared] getLoginUserInfoSuccess:^(HTTPResponse * _Nullable resp) {
                    applyLocalAndFinish();
                } failure:^(NSError * _Nonnull error) {
                    applyLocalAndFinish();
                }];
            } failure:^(NSError * _Nonnull error) {
                __strong typeof(weakSelf) self2 = weakSelf;
                if (!self2) return;
                [self2 hideLoading];
                [self2 showError:error.localizedDescription.length ? error.localizedDescription : NSLocalizedString(@"profile_save_fail", nil)];
            }];
            return;
        }
        UIImage *img = self.uploadedImages[idx];
        NSData *jpeg = UIImageJPEGRepresentation(img, 0.85);
        if (jpeg.length == 0) {
            [self hideLoading];
            [self showError:NSLocalizedString(@"auth_please_upload_work_cert", nil)];
            return;
        }
        [[FileRequest shared] uploadImage:jpeg type:ImageObjectTypeProfessional success:^(HTTPResponse * _Nullable resp) {
            NSString *url = [resp.dataObject isKindOfClass:[NSString class]] ? resp.dataObject : nil;
            if (url.length == 0) {
                __strong typeof(weakSelf) self2 = weakSelf;
                if (!self2) return;
                [self2 hideLoading];
                [self2 showError:NSLocalizedString(@"auth_please_upload_work_cert", nil)];
                return;
            }
            [urls addObject:url];
            uploadNext(idx + 1);
        } failure:^(NSError * _Nonnull error) {
            __strong typeof(weakSelf) self2 = weakSelf;
            if (!self2) return;
            [self2 hideLoading];
            [self2 showError:error.localizedDescription.length ? error.localizedDescription : NSLocalizedString(@"profile_save_fail", nil)];
        }];
    };
    uploadNext(0);
}

- (void)updateLocalizedStrings {
    [super updateLocalizedStrings];
    self.hintLabel.text = NSLocalizedString(@"auth_professional_hint", nil);
    self.subHintLabel.text = NSLocalizedString(@"auth_professional_subhint", nil);
    self.workTitleLabel.text = NSLocalizedString(@"auth_work_cert_title", nil);
    [self.submitBtn setTitle:NSLocalizedString(@"auth_submit_now", nil) forState:UIControlStateNormal];
    self.completedHeaderLabel.text = NSLocalizedString(@"auth_professional_completed", nil);
    self.readOnlyTitleLabel.text = NSLocalizedString(@"auth_work_cert_title", nil);
}

@end
