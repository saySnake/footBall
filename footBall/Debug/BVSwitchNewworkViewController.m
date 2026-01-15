//
//  BVSwitchNewworkViewController.m
//  Bhex
//
//  Created by DZSB-001968 on 6.12.23.
//  Copyright © 2023 Bhex. All rights reserved.
//

#ifdef DEBUG
#import "BVSwitchNewworkViewController.h"
#import "BVAPPEnvironmentHostManager.h"
#import "APIEnvironmentManager.h"
#import "APIServerConfig.h"
@import DoraemonKit;
#import <MBProgressHUD/MBProgressHUD.h>

@interface BVSwitchNewworkViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSMutableArray *datasrouce;
@end

@implementation BVSwitchNewworkViewController

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tableView.frame = self.view.frame;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"切换环境";
    self.view.backgroundColor = UIColor.whiteColor;
    
    [self.view addSubview:self.tableView];
    
    [[BVAPPEnvironmentHostManager shareInstance].datasource enumerateObjectsUsingBlock:^(BVAPPEnvironmentHostItemModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([[BVAPPEnvironmentHostManager shareInstance].currentSelected.displayName isEqualToString:obj.displayName]) {
            obj.isSelected = YES;
        } else {
            obj.isSelected = NO;
        }
        
        [self.datasrouce addObject:obj];
    }];
    [self.tableView reloadData];
}

- (NSMutableArray *)datasrouce {
    if (!_datasrouce) {
        _datasrouce = @[].mutableCopy;
    }
    return _datasrouce;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.estimatedRowHeight = 80;
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    return _tableView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.datasrouce.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell" forIndexPath:indexPath];
    BVAPPEnvironmentHostItemModel *mdoel = self.datasrouce[indexPath.row];
    cell.textLabel.text = mdoel.displayName;
    if (mdoel.isSelected) {
        cell.textLabel.textColor = UIColor.redColor;
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.textLabel.textColor = UIColor.blackColor;
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    BVAPPEnvironmentHostItemModel *mdoel = self.datasrouce[indexPath.row];
    [self.navigationController popToRootViewControllerAnimated:YES];
    [[DoraemonHomeWindow shareInstance] hide];
    
    // 使用标准 MBProgressHUD API 显示警告消息
    NSString *message = [NSString stringWithFormat:@"已切换环境到[%@],APP即将关闭在3秒后关闭,请重新打开", mdoel.displayName];
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    if (!keyWindow) {
        NSArray *windows = [UIApplication sharedApplication].windows;
        for (UIWindow *window in windows) {
            if (window.isKeyWindow) {
                keyWindow = window;
                break;
            }
        }
    }
    if (keyWindow) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:keyWindow animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = message;
        hud.label.numberOfLines = 0;
        hud.minShowTime = 3.0;
        [hud hideAnimated:YES afterDelay:3.0];
    }
    
    // 重新配置域名 - 根据选择的环境切换到对应的 APIEnvironment
    APIEnvironment targetEnvironment = APIEnvironmentTest; // 默认测试环境
    
    // 根据 productFlag 确定目标环境
    // productFlag: 1=生产, 2=UAT, 3=测试
    if (mdoel.productFlag == 1) {
        // 生产环境
        targetEnvironment = APIEnvironmentAppStore;
    } else if (mdoel.productFlag == 2) {
        // UAT环境
        targetEnvironment = APIEnvironmentUAT;
    } else if (mdoel.productFlag == 3) {
        // 测试环境
        targetEnvironment = APIEnvironmentTest;
    }
    
    // 更新服务器地址配置（从 domainUrl 提取）
    if (mdoel.domainUrl && mdoel.domainUrl.length > 0) {
        [[APIServerConfigManager sharedManager] setServerURL:mdoel.domainUrl 
                                               forEnvironment:targetEnvironment];
        NSLog(@"✅ 已更新服务器地址: %@ -> %@", 
              [APIEnvironmentManager displayNameForEnvironment:targetEnvironment],
              mdoel.domainUrl);
    }
    
    // 切换到目标环境
    [[APIEnvironmentManager sharedManager] switchToEnvironment:targetEnvironment];
    
    NSLog(@"✅ 已切换到环境: %@, Base URL: %@", 
          [APIEnvironmentManager displayNameForEnvironment:targetEnvironment],
          [[APIEnvironmentManager sharedManager] currentBaseURL]);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        exit(0);
    });
    
    NSString *bundleIdentifier = NSBundle.mainBundle.bundleIdentifier;
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:bundleIdentifier];
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in [cookieStorage cookies]) {
        [cookieStorage deleteCookie:cookie];
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *doccumentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [doccumentPaths firstObject];
    NSError *error;
    NSArray *filePaths = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:&error];
    if (error) {
        NSLog(@"error:%@", error);
    } else {
        for (NSString *filePath in filePaths) {
            NSString *fullPath = [documentsDirectory stringByAppendingPathComponent:filePath];
            [fileManager removeItemAtPath:fullPath error:&error];
        }
    }
    
    [[BVAPPEnvironmentHostManager shareInstance] switchEnvironmentHost:indexPath.row];
    
}
@end

#endif
