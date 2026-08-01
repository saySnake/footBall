//
//  PrivacyAgreementViewController.m
//  footBall
//

#import "PrivacyAgreementViewController.h"
#import <Masonry/Masonry.h>

static UIColor *PNPrivacyPageBg(void) {
    return [UIColor whiteColor];
}

@interface PrivacyAgreementViewController ()
@property (nonatomic, strong) UILabel *navTitle;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *topContentLabel;
@property (nonatomic, strong) UIView *bottomSectionView;
@property (nonatomic, strong) UILabel *bottomContentLabel;
@end

@implementation PrivacyAgreementViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.shouldShowNavigationBar = NO;
    self.view.backgroundColor = PNPrivacyPageBg();
}

- (void)setupUI {
    UIView *nav = [UIView new];
    nav.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:nav];
    [nav mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
        make.height.mas_equalTo(88);
    }];

    UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *backImg = [UIImage imageNamed:@"nav_back"];
    if (!backImg) backImg = [UIImage imageNamed:@"ad_left"];
    if (!backImg && @available(iOS 13.0, *)) {
        backImg = [UIImage systemImageNamed:@"arrow.left"];
    }
    if (backImg) {
        [back setImage:[backImg imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        back.tintColor = [UIColor blackColor];
    }
    back.imageView.contentMode = UIViewContentModeScaleAspectFit;
    back.adjustsImageWhenHighlighted = NO;
    [back addTarget:self action:@selector(onBack) forControlEvents:UIControlEventTouchUpInside];
    [nav addSubview:back];
    [back mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(nav).offset(16);
        make.bottom.equalTo(nav).offset(-10);
        make.size.mas_equalTo(CGSizeMake(24, 24));
    }];

    self.navTitle = [UILabel new];
    self.navTitle.font = [UIFont boldSystemFontOfSize:17];
    self.navTitle.textColor = [UIColor blackColor];
    [nav addSubview:self.navTitle];
    [self.navTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(nav);
        make.centerY.equalTo(back);
    }];

    self.scrollView = [UIScrollView new];
    self.scrollView.backgroundColor = [UIColor whiteColor];
    self.scrollView.showsVerticalScrollIndicator = YES;
    [self.view addSubview:self.scrollView];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(nav.mas_bottom);
        make.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
    }];

    self.contentView = [UIView new];
    self.contentView.backgroundColor = [UIColor whiteColor];
    [self.scrollView addSubview:self.contentView];
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
    }];

    self.topContentLabel = [UILabel new];
    self.topContentLabel.numberOfLines = 0;
    self.topContentLabel.textColor = [UIColor colorWithWhite:0.18 alpha:1.0];
    self.topContentLabel.font = [UIFont systemFontOfSize:14];
    [self.contentView addSubview:self.topContentLabel];
    [self.topContentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(16);
        make.leading.equalTo(self.contentView).offset(16);
        make.trailing.equalTo(self.contentView).offset(-16);
    }];

    self.bottomSectionView = [UIView new];
    self.bottomSectionView.backgroundColor = [UIColor whiteColor];
    [self.contentView addSubview:self.bottomSectionView];
    [self.bottomSectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.topContentLabel.mas_bottom).offset(16);
        make.leading.trailing.equalTo(self.contentView);
        make.bottom.equalTo(self.contentView);
    }];

    self.bottomContentLabel = [UILabel new];
    self.bottomContentLabel.numberOfLines = 0;
    self.bottomContentLabel.textColor = [UIColor colorWithWhite:0.45 alpha:1.0];
    self.bottomContentLabel.font = [UIFont systemFontOfSize:14];
    [self.bottomSectionView addSubview:self.bottomContentLabel];
    [self.bottomContentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bottomSectionView).offset(16);
        make.leading.equalTo(self.bottomSectionView).offset(16);
        make.trailing.equalTo(self.bottomSectionView).offset(-16);
        make.bottom.equalTo(self.bottomSectionView).offset(-24);
    }];
}

- (NSAttributedString *)privacyText:(NSString *)text {
    if (text.length == 0) return [[NSAttributedString alloc] initWithString:@""];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineSpacing = 4;
    style.paragraphSpacing = 2;
    return [[NSAttributedString alloc] initWithString:text attributes:@{
        NSFontAttributeName: [UIFont systemFontOfSize:14],
        NSForegroundColorAttributeName: [UIColor colorWithWhite:0.18 alpha:1.0],
        NSParagraphStyleAttributeName: style
    }];
}

- (void)updateLocalizedStrings {
    [super updateLocalizedStrings];
    self.navTitle.text = NSLocalizedString(@"settings_privacy", nil);

    NSString *topText = @"加入和使用“游牧足球”表明您已经阅读并同意本协议，您的会员活动将遵从本协议。鉴于“游牧足球”并非关乎国计民生或者具有垄断性质的行业及企业，如您对本协议内容不认同，您完全可以选择不注册、不加入或不使用“游牧足球”。\n本协议由您与北京京昊宇文化有限公司共同缔结，具有合同效力。\n本协议中，协议双方合称“协议方”，北京京昊宇文化有限公司在本协议中亦称为“游牧足球”。\n注册地址/联系地址：北京市（请向客服咨询最新注册地址）。";
    NSString *bottomText = @"1. 协议范围与构成\n本协议内容包括协议正文及“游牧足球”已经发布或将来可能发布的各类规则、公告、说明、指引等内容。上述规则、公告、说明、指引均为本协议不可分割的组成部分，与本协议正文具有同等法律效力。\n除另行明确声明外，任何由“游牧足球”及其关联方提供的服务，均受本协议约束。法律法规另有强制性规定的，从其规定。\n2. 协议的接受与生效\n您在注册“游牧足球”账户时点击“我已阅读并同意《游牧足球用户使用协议》”或进行其他具有确认意义的操作，即视为您已阅读、理解并接受本协议及相关规则，并同意受其约束。\n您应当在使用“游牧足球”服务前认真阅读本协议全部内容，并确保充分理解。如您对本协议有任何疑问，可向“游牧足球”客服或运营方咨询。\n但无论您事实上是否在使用服务前认真阅读本协议内容，只要您完成注册、登录、访问、使用或继续使用“游牧足球”服务，即视为您已接受本协议。\n3. 用户承诺\n您承诺接受并遵守本协议的全部约定。\n如您不同意本协议任一内容，您应立即停止注册程序，并停止使用“游牧足球”提供的全部服务。";
    self.topContentLabel.attributedText = [self privacyText:topText];
    self.bottomContentLabel.attributedText = [self privacyText:bottomText];
    NSMutableAttributedString *bottomAttr = [[NSMutableAttributedString alloc] initWithAttributedString:self.bottomContentLabel.attributedText ?: [[NSAttributedString alloc] initWithString:bottomText]];
    [bottomAttr addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithWhite:0.45 alpha:1.0] range:NSMakeRange(0, bottomAttr.length)];
    self.bottomContentLabel.attributedText = bottomAttr;
}

- (void)onBack {
    [self.navigationController popViewControllerAnimated:YES];
}

@end

