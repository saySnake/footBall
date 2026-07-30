//
//  LocationViewController.m
//  footBall
//

#import "LocationViewController.h"
#import "AddFriendViewController.h"
#import "MyQRCodeViewController.h"
#import "CommunityRequest.h"
#import "StampAlbumMainPageViewController.h"
#import "PassportViewController.h"
#import <Masonry/Masonry.h>
#import "ColorManager.h"
#import <SDWebImage/SDWebImage.h>
#import <YYModel/YYModel.h>

#define kCommunityGreen    [UIColor colorWithRed:0.157 green:0.365 blue:0.294 alpha:1.0] // #285D4B
#define kCommunityHeaderBg [UIColor colorWithRed:0.051 green:0.129 blue:0.133 alpha:1.0] // #0D2122
#define kCommunityPageBg   [UIColor colorWithRed:0.976 green:0.980 blue:0.976 alpha:1.0] // #F9FAF9 设计稿内容区背景
static NSString * const kCommunityPendingCountKey = @"community_pending_count";
static NSString * const kCommunityPendingCountDidChangeNotification = @"community_pending_count_did_change";
static NSString * const kCommunityFriendsDidChangeNotification = @"community_friends_did_change";
static const NSTimeInterval kFriendsRefreshMinInterval = 3.0;

static UIImage *PNCommunityAvatarPlaceholder(void) {
    if (@available(iOS 13.0, *)) {
        return [UIImage systemImageNamed:@"person.crop.circle.fill"];
    }
    return nil;
}

static void PNApplyAvatarToImageView(UIImageView *imageView, NSString *urlString) {
    NSString *rawURL = urlString.length > 0 ? urlString : @"";
    NSString *avatarURL = [rawURL stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    UIImage *placeholder = PNCommunityAvatarPlaceholder();
    if (avatarURL.length == 0) {
        [imageView sd_cancelCurrentImageLoad];
        imageView.image = placeholder;
        if (@available(iOS 13.0, *)) {
            imageView.tintColor = [UIColor colorWithWhite:0.7 alpha:1.0];
            imageView.contentMode = UIViewContentModeCenter;
        }
        return;
    }

    NSURL *url = [NSURL URLWithString:avatarURL];
    if (!url) {
        [imageView sd_cancelCurrentImageLoad];
        imageView.image = placeholder;
        return;
    }

    NSString *cacheKey = [[SDWebImageManager sharedManager] cacheKeyForURL:url];
    UIImage *cached = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:cacheKey];
    if (!cached) {
        cached = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:cacheKey];
    }
    if (cached) {
        [imageView sd_cancelCurrentImageLoad];
        imageView.image = cached;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.tintColor = nil;
        return;
    }

    imageView.image = placeholder;
    if (@available(iOS 13.0, *)) {
        imageView.tintColor = [UIColor colorWithWhite:0.7 alpha:1.0];
        imageView.contentMode = UIViewContentModeCenter;
    }
    __weak UIImageView *weakIV = imageView;
    [imageView sd_setImageWithURL:url
                 placeholderImage:nil
                          options:SDWebImageRetryFailed
                        completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        UIImageView *iv = weakIV;
        if (!iv) return;
        if (image && !error) {
            iv.contentMode = UIViewContentModeScaleAspectFill;
            iv.tintColor = nil;
        } else if (@available(iOS 13.0, *)) {
            iv.image = placeholder;
            iv.tintColor = [UIColor colorWithWhite:0.7 alpha:1.0];
            iv.contentMode = UIViewContentModeCenter;
        }
    }];
}

typedef NS_ENUM(NSInteger, CommunityRankType) {
    CommunityRankTypeWeek,
    CommunityRankTypeMonth,
    CommunityRankTypeSeason
};

@interface CommunityFriendCell : UITableViewCell
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *idLabel;
@property (nonatomic, strong) UIView *statusDot;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIButton *stampBtn;
@property (nonatomic, strong) UIButton *dataBtn;
@property (nonatomic, copy) NSString *loadedAvatarURL;
- (void)configureWithFriend:(PNFriend *)f;
@end

@implementation CommunityFriendCell

- (NSDate *)pn_parseLastOnlineDate:(NSString *)raw {
    if (raw.length == 0) return nil;
    NSString *s = [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (s.length == 0) return nil;
    BOOL allDigits = YES;
    for (NSUInteger i = 0; i < s.length; i++) {
        unichar ch = [s characterAtIndex:i];
        if (ch < '0' || ch > '9') { allDigits = NO; break; }
    }
    if (allDigits && s.length >= 10) {
        long long n = [s longLongValue];
        if (n > 1000000000000LL) return [NSDate dateWithTimeIntervalSince1970:n / 1000.0];
        if (n > 1000000000LL) return [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)n];
    }
    if (@available(iOS 11.0, *)) {
        NSISO8601DateFormatter *iso = [[NSISO8601DateFormatter alloc] init];
        iso.formatOptions = NSISO8601DateFormatWithInternetDateTime | NSISO8601DateFormatWithFractionalSeconds;
        NSDate *d = [iso dateFromString:s];
        if (d) return d;
        iso.formatOptions = NSISO8601DateFormatWithInternetDateTime;
        d = [iso dateFromString:s];
        if (d) return d;
    }
    NSDateFormatter *f = [[NSDateFormatter alloc] init];
    f.locale = [NSLocale currentLocale];
    f.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    for (NSString *fmt in @[@"yyyy-MM-dd'T'HH:mm:ssZ", @"yyyy-MM-dd'T'HH:mm:ss", @"yyyy-MM-dd HH:mm:ss", @"yyyy-MM-dd HH:mm"]) {
        f.dateFormat = fmt;
        NSDate *d = [f dateFromString:s];
        if (d) return d;
    }
    return nil;
}

