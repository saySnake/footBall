//
//  PNMatchDetailViewController.m
//  footBall
//

#import "PNMatchDetailViewController.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>
#import "ColorManager.h"
#import "MatchRequest.h"
#import "MatchRecordModels.h"
#import "Match.h"
#import "HTTPResponse.h"

#define kDetailGreen  [UIColor colorWithRed:0.157 green:0.365 blue:0.294 alpha:1.0]
#define kDetailBg     [UIColor colorWithRed:0.965 green:0.965 blue:0.965 alpha:1.0]
#define kDetailCardBg [UIColor colorWithRed:0.965 green:0.965 blue:0.965 alpha:1.0]

@interface PNMatchDetailViewController ()
// 顶部比赛卡片
@property (nonatomic, strong) UIImageView *homeLogoView;
@property (nonatomic, strong) UILabel *homeNameLabel;
@property (nonatomic, strong) UILabel *awayNameLabel;
@property (nonatomic, strong) UIImageView *awayLogoView;
@property (nonatomic, strong) UILabel *matchDateLabel;
@property (nonatomic, strong) UILabel *kickTimeLabel;
// 比赛信息行
@property (nonatomic, strong) UILabel *watchLocationValue;
@property (nonatomic, strong) UILabel *seatValue;
@property (nonatomic, strong) UILabel *watchReasonValue;
@property (nonatomic, strong) UILabel *matchDateValue;
@property (nonatomic, strong) UILabel *ticketPriceValue;
// 观赛身份胶囊容器
@property (nonatomic, strong) UIView *identityPillsContainer;
// 情绪胶囊
@property (nonatomic, strong) UIView *emotionPillView;
@property (nonatomic, strong) UIImageView *emotionIconView;
@property (nonatomic, strong) UILabel *emotionTextLabel;
// 比赛感想
@property (nonatomic, strong) UITextView *notesTextView;
// 底部栏
@property (nonatomic, strong) UIView *bottomBar;
@end

