//
//  StampAlbumMainPageViewController.m
//  footBall
//

#import "StampAlbumMainPageViewController.h"
#import "PassportHeader2View.h"
#import "PassportViewModel.h"
#import "ProfileRequest.h"
#import "HTTPResponse.h"
#import "Passport.h"
#import "AuthManager.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>
#import "StampRequest.h"
#import "StampModels.h"
#import "StampAlbumCategoryViewController.h"
#import "StampUnlockPopupViewController.h"
#import "MembershipCenterViewController.h"
#import "CommunityRequest.h"
#import "PNMatchInfoInputViewController.h"
#import "TeamsRequest.h"
#define STAMP_SECTION_COUNT  1000
#define STAMP_SECTION_ITEMS  15
#define STAMP_ITEAM_FREE  5

static UIColor *PassportSheetsNavBg(void) {
    return [UIColor colorWithHexString:@"#0D2122"];
}

static UIColor *PassportSheetsListBg(void) {
    return [UIColor colorWithRed:0.94 green:0.94 blue:0.95 alpha:1.0];
}

#pragma mark - Stamp sheet grid
@interface PassportStampGridItem : NSObject
@property (nonatomic, assign) BOOL unlocked;
/// 查看他人主页时为 YES：仅展示已有邮票，禁止交互，不显示添加/解锁
@property (nonatomic, assign) BOOL viewOnly;
@property (nonatomic, strong, nullable) PNStampAlbumItem *stamp;
@end
@implementation PassportStampGridItem
@end
typedef NS_ENUM(NSUInteger, PassportStampGridItemViewState) {
    PassportStampGridItemViewStateAdd,//添加
    PassportStampGridItemViewStateUnlock,//解锁
    PassportStampGridItemViewStateUpdate,//更换
    PassportStampGridItemViewStateDelete,//长按等待删除
    PassportStampGridItemViewStateViewOnly,//他人主页只读
};
@interface PassportStampGridItemView : UIButton
@property (nonatomic, strong) UIImageView *lockView;
@property (nonatomic, strong) PassportStampGridItem *item;
@property (nonatomic, assign) PassportStampGridItemViewState stampState;
@end
@implementation PassportStampGridItemView
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _lockView = [UIImageView.alloc initWithImage:[UIImage imageNamed:@"lock_icon"]];
        [self addSubview:_lockView];
        [_lockView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
        }];
    }
    return self;
}
- (void)longPressAction:(UILongPressGestureRecognizer *)gesture {
    if (self.stampState == PassportStampGridItemViewStateUpdate) {
        self.stampState = PassportStampGridItemViewStateDelete;
    }
}
- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [super endTrackingWithTouch:touch withEvent:event];
    if (self.stampState == PassportStampGridItemViewStateDelete) {
        self.stampState = PassportStampGridItemViewStateUpdate;
    }
}
- (void)setItem:(PassportStampGridItem *)item {
    _item = item;
    if (item.viewOnly) {
        self.stampState = PassportStampGridItemViewStateViewOnly;
        self.userInteractionEnabled = NO;
        self.lockView.hidden = YES;
        if (item.stamp) {
            self.backgroundColor = [UIColor colorWithHexString:@"#9C9C9C"];
            [self sd_setImageWithURL:[NSURL URLWithString:item.stamp.image] forState:UIControlStateNormal];
        } else {
            self.backgroundColor = [UIColor colorWithHexString:@"#E9E9E9"];
            [self sd_cancelImageLoadForState:UIControlStateNormal];
            [self setImage:nil forState:UIControlStateNormal];
        }
        return;
    }
    self.userInteractionEnabled = YES;
    if (item.unlocked) {
        self.backgroundColor = [UIColor colorWithHexString:@"#9C9C9C"];
        self.lockView.image = [UIImage imageNamed:@"stamp_add"];
        if (item.stamp) {
            self.stampState = PassportStampGridItemViewStateUpdate;
            self.lockView.hidden = YES;
            [self sd_setImageWithURL:[NSURL URLWithString:item.stamp.image] forState:UIControlStateNormal];
        } else {
            self.stampState = PassportStampGridItemViewStateAdd;
            self.lockView.hidden = NO;
            [self sd_cancelImageLoadForState:UIControlStateNormal];
            [self setImage:nil forState:UIControlStateNormal];
        }
    } else {
        self.stampState = PassportStampGridItemViewStateUnlock;
        self.backgroundColor = [UIColor colorWithHexString:@"#E9E9E9"];
        self.lockView.image = [UIImage imageNamed:@"lock_icon"];
        self.lockView.hidden = NO;
        [self sd_setImageWithURL:[NSURL URLWithString:item.stamp.image] forState:UIControlStateNormal];
    }
}
@end
@interface PassportStampSheetGridView : UIView
@property (nonatomic, copy) NSArray<PassportStampGridItem *> *items;
//添加
@property (nonatomic, copy) void (^onClickAdd)(NSInteger index,PassportStampGridItem *item);
//解锁
@property (nonatomic, copy) void (^onClickUnLock)(NSInteger index,PassportStampGridItem *item);
//更新
@property (nonatomic, copy) void (^onClickStamp)(NSInteger index,PassportStampGridItem *item);
//删除
@property (nonatomic, copy) void (^onClickDelete)(NSInteger index,PassportStampGridItem *item);
@property (nonatomic, assign) BOOL viewOnly;

