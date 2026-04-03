//
//  PassportViewModel.m
//  footBall
//

#import "PassportViewModel.h"
#import "Passport.h"

@implementation PassportViewModel

+ (instancetype)viewModelWithPassport:(PNPassport *)passport year:(NSInteger)year {
    PassportViewModel *m = [[PassportViewModel alloc] init];
    NSInteger y = year > 0 ? year : (NSInteger)[[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian] component:NSCalendarUnitYear fromDate:[NSDate date]];

    NSString *score = @"62,568.72";
    NSString *digits = passport.passportCode.length >= 4 ? passport.passportCode : @"0088";
    if (digits.length < 4) {
        digits = [[digits stringByPaddingToLength:4 withString:@"0" startingAtIndex:0] copy];
    }
    NSMutableArray *box = [NSMutableArray array];
    for (NSUInteger i = 0; i < 4 && i < digits.length; i++) {
        [box addObject:[[digits substringWithRange:NSMakeRange(i, 1)] copy]];
    }
    while (box.count < 4) { [box addObject:@"0"]; }

    m.mainScoreText = [NSString stringWithFormat:@"%@ %@", score, NSLocalizedString(@"passport_points_suffix", nil) ?: @"分"];
    m.codeDigitTexts = [box copy];
    m.avatarURL = passport.avatar;
    m.nickname = passport.nickname.length ? passport.nickname : @"CHALLENGER";
    m.headerStatLeft = passport.yearTotalMatches > 0 ? passport.yearTotalMatches : 25;
    m.headerStatRight = 0;
    m.promoButtonTitle = NSLocalizedString(@"passport_promo_car", nil) ?: @"特惠购车";

    m.regularSeasonTitle = NSLocalizedString(@"passport_regular_stats", nil) ?: @"常规赛数据";
    m.avgDurationTitle = NSLocalizedString(@"passport_avg_duration", nil) ?: @"平均时长";
    m.avgDurationValue = @"80.68 min";
    m.matchesYearTitle = NSLocalizedString(@"passport_matches_this_year", nil) ?: @"今年登场比赛场次";
    m.matchesYearValue = [NSString stringWithFormat:@"%ld %@", (long)(passport.yearTotalMatches > 0 ? passport.yearTotalMatches : 3), NSLocalizedString(@"passport_times_unit", nil) ?: @"次"];
    m.avgGoalsMatchTitle = NSLocalizedString(@"passport_avg_goals_per_match", nil) ?: @"单场平均进球";
    m.avgGoalsMatchValue = @"3.4 : 1";
    m.totalGoalsTitle = NSLocalizedString(@"passport_total_goals", nil) ?: @"总进球数";
    m.totalGoalsValue = @"3.4 : 1";

    m.growthHeadline = [NSString stringWithFormat:@"6.31%% %@", NSLocalizedString(@"passport_growth_ok", nil) ?: @"暂且看好"];
    m.growthSubtitle = NSLocalizedString(@"passport_growth_vs_last", nil) ?: @"场均比去年增长";

    m.goalTrendTitle = NSLocalizedString(@"passport_goal_trend_8", nil) ?: @"近8场比赛进球数";
    m.goalTrendValues = @[ @2, @5, @3, @7, @4, @6, @1, @8 ];

    m.possessionCardTitle = NSLocalizedString(@"passport_possession_title", nil) ?: @"1场平均控球/射门统计";
    m.possessionLeftLine1 = [NSString stringWithFormat:@"24 %@", NSLocalizedString(@"passport_per_game_shots", nil) ?: @"次/场"];
    m.possessionLeftLine2 = [NSString stringWithFormat:@"85 %@", NSLocalizedString(@"passport_per_game_score", nil) ?: @"分/场"];
    m.possessionCenterPercent = 0.85;

    m.positionSectionTitle = NSLocalizedString(@"passport_position_strength", nil) ?: @"各位置强度";
    m.positionForward = 26;
    m.positionMidfield = 15;
    m.positionDefender = 8;
    m.positionForwardLabel = NSLocalizedString(@"passport_position_fwd", nil) ?: @"前锋 Forward";
    m.positionMidfieldLabel = NSLocalizedString(@"passport_position_mid", nil) ?: @"中场 Midfield";
    m.positionDefenderLabel = NSLocalizedString(@"passport_position_def", nil) ?: @"后卫 Defender";

    m.abilitySectionTitle = NSLocalizedString(@"passport_ability_detail", nil) ?: @"线下观赛数据观";
    m.abilityAverageLevel = 1.45;
    m.abilityItems = [self defaultAbilityItems];

    m.tacticalTitle = NSLocalizedString(@"passport_tactical_identity_title", nil) ?: @"观赛身份";
    m.tacticalIdentityCount = 3;
    m.tacticalSegments = @[
        @{ @"p": @0.55, @"title": NSLocalizedString(@"passport_tactical_seg_pro", nil) ?: @"从业者身份" },
        @{ @"p": @0.35, @"title": NSLocalizedString(@"passport_tactical_seg_media", nil) ?: @"媒体身份" },
        @{ @"p": @0.10, @"title": NSLocalizedString(@"passport_tactical_seg_family", nil) ?: @"家属陪同" },
    ];

    m.recentGoalsTitle = NSLocalizedString(@"passport_recent_goals_title", nil) ?: @"6 场比赛进球";
    m.recentGoalsSubtitle = NSLocalizedString(@"passport_recent_goals_sub", nil) ?: @"进球分布, 数据统计";
    m.metricEmotionCount = 6;
    m.metricHeaderAsideLine1 = NSLocalizedString(@"passport_metric_aside_1", nil) ?: @"我出现了";
    m.metricHeaderAsideLine2 = NSLocalizedString(@"passport_metric_aside_2", nil) ?: @"种赛后情绪";
    m.metricBarsPrompt = NSLocalizedString(@"passport_metric_prompt", nil) ?: @"看球之后，我更容易：";
    m.recentMetricBars = @[
        @{ @"title": NSLocalizedString(@"passport_metric_emotion_0", nil) ?: @"兴奋", @"value": @21 },
        @{ @"title": NSLocalizedString(@"passport_metric_emotion_1", nil) ?: @"激动", @"value": @73 },
        @{ @"title": NSLocalizedString(@"passport_metric_emotion_2", nil) ?: @"希望", @"value": @17 },
        @{ @"title": NSLocalizedString(@"passport_metric_emotion_3", nil) ?: @"平静", @"value": @12 },
        @{ @"title": NSLocalizedString(@"passport_metric_emotion_4", nil) ?: @"失望", @"value": @9 },
        @{ @"title": NSLocalizedString(@"passport_metric_emotion_5", nil) ?: @"遗憾", @"value": @12 },
        @{ @"title": NSLocalizedString(@"passport_metric_emotion_6", nil) ?: @"暴躁", @"value": @6 },
    ];

    m.outcomeTitle = NSLocalizedString(@"passport_outcome_vs_last", nil) ?: @"比上场胜势情况";
    m.outcomeCenterPercent = 0.45;
    m.outcomeLegend = @[
        @{@"t": NSLocalizedString(@"passport_legend_win", nil) ?: @"胜", @"n": @"21", @"h": @"285D4B"},
        @{@"t": NSLocalizedString(@"passport_legend_draw", nil) ?: @"平", @"n": @"3", @"h": @"4A8F7A"},
        @{@"t": NSLocalizedString(@"passport_legend_loss", nil) ?: @"负", @"n": @"22", @"h": @"6BA68A"},
        @{@"t": NSLocalizedString(@"passport_legend_other", nil) ?: @"其它", @"n": @"3", @"h": @"A8D5BA"},
    ];

    (void)y;
    return m;
}