@implementation PNMatchDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self buildUI];
    [self loadRemoteData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

#pragma mark - Build UI

- (void)buildUI {
    // ── 导航栏 ──
    UIView *navBar = [[UIView alloc] init];
    navBar.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:navBar];
    [navBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(44);
    }];

    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *backImg = [UIImage imageNamed:@"nav_back"];
    if (!backImg && @available(iOS 13.0, *)) {
        backImg = [[UIImage systemImageNamed:@"arrow.left"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    [backBtn setImage:backImg forState:UIControlStateNormal];
    backBtn.tintColor = [UIColor blackColor];
    [backBtn addTarget:self action:@selector(onBack) forControlEvents:UIControlEventTouchUpInside];
    [navBar addSubview:backBtn];
    [backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(navBar).offset(16);
        make.bottom.equalTo(navBar).offset(-10);
        make.width.height.mas_equalTo(28);
    }];

    UILabel *navTitle = [[UILabel alloc] init];
    navTitle.text = @"比赛详情";
    navTitle.font = [UIFont boldSystemFontOfSize:17];
    navTitle.textColor = [UIColor blackColor];
    [navBar addSubview:navTitle];
    [navTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(navBar);
        make.centerY.equalTo(backBtn);
    }];

    // ── 底部栏（先加，让 scrollView 不被遮住）──
    UIView *bottomBar = [[UIView alloc] init];
    bottomBar.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:bottomBar];
    self.bottomBar = bottomBar;
    [bottomBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
        make.height.mas_equalTo(64);
    }];

    // 底部左侧编辑图标
    UIButton *editBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *editImg = [UIImage imageNamed:@"edit_icon"];
    if (!editImg && @available(iOS 13.0, *)) {
        editImg = [[UIImage systemImageNamed:@"pencil"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    [editBtn setImage:editImg forState:UIControlStateNormal];
    editBtn.tintColor = [UIColor blackColor];
    [editBtn addTarget:self action:@selector(onEdit) forControlEvents:UIControlEventTouchUpInside];
    [bottomBar addSubview:editBtn];
    [editBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(bottomBar).offset(24);
        make.centerY.equalTo(bottomBar);
        make.width.height.mas_equalTo(36);
    }];

    // 底部确定按钮
    UIButton *confirmBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    confirmBtn.backgroundColor = kDetailGreen;
    confirmBtn.layer.cornerRadius = 22;
    [confirmBtn setTitle:@"确定" forState:UIControlStateNormal];
    [confirmBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    confirmBtn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [confirmBtn addTarget:self action:@selector(onConfirm) forControlEvents:UIControlEventTouchUpInside];
    [bottomBar addSubview:confirmBtn];
    [confirmBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(editBtn.mas_trailing).offset(16);
        make.trailing.equalTo(bottomBar).offset(-24);
        make.centerY.equalTo(bottomBar);
        make.height.mas_equalTo(44);
    }];

    // 底部分隔线
    UIView *separator = [[UIView alloc] init];
    separator.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    [bottomBar addSubview:separator];
    [separator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(bottomBar);
        make.height.mas_equalTo(0.5);
    }];

    // ── ScrollView ──
    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.showsVerticalScrollIndicator = NO;
    if (@available(iOS 11.0, *)) scroll.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:scroll];
    [scroll mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(navBar.mas_bottom);
        make.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(bottomBar.mas_top);
    }];

    UIView *content = [[UIView alloc] init];
    [scroll addSubview:content];
    [content mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(scroll);
        make.width.equalTo(scroll);
    }];

    // ── 顶部比赛卡片 ──
    UIView *topCard = [[UIView alloc] init];
    topCard.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1.0];
    topCard.layer.cornerRadius = 12;
    [content addSubview:topCard];
    [topCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(content).offset(14);
        make.leading.equalTo(content).offset(16);
        make.trailing.equalTo(content).offset(-16);
        make.height.mas_equalTo(109);
    }];

    _homeLogoView = [[UIImageView alloc] init];
    _homeLogoView.layer.cornerRadius = 19;
    _homeLogoView.clipsToBounds = YES;
    _homeLogoView.contentMode = UIViewContentModeScaleAspectFit;
    _homeLogoView.backgroundColor = [UIColor clearColor];
    [topCard addSubview:_homeLogoView];

    _homeNameLabel = [[UILabel alloc] init];
    _homeNameLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    _homeNameLabel.textColor = [UIColor blackColor];
    _homeNameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    _homeNameLabel.text = self.homeName ?: @"-";
    [topCard addSubview:_homeNameLabel];

    UILabel *vsLabel = [[UILabel alloc] init];
    vsLabel.text = @"VS";
    vsLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    vsLabel.textColor = [UIColor blackColor];
    vsLabel.textAlignment = NSTextAlignmentCenter;
    [topCard addSubview:vsLabel];

    _awayNameLabel = [[UILabel alloc] init];
    _awayNameLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    _awayNameLabel.textColor = [UIColor blackColor];
    _awayNameLabel.textAlignment = NSTextAlignmentRight;
    _awayNameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    _awayNameLabel.text = self.awayName ?: @"-";
    [topCard addSubview:_awayNameLabel];

    _awayLogoView = [[UIImageView alloc] init];
    _awayLogoView.layer.cornerRadius = 19;
    _awayLogoView.clipsToBounds = YES;
    _awayLogoView.contentMode = UIViewContentModeScaleAspectFit;
    _awayLogoView.backgroundColor = [UIColor clearColor];
    [topCard addSubview:_awayLogoView];

    _matchDateLabel = [[UILabel alloc] init];
    _matchDateLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    _matchDateLabel.textColor = [UIColor colorWithWhite:0.23 alpha:1.0];
    _matchDateLabel.text = @"-";
    [topCard addSubview:_matchDateLabel];

    _kickTimeLabel = [[UILabel alloc] init];
    _kickTimeLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    _kickTimeLabel.textColor = kDetailGreen;
    _kickTimeLabel.textAlignment = NSTextAlignmentCenter;
    _kickTimeLabel.layer.cornerRadius = 15;
    _kickTimeLabel.layer.borderWidth = 0.5;
    _kickTimeLabel.layer.borderColor = kDetailGreen.CGColor;
    _kickTimeLabel.clipsToBounds = YES;
    _kickTimeLabel.text = @"--:--";
    [topCard addSubview:_kickTimeLabel];

    // 布局：队名 → 队徽 → VS → 队徽 → 队名（与原型一致）
    [_homeNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(topCard).offset(18);
        make.top.equalTo(topCard).offset(22);
        make.trailing.lessThanOrEqualTo(_homeLogoView.mas_leading).offset(-10);
    }];
    [_homeLogoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(topCard.mas_centerX).offset(-60);
        make.top.equalTo(topCard).offset(16);
        make.width.height.mas_equalTo(38);
    }];
    [vsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(topCard);
        make.centerY.equalTo(_homeLogoView);
        make.width.mas_equalTo(52);
    }];
    [_awayLogoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(topCard.mas_centerX).offset(60);
        make.centerY.equalTo(_homeLogoView);
        make.width.height.mas_equalTo(38);
    }];
    [_awayNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.greaterThanOrEqualTo(_awayLogoView.mas_trailing).offset(10);
        make.trailing.equalTo(topCard).offset(-18);
        make.centerY.equalTo(_homeLogoView);
    }];
    [_matchDateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(topCard).offset(18);
        make.centerY.equalTo(_kickTimeLabel);
    }];
    [_kickTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(topCard).offset(-12);
        make.centerX.equalTo(topCard);
        make.width.mas_equalTo(82);
        make.height.mas_equalTo(30);
    }];

    // ── 比赛信息 ──
    UILabel *infoSectionTitle = [self sectionTitleLabel:@"比赛信息"];
    [content addSubview:infoSectionTitle];
    [infoSectionTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(topCard.mas_bottom).offset(20);
        make.leading.equalTo(content).offset(16);
    }];

    UIView *infoCard = [[UIView alloc] init];
    infoCard.backgroundColor = kDetailCardBg;
    infoCard.layer.cornerRadius = 12;
    [content addSubview:infoCard];
    [infoCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(infoSectionTitle.mas_bottom).offset(10);
        make.leading.equalTo(content).offset(16);
        make.trailing.equalTo(content).offset(-16);
    }];

    NSArray *leftTitles = @[@"观赛信息", @"座位", @"看球原因", @"比赛日期", @"售票价格"];
    NSMutableArray *valueLabels = [NSMutableArray array];
    UIView *prevRow = nil;
    for (NSInteger i = 0; i < leftTitles.count; i++) {
        UILabel *leftLab = [self rowLeftLabel:leftTitles[i]];
        UILabel *rightLab = [self rowRightLabel:@"-"];
        [valueLabels addObject:rightLab];
        [infoCard addSubview:leftLab];
        [infoCard addSubview:rightLab];
        [leftLab mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(infoCard).offset(16);
            if (!prevRow) make.top.equalTo(infoCard).offset(16);
            else make.top.equalTo(prevRow.mas_bottom).offset(14);
            if (i == leftTitles.count - 1) make.bottom.equalTo(infoCard).offset(-16);
        }];
        [rightLab mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(leftLab);
            make.trailing.equalTo(infoCard).offset(-16);
            make.leading.greaterThanOrEqualTo(leftLab.mas_trailing).offset(8);
        }];
        prevRow = leftLab;
    }
    _watchLocationValue = valueLabels[0];
    _seatValue          = valueLabels[1];
    _watchReasonValue   = valueLabels[2];
    _matchDateValue     = valueLabels[3];
    _ticketPriceValue   = valueLabels[4];

    // ── 观赛身份 ──
    UILabel *identityTitle = [self sectionTitleLabel:@"观赛身份"];
    [content addSubview:identityTitle];
    [identityTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(infoCard.mas_bottom).offset(20);
        make.leading.equalTo(content).offset(16);
    }];

    UIView *pillsContainer = [[UIView alloc] init];
    [content addSubview:pillsContainer];
    self.identityPillsContainer = pillsContainer;
    [pillsContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(identityTitle.mas_bottom).offset(10);
        make.leading.equalTo(content).offset(16);
        make.trailing.equalTo(content).offset(-16);
        make.height.mas_equalTo(32);
    }];

    // ── 情绪 ──
    UILabel *emotionTitle = [self sectionTitleLabel:@"情绪"];
    [content addSubview:emotionTitle];
    [emotionTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(pillsContainer.mas_bottom).offset(20);
        make.leading.equalTo(content).offset(16);
    }];

    // 情绪胶囊：浅灰底，左侧图片 + 右侧文字
    UIView *emotionPillView = [[UIView alloc] init];
    emotionPillView.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1.0];
    emotionPillView.layer.cornerRadius = 14;
    emotionPillView.clipsToBounds = YES;
    [content addSubview:emotionPillView];
    [emotionPillView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(emotionTitle.mas_bottom).offset(10);
        make.leading.equalTo(content).offset(16);
        make.height.mas_equalTo(32);
    }];

    UILabel *emotionTextLabel = [[UILabel alloc] init];
    emotionTextLabel.font = [UIFont systemFontOfSize:13];
    emotionTextLabel.textColor = [UIColor blackColor];
    emotionTextLabel.text = @"-";
    [emotionPillView addSubview:emotionTextLabel];
    [emotionTextLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(emotionPillView).offset(12);
        make.centerY.equalTo(emotionPillView);
    }];

    UIImageView *emotionIconView = [[UIImageView alloc] init];
    emotionIconView.contentMode = UIViewContentModeScaleAspectFit;
    emotionIconView.clipsToBounds = YES;
    [emotionPillView addSubview:emotionIconView];
    [emotionIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(emotionTextLabel.mas_trailing).offset(6);
        make.trailing.equalTo(emotionPillView).offset(-10);
        make.centerY.equalTo(emotionPillView);
        make.width.height.mas_equalTo(20);
    }];

    self.emotionIconView = emotionIconView;
    self.emotionTextLabel = emotionTextLabel;
    self.emotionPillView = emotionPillView;

    // ── 比赛感想 ──
    UIView *notesTitleRow = [[UIView alloc] init];
    [content addSubview:notesTitleRow];
    [notesTitleRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(emotionPillView.mas_bottom).offset(20);
        make.leading.equalTo(content).offset(16);
        make.trailing.equalTo(content).offset(-16);
        make.height.mas_equalTo(22);
    }];

    UILabel *notesTitle = [self sectionTitleLabel:@"比赛感想"];
    [notesTitleRow addSubview:notesTitle];
    [notesTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.centerY.equalTo(notesTitleRow);
    }];

    UIImageView *notesEditIcon = [[UIImageView alloc] init];
    UIImage *editIco = [UIImage imageNamed:@"edit_icon"];
    if (!editIco && @available(iOS 13.0, *)) {
        editIco = [[UIImage systemImageNamed:@"pencil"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        notesEditIcon.tintColor = [UIColor grayColor];
    }
    notesEditIcon.image = editIco;
    notesEditIcon.contentMode = UIViewContentModeScaleAspectFit;
    [notesTitleRow addSubview:notesEditIcon];
    [notesEditIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(notesTitle.mas_trailing).offset(6);
        make.centerY.equalTo(notesTitleRow);
        make.width.height.mas_equalTo(16);
    }];

    UITextView *notesTV = [[UITextView alloc] init];
    notesTV.backgroundColor = kDetailCardBg;
    notesTV.layer.cornerRadius = 12;
    notesTV.font = [UIFont systemFontOfSize:14];
    notesTV.textColor = [UIColor blackColor];
    notesTV.textContainerInset = UIEdgeInsetsMake(12, 12, 12, 12);
    notesTV.editable = NO;
    notesTV.scrollEnabled = NO;
    notesTV.text = @"";
    [content addSubview:notesTV];
    self.notesTextView = notesTV;
    [notesTV mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(notesTitleRow.mas_bottom).offset(10);
        make.leading.equalTo(content).offset(16);
        make.trailing.equalTo(content).offset(-16);
        make.height.mas_equalTo(140);
        make.bottom.equalTo(content).offset(-24);
    }];
}

