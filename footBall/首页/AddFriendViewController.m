//
//  AddFriendViewController.m
//  footBall
//

#import "AddFriendViewController.h"
#import "NewFriendRequestsViewController.h"
#import <Masonry/Masonry.h>
#import "ColorManager.h"
#import "SocialRequest.h"
#import <SDWebImage/SDWebImage.h>

#define kAddFriendGreen    [UIColor colorWithRed:0.157 green:0.365 blue:0.294 alpha:1.0] // #285D4B
#define kAddFriendHeaderBg [UIColor colorWithRed:0.051 green:0.129 blue:0.133 alpha:1.0] // #0D2122
#define kAddFriendPageBg   [UIColor colorWithRed:0.969 green:0.969 blue:0.969 alpha:1.0] // #F7F7F7
static NSString * const kCommunityPendingCountKey = @"community_pending_count";
static NSString * const kCommunitySentSearchFriendIdsKey = @"community_sent_search_friend_ids";

@interface SearchResultCell : UITableViewCell
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *idLabel;
@property (nonatomic, strong) UIView *statusDot;
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
        _cardView.layer.cornerRadius = 6;
        _avatarView = [UIImageView new];
        _avatarView.layer.cornerRadius = 24;
        _avatarView.clipsToBounds = YES;
        _nameLabel = [UILabel new];
        _nameLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        _nameLabel.textColor = [UIColor blackColor];
        _idLabel = [UILabel new];
        _idLabel.font = [UIFont systemFontOfSize:12];
        _idLabel.textColor = [UIColor blackColor];
        _statusDot = [UIView new];
        _statusDot.layer.cornerRadius = 4;
        _statusDot.backgroundColor = [UIColor colorWithWhite:0.65 alpha:1.0];
        _statusLabel = [UILabel new];
        _statusLabel.font = [UIFont systemFontOfSize:10];
        _addBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _addBtn.layer.cornerRadius = 15;
        _addBtn.layer.borderWidth = 0.6;
        _addBtn.layer.borderColor = kAddFriendHeaderBg.CGColor;
        _addBtn.titleLabel.font = [UIFont systemFontOfSize:12];
        [_addBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_addBtn setTitle:NSLocalizedString(@"community_add_friend", nil) forState:UIControlStateNormal];
        [self.contentView addSubview:_cardView];
        [_cardView addSubview:_avatarView];
        [_cardView addSubview:_nameLabel];
        [_cardView addSubview:_idLabel];
        [_cardView addSubview:_statusDot];
        [_cardView addSubview:_statusLabel];
        [_cardView addSubview:_addBtn];
        [_cardView mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(5, 18, 5, 14)); }];
        [_avatarView mas_makeConstraints:^(MASConstraintMaker *make) { make.leading.equalTo(_cardView).offset(10); make.centerY.equalTo(_cardView); make.size.mas_equalTo(CGSizeMake(48, 48)); }];
        [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) { make.leading.equalTo(_avatarView.mas_trailing).offset(10); make.top.equalTo(_cardView).offset(9); }];
        [_idLabel mas_makeConstraints:^(MASConstraintMaker *make) { make.leading.equalTo(_nameLabel); make.top.equalTo(_nameLabel.mas_bottom).offset(1); }];
        [_statusDot mas_makeConstraints:^(MASConstraintMaker *make) { make.leading.equalTo(_nameLabel); make.top.equalTo(_idLabel.mas_bottom).offset(5); make.size.mas_equalTo(CGSizeMake(8, 8)); }];
        [_statusLabel mas_makeConstraints:^(MASConstraintMaker *make) { make.leading.equalTo(_statusDot.mas_trailing).offset(6); make.centerY.equalTo(_statusDot); }];
        [_addBtn mas_makeConstraints:^(MASConstraintMaker *make) { make.trailing.equalTo(_cardView).offset(-12); make.centerY.equalTo(_cardView); make.size.mas_equalTo(CGSizeMake(76, 30)); }];
    }
    return self;
}
- (void)configureWithResult:(PNUser *)r {
    _nameLabel.text = r.nickname;
    _idLabel.text = [NSString stringWithFormat:NSLocalizedString(@"community_id_format", nil), r.userId];
    _statusLabel.text = r.lastOnlineTime.length > 0 ? NSLocalizedString(@"community_online_15m", nil) : NSLocalizedString(@"community_online_5m_ago", nil);
    _statusLabel.textColor = r.lastOnlineTime.length > 0 ? [UIColor colorWithRed:0.10 green:0.70 blue:0.30 alpha:1.0] : [UIColor grayColor];
    BOOL online = (r.lastOnlineTime.length > 0);
    _statusDot.backgroundColor = online ? [UIColor colorWithRed:0.0 green:0.71 blue:0.12 alpha:1.0] : [UIColor colorWithWhite:0.65 alpha:1.0];
    NSURL *url = r.avatar.length > 0 ? [NSURL URLWithString:r.avatar] : nil;
    UIImage *placeholder = (@available(iOS 13.0, *)) ? [UIImage systemImageNamed:@"person.crop.circle.fill"] : nil;
    [_avatarView sd_setImageWithURL:url placeholderImage:placeholder];
    if (!_avatarView.image && @available(iOS 13.0, *)) { _avatarView.tintColor = [UIColor colorWithWhite:0.7 alpha:1.0]; _avatarView.contentMode = UIViewContentModeCenter; } else { _avatarView.contentMode = UIViewContentModeScaleAspectFill; }
}
@end