- (NSString *)pn_offlineTextFromLastOnline:(NSString *)lastOnlineTime {
    NSDate *d = [self pn_parseLastOnlineDate:lastOnlineTime];
    if (!d) return NSLocalizedString(@"community_online_5m_ago", nil);
    NSTimeInterval delta = [[NSDate date] timeIntervalSinceDate:d];
    if (delta < 0) delta = 0;
    NSInteger mins = (NSInteger)floor(delta / 60.0);
    if (mins < 1) mins = 1;
    if (mins <= 59) {
        if ([[NSLocale preferredLanguages].firstObject.lowercaseString hasPrefix:@"zh"]) {
            return [NSString stringWithFormat:@"%ld分钟前在线", (long)mins];
        }
        return [NSString stringWithFormat:@"Online %ld mins ago", (long)mins];
    }
    NSInteger hours = (NSInteger)floor((double)mins / 60.0);
    if (hours <= 23) {
        if ([[NSLocale preferredLanguages].firstObject.lowercaseString hasPrefix:@"zh"]) {
            return [NSString stringWithFormat:@"%ld小时前在线", (long)hours];
        }
        return [NSString stringWithFormat:@"Online %ld hours ago", (long)hours];
    }
    NSInteger days = (NSInteger)floor((double)hours / 24.0);
    if ([[NSLocale preferredLanguages].firstObject.lowercaseString hasPrefix:@"zh"]) {
        return [NSString stringWithFormat:@"%ld天前在线", (long)days];
    }
    return [NSString stringWithFormat:@"Online %ld days ago", (long)days];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];

        _cardView = [[UIView alloc] init];
        _cardView.backgroundColor = [UIColor whiteColor];
        _cardView.layer.cornerRadius = 6;

        _avatarView = [[UIImageView alloc] init];
        _avatarView.layer.cornerRadius = 27;
        _avatarView.clipsToBounds = YES;
        _avatarView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];

        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];

        _idLabel = [[UILabel alloc] init];
        _idLabel.font = [UIFont systemFontOfSize:12];
        _idLabel.textColor = [UIColor colorWithWhite:0.26 alpha:1.0];

        _statusDot = [[UIView alloc] init];
        _statusDot.layer.cornerRadius = 4;
        _statusDot.backgroundColor = [UIColor colorWithRed:0.0 green:0.71 blue:0.12 alpha:1.0];

        _statusLabel = [[UILabel alloc] init];
        _statusLabel.font = [UIFont systemFontOfSize:10];

        _stampBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _stampBtn.titleLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
        _stampBtn.layer.cornerRadius = 12;
        _stampBtn.layer.borderWidth = 0.6;
        _stampBtn.layer.borderColor = kCommunityGreen.CGColor;
        [_stampBtn setTitleColor:kCommunityGreen forState:UIControlStateNormal];

        _dataBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _dataBtn.titleLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
        _dataBtn.layer.cornerRadius = 12;
        _dataBtn.layer.borderWidth = 0.6;
        _dataBtn.layer.borderColor = kCommunityGreen.CGColor;
        [_dataBtn setTitleColor:kCommunityGreen forState:UIControlStateNormal];

        [self.contentView addSubview:_cardView];
        [_cardView addSubview:_avatarView];
        [_cardView addSubview:_nameLabel];
        [_cardView addSubview:_idLabel];
        [_cardView addSubview:_statusDot];
        [_cardView addSubview:_statusLabel];
        [_cardView addSubview:_stampBtn];
        [_cardView addSubview:_dataBtn];

        [_cardView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(5, 18, 5, 14));
        }];
        [_avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_cardView).offset(10);
            make.centerY.equalTo(_cardView);
            make.width.height.mas_equalTo(54);
        }];
        [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_avatarView.mas_trailing).offset(10);
            make.top.equalTo(_cardView).offset(8);
        }];
        [_idLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_nameLabel);
            make.height.mas_equalTo(22);
            make.top.equalTo(_nameLabel.mas_bottom).offset(1);
        }];
        [_statusDot mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(8);
            make.right.equalTo(_avatarView).offset(-7);
            make.bottom.equalTo(_avatarView).offset(-1);
        }];
        [_statusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_nameLabel);
            make.top.equalTo(_idLabel.mas_bottom).offset(3);
        }];
        [_stampBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(_cardView).offset(-10);
            make.top.equalTo(_cardView).offset(10);
            make.width.mas_equalTo(67);
            make.height.mas_equalTo(24);
        }];
        [_dataBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(_stampBtn);
            make.bottom.equalTo(_cardView).offset(-10);
            make.width.equalTo(_stampBtn);
            make.height.equalTo(_stampBtn);
        }];
        [_cardView bringSubviewToFront:_statusDot];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.avatarView sd_cancelCurrentImageLoad];
}

