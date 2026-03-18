//
//  HTTPHeaders.m
//  footBall
//
//  Created by LWJ on 2026/3/14.
//

#import "HTTPHeaders.h"
static NSDictionary *__header = nil;
@implementation HTTPHeaders
+(NSDictionary *)commonHeaders {
    if (__header == nil) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[@""] = @"";
        __header = dict.copy;
    }
    return __header;
}
+ (void)setupRequestSerializer:(AFHTTPRequestSerializer *)serializer headers:(NSDictionary *)headers{
    //
    [headers enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [serializer setValue:obj forHTTPHeaderField:key];
    }];
    [HTTPHeaders.commonHeaders enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [serializer setValue:obj forHTTPHeaderField:key];
    }];
}
@end