@interface MenuItemCell : UITableViewCell
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIView *iconBg;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UIStackView *titleRowStack;
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
        _cardView.layer.masksToBounds = YES;
        _iconBg = [UIView new];
        _iconBg.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
        _iconBg.layer.cornerRadius = 22.5;
        _iconView = [UIImageView new];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        _iconView.tintColor = [UIColor blackColor];
        _titleLabel = [UILabel new];
        _titleLabel.font = [FontManager fontOfSize:14];
        _titleLabel.textColor = [UIColor blackColor];
        _titleLabel.numberOfLines = 1;
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _subtitleLabel = [UILabel new];
        _subtitleLabel.font = [UIFont systemFontOfSize:12];
        _subtitleLabel.textColor = [UIColor colorWithRed:0.612 green:0.643 blue:0.671 alpha:1.0];
        _badgeView = [UIView new];
        _badgeView.backgroundColor = [UIColor colorWithRed:0.95 green:0.25 blue:0.24 alpha:1.0];
        _badgeView.layer.cornerRadius = 9;
        _badgeView.layer.masksToBounds = YES;
        _badgeLabel = [UILabel new];
        _badgeLabel.font = [UIFont boldSystemFontOfSize:11];
        _badgeLabel.textColor = [UIColor whiteColor];
        _badgeLabel.textAlignment = NSTextAlignmentCenter;
        [_badgeView addSubview:_badgeLabel];
        _titleRowStack = [[UIStackView alloc] initWithArrangedSubviews:@[_titleLabel, _badgeView]];
        _titleRowStack.axis = UILayoutConstraintAxisHorizontal;
        _titleRowStack.spacing = 6;
        _titleRowStack.alignment = UIStackViewAlignmentCenter;
        _titleRowStack.distribution = UIStackViewDistributionFill;
        [_titleLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [_badgeView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [_badgeView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(18);
        }];
        [_badgeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(_badgeView);
            make.leading.equalTo(_badgeView).offset(6);
            make.trailing.equalTo(_badgeView).offset(-6);
        }];
        [self.contentView addSubview:_cardView];
        [_cardView addSubview:_iconBg];
        [_iconBg addSubview:_iconView];
        [_cardView addSubview:_titleRowStack];
        [_cardView addSubview:_subtitleLabel];
        [_cardView mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(6, 16, 6, 16)); }];
        [_iconBg mas_makeConstraints:^(MASConstraintMaker *make) { make.leading.equalTo(_cardView).offset(14); make.centerY.equalTo(_cardView); make.size.mas_equalTo(CGSizeMake(45, 45)); }];
        [_iconView mas_makeConstraints:^(MASConstraintMaker *make) { make.center.equalTo(_iconBg); make.size.mas_equalTo(CGSizeMake(22, 22)); }];
        [_titleRowStack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_iconBg.mas_trailing).offset(12);
            make.top.equalTo(_cardView).offset(17);
            make.trailing.lessThanOrEqualTo(_cardView).offset(-14);
        }];
        [_subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_titleRowStack);
            make.top.equalTo(_titleRowStack.mas_bottom).offset(4);
            make.trailing.lessThanOrEqualTo(_cardView).offset(-14);
        }];
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
@property (nonatomic, strong) NSMutableSet<NSString *> *sentFriendIds;
@property (nonatomic, assign) BOOL isSearching;
@property (nonatomic, assign) NSInteger pendingRequestCount;
@end

