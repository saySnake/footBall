//
//  PNAddConsumeViewController.m
//  footBall
//

#import "PNAddConsumeViewController.h"
#import "PNPickerSheetViewController.h"
#import <Masonry/Masonry.h>
#import "ColorManager.h"

// 统一使用 ColorManager 的主色（与 Figma #285D4B 一致）
#define kPNGreen [ColorManager sharedManager].primaryColor

/// Figma 1:12391 添加消费弹层 — 文本主色 #0D2122
static UIColor *kAddConsumeTextDark(void) {
    return [UIColor colorWithRed:0.051f green:0.129f blue:0.133f alpha:1.0f];
}
/// 输入区背景 #F6F6F6
static UIColor *kAddConsumeInputBg(void) {
    return [UIColor colorWithRed:0.965f green:0.965f blue:0.965f alpha:1.0f];
}
/// 占位符 #6F6F6F
static UIColor *kAddConsumePlaceholder(void) {
    return [UIColor colorWithRed:0.435f green:0.435f blue:0.435f alpha:1.0f];
}

static NSDecimalNumber *PNAddConsumeDecimalFromInput(NSString *raw) {
    NSString *s = [[raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
                   stringByReplacingOccurrencesOfString:@"," withString:@"."];
    return [NSDecimalNumber decimalNumberWithString:s locale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
}

@interface PNAddConsumeViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, strong) UIView *dimmingView;
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIButton *confirmButton;
@property (nonatomic, assign) BOOL submitting;
@property (nonatomic, assign) CGFloat cardDismissThreshold;
@property (nonatomic, assign) BOOL didPrepareInitialOffscreen;
@property (nonatomic, assign) BOOL didSchedulePresentAnimation;
@property (nonatomic, assign) BOOL didRunPresentAnimation;

@property (nonatomic, strong) UIImageView *photoPreview;
@property (nonatomic, strong) UIButton *photoBtn;
@property (nonatomic, strong) UIImage *selectedImage;
/// 图片选中后立即上传，成功后保存 objectKey，提交时直接使用
@property (nonatomic, copy, nullable) NSString *uploadedPhotoKey;
/// 图片正在上传中
@property (nonatomic, assign) BOOL photoUploading;
/// 选图/upload 代际，忽略过期的上传回调
@property (nonatomic, assign) NSInteger photoUploadGeneration;

@property (nonatomic, strong) UITextField *itemField;
@property (nonatomic, strong) UITextField *priceField;

@property (nonatomic, strong) UIButton *dateBtn;
@property (nonatomic, strong) UIButton *timeBtn;
@property (nonatomic, strong) NSDate *selectedDate;
@end

@implementation PNAddConsumeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    self.selectedDate = [NSDate date];

    UIView *dim = [[UIView alloc] init];
    dim.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    dim.alpha = 0.0;
    // alpha=0 时也必须不拦截触摸，否则会出现“卡片没弹出来但全屏点不了”
    dim.userInteractionEnabled = NO;
    [self.view addSubview:dim];
    self.dimmingView = dim;
    [dim mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self.view); }];
    UITapGestureRecognizer *bgTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDismiss)];
    bgTap.cancelsTouchesInView = YES;
    [dim addGestureRecognizer:bgTap];

    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [UIColor whiteColor];
    card.layer.cornerRadius = 24;
    card.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    card.layer.masksToBounds = YES;
    [self.view addSubview:card];
    self.cardView = card;
    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.view);
        make.trailing.equalTo(self.view);
        // 底部贴紧屏幕（与原型一致，底部距离为 0）
        make.bottom.equalTo(self.view);
    }];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onCardPan:)];
    pan.maximumNumberOfTouches = 1;
    [card addGestureRecognizer:pan];

    // 顶部拖拽条（Figma #D4D4D4，约 22% 屏宽）
    UIView *handle = [[UIView alloc] init];
    handle.backgroundColor = [UIColor colorWithRed:0.831f green:0.831f blue:0.831f alpha:1.0f];
    handle.layer.cornerRadius = 2;
    [card addSubview:handle];
    [handle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(card).offset(8);
        make.centerX.equalTo(card);
        make.width.equalTo(card).multipliedBy(0.22);
        make.height.mas_equalTo(4);
    }];

    UILabel *title = [[UILabel alloc] init];
    title.text = NSLocalizedString(@"add_consume_title", nil) ?: @"添加消费";
    title.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    title.textColor = kAddConsumeTextDark();
    title.textAlignment = NSTextAlignmentCenter;
    [card addSubview:title];
    [title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(card).offset(46);
        make.centerX.equalTo(card);
    }];

    UILabel *uploadLab = [[UILabel alloc] init];
    NSString *upMain = NSLocalizedString(@"add_consume_upload_photo_main", nil) ?: NSLocalizedString(@"add_consume_upload_photo", nil) ?: @"上传照片";
    NSString *upCount = NSLocalizedString(@"add_consume_upload_photo_count", nil) ?: @"（1张）";
    NSMutableAttributedString *uploadAttr = [[NSMutableAttributedString alloc] initWithString:upMain attributes:@{
        NSFontAttributeName: [UIFont systemFontOfSize:16 weight:UIFontWeightMedium],
        NSForegroundColorAttributeName: [UIColor blackColor],
    }];
    [uploadAttr appendAttributedString:[[NSAttributedString alloc] initWithString:upCount attributes:@{
        NSFontAttributeName: [UIFont systemFontOfSize:12 weight:UIFontWeightMedium],
        NSForegroundColorAttributeName: [UIColor blackColor],
    }]];
    uploadLab.attributedText = uploadAttr;
    [card addSubview:uploadLab];
    [uploadLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(title.mas_bottom).offset(19);
        make.leading.equalTo(card).offset(16);
    }];

    UIView *photoBox = [[UIView alloc] init];
    photoBox.backgroundColor = kAddConsumeInputBg();
    photoBox.layer.cornerRadius = 8;
    photoBox.layer.masksToBounds = YES;
    [card addSubview:photoBox];
    [photoBox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(uploadLab.mas_bottom).offset(12);
        make.leading.equalTo(card).offset(16);
        make.width.height.mas_equalTo(107);
    }];

    UIImageView *preview = [[UIImageView alloc] init];
    preview.contentMode = UIViewContentModeScaleAspectFill;
    preview.clipsToBounds = YES;
    [photoBox addSubview:preview];
    self.photoPreview = preview;
    [preview mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(photoBox); }];

    UIButton *photoBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *symCfg = [UIImageSymbolConfiguration configurationWithPointSize:28 weight:UIImageSymbolWeightThin];
        UIImage *plusImg = [UIImage systemImageNamed:@"plus" withConfiguration:symCfg];
        [photoBtn setImage:plusImg forState:UIControlStateNormal];
        photoBtn.tintColor = [UIColor colorWithRed:0.635f green:0.635f blue:0.635f alpha:1.0f];
    } else {
        [photoBtn setTitle:@"+" forState:UIControlStateNormal];
    }
    [photoBtn addTarget:self action:@selector(onPickPhoto) forControlEvents:UIControlEventTouchUpInside];
    [photoBox addSubview:photoBtn];
    self.photoBtn = photoBtn;
    [photoBtn mas_makeConstraints:^(MASConstraintMaker *make) { make.center.equalTo(photoBox); }];

    // 消费物品（Figma 标签 14 Medium #0D2122）
    UILabel *itemLab = [[UILabel alloc] init];
    itemLab.text = NSLocalizedString(@"add_consume_item", nil) ?: @"消费物品";
    itemLab.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    itemLab.textColor = kAddConsumeTextDark();
    [card addSubview:itemLab];
    [itemLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(photoBox.mas_bottom).offset(16);
        make.leading.equalTo(card).offset(16);
    }];

    UITextField *item = [[UITextField alloc] init];
    item.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    item.textColor = kAddConsumeTextDark();
    item.attributedPlaceholder = [[NSAttributedString alloc] initWithString:(NSLocalizedString(@"add_consume_item_placeholder", nil) ?: @"请输入消费物品") attributes:@{
        NSForegroundColorAttributeName: kAddConsumePlaceholder(),
        NSFontAttributeName: [UIFont systemFontOfSize:14 weight:UIFontWeightMedium],
    }];
    item.layer.cornerRadius = 8;
    item.layer.borderWidth = 0;
    item.borderStyle = UITextBorderStyleNone;
    item.backgroundColor = kAddConsumeInputBg();
    item.clearButtonMode = UITextFieldViewModeWhileEditing;
    item.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 19, 1)];
    item.leftViewMode = UITextFieldViewModeAlways;
    [card addSubview:item];
    self.itemField = item;
    [item mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(itemLab.mas_bottom).offset(8);
        make.leading.equalTo(card).offset(16);
        make.trailing.equalTo(card).offset(-16);
        make.height.mas_equalTo(50);
    }];

    // 消费价格
    UILabel *priceLab = [[UILabel alloc] init];
    priceLab.text = NSLocalizedString(@"add_consume_price", nil) ?: @"消费价格";
    priceLab.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    priceLab.textColor = kAddConsumeTextDark();
    [card addSubview:priceLab];
    [priceLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(item.mas_bottom).offset(16);
        make.leading.equalTo(card).offset(16);
    }];

    UITextField *price = [[UITextField alloc] init];
    price.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    price.textColor = kAddConsumeTextDark();
    price.attributedPlaceholder = [[NSAttributedString alloc] initWithString:(NSLocalizedString(@"add_consume_price_placeholder", nil) ?: @"请输入价格") attributes:@{
        NSForegroundColorAttributeName: kAddConsumePlaceholder(),
        NSFontAttributeName: [UIFont systemFontOfSize:14 weight:UIFontWeightMedium],
    }];
    price.layer.cornerRadius = 8;
    price.backgroundColor = kAddConsumeInputBg();
    price.borderStyle = UITextBorderStyleNone;
    price.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 19, 1)];
    price.leftViewMode = UITextFieldViewModeAlways;
    price.keyboardType = UIKeyboardTypeDecimalPad;
    [card addSubview:price];
    self.priceField = price;
    [price mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(priceLab.mas_bottom).offset(8);
        make.leading.trailing.height.equalTo(item);
    }];

    // 日期 & 时间（两列各 166pt、间距 11pt，375 设计稿）
    UILabel *dateLab = [[UILabel alloc] init];
    dateLab.text = NSLocalizedString(@"add_consume_date", nil) ?: @"消费日期";
    dateLab.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    dateLab.textColor = kAddConsumeTextDark();
    [card addSubview:dateLab];
    [dateLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(price.mas_bottom).offset(16);
        make.leading.equalTo(card).offset(16);
    }];

    UILabel *timeLab = [[UILabel alloc] init];
    timeLab.text = NSLocalizedString(@"add_consume_time", nil) ?: @"时间";
    timeLab.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    timeLab.textColor = kAddConsumeTextDark();
    [card addSubview:timeLab];
    [timeLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(dateLab);
        make.leading.equalTo(card.mas_centerX).offset(8.5);
    }];

    UIButton* (^fieldBtn)(void) = ^UIButton*{
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
        b.backgroundColor = kAddConsumeInputBg();
        b.layer.cornerRadius = 8;
        b.clipsToBounds = YES;
        b.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeading;
        b.titleEdgeInsets = UIEdgeInsetsMake(0, 14, 0, 8);
        [b setTitleColor:kAddConsumeTextDark() forState:UIControlStateNormal];
        b.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        return b;
    };
    _dateBtn = fieldBtn();
    _timeBtn = fieldBtn();
    [_dateBtn addTarget:self action:@selector(onPickDate) forControlEvents:UIControlEventTouchUpInside];
    [_timeBtn addTarget:self action:@selector(onPickTime) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:_dateBtn];
    [card addSubview:_timeBtn];
    [_dateBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(dateLab.mas_bottom).offset(8);
        make.leading.equalTo(card).offset(16);
        make.trailing.equalTo(card.mas_centerX).offset(-5.5);
        make.height.mas_equalTo(50);
    }];
    [_timeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_dateBtn);
        make.leading.equalTo(card.mas_centerX).offset(5.5);
        make.trailing.equalTo(card).offset(-16);
        make.height.equalTo(_dateBtn);
    }];

    UIButton *confirm = [UIButton buttonWithType:UIButtonTypeCustom];
    [confirm setTitle:NSLocalizedString(@"add_consume_confirm", nil) ?: @"确认" forState:UIControlStateNormal];
    confirm.backgroundColor = kPNGreen;
    [confirm setTitleColor:[UIColor colorWithRed:0.937f green:0.941f blue:0.957f alpha:1.0f] forState:UIControlStateNormal];
    [confirm setTitleColor:[[UIColor colorWithRed:0.937f green:0.941f blue:0.957f alpha:1.0f] colorWithAlphaComponent:0.35f] forState:UIControlStateDisabled];
    confirm.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    confirm.layer.cornerRadius = 26;
    confirm.clipsToBounds = YES;
    [confirm addTarget:self action:@selector(onConfirm) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:confirm];
    self.confirmButton = confirm;
    [confirm mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_dateBtn.mas_bottom).offset(24);
        make.leading.equalTo(card).offset(16);
        make.trailing.equalTo(card).offset(-16);
        make.height.mas_equalTo(52);
        make.bottom.equalTo(card.mas_safeAreaLayoutGuideBottom).offset(-16);
    }];

    [self refreshDateTimeButtons];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.didRunPresentAnimation) {
        return;
    }
    if (!self.cardView || !self.dimmingView) {
        return;
    }
    // 第一次 layout 完成后再把卡片放到屏幕外，避免首帧“先出现再跳”的闪烁。
    if (!self.didPrepareInitialOffscreen) {
        self.didPrepareInitialOffscreen = YES;
        [self.view layoutIfNeeded];
        CGFloat h = CGRectGetHeight(self.cardView.bounds);
        if (h < 1) {
            h = 520;
        }
        self.cardView.transform = CGAffineTransformMakeTranslation(0, h + 40);
        self.dimmingView.alpha = 0.0;
        self.dimmingView.userInteractionEnabled = NO;

        // 不依赖“第二次 layout”：下一轮 runloop 直接播放入场动画
        __weak typeof(self) weakSelf = self;
        if (self.didSchedulePresentAnimation) {
            return;
        }
        self.didSchedulePresentAnimation = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self || self.didRunPresentAnimation) {
                return;
            }
            self.didRunPresentAnimation = YES;
            [UIView animateWithDuration:0.26
                                  delay:0
                 usingSpringWithDamping:0.9
                  initialSpringVelocity:0.6
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                self.cardView.transform = CGAffineTransformIdentity;
                self.dimmingView.alpha = 1.0;
            } completion:^(BOOL finished) {
                self.dimmingView.userInteractionEnabled = YES;
            }];
        });
        return;
    }
}

