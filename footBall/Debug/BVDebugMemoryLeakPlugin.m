//
//  BVDebugMemoryLeakPlugin.m
//  Bhex
//
//  Created by DZSB-001968 on 7.12.23.
//  Copyright © 2023 Bhex. All rights reserved.
//

#ifdef DEBUG
#import "BVDebugMemoryLeakPlugin.h"
#import "BVDebugMemoryLeakController.h"
@import DoraemonKit;

@interface BVDebugMemoryLeakPlugin()<DoraemonPluginProtocol>
@end

@implementation BVDebugMemoryLeakPlugin

- (void)pluginDidLoad {
    BVDebugMemoryLeakController *vc = [[BVDebugMemoryLeakController alloc] init];
    [[DoraemonHomeWindow shareInstance].nav pushViewController:vc animated:YES];
}

@end

#endif
