//
//  PNMatchVerifyViewController.m
//  footBall
//

#import "PNMatchVerifyViewController.h"
#import <Masonry/Masonry.h>
#import <CoreLocation/CoreLocation.h>

static NSString * const kPNMatchVerifyPhotoCellId = @"PNMatchVerifyPhotoCell";

@interface PNMatchVerifyPhotoCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIButton *deleteButton;
@end

@implementation PNMatchVerifyPhotoCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.contentView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
        self.contentView.layer.cornerRadius = 10;
        // 不裁剪子视图，方便右上角删除按钮略微溢出显示，贴合设计图
        self.contentView.clipsToBounds = NO;

        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        [self.contentView addSubview:_imageView];
        [_imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView);
        }];

        _deleteButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _deleteButton.backgroundColor = [UIColor colorWithRed:0.90 green:0.25 blue:0.25 alpha:1.0];
        _deleteButton.tintColor = [UIColor whiteColor];
        _deleteButton.layer.cornerRadius = 10;
        _deleteButton.clipsToBounds = YES;
        [_deleteButton setTitle:@"✕" forState:UIControlStateNormal];
        _deleteButton.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
        [self.contentView addSubview:_deleteButton];
        [_deleteButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView).offset(-4);
            make.trailing.equalTo(self.contentView).offset(4);
            make.width.height.mas_equalTo(20);
        }];
    }
    return self;
}

@end

@interface PNMatchVerifyViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate>

@property (nonatomic, strong) UIView *dimmingView;
@property (nonatomic, strong) UIView *cardView;

@property (nonatomic, assign) CGFloat cardDismissThreshold;
@property (nonatomic, assign) BOOL didPrepareInitialOffscreen;
@property (nonatomic, assign) BOOL didSchedulePresentAnimation;
@property (nonatomic, assign) BOOL didRunPresentAnimation;

@property (nonatomic, strong) UILabel *uploadCountLabel;
@property (nonatomic, strong) UICollectionView *photoCollectionView;
@property (nonatomic, strong) NSMutableArray<UIImage *> *photos;

@property (nonatomic, strong) UILabel *locationLabel;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, copy) NSString *currentAddress;
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

@property (nonatomic, strong) UIButton *confirmButton;

@end

@implementation PNMatchVerifyViewController

static CGFloat PNMatchVerifyDimBaseAlpha(void) {
    return 0.35;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    self.photos = [NSMutableArray array];

    [self buildUI];
    [self startLocate];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.didRunPresentAnimation) {
        return;
    }
    if (!self.cardView || !self.dimmingView) {
        return;
    }

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
                self.dimmingView.alpha = PNMatchVerifyDimBaseAlpha();
            } completion:^(BOOL finished) {
                self.dimmingView.userInteractionEnabled = YES;
            }];
        });
        return;
    }
}

- (void)dealloc {
    _locationManager.delegate = nil;
}