- (void)refreshDateTimeButtons {
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    cal.timeZone = [NSTimeZone localTimeZone];
    NSDateComponents *c = [cal components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute fromDate:self.selectedDate ?: [NSDate date]];
    NSString *dateStr = [NSString stringWithFormat:@"%ld年%02ld月%02ld日", (long)c.year, (long)c.month, (long)c.day];
    NSString *timeStr = [NSString stringWithFormat:@"%02ld:%02ld", (long)c.hour, (long)c.minute];
    [_dateBtn setTitle:dateStr forState:UIControlStateNormal];
    [_timeBtn setTitle:timeStr forState:UIControlStateNormal];
}

- (void)onDismiss {
    [self dismissWithCardAnimation];
}

- (void)dismissWithCardAnimation {
    UIView *card = self.cardView;
    if (!card) {
        [self dismissViewControllerAnimated:NO completion:nil];
        return;
    }
    self.dimmingView.userInteractionEnabled = NO;
    [self.view layoutIfNeeded];
    CGFloat h = CGRectGetHeight(card.bounds);
    if (h < 1) {
        h = 520;
    }
    [UIView animateWithDuration:0.18 animations:^{
        card.transform = CGAffineTransformMakeTranslation(0, h + 40);
        self.dimmingView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }];
}

