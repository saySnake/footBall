//
//  ProfessionalAuthViewController.m
//  footBall
//

#import "ProfessionalAuthViewController.h"
#import "AuthStateStore.h"
#import <Masonry/Masonry.h>

#define kPANavBg    [UIColor colorWithRed:0.114 green:0.188 blue:0.176 alpha:1.0]
#define kPAPageBg   [UIColor colorWithRed:0.965 green:0.965 blue:0.965 alpha:1.0]
#define kPACardBg   [UIColor whiteColor]
#define kPAButtonGreen [UIColor colorWithRed:0.18 green:0.424 blue:0.329 alpha:1.0]

static const NSInteger kMaxProfessionalImages = 4;

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
    navTitle.text = NSLocalizedString(@"auth_professional_nav_title", nil);
    navTitle.font = [UIFont boldSystemFontOfSize:17];
    navTitle.textColor = [UIColor whiteColor];
    [self.headerView addSubview:navTitle];
    [navTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.headerView);
        make.centerY.equalTo(backBtn);
    }];

    // 绿色区域：请完善一下职业信息、已上传信息将为您保存15天...（仅未认证时显示）
    self.hintLabel = [UILabel new];
    self.hintLabel.text = NSLocalizedString(@"auth_professional_hint", nil);
    self.hintLabel.font = [UIFont boldSystemFontOfSize:17];
    self.hintLabel.textColor = [UIColor whiteColor];
    [self.headerView addSubview:self.hintLabel];
    [self.hintLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(backBtn.mas_bottom).offset(20);
        make.leading.equalTo(self.headerView).offset(20);
        make.trailing.equalTo(self.headerView).offset(-20);
    }];

    self.subHintLabel = [UILabel new];
    self.subHintLabel.text = NSLocalizedString(@"auth_professional_subhint", nil);
    self.subHintLabel.font = [UIFont systemFontOfSize:14];
    self.subHintLabel.textColor = [UIColor colorWithWhite:0.88 alpha:1.0];
    self.subHintLabel.numberOfLines = 0;
    [self.headerView addSubview:self.subHintLabel];
    [self.subHintLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.hintLabel.mas_bottom).offset(6);
        make.leading.trailing.equalTo(self.headerView).inset(20);
    }];

    // 已完成职业认证：设计图在顶栏内、标题下方、左对齐、白字（仅已认证时显示）
    self.completedHeaderLabel = [UILabel new];
    self.completedHeaderLabel.text = NSLocalizedString(@"auth_professional_completed", nil);
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
    // 容器卡片：仅职业工作证标题 + 照片 2x2 网格，置于绿底与白底交界，卡片顶部略微与绿色底栏重叠
    self.workCard = [UIView new];
    self.workCard.backgroundColor = kPACardBg;
    self.workCard.layer.cornerRadius = 12;
    self.workCard.layer.shadowColor = [UIColor blackColor].CGColor;
    self.workCard.layer.shadowOpacity = 0.08;
    self.workCard.layer.shadowOffset = CGSizeMake(0, 2);
    self.workCard.layer.shadowRadius = 10;
    [self.content addSubview:self.workCard];
    [self.workCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView.mas_bottom).offset(-16);
        make.leading.equalTo(self.content).offset(12);
        make.trailing.equalTo(self.content).offset(-12);
    }];

    self.workTitleLabel = [UILabel new];
    self.workTitleLabel.text = NSLocalizedString(@"auth_work_cert_title", nil);
    self.workTitleLabel.font = [UIFont boldSystemFontOfSize:16];
    self.workTitleLabel.textColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
    [self.workCard addSubview:self.workTitleLabel];
    [self.workTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.equalTo(self.workCard).offset(20);
        make.trailing.lessThanOrEqualTo(self.workCard).offset(-20);
    }];

    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.minimumInteritemSpacing = 12;
    layout.minimumLineSpacing = 12;
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
        make.leading.trailing.equalTo(self.workCard).inset(20);
        CGFloat w = [UIScreen mainScreen].bounds.size.width - 12*2 - 20*2;
        CGFloat cellW = (w - 12) / 2.0;
        make.height.mas_equalTo(cellW * 2 + 12);
        make.bottom.equalTo(self.workCard).offset(-20);
    }];

    self.submitBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    self.submitBtn.backgroundColor = kPAButtonGreen;
    self.submitBtn.layer.cornerRadius = 25;
    [self.submitBtn setTitle:NSLocalizedString(@"auth_submit_now", nil) forState:UIControlStateNormal];
    [self.submitBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.submitBtn.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
    [self.submitBtn addTarget:self action:@selector(onSubmit) forControlEvents:UIControlEventTouchUpInside];
    [self.content addSubview:self.submitBtn];
    [self.submitBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.workCard.mas_bottom).offset(24);
        make.leading.equalTo(self.content).offset(12);
        make.trailing.equalTo(self.content).offset(-12);
        make.height.mas_equalTo(50);
    }];
}

