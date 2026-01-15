//
//  NSObject+BVDebugMemoryLeak.m
//  Bhex
//
//  Created by leidi on 2024/1/19.
//  Copyright © 2024 Bhex. All rights reserved.
//

#import "NSObject+BVDebugMemoryLeak.h"

#ifdef DEBUG
#if __has_include(<MLeaksFinder/MLeaksFinder.h>)
#import <MLeaksFinder/MLeaksFinder.h>
#endif
#import <objc/runtime.h>
#endif

@implementation NSObject (BVDebugMemoryLeak)

#ifdef DEBUG
+ (void)load {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"isOpenMemoryLeak"]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{
            SEL originSel = @selector(willDealloc);
            SEL swizzleSel = @selector(overrideWillDealloc);
            
            // 检查原始方法是否存在
            Method originalMethod = class_getInstanceMethod(self, originSel);
            if (originalMethod) {
                // 添加交换方法
                Method swizzleMethod = class_getInstanceMethod(self, swizzleSel);
                if (swizzleMethod) {
                    // 进行方法交换
                    method_exchangeImplementations(originalMethod, swizzleMethod);
                }
            }
        });
    }
}

- (BOOL)overrideWillDealloc {
    NSLog(@"override MemoryLeak check");
    return NO;
}
#endif

@end