- (void)onCardPan:(UIPanGestureRecognizer *)gr {
    UIView *card = self.cardView;
    if (!card) { return; }

    CGPoint t = [gr translationInView:self.view];
    CGFloat dy = MAX(0, t.y); // 只允许向下拖动

    if (gr.state == UIGestureRecognizerStateBegan) {
        [self.view layoutIfNeeded];
        CGFloat h = CGRectGetHeight(card.bounds);
        if (h < 1) {
            h = 520;
        }
        self.cardDismissThreshold = h / 3.0;
    }

    if (gr.state == UIGestureRecognizerStateChanged) {
        card.transform = CGAffineTransformMakeTranslation(0, dy);
        CGFloat baseAlpha = 0.5;
        CGFloat p = self.cardDismissThreshold > 0 ? MIN(1, dy / self.cardDismissThreshold) : 0;
        CGFloat a = baseAlpha * (1 - 0.9 * p);
        self.dimmingView.alpha = a;
        self.dimmingView.userInteractionEnabled = (a > 0.02);
        return;
    }

    if (gr.state == UIGestureRecognizerStateEnded || gr.state == UIGestureRecognizerStateCancelled) {
        BOOL shouldDismiss = (dy > self.cardDismissThreshold);
        if (shouldDismiss) {
            [self dismissWithCardAnimation];
        } else {
            [UIView animateWithDuration:0.22
                                  delay:0
                 usingSpringWithDamping:0.92
                  initialSpringVelocity:0.0
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                card.transform = CGAffineTransformIdentity;
                self.dimmingView.alpha = 1.0;
            } completion:^(BOOL finished) {
                self.dimmingView.userInteractionEnabled = YES;
            }];
        }
    }
}

