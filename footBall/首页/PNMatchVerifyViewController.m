//
//  PNMatchVerifyViewController.m
//  footBall
//

#import "PNMatchVerifyViewController.h"
#import <Masonry/Masonry.h>
#import <CoreLocation/CoreLocation.h>

#if __has_include(<AMapLocationKit/AMapLocationKit.h>)
#import <AMapLocationKit/AMapLocationKit.h>
#define PN_HAS_AMAP_LOCATION 1
#else
#define PN_HAS_AMAP_LOCATION 0
#endif

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

@interface PNMatchVerifyViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) UIView *dimmingView;
@property (nonatomic, strong) UIView *cardView;

@property (nonatomic, strong) UILabel *uploadCountLabel;
@property (nonatomic, strong) UICollectionView *photoCollectionView;
@property (nonatomic, strong) NSMutableArray<UIImage *> *photos;

@property (nonatomic, strong) UILabel *locationLabel;
#if PN_HAS_AMAP_LOCATION
@property (nonatomic, strong) AMapLocationManager *locationManager;
#endif
@property (nonatomic, copy) NSString *currentAddress;

@property (nonatomic, strong) UIButton *confirmButton;

@end

@implementation PNMatchVerifyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    self.photos = [NSMutableArray array];

    [self buildUI];
    [self startLocate];
}

- (void)dealloc {
    _locationManager.delegate = nil;
}

- (void)buildUI {
    UIView *dim = [[UIView alloc] init];
    dim.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.35];
    [self.view addSubview:dim];
    self.dimmingView = dim;
    [dim mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [dim addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDismiss)]];

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
    confirm.backgroundColor = [UIColor colorWithRed:0.10 green:0.36 blue:0.28 alpha:1.0];
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

- (void)onDismiss {
    [self dismissViewControllerAnimated:NO completion:nil];
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

#if PN_HAS_AMAP_LOCATION
    if (!self.locationManager) {
        self.locationManager = [[AMapLocationManager alloc] init];
        [self.locationManager setDesiredAccuracy:kCLLocationAccuracyHundredMeters];
        self.locationManager.locationTimeout = 6;
        self.locationManager.reGeocodeTimeout = 6;
    }

    __weak typeof(self) weakSelf = self;
    [self.locationManager requestLocationWithReGeocode:YES completionBlock:^(CLLocation *location, AMapLocationReGeocode *regeocode, NSError *error) {
        if (error || !location) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.locationLabel.text = @"定位失败";
                [weakSelf updateConfirmButtonState];
            });
            return;
        }

        NSString *display = nil;
        if (regeocode) {
            // 直辖市等 city 为空时用 province 兜底
            NSString *city = (regeocode.city.length > 0) ? regeocode.city : regeocode.province;
            NSString *district = regeocode.district ?: @"";
            NSString *poi = regeocode.POIName ?: @"";

            // 优先 “城市·POI”，否则城市+区县，再退回详细地址
            if (city.length > 0 && poi.length > 0) {
                display = [NSString stringWithFormat:@"%@·%@", city, poi];
            } else if (city.length > 0 && district.length > 0) {
                display = [NSString stringWithFormat:@"%@%@", city, district];
            } else if (regeocode.formattedAddress.length > 0) {
                display = regeocode.formattedAddress;
            } else if (city.length > 0) {
                display = city;
            } else if (district.length > 0) {
                display = district;
            }
        }
        if (display.length == 0) {
            display = [NSString stringWithFormat:@"%.6f,%.6f",
                       location.coordinate.longitude,
                       location.coordinate.latitude];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.currentAddress = display;
            weakSelf.locationLabel.text = display;
            [weakSelf updateConfirmButtonState];
        });
    }];
#else
    // 未集成高德 SDK 时的兜底提示（避免编译错误）
    self.locationLabel.text = @"请集成 AMapLocationKit 以使用定位";
    self.currentAddress = @"";
    [self updateConfirmButtonState];
#endif
}

#pragma mark - Confirm

- (void)updateConfirmButtonState {
    BOOL enabled = (self.photos.count >= 2 && self.currentAddress.length > 0);
    self.confirmButton.enabled = enabled;
    self.confirmButton.alpha = enabled ? 1.0 : 0.4;
}

- (void)onConfirm {
    // 提交逻辑留给后端集成，这里先关闭弹层
    [self dismissViewControllerAnimated:NO completion:nil];
}

@end