- (void)buildVerifiedUI {
    // 已认证状态：白卡内仅「职业工作证」标题 + 工作证图片（与设计图一致）
    self.readOnlyCard = [UIView new];
    self.readOnlyCard.backgroundColor = kPACardBg;
    self.readOnlyCard.layer.cornerRadius = 12;
    self.readOnlyCard.layer.shadowColor = [UIColor blackColor].CGColor;
    self.readOnlyCard.layer.shadowOpacity = 0.08;
    self.readOnlyCard.layer.shadowOffset = CGSizeMake(0, 2);
    self.readOnlyCard.layer.shadowRadius = 10;
    [self.content addSubview:self.readOnlyCard];
    // 职业工作证卡片压在绿底与白底交界：顶部与 header 底重叠一截，形成「绿底底下、白底上边」的视觉效果
    [self.readOnlyCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView.mas_bottom).offset(-16);
        make.leading.equalTo(self.content).offset(12);
        make.trailing.equalTo(self.content).offset(-12);
    }];

    self.readOnlyTitleLabel = [UILabel new];
    self.readOnlyTitleLabel.text = NSLocalizedString(@"auth_work_cert_title", nil);
    self.readOnlyTitleLabel.font = [UIFont boldSystemFontOfSize:16];
    self.readOnlyTitleLabel.textColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
    [self.readOnlyCard addSubview:self.readOnlyTitleLabel];
    [self.readOnlyTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.equalTo(self.readOnlyCard).offset(20);
        make.trailing.lessThanOrEqualTo(self.readOnlyCard).offset(-20);
    }];

    self.readOnlyImageView = [UIImageView new];
    self.readOnlyImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.readOnlyImageView.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0];
    self.readOnlyImageView.layer.cornerRadius = 8;
    self.readOnlyImageView.clipsToBounds = YES;
    [self.readOnlyCard addSubview:self.readOnlyImageView];
    [self.readOnlyImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.readOnlyTitleLabel.mas_bottom).offset(12);
        make.leading.trailing.equalTo(self.readOnlyCard).inset(20);
        make.height.mas_equalTo(220);
        make.bottom.equalTo(self.readOnlyCard).offset(-20);
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
    cell.contentView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    cell.contentView.layer.cornerRadius = 12;
    cell.contentView.clipsToBounds = YES;

    if (indexPath.item < (NSInteger)self.uploadedImages.count) {
        UIImageView *iv = [UIImageView new];
        iv.contentMode = UIViewContentModeScaleAspectFill;
        iv.clipsToBounds = YES;
        iv.image = self.uploadedImages[indexPath.item];
        [cell.contentView addSubview:iv];
        [iv mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(cell.contentView);
        }];
    } else {
        UIView *circle = [UIView new];
        circle.backgroundColor = kPAButtonGreen;
        circle.layer.cornerRadius = 28;
        [cell.contentView addSubview:circle];
        [circle mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(cell.contentView);
            make.size.mas_equalTo(CGSizeMake(56, 56));
        }];
        UIImageView *cam = [UIImageView new];
        if (@available(iOS 13.0, *)) {
            cam.image = [UIImage systemImageNamed:@"camera.fill"];
            cam.tintColor = [UIColor whiteColor];
        }
        cam.contentMode = UIViewContentModeScaleAspectFit;
        [circle addSubview:cam];
        [cam mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(circle);
            make.size.mas_equalTo(CGSizeMake(24, 24));
        }];
    }
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat w = [UIScreen mainScreen].bounds.size.width - 12*2 - 20*2;
    CGFloat cellW = (w - 12) / 2.0;
    return CGSizeMake(cellW, cellW);
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
    if (self.uploadedImages.count == 0) {
        [self showError:NSLocalizedString(@"auth_please_upload_work_cert", nil)];
        return;
    }
    [AuthStateStore saveProfessionalImages:[self.uploadedImages copy]];
    [AuthStateStore setProfessionalAuthCompleted:YES];
    [self showSuccess:NSLocalizedString(@"auth_professional_success", nil)];
    __weak typeof(self) w = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [w refreshState];
    });
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
