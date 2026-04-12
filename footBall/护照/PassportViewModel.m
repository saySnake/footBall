//
//  PassportViewModel.m
//  footBall
//

#import "PassportViewModel.h"
#import "Passport.h"
#import "PassportNestedModels.h"
#import "Team.h"

/// 线上观赛方式饼图扇区颜色（与条数对应循环使用）
static NSArray<NSString *> *PassportOnlineMethodHexPalette(void) {
    static NSArray<NSString *> *p;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        p = @[ @"62D486", @"5CB793", @"285D4B", @"0D2122", @"3D8B7A", @"1A5C52" ];
    });
    return p;
}

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
    
    if (passport.yearSpending.length) {
        m.headerSpendingAmountText = passport.yearSpending;
    } else {
        m.headerSpendingAmountText = @"";
    }
    
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

/// 暗色统计卡四行：与 PassportDarkStatsCardCell 行序一致（总时长 / 赛季天数 / 周末工作日比 / 昼夜比）。
+ (NSString *)seasonDaysLineFromPassport:(nullable PNPassport *)passport {
    if (!passport) {
        return @"";
    }
    NSString *raw = [passport.seasonDays stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (raw.length) {
        return [NSString stringWithFormat:@"%@ %@", raw, NSLocalizedString(@"passport_days_unit", nil) ?: @"天"];
    }
    NSInteger minutes = MAX(0, passport.yearTotalWatchTime);
    if (minutes <= 0) {
        return @"";
    }
    double days = minutes / (24.0 * 60.0);
    return [NSString stringWithFormat:@"%.3f %@", days, NSLocalizedString(@"passport_days_unit", nil) ?: @"天"];
}

+ (NSString *)awakeWatchPercentDisplay:(nullable NSString *)awake {
    NSString *t = [awake stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (!t.length) {
        return @"";
    }
    if ([t hasSuffix:@"%"]) {
        return t;
    }
    return [NSString stringWithFormat:@"%@%%", t];
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

    NSArray<PNIdentityDist *> *identityList = passport ? (passport.identityDist ?: @[]) : @[];
    NSArray<PNEmotionDist *> *emotionList = passport ? (passport.emotionDist ?: @[]) : @[];
    NSArray<PNStandDist *> *standList = passport ? (passport.standDist ?: @[]) : @[];
    NSArray<PNLocationDist *> *locationList = passport ? (passport.locationDist ?: @[]) : @[];
    NSArray<PNOnlineMethodDist *> *onlineList = passport ? (passport.onlineMethodDist ?: @[]) : @[];

    m.codeDigitTexts = [box copy];
    m.avatarURL = passport ? passport.avatar : nil;
    m.nickname = (passport && passport.nickname.length) ? passport.nickname : @"";
    NSInteger ym = passport ? passport.yearTotalMatches : 0;
    m.headerStatLeft = ym;
    m.headerStatRight = 0;
    m.promoButtonTitle = NSLocalizedString(@"passport_promo_car", nil) ?: @"特惠购车";

    m.regularSeasonTitle = NSLocalizedString(@"passport_regular_stats", nil) ?: @"常规赛数据";
    // 行 0：年度总观赛时长（分钟，接口 yearTotalWatchTime）
    m.avgDurationTitle = NSLocalizedString(@"passport_year_total_watch_time", nil) ?: @"年度总观赛时长";
    if (passport) {
        NSInteger minutes = MAX(0, passport.yearTotalWatchTime);
        if (minutes > 0) {
            m.avgDurationValue = [NSString stringWithFormat:@"%ld %@", (long)minutes, NSLocalizedString(@"passport_minutes_unit", nil) ?: @"分钟"];
        } else {
            m.avgDurationValue = @"";
        }
    } else {
        m.avgDurationValue = @"";
    }
    // 行 1：赛季投入天数（接口 seasonDays；无则按总分钟换算）
    m.matchesYearTitle = NSLocalizedString(@"passport_season_days", nil) ?: @"赛季投入天数";
    m.matchesYearValue = [self seasonDaysLineFromPassport:passport];
    // 行 2、3：周末:工作日、白天:夜晚（接口为化简字符串，如 34:1）
    m.avgGoalsMatchTitle = NSLocalizedString(@"passport_weekend_weekday_ratio", nil) ?: @"周末/工作日";
    m.avgGoalsMatchValue = (passport && passport.weekendWeekdayRatio.length) ? passport.weekendWeekdayRatio : @"";
    m.totalGoalsTitle = NSLocalizedString(@"passport_day_night_ratio", nil) ?: @"白天/夜晚";
    m.totalGoalsValue = (passport && passport.dayNightRatio.length) ? passport.dayNightRatio : @"";

    // 成长横幅：年份文案 + 睡醒时间看球占比（接口 awakeWatchPercent）
    m.growthHeadline = [NSString stringWithFormat:@"%ld%@", (long)y, NSLocalizedString(@"passport_growth_wake_suffix", nil) ?: @"年睡醒时间里的"];
    m.growthSubtitle = [self awakeWatchPercentDisplay:passport ? passport.awakeWatchPercent : nil];

    // 柱状图：用 locationDist 各点 count 作为 Y 值（与设计注释「地点频次」一致）
    m.goalTrendTitle = NSLocalizedString(@"passport_location_frequency_title", nil) ?: @"观赛地点频次";
    NSMutableArray<NSNumber *> *locTrend = [NSMutableArray array];
    for (PNLocationDist *ld in locationList) {
        [locTrend addObject:@(MAX(0, ld.count))];
    }
    m.goalTrendValues = [locTrend copy];

    PNPassportTeamRecord *tr = passport ? passport.teamRecord : nil;

    // %ld年我关注的主队胜率（赛季 Tab 年份）
    {
        NSString *winTitleFmt = NSLocalizedString(@"passport_followed_team_win_rate_title", nil);
        if (!winTitleFmt.length || [winTitleFmt isEqualToString:@"passport_followed_team_win_rate_title"]) {
            winTitleFmt = @"%ld年我关注的主队胜率";
        }
        m.possessionCardTitle = [NSString stringWithFormat:winTitleFmt, (long)y];
    }
    NSInteger teamWins = tr ? tr.wins : 0;
    float winRateVal = tr ? tr.winRate : 0.f;
    m.possessionLeftLine1 = [NSString stringWithFormat:@"%ld", (long)teamWins];
    m.possessionLeftLine2 = [NSString stringWithFormat:@"%.0f", winRateVal];
    CGFloat winRate01 = (CGFloat)winRateVal;
    if (winRate01 > 1.0f) {
        winRate01 = winRate01 / 100.f;
    }
    m.possessionCenterPercent = MIN(1, MAX(0, winRate01));

    // 空间维度（球场 / 城市 / 国家覆盖）
    m.positionSectionTitle = NSLocalizedString(@"passport_position_strength", nil) ?: @"空间维度";
    m.positionForwardLabel = NSLocalizedString(@"passport_coverage_stadium", nil) ?: @"我去过的\n球场";
    m.positionMidfieldLabel = NSLocalizedString(@"passport_coverage_city", nil) ?: @"我去过的\n城市";
    m.positionDefenderLabel = NSLocalizedString(@"passport_coverage_country", nil) ?: @"我去过的\n国家";
    m.positionForward = passport ? passport.yearStadiumCount : 0;
    m.positionMidfield = passport ? passport.yearCityCount : 0;
    m.positionDefender = passport ? passport.yearCountryCount : 0;

    //线下观赛数据 ability：看台类型分布 standDist → 柱状条目；平均层数 averageFloor
    m.abilitySectionTitle = NSLocalizedString(@"passport_ability_detail", nil) ?: @"线下观赛数据观";
    if (passport && passport.averageFloor.length) {
        m.abilityAverageLevel = passport.averageFloor.doubleValue;
    } else {
        m.abilityAverageLevel = 0;
    }
    NSMutableArray<NSDictionary *> *abilityRows = [NSMutableArray array];
    for (PNStandDist *sd in standList) {
        [abilityRows addObject:@{ @"title": sd.standType ?: @"", @"value": @(MAX(0, sd.count)) }];
    }
    m.abilityItems = [abilityRows copy];

    //观赛身份 tactical：用 identityDist（有 count/percentage）构建 segments
    m.tacticalTitle = NSLocalizedString(@"passport_tactical_identity_title", nil) ?: @"观赛身份";
    NSMutableArray<NSDictionary *> *segs = [NSMutableArray array];
    double totalIdentity = 0;
    for (PNIdentityDist *d in identityList) {
        totalIdentity += MAX(0, (double)d.count);
    }
    for (PNIdentityDist *d in identityList) {
        double p = totalIdentity > 0 ? ((double)MAX(0, d.count) / totalIdentity) : 0;
        [segs addObject:@{ @"p": @(p), @"title": d.identity ?: @"" }];
    }
    m.tacticalSegments = [segs copy];
    m.tacticalIdentityCount = (NSInteger)MIN(6, m.tacticalSegments.count);

    //观赛后的情绪 metric bars：用 emotionDist
    m.metricEmotionCount = (NSInteger)MIN(9, (NSInteger)emotionList.count);
    m.metricHeaderAsideLine1 = (passport && passport.topLocation.length) ? passport.topLocation : @"";
    m.metricHeaderAsideLine2 = (passport && passport.topEmotion.length) ? passport.topEmotion : @"";
    m.metricBarsPrompt = NSLocalizedString(@"passport_metric_prompt", nil) ?: @"";
    NSMutableArray *bars = [NSMutableArray array];
    for (PNEmotionDist *d in emotionList) {
        [bars addObject:@{ @"title": d.emotion ?: @"", @"value": @(MAX(0, d.count)) }];
    }
    m.recentMetricBars = [bars copy];
    m.recentGoalsTitle = @"";
    m.recentGoalsSubtitle = @"";

    // 线上观赛数据：onlineMethodDist（method / count / percentage）
    {
        NSString *onlineTitle = NSLocalizedString(@"passport_online_viewing_title", nil);
        if (!onlineTitle.length || [onlineTitle isEqualToString:@"passport_online_viewing_title"]) {
            onlineTitle = NSLocalizedString(@"passport_outcome_vs_last", nil) ?: @"线上观赛数据";
        }
        m.outcomeTitle = onlineTitle;
    }
    NSMutableArray<NSDictionary *> *onlineLegend = [NSMutableArray array];
    double totalOnlineCount = 0;
    NSInteger maxOnlineCount = 0;
    for (PNOnlineMethodDist *om in onlineList) {
        NSInteger c = MAX(0, om.count);
        totalOnlineCount += (double)c;
        maxOnlineCount = MAX(maxOnlineCount, c);
    }
    NSUInteger omIdx = 0;
    NSArray<NSString *> *pal = PassportOnlineMethodHexPalette();
    for (PNOnlineMethodDist *om in onlineList) {
        NSString *hex = pal[omIdx % pal.count];
        NSInteger c = MAX(0, om.count);
        [onlineLegend addObject:@{
            @"t": om.method ?: @"",
            @"n": [NSString stringWithFormat:@"%ld", (long)c],
            @"h": hex,
        }];
        omIdx++;
    }
    m.outcomeLegend = [onlineLegend copy];

    CGFloat centerShare = 0;
    if (onlineList.count == 0) {
        centerShare = 0;
    } else if (totalOnlineCount > 1e-6) {
        centerShare = (CGFloat)((double)maxOnlineCount / totalOnlineCount);
    } else {
        double pSum = 0;
        double maxP = 0;
        for (PNOnlineMethodDist *om in onlineList) {
            double pv = om.percentage.length ? om.percentage.doubleValue : 0;
            if (pv > 1.0 + 1e-6) {
                pv = pv / 100.0;
            }
            pv = MAX(0, MIN(1, pv));
            pSum += pv;
            maxP = MAX(maxP, pv);
        }
        if (pSum > 1e-6) {
            centerShare = (CGFloat)(maxP / pSum);
        } else {
            centerShare = (CGFloat)(1.0 / (double)onlineList.count);
        }
    }
    m.outcomeCenterPercent = MIN(1, MAX(0, centerShare));

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
