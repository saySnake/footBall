//
//  NewFriendRequestsViewController.m
//  footBall
//

#import "NewFriendRequestsViewController.h"
#import <Masonry/Masonry.h>
#import "ColorManager.h"

#define kRequestGreen    [UIColor colorWithRed:0.157 green:0.365 blue:0.294 alpha:1.0] // #285D4B
#define kRequestHeaderBg [UIColor colorWithRed:0.051 green:0.129 blue:0.133 alpha:1.0] // #0D2122
#define kRequestRed      [UIColor colorWithRed:1.0 green:0.031 blue:0.047 alpha:1.0]   // #FF080C
#define kRequestPageBg   [UIColor colorWithRed:0.969 green:0.969 blue:0.969 alpha:1.0] // #F7F7F7
static NSString * const kCommunityPendingCountKey = @"community_pending_count";
static NSString * const kCommunityPendingCountDidChangeNotification = @"community_pending_count_did_change";
static NSString * const kCommunityAddedFriendsKey = @"community_added_friends";
static NSString * const kCommunityFriendsDidChangeNotification = @"community_friends_did_change";

typedef NS_ENUM(NSInteger, FriendRequestStatus) {
    FriendRequestStatusPending,
    FriendRequestStatusExpired,
    FriendRequestStatusAdded
};

@interface FriendRequestCell : UITableViewCell
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *idLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIButton *acceptBtn;
@property (nonatomic, strong) UIButton *rejectBtn;
@property (nonatomic, strong) UIButton *statusBtn;
- (void)configureWithName:(NSString *)name
                     odId:(NSString *)odId
               statusText:(NSString *)statusText
                  message:(NSString *)message
                 isOnline:(BOOL)isOnline
                   status:(FriendRequestStatus)status;
@end