- (void)buildUI {
    UIView *dim = [[UIView alloc] init];
    dim.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.35];
    dim.alpha = 0.0;
    dim.userInteractionEnabled = NO;
    [self.view addSubview:dim];
    self.dimmingView = dim;
    [dim mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [UIColor whiteColor];
    card.layer.cornerRadius = 18;
    card.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    card.layer.masksToBounds = YES;
    [self.view addSubview:card];
    self.cardView = card;
    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onCardPan:)];
    pan.maximumNumberOfTouches = 1;
    [card addGestureRecognizer:pan];

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
    title.text = @"认证比赛";
    title.font = [UIFont boldSystemFontOfSize:18];
    title.textAlignment = NSTextAlignmentCenter;
    [card addSubview:title];
    [title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(handle.mas_bottom).offset(12);
        make.centerX.equalTo(card);
    }];

    UILabel *uploadLabel = [[UILabel alloc] init];
    uploadLabel.text = @"上传照片认证";
    uploadLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    uploadLabel.textColor = [UIColor blackColor];
    [card addSubview:uploadLabel];
    [uploadLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(title.mas_bottom).offset(18);
        make.leading.equalTo(card).offset(18);
    }];

    UILabel *countLabel = [[UILabel alloc] init];
    countLabel.font = [UIFont systemFontOfSize:12];
    countLabel.textColor = [UIColor lightGrayColor];
    [card addSubview:countLabel];
    self.uploadCountLabel = countLabel;
    [countLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(uploadLabel);
        make.leading.equalTo(uploadLabel.mas_trailing).offset(4);
    }];

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(72, 72);
    layout.minimumInteritemSpacing = 12;
    layout.minimumLineSpacing = 12;
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.sectionInset = UIEdgeInsetsMake(0, 18, 0, 18);

    UICollectionView *collection = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    collection.backgroundColor = [UIColor clearColor];
    collection.dataSource = self;
    collection.delegate = self;
    [collection registerClass:[PNMatchVerifyPhotoCell class] forCellWithReuseIdentifier:kPNMatchVerifyPhotoCellId];
    [card addSubview:collection];
    self.photoCollectionView = collection;
    [collection mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(uploadLabel.mas_bottom).offset(12);
        make.leading.trailing.equalTo(card);
        make.height.mas_equalTo(80);
    }];

    UILabel *locTitle = [[UILabel alloc] init];
    locTitle.text = @"添加定位";
    locTitle.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    locTitle.textColor = [UIColor blackColor];
    [card addSubview:locTitle];
    [locTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(collection.mas_bottom).offset(20);
        make.leading.equalTo(card).offset(18);
    }];

    UIView *locBox = [[UIView alloc] init];
    // 按设计图：根据文字自适应宽度的浅灰色圆角条
    locBox.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    locBox.layer.cornerRadius = 16; // 高度的一半，形成圆弧
    [card addSubview:locBox];
    [locBox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(locTitle.mas_bottom).offset(8);
        make.leading.equalTo(card).offset(18);
        // 宽度由内部图标+文字内容撑开，最多不超过整体左右 18 间距
        make.trailing.lessThanOrEqualTo(card).offset(-18);
        make.height.mas_equalTo(32);
    }];

    UIImageView *locIcon = [[UIImageView alloc] init];
    if (@available(iOS 13.0, *)) {
        locIcon.image = [UIImage systemImageNamed:@"mappin.and.ellipse"];
        locIcon.tintColor = [UIColor colorWithRed:0.10 green:0.36 blue:0.28 alpha:1.0];
    }
    locIcon.contentMode = UIViewContentModeScaleAspectFit;
    [locBox addSubview:locIcon];
    [locIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(locBox).offset(12);
        make.centerY.equalTo(locBox);
        make.width.height.mas_equalTo(18);
    }];

    UILabel *locLabel = [[UILabel alloc] init];
    locLabel.font = [UIFont systemFontOfSize:14];
    locLabel.textColor = [UIColor darkGrayColor];
    locLabel.text = @"定位中...";
    [locBox addSubview:locLabel];
    self.locationLabel = locLabel;
    [locLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(locIcon.mas_trailing).offset(6);
        make.centerY.equalTo(locBox);
        make.trailing.lessThanOrEqualTo(locBox).offset(-12);
    }];

    UIButton *confirm = [UIButton buttonWithType:UIButtonTypeSystem];
    [confirm setTitle:@"确认" forState:UIControlStateNormal];
    // 使用 ColorManager 主色
    confirm.backgroundColor = [ColorManager sharedManager].primaryColor;
    [confirm setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    confirm.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    confirm.layer.cornerRadius = 26;
    [confirm addTarget:self action:@selector(onConfirm) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:confirm];
    self.confirmButton = confirm;
    [confirm mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(locBox.mas_bottom).offset(24);
        make.leading.equalTo(card).offset(18);
        make.trailing.equalTo(card).offset(-18);
        make.height.mas_equalTo(52);
        make.bottom.equalTo(card.mas_safeAreaLayoutGuideBottom).offset(-16);
    }];

    [self updateUploadCountLabel];
    [self updateConfirmButtonState];
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
        h = 600;
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
    if (!card) {
        return;
    }
    CGPoint t = [gr translationInView:self.view];
    CGFloat dy = MAX(0, t.y); // 仅向下拖动

    if (gr.state == UIGestureRecognizerStateBegan) {
        CGFloat h = CGRectGetHeight(card.bounds);
        if (h < 1) {
            [card layoutIfNeeded];
            h = CGRectGetHeight(card.bounds);
        }
        if (h < 1) {
            h = 300;
        }
        self.cardDismissThreshold = h / 3.0;
    }

    if (gr.state == UIGestureRecognizerStateChanged) {
        card.transform = CGAffineTransformMakeTranslation(0, dy);
        CGFloat baseAlpha = PNMatchVerifyDimBaseAlpha();
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
            [UIView animateWithDuration:0.2
                                  delay:0
                 usingSpringWithDamping:0.9
                  initialSpringVelocity:0
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                card.transform = CGAffineTransformIdentity;
                self.dimmingView.alpha = PNMatchVerifyDimBaseAlpha();
            } completion:^(BOOL finished) {
                self.dimmingView.userInteractionEnabled = YES;
            }];
        }
    }
}