- (void)configureWithItems:(NSArray<PassportStampGridItem *> *)items viewOnly:(BOOL)viewOnly;
@end
@implementation PassportStampSheetGridView
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        NSInteger rowItemCount = 5;
        PassportStampGridItemView *preItem = nil;
        CGFloat itemHorMargin = (SCREEN_WIDTH - 32 - 20 - rowItemCount*50)/(rowItemCount-1);
        for (int i = 0; i<STAMP_SECTION_ITEMS; i++) {
            PassportStampGridItemView *item = PassportStampGridItemView.alloc.init;
            item.tag = 0x900 + i;
            item.layer.cornerRadius = 25;
            item.clipsToBounds = YES;
            [item addTarget:self action:@selector(onClick:) forControlEvents:UIControlEventTouchUpInside];
            [item addGestureRecognizer:[UILongPressGestureRecognizer.alloc initWithTarget:self action:@selector(itemLongPressAction:)]];
            [self addSubview:item];
            UIButton *deleteBtn = [[UIButton alloc] init];
            deleteBtn.tag = 0xF + i;
            deleteBtn.hidden = YES;
            [deleteBtn setImage:[UIImage imageNamed:@"red_delete_icon"] forState:UIControlStateNormal];
            [deleteBtn addTarget:self action:@selector(deleteAction:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:deleteBtn];
            [deleteBtn mas_makeConstraints:^(MASConstraintMaker *make) {
                make.right.equalTo(item).offset(5);
                make.top.equalTo(item).offset(-5);
            }];
            [item mas_makeConstraints:^(MASConstraintMaker *make) {
                make.width.height.equalTo(@50);
                if (preItem == nil) {
                    make.left.equalTo(@0);
                } else {
                    make.left.equalTo(preItem.mas_right).offset(itemHorMargin);
                }
                if (i/rowItemCount == 0) {
                    make.top.equalTo(self);
                } else if (i/rowItemCount == 1) {
                    make.centerY.equalTo(self);
                } else {
                    make.bottom.equalTo(self);
                }
            }];
            if (i%rowItemCount == rowItemCount-1) {
                preItem = nil;
            } else {
                preItem = item;
            }
        }
        
    }
    return self;
}
- (void)onClick:(PassportStampGridItemView *)sender {
    if (self.viewOnly || sender.stampState == PassportStampGridItemViewStateViewOnly) {
        return;
    }
    NSInteger idx = sender.tag - 0x900;
    if (sender.stampState == PassportStampGridItemViewStateDelete) {
        sender.stampState = PassportStampGridItemViewStateUpdate;
        UIButton *btn = (UIButton *)[self viewWithTag:0xF+idx];
        btn.hidden = YES;
    } else if (sender.stampState == PassportStampGridItemViewStateUpdate) {
        if (self.onClickStamp) {
            self.onClickStamp(idx, sender.item);
        }
    } else if (sender.stampState == PassportStampGridItemViewStateAdd) {
        if (self.onClickAdd) {
            self.onClickAdd(idx, sender.item);
        }
    } else if (sender.stampState == PassportStampGridItemViewStateUnlock) {
        if (self.onClickUnLock) {
            self.onClickUnLock(idx, sender.item);
        }
    }
}
- (void)deleteAction:(UIButton *)sender {
    if (self.viewOnly) {
        return;
    }
    sender.hidden = YES;
    NSInteger idx = sender.tag - 0xF;
    PassportStampGridItemView *itemView = (PassportStampGridItemView *)[self viewWithTag:0x900+idx];
    if (self.onClickDelete) {
        self.onClickDelete(idx, itemView.item);
    }
//    itemView.item.stamp = nil;
//    [itemView setItem:itemView.item];
}
- (void)itemLongPressAction:(UILongPressGestureRecognizer *)sender {
    if (self.viewOnly) {
        return;
    }
    PassportStampGridItemView *itemView = (PassportStampGridItemView *)sender.view;
    if (itemView.stampState == PassportStampGridItemViewStateUpdate) {
        itemView.stampState = PassportStampGridItemViewStateDelete;
        NSInteger idx = itemView.tag - 0x900;
        UIButton *btn = (UIButton *)[self viewWithTag:0xF+idx];
        btn.hidden = NO;
    }

}
- (void)configureWithItems:(NSArray<PassportStampGridItem *> *)items {
    [self configureWithItems:items viewOnly:NO];
}