- (void)configureWithFriend:(PNFriend *)f {
    self.nameLabel.text = f.nickname.length > 0 ? f.nickname : @"-";
    self.idLabel.text = [NSString stringWithFormat:NSLocalizedString(@"community_id_format", nil), f.userId];
    self.statusLabel.text = f.online ? NSLocalizedString(@"community_online_15m", nil) : [self pn_offlineTextFromLastOnline:f.lastOnlineTime];
    self.statusLabel.textColor = f.online ? [UIColor colorWithRed:0.10 green:0.70 blue:0.30 alpha:1.0] : [UIColor grayColor];
    self.statusDot.backgroundColor = f.online ? [UIColor colorWithRed:0.0 green:0.71 blue:0.12 alpha:1.0] : [UIColor colorWithWhite:0.65 alpha:1.0];
    [self.stampBtn setTitle:NSLocalizedString(@"community_view_stamps", nil) forState:UIControlStateNormal];
    [self.dataBtn setTitle:NSLocalizedString(@"community_view_data", nil) forState:UIControlStateNormal];

    NSString *rawAvatar = f.avatar.length > 0 ? f.avatar : @"";
    NSString *avatarURL = [rawAvatar stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([self.loadedAvatarURL isEqualToString:avatarURL] && self.avatarView.image) {
        return;
    }
    self.loadedAvatarURL = avatarURL;
    PNApplyAvatarToImageView(self.avatarView, avatarURL);
}

@end

//周榜cell
@interface CommunityRankCell : UITableViewCell
@property (nonatomic, strong) UILabel *rankLabel;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *teamLabel;
@property (nonatomic, strong) UILabel *gamesLabel;
@property (nonatomic, copy) NSString *loadedAvatarURL;
- (void)configureWithItem:(PNLeaderboardEntry *)item rank:(NSInteger)rank;
@end

@implementation CommunityRankCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        _rankLabel = [UILabel new];
        _rankLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        _rankLabel.textColor = [UIColor blackColor];
        _rankLabel.textAlignment = NSTextAlignmentLeft;
        _avatarView = [UIImageView new];
        _avatarView.layer.cornerRadius = 30;
        _avatarView.clipsToBounds = YES;
        _nameLabel = [UILabel new];
        _nameLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        _nameLabel.textColor = [UIColor blackColor];
        _teamLabel = [UILabel new];
        _teamLabel.font = [UIFont systemFontOfSize:12];
        _teamLabel.textColor = [UIColor colorWithRed:0.612 green:0.643 blue:0.671 alpha:1.0]; // #9CA4AB
        _gamesLabel = [UILabel new];
        _gamesLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        _gamesLabel.textColor = [UIColor blackColor];
        _gamesLabel.textAlignment = NSTextAlignmentRight;
        [self.contentView addSubview:_rankLabel];
        [self.contentView addSubview:_avatarView];
        [self.contentView addSubview:_nameLabel];
        [self.contentView addSubview:_teamLabel];
        [self.contentView addSubview:_gamesLabel];
        [_rankLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentView).offset(24);
            make.centerY.equalTo(self.contentView);
            make.width.mas_greaterThanOrEqualTo(12);
        }];
        // Figma 1:5798：名次在 24pt，头像左缘 50pt
        [_avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentView).offset(50);
            make.centerY.equalTo(self.contentView);
            make.size.mas_equalTo(CGSizeMake(60, 60));
        }];
        [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_avatarView.mas_trailing).offset(10);
            make.top.equalTo(_avatarView).offset(10);
            make.trailing.lessThanOrEqualTo(_gamesLabel.mas_leading).offset(-10);
        }];
        [_teamLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_nameLabel);
            make.top.equalTo(_nameLabel.mas_bottom).offset(2);
            make.trailing.lessThanOrEqualTo(_gamesLabel.mas_leading).offset(-10);
        }];
        [_gamesLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(self.contentView).offset(-24);
            make.centerY.equalTo(self.contentView);
            make.width.mas_greaterThanOrEqualTo(70);
        }];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.avatarView sd_cancelCurrentImageLoad];
}

