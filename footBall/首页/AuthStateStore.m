//
//  AuthStateStore.m
//  footBall
//

#import "AuthStateStore.h"

static NSString * const kRealNameCompletedKey = @"auth_realname_completed";
static NSString * const kRealNameFrontKey = @"auth_realname_front_data";
static NSString * const kRealNameBackKey = @"auth_realname_back_data";
static NSString * const kProfessionalCompletedKey = @"auth_professional_completed";
static NSString * const kProfessionalImagesKey = @"auth_professional_images";

@implementation AuthStateStore

#pragma mark - 实名认证

+ (BOOL)isRealNameAuthCompleted {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kRealNameCompletedKey];
}

+ (void)setRealNameAuthCompleted:(BOOL)completed {
    [[NSUserDefaults standardUserDefaults] setBool:completed forKey:kRealNameCompletedKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)saveRealNameFrontImage:(UIImage *)front backImage:(UIImage *)back {
    // ⚠️ 安全：身份证正反面属于敏感个人信息，禁止写入 NSUserDefaults（会被 iTunes/iCloud 备份、无加密）。
    // 当前全工程无任何调用方读取这两个方法（realNameFrontImage/realNameBackImage 也无调用），
    // 因此这里直接 no-op，避免误用造成隐私泄露。如未来需要本地缓存身份证图片，
    // 请改用 Keychain（少量）/ 加密文件（Library/Application Support，并设置 NSURLIsExcludedFromBackupKey）。
    (void)front;
    (void)back;
}

+ (UIImage *)realNameFrontImage {
    // 见 saveRealNameFrontImage: 的说明：已停止持久化，恒返回 nil
    return nil;
}

+ (UIImage *)realNameBackImage {
    return nil;
}

#pragma mark - 职业认证

+ (BOOL)isProfessionalAuthCompleted {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kProfessionalCompletedKey];
}

+ (void)setProfessionalAuthCompleted:(BOOL)completed {
    [[NSUserDefaults standardUserDefaults] setBool:completed forKey:kProfessionalCompletedKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)saveProfessionalImages:(NSArray<UIImage *> *)images {
    // ⚠️ 安全：职业认证图片同样属于敏感信息，禁止写入 NSUserDefaults。
    // 当前全工程无调用方读取（professionalImages 无调用），直接 no-op。
    (void)images;
}

+ (NSArray<UIImage *> *)professionalImages {
    return @[];
}

@end
