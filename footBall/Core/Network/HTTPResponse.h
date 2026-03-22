//
//  HTTPResponse.h
//  footBall
//
//  Created by LWJ on 2026/3/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HTTPResponse <ObjectType> : NSObject
@property (nonatomic, assign) BOOL success;
@property (nonatomic, strong) NSString *errorCode;
@property (nonatomic, strong) id data;
@property (nonatomic, strong) ObjectType dataObject;//由data解析完的model数组或model
@property (nonatomic, strong) NSString *errorMessage;
@end

NS_ASSUME_NONNULL_END
