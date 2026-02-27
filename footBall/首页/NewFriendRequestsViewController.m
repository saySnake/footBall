//
//  NewFriendRequestsViewController.m
//  footBall
//

#import "NewFriendRequestsViewController.h"
#import <Masonry/Masonry.h>

#define kRequestGreen [UIColor colorWithRed:0.10 green:0.36 blue:0.28 alpha:1.0]
#define kRequestHeaderBg [UIColor colorWithRed:0.02 green:0.14 blue:0.15 alpha:1.0]
#define kRequestRed [UIColor colorWithRed:0.95 green:0.20 blue:0.20 alpha:1.0]
#define kRequestPageBg [UIColor colorWithWhite:0.94 alpha:1.0]
static NSString * const kCommunityPendingCountKey = @"community_pending_count";
static NSString * const kCommunityPendingCountDidChangeNotification = @"community_pending_count_did_change";
static NSString * const kCommunityAddedFriendsKey = @"community_added_friends";
static NSString * const kCommunityFriendsDidChangeNotification = @"community_friends_did_change";

typedef NS_ENUM(NSInteger, FriendRequestStatus) {
    FriendRequestStatusPending,
    FriendRequestStatusExpired,
    FriendRequestStatusAdded
};

@interface FriendRequest : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *odId;
@property (nonatomic, copy) NSString *statusText;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, assign) BOOL isOnline;
@property (nonatomic, assign) FriendRequestStatus status;
@end
@implementation FriendRequest
@end

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
- (void)configureWithRequest:(FriendRequest *)r;
@end

@implementation FriendRequestCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _cardView = [UIView new];
        _cardView.backgroundColor = [UIColor whiteColor];
        _cardView.layer.cornerRadius = 8;
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
        _acceptBtn.layer.cornerRadius = 14;
        _acceptBtn.backgroundColor = kRequestGreen;
        _acceptBtn.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        [_acceptBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

        _rejectBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _rejectBtn.layer.cornerRadius = 14;
        _rejectBtn.backgroundColor = kRequestRed;
        _rejectBtn.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        [_rejectBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

        _statusBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _statusBtn.layer.cornerRadius = 14;
        _statusBtn.layer.borderWidth = 1;
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
            make.size.mas_equalTo(CGSizeMake(56, 28));
        }];
        [_rejectBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(_cardView).offset(-10);
            make.centerY.equalTo(_cardView).offset(18);
            make.size.mas_equalTo(CGSizeMake(56, 28));
        }];
        // 状态按钮（已添加/已过期）居中
        [_statusBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(_cardView).offset(-10);
            make.centerY.equalTo(_cardView);
            make.size.mas_equalTo(CGSizeMake(64, 28));
        }];

        // 头像：左侧固定，顶部距 cardView 12pt，固定 40×40，底部约束撑起无 message 时的最小高度
        [_avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_cardView).offset(12);
            make.top.equalTo(_cardView).offset(12);
            make.size.mas_equalTo(CGSizeMake(40, 40));
            make.bottom.lessThanOrEqualTo(_cardView).offset(-12);
        }];

        // 文字区域：头像右侧，纵向依次排列
        [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_avatarView.mas_trailing).offset(10);
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
            make.leading.equalTo(_avatarView.mas_trailing).offset(10);
            make.trailing.equalTo(_cardView).offset(-80);
            make.top.equalTo(_statusLabel.mas_bottom).offset(6);
            make.bottom.equalTo(_cardView).offset(-12);
        }];
    }
    return self;
}

