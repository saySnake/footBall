//
//  PassportViewModel.m
//  footBall
//

#import "PassportViewModel.h"
#import "Passport.h"
#import "PassportNestedModels.h"
#import "Team.h"
#import "AuthManager.h"

/// 与 PNMatchInfoInputViewController 座位 pill 顺序一致
static NSArray<NSString *> *PNPassportSeatTypeOrder(void) {
    static NSArray<NSString *> *order;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        order = @[ @"主席台", @"VIP看台", @"包厢", @"看台区", @"场边", @"山顶", @"短边", @"球门后", @"曲线看台", @"角旗区" ];
    });
    return order;
}

/// 接口/历史看台文案 → 输入页座位分类
static NSString *PNPassportInputSeatLabelForServerStandType(NSString *server) {
    NSString *s = [server stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (s.length == 0) {
        return nil;
    }
    static NSDictionary<NSString *, NSString *> *aliasToLabel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary<NSString *, NSString *> *m = [NSMutableDictionary dictionary];
        NSDictionary<NSString *, NSArray<NSString *> *> *groups = @{
            @"主席台": @[ @"主席台" ],
            @"VIP看台": @[ @"VIP看台" ],
            @"包厢": @[ @"包厢", @"包厢层" ],
            @"看台区": @[ @"看台区" ],
            @"场边": @[ @"场边" ],
            @"山顶": @[ @"山顶" ],
            @"短边": @[ @"短边" ],
            @"球门后": @[ @"球门后" ],
            @"曲线看台": @[ @"曲线看台", @"曲线看球" ],
            @"角旗区": @[ @"角旗区" ],
        };
        for (NSString *label in PNPassportSeatTypeOrder()) {
            for (NSString *alias in groups[label] ?: @[ label ]) {
                m[alias] = label;
            }
        }
        aliasToLabel = [m copy];
    });
    return aliasToLabel[s];
}

/// 与 PNMatchInfoInputViewController 赛后情绪选项一致（接口 emotion / topEmotion 为 emoji）
static NSArray<NSDictionary<NSString *, NSString *> *> *PNPassportEmotionOptionsData(void) {
    static NSArray<NSDictionary<NSString *, NSString *> *> *options = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = @[
            @{ @"name": @"兴奋", @"emoji": @"🤩", @"icon": @"team_ex" },
            @{ @"name": @"激动", @"emoji": @"🥳", @"icon": @"team_ji" },
            @{ @"name": @"希望", @"emoji": @"🤗", @"icon": @"team_hop" },
            @{ @"name": @"遗憾", @"emoji": @"😩", @"icon": @"team_ku" },
            @{ @"name": @"平静", @"emoji": @"😎", @"icon": @"team_ping" },
            @{ @"name": @"失望", @"emoji": @"😤", @"icon": @"team_shi" },
            @{ @"name": @"暴躁", @"emoji": @"😡", @"icon": @"team_angry" },
        ];
    });
    return options;
}

/// 与 PNMatchInfoInputViewController 赛后情绪选项顺序一致
static NSArray<NSString *> *PNPassportEmotionOrder(void) {
    static NSArray<NSString *> *order;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableArray<NSString *> *names = [NSMutableArray array];
        for (NSDictionary<NSString *, NSString *> *opt in PNPassportEmotionOptionsData()) {
            [names addObject:opt[@"name"] ?: @""];
        }
        order = [names copy];
    });
    return order;
}

/// 接口 emotion / topEmotion（emoji）或历史中文别名 → 情绪选项
static NSDictionary<NSString *, NSString *> *PNPassportEmotionOptionForServerValue(NSString *value) {
    NSString *v = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (v.length == 0) {
        return nil;
    }
    static NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *aliasToOption;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *m = [NSMutableDictionary dictionary];
        NSDictionary<NSString *, NSArray<NSString *> *> *legacyNames = @{
            @"希望": @[ @"乐观" ],
            @"遗憾": @[ @"迷茫" ],
        };
        for (NSDictionary<NSString *, NSString *> *opt in PNPassportEmotionOptionsData()) {
            NSString *name = opt[@"name"] ?: @"";
            NSString *emoji = opt[@"emoji"] ?: @"";
            m[name] = opt;
            if (emoji.length) {
                m[emoji] = opt;
            }
            m[[NSString stringWithFormat:@"%@ %@", name, emoji]] = opt;
            for (NSString *alias in legacyNames[name] ?: @[]) {
                m[alias] = opt;
            }
        }
        aliasToOption = [m copy];
    });
    NSDictionary<NSString *, NSString *> *exact = aliasToOption[v];
    if (exact) {
        return exact;
    }
    for (NSDictionary<NSString *, NSString *> *opt in PNPassportEmotionOptionsData()) {
        NSString *name = opt[@"name"] ?: @"";
        NSString *emoji = opt[@"emoji"] ?: @"";
        if ((emoji.length && [v containsString:emoji]) || [v containsString:name]) {
            return opt;
        }
    }
    return nil;
}

