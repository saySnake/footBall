//
//  ProfileTeamsStore.m
//  footBall
//

#import "ProfileTeamsStore.h"

static NSString * const kProfileFollowedTeamsKey = @"profile_followed_teams";

@implementation ProfileTeamItem
@end

@implementation ProfileTeamsStore

+ (NSArray<ProfileTeamItem *> *)allTeams {
    static NSArray<ProfileTeamItem *> *cache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *raw = @[
            // id, nameKey, icon, tint
            @[@"mancity",   @"team_name_mancity",   @"circle.hexagongrid.fill", @"#6CABDD"],
            @[@"wolves",    @"team_name_wolves",    @"pawprint.fill",           @"#FDB913"],
            @[@"liverpool", @"team_name_liverpool", @"flame.fill",              @"#C8102E"],
            @[@"nforest",   @"team_name_nforest",   @"tree.fill",               @"#DD0000"],
            @[@"manutd",    @"team_name_manutd",    @"shield.lefthalf.filled",  @"#DA291C"],
            @[@"chelsea",   @"team_name_chelsea",   @"crown.fill",              @"#034694"],
            @[@"arsenal",   @"team_name_arsenal",   @"scope",                   @"#EF0107"],
            @[@"spurs",     @"team_name_spurs",     @"bolt.heart.fill",         @"#132257"],
            @[@"brentford", @"team_name_brentford", @"hexagon.fill",            @"#E30613"],
            @[@"brighton",  @"team_name_brighton",  @"circlebadge.fill",        @"#0057B8"],
            @[@"burnley",   @"team_name_burnley",   @"drop.fill",               @"#6C1D45"],
            @[@"astonvilla",@"team_name_astonvilla",@"a.circle.fill",           @"#95BFE5"],
            @[@"everton",   @"team_name_everton",   @"e.circle.fill",           @"#003399"],
            @[@"westham",   @"team_name_westham",   @"w.circle.fill",           @"#7A263A"],
            @[@"fulham",    @"team_name_fulham",    @"f.circle.fill",           @"#111111"],
            @[@"bournemouth",@"team_name_bournemouth",@"b.circle.fill",         @"#DA291C"],
            @[@"sunderland",@"team_name_sunderland",@"s.circle.fill",           @"#EB172B"],
        ];
        NSMutableArray *arr = [NSMutableArray array];
        for (NSArray *r in raw) {
            ProfileTeamItem *t = [ProfileTeamItem new];
            t.teamId = r[0];
            t.nameKey = r[1];
            t.iconName = r[2];
            NSString *hex = [r[3] stringByReplacingOccurrencesOfString:@"#" withString:@""];
            unsigned int rgb = 0;
            [[NSScanner scannerWithString:hex] scanHexInt:&rgb];
            t.tintColor = [UIColor colorWithRed:((rgb>>16)&0xFF)/255.0
                                          green:((rgb>>8)&0xFF)/255.0
                                           blue:(rgb&0xFF)/255.0
                                          alpha:1.0];
            [arr addObject:t];
        }
        cache = [arr copy];
    });
    return cache;
}

+ (NSArray<NSString *> *)defaultFollowedTeamIds {
    return @[ @"mancity", @"wolves", @"liverpool", @"nforest" ];
}

+ (NSArray<NSString *> *)loadFollowedTeamIds {
    // 允许用户“删除到空”，空数组代表没有关注任何球队。
    // 只有在 key 不存在时才使用默认值。
    id obj = [[NSUserDefaults standardUserDefaults] objectForKey:kProfileFollowedTeamsKey];
    if (!obj) {
        return [self defaultFollowedTeamIds];
    }
    NSArray *raw = [obj isKindOfClass:[NSArray class]] ? (NSArray *)obj : nil;
    if (!raw) {
        return [self defaultFollowedTeamIds];
    }
    NSMutableArray *ids = [NSMutableArray array];
    for (id v in raw) {
        if ([v isKindOfClass:[NSString class]] && ((NSString *)v).length > 0) {
            [ids addObject:v];
        }
    }
    // key 存在但内容为空/无效时，按“无关注球队”处理
    return ids;
}

+ (void)saveFollowedTeamIds:(NSArray<NSString *> *)teamIds {
    NSMutableArray *unique = [NSMutableArray array];
    NSMutableSet *seen = [NSMutableSet set];
    for (NSString *tid in teamIds) {
        if (![tid isKindOfClass:[NSString class]] || tid.length == 0) continue;
        if ([seen containsObject:tid]) continue;
        [seen addObject:tid];
        [unique addObject:tid];
    }
    [[NSUserDefaults standardUserDefaults] setObject:unique forKey:kProfileFollowedTeamsKey];
}

+ (NSArray<ProfileTeamItem *> *)teamsForIds:(NSArray<NSString *> *)teamIds {
    NSDictionary<NSString *, ProfileTeamItem *> *map = [self mapById];
    NSMutableArray *arr = [NSMutableArray array];
    for (NSString *tid in teamIds) {
        ProfileTeamItem *t = map[tid];
        if (t) [arr addObject:t];
    }
    return arr;
}

+ (NSDictionary<NSString *, ProfileTeamItem *> *)mapById {
    static NSDictionary<NSString *, ProfileTeamItem *> *cache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        for (ProfileTeamItem *t in [self allTeams]) {
            if (t.teamId) d[t.teamId] = t;
        }
        cache = [d copy];
    });
    return cache;
}

@end

