//
//  HTTPResponse.h
//  footBall
//
//  Created by LWJ on 2026/3/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HTTPResponse : NSObject
@property (nonatomic, assign) BOOL success;
@property (nonatomic, strong) NSString *errorCode;
@property (nonatomic, strong) id data;
@property (nonatomic, strong) NSString *errorMessage;
@end

NS_ASSUME_NONNULL_END
