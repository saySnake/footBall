//
//  AddFriendViewController.m
//  footBall
//

#import "AddFriendViewController.h"
#import "NewFriendRequestsViewController.h"
#import <Masonry/Masonry.h>
#import "ColorManager.h"

#define kAddFriendGreen    [ColorManager sharedManager].primaryColor
#define kAddFriendHeaderBg [ColorManager sharedManager].primaryDarkColor
#define kAddFriendPageBg   [ColorManager sharedManager].secondaryBackgroundColor
static NSString * const kCommunityPendingCountKey = @"community_pending_count";
static NSString * const kCommunitySentSearchFriendIdsKey = @"community_sent_search_friend_ids";

@interface SearchResultCell : UITableViewCell
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *idLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIButton *addBtn;
- (void)configureWithResult:(PNUser *)r;
@end

@implementation SearchResultCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        _cardView = [UIView new];
        _cardView.backgroundColor = [UIColor whiteColor];
        _cardView.layer.cornerRadius = 8;
        _avatarView = [UIImageView new];
        _avatarView.layer.cornerRadius = 20;
        _avatarView.clipsToBounds = YES;
        _nameLabel = [UILabel new];
        _nameLabel.font = [UIFont boldSystemFontOfSize:15];
        _idLabel = [UILabel new];
        _idLabel.font = [UIFont systemFontOfSize:12];
        _idLabel.textColor = [UIColor grayColor];
        _statusLabel = [UILabel new];
        _statusLabel.font = [UIFont systemFontOfSize:11];
        _addBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _addBtn.layer.cornerRadius = 14;
        _addBtn.layer.borderWidth = 1;
        _addBtn.layer.borderColor = [UIColor colorWithWhite:0.75 alpha:1.0].CGColor;
        _addBtn.titleLabel.font = [UIFont systemFontOfSize:12];
        [_addBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_addBtn setTitle:NSLocalizedString(@"community_add_friend", nil) forState:UIControlStateNormal];
        [self.contentView addSubview:_cardView];
        [_cardView addSubview:_avatarView];
        [_cardView addSubview:_nameLabel];
        [_cardView addSubview:_idLabel];
        [_cardView addSubview:_statusLabel];
        [_cardView addSubview:_addBtn];
        [_cardView mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(4, 12, 4, 12)); }];
        [_avatarView mas_makeConstraints:^(MASConstraintMaker *make) { make.leading.equalTo(_cardView).offset(10); make.centerY.equalTo(_cardView); make.size.mas_equalTo(CGSizeMake(40, 40)); }];
        [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) { make.leading.equalTo(_avatarView.mas_trailing).offset(10); make.top.equalTo(_cardView).offset(9); }];
        [_idLabel mas_makeConstraints:^(MASConstraintMaker *make) { make.leading.equalTo(_nameLabel); make.top.equalTo(_nameLabel.mas_bottom).offset(1); }];
        [_statusLabel mas_makeConstraints:^(MASConstraintMaker *make) { make.leading.equalTo(_nameLabel); make.top.equalTo(_idLabel.mas_bottom).offset(1); }];
        [_addBtn mas_makeConstraints:^(MASConstraintMaker *make) { make.trailing.equalTo(_cardView).offset(-10); make.centerY.equalTo(_cardView); make.size.mas_equalTo(CGSizeMake(74, 28)); }];
    }
    return self;
}
- (void)configureWithResult:(PNUser *)r {
    _nameLabel.text = r.nickname;
    _idLabel.text = [NSString stringWithFormat:NSLocalizedString(@"community_id_format", nil), r.userId];
    _statusLabel.text = r.lastOnlineTime.length > 0 ? NSLocalizedString(@"community_online_15m", nil) : NSLocalizedString(@"community_online_5m_ago", nil);
    _statusLabel.textColor = r.lastOnlineTime.length > 0 ? [UIColor colorWithRed:0.10 green:0.70 blue:0.30 alpha:1.0] : [UIColor grayColor];
    if (@available(iOS 13.0, *)) { _avatarView.image = [UIImage systemImageNamed:@"person.crop.circle.fill"]; _avatarView.tintColor = [UIColor colorWithWhite:0.7 alpha:1.0]; }
}
@end

@interface MenuItemCell : UITableViewCell
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIView *badgeView;
@property (nonatomic, strong) UILabel *badgeLabel;
@end

