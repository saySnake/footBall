//
//  APIAppMetadataInterceptor.m
//  footBall
//

#import "APIAppMetadataInterceptor.h"
#import "PNAppVersionManager.h"

static NSString * const kPNHeaderPlatform = @"X-App-Platform";
static NSString * const kPNHeaderVersion = @"X-App-Version";
static NSString * const kPNHeaderBuild = @"X-App-Build";

@implementation APIAppMetadataInterceptor

- (NSURLRequest *)interceptRequest:(NSURLRequest *)request {
    NSMutableURLRequest *mutable = [request mutableCopy];
    [mutable setValue:@"ios" forHTTPHeaderField:kPNHeaderPlatform];
    NSString *version = [PNAppVersionManager marketingVersion];
    NSString *build = [PNAppVersionManager buildNumber];
    if (version.length > 0) {
        [mutable setValue:version forHTTPHeaderField:kPNHeaderVersion];
    }
    if (build.length > 0) {
        [mutable setValue:build forHTTPHeaderField:kPNHeaderBuild];
    }
    return mutable;
}

@end