#pragma mark - Helper

- (UILabel *)sectionTitleLabel:(NSString *)text {
    UILabel *l = [[UILabel alloc] init];
    l.text = text;
    l.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    l.textColor = [UIColor blackColor];
    return l;
}

- (UILabel *)rowLeftLabel:(NSString *)text {
    UILabel *l = [[UILabel alloc] init];
    l.text = text;
    l.font = [UIFont systemFontOfSize:13];
    l.textColor = [UIColor colorWithWhite:0.55 alpha:1.0];
    return l;
}

- (UILabel *)rowRightLabel:(NSString *)text {
    UILabel *l = [[UILabel alloc] init];
    l.text = text;
    l.font = [UIFont systemFontOfSize:13];
    l.textColor = [UIColor blackColor];
    l.textAlignment = NSTextAlignmentRight;
    return l;
}

- (void)rebuildIdentityPills:(NSArray<NSString *> *)identities {
    for (UIView *v in self.identityPillsContainer.subviews) [v removeFromSuperview];
    if (identities.count == 0) return;
    UIButton *prev = nil;
    for (NSString *t in identities) {
        UIButton *pill = [UIButton buttonWithType:UIButtonTypeCustom];
        [pill setTitle:t forState:UIControlStateNormal];
        [pill setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        pill.titleLabel.font = [UIFont systemFontOfSize:12];
        pill.backgroundColor = kDetailGreen;
        pill.layer.cornerRadius = 14;
        pill.clipsToBounds = YES;
        pill.contentEdgeInsets = UIEdgeInsetsMake(6, 12, 6, 12);
        pill.userInteractionEnabled = NO;
        [self.identityPillsContainer addSubview:pill];
        [pill mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(self.identityPillsContainer);
            if (!prev) make.leading.equalTo(self.identityPillsContainer);
            else make.leading.equalTo(prev.mas_trailing).offset(8);
        }];
        prev = pill;
    }
}