- (void)configureWithItem:(PNLeaderboardEntry *)item rank:(NSInteger)rank {
    NSInteger displayRank = item.rank > 0 ? item.rank : rank;
    self.rankLabel.text = [NSString stringWithFormat:@"%ld", (long)displayRank];
    self.nameLabel.text = item.nickname.length > 0 ? item.nickname : @"-";
    TeamIcon *team = item.followedTeams.firstObject;
    NSString *teamText = item.teamName.length > 0 ? item.teamName : (team.name.length > 0 ? team.name : @"-");
    self.teamLabel.text = teamText;
    self.gamesLabel.text = [NSString stringWithFormat:NSLocalizedString(@"community_rank_games_format", nil), (long)MAX(item.matchCount, 0)];
    NSString *rawAvatar = item.avatar.length > 0 ? item.avatar : @"";
    NSString *avatarURL = [rawAvatar stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([self.loadedAvatarURL isEqualToString:avatarURL] && self.avatarView.image) {
        return;
    }
    self.loadedAvatarURL = avatarURL;
    PNApplyAvatarToImageView(self.avatarView, avatarURL);
}

@end

@interface LocationViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *switchBgView;
@property (nonatomic, strong) UIButton *friendsTab;
@property (nonatomic, strong) UIButton *rankTab;
@property (nonatomic, strong) UIButton *addFriendBtn;
@property (nonatomic, strong) UIButton *qrCodeBtn;
@property (nonatomic, strong) UIView *pendingBadgeView;
@property (nonatomic, strong) UILabel *pendingBadgeLabel;
@property (nonatomic, strong) UILabel *sectionLabel;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<PNFriend *> *friends;
@property (nonatomic, strong) NSArray<PNLeaderboardEntry *> *weekRanks;
@property (nonatomic, strong) NSArray<PNLeaderboardEntry *> *monthRanks;
@property (nonatomic, strong) NSArray<PNLeaderboardEntry *> *seasonRanks;
@property (nonatomic, assign) CommunityRankType currentRankType;
@property (nonatomic, assign) BOOL isFriendsTab;
@property (nonatomic, assign) NSInteger pendingCount;
@property (nonatomic, strong) UIButton *weekBtn;
@property (nonatomic, strong) UIButton *monthBtn;
@property (nonatomic, strong) UIButton *seasonBtn;
@property (nonatomic, strong) UIView *weekLine;
@property (nonatomic, strong) UIView *monthLine;
@property (nonatomic, strong) UIView *seasonLine;
@property (nonatomic, strong) UIView *rankFilterContainer;
@property (nonatomic, strong) MASConstraint *headerHeightConstraint;
@property (nonatomic, strong) UIView *friendsEmptyBackgroundView;
@property (nonatomic, strong) UILabel *friendsEmptyTitleLabel;
/// 标记是否需要重新拉取好友列表（首次进入或好友关系变化时置 YES）
@property (nonatomic, assign) BOOL needsReloadFriends;
@property (nonatomic, strong) NSDate *friendsLastRefreshDate;
@end

@implementation LocationViewController

- (void)updateFriendsSectionTitle {
    if (!self.isFriendsTab) {
        return;
    }
    self.sectionLabel.text = (self.friends.count > 0)
        ? (NSLocalizedString(@"community_tab_friends", nil) ?: @"好友")
        : (NSLocalizedString(@"community_section_may_know", nil) ?: @"你可能认识的人");
}

- (NSArray<PNFriend *> *)pnFriendsFromCommunityData:(id)data {
    if (!data || data == (id)kCFNull) {
        return @[];
    }
    if ([data isKindOfClass:[NSArray class]]) {
        return [self pnFriendsFromJSONArray:(NSArray *)data];
    }
    if ([data isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)data;
        for (NSString *key in @[@"list", @"records", @"items", @"rows", @"friends", @"content"]) {
            id list = dict[key];
            if ([list isKindOfClass:[NSArray class]]) {
                return [self pnFriendsFromJSONArray:(NSArray *)list];
            }
        }
        PNFriend *item = [PNFriend yy_modelWithJSON:dict];
        if (item && (item.userId.length > 0 || item.nickname.length > 0)) {
            return @[item];
        }
    }
    return @[];
}

- (NSArray<PNFriend *> *)pnFriendsFromJSONArray:(NSArray *)raw {
    NSMutableArray<PNFriend *> *out = [NSMutableArray array];
    for (id item in raw) {
        if ([item isKindOfClass:PNFriend.class]) {
            PNFriend *f = (PNFriend *)item;
            if (f.userId.length > 0 || f.nickname.length > 0) {
                [out addObject:f];
            }
            continue;
        }
        if (![item isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        id payload = ((NSDictionary *)item)[@"friend"] ?: ((NSDictionary *)item)[@"user"] ?: item;
        PNFriend *f = [PNFriend yy_modelWithJSON:payload];
        if (f && (f.userId.length > 0 || f.nickname.length > 0)) {
            [out addObject:f];
        }
    }
    return out;
}

- (BOOL)pn_friendsList:(NSArray<PNFriend *> *)lhs equalTo:(NSArray<PNFriend *> *)rhs {
    if (lhs.count != rhs.count) return NO;
    for (NSInteger i = 0; i < lhs.count; i++) {
        PNFriend *a = lhs[i];
        PNFriend *b = rhs[i];
        if (![a.userId ?: @"" isEqualToString:b.userId ?: @""]) return NO;
        if (![a.avatar ?: @"" isEqualToString:b.avatar ?: @""]) return NO;
        if (![a.nickname ?: @"" isEqualToString:b.nickname ?: @""]) return NO;
        if (a.online != b.online) return NO;
        if (![a.lastOnlineTime ?: @"" isEqualToString:b.lastOnlineTime ?: @""]) return NO;
    }
    return YES;
}

- (void)viewDidLoad {
    self.friends = @[];
    self.weekRanks = @[];
    self.monthRanks = @[];
    self.seasonRanks = @[];
    self.isFriendsTab = YES;
    self.currentRankType = CommunityRankTypeWeek;
    self.pendingCount = [[NSUserDefaults standardUserDefaults] integerForKey:kCommunityPendingCountKey];
    self.needsReloadFriends = NO;
    [super viewDidLoad];
    self.view.backgroundColor = kCommunityPageBg;
    self.shouldShowNavigationBar = NO;
    [self refreshPendingCountFromServer];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onPendingCountChanged) name:kCommunityPendingCountDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFriendsChanged) name:kCommunityFriendsDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [self loadRemoteFriends];
    [self loadRemoteRanks];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat tabBarH = self.tabBarController.tabBar.bounds.size.height;
    if (tabBarH > 0 && self.tableView.contentInset.bottom != tabBarH) {
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, tabBarH + 6, 0);
    }
}

- (BOOL)isCommunityNavigationRoot {
    UINavigationController *nav = self.navigationController;
    if (!nav) {
        return YES;
    }
    return nav.viewControllers.count <= 1 || nav.viewControllers.firstObject == self;
}

- (BOOL)shouldRefreshFriendsNow {
    if (!self.friendsLastRefreshDate) {
        return YES;
    }
    return [[NSDate date] timeIntervalSinceDate:self.friendsLastRefreshDate] >= kFriendsRefreshMinInterval;
}

