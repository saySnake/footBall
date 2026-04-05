//
//  PassportViewModel.m
//  footBall
//

#import "PassportViewModel.h"
#import "Passport.h"
#import "PassportNestedModels.h"
#import "Team.h"

@implementation PassportViewModel

+ (NSArray<NSNumber *> *)headerWeekValuesNormalizedFromWeekly:(NSArray<NSNumber *> *)weekly {
    if (![weekly isKindOfClass:[NSArray class]] || weekly.count != 7) {
        return nil;
    }
    double maxV = 1.0;
    for (NSNumber *n in weekly) {
        double v = fabs(n.doubleValue);
        if (v > maxV) {
            maxV = v;
        }
    }
    NSMutableArray<NSNumber *> *out = [NSMutableArray arrayWithCapacity:7];
    for (NSNumber *n in weekly) {
        double ratio = maxV > 0 ? (n.doubleValue / maxV) : 0;
        NSInteger scaled = (NSInteger)llround(MAX(0, MIN(100, ratio * 100.0)));
        [out addObject:@(scaled)];
    }
    return [out copy];
}

+ (NSString *)isoCodeFromHeatmapCountryField:(NSString *)country {
    if (![country isKindOfClass:[NSString class]]) {
        return nil;
    }
    NSString *s = [country stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (s.length == 0) {
        return nil;
    }
    NSString *u = [s uppercaseString];
    if (u.length == 2) {
        NSCharacterSet *nonLetters = [[NSCharacterSet letterCharacterSet] invertedSet];
        if ([u rangeOfCharacterFromSet:nonLetters].location == NSNotFound) {
            return u;
        }
    }
    static NSDictionary<NSString *, NSString *> *zhToISO;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        zhToISO = @{
            @"中国": @"CN", @"日本": @"JP", @"美国": @"US", @"英国": @"GB",
            @"法国": @"FR", @"德国": @"DE", @"韩国": @"KR", @"泰国": @"TH",
            @"西班牙": @"ES", @"意大利": @"IT", @"澳大利亚": @"AU",
        };
    });
    return zhToISO[s] ?: nil;
}

+ (void)applyHeaderFromPassport:(nullable PNPassport *)passport toModel:(PassportViewModel *)m codeDigits:(NSArray<NSString *> *)box {
    NSString *prefix = NSLocalizedString(@"passport_header_no_prefix", nil);
    if (!prefix.length || [prefix isEqualToString:@"passport_header_no_prefix"]) {
        prefix = @"NO.";
    }
    m.headerPassportCodeLine = [NSString stringWithFormat:@"%@%@", prefix, [box componentsJoinedByString:@""]];

    if (!passport) {
        m.headerWeekLineValues = @[ @15, @32, @48, @75, @38, @62, @28 ];
        m.headerRedCards = 0;
        m.headerYellowCards = 0;
        m.headerCleanMatches = 0;
        m.headerMapOftenISOs = @[ @"CN", @"JP" ];
        m.headerMapGoneISOs = @[ @"US", @"GB" ];
        m.headerSpendingAmountText = @"999,999.99";
        m.headerBottomStatTexts = @[ @"12", @"3", @"5", @"62%", @"1", @"2", @"25", @"18" ];
        return;
    }

    NSArray<NSNumber *> *normWeek = [self headerWeekValuesNormalizedFromWeekly:passport.weeklyFrequency];
    m.headerWeekLineValues = normWeek ?: @[ @15, @32, @48, @75, @38, @62, @28 ];

    if (passport.discipline) {
        m.headerRedCards = passport.discipline.redCards;
        m.headerYellowCards = passport.discipline.yellowCards;
        m.headerCleanMatches = passport.discipline.cleanMatches;
    } else {
        m.headerRedCards = 0;
        m.headerYellowCards = 0;
        m.headerCleanMatches = 0;
    }

    NSMutableArray<NSString *> *often = [NSMutableArray array];
    NSMutableArray<NSString *> *gone = [NSMutableArray array];
    for (PNCountryHeatmap *h in passport.countryHeatmap) {
        NSString *iso = [self isoCodeFromHeatmapCountryField:h.country];
        if (!iso.length) {
            continue;
        }
        if (h.level >= 3) {
            [often addObject:iso];
        } else if (h.level >= 1) {
            [gone addObject:iso];
        }
    }
    m.headerMapOftenISOs = [often copy];
    m.headerMapGoneISOs = [gone copy];

    m.headerSpendingAmountText = passport.yearSpending.length ? passport.yearSpending : @"0.00";

//    m.headerMiniStatTexts = @[
//        [NSString stringWithFormat:@"%ld", (long)MAX(0, passport.yearCityCount)],
//        [NSString stringWithFormat:@"%ld", (long)MAX(0, passport.yearCountryCount)],
//        [NSString stringWithFormat:@"%ld", (long)MAX(0, passport.yearStadiumCount)],
//    ];

    PNPassportTeamRecord *tr = passport.teamRecord;
    NSString *winRate = (tr.winRate.length ? tr.winRate : @"—");
    NSInteger w = tr ? tr.wins : 0;
    NSInteger d = tr ? tr.draws : 0;
    NSInteger l = tr ? tr.losses : 0;
    NSInteger el = tr ? tr.eliminated : 0;
    NSInteger qu = tr ? tr.qualified : 0;
    m.headerBottomStatTexts = @[
        [NSString stringWithFormat:@"%ld", (long)MAX(0, w)],
        [NSString stringWithFormat:@"%ld", (long)MAX(0, d)],
        [NSString stringWithFormat:@"%ld", (long)MAX(0, l)],
        winRate,
        [NSString stringWithFormat:@"%ld", (long)MAX(0, el)],
        [NSString stringWithFormat:@"%ld", (long)MAX(0, qu)],
        [NSString stringWithFormat:@"%ld", (long)MAX(0, passport.yearTotalMatches)],
        [NSString stringWithFormat:@"%ld", (long)MAX(0, passport.yearTotalGoals)],
    ];
}