#pragma mark - Data

- (void)loadRemoteData {
    NSString *rid = self.recordId;
    if (rid.length == 0) return;
    __weak typeof(self) weakSelf = self;
    [[MatchRequest shared] getMatchRecordDetail:rid success:^(HTTPResponse * _Nullable responseObject) {
        PNMatchRecordDetail *detail = nil;
        if ([responseObject.dataObject isKindOfClass:PNMatchRecordDetail.class]) {
            detail = responseObject.dataObject;
        } else if ([responseObject.data isKindOfClass:NSDictionary.class]) {
            detail = [PNMatchRecordDetail yy_modelWithJSON:responseObject.data];
        }
        if (!detail) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf applyDetail:detail];
        });
        // 用 matchId 拉比赛详情，获取队徽 URL
        NSString *mid = detail.matchId ?: weakSelf.matchId;
        if (mid.length == 0) return;
        [[MatchRequest shared] getMatchDetail:mid success:^(HTTPResponse * _Nullable r2) {
            Match *match = [r2.dataObject isKindOfClass:Match.class] ? r2.dataObject : nil;
            if (!match) return;
            dispatch_async(dispatch_get_main_queue(), ^{
                UIImage *ph = [UIImage imageNamed:@"team_placeholder"];
                if (match.homeTeamLogo.length > 0) {
                    [weakSelf.homeLogoView sd_setImageWithURL:[NSURL URLWithString:match.homeTeamLogo]
                                            placeholderImage:ph];
                }
                if (match.awayTeamLogo.length > 0) {
                    [weakSelf.awayLogoView sd_setImageWithURL:[NSURL URLWithString:match.awayTeamLogo]
                                            placeholderImage:ph];
                }
            });
        } failure:nil];
    } failure:^(NSError * _Nonnull error) {}];
}

