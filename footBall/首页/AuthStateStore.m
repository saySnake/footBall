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
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (front) {
        NSData *data = UIImageJPEGRepresentation(front, 0.7);
        [ud setObject:data forKey:kRealNameFrontKey];
    } else {
        [ud removeObjectForKey:kRealNameFrontKey];
    }
    if (back) {
        NSData *data = UIImageJPEGRepresentation(back, 0.7);
        [ud setObject:data forKey:kRealNameBackKey];
    } else {
        [ud removeObjectForKey:kRealNameBackKey];
    }
    [ud synchronize];
}

+ (UIImage *)realNameFrontImage {
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:kRealNameFrontKey];
    return data && [data isKindOfClass:[NSData class]] ? [UIImage imageWithData:(NSData *)data] : nil;
}

+ (UIImage *)realNameBackImage {
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:kRealNameBackKey];
    return data && [data isKindOfClass:[NSData class]] ? [UIImage imageWithData:(NSData *)data] : nil;
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
    if (!images.count) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kProfessionalImagesKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return;
    }
    NSMutableArray<NSData *> *arr = [NSMutableArray array];
    for (UIImage *img in images) {
        NSData *data = UIImageJPEGRepresentation(img, 0.7);
        if (data) [arr addObject:data];
    }
    [[NSUserDefaults standardUserDefaults] setObject:arr forKey:kProfessionalImagesKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSArray<UIImage *> *)professionalImages {
    id obj = [[NSUserDefaults standardUserDefaults] objectForKey:kProfessionalImagesKey];
    if (![obj isKindOfClass:[NSArray class]]) return @[];
    NSMutableArray<UIImage *> *result = [NSMutableArray array];
    for (id item in (NSArray *)obj) {
        if ([item isKindOfClass:[NSData class]]) {
            UIImage *img = [UIImage imageWithData:(NSData *)item];
            if (img) [result addObject:img];
        }
    }
    return [result copy];
}

@end
