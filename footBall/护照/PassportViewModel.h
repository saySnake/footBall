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

@property (nonatomic, copy) NSString *mainScoreText;
@property (nonatomic, copy) NSArray<NSString *> *codeDigitTexts;

@property (nonatomic, copy, nullable) NSString *avatarURL;
@property (nonatomic, copy) NSString *nickname;
@property (nonatomic, assign) NSInteger headerStatLeft;
@property (nonatomic, assign) NSInteger headerStatRight;
@property (nonatomic, copy) NSString *promoButtonTitle;

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