- (void)applyDetail:(PNMatchRecordDetail *)d {
    // 顶部卡片
    _homeNameLabel.text = d.homeTeamName.length ? d.homeTeamName : (self.homeName ?: @"-");
    _awayNameLabel.text = d.awayTeamName.length ? d.awayTeamName : (self.awayName ?: @"-");
    NSString *topDateRaw = d.matchDate.length ? d.matchDate : d.matchDateTime;
    _matchDateLabel.text = [self weekdayDateText:topDateRaw];
    _kickTimeLabel.text  = [self timeText:topDateRaw];

    // 比赛信息行
    _watchLocationValue.text = d.viewingLocation.length ? d.viewingLocation : @"-";
    _seatValue.text          = d.standType.length ? d.standType : (d.seatLocation.length ? d.seatLocation : @"-");
    _watchReasonValue.text   = d.watchReason.length ? d.watchReason : @"-";
    _matchDateValue.text     = [self fullDateTimeText:d.matchDateTime ?: d.matchDate];
    // ticketPrice 可能是数字或字符串
    if (d.ticketPrice.length > 0) {
        double price = [d.ticketPrice doubleValue];
        _ticketPriceValue.text = price > 0 ? [NSString stringWithFormat:@"%.1f", price] : d.ticketPrice;
    } else {
        _ticketPriceValue.text = @"-";
    }

    // 观赛身份胶囊
    [self rebuildIdentityPills:d.viewingIdentities ?: @[]];

    // 情绪
    NSString *emotion = d.postMatchEmotion ?: @"";
    NSDictionary *emotionOpt = [self emotionOptionForValue:emotion];
    NSString *emotionName  = emotionOpt[@"name"] ?: (emotion.length ? emotion : @"-");
    NSString *emotionIcon  = emotionOpt[@"icon"] ?: @"team_ex";
    _emotionTextLabel.text = emotionName;
    _emotionIconView.image = [UIImage imageNamed:emotionIcon];

    // 比赛感想
    _notesTextView.text = d.notes ?: @"";
}