- (void)configureWithItems:(NSArray<PassportStampGridItem *> *)items viewOnly:(BOOL)viewOnly {
    self.viewOnly = viewOnly;
    self.userInteractionEnabled = !viewOnly;
    self.items = items ?: @[];
    for (int i = 0; i < STAMP_SECTION_ITEMS; i++) {
        UIButton *deleteBtn = (UIButton *)[self viewWithTag:0xF + i];
        deleteBtn.hidden = YES;
        deleteBtn.userInteractionEnabled = !viewOnly;
    }
    for (int i = 0; i < (NSInteger)self.items.count; i++) {
        PassportStampGridItemView *iv = (PassportStampGridItemView *)[self viewWithTag:0x900 + i];
        if (![iv isKindOfClass:PassportStampGridItemView.class]) {
            continue;
        }
        PassportStampGridItem *it = self.items[(NSUInteger)i];
        it.viewOnly = viewOnly;
        iv.item = it;
    }
}

@end

#pragma mark - Header2 card (first row)
@interface PassportStampSheetCardItem : NSObject
@property (nonatomic, strong) NSArray <PassportStampGridItem *> *topItems;
@property (nonatomic, strong) NSArray <PassportStampGridItem *> *bottomItems;
@end
@implementation PassportStampSheetCardItem

@end

@interface PassportHeader2Card : UIView
@property (nonatomic, strong) UIView *card;
@property (nonatomic, strong) PassportHeader2View *header2;
@property (nonatomic, strong) PassportStampSheetGridView *bottomGridView;
@end

@implementation PassportHeader2Card

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        UIView *topBg = UIView.alloc.init;
        topBg.backgroundColor = [UIColor colorWithHexString:@"#0D2122"];
        [self addSubview:topBg];
        [topBg mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.equalTo(self);
            make.height.equalTo(@76);
        }];
        
        
        _card = [[UIView alloc] init];
        _card.backgroundColor = [UIColor colorWithHexString:@"#FEFEFE"];
        _card.layer.cornerRadius = 16;
        _card.clipsToBounds = YES;
        [self addSubview:_card];

        UIImageView *sepTop= [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"passport_header_sep"]];
        [_card addSubview:sepTop];
        [sepTop mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_card).offset(10);
            make.height.mas_equalTo(10);
            make.leading.trailing.equalTo(_card).insets(UIEdgeInsetsMake(0, 10, 0, 10));
        }];

        _header2 = [[PassportHeader2View alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH-32, 0)];
        [_card addSubview:_header2];

        CGFloat whUnit = [PassportHeader2Card itemWH];
        CGFloat headerH = whUnit * 5.0;

        [_card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self).insets(UIEdgeInsetsMake(8, 16, 8, 16));
        }];
        [_header2 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_card).offset(30);
            make.leading.trailing.equalTo(_card).insets(UIEdgeInsetsMake(0, 16, 0, 16));
            make.height.mas_equalTo(headerH);
        }];

        StampDashView *dashView = [[StampDashView alloc] init];
        [_card addSubview:dashView];
        [dashView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.header2.mas_bottom).offset(10);
            make.height.mas_equalTo(5);
            make.leading.trailing.equalTo(_card);
        }];
        UIImageView *sepMid= [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"passport_header_sep"]];
        [_card addSubview:sepMid];
        self.bottomGridView = PassportStampSheetGridView.alloc.init;
        [_card addSubview:self.bottomGridView];
        [sepMid mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.header2.mas_bottom).offset(20);
            make.height.mas_equalTo(10);
            make.leading.trailing.equalTo(_card).insets(UIEdgeInsetsMake(0, 10, 0, 10));
        }];

        [self.bottomGridView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.header2.mas_bottom).offset(40);
            make.height.mas_equalTo(200);
            make.leading.trailing.equalTo(_card).insets(UIEdgeInsetsMake(0, 10, 0, 10));
        }];

    }
    return self;
}
+ (CGFloat)itemWH{
    CGFloat whUnit = (SCREEN_WIDTH - 32 - 32) / 8.0;
    return whUnit;
}
- (void)configureWithModel:(PassportViewModel *)model {
    [self.header2 configureWithModel:model];
}
- (void)configureWithSectionItem:(PassportStampSheetCardItem *)item viewOnly:(BOOL)viewOnly {
    [self.bottomGridView configureWithItems:item.bottomItems viewOnly:viewOnly];
}
- (void)configureWithSectionItem:(PassportStampSheetCardItem *)item {
    [self configureWithSectionItem:item viewOnly:NO];
}
@end

#pragma mark - Stamp sheet placeholder (5×3 grid)
@interface PassportStampSheetCardCell : UITableViewCell
@property (nonatomic, strong) UIView *card;
@property (nonatomic, strong) PassportStampSheetGridView *topGridView;
@property (nonatomic, strong) PassportStampSheetGridView *bottomGridView;
- (void)configureWithSectionItem:(PassportStampSheetCardItem *)item;
@end