@implementation MenuItemCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        _cardView = [UIView new];
        _cardView.backgroundColor = [UIColor whiteColor];
        _cardView.layer.cornerRadius = 8;
        _iconView = [UIImageView new];
        _iconView.tintColor = [UIColor darkGrayColor];
        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont boldSystemFontOfSize:15];
        _subtitleLabel = [UILabel new];
        _subtitleLabel.font = [UIFont systemFontOfSize:12];
        _subtitleLabel.textColor = [UIColor grayColor];
        _badgeView = [UIView new];
        _badgeView.backgroundColor = [UIColor colorWithRed:0.95 green:0.25 blue:0.24 alpha:1.0];
        _badgeView.layer.cornerRadius = 9;
        _badgeLabel = [UILabel new];
        _badgeLabel.font = [UIFont boldSystemFontOfSize:11];
        _badgeLabel.textColor = [UIColor whiteColor];
        [_badgeView addSubview:_badgeLabel];
        UIImageView *arrow = [UIImageView new];
        if (@available(iOS 13.0, *)) { arrow.image = [UIImage systemImageNamed:@"chevron.right"]; arrow.tintColor = [UIColor lightGrayColor]; }
        [self.contentView addSubview:_cardView];
        [_cardView addSubview:_iconView];
        [_cardView addSubview:_titleLabel];
        [_cardView addSubview:_subtitleLabel];
        [_cardView addSubview:_badgeView];
        [_cardView addSubview:arrow];
        [_cardView mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(6, 12, 6, 12)); }];
        [_iconView mas_makeConstraints:^(MASConstraintMaker *make) { make.leading.equalTo(_cardView).offset(12); make.centerY.equalTo(_cardView); make.size.mas_equalTo(CGSizeMake(30, 30)); }];
        [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) { make.leading.equalTo(_iconView.mas_trailing).offset(10); make.top.equalTo(_cardView).offset(12); }];
        [_badgeView mas_makeConstraints:^(MASConstraintMaker *make) { make.leading.equalTo(_titleLabel.mas_trailing).offset(6); make.centerY.equalTo(_titleLabel); make.height.mas_equalTo(18); make.width.mas_greaterThanOrEqualTo(18); }];
        [_badgeLabel mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(_badgeView).insets(UIEdgeInsetsMake(2, 5, 2, 5)); }];
        [_subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) { make.leading.equalTo(_titleLabel); make.top.equalTo(_titleLabel.mas_bottom).offset(2); }];
        [arrow mas_makeConstraints:^(MASConstraintMaker *make) { make.trailing.equalTo(_cardView).offset(-12); make.centerY.equalTo(_cardView); make.size.mas_equalTo(CGSizeMake(14, 14)); }];
    }
    return self;
}
@end

@interface AddFriendViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UITextField *searchField;
@property (nonatomic, strong) UIButton *searchBtn;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<PNUser *> *searchResults;
@property (nonatomic, strong) NSArray<PNUser *> *searchPool;
@property (nonatomic, strong) NSMutableSet<NSString *> *sentFriendIds;
@property (nonatomic, assign) BOOL isSearching;
@property (nonatomic, assign) NSInteger pendingRequestCount;
@end

@implementation AddFriendViewController

- (void)viewDidLoad {
    self.hidesBottomBarWhenPushed = YES;
    NSInteger storedCount = [[NSUserDefaults standardUserDefaults] integerForKey:kCommunityPendingCountKey];
    self.pendingRequestCount = storedCount > 0 ? storedCount : 23;
    NSArray *sentIds = [[NSUserDefaults standardUserDefaults] arrayForKey:kCommunitySentSearchFriendIdsKey];
    self.sentFriendIds = [NSMutableSet setWithArray:(sentIds ?: @[])];
    [self buildSearchPool];
    [super viewDidLoad];
    self.view.backgroundColor = kAddFriendPageBg;
    self.shouldShowNavigationBar = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSInteger storedCount = [[NSUserDefaults standardUserDefaults] integerForKey:kCommunityPendingCountKey];
    self.pendingRequestCount = MAX(0, storedCount);
    if (!self.isSearching) {
        [self.tableView reloadData];
    }
}

