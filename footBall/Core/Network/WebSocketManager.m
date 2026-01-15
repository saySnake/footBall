//
//  WebSocketManager.m
//  footBall
//
//  Created on 2026/1/15.
//

#import "WebSocketManager.h"
#import "WebSocketEnvironmentManager.h"
#import <SocketRocket/SocketRocket.h>

@interface WebSocketManager () <SRWebSocketDelegate>

@property (nonatomic, strong) SRWebSocket *webSocket;
@property (nonatomic, assign) WebSocketStatus status;
@property (nonatomic, strong) NSString *URLString;
@property (nonatomic, strong) NSArray<NSString *> *protocols;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *headers;
@property (nonatomic, assign) NSInteger reconnectCount;
@property (nonatomic, strong) NSTimer *reconnectTimer;
@property (nonatomic, strong) NSTimer *heartbeatTimer;
@property (nonatomic, strong) NSMutableArray<id> *messageQueue; // 消息队列
@property (nonatomic, strong) NSMutableArray<id> *cachedMessages; // 缓存的消息

@end

@implementation WebSocketManager

+ (instancetype)sharedManager {
    static WebSocketManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WebSocketManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _status = WebSocketStatusDisconnected;
        _autoReconnect = YES;
        _reconnectInterval = 3.0;
        _maxReconnectCount = 5;
        _reconnectCount = 0;
        _enableHeartbeat = NO;
        _heartbeatInterval = 30.0;
        _connectTimeout = 30.0;
        _cacheMessagesWhenDisconnected = NO;
        _maxCachedMessages = 100;
        _messageQueue = [NSMutableArray array];
        _cachedMessages = [NSMutableArray array];
    }
    return self;
}

- (void)connectWithURLString:(NSString *)URLString protocols:(NSArray<NSString *> *)protocols {
    [self connectWithURLString:URLString protocols:protocols headers:nil];
}

- (void)connectWithURLString:(NSString *)URLString protocols:(NSArray<NSString *> *)protocols headers:(NSDictionary<NSString *, NSString *> *)headers {
    if (self.status == WebSocketStatusConnected || self.status == WebSocketStatusConnecting) {
        NSLog(@"WebSocket已连接或正在连接中");
        return;
    }
    
    self.URLString = URLString;
    self.protocols = protocols;
    self.headers = headers;
    
    [self connect];
}

- (void)connectWithPathName:(NSString *)pathName protocols:(NSArray<NSString *> *)protocols {
    [self connectWithPathName:pathName protocols:protocols headers:nil];
}

- (void)connectWithPathName:(NSString *)pathName protocols:(NSArray<NSString *> *)protocols headers:(NSDictionary<NSString *, NSString *> *)headers {
    [self connectWithPathName:pathName environment:nil protocols:protocols headers:headers];
}

- (void)connectWithPathName:(NSString *)pathName environment:(nullable NSNumber *)environment protocols:(NSArray<NSString *> *)protocols headers:(NSDictionary<NSString *, NSString *> *)headers {
    if (self.status == WebSocketStatusConnected || self.status == WebSocketStatusConnecting) {
        NSLog(@"WebSocket已连接或正在连接中");
        return;
    }
    
    // 获取完整WebSocket URL
    WebSocketEnvironmentManager *envManager = [WebSocketEnvironmentManager sharedManager];
    
    // 如果指定了环境，临时切换环境
    APIEnvironment originalEnvironment = envManager.currentEnvironment;
    if (environment) {
        [envManager switchToEnvironment:[environment integerValue]];
    }
    
    // 获取完整URL
    NSString *fullURL = [envManager fullWebSocketURLForPathName:pathName];
    
    // 恢复原环境（如果临时切换了）
    if (environment) {
        [envManager switchToEnvironment:originalEnvironment];
    }
    
    if (!fullURL || fullURL.length == 0) {
        NSLog(@"⚠️ 无法获取WebSocket URL，路径名称: %@", pathName);
        return;
    }
    
    NSLog(@"✅ WebSocket连接URL: %@ (路径名称: %@)", fullURL, pathName);
    
    // 使用完整URL连接
    [self connectWithURLString:fullURL protocols:protocols headers:headers];
}