@implementation FriendRequestCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _cardView = [UIView new];
        _cardView.backgroundColor = [UIColor whiteColor];
        _cardView.layer.cornerRadius = 6;
        _cardView.clipsToBounds = YES;

        _avatarView = [UIImageView new];
        _avatarView.layer.cornerRadius = 20;
        _avatarView.clipsToBounds = YES;

        _nameLabel = [UILabel new];
        _nameLabel.font = [UIFont boldSystemFontOfSize:15];
        _nameLabel.textColor = [UIColor blackColor];

        _idLabel = [UILabel new];
        _idLabel.font = [UIFont systemFontOfSize:12];
        _idLabel.textColor = [UIColor grayColor];

        _statusLabel = [UILabel new];
        _statusLabel.font = [UIFont systemFontOfSize:11];
        _statusLabel.textColor = [UIColor grayColor];

        _messageLabel = [UILabel new];
        _messageLabel.font = [UIFont systemFontOfSize:12];
        _messageLabel.textColor = [UIColor darkGrayColor];
        _messageLabel.numberOfLines = 2;

        _acceptBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _acceptBtn.layer.cornerRadius = 15;
        _acceptBtn.backgroundColor = kRequestGreen;
        _acceptBtn.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        [_acceptBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

        _rejectBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _rejectBtn.layer.cornerRadius = 15;
        _rejectBtn.backgroundColor = kRequestRed;
        _rejectBtn.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        [_rejectBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

        _statusBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _statusBtn.layer.cornerRadius = 15;
        _statusBtn.layer.borderWidth = 0.6;
        _statusBtn.userInteractionEnabled = NO;
        _statusBtn.titleLabel.font = [UIFont systemFontOfSize:12];

        [self.contentView addSubview:_cardView];
        [_cardView addSubview:_avatarView];
        [_cardView addSubview:_nameLabel];
        [_cardView addSubview:_idLabel];
        [_cardView addSubview:_statusLabel];
        [_cardView addSubview:_messageLabel];
        [_cardView addSubview:_acceptBtn];
        [_cardView addSubview:_rejectBtn];
        [_cardView addSubview:_statusBtn];

        // cardView 撑满 contentView（上下各留 4pt 间距）
        [_cardView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView).offset(4);
            make.leading.equalTo(self.contentView).offset(12);
            make.trailing.equalTo(self.contentView).offset(-12);
            make.bottom.equalTo(self.contentView).offset(-4);
        }];

        // 右侧操作按钮：同意/拒绝 竖排，固定宽高
        [_acceptBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(_cardView).offset(-10);
            make.centerY.equalTo(_cardView).offset(-18);
            make.size.mas_equalTo(CGSizeMake(75, 30));
        }];
        [_rejectBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(_cardView).offset(-10);
            make.centerY.equalTo(_cardView).offset(18);
            make.size.mas_equalTo(CGSizeMake(75, 30));
        }];
        // 状态按钮（已添加/已过期）居中
        [_statusBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(_cardView).offset(-10);
            make.centerY.equalTo(_cardView);
            make.size.mas_equalTo(CGSizeMake(76, 30));
        }];

        // 头像：左侧固定，顶部距 cardView 12pt，固定 40×40，底部约束撑起无 message 时的最小高度
        [_avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_cardView).offset(12);
            make.top.equalTo(_cardView).offset(12);
            make.size.mas_equalTo(CGSizeMake(54, 54));
            make.bottom.lessThanOrEqualTo(_cardView).offset(-12);
        }];

        // 文字区域：头像右侧，纵向依次排列
        [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_avatarView.mas_trailing).offset(8);
            make.top.equalTo(_cardView).offset(12);
            make.trailing.lessThanOrEqualTo(_acceptBtn.mas_leading).offset(-8);
        }];
        [_idLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_nameLabel);
            make.top.equalTo(_nameLabel.mas_bottom).offset(3);
            make.trailing.lessThanOrEqualTo(_acceptBtn.mas_leading).offset(-8);
        }];
        [_statusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_nameLabel);
            make.top.equalTo(_idLabel.mas_bottom).offset(2);
            make.trailing.lessThanOrEqualTo(_acceptBtn.mas_leading).offset(-8);
        }];
        // messageLabel：在 statusLabel 下方，bottom 撑起 cardView（有内容时生效）
        [_messageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_cardView).offset(12);
            make.trailing.equalTo(_cardView).offset(-90);
            make.top.equalTo(_statusLabel.mas_bottom).offset(6);
            make.bottom.equalTo(_cardView).offset(-12);
        }];
    }
    return self;
}