static NSString *PNPassportEmotionDisplayNameForServerValue(NSString *value) {
    return PNPassportEmotionOptionForServerValue(value)[@"name"];
}

/// 与 PNMatchInfoInputViewController 观赛地点 pill 顺序一致
static NSArray<NSString *> *PNPassportViewingLocationOrder(void) {
    static NSArray<NSString *> *order;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        order = @[ @"在聚会", @"在球场", @"在酒吧", @"在家里", @"在外面", @"在学校", @"在公司" ];
    });
    return order;
}

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

+ (NSArray<NSDictionary *> *)abilityItemsOrderedFromStandDist:(NSArray<PNStandDist *> *)standList {
    NSMutableDictionary<NSString *, NSNumber *> *countBySeat = [NSMutableDictionary dictionary];
    for (PNStandDist *sd in standList) {
        NSString *label = PNPassportInputSeatLabelForServerStandType(sd.standType);
        if (!label.length) {
            continue;
        }
        NSInteger add = MAX(0, sd.count);
        countBySeat[label] = @([countBySeat[label] integerValue] + add);
    }
    NSMutableArray<NSDictionary *> *rows = [NSMutableArray array];
    for (NSString *title in PNPassportSeatTypeOrder()) {
        [rows addObject:@{ @"title": title, @"value": countBySeat[title] ?: @0 }];
    }
    return [rows copy];
}

+ (NSArray<NSDictionary *> *)emotionMetricBarsOrderedFromEmotionDist:(NSArray<PNEmotionDist *> *)emotionList {
    NSMutableDictionary<NSString *, NSNumber *> *countByEmotion = [NSMutableDictionary dictionary];
    for (PNEmotionDist *ed in emotionList) {
        NSString *label = PNPassportEmotionDisplayNameForServerValue(ed.emotion);
        if (!label.length) {
            continue;
        }
        NSInteger add = MAX(0, ed.count);
        countByEmotion[label] = @([countByEmotion[label] integerValue] + add);
    }
    NSMutableArray<NSDictionary *> *bars = [NSMutableArray array];
    for (NSDictionary<NSString *, NSString *> *opt in PNPassportEmotionOptionsData()) {
        NSString *title = opt[@"name"] ?: @"";
        [bars addObject:@{
            @"title": title,
            @"value": countByEmotion[title] ?: @0,
            @"icon": opt[@"icon"] ?: @"",
        }];
    }
    return [bars copy];
}