- (void)connect {
    if (self.URLString.length == 0) {
        NSLog(@"WebSocket URL为空");
        return;
    }
    
    NSURL *url = [NSURL URLWithString:self.URLString];
    if (!url) {
        NSLog(@"WebSocket URL格式错误: %@", self.URLString);
        return;
    }
    
    // 断开旧连接
    [self disconnect];
    
    // 创建WebSocket请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = self.connectTimeout;
    
    // 设置请求头
    if (self.headers && self.headers.count > 0) {
        for (NSString *key in self.headers.allKeys) {
            [request setValue:self.headers[key] forHTTPHeaderField:key];
        }
    }
    
    // 创建WebSocket
    if (self.protocols && self.protocols.count > 0) {
        self.webSocket = [[SRWebSocket alloc] initWithURLRequest:request protocols:self.protocols];
    } else {
        self.webSocket = [[SRWebSocket alloc] initWithURLRequest:request];
    }
    
    self.webSocket.delegate = self;
    
    // 更新状态
    self.status = WebSocketStatusConnecting;
    if (self.statusBlock) {
        self.statusBlock(self.status);
    }
    
    // 开始连接
    [self.webSocket open];
}

- (void)disconnect {
    [self stopReconnectTimer];
    [self stopHeartbeatTimer];
    
    if (self.webSocket) {
        self.webSocket.delegate = nil;
        [self.webSocket close];
        self.webSocket = nil;
    }
    
    self.status = WebSocketStatusDisconnected;
    if (self.statusBlock) {
        self.statusBlock(self.status);
    }
    
    self.reconnectCount = 0;
}

- (BOOL)sendMessage:(id)message {
    if (!message) {
        NSLog(@"消息为空");
        return NO;
    }
    
    // 如果未连接，根据配置决定是否缓存消息
    if (self.status != WebSocketStatusConnected || !self.webSocket) {
        if (self.cacheMessagesWhenDisconnected) {
            [self cacheMessage:message];
        }
        NSLog(@"WebSocket未连接，无法发送消息");
        return NO;
    }
    
    NSError *error = nil;
    BOOL success = NO;
    
    if ([message isKindOfClass:[NSString class]]) {
        success = [self.webSocket sendString:message error:&error];
    } else if ([message isKindOfClass:[NSData class]]) {
        success = [self.webSocket sendData:message error:&error];
    } else {
        NSLog(@"不支持的消息类型: %@", [message class]);
        return NO;
    }
    
    if (!success || error) {
        NSLog(@"发送消息失败: %@", error.localizedDescription);
        if (self.errorBlock) {
            self.errorBlock(error);
        }
        // 发送失败也缓存
        if (self.cacheMessagesWhenDisconnected) {
            [self cacheMessage:message];
        }
        return NO;
    }
    
    return YES;
}

- (BOOL)sendJSON:(id)jsonObject {
    if (!jsonObject) {
        NSLog(@"JSON对象为空");
        return NO;
    }
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                       options:0
                                                         error:&error];
    if (error) {
        NSLog(@"JSON序列化失败: %@", error.localizedDescription);
        return NO;
    }
    
    return [self sendMessage:jsonData];
}

- (void)cacheMessage:(id)message {
    if (self.cachedMessages.count >= self.maxCachedMessages) {
        [self.cachedMessages removeObjectAtIndex:0];
    }
    [self.cachedMessages addObject:message];
}

- (void)sendPing {
    if (self.status == WebSocketStatusConnected && self.webSocket) {
        // SRWebSocket 没有直接的 sendPing 方法
        // 通过发送特定的 ping 消息来实现心跳
        // 服务器需要识别并响应这个 ping 消息
        NSError *error = nil;
        NSString *pingMessage = @"{\"type\":\"ping\"}";
        BOOL success = [self.webSocket sendString:pingMessage error:&error];
        if (!success || error) {
            NSLog(@"发送心跳失败: %@", error ? error.localizedDescription : @"未知错误");
        } else {
            NSLog(@"发送心跳成功");
        }
    }
}

