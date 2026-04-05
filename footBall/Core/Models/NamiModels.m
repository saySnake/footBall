//
//  NamiModels.m
//  footBall
//

#import "NamiModels.h"

@implementation PNNamiStatItem
@end

@implementation PNNamiIncidentItem
@end

@implementation PNNamiTextLiveItem
@end

@implementation PNNamiMatch
@end

@implementation PNNamiMatchDetail
+ (NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass {
    return @{ @"stats": PNNamiStatItem.class,
              @"incidents": PNNamiIncidentItem.class };
}
@end

@implementation PNNamiMatchLive
+ (NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass {
    return @{ @"stats": PNNamiStatItem.class,
              @"incidents": PNNamiIncidentItem.class,
              @"textLives": PNNamiTextLiveItem.class };
}
@end

@implementation PNNamiMatchTrend
@end

@implementation PNNamiLineupPlayer
@end

@implementation PNNamiMatchLineup
+ (NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass {
    return @{ @"players": PNNamiLineupPlayer.class };
}
@end

@implementation PNNamiPlayerStat
@end

@implementation PNNamiStreamUrl
@end

@implementation PNNamiVideoCollection
@end
