//
//  UIImage+Theme.m
//  footBall
//
//  Created on 2026/1/15.
//

#import <UIKit/UIKit.h>
#import "ThemeImageManager.h"

@implementation UIImage (Theme)

+ (nullable UIImage *)themeImageNamed:(NSString *)imageName {
    return [[ThemeImageManager sharedManager] imageNamed:imageName];
}

+ (nullable UIImage *)themeImageNamed:(NSString *)imageName darkMode:(BOOL)isDarkMode {
    return [[ThemeImageManager sharedManager] imageNamed:imageName darkMode:isDarkMode];
}

@end