@implementation PassportStampSheetCardCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];

        _card = [[UIView alloc] init];
        _card.backgroundColor = [UIColor whiteColor];
        _card.layer.cornerRadius = 16;
        _card.clipsToBounds = YES;
        [self.contentView addSubview:_card];
        [_card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(8, 16, 8, 16));
        }];
        
        UIImageView *sepTop= [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"passport_header_sep"]];
        [_card addSubview:sepTop];
        [sepTop mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_card).offset(10);
            make.height.mas_equalTo(10);
            make.leading.trailing.equalTo(_card).insets(UIEdgeInsetsMake(0, 10, 0, 10));
        }];

        self.topGridView = PassportStampSheetGridView.alloc.init;
        [_card addSubview:self.topGridView];
        [self.topGridView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(sepTop.mas_bottom).offset(10);
            make.height.mas_equalTo(200);
            make.leading.trailing.equalTo(_card).insets(UIEdgeInsetsMake(0, 10, 0, 10));
        }];
        
        StampDashView *dashView = [[StampDashView alloc] init];
        [_card addSubview:dashView];
        [dashView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.topGridView.mas_bottom).offset(10);
            make.height.mas_equalTo(5);
            make.leading.trailing.equalTo(_card);
        }];
        UIImageView *sepMid= [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"passport_header_sep"]];
        [_card addSubview:sepMid];
        self.bottomGridView = PassportStampSheetGridView.alloc.init;
        [_card addSubview:self.bottomGridView];
        [sepMid mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.topGridView.mas_bottom).offset(20);
            make.height.mas_equalTo(10);
            make.leading.trailing.equalTo(_card).insets(UIEdgeInsetsMake(0, 10, 0, 10));
        }];

        [self.bottomGridView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.topGridView.mas_bottom).offset(40);
            make.height.mas_equalTo(200);
            make.leading.trailing.equalTo(_card).insets(UIEdgeInsetsMake(0, 10, 0, 10));
            make.bottom.equalTo(@-10);
        }];

    }
    return self;
}

- (void)configureWithSectionItem:(PassportStampSheetCardItem *)item viewOnly:(BOOL)viewOnly {
    [self.topGridView configureWithItems:item.topItems viewOnly:viewOnly];
    [self.bottomGridView configureWithItems:item.bottomItems viewOnly:viewOnly];
}
- (void)configureWithSectionItem:(PassportStampSheetCardItem *)item {
    [self configureWithSectionItem:item viewOnly:NO];
}



@end

#pragma mark - View controller

@interface StampAlbumMainPageViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) PassportViewModel *viewModel;
@property (nonatomic, assign) NSInteger year;
@property (nonatomic, strong) UIView *topBar;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *shareButton;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) PassportHeader2Card *headerCard;
@property (nonatomic, strong) NSArray <PassportStampSheetCardItem *> *items;
/// 邮票配额（仅自己护照页使用）
@property (nonatomic, assign) BOOL stampIsMember;
@property (nonatomic, assign) NSInteger stampFreeQuota;
@property (nonatomic, assign) NSInteger stampMaxCount;

@end

@implementation StampAlbumMainPageViewController

- (void)presentStampUnlockDialog {
    __weak typeof(self) weakSelf = self;
    StampUnlockPopupViewController *vc = [[StampUnlockPopupViewController alloc] init];
    vc.onConfirm = ^(NSInteger initialPlanIndex) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        MembershipCenterViewController *member = [[MembershipCenterViewController alloc] init];
        member.initialPlanIndex = initialPlanIndex;
        [self.navigationController pushViewController:member animated:YES];
    };
    [self presentViewController:vc animated:NO completion:nil];
}
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        NSCalendar *cal = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
        _year = [cal component:NSCalendarUnitYear fromDate:[NSDate date]];
        _stampFreeQuota = STAMP_ITEAM_FREE;
    }
    return self;
}
- (instancetype)initWithViewModel:(PassportViewModel *)viewModel year:(NSInteger)year {
    if (self = [super init]) {
        _viewModel = viewModel;
        _year = year;
        _stampFreeQuota = STAMP_ITEAM_FREE;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 从会员中心等页面返回时刷新配额与锁状态（首次 push 时 isMovingToParentViewController 为 YES，跳过避免重复请求）
    if (!self.isMovingToParentViewController && self.targetUserId.length == 0) {
        [self loadStampCollection];
        [self loadPassportDataForceRefresh:NO];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 自定义导航栏页面也开启系统左侧滑动返回
    if (self.navigationController.viewControllers.count > 1) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        self.navigationController.interactivePopGestureRecognizer.delegate = nil;
    }
}

- (BOOL)isViewingOthers {
    return self.targetUserId.length > 0;
}

- (BOOL)isSlotUnlockedInFirstGroup:(BOOL)isFirstGroup atIndex:(NSInteger)index {
    if ([self isViewingOthers]) {
        return NO;
    }
    // 仅第一组（header，坐标 section=1）前 5 格永久免费；其余全部按会员解锁
    if (isFirstGroup && index < STAMP_ITEAM_FREE) {
        return YES;
    }
    return self.stampIsMember;
}

- (void)applyStampQuota:(PNStampQuota *)quota {
    if (!quota) {
        return;
    }
    self.stampIsMember = quota.isMember;
    if (quota.freeQuota > 0) {
        self.stampFreeQuota = quota.freeQuota;
    }
    self.stampMaxCount = quota.maxStampCount;
}

- (void)setupRefresh {
    RefreshPagHeader *header = [RefreshPagHeader headerWithRefreshingTarget:self refreshingAction:@selector(onPullToRefresh)];
    [header prepare];
    _tableView.mj_header = header;
}

- (void)onPullToRefresh {
    [self loadStampCollection];
    [self loadPassportData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hidesBottomBarWhenPushed = YES;
    self.shouldShowNavigationBar = NO;
    self.view.backgroundColor = PassportSheetsListBg();

    [self buildTopBar];
    [self buildTable];
    [self setupRefresh];
    if (_viewModel == nil) {
        [self loadPassportData];
    }
    [self reloadStamps:@[]];
    [self loadStampCollection];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onMatchRecordDidUpdate:)
                                                 name:PNMatchRecordDidUpdateNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onTeamFollowDidUpdate:)
                                                 name:PNTeamFollowDidUpdateNotification
                                               object:nil];
}

