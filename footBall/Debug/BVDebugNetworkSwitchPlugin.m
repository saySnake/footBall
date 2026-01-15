//
//  BVDebugNetworkSwitchPlugin.m
//  Bhex
//
//  Created by DZSB-001968 on 6.12.23.
//  Copyright © 2023 Bhex. All rights reserved.
//

#ifdef DEBUG

#import "BVDebugNetworkSwitchPlugin.h"
#import "BVSwitchNewworkViewController.h"
@import DoraemonKit;

@interface BVDebugNetworkSwitchPlugin()<DoraemonPluginProtocol>
@end

@implementation BVDebugNetworkSwitchPlugin

- (void)pluginDidLoad {
    BVSwitchNewworkViewController *vc = [[BVSwitchNewworkViewController alloc] init];
    [[DoraemonHomeWindow shareInstance].nav pushViewController:vc animated:YES];
}

@end

#endif
