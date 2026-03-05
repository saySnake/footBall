//
//  PNMatchDetailViewController.m
//  footBall
//

#import "PNMatchDetailViewController.h"
#import <Masonry/Masonry.h>
#import "ColorManager.h"

static UIColor *PNMatchGreenColor(void) {
    // 统一使用 ColorManager 主色
    return [ColorManager sharedManager].primaryColor;
}

@interface PNMatchDetailViewController ()
@property (nonatomic, strong) UIView *customNavBar;
@property (nonatomic, strong) UILabel *watchStatusLabel;
@property (nonatomic, strong) UILabel *matchNameLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *seatLabel;
@property (nonatomic, strong) UILabel *reasonLabel;
@property (nonatomic, strong) UILabel *priceLabel;
@property (nonatomic, strong) NSArray<UIButton *> *identityPillButtons;
@property (nonatomic, strong) UIButton *emotionPillButton;
@end

@implementation PNMatchDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self buildUI];
    [self fillFakeData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 不显示系统导航栏，用自定义顶部栏，避免系统 navBar 的 contentView KVC 崩溃及标题红色等问题
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)buildUI {
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 自定义顶部栏：白底、左侧返回箭头图、中间黑色标题，不依赖系统导航栏
    UIView *navBar = [[UIView alloc] init];
    navBar.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:navBar];
    self.customNavBar = navBar;
    [navBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
        make.height.mas_equalTo(88);
    }];
    
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *backImage = [UIImage imageNamed:@"left"];
    if (backImage) {
        [backBtn setImage:backImage forState:UIControlStateNormal];
    }
    backBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [backBtn addTarget:self action:@selector(onBack) forControlEvents:UIControlEventTouchUpInside];
    [navBar addSubview:backBtn];
    [backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(navBar).offset(16);
        make.bottom.equalTo(navBar).offset(-10);
        make.size.mas_equalTo(CGSizeMake(44, 44));
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
    
    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.showsVerticalScrollIndicator = NO;
    [self.view addSubview:scroll];
    [scroll mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(navBar.mas_bottom);
        make.leading.trailing.bottom.equalTo(self.view);
    }];
    
    UIView *content = [[UIView alloc] init];
    [scroll addSubview:content];
    [content mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(scroll);
        make.width.equalTo(scroll);
    }];
    
    // 顶部比赛卡片：左队徽+队名、VS、右队名+队徽；下一行日期左、开球时间绿色椭圆右（仅一个标题「比赛详情」在自定义顶部栏）
    UIView *topCard = [[UIView alloc] init];
    topCard.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1.0];
    topCard.layer.cornerRadius = 16;
    [content addSubview:topCard];
    [topCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(content).offset(16);
        make.leading.equalTo(content).offset(16);
        make.trailing.equalTo(content).offset(-16);
    }];
    
    UIImageView *homeLogo = [[UIImageView alloc] init];
    homeLogo.backgroundColor = [UIColor colorWithRed:0.85 green:0.20 blue:0.25 alpha:1.0];
    homeLogo.layer.cornerRadius = 20;
    homeLogo.clipsToBounds = YES;
    homeLogo.contentMode = UIViewContentModeCenter;
    if (@available(iOS 13.0, *)) {
        homeLogo.image = [UIImage systemImageNamed:@"leaf.fill"];
        homeLogo.tintColor = [UIColor whiteColor];
    }
    [topCard addSubview:homeLogo];
    
    UILabel *home = [[UILabel alloc] init];
    home.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    home.textColor = [UIColor blackColor];
    home.text = self.homeName.length > 0 ? self.homeName : @"诺丁汉森林队";
    [topCard addSubview:home];
    
    UILabel *vsLabel = [[UILabel alloc] init];
    vsLabel.text = @"VS";
    vsLabel.font = [UIFont boldSystemFontOfSize:16];
    vsLabel.textColor = [UIColor darkGrayColor];
    [topCard addSubview:vsLabel];
    
    UILabel *away = [[UILabel alloc] init];
    away.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    away.textAlignment = NSTextAlignmentRight;
    away.textColor = [UIColor blackColor];
    away.text = self.awayName.length > 0 ? self.awayName : @"利物浦";
    [topCard addSubview:away];
    
    UIImageView *awayLogo = [[UIImageView alloc] init];
    awayLogo.backgroundColor = [UIColor colorWithRed:0.85 green:0.20 blue:0.25 alpha:1.0];
    awayLogo.layer.cornerRadius = 20;
    awayLogo.clipsToBounds = YES;
    awayLogo.contentMode = UIViewContentModeCenter;
    if (@available(iOS 13.0, *)) {
        awayLogo.image = [UIImage systemImageNamed:@"bird.fill"];
        awayLogo.tintColor = [UIColor whiteColor];
    }
    [topCard addSubview:awayLogo];
    
    UILabel *dateInfo = [[UILabel alloc] init];
    dateInfo.font = [UIFont systemFontOfSize:12];
    dateInfo.textColor = [UIColor grayColor];
    dateInfo.text = @"Sun, 18 Feb 25";
    [topCard addSubview:dateInfo];
    
    UILabel *kickTime = [[UILabel alloc] init];
    kickTime.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    kickTime.textColor = PNMatchGreenColor();
    kickTime.textAlignment = NSTextAlignmentCenter;
    kickTime.backgroundColor = [UIColor clearColor];
    kickTime.layer.cornerRadius = 14;
    kickTime.layer.borderWidth = 1;
    kickTime.layer.borderColor = PNMatchGreenColor().CGColor;
    kickTime.clipsToBounds = YES;
    kickTime.text = @"06:30";
    [topCard addSubview:kickTime];
    
    [homeLogo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(topCard).offset(16);
        make.top.equalTo(topCard).offset(20);
        make.width.height.mas_equalTo(40);
    }];
    [home mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(homeLogo.mas_trailing).offset(10);
        make.centerY.equalTo(homeLogo);
    }];
    [vsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(topCard);
        make.centerY.equalTo(homeLogo);
    }];
    [away mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(awayLogo.mas_leading).offset(-10);
        make.centerY.equalTo(homeLogo);
    }];
    [awayLogo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(topCard).offset(-16);
        make.centerY.equalTo(homeLogo);
        make.width.height.mas_equalTo(40);
    }];
    [dateInfo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(topCard).offset(16);
        make.top.equalTo(homeLogo.mas_bottom).offset(16);
    }];
    [kickTime mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(dateInfo);
        make.trailing.equalTo(topCard).offset(-16);
        make.width.mas_equalTo(56);
        make.height.mas_equalTo(28);
        make.bottom.equalTo(topCard).offset(-16);
    }];
    
    // 比赛信息卡片
    UIView *infoCard = [[UIView alloc] init];
    infoCard.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1.0];
    infoCard.layer.cornerRadius = 16;
    [content addSubview:infoCard];
    [infoCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(topCard.mas_bottom).offset(16);
        make.leading.equalTo(content).offset(16);
        make.trailing.equalTo(content).offset(-16);
    }];
    
    UILabel *sectionTitle = [[UILabel alloc] init];
    sectionTitle.text = @"比赛信息";
    sectionTitle.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    sectionTitle.textColor = [UIColor blackColor];
    [infoCard addSubview:sectionTitle];
    [sectionTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(infoCard).offset(16);
        make.leading.equalTo(infoCard).offset(16);
    }];
    
    UILabel *statusTitle = [self smallGrayLabel:@"观赛信息"];
    UILabel *seatTitle = [self smallGrayLabel:@"座位"];
    UILabel *reasonTitle = [self smallGrayLabel:@"看球原因"];
    UILabel *dateTitle = [self smallGrayLabel:@"比赛日期"];
    UILabel *priceTitle = [self smallGrayLabel:@"售票价格"];
    
    UILabel *statusValue = [self smallValueLabel];
    UILabel *seatValue = [self smallValueLabel];
    UILabel *reasonValue = [self smallValueLabel];
    UILabel *dateValue = [self smallValueLabel];
    UILabel *priceValue = [self smallValueLabel];
    
    self.watchStatusLabel = statusValue;
    self.timeLabel = dateValue;
    self.seatLabel = seatValue;
    self.reasonLabel = reasonValue;
    self.priceLabel = priceValue;
    
    [infoCard addSubview:statusTitle];
    [infoCard addSubview:seatTitle];
    [infoCard addSubview:reasonTitle];
    [infoCard addSubview:dateTitle];
    [infoCard addSubview:priceTitle];
    [infoCard addSubview:statusValue];
    [infoCard addSubview:seatValue];
    [infoCard addSubview:reasonValue];
    [infoCard addSubview:dateValue];
    [infoCard addSubview:priceValue];
    
    [statusTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(sectionTitle.mas_bottom).offset(16);
        make.leading.equalTo(infoCard).offset(16);
    }];
    [statusValue mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(statusTitle);
        make.trailing.equalTo(infoCard).offset(-16);
    }];
    [seatTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(statusTitle.mas_bottom).offset(12);
        make.leading.equalTo(statusTitle);
    }];
    [seatValue mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(seatTitle);
        make.trailing.equalTo(statusValue);
    }];
    [reasonTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(seatTitle.mas_bottom).offset(12);
        make.leading.equalTo(statusTitle);
    }];
    [reasonValue mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(reasonTitle);
        make.trailing.equalTo(statusValue);
    }];
    [dateTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(reasonTitle.mas_bottom).offset(12);
        make.leading.equalTo(statusTitle);
    }];
    [dateValue mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(dateTitle);
        make.trailing.equalTo(statusValue);
    }];
    [priceTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(dateTitle.mas_bottom).offset(12);
        make.leading.equalTo(statusTitle);
        make.bottom.equalTo(infoCard).offset(-16);
    }];
    [priceValue mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(priceTitle);
        make.trailing.equalTo(statusValue);
    }];
    
    // 观赛身份：多个深绿底白字圆角胶囊，带内边距，与设计图一致
    UILabel *identityTitle = [[UILabel alloc] init];
    identityTitle.text = @"观赛身份";
    identityTitle.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    identityTitle.textColor = [UIColor blackColor];
    [content addSubview:identityTitle];
    [identityTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(infoCard.mas_bottom).offset(20);
        make.leading.equalTo(content).offset(16);
    }];
    
    NSArray<NSString *> *identityTitles = @[ @"媒体记者", @"球迷", @"领喊", @"文字记者" ];
    NSMutableArray<UIButton *> *identityPills = [NSMutableArray array];
    UIButton *prevIdentityPill = nil;
    for (NSString *t in identityTitles) {
        UIButton *pill = [UIButton buttonWithType:UIButtonTypeCustom];
        [pill setTitle:t forState:UIControlStateNormal];
        [pill setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        pill.titleLabel.font = [UIFont systemFontOfSize:12];
        pill.backgroundColor = PNMatchGreenColor();
        pill.layer.cornerRadius = 14;
        pill.clipsToBounds = YES;
        pill.contentEdgeInsets = UIEdgeInsetsMake(6, 12, 6, 12);
        pill.userInteractionEnabled = NO;
        [content addSubview:pill];
        [identityPills addObject:pill];
        [pill mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(32);
            if (!prevIdentityPill) {
                make.top.equalTo(identityTitle.mas_bottom).offset(8);
                make.leading.equalTo(content).offset(16);
            } else {
                make.leading.equalTo(prevIdentityPill.mas_trailing).offset(8);
                make.centerY.equalTo(prevIdentityPill);
            }
        }];
        prevIdentityPill = pill;
    }
    self.identityPillButtons = identityPills;
    
    UILabel *emotionTitle = [[UILabel alloc] init];
    emotionTitle.text = @"情绪";
    emotionTitle.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    emotionTitle.textColor = [UIColor blackColor];
    [content addSubview:emotionTitle];
    [emotionTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(prevIdentityPill.mas_bottom).offset(20);
        make.leading.equalTo(identityTitle);
    }];
    
    // 情绪：浅灰底、深色文字+emoji 的圆角胶囊，带内边距
    UIButton *emotionPill = [UIButton buttonWithType:UIButtonTypeCustom];
    [emotionPill setTitle:@"兴奋 🤩" forState:UIControlStateNormal];
    [emotionPill setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    emotionPill.titleLabel.font = [UIFont systemFontOfSize:13];
    emotionPill.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1.0];
    emotionPill.layer.cornerRadius = 14;
    emotionPill.clipsToBounds = YES;
    emotionPill.contentEdgeInsets = UIEdgeInsetsMake(6, 12, 6, 12);
    emotionPill.userInteractionEnabled = NO;
    [content addSubview:emotionPill];
    self.emotionPillButton = emotionPill;
    [emotionPill mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(emotionTitle.mas_bottom).offset(8);
        make.leading.equalTo(content).offset(16);
        make.bottom.equalTo(content.mas_bottom).offset(-32);
    }];
}