+ (NSArray<NSNumber *> *)goalTrendValuesOrderedFromLocationDist:(NSArray<PNLocationDist *> *)locationList {
    NSMutableDictionary<NSString *, NSNumber *> *countByLocation = [NSMutableDictionary dictionary];
    for (PNLocationDist *ld in locationList) {
        NSString *name = [ld.location stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([name isEqualToString:@"在现场"] || [name isEqualToString:@"AT_SCENE"]) {
            name = @"在聚会";
        }
        if (name.length > 0) {
            NSInteger prev = [countByLocation[name] integerValue];
            countByLocation[name] = @(prev + MAX(0, ld.count));
        }
    }
    NSMutableArray<NSNumber *> *values = [NSMutableArray array];
    for (NSString *title in PNPassportViewingLocationOrder()) {
        [values addObject:countByLocation[title] ?: @0];
    }
    return [values copy];
}

+ (NSArray<NSNumber *> *)headerWeekValuesNormalizedFromWeekly:(NSArray<NSNumber *> *)weekly {
    if (![weekly isKindOfClass:[NSArray class]] || weekly.count != 7) {
        return nil;
    }
    // maxV 初始为 1.0 作为下限：当所有值都为 0 或缺失时，避免后续除以 0；
    // 若有更大值则取实际最大值。因此下方 maxV 必然 > 0，三元 maxV>0 永真，
    // 直接用 maxV 做除数即可。
    double maxV = 1.0;
    for (NSNumber *n in weekly) {
        double v = fabs(n.doubleValue);
        if (v > maxV) {
            maxV = v;
        }
    }
    NSMutableArray<NSNumber *> *out = [NSMutableArray arrayWithCapacity:7];
    for (NSNumber *n in weekly) {
        double ratio = n.doubleValue / maxV;
        NSInteger scaled = (NSInteger)llround(MAX(0, MIN(100, ratio * 100.0)));
        [out addObject:@(scaled)];
    }
    return [out copy];
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
        m.headerMapUngoISOs = @[];
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
    NSMutableArray<NSString *> *ungo = [NSMutableArray array];
    NSMutableCharacterSet *cnTrim = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    [cnTrim addCharactersInString:@"\u3000"];
    for (PNCountryHeatmap *h in passport.countryHeatmap) {
        NSString *cn = [h.country stringByTrimmingCharactersInSet:cnTrim];
        if (!cn.length) {
            continue;
        }
        if (h.level >= 2) {
            [often addObject:cn];
        } else if (h.level >= 1) {
            [gone addObject:cn];
        } else {
            [ungo addObject:cn];
        }
    }
    m.headerMapOftenISOs = [often copy];
    m.headerMapGoneISOs = [gone copy];
    m.headerMapUngoISOs = [ungo copy];

    if (passport.yearSpending.length) {
        m.headerSpendingAmountText = passport.yearSpending;
    } else {
        m.headerSpendingAmountText = @"";
    }
    
    // yearTotalWatchTime -> totalWatchTimeTexts（与折线图/地图/消费等同属所选赛季）
    NSInteger minutes = MAX(0, passport.yearTotalWatchTime);
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
        m.header2IconItems = @[];
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
    if (!m.header2IconItems) {
        m.header2IconItems = @[];
    }
}

/// 暗色统计卡四行：与 PassportDarkStatsCardCell 行序一致（总时长 / 赛季天数 / 周末工作日比 / 昼夜比）。
/// 天数展示最多 2 位小数，去掉多余尾零（如 1.50→1.5，1.00→1）
+ (NSString *)seasonDaysNumberText:(double)days {
    if (days < 0 || days != days) {
        days = 0;
    }
    NSString *s = [NSString stringWithFormat:@"%.2f", days];
    while ([s containsString:@"."] && ([s hasSuffix:@"0"] || [s hasSuffix:@"."])) {
        s = [s substringToIndex:s.length - 1];
    }
    return s.length ? s : @"0";
}

+ (NSString *)seasonDaysLineFromPassport:(nullable PNPassport *)passport {
    if (!passport) {
        return @"";
    }
    NSString *unit = NSLocalizedString(@"passport_days_unit", nil) ?: @"天";
    NSString *raw = [passport.seasonDays stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (raw.length) {
        return [NSString stringWithFormat:@"%@ %@", [self seasonDaysNumberText:raw.doubleValue], unit];
    }
    NSInteger minutes = MAX(0, passport.yearTotalWatchTime);
    if (minutes <= 0) {
        return @"";
    }
    double days = minutes / (24.0 * 60.0);
    return [NSString stringWithFormat:@"%@ %@", [self seasonDaysNumberText:days], unit];
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

    NSString *digits = @"";
    if (passport.passportCode.length > 0) {
        digits = passport.passportCode;
    } else if (passport.userId.length > 0) {
        digits = passport.userId;
    } else {
        NSString *localId = AuthManager.sharedManager.user.userId;
        if (localId.length > 0) {
            digits = localId;
        }
    }
    NSMutableArray *box = [NSMutableArray array];
    for (NSUInteger i = 0; i < digits.length; i++) {
        [box addObject:[[digits substringWithRange:NSMakeRange(i, 1)] copy]];
    }

    NSArray<PNIdentityDist *> *identityList = passport ? (passport.identityDist ?: @[]) : @[];
    NSArray<PNEmotionDist *> *emotionList = passport ? (passport.emotionDist ?: @[]) : @[];
    NSArray<PNStandDist *> *standList = passport ? (passport.standDist ?: @[]) : @[];
    NSArray<PNLocationDist *> *locationList = passport ? (passport.locationDist ?: @[]) : @[];
    NSArray<PNOnlineMethodDist *> *onlineList = passport ? (passport.onlineMethodDist ?: @[]) : @[];

    m.codeDigitTexts = [box copy];
    // 头像：直接用接口返回的头像 URL（自己/他人护照都走接口数据）
    // 调用方（PassportViewController）负责在查看自己护照时，用本地 AuthManager 头像覆盖
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

    // 柱状图：观赛地点频次，X 轴类别与输入信息页一致
    m.goalTrendTitle = [NSString stringWithFormat:@"%ld年观赛数据", (long)y];
    m.goalTrendXTitles = PNPassportViewingLocationOrder();
    m.goalTrendValues = [PassportViewModel goalTrendValuesOrderedFromLocationDist:locationList];

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
    CGFloat winRate01 = (CGFloat)winRateVal;
    if (winRate01 > 1.0f) {
        winRate01 = winRate01 / 100.f;
    }
    m.possessionLeftLine1 = [NSString stringWithFormat:@"%ld", (long)teamWins];
    m.possessionLeftLine2 = [NSString stringWithFormat:@"%.0f", winRate01 * 100.f];
    m.possessionCenterPercent = MIN(1, MAX(0, winRate01));

    // 空间维度（球场 / 城市 / 国家覆盖）
    m.positionSectionTitle = NSLocalizedString(@"passport_position_strength", nil) ?: @"空间维度";
    m.positionForwardLabel = NSLocalizedString(@"passport_coverage_stadium", nil) ?: @"我去过的\n球场";
    m.positionMidfieldLabel = NSLocalizedString(@"passport_coverage_city", nil) ?: @"我去过的\n城市";
    m.positionDefenderLabel = NSLocalizedString(@"passport_coverage_country", nil) ?: @"我去过的\n国家";
    // 后端脏数据可能返回负数，展示时用 MAX(0, …) 兜底，避免 UI 出现 "-3 个球场"
    m.positionForward = MAX(0, passport ? passport.yearStadiumCount : 0);
    m.positionMidfield = MAX(0, passport ? passport.yearCityCount : 0);
    m.positionDefender = MAX(0, passport ? passport.yearCountryCount : 0);

    //线下观赛数据 ability：看台类型分布 standDist → 柱状条目；平均层数 averageFloor
    m.abilitySectionTitle = NSLocalizedString(@"passport_ability_detail", nil) ?: @"线下观赛数据观";
    if (passport && passport.averageFloor.length) {
        m.abilityAverageLevel = passport.averageFloor.doubleValue;
    } else {
        m.abilityAverageLevel = 0;
    }
    m.abilityItems = [PassportViewModel abilityItemsOrderedFromStandDist:standList];

    //观赛身份 tactical：用 identityDist（有 count/percentage）构建 segments
    // 环形图只展示频次最高的前 5 项，其余汇总为「其他」；副标题仍用真实身份种类数
    m.tacticalTitle = NSLocalizedString(@"passport_tactical_identity_title", nil) ?: @"观赛身份";
    NSMutableArray<PNIdentityDist *> *filteredIdentities = [NSMutableArray array];
    for (PNIdentityDist *d in identityList) {
        if (d.count > 0) {
            [filteredIdentities addObject:d];
        }
    }
    [filteredIdentities sortUsingComparator:^NSComparisonResult(PNIdentityDist *a, PNIdentityDist *b) {
        NSInteger ca = MAX(0, a.count);
        NSInteger cb = MAX(0, b.count);
        if (ca > cb) {
            return NSOrderedAscending;
        }
        if (ca < cb) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
    double totalIdentity = 0;
    for (PNIdentityDist *d in filteredIdentities) {
        totalIdentity += MAX(0, (double)d.count);
    }
    static const NSUInteger kTacticalChartTopCount = 5;
    NSMutableArray<NSDictionary *> *segs = [NSMutableArray array];
    double otherCount = 0;
    for (NSUInteger i = 0; i < filteredIdentities.count; i++) {
        PNIdentityDist *d = filteredIdentities[i];
        double c = MAX(0, (double)d.count);
        if (i < kTacticalChartTopCount) {
            double p = totalIdentity > 0 ? (c / totalIdentity) : 0;
            [segs addObject:@{ @"p": @(p), @"title": d.identity ?: @"" }];
        } else {
            otherCount += c;
        }
    }
    if (otherCount > 0 && totalIdentity > 0) {
        NSString *otherTitle = NSLocalizedString(@"passport_legend_other", nil);
        if (!otherTitle.length || [otherTitle isEqualToString:@"passport_legend_other"]) {
            otherTitle = @"其他";
        }
        [segs addObject:@{ @"p": @(otherCount / totalIdentity), @"title": otherTitle }];
    }
    m.tacticalSegments = [segs copy];
    m.tacticalIdentityCount = (NSInteger)filteredIdentities.count;

    // 观赛后的情绪：与输入信息页 7 种情绪顺序一致
    NSArray<NSDictionary *> *emotionBars = [PassportViewModel emotionMetricBarsOrderedFromEmotionDist:emotionList];
    NSInteger emotionKindCount = 0;
    for (NSDictionary *item in emotionBars) {
        if ([item[@"value"] integerValue] > 0) {
            emotionKindCount++;
        }
    }
    m.metricEmotionCount = emotionKindCount;
    m.metricHeaderAsideLine1 = (passport && passport.topLocation.length) ? passport.topLocation : @"";
    NSString *topEmotion = passport.topEmotion ?: @"";
    NSString *topEmotionName = PNPassportEmotionDisplayNameForServerValue(topEmotion);
    m.metricHeaderAsideLine2 = topEmotionName.length ? topEmotionName : topEmotion;
    m.metricBarsPrompt = NSLocalizedString(@"passport_metric_prompt", nil) ?: @"";
    m.recentMetricBars = emotionBars;
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
    NSMutableArray *out = [NSMutableArray array];
    for (NSString *title in PNPassportSeatTypeOrder()) {
        [out addObject:@{ @"title": title, @"value": @0 }];
    }
    return [out copy];
}

@end