@implementation AddFriendViewController

- (void)updateSearchFieldPlaceholder {
    if (!self.searchField) return;
    NSString *ph = NSLocalizedString(@"community_search_placeholder", nil);
    UIFont *font = self.searchField.font ?: [UIFont systemFontOfSize:14];
    self.searchField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:ph attributes:@{
        NSForegroundColorAttributeName: kAddFriendGreen,
        NSFontAttributeName: font
    }];
    self.searchField.typingAttributes = @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: [UIColor blackColor]
    };
}

- (void)viewDidLoad {
    self.hidesBottomBarWhenPushed = YES;
    NSInteger storedCount = [[NSUserDefaults standardUserDefaults] integerForKey:kCommunityPendingCountKey];
    self.pendingRequestCount = MAX(0, storedCount);
    NSArray *sentIds = [[NSUserDefaults standardUserDefaults] arrayForKey:kCommunitySentSearchFriendIdsKey];
    self.sentFriendIds = [NSMutableSet setWithArray:(sentIds ?: @[])];
    [super viewDidLoad];
    // 勿再次调用 setupUI / updateLocalizedStrings：QMBaseViewController.viewDidLoad 已调用，重复会导致头部与列表叠两层
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
    __weak typeof(self) weakSelf = self;
    [SocialRequest.shared getFriendRequestsPendingCountSuccess:^(HTTPResponse * _Nullable responseObject) {
        NSInteger count = [responseObject.dataObject respondsToSelector:@selector(integerValue)] ? [responseObject.dataObject integerValue] : 0;
        weakSelf.pendingRequestCount = MAX(0, count);
        [[NSUserDefaults standardUserDefaults] setInteger:weakSelf.pendingRequestCount forKey:kCommunityPendingCountKey];
        if (!weakSelf.isSearching) {
            [weakSelf.tableView reloadData];
        }
    } failure:^(NSError * _Nonnull error) {
    }];
}

