//
//  LegalDocumentViewController.m
//  footBall
//

#import "LegalDocumentViewController.h"
#import <Masonry/Masonry.h>

@interface LegalDocumentViewController ()
@property (nonatomic, copy) NSString *documentTitle;
@property (nonatomic, copy) NSString *resourceName;
@property (nonatomic, strong) UILabel *navTitle;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UILabel *contentLabel;
@end

@implementation LegalDocumentViewController

+ (instancetype)documentWithTitle:(NSString *)title resourceName:(NSString *)resourceName {
    LegalDocumentViewController *vc = [[LegalDocumentViewController alloc] init];
    vc.documentTitle = title ?: @"";
    vc.resourceName = resourceName ?: @"";
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
    self.navTitle.textAlignment = NSTextAlignmentCenter;
    self.navTitle.numberOfLines = 2;
    [nav addSubview:self.navTitle];
    [self.navTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(nav);
        make.centerY.equalTo(back);
        make.leading.greaterThanOrEqualTo(back.mas_trailing).offset(8);
        make.trailing.lessThanOrEqualTo(nav).offset(-16);
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

    self.contentLabel = [UILabel new];
    self.contentLabel.numberOfLines = 0;
    self.contentLabel.textColor = [UIColor colorWithWhite:0.18 alpha:1.0];
    self.contentLabel.font = [UIFont systemFontOfSize:14];
    [self.scrollView addSubview:self.contentLabel];
    [self.contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.scrollView).offset(16);
        make.leading.equalTo(self.view).offset(16);
        make.trailing.equalTo(self.view).offset(-16);
        make.bottom.equalTo(self.scrollView).offset(-24);
    }];
}

- (void)updateLocalizedStrings {
    [super updateLocalizedStrings];
    self.navTitle.text = self.documentTitle;
    self.contentLabel.attributedText = [self attributedBodyText:[self loadDocumentText]];
}

- (NSString *)loadDocumentText {
    if (self.resourceName.length == 0) return @"";
    NSBundle *bundle = [NSBundle mainBundle];
    NSArray<NSString *> *subdirs = @[ @"Resources/Legal", @"Legal" ];
    for (NSString *subdir in subdirs) {
        NSString *path = [bundle pathForResource:self.resourceName ofType:@"txt" inDirectory:subdir];
        if (path.length) {
            NSString *text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
            if (text.length) return text;
        }
    }
    NSString *path = [bundle pathForResource:self.resourceName ofType:@"txt"];
    if (path.length) {
        NSString *text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        if (text.length) return text;
    }
    return @"文档加载失败，请稍后重试。";
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