- (UILabel *)smallGrayLabel:(NSString *)text {
    UILabel *lab = [[UILabel alloc] init];
    lab.text = text;
    lab.font = [UIFont systemFontOfSize:12];
    lab.textColor = [UIColor grayColor];
    return lab;
}

- (UILabel *)smallValueLabel {
    UILabel *lab = [[UILabel alloc] init];
    lab.font = [UIFont systemFontOfSize:13];
    lab.textColor = [UIColor blackColor];
    lab.textAlignment = NSTextAlignmentRight;
    return lab;
}

- (UILabel *)pillLabel {
    UILabel *lab = [[UILabel alloc] init];
    lab.font = [UIFont systemFontOfSize:13];
    lab.textColor = PNMatchGreenColor();
    lab.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1.0];
    lab.textAlignment = NSTextAlignmentCenter;
    lab.layer.cornerRadius = 16;
    lab.clipsToBounds = YES;
    lab.contentMode = UIViewContentModeCenter;
    return lab;
}

- (void)fillFakeData {
    // 比赛信息（日期/时间等，先使用静态文案，与效果图一致）
    self.watchStatusLabel.text = @"在球场";
    self.timeLabel.text = @"2025-12-20 21:30";
    self.seatLabel.text = @"VIP看台";
    self.reasonLabel.text = @"球迷";
    self.priceLabel.text = @"55.5";
    
    // 观赛身份、情绪已在 buildUI 中按设计图写死，此处可省略
    
    // 这里暂时不区分每场比赛的具体详情，所有假数据一致即可
    // 如后续需要按场次展示不同内容，可新增字段到 DiscoverMatch 中再填充
}

- (void)onBack {
    [self.navigationController popViewControllerAnimated:YES];
}

@end

