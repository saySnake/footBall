//
//  APICurlLogInterceptor.m
//  footBall
//
//  只在请求异常时打印 curl（网络错误 / success==false）
//

#import "APICurlLogInterceptor.h"
#import <objc/runtime.h>

static const void *kCurlStringKey = &kCurlStringKey;

@implementation APICurlLogInterceptor

+ (instancetype)shared {
    static APICurlLogInterceptor *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[APICurlLogInterceptor alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
#ifdef DEBUG
        _enabled = YES;
#else
        _enabled = NO;
#endif
        _logResponseBody = NO;
    }
    return self;
}

#pragma mark - curl 构建

+ (NSString *)curlFromRequest:(NSURLRequest *)request {
    if (!request) return nil;
    NSMutableString *curl = [NSMutableString stringWithString:@"curl -k"];
    [curl appendFormat:@" -X %@", request.HTTPMethod ?: @"GET"];
    for (NSString *key in request.allHTTPHeaderFields) {
        NSString *escaped = [request.allHTTPHeaderFields[key] stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"];
        [curl appendFormat:@" \\\n  -H '%@: %@'", key, escaped];
    }
    if (request.HTTPBody.length > 0) {
        NSString *body = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
        if (body) {
            [curl appendFormat:@" \\\n  -d '%@'", [body stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"]];
        }
    }
    [curl appendFormat:@" \\\n  '%@'", request.URL.absoluteString];
    return curl;
}

#pragma mark - APIRequestInterceptor

/// 请求发出前：缓存 curl 字符串，不打印
- (nullable NSURLRequest *)interceptRequest:(NSURLRequest *)request {
    if (!self.enabled) return request;
    NSString *curl = [APICurlLogInterceptor curlFromRequest:request];
    if (curl) {
        objc_setAssociatedObject(request, kCurlStringKey, curl, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    return request;
}

/// 响应回来：只在 success==false 时打印
- (BOOL)interceptResponse:(id)response task:(NSURLSessionDataTask *)task {
    if (!self.enabled) return YES;
    BOOL isBusinessError = NO;
    if ([response isKindOfClass:[NSDictionary class]]) {
        id successVal = response[@"success"];
        if (successVal && [successVal respondsToSelector:@selector(boolValue)]) {
            isBusinessError = ![successVal boolValue];
        }
    }
    if (isBusinessError) {
        [self printCurlForTask:task tag:@"BIZ ERROR" extra:response];
    }
    return YES;
}

/// 网络错误时打印
- (nullable NSError *)interceptError:(NSError *)error task:(NSURLSessionDataTask *)task {
    if (!self.enabled) return error;
    NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)task.response;
    NSString *tag = [NSString stringWithFormat:@"HTTP %ld", (long)httpResp.statusCode];
    [self printCurlForTask:task tag:tag extra:error.localizedDescription];
    return error;
}

#pragma mark - 打印

- (void)printCurlForTask:(NSURLSessionDataTask *)task tag:(NSString *)tag extra:(id)extra {
    NSURLRequest *req = task.originalRequest;
    NSString *curl = objc_getAssociatedObject(req, kCurlStringKey);
    if (!curl) {
        curl = [APICurlLogInterceptor curlFromRequest:req];
    }
    NSMutableString *log = [NSMutableString string];
    [log appendString:@"\n🔗 [CURL] ─── 请求异常 ───────────────────"];
    [log appendFormat:@"\n⚠️ %@", tag];
    [log appendFormat:@"\n%@", curl ?: @"(无法构建curl)"];
    if (self.logResponseBody && extra) {
        NSString *snippet = nil;
        if ([extra isKindOfClass:[NSDictionary class]] || [extra isKindOfClass:[NSArray class]]) {
            NSData *d = [NSJSONSerialization dataWithJSONObject:extra options:0 error:nil];
            if (d) snippet = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
        } else {
            snippet = [extra description];
        }
        if (snippet.length > 500) snippet = [[snippet substringToIndex:500] stringByAppendingString:@"..."];
        [log appendFormat:@"\n📄 %@", snippet];
    }
    [log appendString:@"\n🔗 ──────────────────────────────────────"];
    NSLog(@"%@", log);
}

@endrespondsToSelector:@selector(boolValue)]) {
ubstringToIndex:500] stringByAppendingString:@"..."];
        }
        [log appendFormat:@"\n📄 %@", snippet];
    }

    [log appendString:@"\n🔗 ──────────────────────────────────────"];
    NSLog(@"%@", log);
}

@end
;
        }
        if (snippet.length > 500) {
            snippet = [[snippet sndFormat:@"\n%@", curl ?: @"(无法构建curl)"];

    if (self.logResponseBody && extra) {
        NSString *snippet = nil;
        if ([extra isKindOfClass:[NSDictionary class]] || [extra isKindOfClass:[NSArray class]]) {
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:extra options:0 error:nil];
            if (jsonData) {
                snippet = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            }
        } else {
            snippet = [extra description] 请求异常 ───────────────────"];
    [log appendFormat:@"\n⚠️ %@", tag];
    [log appeiption];

    return error;
}

#pragma mark - 打印

- (void)printCurlForTask:(NSURLSessionDataTask *)task tag:(NSString *)tag extra:(id)extra {
    NSURLRequest *originalRequest = task.originalRequest;
    NSString *curl = objc_getAssociatedObject(originalRequest, kCurlStringKey);

    // 如果 associated object 丢了（比如重定向），重新构建
    if (!curl) {
        curl = [APICurlLogInterceptor curlFromRequest:originalRequest];
    }

    NSMutableString *log = [NSMutableString string];
    [log appendString:@"\n🔗 [CURL] ───ng)httpResp.statusCode];
    [self printCurlForTask:task tag:tag extra:error.localizedDescr            isBusinessError = ![successVal boolValue];
        }
    }

    if (isBusinessError) {
        [self printCurlForTask:task tag:@"BIZ ERROR" extra:response];
    }

    return YES;
}

/// 网络错误时打印
- (nullable NSError *)interceptError:(NSError *)error task:(NSURLSessionDataTask *)task {
    if (!self.enabled) return error;

    NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)task.response;
    NSString *tag = [NSString stringWithFormat:@"HTTP %ld", (lo