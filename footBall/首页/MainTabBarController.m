//
//  MainTabBarController.m
//  footBall
//

#import "MainTabBarController.h"
#import "HomeViewController.h"
#import "DiscoverViewController.h"
#import "LocationViewController.h"
#import "ProfileViewController.h"

@implementation MainTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];

    HomeViewController *home = [[HomeViewController alloc] init];
    UINavigationController *navHome = [[UINavigationController alloc] initWithRootViewController:home];
    navHome.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"tab_home", nil)
                                                       image:[self imageWithSystemName:@"house.fill"]
                                                         tag:0];

    DiscoverViewController *discover = [[DiscoverViewController alloc] init];
    UINavigationController *navDiscover = [[UINavigationController alloc] initWithRootViewController:discover];
    navDiscover.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"tab_discover", nil)
                                                          image:[self imageWithSystemName:@"bolt.fill"]
                                                            tag:1];

    LocationViewController *location = [[LocationViewController alloc] init];
    UINavigationController *navLocation = [[UINavigationController alloc] initWithRootViewController:location];
    navLocation.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"tab_location", nil)
                                                          image:[self imageWithSystemName:@"location.fill"]
                                                            tag:2];

    ProfileViewController *profile = [[ProfileViewController alloc] init];
    UINavigationController *navProfile = [[UINavigationController alloc] initWithRootViewController:profile];
    navProfile.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"tab_profile", nil)
                                                        image:[self imageWithSystemName:@"person.fill"]
                                                          tag:3];

    self.viewControllers = @[ navHome, navDiscover, navLocation, navProfile ];
}

- (UIImage *)imageWithSystemName:(NSString *)name {
    if (@available(iOS 13.0, *)) {
        return [UIImage systemImageNamed:name];
    }
    return nil;
}

@end
