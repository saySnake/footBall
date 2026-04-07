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
        // 不使用 mock：无数据时全部置空/0，由 UI 决定空态展示。
        m.headerWeekLineValues = @[];
        m.headerRedCards = 0;
        m.headerYellowCards = 0;
        m.headerCleanMatches = 0;
        m.headerMapOftenISOs = @[];
        m.headerMapGoneISOs = @[];
        m.headerSpendingAmountText = @"";
        m.totalWatchTimeTexts = @[];
        return;
    }
    
    NSArray<NSNumber *> *normWeek = [self headerWeekValuesNormalizedFromWeekly:passport.weeklyFrequency];
    m.headerWeekLineValues = normWeek ?: @[];
    
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
    
    m.headerSpendingAmountText = passport.yearSpending.length ? passport.yearSpending : @"";
    
    // careerTotalWatchTime -> totalWatchTimeTexts
    NSInteger minutes = MAX(0, passport.careerTotalWatchTime);
    NSString *minuteStr = [NSString stringWithFormat:@"%ld", (long)minutes];
    NSMutableArray<NSString *> *parts = [NSMutableArray arrayWithCapacity:minuteStr.length + 1];
    for (NSUInteger i = 0; i < minuteStr.length; i++) {
        unichar ch = [minuteStr characterAtIndex:i];
        [parts addObject:[NSString stringWithCharacters:&ch length:1]];
    }
    [parts addObject:@"分"];
    m.totalWatchTimeTexts = [parts copy];
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
        // 不使用 mock：无数据时全部置空/0，由 UI 决定空态展示。
        m.userCity = nil;
        m.header2YearMatchCount = 0;
        m.header2GenerationMainText = @"";
        m.header2GenerationHasHouSuffix = NO;
        m.header2YearWatchMinutes = 0;
        m.header2YearGoals = 0;
        m.header2CityCount = 0;
        m.header2CountryCount = 0;
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

    // TODO: 后端暂无“护照积分/总分”字段时，不填该展示；待接口补字段后再映射（例如 points/score 等）。
    m.mainScoreText = @"";
    m.codeDigitTexts = [box copy];
    m.avatarURL = passport ? passport.avatar : nil;
    m.nickname = (passport && passport.nickname.length) ? passport.nickname : @"";
    NSInteger ym = passport ? passport.yearTotalMatches : 0;
    m.headerStatLeft = ym;
    m.headerStatRight = 0;
    m.promoButtonTitle = NSLocalizedString(@"passport_promo_car", nil) ?: @"特惠购车";

    m.regularSeasonTitle = NSLocalizedString(@"passport_regular_stats", nil) ?: @"常规赛数据";
    m.avgDurationTitle = NSLocalizedString(@"passport_avg_duration", nil) ?: @"平均时长";
    // 平均时长：年度总时长 / 年度场次（分钟）
    if (passport && passport.yearTotalMatches > 0) {
        double avg = (double)passport.yearTotalWatchTime / (double)passport.yearTotalMatches;
        m.avgDurationValue = [NSString stringWithFormat:@"%.2f min", avg];
    } else {
        m.avgDurationValue = @"";
    }
    m.matchesYearTitle = NSLocalizedString(@"passport_matches_this_year", nil) ?: @"今年登场比赛场次";
    if (ym > 0) {
        m.matchesYearValue = [NSString stringWithFormat:@"%ld %@", (long)ym, NSLocalizedString(@"passport_times_unit", nil) ?: @"次"];
    } else {
        m.matchesYearValue = @"";
    }
    m.avgGoalsMatchTitle = NSLocalizedString(@"passport_avg_goals_per_match", nil) ?: @"单场平均进球";
    if (passport && passport.yearTotalMatches > 0) {
        double g = (double)passport.yearTotalGoals / (double)passport.yearTotalMatches;
        m.avgGoalsMatchValue = [NSString stringWithFormat:@"%.2f", g];
    } else {
        m.avgGoalsMatchValue = @"";
    }
    m.totalGoalsTitle = NSLocalizedString(@"passport_total_goals", nil) ?: @"总进球数";
    if (passport) {
        m.totalGoalsValue = [NSString stringWithFormat:@"%ld", (long)MAX(0, passport.yearTotalGoals)];
    } else {
        m.totalGoalsValue = @"";
    }

    // TODO: growth 相关（awakeWatchPercent/seasonDays 等）需与设计稿口径确认后再组装文案
    m.growthHeadline = @"";
    m.growthSubtitle = @"";

    // TODO: 近 N 场趋势类数据目前 PNPassport 未提供
    m.goalTrendTitle = @"";
    m.goalTrendValues = @[];

    // TODO: 控球/射门等 per-game 统计目前 PNPassport 未提供
    m.possessionCardTitle = @"";
    m.possessionLeftLine1 = @"";
    m.possessionLeftLine2 = @"";
    m.possessionCenterPercent = 0;

    // 该 cell 当前注释更像“球场/城市/国家覆盖数”，用已有字段先对齐（不再用 mock）
    m.positionSectionTitle = NSLocalizedString(@"passport_position_strength", nil) ?: @"各位置强度";
    m.positionForwardLabel = NSLocalizedString(@"passport_position_fwd", nil) ?: @"球场";
    m.positionMidfieldLabel = NSLocalizedString(@"passport_position_mid", nil) ?: @"城市";
    m.positionDefenderLabel = NSLocalizedString(@"passport_position_def", nil) ?: @"国家";
    m.positionForward = passport ? passport.yearStadiumCount : 0;
    m.positionMidfield = passport ? passport.yearCityCount : 0;
    m.positionDefender = passport ? passport.yearCountryCount : 0;

    // TODO: ability（线下观赛类型/层数分布）需要用 standDist/locationDist 等字段重组为 abilityItems
    m.abilitySectionTitle = NSLocalizedString(@"passport_ability_detail", nil) ?: @"线下观赛数据观";
    m.abilityAverageLevel = passport.averageFloor.doubleValue;
    m.abilityItems = @[];

    // tactical：用 identityDist（有 count/percentage）构建 segments
    m.tacticalTitle = NSLocalizedString(@"passport_tactical_identity_title", nil) ?: @"观赛身份";
    NSMutableArray<NSDictionary *> *segs = [NSMutableArray array];
    double totalIdentity = 0;
    for (PNIdentityDist *d in passport.identityDist) { totalIdentity += MAX(0, (double)d.count); }
    for (PNIdentityDist *d in passport.identityDist) {
        double p = totalIdentity > 0 ? ((double)MAX(0, d.count) / totalIdentity) : 0;
        [segs addObject:@{@"p": @(p), @"title": d.identity ?: @""}];
    }
    m.tacticalSegments = [segs copy];
    m.tacticalIdentityCount = (NSInteger)MIN(6, m.tacticalSegments.count);

    // metric bars：用 emotionDist
    m.metricEmotionCount = (NSInteger)MIN(9, passport.emotionDist.count);
    m.metricHeaderAsideLine1 = NSLocalizedString(@"passport_metric_aside_1", nil) ?: @"";
    m.metricHeaderAsideLine2 = NSLocalizedString(@"passport_metric_aside_2", nil) ?: @"";
    m.metricBarsPrompt = NSLocalizedString(@"passport_metric_prompt", nil) ?: @"";
    NSMutableArray *bars = [NSMutableArray array];
    for (PNEmotionDist *d in passport.emotionDist) {
        [bars addObject:@{ @"title": d.emotion ?: @"", @"value": @(MAX(0, d.count)) }];
    }
    m.recentMetricBars = [bars copy];
    m.recentGoalsTitle = @"";
    m.recentGoalsSubtitle = @"";

    // outcome：用 teamRecord（胜平负/胜率），无则置空
    m.outcomeTitle = NSLocalizedString(@"passport_outcome_vs_last", nil) ?: @"";
    PNPassportTeamRecord *tr = passport.teamRecord;
    NSInteger w = tr ? tr.wins : 0;
    NSInteger d = tr ? tr.draws : 0;
    NSInteger l = tr ? tr.losses : 0;
    double sum = (double)(MAX(0, w) + MAX(0, d) + MAX(0, l));
    m.outcomeCenterPercent = sum > 0 ? ((double)MAX(0, w) / sum) : 0;
    m.outcomeLegend = @[
        @{@"t": NSLocalizedString(@"passport_legend_win", nil) ?: @"胜", @"n": [NSString stringWithFormat:@"%ld", (long)MAX(0, w)], @"h": @"62D486"},
        @{@"t": NSLocalizedString(@"passport_legend_draw", nil) ?: @"平", @"n": [NSString stringWithFormat:@"%ld", (long)MAX(0, d)], @"h": @"5CB793"},
        @{@"t": NSLocalizedString(@"passport_legend_loss", nil) ?: @"负", @"n": [NSString stringWithFormat:@"%ld", (long)MAX(0, l)], @"h": @"285D4B"},
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