- (void)onPickPhoto {
    // 只允许 1 张：已有则替换
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    picker.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    UIImage *img = info[UIImagePickerControllerOriginalImage];
    self.selectedImage = img;
    self.photoPreview.image = img;
    self.photoBtn.hidden = (img != nil);
    self.uploadedPhotoKey = nil;
    [picker dismissViewControllerAnimated:YES completion:nil];

    // 选图后立即上传，保存 objectKey，提交时直接使用，避免提交时重复上传
    NSData *imgData = UIImageJPEGRepresentation(img, 0.85);
    if (!imgData) imgData = UIImagePNGRepresentation(img);
    if (!imgData) return;

    self.photoUploading = YES;
    NSInteger uploadToken = ++self.photoUploadGeneration;
    __weak typeof(self) weakSelf = self;
    [FileRequest.shared uploadImage:imgData type:ImageObjectTypeConsumption success:^(HTTPResponse * _Nullable responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self || uploadToken != self.photoUploadGeneration) return;
            self.photoUploading = NO;
            NSString *key = [responseObject.dataObject isKindOfClass:[NSString class]] ? responseObject.dataObject : nil;
            self.uploadedPhotoKey = key;
        });
    } failure:^(NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self || uploadToken != self.photoUploadGeneration) return;
            self.photoUploading = NO;
            self.uploadedPhotoKey = nil;
            // 上传失败，清除已选图片，提示用户重新选择
            self.selectedImage = nil;
            self.photoPreview.image = nil;
            self.photoBtn.hidden = NO;
            [[LoadingManager sharedManager] showError:(NSLocalizedString(@"add_consume_upload_fail", nil) ?: @"图片上传失败，请重新选择") inView:self.view];
        });
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)onPickDate {
    PNPickerSheetViewController *sheet = [PNPickerSheetViewController new];
    sheet.mode = PNPickerSheetModeDate;
    sheet.selectedDate = self.selectedDate;
    sheet.modalPresentationStyle = UIModalPresentationOverFullScreen;
    __weak typeof(self) weakSelf = self;
    sheet.onConfirm = ^(NSDate *date) {
        weakSelf.selectedDate = date;
        [weakSelf refreshDateTimeButtons];
    };
    // 取消底部阴影渐变动画，直接显示
    [self presentViewController:sheet animated:NO completion:nil];
}