- (void)buildTopBar {
    _topBar = [[UIView alloc] init];
    _topBar.backgroundColor = PassportSheetsNavBg();
    [self.view addSubview:_topBar];

    _backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    if (@available(iOS 13.0, *)) {
        UIImage *img = [UIImage systemImageNamed:@"chevron.left"];
        [_backButton setImage:[img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    } else {
        [_backButton setTitle:NSLocalizedString(@"back", nil) ?: @"返回" forState:UIControlStateNormal];
    }
    _backButton.tintColor = [UIColor whiteColor];
    [_backButton addTarget:self action:@selector(onBack) forControlEvents:UIControlEventTouchUpInside];
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    _titleLabel.textColor = [UIColor whiteColor];
    if (self.targetUserId.length > 0) {
        NSString *name = self.targetNickname.length > 0 ? self.targetNickname : (NSLocalizedString(@"stamp_album_friend_title", nil) ?: @"TA的邮票夹");
        _titleLabel.text = name;
    } else {
        _titleLabel.text = NSLocalizedString(@"passport_nav_title", nil) ?: @"我的护照";
    }


    _shareButton = [UIButton buttonWithType:UIButtonTypeSystem];
    if (@available(iOS 13.0, *)) {
        UIImage *img = [UIImage imageNamed:@"passport_share"];
        [_shareButton setImage:[img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    _shareButton.hidden = YES;
    _shareButton.tintColor = [UIColor whiteColor];
    [_shareButton addTarget:self action:@selector(share) forControlEvents:UIControlEventTouchUpInside];

    [_topBar addSubview:_backButton];
    [_topBar addSubview:_titleLabel];
    [_topBar addSubview:_shareButton];

    [_topBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(44);
    }];
    [_backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(_topBar).offset(8);
        make.bottom.equalTo(_topBar).offset(-8);
        make.width.height.mas_equalTo(36);
    }];
    [_shareButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(_topBar).offset(-8);
        make.centerY.equalTo(_backButton);
        make.width.height.mas_equalTo(36);
    }];
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(_topBar);
        make.centerY.equalTo(_backButton);
    }];
}

- (void)buildTable {
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.backgroundColor = PassportSheetsListBg();
    _tableView.showsVerticalScrollIndicator = YES;
    _tableView.estimatedRowHeight = 280;
    _tableView.rowHeight = UITableViewAutomaticDimension;
    _tableView.contentInset = UIEdgeInsetsMake(0, 0, 24, 0);
    [self.view addSubview:_tableView];

    CGFloat headerHeight = ([PassportHeader2Card itemWH]*5+30+40+30+200);
    PassportHeader2Card *header = [PassportHeader2Card.alloc initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, headerHeight)];
    [header configureWithModel:self.viewModel];
    __weak typeof(self) weakSelf = self;
    if (![self isViewingOthers]) {
        header.bottomGridView.onClickAdd = ^(NSInteger index, PassportStampGridItem *item) {
        StampAlbumCategoryViewController *album = StampAlbumCategoryViewController.alloc.init;
        album.didSelected = ^(PNStampAlbumItem * _Nonnull stamp) {
            //header只有一组,坐标分组从1开始
            NSString *position = [NSString stringWithFormat:@"1,%ld",index];
            [StampRequest.shared addStamp:stamp.stampId position:position success:^(HTTPResponse * _Nullable responseObject) {
                [weakSelf loadStampCollection];
            } failure:^(NSError * _Nonnull error) {
                [QMUITips showError:error.localizedDescription];
            }];
        };
        [weakSelf.navigationController pushViewController:album animated:YES];
    };
    header.bottomGridView.onClickStamp = ^(NSInteger index, PassportStampGridItem *item) {
        StampAlbumCategoryViewController *album = StampAlbumCategoryViewController.alloc.init;
        album.didSelected = ^(PNStampAlbumItem * _Nonnull stamp) {
            [StampRequest.shared updateOldStamp:item.stamp.stampId newStamp:stamp.stampId success:^(HTTPResponse * _Nullable responseObject) {
                [weakSelf loadStampCollection];
            } failure:^(NSError * _Nonnull error) {
                [QMUITips showError:error.localizedDescription];
            }];
        };
        [weakSelf.navigationController pushViewController:album animated:YES];
    };
    header.bottomGridView.onClickUnLock = ^(NSInteger index, PassportStampGridItem *item) {
        [weakSelf presentStampUnlockDialog];
    };
    header.bottomGridView.onClickDelete = ^(NSInteger index, PassportStampGridItem *item) {
        // 删除
        [StampRequest.shared deleteStamp:item.stamp.stampId success:^(HTTPResponse * _Nullable responseObject) {
            [weakSelf loadStampCollection];
        } failure:^(NSError * _Nonnull error) {
            [QMUITips showError:error.localizedDescription];
        }];
    };
    }
    self.headerCard = header;
    self.tableView.tableHeaderView = header;
    
    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_topBar.mas_bottom);
        make.leading.trailing.bottom.equalTo(self.view);
    }];

    [_tableView registerClass:[PassportStampSheetCardCell class] forCellReuseIdentifier:@"stamp"];
}