- (void)configureWithName:(NSString *)name odId:(NSString *)odId statusText:(NSString *)statusText message:(NSString *)message isOnline:(BOOL)isOnline status:(FriendRequestStatus)status {
    self.nameLabel.text = name;
    self.idLabel.text = [NSString stringWithFormat:NSLocalizedString(@"community_id_format", nil), odId];
    self.statusLabel.text = statusText;
    self.statusLabel.hidden = (statusText.length == 0);
    self.statusLabel.textColor = isOnline ? [UIColor colorWithRed:0.10 green:0.70 blue:0.30 alpha:1.0] : [UIColor grayColor];
    self.messageLabel.text = message;
    self.messageLabel.hidden = (message.length == 0);

    [self.acceptBtn setTitle:NSLocalizedString(@"community_request_accept", nil) forState:UIControlStateNormal];
    [self.rejectBtn setTitle:NSLocalizedString(@"community_request_reject", nil) forState:UIControlStateNormal];
    if (@available(iOS 13.0, *)) {
        self.avatarView.image = [UIImage systemImageNamed:@"person.crop.circle.fill"];
        self.avatarView.tintColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    }
    switch (status) {
        case FriendRequestStatusPending:
            self.acceptBtn.hidden = NO;
            self.rejectBtn.hidden = NO;
            self.statusBtn.hidden = YES;
            break;
        case FriendRequestStatusExpired:
            self.acceptBtn.hidden = YES;
            self.rejectBtn.hidden = YES;
            self.statusBtn.hidden = NO;
            [self.statusBtn setTitle:NSLocalizedString(@"community_request_expired", nil) forState:UIControlStateNormal];
            [self.statusBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
            self.statusBtn.layer.borderColor = [UIColor grayColor].CGColor;
            break;
        case FriendRequestStatusAdded:
            self.acceptBtn.hidden = YES;
            self.rejectBtn.hidden = YES;
            self.statusBtn.hidden = NO;
            [self.statusBtn setTitle:NSLocalizedString(@"community_request_added", nil) forState:UIControlStateNormal];
            [self.statusBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
            self.statusBtn.layer.borderColor = [UIColor grayColor].CGColor;
            break;
    }
}
@end

@interface NewFriendRequestsViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UITextField *searchField;
@property (nonatomic, strong) UIButton *searchBtn;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<PNFriendRequest *> *recentRequests;
@property (nonatomic, strong) NSMutableArray<PNFriendRequest *> *olderRequests;
@property (nonatomic, strong) NSArray<PNFriend *> *searchCandidates;
@property (nonatomic, strong) NSArray<PNFriend *> *filteredSearchResults;
@property (nonatomic, assign) BOOL isSearching;
@end

@implementation NewFriendRequestsViewController

- (void)viewDidLoad {
    self.hidesBottomBarWhenPushed = YES;
    [self loadRemoteData];
    [super viewDidLoad];
    self.view.backgroundColor = kRequestPageBg;
    self.shouldShowNavigationBar = NO;
    // 勿再次调用 setupUI / updateLocalizedStrings：QMBaseViewController.viewDidLoad 已调用，重复会导致头部与列表叠两层
}

- (void)loadRemoteData {
    self.recentRequests = NSMutableArray.array;
    self.olderRequests = NSMutableArray.array;
    self.filteredSearchResults = @[];
    self.isSearching = NO;
    __weak typeof(self) weakSelf = self;
    [SocialRequest.shared getFriendRequestsSuccess:^(HTTPResponse * _Nullable responseObject) {
        PNFriendRequestPage *page = [responseObject.dataObject isKindOfClass:PNFriendRequestPage.class] ? responseObject.dataObject : nil;
        NSArray<PNFriendRequest *> *list = page.list ?: @[];
        weakSelf.recentRequests = list.mutableCopy;
        weakSelf.olderRequests = NSMutableArray.array;
        [weakSelf syncPendingCountWithCurrentRequests];
        [weakSelf.tableView reloadData];
    } failure:^(NSError * _Nonnull error) {
        [weakSelf.tableView reloadData];
    }];

    [SocialRequest.shared getFriendsSuccess:^(HTTPResponse * _Nullable responseObject) {
        PNFriendPage *page = [responseObject.dataObject isKindOfClass:PNFriendPage.class] ? responseObject.dataObject : nil;
        weakSelf.searchCandidates = page.list ?: @[];
    } failure:^(NSError * _Nonnull error) {
        weakSelf.searchCandidates = @[];
    }];

    [SocialRequest.shared getFriendRequestsPendingCountSuccess:^(HTTPResponse * _Nullable responseObject) {
        NSInteger count = [responseObject.dataObject respondsToSelector:@selector(integerValue)] ? [responseObject.dataObject integerValue] : 0;
        NSInteger actualPending = [weakSelf currentPendingRequestCount];
        NSInteger finalCount = actualPending >= 0 ? actualPending : MAX(count, 0);
        [weakSelf persistPendingCount:finalCount];
    } failure:^(NSError * _Nonnull error) {
    }];
}

- (NSInteger)currentPendingRequestCount {
    NSInteger count = 0;
    for (PNFriendRequest *request in self.recentRequests) {
        if ([self statusForFriendRequest:request] == FriendRequestStatusPending) {
            count += 1;
        }
    }
    for (PNFriendRequest *request in self.olderRequests) {
        if ([self statusForFriendRequest:request] == FriendRequestStatusPending) {
            count += 1;
        }
    }
    return count;
}

- (void)persistPendingCount:(NSInteger)count {
    NSInteger safeCount = MAX(count, 0);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger oldCount = [defaults integerForKey:kCommunityPendingCountKey];
    [defaults setInteger:safeCount forKey:kCommunityPendingCountKey];
    if (oldCount != safeCount) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kCommunityPendingCountDidChangeNotification object:nil];
    }
}

