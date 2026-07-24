//
//  PNAppVersionManager.m
//  footBall
//

#import "PNAppVersionManager.h"
#import "AppVersionRequest.h"
#import "PNAppVersionInfo.h"
#import "PNForceUpdateViewController.h"
#import "APIError.h"
#import <AFNetworking/AFNetworking.h>

/// 临时关闭版本检查 / 强制更新（改回 YES 即恢复）
static const BOOL kPNAppVersionCheckEnabled = NO;

@interface PNAppVersionManager ()

@property (nonatomic, strong, readwrite, nullable) UIWindow *forceUpdateWindow;
@property (nonatomic, strong, nullable) PNAppVersionInfo *cachedForceInfo;
@property (nonatomic, assign) BOOL isChecking;
@property (nonatomic, strong) NSMutableArray *pendingCompletions;

@end

@implementation PNAppVersionManager

+ (instancetype)shared {
    static PNAppVersionManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PNAppVersionManager alloc] init];
        instance.pendingCompletions = [NSMutableArray array];
    });
    return instance;
}

+ (NSString *)marketingVersion {
    NSString *v = [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"];
    return v.length > 0 ? v : @"0";
}

+ (NSString *)buildNumber {
    NSString *b = [NSBundle mainBundle].infoDictionary[@"CFBundleVersion"];
    return b.length > 0 ? b : @"0";
}

- (void)checkForceUpdateWithCompletion:(void (^)(BOOL, PNAppVersionInfo * _Nullable, NSError * _Nullable))completion {
    if (!completion) return;
    if (!kPNAppVersionCheckEnabled) {
        completion(NO, nil, nil);
        return;
    }
    if (self.forceUpdateWindow) {
        completion(YES, self.cachedForceInfo, nil);
        return;
    }
    [self.pendingCompletions addObject:[completion copy]];
    if (self.isChecking) {
        return;
    }
    self.isChecking = YES;
    [[AppVersionRequest shared] checkVersionSuccess:^(HTTPResponse * _Nullable responseObject) {
        PNAppVersionInfo *info = [responseObject.dataObject isKindOfClass:PNAppVersionInfo.class]
            ? responseObject.dataObject
            : [PNAppVersionInfo yy_modelWithJSON:responseObject.data];
        BOOL needs = info.forceUpdate;
        if (needs) {
            self.cachedForceInfo = info;
        }
        [self finishCheckWithNeeds:needs info:info error:nil];
    } failure:^(NSError * _Nonnull error) {
        [self finishCheckWithNeeds:NO info:nil error:error];
    }];
}

- (void)finishCheckWithNeeds:(BOOL)needs info:(PNAppVersionInfo *)info error:(NSError *)error {
    self.isChecking = NO;
    NSArray *callbacks = [self.pendingCompletions copy];
    [self.pendingCompletions removeAllObjects];
    for (void (^cb)(BOOL, PNAppVersionInfo *, NSError *) in callbacks) {
        cb(needs, info, error);
    }
}

- (void)presentForceUpdateOnWindow:(UIWindow *)window info:(PNAppVersionInfo *)info {
    if (!kPNAppVersionCheckEnabled) return;
    if (!window || !info) return;
    self.cachedForceInfo = info;
    // 已在强制更新页则只刷新文案所需数据，避免重复替换 root
    if (self.forceUpdateWindow && [window.rootViewController isKindOfClass:PNForceUpdateViewController.class]) {
        return;
    }
    // 直接挂到主 window.root，强引用 window；避免额外 overlay + weak 导致弹层被释放、只剩空白启动页
    PNForceUpdateViewController *vc = [[PNForceUpdateViewController alloc] initWithVersionInfo:info];
    window.rootViewController = vc;
    [window makeKeyAndVisible];
    self.forceUpdateWindow = window;
}

- (void)handleAPIErrorIfNeeded:(NSError *)error {
    if (!kPNAppVersionCheckEnabled) return;
    APIError *apiError = [error isKindOfClass:APIError.class] ? (APIError *)error : nil;
    if (![apiError.businessCode isEqualToString:PNAppVersionOutdatedErrorCode]) {
        return;
    }
    PNAppVersionInfo *info = self.cachedForceInfo ?: [self versionInfoFromError:error];
    if (!info) {
        info = [PNAppVersionInfo new];
        info.forceUpdate = YES;
        info.updateTitle = NSLocalizedString(@"force_update_title", nil);
        info.updateMessage = apiError.businessMessage.length > 0
            ? apiError.businessMessage
            : NSLocalizedString(@"force_update_message", nil);
    }
    self.cachedForceInfo = info;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [self keyWindow];
        if (window) {
            [self presentForceUpdateOnWindow:window info:info];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:PNAppVersionForceUpdateRequiredNotification
                                                            object:nil
                                                          userInfo:@{ @"info": info }];
    });
}

- (PNAppVersionInfo *)versionInfoFromError:(NSError *)error {
    NSData *raw = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
    if (![raw isKindOfClass:NSData.class] || raw.length == 0) {
        raw = error.userInfo[@"com.alamofire.serialization.response.error.data"];
    }
    if (![raw isKindOfClass:NSData.class] || raw.length == 0) {
        return nil;
    }
    id json = [NSJSONSerialization JSONObjectWithData:raw options:0 error:nil];
    if (![json isKindOfClass:NSDictionary.class]) {
        return nil;
    }
    id data = ((NSDictionary *)json)[@"data"];
    if (![data isKindOfClass:NSDictionary.class]) {
        return nil;
    }
    return [PNAppVersionInfo yy_modelWithJSON:data];
}

- (nullable UIWindow *)keyWindow {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) continue;
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        for (UIWindow *window in windowScene.windows) {
            if (window.isKeyWindow) return window;
        }
        if (windowScene.windows.firstObject) {
            return windowScene.windows.firstObject;
        }
    }
    return nil;
}

@end