- (void)onDismiss {
    [self dismissWithCardAnimation];
}

#pragma mark - Photos

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger count = self.photos.count;
    if (count >= 4) return 4;
    return count + 1; // 包含“+”占位
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PNMatchVerifyPhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kPNMatchVerifyPhotoCellId forIndexPath:indexPath];

    BOOL isAddCell = (indexPath.item >= self.photos.count);
    if (isAddCell) {
        if (@available(iOS 13.0, *)) {
            cell.imageView.image = [UIImage systemImageNamed:@"plus"];
            cell.imageView.tintColor = [UIColor lightGrayColor];
            cell.imageView.contentMode = UIViewContentModeCenter;
        } else {
            cell.imageView.image = nil;
        }
        cell.deleteButton.hidden = YES;
    } else {
        cell.imageView.image = self.photos[indexPath.item];
        cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
        cell.deleteButton.hidden = NO;
        cell.deleteButton.tag = indexPath.item;
        [cell.deleteButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [cell.deleteButton addTarget:self action:@selector(onDeletePhoto:) forControlEvents:UIControlEventTouchUpInside];
    }

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item >= self.photos.count) {
        [self pickPhoto];
    }
}

- (void)pickPhoto {
    if (self.photos.count >= 4) return;
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    picker.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)onDeletePhoto:(UIButton *)sender {
    NSInteger index = sender.tag;
    if (index >= 0 && index < (NSInteger)self.photos.count) {
        [self.photos removeObjectAtIndex:(NSUInteger)index];
        [self.photoCollectionView reloadData];
        [self updateUploadCountLabel];
        [self updateConfirmButtonState];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    UIImage *img = info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:NO completion:nil];
    if (!img) return;
    if (self.photos.count >= 4) return;
    [self.photos addObject:img];
    [self.photoCollectionView reloadData];
    [self updateUploadCountLabel];
    [self updateConfirmButtonState];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:NO completion:nil];
}

- (void)updateUploadCountLabel {
    self.uploadCountLabel.text = [NSString stringWithFormat:@"(%ld/4，至少2张)", (long)self.photos.count];
}

#pragma mark - Location