- (void)reconnect {
    if (self.status == WebSocketStatusConnected || self.status == WebSocketStatusConnecting) {
        return;
    }
    
    if (self.maxReconnectCount > 0 && self.reconnectCount >= self.maxReconnectCount) {
        NSLog(@"已达到最大重连次数，停止重连");
        return;
    }
    
    self.reconnectCount++;
    NSLog(@"WebSocket开始第 %ld 次重连", (long)self.reconnectCount);
    
    [self connect];
}

- (void)startReconnectTimer {
    [self stopReconnectTimer];
    
    __weak typeof(self) weakSelf = self;
    self.reconnectTimer = [NSTimer scheduledTimerWithTimeInterval:self.reconnectInterval
                                                           repeats:NO
                                                             block:^(NSTimer * _Nonnull timer) {
        [weakSelf reconnect];
    }];
}

- (void)stopReconnectTimer {
    if (self.reconnectTimer) {
        [self.reconnectTimer invalidate];
        self.reconnectTimer = nil;
    }
}

#pragma mark - SRWebSocketDelegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    NSLog(@"WebSocket连接成功");
    
    self.status = WebSocketStatusConnected;
    self.reconnectCount = 0;
    [self stopReconnectTimer];
    
    // 启动心跳
    if (self.enableHeartbeat) {
        [self startHeartbeatTimer];
    }
    
    // 发送缓存的消息
    [self sendCachedMessages];
    
    if (self.statusBlock) {
        self.statusBlock(self.status);
    }
}

- (void)startHeartbeatTimer {
    [self stopHeartbeatTimer];
    
    __weak typeof(self) weakSelf = self;
    self.heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:self.heartbeatInterval
                                                          repeats:YES
                                                            block:^(NSTimer * _Nonnull timer) {
        [weakSelf sendPing];
    }];
}

- (void)stopHeartbeatTimer {
    if (self.heartbeatTimer) {
        [self.heartbeatTimer invalidate];
        self.heartbeatTimer = nil;
    }
}

- (void)sendCachedMessages {
    if (self.cachedMessages.count == 0) {
        return;
    }
    
    NSLog(@"开始发送 %ld 条缓存消息", (long)self.cachedMessages.count);
    
    NSArray *messages = [self.cachedMessages copy];
    [self.cachedMessages removeAllObjects];
    
    for (id message in messages) {
        [self sendMessage:message];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    if (self.messageBlock) {
        self.messageBlock(message);
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    NSLog(@"WebSocket连接失败: %@", error.localizedDescription);
    
    [self stopHeartbeatTimer];
    
    self.status = WebSocketStatusDisconnected;
    if (self.statusBlock) {
        self.statusBlock(self.status);
    }
    
    if (self.errorBlock) {
        self.errorBlock(error);
    }
    
    // 自动重连
    if (self.autoReconnect) {
        self.status = WebSocketStatusReconnecting;
        if (self.statusBlock) {
            self.statusBlock(self.status);
        }
        [self startReconnectTimer];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    NSLog(@"WebSocket连接关闭: code=%ld, reason=%@, wasClean=%d", (long)code, reason ?: @"", wasClean);
    
    [self stopHeartbeatTimer];
    
    self.status = WebSocketStatusDisconnected;
    if (self.statusBlock) {
        self.statusBlock(self.status);
    }
    
    // 自动重连
    if (self.autoReconnect && !wasClean) {
        self.status = WebSocketStatusReconnecting;
        if (self.statusBlock) {
            self.statusBlock(self.status);
        }
        [self startReconnectTimer];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongData {
    NSLog(@"WebSocket收到Pong");
}

- (void)clearCachedMessages {
    [self.cachedMessages removeAllObjects];
}

- (NSInteger)cachedMessagesCount {
    return self.cachedMessages.count;
}

@end