- (void)reloadStamps:(NSArray <PNStampAlbumItem *> *)stamps {
    BOOL viewOnly = [self isViewingOthers];
    //第一组 tableView headerView
    PassportStampSheetCardItem *headerItem = PassportStampSheetCardItem.alloc.init;
    NSMutableArray *subItem = [NSMutableArray arrayWithCapacity:STAMP_SECTION_ITEMS];
    for (int j=0; j<STAMP_SECTION_ITEMS; j++) {
        PassportStampGridItem *gridItem1 = PassportStampGridItem.alloc.init;
        gridItem1.viewOnly = viewOnly;
        gridItem1.unlocked = viewOnly ? NO : [self isSlotUnlockedInFirstGroup:YES atIndex:j];
        [subItem addObject:gridItem1];
    }
    headerItem.bottomItems = subItem;
    //一个cell对应两组， tableView dataSource
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:STAMP_SECTION_COUNT];
    for (int i=0; i<STAMP_SECTION_COUNT; i++) {
        PassportStampSheetCardItem *item = PassportStampSheetCardItem.alloc.init;
        NSMutableArray *subItem1 = [NSMutableArray arrayWithCapacity:STAMP_SECTION_ITEMS];
        NSMutableArray *subItem2 = [NSMutableArray arrayWithCapacity:STAMP_SECTION_ITEMS];
        for (int j=0; j<STAMP_SECTION_ITEMS; j++) {
            PassportStampGridItem *gridItem1 = PassportStampGridItem.alloc.init;
            gridItem1.viewOnly = viewOnly;
            gridItem1.unlocked = viewOnly ? NO : [self isSlotUnlockedInFirstGroup:NO atIndex:j];
            [subItem1 addObject:gridItem1];
            PassportStampGridItem *gridItem2 = PassportStampGridItem.alloc.init;
            gridItem2.viewOnly = viewOnly;
            gridItem2.unlocked = viewOnly ? NO : [self isSlotUnlockedInFirstGroup:NO atIndex:j];
            [subItem2 addObject:gridItem2];
        }
        item.topItems = subItem1;
        item.bottomItems = subItem2;
        [array addObject:item];
    }
    self.items = array.copy;
    
    //e.g stamp position = "3,10" 坐标分组从1开始
    // row 0 => section 2 & 3
    // row 1 => section 4 & 5
    // row 2 => section 6 & 7
    // NSInteger row = (section - 2) / 2;
    // NSInteger section = row * 2 + 2 + (0 or 1)
    for (int i = 0; i<stamps.count; i++) {
        NSArray <NSString *> *position = [stamps[i].position componentsSeparatedByString:@","];
        if (position.count == 2) {
            NSInteger section = position.firstObject.integerValue;
            NSInteger index = position.lastObject.integerValue;
            if (section < 2) {
                headerItem.bottomItems[index].stamp = stamps[i];
            } else {
                NSInteger row = (section - 2) / 2;
                PassportStampSheetCardItem *item = self.items[row];
                if (section%2 == 0) {
                    item.topItems[index].stamp = stamps[i];
                } else {
                    item.bottomItems[index].stamp = stamps[i];
                }
            }
            
        }
    }
    [self.headerCard configureWithSectionItem:headerItem viewOnly:viewOnly];
    [self.tableView reloadData];
}
// 获取邮票列表（自己或好友）
- (void)loadStampCollection {
    __weak typeof(self) weakSelf = self;

    if (self.targetUserId.length > 0) {
        [CommunityRequest.shared getFriendStamps:self.targetUserId success:^(HTTPResponse * _Nullable responseObject) {
            NSArray<PNStampAlbumItem *> *stamps = [responseObject.dataObject isKindOfClass:NSArray.class] ? responseObject.dataObject : @[];
            [weakSelf reloadStamps:stamps];
            [weakSelf.tableView.mj_header endRefreshing];
        } failure:^(NSError * _Nonnull error) {
            [weakSelf showError:error.localizedDescription ?: (NSLocalizedString(@"network_error", nil) ?: @"")];
            [weakSelf.tableView.mj_header endRefreshing];
        }];
        return;
    }

    __block NSArray<PNStampAlbumItem *> *stamps = @[];
    __block PNStampQuota *quota = nil;
    dispatch_group_t group = dispatch_group_create();

    dispatch_group_enter(group);
    [StampRequest.shared getStampQuotaSuccess:^(HTTPResponse * _Nullable responseObject) {
        if ([responseObject.dataObject isKindOfClass:PNStampQuota.class]) {
            quota = (PNStampQuota *)responseObject.dataObject;
        }
        dispatch_group_leave(group);
    } failure:^(NSError * _Nonnull error) {
        dispatch_group_leave(group);
    }];

    dispatch_group_enter(group);
    [StampRequest.shared getStampListSuccess:^(HTTPResponse * _Nullable responseObject) {
        if ([responseObject.dataObject isKindOfClass:NSArray.class]) {
            stamps = (NSArray<PNStampAlbumItem *> *)responseObject.dataObject;
        }
        dispatch_group_leave(group);
    } failure:^(NSError * _Nonnull error) {
        dispatch_group_leave(group);
    }];

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [weakSelf applyStampQuota:quota];
        [weakSelf reloadStamps:stamps];
        [weakSelf.tableView.mj_header endRefreshing];
    });
}
- (void)loadPassportData {
    [self loadPassportDataForceRefresh:NO];
}