- (void)configureWithRequest:(FriendRequest *)r {
    self.nameLabel.text = r.name;
    self.idLabel.text = [NSString stringWithFormat:NSLocalizedString(@"community_id_format", nil), r.odId];
    self.statusLabel.text = r.statusText;
    self.statusLabel.hidden = (r.statusText.length == 0);
    self.statusLabel.textColor = r.isOnline ? [UIColor colorWithRed:0.10 green:0.70 blue:0.30 alpha:1.0] : [UIColor grayColor];
    self.messageLabel.text = r.message;
    self.messageLabel.hidden = (r.message.length == 0);

    [self.acceptBtn setTitle:NSLocalizedString(@"community_request_accept", nil) forState:UIControlStateNormal];
    [self.rejectBtn setTitle:NSLocalizedString(@"community_request_reject", nil) forState:UIControlStateNormal];
    if (@available(iOS 13.0, *)) {
        self.avatarView.image = [UIImage systemImageNamed:@"person.crop.circle.fill"];
        self.avatarView.tintColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    }
    switch (r.status) {
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
@property (nonatomic, strong) NSMutableArray<FriendRequest *> *recentRequests;
@property (nonatomic, strong) NSMutableArray<FriendRequest *> *olderRequests;
@property (nonatomic, strong) NSArray<FriendRequest *> *searchCandidates;
@property (nonatomic, strong) NSArray<FriendRequest *> *filteredSearchResults;
@property (nonatomic, assign) BOOL isSearching;
@end

@implementation NewFriendRequestsViewController

- (void)viewDidLoad {
    self.hidesBottomBarWhenPushed = YES;
    [self loadFakeData];
    [super viewDidLoad];
    self.view.backgroundColor = kRequestPageBg;
    self.shouldShowNavigationBar = NO;
}

- (void)loadFakeData {
    // 三天内：第一条有留言，第二条无留言（仅在线状态）
    FriendRequest *a = [FriendRequest new];
    a.name = @"Marcus Chen"; a.odId = @"10234567";
    a.message = NSLocalizedString(@"community_request_message", nil);
    a.status = FriendRequestStatusPending;

    FriendRequest *b = [FriendRequest new];
    b.name = @"James Walker"; b.odId = @"20384951";
    b.statusText = NSLocalizedString(@"community_online_15m", nil); b.isOnline = YES;
    b.status = FriendRequestStatusPending;

    // 一周前
    FriendRequest *c = [FriendRequest new];
    c.name = @"Sophie Turner"; c.odId = @"30192847";
    c.message = NSLocalizedString(@"community_request_message", nil);
    c.status = FriendRequestStatusPending;

    FriendRequest *d = [FriendRequest new];
    d.name = @"Kevin Hart"; d.odId = @"40283756";
    d.message = NSLocalizedString(@"community_request_message", nil);
    d.status = FriendRequestStatusExpired;

    FriendRequest *e = [FriendRequest new];
    e.name = @"Lily Zhang"; e.odId = @"50192736";
    e.statusText = NSLocalizedString(@"community_online_15m", nil); e.isOnline = YES;
    e.status = FriendRequestStatusAdded;

    self.recentRequests = [NSMutableArray arrayWithArray:@[a, b]];
    self.olderRequests = [NSMutableArray arrayWithArray:@[c, d, e]];

    // 搜索候选池
    FriendRequest *s1 = [FriendRequest new];
    s1.name = @"Marcus Chen"; s1.odId = @"10234567";
    s1.statusText = NSLocalizedString(@"community_online_15m", nil); s1.isOnline = YES;
    s1.status = FriendRequestStatusAdded;

    FriendRequest *s2 = [FriendRequest new];
    s2.name = @"James Walker"; s2.odId = @"20384951";
    s2.statusText = NSLocalizedString(@"community_online_5m_ago", nil); s2.isOnline = NO;
    s2.status = FriendRequestStatusAdded;

    FriendRequest *s3 = [FriendRequest new];
    s3.name = @"Sophie Turner"; s3.odId = @"30192847";
    s3.statusText = NSLocalizedString(@"community_online_15m", nil); s3.isOnline = YES;
    s3.status = FriendRequestStatusAdded;

    FriendRequest *s4 = [FriendRequest new];
    s4.name = @"Kevin Hart"; s4.odId = @"40283756";
    s4.statusText = NSLocalizedString(@"community_online_5m_ago", nil); s4.isOnline = NO;
    s4.status = FriendRequestStatusAdded;

    self.searchCandidates = @[s1, s2, s3, s4];
    self.filteredSearchResults = @[];
    self.isSearching = NO;
}

- (void)setupUI {
    self.headerView = [UIView new];
    self.headerView.backgroundColor = kRequestHeaderBg;
    [self.view addSubview:self.headerView];
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    if (@available(iOS 13.0, *)) [backBtn setImage:[UIImage systemImageNamed:@"arrow.left"] forState:UIControlStateNormal];
    backBtn.tintColor = [UIColor whiteColor];
    [backBtn addTarget:self action:@selector(onBack) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView addSubview:backBtn];
    self.titleLabel = [UILabel new];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:30];
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
    self.searchBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    self.searchBtn.backgroundColor = kRequestGreen;
    self.searchBtn.layer.cornerRadius = 18;
    self.searchBtn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [self.searchBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.searchBtn addTarget:self action:@selector(onSearchTapped) forControlEvents:UIControlEventTouchUpInside];
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
    [self.headerView mas_makeConstraints:^(MASConstraintMaker *make) { make.top.leading.trailing.equalTo(self.view); make.height.mas_equalTo(148); }];
    [backBtn mas_makeConstraints:^(MASConstraintMaker *make) { make.leading.equalTo(self.headerView).offset(12); make.top.equalTo(self.headerView.mas_safeAreaLayoutGuideTop).offset(8); make.size.mas_equalTo(CGSizeMake(32, 32)); }];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) { make.centerX.equalTo(self.headerView); make.centerY.equalTo(backBtn); }];
    [searchBg mas_makeConstraints:^(MASConstraintMaker *make) { make.leading.equalTo(self.headerView).offset(12); make.trailing.equalTo(self.headerView).offset(-12); make.bottom.equalTo(self.headerView).offset(-12); make.height.mas_equalTo(44); }];
    [searchIcon mas_makeConstraints:^(MASConstraintMaker *make) { make.leading.equalTo(searchBg).offset(12); make.centerY.equalTo(searchBg); make.size.mas_equalTo(CGSizeMake(18, 18)); }];
    [self.searchBtn mas_makeConstraints:^(MASConstraintMaker *make) { make.trailing.equalTo(searchBg).offset(-4); make.centerY.equalTo(searchBg); make.size.mas_equalTo(CGSizeMake(58, 36)); }];
    [self.searchField mas_makeConstraints:^(MASConstraintMaker *make) { make.leading.equalTo(searchIcon.mas_trailing).offset(8); make.trailing.equalTo(self.searchBtn.mas_leading).offset(-6); make.centerY.equalTo(searchBg); }];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) { make.top.equalTo(self.headerView.mas_bottom).offset(8); make.leading.trailing.bottom.equalTo(self.view); }];
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
        for (FriendRequest *item in self.searchCandidates) {
            BOOL matchId = [item.odId containsString:keyword];
            BOOL matchName = [item.name.lowercaseString containsString:lower];
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
    label.font = [UIFont boldSystemFontOfSize:14];
    label.text = self.isSearching ? NSLocalizedString(@"community_week_ago", nil) : (section == 0 ? NSLocalizedString(@"community_recent_3days", nil) : NSLocalizedString(@"community_week_ago", nil));
    [header addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) { make.leading.equalTo(header).offset(14); make.centerY.equalTo(header); }];
    return header;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section { return 30; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FriendRequestCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FriendRequestCell" forIndexPath:indexPath];
    FriendRequest *request = self.isSearching ? self.filteredSearchResults[indexPath.row] : (indexPath.section == 0 ? self.recentRequests : self.olderRequests)[indexPath.row];
    [cell configureWithRequest:request];
    if (self.isSearching) {
        cell.acceptBtn.hidden = YES;
        cell.rejectBtn.hidden = YES;
        cell.statusBtn.hidden = NO;
        [cell.statusBtn setTitle:NSLocalizedString(@"community_request_added", nil) forState:UIControlStateNormal];
        [cell.statusBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        cell.statusBtn.layer.borderColor = [UIColor grayColor].CGColor;
        return cell;
    }
    NSInteger tag = indexPath.section * 1000 + indexPath.row;
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
    NSMutableArray<FriendRequest *> *arr = section == 0 ? self.recentRequests : self.olderRequests;
    if (row < 0 || row >= arr.count) return;
    FriendRequest *request = arr[row];
    if (request.status != FriendRequestStatusPending) return;
    if (accept) {
        [self addFriendToCommunityList:request];
    }
    [arr removeObjectAtIndex:row];
    [self decreasePendingCountIfNeeded];
    [self.tableView reloadData];
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

- (void)addFriendToCommunityList:(FriendRequest *)request {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *raw = [defaults arrayForKey:kCommunityAddedFriendsKey];
    NSMutableArray *arr = raw ? [raw mutableCopy] : [NSMutableArray array];
    NSDictionary *item = @{
        @"name": request.name ?: NSLocalizedString(@"team_name_arsenal", nil),
        @"odId": request.odId ?: @"12653795",
        @"statusText": NSLocalizedString(@"community_online_5m_ago", nil),
        @"isOnline": @NO
    };
    [arr insertObject:item atIndex:0];
    [defaults setObject:arr forKey:kCommunityAddedFriendsKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:kCommunityFriendsDidChangeNotification object:nil];
}

- (void)updateLocalizedStrings {
    [super updateLocalizedStrings];
    self.titleLabel.text = NSLocalizedString(@"community_new_friends", nil);
    self.searchField.placeholder = NSLocalizedString(@"community_search_placeholder", nil);
    [self.searchBtn setTitle:NSLocalizedString(@"community_search", nil) forState:UIControlStateNormal];
    [self.tableView reloadData];
}

@end
