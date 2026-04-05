//
//  Passport.h
//  footBall
//
//  PNPassport 对应后端 PassportVO；嵌套类型见 PassportNestedModels.h。
//

#import <Foundation/Foundation.h>
#import "PassportNestedModels.h"

NS_ASSUME_NONNULL_BEGIN

@class TeamIcon;

@interface PNPassport : NSObject <YYModel>

#pragma mark - 个人信息
/// 用户 ID
@property (nonatomic, copy) NSString *userId;
/// 昵称
@property (nonatomic, copy) NSString *nickname;
/// 头像 URL
@property (nonatomic, copy, nullable) NSString *avatar;
/// 所在城市
@property (nonatomic, copy, nullable) NSString *city;
/// 世代标签（60后/70后/…/05后）
@property (nonatomic, copy, nullable) NSString *generationTag;
/// 护照代号（用户 DIY）
@property (nonatomic, copy, nullable) NSString *passportCode;
/// 星座
@property (nonatomic, copy, nullable) NSString *constellation;
/// 关注球队队徽列表（TeamLogoVO）
@property (nonatomic, strong) NSArray<TeamIcon *> *followedTeams;

#pragma mark - 邮票展示
/// 最近获得的邮票摘要
@property (nonatomic, strong) NSArray<PNStampShort *> *recentStamps;
/// 邮票分类快捷入口
@property (nonatomic, strong) NSArray<PNStampCategoryShort *> *stampCategories;

#pragma mark - 年度统计
/// 年度总场次
@property (nonatomic, assign) NSInteger yearTotalMatches;
/// 年度总观赛时长（分钟）
@property (nonatomic, assign) NSInteger yearTotalWatchTime;
/// 年度总进球数
@property (nonatomic, assign) NSInteger yearTotalGoals;
/// 年度城市数（去重）
@property (nonatomic, assign) NSInteger yearCityCount;
/// 年度国家数（去重）
@property (nonatomic, assign) NSInteger yearCountryCount;

#pragma mark - 周频率 / 热力图 / 纪律 / 消费 / 生涯
/// 周观赛频率，7 个点 [日…六]
@property (nonatomic, strong) NSArray<NSNumber *> *weeklyFrequency;
/// 国家热力图
@property (nonatomic, strong) NSArray<PNCountryHeatmap *> *countryHeatmap;
/// 纪律统计（红黄牌/干净场）
@property (nonatomic, strong, nullable) PNDisciplineStats *discipline;
/// 年度消费总额（金额字符串）
@property (nonatomic, copy, nullable) NSString *yearSpending;
/// 生涯总观赛时长（分钟，不限年份）
@property (nonatomic, assign) NSInteger careerTotalWatchTime;

#pragma mark - 主队战绩 / 空间
/// 主队战绩（胜平负/胜率/淘汰/出线）
@property (nonatomic, strong, nullable) PNPassportTeamRecord *teamRecord;
/// 年度球场数（去重）
@property (nonatomic, assign) NSInteger yearStadiumCount;

#pragma mark - 观赛数据观
/// 赛季投入天数
@property (nonatomic, copy, nullable) NSString *seasonDays;
/// 周末:工作日比值化简，如 34:1
@property (nonatomic, copy, nullable) NSString *weekendWeekdayRatio;
/// 白天:深夜比值化简
@property (nonatomic, copy, nullable) NSString *dayNightRatio;
/// 睡醒时间看球百分比（字符串）
@property (nonatomic, copy, nullable) NSString *awakeWatchPercent;

#pragma mark - 分布
/// 观赛地点频次分布
@property (nonatomic, strong) NSArray<PNLocationDist *> *locationDist;
/// 频次最高地点
@property (nonatomic, copy, nullable) NSString *topLocation;
/// 看台类型频次分布
@property (nonatomic, strong) NSArray<PNStandDist *> *standDist;
/// 平均观赛层数（字符串）
@property (nonatomic, copy, nullable) NSString *averageFloor;
/// 观赛身份占比
@property (nonatomic, strong) NSArray<PNIdentityDist *> *identityDist;
/// 赛后情绪分布
@property (nonatomic, strong) NSArray<PNEmotionDist *> *emotionDist;
/// 频次最高情绪
@property (nonatomic, copy, nullable) NSString *topEmotion;
/// 线上观赛方式分布
@property (nonatomic, strong) NSArray<PNOnlineMethodDist *> *onlineMethodDist;

@end

NS_ASSUME_NONNULL_END