- (void)setupUI {
    self.headerView = [UIView new];
    self.headerView.backgroundColor = kAddFriendHeaderBg;
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
    self.searchField.textColor = [UIColor blackColor];
    self.searchField.tintColor = [UIColor blackColor];
    self.searchField.typingAttributes = @{
        NSFontAttributeName: [UIFont systemFontOfSize:14],
        NSForegroundColorAttributeName: [UIColor blackColor]
    };
    self.searchField.delegate = self;
    self.searchField.returnKeyType = UIReturnKeySearch;
    [searchBg addSubview:self.searchField];
    [self updateSearchFieldPlaceholder];

    self.searchBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    self.searchBtn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [self.searchBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.searchBtn.backgroundColor = kAddFriendGreen;
    self.searchBtn.layer.cornerRadius = 20;
    [self.searchBtn addTarget:self action:@selector(onSearch) forControlEvents:UIControlEventTouchUpInside];
    [self.searchBtn setTitle:NSLocalizedString(@"community_search", nil) forState:UIControlStateNormal];
    [searchBg addSubview:self.searchBtn];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    if (@available(iOS 15.0, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:[MenuItemCell class] forCellReuseIdentifier:@"MenuItemCell"];
    [self.tableView registerClass:[SearchResultCell class] forCellReuseIdentifier:@"SearchResultCell"];
    [self.view addSubview:self.tableView];

    [self.headerView mas_makeConstraints:^(MASConstraintMaker *make) { make.top.leading.trailing.equalTo(self.view); make.height.mas_equalTo(162); }];
    [backBtn mas_makeConstraints:^(MASConstraintMaker *make) { make.leading.equalTo(self.headerView).offset(12); make.top.equalTo(self.headerView.mas_safeAreaLayoutGuideTop).offset(8); make.size.mas_equalTo(CGSizeMake(32, 32)); }];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) { make.centerX.equalTo(self.headerView); make.centerY.equalTo(backBtn); }];
    [searchBg mas_makeConstraints:^(MASConstraintMaker *make) { make.leading.equalTo(self.headerView).offset(16); make.trailing.equalTo(self.headerView).offset(-16); make.bottom.equalTo(self.headerView).offset(-15); make.height.mas_equalTo(44); }];
    [searchIcon mas_makeConstraints:^(MASConstraintMaker *make) { make.leading.equalTo(searchBg).offset(12); make.centerY.equalTo(searchBg); make.size.mas_equalTo(CGSizeMake(18, 18)); }];
    [self.searchBtn mas_makeConstraints:^(MASConstraintMaker *make) { make.trailing.equalTo(searchBg).offset(-4); make.centerY.equalTo(searchBg); make.size.mas_equalTo(CGSizeMake(77, 40)); }];
    [self.searchField mas_makeConstraints:^(MASConstraintMaker *make) { make.leading.equalTo(searchIcon.mas_trailing).offset(8); make.trailing.equalTo(self.searchBtn.mas_leading).offset(-6); make.centerY.equalTo(searchBg); }];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) { make.top.equalTo(self.headerView.mas_bottom).offset(0); make.leading.trailing.bottom.equalTo(self.view); }];
}

- (void)onBack { [self.navigationController popViewControllerAnimated:YES]; }

/// 解析 `/api/v1/users/search` 的 data：数组、`{ list }`、`PNUserPage`、`{ users|records|items }`、单用户字典，或元素内嵌 `user`/`profile`
- (NSArray<PNUser *> *)pnUsersFromSearchResponseData:(id)data {
    if (!data || data == (id)kCFNull) {
        return @[];
    }
    if ([data isKindOfClass:[NSArray class]]) {
        NSArray *arr = (NSArray *)data;
        if (arr.count > 0 && [arr.firstObject isKindOfClass:PNUser.class]) {
            return arr;
        }
    }
    if ([data isKindOfClass:[NSArray class]]) {
        return [self pnUsersFromSearchJSONArray:(NSArray *)data];
    }
    if ([data isKindOfClass:[NSDictionary class]]) {
        NSDictionary *d = (NSDictionary *)data;
        PNUserPage *page = [PNUserPage yy_modelWithJSON:d];
        if (page.list.count > 0) {
            return page.list;
        }
        for (NSString *key in @[@"list", @"users", @"records", @"items", @"rows", @"content"]) {
            id list = d[key];
            if ([list isKindOfClass:[NSArray class]]) {
                return [self pnUsersFromSearchJSONArray:list];
            }
        }
        PNUser *u = [PNUser yy_modelWithJSON:d];
        if (u && (u.userId.length > 0 || u.nickname.length > 0)) {
            return @[u];
        }
    }
    return @[];
}

