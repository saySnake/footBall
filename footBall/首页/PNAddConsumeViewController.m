//
//  PNAddConsumeViewController.m
//  footBall
//

#import "PNAddConsumeViewController.h"
#import "PNPickerSheetViewController.h"
#import <Masonry/Masonry.h>
#import "ColorManager.h"

// 统一使用 ColorManager 的主色，方便主题切换
#define kPNGreen [ColorManager sharedManager].primaryColor

@interface PNAddConsumeViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate>
@property (nonatomic, strong) UIView *dimmingView;
@property (nonatomic, strong) UIView *cardView;

@property (nonatomic, strong) UIImageView *photoPreview;
@property (nonatomic, strong) UIButton *photoBtn;
@property (nonatomic, strong) UIImage *selectedImage;

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
    dim.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.35];
    [self.view addSubview:dim];
    self.dimmingView = dim;
    [dim mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self.view); }];
    [dim addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDismiss)]];

    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [UIColor whiteColor];
    card.layer.cornerRadius = 18;
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

    // 顶部拖拽条
    UIView *handle = [[UIView alloc] init];
    handle.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1.0];
    handle.layer.cornerRadius = 2;
    [card addSubview:handle];
    [handle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(card).offset(8);
        make.centerX.equalTo(card);
        make.width.mas_equalTo(40);
        make.height.mas_equalTo(4);
    }];

    UILabel *title = [[UILabel alloc] init];
    title.text = NSLocalizedString(@"add_consume_title", nil) ?: @"添加消费";
    title.font = [UIFont boldSystemFontOfSize:18];
    title.textAlignment = NSTextAlignmentCenter;
    [card addSubview:title];
    [title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(handle.mas_bottom).offset(10);
        make.centerX.equalTo(card);
    }];

    UILabel *uploadLab = [[UILabel alloc] init];
    uploadLab.text = NSLocalizedString(@"add_consume_upload_photo", nil) ?: @"上传照片";
    uploadLab.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    uploadLab.textColor = [UIColor blackColor];
    [card addSubview:uploadLab];
    [uploadLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(title.mas_bottom).offset(18);
        make.leading.equalTo(card).offset(18);
    }];

    UILabel *countLab = [[UILabel alloc] init];
    countLab.text = @"(1张)";
    countLab.font = [UIFont systemFontOfSize:12];
    countLab.textColor = [UIColor lightGrayColor];
    [card addSubview:countLab];
    [countLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(uploadLab);
        make.leading.equalTo(uploadLab.mas_trailing).offset(4);
    }];

    UIView *photoBox = [[UIView alloc] init];
    photoBox.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    photoBox.layer.cornerRadius = 10;
    photoBox.layer.masksToBounds = YES;
    [card addSubview:photoBox];
    [photoBox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(uploadLab.mas_bottom).offset(10);
        make.leading.equalTo(card).offset(18);
        make.width.height.mas_equalTo(76);
    }];

    UIImageView *preview = [[UIImageView alloc] init];
    preview.contentMode = UIViewContentModeScaleAspectFill;
    preview.clipsToBounds = YES;
    [photoBox addSubview:preview];
    self.photoPreview = preview;
    [preview mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(photoBox); }];

    UIButton *photoBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    if (@available(iOS 13.0, *)) {
        [photoBtn setImage:[UIImage systemImageNamed:@"plus"] forState:UIControlStateNormal];
        photoBtn.tintColor = [UIColor lightGrayColor];
    } else {
        [photoBtn setTitle:@"+" forState:UIControlStateNormal];
    }
    [photoBtn addTarget:self action:@selector(onPickPhoto) forControlEvents:UIControlEventTouchUpInside];
    [photoBox addSubview:photoBtn];
    self.photoBtn = photoBtn;
    [photoBtn mas_makeConstraints:^(MASConstraintMaker *make) { make.center.equalTo(photoBox); }];

    // 消费物品
    UILabel *itemLab = [[UILabel alloc] init];
    itemLab.text = NSLocalizedString(@"add_consume_item", nil) ?: @"消费物品";
    itemLab.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    [card addSubview:itemLab];
    [itemLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(photoBox.mas_bottom).offset(16);
        make.leading.equalTo(card).offset(18);
    }];

    UITextField *item = [[UITextField alloc] init];
    item.placeholder = NSLocalizedString(@"add_consume_item_placeholder", nil) ?: @"请输入消费物品";
    item.font = [UIFont systemFontOfSize:14];
    // 初始与价格框一样（浅灰底无边框），获得焦点时再高亮为蓝边
    item.layer.cornerRadius = 8;
    item.layer.borderWidth = 0;
    item.borderStyle = UITextBorderStyleNone;
    item.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    item.clearButtonMode = UITextFieldViewModeWhileEditing;
    item.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 1)];
    item.leftViewMode = UITextFieldViewModeAlways;
    item.delegate = self;
    [card addSubview:item];
    self.itemField = item;
    [item mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(itemLab.mas_bottom).offset(8);
        make.leading.equalTo(card).offset(18);
        make.trailing.equalTo(card).offset(-18);
        make.height.mas_equalTo(44);
    }];

    // 消费价格
    UILabel *priceLab = [[UILabel alloc] init];
    priceLab.text = NSLocalizedString(@"add_consume_price", nil) ?: @"消费价格";
    priceLab.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    [card addSubview:priceLab];
    [priceLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(item.mas_bottom).offset(14);
        make.leading.equalTo(card).offset(18);
    }];

    UITextField *price = [[UITextField alloc] init];
    price.placeholder = NSLocalizedString(@"add_consume_price_placeholder", nil) ?: @"请输入价格";
    price.font = [UIFont systemFontOfSize:14];
    price.layer.cornerRadius = 8;
    price.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    price.borderStyle = UITextBorderStyleNone;
    price.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 1)];
    price.leftViewMode = UITextFieldViewModeAlways;
    price.keyboardType = UIKeyboardTypeDecimalPad;
    price.delegate = self;
    [card addSubview:price];
    self.priceField = price;
    [price mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(priceLab.mas_bottom).offset(8);
        make.leading.trailing.height.equalTo(item);
    }];

    // 日期 & 时间
    UILabel *dateLab = [[UILabel alloc] init];
    dateLab.text = NSLocalizedString(@"add_consume_date", nil) ?: @"消费日期";
    dateLab.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    [card addSubview:dateLab];
    [dateLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(price.mas_bottom).offset(14);
        make.leading.equalTo(card).offset(18);
    }];

    UILabel *timeLab = [[UILabel alloc] init];
    timeLab.text = NSLocalizedString(@"add_consume_time", nil) ?: @"时间";
    timeLab.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    [card addSubview:timeLab];
    [timeLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(dateLab);
        make.leading.equalTo(card.mas_centerX).offset(10);
    }];

    UIButton* (^fieldBtn)(void) = ^UIButton*{
        UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
        b.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
        b.layer.cornerRadius = 8;
        [b setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        b.titleLabel.font = [UIFont systemFontOfSize:14];
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
        make.leading.equalTo(card).offset(18);
        make.trailing.equalTo(card.mas_centerX).offset(-8);
        make.height.mas_equalTo(44);
    }];
    [_timeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_dateBtn);
        make.leading.equalTo(card.mas_centerX).offset(8);
        make.trailing.equalTo(card).offset(-18);
        make.height.equalTo(_dateBtn);
    }];

    UIButton *confirm = [UIButton buttonWithType:UIButtonTypeSystem];
    [confirm setTitle:NSLocalizedString(@"add_consume_confirm", nil) ?: @"确认" forState:UIControlStateNormal];
    confirm.backgroundColor = kPNGreen;
    [confirm setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    confirm.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    confirm.layer.cornerRadius = 22;
    [confirm addTarget:self action:@selector(onConfirm) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:confirm];
    [confirm mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_dateBtn.mas_bottom).offset(18);
        make.leading.equalTo(card).offset(18);
        make.trailing.equalTo(card).offset(-18);
        make.height.mas_equalTo(46);
        make.bottom.equalTo(card.mas_safeAreaLayoutGuideBottom).offset(-10);
    }];

    [self refreshDateTimeButtons];
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
    [self dismissViewControllerAnimated:YES completion:nil];
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
    [picker dismissViewControllerAnimated:YES completion:nil];
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

- (void)onConfirm {
    // 假提交：直接关闭
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == self.itemField) {
        // 消费物品获得焦点时显示蓝色描边，贴合设计图
        textField.layer.borderWidth = 2;
        textField.layer.borderColor = [UIColor colorWithRed:0.16 green:0.55 blue:0.95 alpha:1.0].CGColor;
        textField.backgroundColor = [UIColor whiteColor];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == self.itemField) {
        // 失焦后恢复为浅灰底、无边框
        textField.layer.borderWidth = 0;
        textField.layer.borderColor = [UIColor clearColor].CGColor;
        textField.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    }
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    // 再保险：在将要编辑时也打一遍样式，避免某些机型 delegate 顺序差异
    if (textField == self.itemField) {
        textField.layer.borderWidth = 2;
        textField.layer.borderColor = [UIColor colorWithRed:0.16 green:0.55 blue:0.95 alpha:1.0].CGColor;
        textField.backgroundColor = [UIColor whiteColor];
    }
    return YES;
}

@end

