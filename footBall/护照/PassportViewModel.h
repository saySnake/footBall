//
//  PassportViewModel.h
//  footBall
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PNPassport;

/// 护照页展示数据（合并接口 PNPassport 与设计稿占位，便于后续对接完整 API）
@interface PassportViewModel : NSObject

@property (nonatomic, copy) NSArray<NSString *> *codeDigitTexts;

@property (nonatomic, copy, nullable) NSString *avatarURL;
@property (nonatomic, copy) NSString *nickname;
@property (nonatomic, assign) NSInteger headerStatLeft;
@property (nonatomic, assign) NSInteger headerStatRight;
@property (nonatomic, copy) NSString *promoButtonTitle;

#pragma mark - 护照头部 PassportHeaderView
/// 用户区第一行：护照代号展示（如 NO.0088）
@property (nonatomic, copy) NSString *headerPassportCodeLine;
/// 周折线图：周一至周日 7 个值，范围 0～100（由 weeklyFrequency 归一化）
@property (nonatomic, copy) NSArray<NSNumber *> *headerWeekLineValues;
/// 纪律：红 / 黄 / 干净场（绿）
@property (nonatomic, assign) NSInteger headerRedCards;
@property (nonatomic, assign) NSInteger headerYellowCards;
@property (nonatomic, assign) NSInteger headerCleanMatches;
/// 地图填充：ISO 3166-1 alpha-2 大写（经常去 / 已去过/未去过）
/// 世界地图填充：与 `world-zh.json` 的 `properties.name` 一致的中文国名（兼容两字母 ISO）
@property (nonatomic, copy) NSArray<NSString *> *headerMapOftenISOs;
@property (nonatomic, copy) NSArray<NSString *> *headerMapGoneISOs;
@property (nonatomic, copy) NSArray<NSString *> *headerMapUngoISOs;

/// 年度消费金额展示（RMB 数字文案，可含千分位）
@property (nonatomic, copy) NSString *headerSpendingAmountText;
/// 所选赛季总观赛时长（分钟），与 header2 / 常规赛数据卡一致
@property (nonatomic, copy) NSArray<NSString *> *totalWatchTimeTexts;

#pragma mark - 护照头部下区 PassportHeader2View
/// 当前选中年份（与年份 Tab / 接口 year 一致）
@property (nonatomic, assign) NSInteger displayYear;
/// 所在城市（护照 city，空则 UI 用默认文案）
@property (nonatomic, copy, nullable) NSString *userCity;
/// 本年度观赛场次（大数字，「场」旁白另显示）
@property (nonatomic, assign) NSInteger header2YearMatchCount;
/// 世代标签主数字（如 05后 → "05"）
@property (nonatomic, copy) NSString *header2GenerationMainText;
/// 世代标签是否带「…后」后缀（由 generationTag 是否以「后」结尾推断）
@property (nonatomic, assign) BOOL header2GenerationHasHouSuffix;
@property (nonatomic, assign) NSInteger header2YearWatchMinutes;
@property (nonatomic, assign) NSInteger header2YearGoals;
@property (nonatomic, assign) NSInteger header2CityCount;
@property (nonatomic, assign) NSInteger header2CountryCount;
/// 关注球队队徽 URL，最多取 5 个填满底部前 5 圆
@property (nonatomic, copy) NSArray<NSString *> *header2FollowedTeamLogoURLs;

@property (nonatomic, copy) NSString *regularSeasonTitle;
@property (nonatomic, copy) NSString *avgDurationTitle;
@property (nonatomic, copy) NSString *avgDurationValue;
@property (nonatomic, copy) NSString *matchesYearTitle;
@property (nonatomic, copy) NSString *matchesYearValue;
@property (nonatomic, copy) NSString *avgGoalsMatchTitle;
@property (nonatomic, copy) NSString *avgGoalsMatchValue;
@property (nonatomic, copy) NSString *totalGoalsTitle;
@property (nonatomic, copy) NSString *totalGoalsValue;

@property (nonatomic, copy) NSString *growthHeadline;
@property (nonatomic, copy) NSString *growthSubtitle;

@property (nonatomic, copy) NSString *goalTrendTitle;
/// 与输入信息页观赛地点顺序一致
@property (nonatomic, copy) NSArray<NSString *> *goalTrendXTitles;
@property (nonatomic, strong) NSArray<NSNumber *> *goalTrendValues;

@property (nonatomic, copy) NSString *possessionCardTitle;
@property (nonatomic, copy) NSString *possessionLeftLine1;
@property (nonatomic, copy) NSString *possessionLeftLine2;
@property (nonatomic, assign) CGFloat possessionCenterPercent;

@property (nonatomic, copy) NSString *positionSectionTitle;
@property (nonatomic, assign) NSInteger positionForward;
@property (nonatomic, assign) NSInteger positionMidfield;
@property (nonatomic, assign) NSInteger positionDefender;
@property (nonatomic, copy) NSString *positionForwardLabel;
@property (nonatomic, copy) NSString *positionMidfieldLabel;
@property (nonatomic, copy) NSString *positionDefenderLabel;

@property (nonatomic, copy) NSString *abilitySectionTitle;
/// 副标题中间数字，如 1.45（线下观赛平均层数）
@property (nonatomic, assign) CGFloat abilityAverageLevel;
@property (nonatomic, copy) NSArray<NSDictionary *> *abilityItems;

@property (nonatomic, copy) NSString *tacticalTitle;
/// 副标题中的身份种类数量，如「我以 3 种身份看比赛」中的 3
@property (nonatomic, assign) NSInteger tacticalIdentityCount;
@property (nonatomic, strong) NSArray<NSDictionary *> *tacticalSegments;

@property (nonatomic, copy) NSString *recentGoalsTitle;
@property (nonatomic, copy) NSString *recentGoalsSubtitle;
/// 赛后情绪条：左侧大数字（如 6），旁白两行说明
@property (nonatomic, assign) NSInteger metricEmotionCount;
@property (nonatomic, copy) NSString *metricHeaderAsideLine1;
@property (nonatomic, copy) NSString *metricHeaderAsideLine2;
@property (nonatomic, copy) NSString *metricBarsPrompt;
/// 每项 @{ @"title": @"兴奋", @"value": @21 }，value 为整数，条长按同批最大值归一
@property (nonatomic, copy) NSArray<NSDictionary *> *recentMetricBars;

@property (nonatomic, copy) NSString *outcomeTitle;
@property (nonatomic, assign) CGFloat outcomeCenterPercent;
@property (nonatomic, copy) NSArray<NSDictionary *> *outcomeLegend;

+ (instancetype)viewModelWithPassport:(nullable PNPassport *)passport year:(NSInteger)year;

@end

NS_ASSUME_NONNULL_END