#pragma mark - Emotion helper

/// 根据存储值（emoji 或 名称 或 "名称 emoji"）查找对应的情绪选项字典
- (NSDictionary<NSString *, NSString *> *)emotionOptionForValue:(NSString *)raw {
    static NSArray<NSDictionary<NSString *, NSString *> *> *options = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = @[
            @{ @"name": @"兴奋", @"emoji": @"🤩", @"icon": @"team_ex"    },
            @{ @"name": @"激动", @"emoji": @"🥳", @"icon": @"team_ji"    },
            @{ @"name": @"希望", @"emoji": @"🤗", @"icon": @"team_hop"   },
            @{ @"name": @"遗憾", @"emoji": @"😩", @"icon": @"team_ku"    },
            @{ @"name": @"平静", @"emoji": @"😎", @"icon": @"team_ping"  },
            @{ @"name": @"失望", @"emoji": @"😤", @"icon": @"team_shi"   },
            @{ @"name": @"暴躁", @"emoji": @"😡", @"icon": @"team_angry" },
        ];
    });
    NSString *v = [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (v.length == 0) return options.firstObject;
    for (NSDictionary *opt in options) {
        NSString *name  = opt[@"name"]  ?: @"";
        NSString *emoji = opt[@"emoji"] ?: @"";
        if ([v isEqualToString:name] || [v isEqualToString:emoji] ||
            [v containsString:emoji] || [v containsString:name]) {
            return opt;
        }
    }
    return options.firstObject;
}

#pragma mark - Date helpers

- (NSDate *)parseDateFromRaw:(NSString *)raw {
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
        NSDate *d = [iso dateFromString:raw]; if (d) return d;
        iso.formatOptions = NSISO8601DateFormatWithInternetDateTime;
        d = [iso dateFromString:raw]; if (d) return d;
    }
    NSDateFormatter *f = [[NSDateFormatter alloc] init];
    f.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    for (NSString *fmt in @[@"yyyy-MM-dd'T'HH:mm:ssZ", @"yyyy-MM-dd'T'HH:mm:ss", @"yyyy-MM-dd'T'HH:mm:ss.SSS", @"yyyy-MM-dd HH:mm:ss", @"yyyy-MM-dd HH:mm", @"yyyy-MM-dd"]) {
        f.dateFormat = fmt;
        NSDate *d = [f dateFromString:raw]; if (d) return d;
    }
    return nil;
}

/// "Sun, 18 Feb 25"
- (NSString *)weekdayDateText:(NSString *)raw {
    NSDate *d = [self parseDateFromRaw:raw];
    if (!d) return @"-";
    NSDateFormatter *f = [[NSDateFormatter alloc] init];
    f.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    f.dateFormat = @"EEE, d MMM yy";
    return [f stringFromDate:d];
}

/// "06:30"
- (NSString *)timeText:(NSString *)raw {
    NSDate *d = [self parseDateFromRaw:raw];
    if (!d) return @"--:--";
    NSDateFormatter *f = [[NSDateFormatter alloc] init];
    f.dateFormat = @"HH:mm";
    return [f stringFromDate:d];
}

/// "2025-12-20 21:30"
- (NSString *)fullDateTimeText:(NSString *)raw {
    NSDate *d = [self parseDateFromRaw:raw];
    if (!d) return raw.length ? raw : @"-";
    NSDateFormatter *f = [[NSDateFormatter alloc] init];
    f.dateFormat = @"yyyy-MM-dd HH:mm";
    return [f stringFromDate:d];
}

#pragma mark - Actions

- (void)onBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onEdit {
    // 预留：跳转到编辑观赛信息页
}

- (void)onConfirm {
    [self.navigationController popViewControllerAnimated:YES];
}

@end