- (void)refreshFriendsIfNeededForced:(BOOL)forced {
    if (!forced && !self.needsReloadFriends && ![self shouldRefreshFriendsNow]) {
        return;
    }
    self.needsReloadFriends = NO;
    [self loadRemoteFriends];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.pendingCount = [[NSUserDefaults standardUserDefaults] integerForKey:kCommunityPendingCountKey];
    if (self.needsReloadFriends) {
        [self refreshFriendsIfNeededForced:YES];
    } else if ([self isCommunityNavigationRoot]) {
        // 社区根页面：切 Tab 回来、从添加好友返回、对方同意申请后需看到最新列表
        [self refreshFriendsIfNeededForced:NO];
    }
    [self refreshPendingCountFromServer];
    [self updateCommunityEmptyState];
    [self updatePendingBadge];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadRemoteFriends {
    self.friendsLastRefreshDate = [NSDate date];
    __weak typeof(self) weakSelf = self;
    [CommunityRequest.shared getCommunityFriendsWithPage:1 pageSize:50 success:^(HTTPResponse * _Nullable responseObject) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        id raw = responseObject.dataObject ?: responseObject.data;
        NSArray<PNFriend *> *newFriends = [self pnFriendsFromCommunityData:raw];
        if ([self pn_friendsList:self.friends equalTo:newFriends]) {
            return;
        }
        self.friends = newFriends;
        [self updateFriendsSectionTitle];
        [self.tableView reloadData];
        [self updateCommunityEmptyState];
    } failure:^(NSError * _Nonnull error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        if (self.friends.count == 0) {
            [self updateFriendsSectionTitle];
            [self.tableView reloadData];
            [self updateCommunityEmptyState];
        }
    }];
}

- (void)refreshPendingCountFromServer {
    __weak typeof(self) weakSelf = self;
    [SocialRequest.shared getFriendRequestsPendingCountSuccess:^(HTTPResponse * _Nullable responseObject) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        NSInteger count = [responseObject.dataObject respondsToSelector:@selector(integerValue)] ? [responseObject.dataObject integerValue] : 0;
        self.pendingCount = MAX(count, 0);
        [[NSUserDefaults standardUserDefaults] setInteger:self.pendingCount forKey:kCommunityPendingCountKey];
        [self updatePendingBadge];
    } failure:^(NSError * _Nonnull error) {
    }];
}

- (UIButton *)makeOutlinedButton {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.layer.cornerRadius = 8;
    btn.layer.borderWidth = 0.8;
    btn.layer.borderColor = [UIColor blackColor].CGColor;
    btn.backgroundColor = [UIColor whiteColor];
    btn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    return btn;
}

