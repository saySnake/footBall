//
//  MatchRecordModels.m
//  footBall
//

#import "MatchRecordModels.h"

@implementation PNMatchRecord
+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{ @"recordId": @[ @"id", @"recordId" ] };
}
@end

@implementation PNMatchRecordDetail
+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{ @"recordId": @[ @"id", @"recordId" ] };
}

- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    id p = dic[@"ticketPrice"];
    if ([p isKindOfClass:NSNumber.class]) {
        self.ticketPrice = [p stringValue];
    }
    return YES;
}
@end

@implementation PNMatchRecordPage
+ (NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass {
    return @{ @"list": PNMatchRecord.class };
}
@end