- (void)setupUI {
    self.headerView = [UIView new];
    self.headerView.backgroundColor = kAddFriendHeaderBg;
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
    self.searchBtn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [self.searchBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.searchBtn.backgroundColor = kAddFriendGreen;
    self.searchBtn.layer.cornerRadius = 18;
    [self.searchBtn addTarget:self action:@selector(onSearch) forControlEvents:UIControlEventTouchUpInside];
    [searchBg addSubview:self.searchBtn];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:[MenuItemCell class] forCellReuseIdentifier:@"MenuItemCell"];
    [self.tableView registerClass:[SearchResultCell class] forCellReuseIdentifier:@"SearchResultCell"];
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

- (void)onSearch {
    NSString *text = [self.searchField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (text.length == 0) {
        self.isSearching = NO;
        self.searchResults = @[];
    } else {
        self.isSearching = YES;
        NSMutableArray *arr = [NSMutableArray arrayWithCapacity:self.searchPool.count];
        NSString *lower = text.lowercaseString;
        for (PNUser *r in self.searchPool) {
            BOOL matchId = [r.userId containsString:text];
            BOOL matchName = [r.nickname.lowercaseString containsString:lower];
            if (matchId || matchName) {
                [arr addObject:r];
            }
        }
        self.searchResults = arr;
    }
    [self.searchField resignFirstResponder];
    [self.tableView reloadData];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self onSearch];
    return YES;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.isSearching ? self.searchResults.count : 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.isSearching ? 74 : 78;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (!self.isSearching) return nil;
    UIView *header = [UIView new];
    header.backgroundColor = [UIColor clearColor];
    UILabel *label = [UILabel new];
    label.font = [UIFont boldSystemFontOfSize:14];
    label.text = [NSString stringWithFormat:NSLocalizedString(@"community_search_result_format", nil), (long)self.searchResults.count];
    [header addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) { make.leading.equalTo(header).offset(14); make.centerY.equalTo(header); }];
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return self.isSearching ? 28 : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isSearching) {
        SearchResultCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SearchResultCell" forIndexPath:indexPath];
        PNUser *result = self.searchResults[indexPath.row];
        [cell configureWithResult:result];
        BOOL sent = [self.sentFriendIds containsObject:result.userId];
        NSString *title = sent ? NSLocalizedString(@"community_request_sent", nil) : NSLocalizedString(@"community_add_friend", nil);
        [cell.addBtn setTitle:title forState:UIControlStateNormal];
        [cell.addBtn setTitleColor:(sent ? [UIColor grayColor] : [UIColor blackColor]) forState:UIControlStateNormal];
        cell.addBtn.layer.borderColor = (sent ? [UIColor lightGrayColor].CGColor : [UIColor colorWithWhite:0.75 alpha:1.0].CGColor);
        cell.addBtn.enabled = YES;
        cell.addBtn.tag = indexPath.row;
        [cell.addBtn removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
        [cell.addBtn addTarget:self action:@selector(onAddSearchFriendTapped:) forControlEvents:UIControlEventTouchUpInside];
        return cell;
    }
    MenuItemCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MenuItemCell" forIndexPath:indexPath];
    if (indexPath.row == 0) {
        if (@available(iOS 13.0, *)) cell.iconView.image = [UIImage systemImageNamed:@"person.2"];
        cell.titleLabel.text = NSLocalizedString(@"community_new_friends", nil);
        cell.subtitleLabel.text = NSLocalizedString(@"community_new_friends_subtitle", nil);
        cell.badgeView.hidden = NO;
        cell.badgeLabel.text = [NSString stringWithFormat:@"%ld", (long)self.pendingRequestCount];
    } else {
        if (@available(iOS 13.0, *)) cell.iconView.image = [UIImage systemImageNamed:@"qrcode.viewfinder"];
        cell.titleLabel.text = NSLocalizedString(@"community_scan_add_friend", nil);
        cell.subtitleLabel.text = NSLocalizedString(@"community_scan_add_friend_subtitle", nil);
        cell.badgeView.hidden = YES;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.isSearching && indexPath.row == 0) {
        NewFriendRequestsViewController *vc = [[NewFriendRequestsViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)updateLocalizedStrings {
    [super updateLocalizedStrings];
    self.titleLabel.text = NSLocalizedString(@"community_add_friend", nil);
    self.searchField.placeholder = NSLocalizedString(@"community_search_placeholder", nil);
    [self.searchBtn setTitle:NSLocalizedString(@"community_search", nil) forState:UIControlStateNormal];
    [self.tableView reloadData];
}

- (void)buildSearchPool {
    PNUser *a = [PNUser yy_modelWithJSON:@{@"nickname": NSLocalizedString(@"team_name_arsenal", nil), @"userId": @"12653795", @"lastOnlineTime": @"1"}];
    PNUser *b = [PNUser yy_modelWithJSON:@{@"nickname": NSLocalizedString(@"team_name_mancity", nil), @"userId": @"521467395", @"lastOnlineTime": @""}];
    PNUser *c = [PNUser yy_modelWithJSON:@{@"nickname": NSLocalizedString(@"team_name_liverpool", nil), @"userId": @"912653795", @"lastOnlineTime": @"1"}];
    PNUser *d = [PNUser yy_modelWithJSON:@{@"nickname": NSLocalizedString(@"team_name_chelsea", nil), @"userId": @"770034821", @"lastOnlineTime": @""}];
    PNUser *e = [PNUser yy_modelWithJSON:@{@"nickname": NSLocalizedString(@"team_name_spurs", nil), @"userId": @"300198426", @"lastOnlineTime": @"1"}];
    PNUser *f = [PNUser yy_modelWithJSON:@{@"nickname": NSLocalizedString(@"team_name_manutd", nil), @"userId": @"450762190", @"lastOnlineTime": @""}];
    self.searchPool = @[a, b, c, d, e, f];
}

- (void)onAddSearchFriendTapped:(UIButton *)sender {
    if (sender.tag < 0 || sender.tag >= self.searchResults.count) return;
    PNUser *result = self.searchResults[sender.tag];
    if ([self.sentFriendIds containsObject:result.userId]) {
        [self showSuccess:NSLocalizedString(@"community_request_sent", nil)];
        return;
    }
    [self.sentFriendIds addObject:result.userId];
    [[NSUserDefaults standardUserDefaults] setObject:self.sentFriendIds.allObjects forKey:kCommunitySentSearchFriendIdsKey];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:sender.tag inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    [self showSuccess:NSLocalizedString(@"community_request_sent", nil)];
}

@end