- (void)onPickTime {
    PNPickerSheetViewController *sheet = [PNPickerSheetViewController new];
    sheet.mode = PNPickerSheetModeTime;
    sheet.selectedDate = self.selectedDate;
    sheet.modalPresentationStyle = UIModalPresentationOverFullScreen;
    __weak typeof(self) weakSelf = self;
    sheet.onConfirm = ^(NSDate *date) {
        weakSelf.selectedDate = date;
        [weakSelf refreshDateTimeButtons];
    };
    // 取消底部阴影渐变动画，直接显示
    [self presentViewController:sheet animated:NO completion:nil];
}

- (NSString *)expenseDateStringForAPI {
    NSDate *d = self.selectedDate ?: [NSDate date];
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    // 上送后端的固定格式串必须用 en_US_POSIX（QA1480），用 currentLocale 会在
    // ar/th 等区域下输出非阿拉伯数字，后端解析失败
    fmt.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    fmt.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    fmt.timeZone = [NSTimeZone localTimeZone];
    // 服务端 expenseDate 是 LocalDate，只接受 yyyy-MM-dd 格式
    fmt.dateFormat = @"yyyy-MM-dd";
    return [fmt stringFromDate:d];
}

- (void)resetSubmittingState {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.submitting = NO;
    self.confirmButton.enabled = YES;
}

