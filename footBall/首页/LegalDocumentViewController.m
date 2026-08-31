//
//  LegalDocumentViewController.m
//  footBall
//

#import "LegalDocumentViewController.h"
#import "LegalDocumentCache.h"
#import <Masonry/Masonry.h>

@interface LegalDocumentViewController ()
@property (nonatomic, copy) NSString *documentTitle;
@property (nonatomic, copy) NSString *resourceName;
@property (nonatomic, strong) UILabel *navTitle;
@property (nonatomic, strong) UITextView *contentTextView;
@end

@implementation LegalDocumentViewController

+ (instancetype)documentWithTitle:(NSString *)title resourceName:(NSString *)resourceName {
    LegalDocumentViewController *vc = [[LegalDocumentViewController alloc] init];
    vc.documentTitle = title ?: @"";
    vc.resourceName = resourceName ?: @"";
    vc.hidesBottomBarWhenPushed = YES;
    vc.preloadedText = [LegalDocumentCache textForResource:resourceName];
    return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.shouldShowNavigationBar = NO;
    self.view.backgroundColor = [UIColor whiteColor];
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
    if (@available(iOS 13.0, *)) {
        if (!backImg) backImg = [UIImage systemImageNamed:@"arrow.left"];
    }
    if (backImg) {
        [back setImage:[backImg imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        back.tintColor = [UIColor blackColor];
    }
    back.imageView.contentMode = UIViewContentModeScaleAspectFit;
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
    self.navTitle.textAlignment = NSTextAlignmentCenter;
    self.navTitle.numberOfLines = 2;
    [nav addSubview:self.navTitle];
    [self.navTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(nav);
        make.centerY.equalTo(back);
        make.leading.greaterThanOrEqualTo(back.mas_trailing).offset(8);
        make.trailing.lessThanOrEqualTo(nav).offset(-16);
    }];

    self.contentTextView = [UITextView new];
    self.contentTextView.editable = NO;
    self.contentTextView.selectable = YES;
    self.contentTextView.scrollEnabled = YES;
    self.contentTextView.showsVerticalScrollIndicator = YES;
    self.contentTextView.backgroundColor = [UIColor whiteColor];
    self.contentTextView.textContainerInset = UIEdgeInsetsMake(16, 12, 24, 12);
    self.contentTextView.textContainer.lineFragmentPadding = 0;
    [self.view addSubview:self.contentTextView];
    [self.contentTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(nav.mas_bottom);
        make.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
    }];
}

- (void)updateLocalizedStrings {
    [super updateLocalizedStrings];
    self.navTitle.text = self.documentTitle;
    [self applyDocumentText:self.preloadedText ?: @""];
    if (self.preloadedText.length == 0 && self.resourceName.length > 0) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            NSString *text = [LegalDocumentCache textForResource:weakSelf.resourceName] ?: @"文档加载失败，请稍后重试。";
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) self = weakSelf;
                if (!self) return;
                self.preloadedText = text;
                [self applyDocumentText:text];
            });
        });
    }
}

- (void)applyDocumentText:(NSString *)text {
    self.contentTextView.attributedText = [self attributedBodyText:text];
}

- (NSAttributedString *)attributedBodyText:(NSString *)text {
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

- (void)onBack {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