+ (NSArray<NSDictionary *> *)defaultAbilityItems {
    NSArray<NSString *> *titleKeys = @[
        @"passport_ability_seat_0", @"passport_ability_seat_1", @"passport_ability_seat_2", @"passport_ability_seat_3",
        @"passport_ability_seat_4", @"passport_ability_seat_5", @"passport_ability_seat_6", @"passport_ability_seat_7",
        @"passport_ability_seat_8", @"passport_ability_seat_9", @"passport_ability_seat_10", @"passport_ability_seat_11",
        @"passport_ability_seat_12", @"passport_ability_seat_13",
    ];
    NSArray<NSNumber *> *vals = @[
        @21, @73, @17, @12, @9, @6, @21, @23, @25, @12, @9, @3, @12, @0,
    ];
    NSArray<NSString *> *zhFallbacks = @[
        @"内场", @"1层", @"2层", @"3层", @"4层", @"包厢层", @"看台区", @"短边", @"场边",
        @"VIP看台", @"山顶", @"主席台", @"球门后", @"曲线看球",
    ];
    NSMutableArray *out = [NSMutableArray array];
    for (NSUInteger i = 0; i < titleKeys.count; i++) {
        NSString *key = titleKeys[i];
        NSString *t = NSLocalizedString(key, nil);
        if (!t.length || [t isEqualToString:key]) {
            t = zhFallbacks[i];
        }
        [out addObject:@{@"title": t, @"value": vals[i]}];
    }
    return [out copy];
}

@end