- (void)loadPassportDataForceRefresh:(BOOL)forceRefresh {
    __weak typeof(self) weakSelf = self;
    BOOL isPullRefresh = self.tableView.mj_header.isRefreshing;
    if (!isPullRefresh) {
        [self showLoading];
    }
    NSString *y = [NSString stringWithFormat:@"%ld", (long)self.year];
    BOOL isOther = self.targetUserId.length > 0;
    void (^handleSuccess)(PNPassport *) = ^(PNPassport *p) {
        [weakSelf hideLoading];
        [weakSelf.tableView.mj_header endRefreshing];
        weakSelf.viewModel = [PassportViewModel viewModelWithPassport:p year:weakSelf.year];
        // 查看自己时用本地头像和城市
        if (!isOther) {
            NSString *localAvatar = AuthManager.sharedManager.user.profile.avatar;
            if (!localAvatar.length) localAvatar = AuthManager.sharedManager.user.avatar;
            if (localAvatar.length) weakSelf.viewModel.avatarURL = localAvatar;
            NSString *localCity = AuthManager.sharedManager.user.profile.city;
            if (localCity.length) weakSelf.viewModel.userCity = localCity;
        }
        [weakSelf.headerCard configureWithModel:weakSelf.viewModel];
        [weakSelf.tableView reloadData];
        [weakSelf.view setNeedsLayout];
    };
    void (^handleFailure)(NSError *) = ^(NSError *error) {
        [weakSelf hideLoading];
        [weakSelf.tableView.mj_header endRefreshing];
        [weakSelf showError:error.localizedDescription ?: (NSLocalizedString(@"network_error", nil) ?: @"")];
        weakSelf.viewModel = [PassportViewModel viewModelWithPassport:nil year:weakSelf.year];
    };
    if (isOther) {
        [[ProfileRequest shared] getPassportForUserId:self.targetUserId year:y success:^(HTTPResponse * _Nullable responseObject) {
            PNPassport *p = [responseObject.dataObject isKindOfClass:PNPassport.class] ? responseObject.dataObject : nil;
            if (p && !p.nickname.length && weakSelf.targetNickname.length > 0) {
                p.nickname = weakSelf.targetNickname;
            }
            handleSuccess(p);
        } failure:^(NSError * _Nonnull error) {
            handleFailure(error);
        }];
    } else {
        [[ProfileRequest shared] getMyPassportWithYear:y bypassCache:forceRefresh success:^(HTTPResponse * _Nullable responseObject) {
            handleSuccess(responseObject.dataObject);
        } failure:^(NSError * _Nonnull error) {
            handleFailure(error);
        }];
    }
}
// 分享
- (void)share {
    
}