- (void)startLocate {
    if (![CLLocationManager locationServicesEnabled]) {
        self.locationLabel.text = @"定位服务未开启";
        [self updateConfirmButtonState];
        return;
    }

    if (!self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        self.locationManager.delegate = self;
    }
    
    // iOS 8+ 需要显式请求授权
    CLAuthorizationStatus status;
    if (@available(iOS 14.0, *)) {
        status = self.locationManager.authorizationStatus;
    } else {
        status = [CLLocationManager authorizationStatus];
    }
    if (status == kCLAuthorizationStatusNotDetermined) {
        [self.locationManager requestWhenInUseAuthorization];
    }

    self.locationLabel.text = @"定位中...";
    self.currentAddress = @"";
    [self updateConfirmButtonState];

    // 请求一次当前定位，结果在代理回调中处理
    [self.locationManager requestLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.locationLabel.text = @"定位失败";
        self.currentAddress = @"";
        [self updateConfirmButtonState];
    });
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *location = [locations lastObject];
    if (!location) {
        [self locationManager:manager didFailWithError:[NSError errorWithDomain:kCLErrorDomain code:kCLErrorLocationUnknown userInfo:nil]];
        return;
    }
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    __weak typeof(self) weakSelf = self;
    self.coordinate=location.coordinate;
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error || placemarks.count == 0) {
                weakSelf.locationLabel.text = @"定位失败";
                weakSelf.currentAddress = @"";
                [weakSelf updateConfirmButtonState];
                return;
            }
            
            CLPlacemark *placemark = [placemarks firstObject];
            NSString *city = placemark.locality ?: placemark.administrativeArea;
            NSString *subLocality = placemark.subLocality ?: @"";
            NSString *name = placemark.name ?: @"";
            
            NSString *display = nil;
            if (city.length > 0 && name.length > 0) {
                display = [NSString stringWithFormat:@"%@·%@", city, name];
            } else if (city.length > 0 && subLocality.length > 0) {
                display = [NSString stringWithFormat:@"%@%@", city, subLocality];
            } else if (placemark.postalAddress) {
                // 使用 CNPostalAddressFormatter 生成更详细地址（需要 Contacts.framework）
                display = name.length > 0 ? name : city;
            } else if (name.length > 0) {
                display = name;
            } else if (city.length > 0) {
                display = city;
            } else {
                display = [NSString stringWithFormat:@"%.6f,%.6f",
                           location.coordinate.longitude,
                           location.coordinate.latitude];
            }
            
            weakSelf.currentAddress = display;
            weakSelf.locationLabel.text = display;
            [weakSelf updateConfirmButtonState];
        });
    }];
}

#pragma mark - Confirm

- (void)updateConfirmButtonState {
    BOOL enabled = (self.photos.count >= 2 && self.currentAddress.length > 0);
    self.confirmButton.enabled = enabled;
    self.confirmButton.alpha = enabled ? 1.0 : 0.4;
}

- (void)onConfirm {
    // 提交逻辑留给后端集成，这里先回调上层并关闭弹层
    // 把所有image转成data上传至oss，把返回的所有oss的objectKey上传至自己后端
    NSMutableArray *urls = [NSMutableArray arrayWithCapacity:_photos.count];
    dispatch_group_t group = dispatch_group_create();
    for (int i=0; i<_photos.count; i++) {
        NSData *data = UIImageJPEGRepresentation(_photos[i], 0.5);
        dispatch_group_enter(group);
        [FileRequest.shared uploadImage:data type:ImageObjectTypeMatch success:^(HTTPResponse * _Nullable responseObject) {
            [urls addObject:responseObject.dataObject];
            dispatch_group_leave(group);
        } failure:^(NSError * _Nonnull error) {
            dispatch_group_leave(group);
        }];
    }
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
       //调用比赛认证接口上传所有path至服务器
        [MatchRequest.shared verifyMatchRecord:self.recordId body:@{@"photoUrls":urls,@"latitude":@(self.coordinate.latitude),@"longitude":@(self.coordinate.longitude),@"address":self.currentAddress ?: @""} success:^(HTTPResponse * _Nullable responseObject) {
            if (self.completion) {
                self.completion();
            }
            [self dismissWithCardAnimation];
        } failure:^(NSError * _Nonnull error) {
            [QMUITips showError:error.localizedDescription];
        }];
    });
}

@end

