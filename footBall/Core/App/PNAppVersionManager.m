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

@interface PNAppVersionManager ()

@property (nonatomic, weak, readwrite) UIWindow *forceUpdateWindow;
@property (nonatomic, strong, nullable) PNAppVersionInfo *cachedForceInfo;
@property (nonatomic, assign) BOOL isChecking;

@end

@implementation PNAppVersionManager

+ (instancetype)shared {
    static PNAppVersionManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PNAppVersionManager alloc] init];
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
    if (self.forceUpdateWindow) {
        completion(YES, self.cachedForceInfo, nil);
        return;
    }
    if (self.isChecking) {
        completion(NO, nil, nil);
        return;
    }
    self.isChecking = YES;
    [[AppVersionRequest shared] checkVersionSuccess:^(HTTPResponse * _Nullable responseObject) {
        self.isChecking = NO;
        PNAppVersionInfo *info = [responseObject.dataObject isKindOfClass:PNAppVersionInfo.class]
            ? responseObject.dataObject
            : [PNAppVersionInfo yy_modelWithJSON:responseObject.data];
        BOOL needs = info.forceUpdate;
        if (needs) {
            self.cachedForceInfo = info;
        }
        completion(needs, info, nil);
    } failure:^(NSError * _Nonnull error) {
        self.isChecking = NO;
        completion(NO, nil, error);
    }];
}

- (void)presentForceUpdateOnWindow:(UIWindow *)window info:(PNAppVersionInfo *)info {
    if (!window || !info) return;
    self.cachedForceInfo = info;
    if (self.forceUpdateWindow) {
        return;
    }
    PNForceUpdateViewController *vc = [[PNForceUpdateViewController alloc] initWithVersionInfo:info];
    UIWindow *overlay = [[UIWindow alloc] initWithWindowScene:window.windowScene];
    overlay.frame = window.bounds;
    overlay.windowLevel = UIWindowLevelAlert + 1;
    overlay.rootViewController = vc;
    overlay.hidden = NO;
    [overlay makeKeyAndVisible];
    self.forceUpdateWindow = overlay;
}

- (void)handleAPIErrorIfNeeded:(NSError *)error {
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