- (NSArray<PNUser *> *)pnUsersFromSearchJSONArray:(NSArray *)raw {
    NSMutableArray<PNUser *> *out = [NSMutableArray array];
    for (id item in raw) {
        if ([item isKindOfClass:PNUser.class]) {
            PNUser *u = (PNUser *)item;
            if (u.userId.length > 0 || u.nickname.length > 0) {
                [out addObject:u];
            }
            continue;
        }
        if (![item isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        NSDictionary *dict = (NSDictionary *)item;
        id payload = dict[@"user"] ?: dict[@"profile"] ?: dict[@"member"] ?: item;
        PNUser *u = [PNUser yy_modelWithJSON:payload];
        if (u && (u.userId.length > 0 || u.nickname.length > 0)) {
            [out addObject:u];
        }
    }
    return out;
}

- (void)onSearch {
    NSString *text = [self.searchField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (text.length == 0) {
        self.isSearching = NO;
        self.searchResults = @[];
        [self.searchField resignFirstResponder];
        [self.tableView reloadData];
        return;
    }
    self.isSearching = YES;
    [self.searchField resignFirstResponder];
    [self.tableView reloadData];
    [self showLoading];

    __weak typeof(self) weakSelf = self;
    [UserRequest.shared searchUser:text success:^(HTTPResponse * _Nullable responseObject) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [self hideLoading];
        id raw = responseObject.dataObject ?: responseObject.data;
        self.searchResults = [self pnUsersFromSearchResponseData:raw];
        [self.tableView reloadData];
    } failure:^(NSError * _Nonnull error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [self hideLoading];
        self.searchResults = @[];
        [self.tableView reloadData];
        NSString *msg = error.localizedDescription.length ? error.localizedDescription : NSLocalizedString(@"community_search_failed", nil);
        [self showError:msg];
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self onSearch];
    return YES;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.isSearching ? self.searchResults.count : 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.isSearching ? 74 : 82;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (!self.isSearching) return nil;
    UIView *header = [UIView new];
    header.backgroundColor = [UIColor clearColor];
    UILabel *label = [UILabel new];
    label.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    label.textColor = [UIColor blackColor];
    label.text = [NSString stringWithFormat:NSLocalizedString(@"community_search_result_format", nil), (long)self.searchResults.count];
    [header addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(header).offset(18);
        make.top.equalTo(header).offset(8);
        make.bottom.equalTo(header).offset(-16);
    }];
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    // 8 顶边距 + 单行标题约 22 + 与首个 cell 间距 16
    return self.isSearching ? 46 : 0;
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
        UIImage *icon = [UIImage imageNamed:@"new_friends"];
        BOOL assetIcon = (icon != nil);
        if (!icon && @available(iOS 13.0, *)) {
            icon = [UIImage systemImageNamed:@"person.2"];
        }
        cell.iconView.image = icon;
        cell.iconView.tintColor = assetIcon ? nil : [UIColor blackColor];
        cell.titleLabel.text = NSLocalizedString(@"community_new_friends", nil);
        cell.subtitleLabel.text = NSLocalizedString(@"community_new_friends_subtitle", nil);
        BOOL showBadge = self.pendingRequestCount > 0;
        cell.badgeView.hidden = !showBadge;
        cell.badgeLabel.text = showBadge ? (self.pendingRequestCount > 99 ? @"99+" : [NSString stringWithFormat:@"%ld", (long)self.pendingRequestCount]) : @"";
    } else {
        UIImage *icon = [UIImage imageNamed:@"scan_qr_icon"];
        BOOL assetIcon = (icon != nil);
        if (!icon && @available(iOS 13.0, *)) {
            icon = [UIImage systemImageNamed:@"qrcode.viewfinder"];
        }
        cell.iconView.image = icon;
        cell.iconView.tintColor = assetIcon ? nil : [UIColor blackColor];
        cell.titleLabel.text = NSLocalizedString(@"community_scan_add_friend", nil);
        cell.subtitleLabel.text = NSLocalizedString(@"community_scan_add_friend_subtitle", nil);
        cell.badgeView.hidden = YES;
        cell.badgeLabel.text = @"";
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
    self.titleLabel.text = NSLocalizedString(@"community_new_friends", nil);
    [self updateSearchFieldPlaceholder];
    [self.searchBtn setTitle:NSLocalizedString(@"community_search", nil) forState:UIControlStateNormal];
    [self.tableView reloadData];
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