- (void)onBack {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PassportStampSheetCardCell *c = [tableView dequeueReusableCellWithIdentifier:@"stamp" forIndexPath:indexPath];
    __weak typeof(self) weakSelf = self;
    if (![self isViewingOthers]) {
    c.topGridView.onClickAdd = ^(NSInteger index, PassportStampGridItem *item) {
        StampAlbumCategoryViewController *album = StampAlbumCategoryViewController.alloc.init;
        album.didSelected = ^(PNStampAlbumItem * _Nonnull stamp) {
            // NSInteger section = row * 2 + 2 + (0 or 1) 坐标分组从1开始
            NSInteger section = indexPath.row*2 + 2;
            NSString *position = [NSString stringWithFormat:@"%ld,%ld",section,index];
            [StampRequest.shared addStamp:stamp.stampId position:position success:^(HTTPResponse * _Nullable responseObject) {
                [weakSelf loadStampCollection];
            } failure:^(NSError * _Nonnull error) {
                [QMUITips showError:error.localizedDescription];
            }];
        };
        [weakSelf.navigationController pushViewController:album animated:YES];
    };
    c.topGridView.onClickStamp = ^(NSInteger index, PassportStampGridItem *item) {
        StampAlbumCategoryViewController *album = StampAlbumCategoryViewController.alloc.init;
        album.didSelected = ^(PNStampAlbumItem * _Nonnull stamp) {
            NSString *oldId = item.stamp.stampId ?: @"";
            NSString *newId = stamp.stampId ?: @"";
            if (oldId.length == 0 || newId.length == 0) {
                return;
            }
            [StampRequest.shared updateOldStamp:oldId newStamp:newId success:^(HTTPResponse * _Nullable responseObject) {
                [weakSelf loadStampCollection];
            } failure:^(NSError * _Nonnull error) {
                [QMUITips showError:error.localizedDescription];
            }];
        };
        [weakSelf.navigationController pushViewController:album animated:YES];
    };
    c.topGridView.onClickUnLock = ^(NSInteger index, PassportStampGridItem *item) {
        [weakSelf presentStampUnlockDialog];
    };
    c.topGridView.onClickDelete = ^(NSInteger index, PassportStampGridItem *item) {
        NSString *sid = item.stamp.stampId ?: @"";
        if (sid.length == 0) {
            return;
        }
        [StampRequest.shared deleteStamp:sid success:^(HTTPResponse * _Nullable responseObject) {
            [weakSelf loadStampCollection];
        } failure:^(NSError * _Nonnull error) {
            [QMUITips showError:error.localizedDescription];
        }];
    };
    c.bottomGridView.onClickAdd = ^(NSInteger index, PassportStampGridItem *item) {
        StampAlbumCategoryViewController *album = StampAlbumCategoryViewController.alloc.init;
        album.didSelected = ^(PNStampAlbumItem * _Nonnull stamp) {
            // NSInteger section = row * 2 + 2 + (0 or 1) 坐标分组从1开始
            NSInteger section = indexPath.row*2 + 2 + 1;
            NSString *position = [NSString stringWithFormat:@"%ld,%ld",section,index];
            [StampRequest.shared addStamp:stamp.stampId position:position success:^(HTTPResponse * _Nullable responseObject) {
                [weakSelf loadStampCollection];
            } failure:^(NSError * _Nonnull error) {
                [QMUITips showError:error.localizedDescription];
            }];
        };
        [weakSelf.navigationController pushViewController:album animated:YES];
    };
    c.bottomGridView.onClickStamp = ^(NSInteger index, PassportStampGridItem *item) {
        StampAlbumCategoryViewController *album = StampAlbumCategoryViewController.alloc.init;
        album.didSelected = ^(PNStampAlbumItem * _Nonnull stamp) {
            NSString *oldId = item.stamp.stampId ?: @"";
            NSString *newId = stamp.stampId ?: @"";
            if (oldId.length == 0 || newId.length == 0) {
                return;
            }
            [StampRequest.shared updateOldStamp:oldId newStamp:newId success:^(HTTPResponse * _Nullable responseObject) {
                [weakSelf loadStampCollection];
            } failure:^(NSError * _Nonnull error) {
                [QMUITips showError:error.localizedDescription];
            }];
        };
        [weakSelf.navigationController pushViewController:album animated:YES];
    };
    c.bottomGridView.onClickUnLock = ^(NSInteger index, PassportStampGridItem *item) {
        [weakSelf presentStampUnlockDialog];
    };
    c.bottomGridView.onClickDelete = ^(NSInteger index, PassportStampGridItem *item) {
        NSString *sid = item.stamp.stampId ?: @"";
        if (sid.length == 0) {
            return;
        }
        [StampRequest.shared deleteStamp:sid success:^(HTTPResponse * _Nullable responseObject) {
            [weakSelf loadStampCollection];
        } failure:^(NSError * _Nonnull error) {
            [QMUITips showError:error.localizedDescription];
        }];
    };
    } else {
        c.topGridView.onClickAdd = nil;
        c.topGridView.onClickStamp = nil;
        c.topGridView.onClickUnLock = nil;
        c.topGridView.onClickDelete = nil;
        c.bottomGridView.onClickAdd = nil;
        c.bottomGridView.onClickStamp = nil;
        c.bottomGridView.onClickUnLock = nil;
        c.bottomGridView.onClickDelete = nil;
    }
    [c configureWithSectionItem:self.items[indexPath.row] viewOnly:[self isViewingOthers]];
    return c;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 236*2;
}

- (void)updateLocalizedStrings {
    [super updateLocalizedStrings];
    if ([self isViewingOthers]) {
        NSString *name = self.targetNickname.length > 0 ? self.targetNickname : (NSLocalizedString(@"stamp_album_friend_title", nil) ?: @"TA的邮票夹");
        _titleLabel.text = name;
    } else {
        _titleLabel.text = NSLocalizedString(@"passport_nav_title", nil) ?: @"我的护照";
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Notifications

- (void)onMatchRecordDidUpdate:(NSNotification *)notification {
    [self loadStampCollection];
    [self loadPassportDataForceRefresh:YES];
}

- (void)onTeamFollowDidUpdate:(NSNotification *)notification {
    [self loadPassportData];
}

@end
