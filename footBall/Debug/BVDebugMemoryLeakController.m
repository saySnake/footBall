//
//  BVDebugMemoryLeakController.m
//  Bhex
//
//  Created by DZSB-001968 on 7.12.23.
//  Copyright © 2023 Bhex. All rights reserved.
//

#ifdef DEBUG
#import "BVDebugMemoryLeakController.h"
@import DoraemonKit;
#import <Masonry/Masonry.h>
#import <MBProgressHUD/MBProgressHUD.h>

@interface BVDebugMemoryLeakController ()
@property (strong, nonatomic) UISwitch *memoryLeakSwitch;
@property (strong, nonatomic) UILabel *memoryLeakLabel;
@end

@implementation BVDebugMemoryLeakController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"内存检测";
    self.view.backgroundColor = UIColor.whiteColor;
    
    [self.view addSubview:self.memoryLeakLabel];
    [self.view addSubview:self.memoryLeakSwitch];
    
    [self.memoryLeakLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.view.mas_leading).offset(20);
        make.top.equalTo(self.view.mas_top).offset(120);
    }];
    
    [self.memoryLeakSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.view.mas_trailing).offset(-20);
        make.centerY.equalTo(self.memoryLeakLabel.mas_centerY);
    }];
    
    BOOL isOn = [[NSUserDefaults standardUserDefaults] boolForKey:@"isOpenMemoryLeak"];
    self.memoryLeakSwitch.on = isOn;
}

- (UILabel *)memoryLeakLabel {
    if (!_memoryLeakLabel) {
        _memoryLeakLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _memoryLeakLabel.textColor = UIColor.blackColor;
        _memoryLeakLabel.font = [UIFont systemFontOfSize:14];
        _memoryLeakLabel.text = @"是否开启内存检测";
    }
    return _memoryLeakLabel;
}

- (UISwitch *)memoryLeakSwitch {
    if (!_memoryLeakSwitch) {
        _memoryLeakSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        [_memoryLeakSwitch addTarget:self action:@selector(memoryLeakSwitchChangeValue) forControlEvents:UIControlEventValueChanged];
    }
    return _memoryLeakSwitch;
}

- (void)memoryLeakSwitchChangeValue {
    [self.navigationController popToRootViewControllerAnimated:YES];
    [[DoraemonHomeWindow shareInstance] hide];
    [[NSUserDefaults standardUserDefaults] setBool:self.memoryLeakSwitch.isOn forKey:@"isOpenMemoryLeak"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSString *notiMsg;
    if (self.memoryLeakSwitch.isOn) {
        notiMsg = @"内存检测已开启, APP即将关闭在3秒后关闭,请重新打开";
    } else {
        notiMsg = @"内存检测已关闭, APP即将关闭在3秒后关闭,请重新打开";
    }
    
    // 使用标准 MBProgressHUD API 显示警告消息
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
        hud.label.text = notiMsg;
        hud.label.numberOfLines = 0;
        hud.minShowTime = 3.0;
        [hud hideAnimated:YES afterDelay:3.0];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        exit(0);
    });
}

@end

#endif