- (void)setupUI {
    self.headerView = [[UIView alloc] init];
    self.headerView.backgroundColor = kCommunityHeaderBg;
    [self.view addSubview:self.headerView];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    self.titleLabel.textColor = [UIColor whiteColor];
    [self.headerView addSubview:self.titleLabel];

    self.switchBgView = [[UIView alloc] init];
    self.switchBgView.backgroundColor = [UIColor whiteColor];
    self.switchBgView.layer.cornerRadius = 23.5;
    [self.headerView addSubview:self.switchBgView];

    self.friendsTab = [UIButton buttonWithType:UIButtonTypeSystem];
    self.friendsTab.layer.cornerRadius = 20.5;
    self.friendsTab.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    [self.friendsTab addTarget:self action:@selector(onFriendsTab) forControlEvents:UIControlEventTouchUpInside];
    [self.switchBgView addSubview:self.friendsTab];

    self.rankTab = [UIButton buttonWithType:UIButtonTypeSystem];
    self.rankTab.layer.cornerRadius = 20.5;
    self.rankTab.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [self.rankTab addTarget:self action:@selector(onRankTab) forControlEvents:UIControlEventTouchUpInside];
    [self.switchBgView addSubview:self.rankTab];

    self.addFriendBtn = [self makeOutlinedButton];
    [self.addFriendBtn setImage:[UIImage imageNamed:@"add_friend_icon"] forState:UIControlStateNormal];
    self.addFriendBtn.tintColor = [UIColor blackColor];
    [self.addFriendBtn addTarget:self action:@selector(onAddFriend) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.addFriendBtn];

    self.pendingBadgeView = [[UIView alloc] init];
    self.pendingBadgeView.backgroundColor = [UIColor colorWithRed:0.95 green:0.25 blue:0.24 alpha:1.0];
    self.pendingBadgeView.layer.cornerRadius = 8;
    [self.addFriendBtn addSubview:self.pendingBadgeView];
    self.pendingBadgeLabel = [[UILabel alloc] init];
    self.pendingBadgeLabel.font = [UIFont boldSystemFontOfSize:10];
    self.pendingBadgeLabel.textColor = [UIColor whiteColor];
    [self.pendingBadgeView addSubview:self.pendingBadgeLabel];
    [self.pendingBadgeLabel mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self.pendingBadgeView).insets(UIEdgeInsetsMake(2, 4, 2, 4)); }];
    [self.pendingBadgeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.addFriendBtn.mas_top).offset(12);
        make.trailing.equalTo(self.addFriendBtn).offset(-8);
        make.width.mas_greaterThanOrEqualTo(16);
        make.height.mas_equalTo(16);
    }];

    self.qrCodeBtn = [self makeOutlinedButton];
    [self.qrCodeBtn setImage:[UIImage imageNamed:@"qrcode_icon"] forState:UIControlStateNormal];
    self.qrCodeBtn.tintColor = [UIColor blackColor];
    [self.qrCodeBtn addTarget:self action:@selector(onQRCode) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.qrCodeBtn];

    self.sectionLabel = [[UILabel alloc] init];
    self.sectionLabel.textColor = [UIColor blackColor];
    self.sectionLabel.font = FontManager.sharedManager.font16;
    [self.view addSubview:self.sectionLabel];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:[CommunityFriendCell class] forCellReuseIdentifier:@"CommunityFriendCell"];
    [self.tableView registerClass:[CommunityRankCell class] forCellReuseIdentifier:@"CommunityRankCell"];
    [self.view addSubview:self.tableView];

    [self.headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
        self.headerHeightConstraint = make.height.mas_equalTo(166);
    }];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.headerView);
        make.top.equalTo(self.headerView.mas_safeAreaLayoutGuideTop).offset(10);
    }];
    [self.switchBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.headerView).offset(16);
        make.trailing.equalTo(self.headerView).offset(-16);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(12);
        make.height.mas_equalTo(47);
    }];
    [self.friendsTab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.bottom.equalTo(self.switchBgView).insets(UIEdgeInsetsMake(3, 4, 3, 0));
        make.trailing.equalTo(self.switchBgView.mas_centerX).offset(-2);
    }];
    [self.rankTab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.top.bottom.equalTo(self.switchBgView).insets(UIEdgeInsetsMake(3, 0, 3, 4));
        make.leading.equalTo(self.switchBgView.mas_centerX).offset(2);
    }];

    self.rankFilterContainer = [[UIView alloc] init];
    self.rankFilterContainer.backgroundColor = [UIColor clearColor];
    [self.headerView addSubview:self.rankFilterContainer];
    self.weekBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    self.monthBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    self.seasonBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    NSArray<UIButton *> *rankButtons = @[self.weekBtn, self.monthBtn, self.seasonBtn];
    for (UIButton *btn in rankButtons) {
        btn.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
        [btn addTarget:self action:@selector(onRankFilterTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.rankFilterContainer addSubview:btn];
    }
    self.weekLine = [[UIView alloc] init];
    self.monthLine = [[UIView alloc] init];
    self.seasonLine = [[UIView alloc] init];
    NSArray<UIView *> *lines = @[self.weekLine, self.monthLine, self.seasonLine];
    for (UIView *line in lines) {
        line.backgroundColor = [UIColor whiteColor];
        line.layer.cornerRadius = 1.5;
        [self.rankFilterContainer addSubview:line];
    }
    [self.rankFilterContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.headerView);
        make.top.equalTo(self.switchBgView.mas_bottom).offset(20);
        make.height.mas_equalTo(38);
    }];
    [self.weekBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.rankFilterContainer).offset(4);
        make.top.equalTo(self.rankFilterContainer);
        make.width.equalTo(self.rankFilterContainer.mas_width).multipliedBy(1.0/3.0).offset(-2);
        make.height.mas_equalTo(30);
    }];
    [self.monthBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.weekBtn.mas_trailing).offset(2);
        make.top.width.height.equalTo(self.weekBtn);
    }];
    [self.seasonBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.monthBtn.mas_trailing).offset(2);
        make.top.width.height.equalTo(self.weekBtn);
    }];
    [self.weekLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.weekBtn.mas_bottom).offset(2);
        make.centerX.equalTo(self.weekBtn);
        make.width.mas_equalTo(18);
        make.height.mas_equalTo(3);
    }];
    [self.monthLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.monthBtn.mas_bottom).offset(2);
        make.centerX.equalTo(self.monthBtn);
        make.width.mas_equalTo(18);
        make.height.mas_equalTo(3);
    }];
    [self.seasonLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.seasonBtn.mas_bottom).offset(2);
        make.centerX.equalTo(self.seasonBtn);
        make.width.mas_equalTo(18);
        make.height.mas_equalTo(3);
    }];
    [self.addFriendBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView.mas_bottom).offset(17);
        make.leading.equalTo(self.view).offset(16);
        make.trailing.equalTo(self.view.mas_centerX).offset(-5);
        make.height.mas_equalTo(50);
    }];
    [self.qrCodeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.height.equalTo(self.addFriendBtn);
        make.leading.equalTo(self.view.mas_centerX).offset(5);
        make.trailing.equalTo(self.view).offset(-16);
    }];
    [self.sectionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.addFriendBtn.mas_bottom).offset(16);
        make.leading.equalTo(self.view).offset(16);
    }];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.sectionLabel.mas_bottom).offset(6);
        make.leading.trailing.bottom.equalTo(self.view);
    }];

    [self updateTabs];
    [self updatePendingBadge];
    [self refreshTableHeaderForCurrentMode];
    [self updateCommunityEmptyState];
}