+ (NSString *)generationMainTextFromTag:(nullable NSString *)tag hasHouSuffix:(BOOL *)outHasHou {
    if (![tag isKindOfClass:[NSString class]] || tag.length == 0) {
        if (outHasHou) {
            *outHasHou = NO;
        }
        return @"";
    }
    NSString *t = [tag stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    BOOL hou = t.length >= 2 && [t hasSuffix:@"后"];
    if (outHasHou) {
        *outHasHou = hou;
    }
    if (hou) {
        return [t substringToIndex:t.length - 1];
    }
    return t;
}

+ (void)applyHeader2FromPassport:(nullable PNPassport *)passport toModel:(PassportViewModel *)m year:(NSInteger)year {
    NSInteger cy = year > 0 ? year : (NSInteger)[[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian] component:NSCalendarUnitYear fromDate:[NSDate date]];
    m.displayYear = cy;

    if (!passport) {
        m.userCity = nil;
        m.header2YearMatchCount = 11;
        m.header2GenerationMainText = @"05";
        m.header2GenerationHasHouSuffix = YES;
        m.header2YearWatchMinutes = 9500;
        m.header2YearGoals = 30;
        m.header2CityCount = 20;
        m.header2CountryCount = 6;
        m.header2FollowedTeamLogoURLs = @[];
        return;
    }

    m.userCity = passport.city;
    m.header2YearMatchCount = MAX(0, passport.yearTotalMatches);
    BOOL genHou = NO;
    m.header2GenerationMainText = [self generationMainTextFromTag:passport.generationTag hasHouSuffix:&genHou];
    m.header2GenerationHasHouSuffix = genHou;
    m.header2YearWatchMinutes = MAX(0, passport.yearTotalWatchTime);
    m.header2YearGoals = MAX(0, passport.yearTotalGoals);
    m.header2CityCount = MAX(0, passport.yearCityCount);
    m.header2CountryCount = MAX(0, passport.yearCountryCount);

    NSMutableArray<NSString *> *logos = [NSMutableArray array];
    for (id obj in passport.followedTeams) {
        if (![obj isKindOfClass:[TeamIcon class]]) {
            continue;
        }
        TeamIcon *team = (TeamIcon *)obj;
        NSString *logo = team.logo;
        if ([logo isKindOfClass:[NSString class]] && logo.length > 0) {
            [logos addObject:logo];
        }
        if (logos.count >= 5) {
            break;
        }
    }
    m.header2FollowedTeamLogoURLs = [logos copy];
}

+ (instancetype)viewModelWithPassport:(nullable PNPassport *)passport year:(NSInteger)year {
    PassportViewModel *m = [[PassportViewModel alloc] init];
    NSInteger y = year > 0 ? year : (NSInteger)[[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian] component:NSCalendarUnitYear fromDate:[NSDate date]];

    NSString *score = @"62,568.72";
    NSString *digits = @"0088";
    if (passport) {
        if (passport.passportCode.length >= 4) {
            digits = passport.passportCode;
        } else if (passport.passportCode.length > 0) {
            digits = [passport.passportCode stringByPaddingToLength:4 withString:@"0" startingAtIndex:0];
        }
    }
    NSMutableArray *box = [NSMutableArray array];
    for (NSUInteger i = 0; i < 4 && i < digits.length; i++) {
        [box addObject:[[digits substringWithRange:NSMakeRange(i, 1)] copy]];
    }
    while (box.count < 4) { [box addObject:@"0"]; }

    m.mainScoreText = [NSString stringWithFormat:@"%@ %@", score, NSLocalizedString(@"passport_points_suffix", nil) ?: @"分"];
    m.codeDigitTexts = [box copy];
    m.avatarURL = passport ? passport.avatar : nil;
    m.nickname = (passport && passport.nickname.length) ? passport.nickname : @"CHALLENGER";
    NSInteger ym = passport ? passport.yearTotalMatches : 0;
    m.headerStatLeft = ym > 0 ? ym : 25;
    m.headerStatRight = 0;
    m.promoButtonTitle = NSLocalizedString(@"passport_promo_car", nil) ?: @"特惠购车";

    m.regularSeasonTitle = NSLocalizedString(@"passport_regular_stats", nil) ?: @"常规赛数据";
    m.avgDurationTitle = NSLocalizedString(@"passport_avg_duration", nil) ?: @"平均时长";
    m.avgDurationValue = @"80.68 min";
    m.matchesYearTitle = NSLocalizedString(@"passport_matches_this_year", nil) ?: @"今年登场比赛场次";
    m.matchesYearValue = [NSString stringWithFormat:@"%ld %@", (long)(ym > 0 ? ym : 3), NSLocalizedString(@"passport_times_unit", nil) ?: @"次"];
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

    [self applyHeaderFromPassport:passport toModel:m codeDigits:[box copy]];
    [self applyHeader2FromPassport:passport toModel:m year:y];
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