- (void)syncPendingCountWithCurrentRequests {
    [self persistPendingCount:[self currentPendingRequestCount]];
}

- (void)setupUI {
    self.headerView = [UIView new];
    self.headerView.backgroundColor = kRequestHeaderBg;
    [self.view addSubview:self.headerView];
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImage *backIcon = [UIImage imageNamed:@"ad_left"];
    if (!backIcon && @available(iOS 13.0, *)) {
        backIcon = [UIImage systemImageNamed:@"arrow.left"];
    }
    [backBtn setImage:backIcon forState:UIControlStateNormal];
    backBtn.tintColor = [UIColor whiteColor];
    [backBtn addTarget:self action:@selector(onBack) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView addSubview:backBtn];
    self.titleLabel = [UILabel new];
    self.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    self.titleLabel.textColor = [UIColor whiteColor];
    [self.headerView addSubview:self.titleLabel];
    UIView *searchBg = [UIView new];
    searchBg.backgroundColor = [UIColor whiteColor];
    searchBg.layer.cornerRadius = 22;
    [self.headerView addSubview:searchBg];
    UIImageView *searchIcon = [UIImageView new];
    if (@available(iOS 13.0, *)) { searchIcon.image = [UIImage systemImageNamed:@"magnifyingglass"]; searchIcon.tintColor = [UIColor grayColor]; }
    [searchBg addSubview:searchIcon];
    self.searchField = [UITextField new];
    self.searchField.font = [UIFont systemFontOfSize:14];
    self.searchField.delegate = self;
    self.searchField.returnKeyType = UIReturnKeySearch;
    [searchBg addSubview:self.searchField];
    [self applySearchFieldPlaceholderAndColors];
    self.searchBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    self.searchBtn.backgroundColor = kRequestGreen;
    self.searchBtn.layer.cornerRadius = 20;
    self.searchBtn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [self.searchBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.searchBtn addTarget:self action:@selector(onSearchTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.searchBtn setTitle:NSLocalizedString(@"community_search", nil) forState:UIControlStateNormal];
    [searchBg addSubview:self.searchBtn];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 80;
    [self.tableView registerClass:[FriendRequestCell class] forCellReuseIdentifier:@"FriendRequestCell"];
    [self.view addSubview:self.tableView];
    [self.headerView mas_makeConstraints:^(MASConstraintMaker *make) { make.top.leading.trailing.equalTo(self.view); make.height.mas_equalTo(162); }];
    [backBtn mas_makeConstraints:^(MASConstraintMaker *make) { make.leading.equalTo(self.headerView).offset(12); make.top.equalTo(self.headerView.mas_safeAreaLayoutGuideTop).offset(8); make.size.mas_equalTo(CGSizeMake(32, 32)); }];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) { make.centerX.equalTo(self.headerView); make.centerY.equalTo(backBtn); }];
    [searchBg mas_makeConstraints:^(MASConstraintMaker *make) { make.leading.equalTo(self.headerView).offset(16); make.trailing.equalTo(self.headerView).offset(-16); make.bottom.equalTo(self.headerView).offset(-15); make.height.mas_equalTo(44); }];
    [searchIcon mas_makeConstraints:^(MASConstraintMaker *make) { make.leading.equalTo(searchBg).offset(12); make.centerY.equalTo(searchBg); make.size.mas_equalTo(CGSizeMake(18, 18)); }];
    [self.searchBtn mas_makeConstraints:^(MASConstraintMaker *make) { make.trailing.equalTo(searchBg).offset(-4); make.centerY.equalTo(searchBg); make.size.mas_equalTo(CGSizeMake(77, 40)); }];
    [self.searchField mas_makeConstraints:^(MASConstraintMaker *make) { make.leading.equalTo(searchIcon.mas_trailing).offset(8); make.trailing.equalTo(self.searchBtn.mas_leading).offset(-6); make.centerY.equalTo(searchBg); }];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) { make.top.equalTo(self.headerView.mas_bottom); make.leading.trailing.bottom.equalTo(self.view); }];
}