- (void)updateTabs {
    if (self.isFriendsTab) {
        self.friendsTab.backgroundColor = kCommunityGreen;
        [self.friendsTab setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.rankTab.backgroundColor = [UIColor clearColor];
        [self.rankTab setTitleColor:kCommunityGreen forState:UIControlStateNormal];
    } else {
        self.rankTab.backgroundColor = kCommunityGreen;
        [self.rankTab setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.friendsTab.backgroundColor = [UIColor clearColor];
        [self.friendsTab setTitleColor:kCommunityGreen forState:UIControlStateNormal];
    }
    [self updateFriendsSectionTitle];
    [self refreshTableHeaderForCurrentMode];
    [self.tableView reloadData];
    [self updateCommunityEmptyState];
}

- (void)onFriendsTab {
    self.isFriendsTab = YES;
    [self updateTabs];
}

- (void)onRankTab {
    self.isFriendsTab = NO;
    [self updateTabs];
}

- (void)onRankFilterTapped:(UIButton *)sender {
    if (sender == self.weekBtn) self.currentRankType = CommunityRankTypeWeek;
    else if (sender == self.monthBtn) self.currentRankType = CommunityRankTypeMonth;
    else self.currentRankType = CommunityRankTypeSeason;
    [self refreshRankButtonsUI];
    [self.tableView reloadData];
    [self updateCommunityEmptyState];
}

- (void)refreshTableHeaderForCurrentMode {
    if (self.isFriendsTab) {
        self.headerHeightConstraint.offset = 166;
        self.tableView.backgroundColor = [UIColor clearColor];
        self.sectionLabel.hidden = NO;
        self.addFriendBtn.hidden = NO;
        self.qrCodeBtn.hidden = NO;
        self.rankFilterContainer.hidden = YES;
        [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.sectionLabel.mas_bottom).offset(6);
            make.leading.trailing.bottom.equalTo(self.view);
        }];
        [self updateCommunityEmptyState];
        return;
    }
    // 设计稿顶栏深色区约 206pt；刘海/Dynamic Island 机型需略增高以免裁切周/月/赛季
    self.headerHeightConstraint.offset = 214;
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.sectionLabel.hidden = YES;
    self.addFriendBtn.hidden = YES;
    self.qrCodeBtn.hidden = YES;
    self.rankFilterContainer.hidden = NO;
    [self.weekBtn setTitle:NSLocalizedString(@"community_rank_week", nil) forState:UIControlStateNormal];
    [self.monthBtn setTitle:NSLocalizedString(@"community_rank_month", nil) forState:UIControlStateNormal];
    [self.seasonBtn setTitle:NSLocalizedString(@"community_rank_season", nil) forState:UIControlStateNormal];
    [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView.mas_bottom);
        make.leading.trailing.bottom.equalTo(self.view);
    }];
    self.tableView.tableHeaderView = nil;
    [self refreshRankButtonsUI];
    [self updateCommunityEmptyState];
}

- (void)refreshRankButtonsUI {
    NSArray<UIButton *> *buttons = @[self.weekBtn, self.monthBtn, self.seasonBtn];
    NSArray<UIView *> *lines = @[self.weekLine, self.monthLine, self.seasonLine];
    for (NSInteger i = 0; i < buttons.count; i++) {
        UIButton *btn = buttons[i];
        BOOL selected = (i == self.currentRankType);
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        btn.alpha = selected ? 1.0 : 0.78;
        btn.titleLabel.font = [UIFont systemFontOfSize:14 weight:(selected ? UIFontWeightSemibold : UIFontWeightMedium)];
        lines[i].hidden = !selected;
    }
}