- (void)postCreateExpenseWithBody:(NSDictionary *)body {
    __weak typeof(self) weakSelf = self;
    [[ExpenseRequest shared] createExpenseWithBody:body success:^(HTTPResponse * _Nullable responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            [self resetSubmittingState];
            NSString *ok = NSLocalizedString(@"add_consume_success", nil) ?: @"添加成功";
            [[LoadingManager sharedManager] showText:ok];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"PNExpenseDidCreate" object:nil];
            [self dismissViewControllerAnimated:YES completion:nil];
        });
    } failure:^(NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            [self resetSubmittingState];
            NSString *msg = error.localizedDescription ?: @"";
            if ([error isKindOfClass:[APIError class]]) {
                APIError *ae = (APIError *)error;
                if (ae.businessMessage.length) msg = ae.businessMessage;
            }
            if (msg.length == 0) msg = NSLocalizedString(@"add_consume_fail", nil) ?: @"添加失败";
            [[LoadingManager sharedManager] showError:msg inView:self.view];
        });
    }];
}

- (void)onConfirm {
    [self.view endEditing:YES];
    if (self.submitting) return;

    if (!AuthManager.sharedManager.isLoggedIn) {
        NSString *msg = NSLocalizedString(@"add_consume_error_login", nil) ?: @"请先登录";
        [[LoadingManager sharedManager] showError:msg inView:self.view];
        return;
    }

    NSString *itemName = [self.itemField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (itemName.length == 0) {
        NSString *msg = NSLocalizedString(@"add_consume_error_item", nil) ?: @"请输入消费物品";
        [[LoadingManager sharedManager] showError:msg inView:self.view];
        return;
    }

    NSString *priceStr = [self.priceField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (priceStr.length == 0) {
        NSString *msg = NSLocalizedString(@"add_consume_error_price", nil) ?: @"请输入价格";
        [[LoadingManager sharedManager] showError:msg inView:self.view];
        return;
    }

    NSDecimalNumber *amount = PNAddConsumeDecimalFromInput(priceStr);
    if ([amount isEqualToNumber:[NSDecimalNumber notANumber]] || [amount compare:[NSDecimalNumber zero]] != NSOrderedDescending) {
        NSString *msg = NSLocalizedString(@"add_consume_error_price_invalid", nil) ?: @"请输入有效金额";
        [[LoadingManager sharedManager] showError:msg inView:self.view];
        return;
    }

    self.submitting = YES;
    self.confirmButton.enabled = NO;
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];

    NSString *dateStr = [self expenseDateStringForAPI];
    __weak typeof(self) weakSelf = self;

    void (^sendBody)(NSArray<NSString *> *) = ^(NSArray<NSString *> *photoURLs) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        NSMutableDictionary *body = [NSMutableDictionary dictionary];
        body[@"itemName"] = itemName;
        // amount 必须传数字类型，不能传字符串，否则服务端 BigDecimal 反序列化失败
        body[@"amount"] = amount;
        body[@"expenseDate"] = dateStr;
        if (photoURLs.count > 0) {
            body[@"photos"] = photoURLs;
        }
        [self postCreateExpenseWithBody:body];
    };

    // 有选图但还在上传中，等待上传完成
    if (self.selectedImage && self.photoUploading) {
        [self resetSubmittingState];
        [[LoadingManager sharedManager] showError:(NSLocalizedString(@"add_consume_photo_uploading", nil) ?: @"图片上传中，请稍候再提交") inView:self.view];
        return;
    }

    // 有选图且上传成功，直接用已上传的 key
    if (self.selectedImage && self.uploadedPhotoKey.length > 0) {
        sendBody(@[self.uploadedPhotoKey]);
        return;
    }

    // 有选图但上传失败（key 为空），提示重新选图
    if (self.selectedImage && self.uploadedPhotoKey.length == 0) {
        [self resetSubmittingState];
        [[LoadingManager sharedManager] showError:(NSLocalizedString(@"add_consume_upload_fail", nil) ?: @"图片上传失败，请重新选择") inView:self.view];
        return;
    }

    // 没有选图，直接提交
    sendBody(@[]);
}

@end