- (void)applySearchFieldPlaceholderAndColors {
    if (!self.searchField) return;
    NSString *ph = NSLocalizedString(@"community_search_placeholder", nil);
    UIFont *font = self.searchField.font ?: [UIFont systemFontOfSize:14];
    UIColor *placeholderGreen = kRequestGreen;
    UIColor *inputBlack = [UIColor blackColor];
    self.searchField.textColor = inputBlack;
    self.searchField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:ph attributes:@{
        NSForegroundColorAttributeName: placeholderGreen,
        NSFontAttributeName: font
    }];
    self.searchField.typingAttributes = @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: inputBlack
    };
}

- (void)onBack { [self.navigationController popViewControllerAnimated:YES]; }

- (void)onSearchTapped {
    NSString *keyword = [self.searchField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (keyword.length == 0) {
        self.isSearching = NO;
        self.filteredSearchResults = @[];
    } else {
        self.isSearching = YES;
        NSMutableArray *result = [NSMutableArray array];
        NSString *lower = keyword.lowercaseString;
        for (PNFriend *item in self.searchCandidates) {
            BOOL matchId = [item.userId containsString:keyword];
            BOOL matchName = [item.nickname.lowercaseString containsString:lower];
            if (matchId || matchName) {
                [result addObject:item];
            }
        }
        self.filteredSearchResults = result;
    }
    [self.searchField resignFirstResponder];
    [self.tableView reloadData];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self onSearchTapped];
    return YES;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return self.isSearching ? 1 : 2; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.isSearching) return self.filteredSearchResults.count;
    return section == 0 ? self.recentRequests.count : self.olderRequests.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *header = [UIView new];
    header.backgroundColor = [UIColor clearColor];
    UILabel *label = [UILabel new];
    label.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    label.textColor = [UIColor blackColor];
    label.text = self.isSearching ? NSLocalizedString(@"community_week_ago", nil) : (section == 0 ? NSLocalizedString(@"community_recent_3days", nil) : NSLocalizedString(@"community_week_ago", nil));
    [header addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(header).offset(16);
        make.top.equalTo(header);
    }];
    return header;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section { return 36; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FriendRequestCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FriendRequestCell" forIndexPath:indexPath];
    if (self.isSearching) {
        PNFriend *user = self.filteredSearchResults[indexPath.row];
        [cell configureWithName:(user.nickname ?: @"-")
                           odId:(user.userId ?: @"")
                     statusText:(user.online ? NSLocalizedString(@"community_online_15m", nil) : NSLocalizedString(@"community_online_5m_ago", nil))
                        message:@""
                       isOnline:user.online
                         status:FriendRequestStatusAdded];
        cell.acceptBtn.hidden = YES;
        cell.rejectBtn.hidden = YES;
        cell.statusBtn.hidden = NO;
        [cell.statusBtn setTitle:NSLocalizedString(@"community_request_added", nil) forState:UIControlStateNormal];
        [cell.statusBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        cell.statusBtn.layer.borderColor = [UIColor grayColor].CGColor;
        return cell;
    }
    NSInteger tag = indexPath.section * 1000 + indexPath.row;
    PNFriendRequest *request = (indexPath.section == 0 ? self.recentRequests : self.olderRequests)[indexPath.row];
    FriendRequestStatus status = [self statusForFriendRequest:request];
    [cell configureWithName:(request.fromUserNickname ?: @"-")
                       odId:(request.fromUserId ?: @"")
                 statusText:@""
                    message:(request.message ?: @"")
                   isOnline:NO
                     status:status];
    cell.acceptBtn.tag = tag;
    cell.rejectBtn.tag = tag;
    [cell.acceptBtn removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [cell.rejectBtn removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [cell.acceptBtn addTarget:self action:@selector(onAcceptTapped:) forControlEvents:UIControlEventTouchUpInside];
    [cell.rejectBtn addTarget:self action:@selector(onRejectTapped:) forControlEvents:UIControlEventTouchUpInside];
    return cell;
}

- (void)onAcceptTapped:(UIButton *)sender {
    [self updateRequestWithTag:sender.tag accept:YES];
}

- (void)onRejectTapped:(UIButton *)sender {
    [self updateRequestWithTag:sender.tag accept:NO];
}

- (void)updateRequestWithTag:(NSInteger)tag accept:(BOOL)accept {
    NSInteger section = tag / 1000;
    NSInteger row = tag % 1000;
    NSMutableArray<PNFriendRequest *> *arr = section == 0 ? self.recentRequests : self.olderRequests;
    if (row < 0 || row >= arr.count) return;
    PNFriendRequest *request = arr[row];
    if ([self statusForFriendRequest:request] != FriendRequestStatusPending) return;
    __weak typeof(self) weakSelf = self;
    [SocialRequest.shared processFriendRequest:request.requestId accept:accept success:^(HTTPResponse * _Nullable responseObject) {
        if (accept) {
            [weakSelf addFriendToCommunityList:request];
        }
        [arr removeObjectAtIndex:row];
        [weakSelf decreasePendingCountIfNeeded];
        [weakSelf.tableView reloadData];
    } failure:^(NSError * _Nonnull error) {
    }];
}

- (void)decreasePendingCountIfNeeded {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger count = [defaults integerForKey:kCommunityPendingCountKey];
    if (count > 0) {
        count -= 1;
        [defaults setInteger:count forKey:kCommunityPendingCountKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:kCommunityPendingCountDidChangeNotification object:nil];
    }
}

- (void)addFriendToCommunityList:(PNFriendRequest *)request {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *raw = [defaults arrayForKey:kCommunityAddedFriendsKey];
    NSMutableArray *arr = raw ? [raw mutableCopy] : [NSMutableArray array];
    NSDictionary *item = @{
        @"name": request.fromUserNickname ?: NSLocalizedString(@"team_name_arsenal", nil),
        @"odId": request.fromUserId ?: @"12653795",
        @"statusText": NSLocalizedString(@"community_online_5m_ago", nil),
        @"isOnline": @NO
    };
    [arr insertObject:item atIndex:0];
    [defaults setObject:arr forKey:kCommunityAddedFriendsKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:kCommunityFriendsDidChangeNotification object:nil];
}

- (FriendRequestStatus)statusForFriendRequest:(PNFriendRequest *)request {
    NSString *status = request.status ?: @"PENDING";
    if ([status isEqualToString:@"EXPIRED"]) return FriendRequestStatusExpired;
    if ([status isEqualToString:@"ACCEPTED"]) return FriendRequestStatusAdded;
    return FriendRequestStatusPending;
}

- (void)updateLocalizedStrings {
    [super updateLocalizedStrings];
    self.titleLabel.text = NSLocalizedString(@"community_new_friends", nil);
    [self applySearchFieldPlaceholderAndColors];
    [self.searchBtn setTitle:NSLocalizedString(@"community_search", nil) forState:UIControlStateNormal];
    [self.tableView reloadData];
}

@end