- (void)onAddFriend {
    self.needsReloadFriends = YES;
    AddFriendViewController *vc = [[AddFriendViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onQRCode {
    MyQRCodeViewController *vc = [[MyQRCodeViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onPendingCountChanged {
    self.pendingCount = [[NSUserDefaults standardUserDefaults] integerForKey:kCommunityPendingCountKey];
    [self updatePendingBadge];
    [self refreshPendingCountFromServer];
}

- (void)onFriendsChanged {
    if (self.isViewLoaded && self.view.window) {
        [self refreshFriendsIfNeededForced:YES];
    } else {
        self.needsReloadFriends = YES;
    }
}

- (void)onAppWillEnterForeground {
    [self refreshPendingCountFromServer];
    if (self.isViewLoaded && self.view.window) {
        [self refreshFriendsIfNeededForced:YES];
    } else {
        self.needsReloadFriends = YES;
    }
}

- (void)updatePendingBadge {
    BOOL shouldShow = self.pendingCount > 0;
    self.pendingBadgeView.hidden = !shouldShow;
    if (!shouldShow) {
        return;
    }
    self.pendingBadgeLabel.text = self.pendingCount > 99 ? @"99+" : [NSString stringWithFormat:@"%ld", (long)self.pendingCount];
}

- (void)ensureFriendsEmptyBackgroundView {
    if (self.friendsEmptyBackgroundView) {
        return;
    }
    UIView *bg = [[UIView alloc] init];
    bg.backgroundColor = kCommunityPageBg; // 实际颜色在 updateCommunityEmptyState 中按 Tab 覆盖
    UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"friend_nodata"]];
    iv.contentMode = UIViewContentModeScaleAspectFit;
    [bg addSubview:iv];
    UILabel *lb = [[UILabel alloc] init];
    lb.font = [UIFont systemFontOfSize:14];
    lb.textColor = [UIColor colorWithRed:0.6 green:0.62 blue:0.65 alpha:1.0];
    lb.text = NSLocalizedString(@"community_empty_no_data", nil);
    lb.textAlignment = NSTextAlignmentCenter;
    [bg addSubview:lb];
    self.friendsEmptyTitleLabel = lb;
    [iv mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(bg);
        make.centerY.equalTo(bg).offset(-28);
        make.width.height.mas_equalTo(120);
    }];
    [lb mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(iv.mas_bottom).offset(16);
        make.centerX.equalTo(bg);
    }];
    self.friendsEmptyBackgroundView = bg;
}

/// 好友或排行榜无数据时展示占位（friend_nodata + 暂无数据）
- (void)updateCommunityEmptyState {
    BOOL friendsEmpty = self.isFriendsTab && self.friends.count == 0;
    NSInteger rankCount = 0;
    if (!self.isFriendsTab) {
        if (self.currentRankType == CommunityRankTypeWeek) rankCount = self.weekRanks.count;
        else if (self.currentRankType == CommunityRankTypeMonth) rankCount = self.monthRanks.count;
        else rankCount = self.seasonRanks.count;
    }
    BOOL rankEmpty = !self.isFriendsTab && rankCount == 0;
    if (!friendsEmpty && !rankEmpty) {
        self.tableView.backgroundView = nil;
        return;
    }
    [self ensureFriendsEmptyBackgroundView];
    self.friendsEmptyBackgroundView.backgroundColor = self.isFriendsTab ? kCommunityPageBg : [UIColor whiteColor];
    self.friendsEmptyTitleLabel.text = NSLocalizedString(@"community_empty_no_data", nil);
    self.tableView.backgroundView = self.friendsEmptyBackgroundView;
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.isFriendsTab) return self.friends.count;
    if (self.currentRankType == CommunityRankTypeWeek) return self.weekRanks.count;
    if (self.currentRankType == CommunityRankTypeMonth) return self.monthRanks.count;
    return self.seasonRanks.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.isFriendsTab ? 84 : 80;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isFriendsTab) {
        CommunityFriendCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CommunityFriendCell" forIndexPath:indexPath];
        [cell configureWithFriend:self.friends[indexPath.row]];
        cell.stampBtn.tag = indexPath.row;
        [cell.stampBtn removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
        [cell.stampBtn addTarget:self action:@selector(onFriendStampsTapped:) forControlEvents:UIControlEventTouchUpInside];
        cell.dataBtn.tag = indexPath.row;
        [cell.dataBtn removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
        [cell.dataBtn addTarget:self action:@selector(onFriendDataTapped:) forControlEvents:UIControlEventTouchUpInside];
        return cell;
    }
    CommunityRankCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CommunityRankCell" forIndexPath:indexPath];
    NSArray<PNLeaderboardEntry *> *source = self.currentRankType == CommunityRankTypeWeek ? self.weekRanks : (self.currentRankType == CommunityRankTypeMonth ? self.monthRanks : self.seasonRanks);
    [cell configureWithItem:source[indexPath.row] rank:indexPath.row + 1];
    return cell;
}

- (void)updateLocalizedStrings {
    [super updateLocalizedStrings];
    self.titleLabel.text = NSLocalizedString(@"community_title", nil);
    [self.friendsTab setTitle:NSLocalizedString(@"community_tab_friends", nil) forState:UIControlStateNormal];
    [self.rankTab setTitle:NSLocalizedString(@"community_tab_rank", nil) forState:UIControlStateNormal];
    [self.addFriendBtn setTitle:[NSString stringWithFormat:@"  %@  ", NSLocalizedString(@"community_add_friend", nil)] forState:UIControlStateNormal];
    [self.qrCodeBtn setTitle:[NSString stringWithFormat:@"  %@  ", NSLocalizedString(@"community_my_qrcode", nil)] forState:UIControlStateNormal];
    [self updateFriendsSectionTitle];
    [self loadRemoteRanks];
    [self.tableView reloadData];
    [self updateCommunityEmptyState];
}

- (void)loadRemoteRanks {
    [self loadLeaderboardForPeriod:@"week" completion:^(NSArray<PNLeaderboardEntry *> *items) {
        self.weekRanks = items;
        [self.tableView reloadData];
        [self updateCommunityEmptyState];
    }];
    [self loadLeaderboardForPeriod:@"month" completion:^(NSArray<PNLeaderboardEntry *> *items) {
        self.monthRanks = items;
        [self.tableView reloadData];
        [self updateCommunityEmptyState];
    }];
    [self loadLeaderboardForPeriod:@"season" completion:^(NSArray<PNLeaderboardEntry *> *items) {
        self.seasonRanks = items;
        [self.tableView reloadData];
        [self updateCommunityEmptyState];
    }];
}

- (void)loadLeaderboardForPeriod:(NSString *)period completion:(void(^)(NSArray<PNLeaderboardEntry *> *items))completion {
    [ProfileRequest.shared getLeaderboardWithPeriod:period page:1 pageSize:30 success:^(HTTPResponse * _Nullable responseObject) {
        PNLeaderboard *board = [responseObject.dataObject isKindOfClass:PNLeaderboard.class] ? responseObject.dataObject : nil;
        completion(board.list ?: @[]);
    } failure:^(NSError * _Nonnull error) {
        completion(@[]);
    }];
}

- (void)onFriendStampsTapped:(UIButton *)sender {
    if (sender.tag < 0 || sender.tag >= self.friends.count) return;
    PNFriend *friend = self.friends[sender.tag];
    if (friend.userId.length == 0) return;
    
    // 跳转到邮票夹页面，传入好友 userId
    StampAlbumMainPageViewController *vc = [[StampAlbumMainPageViewController alloc] init];
    vc.targetUserId = friend.userId;
    vc.targetNickname = friend.nickname.length > 0 ? [NSString stringWithFormat:@"%@%@", friend.nickname, (NSLocalizedString(@"stamp_album_suffix", nil) ?: @"的邮票夹")] : nil;
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onFriendDataTapped:(UIButton *)sender {
    if (sender.tag < 0 || sender.tag >= self.friends.count) return;
    PNFriend *friend = self.friends[sender.tag];
    if (friend.userId.length == 0) return;
    
    // 跳转到护照页面，传入好友 userId
    PassportViewController *vc = [[PassportViewController alloc] init];
    vc.targetUserId = friend.userId;
    vc.targetNickname = friend.nickname.length > 0 ? [NSString stringWithFormat:@"%@%@", friend.nickname, (NSLocalizedString(@"passport_suffix", nil) ?: @"的护照")] : nil;
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
