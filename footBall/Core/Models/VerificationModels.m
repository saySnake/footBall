//
//  VerificationModels.m
//  footBall
//

#import "VerificationModels.h"

@implementation PNVerificationStatus
@end

@implementation PNRealnameInfo
@end

@implementation PNVerificationHistory
+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{ @"historyId": @[ @"id", @"historyId" ] };
}
@end
