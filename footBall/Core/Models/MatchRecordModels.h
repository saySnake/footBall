//
//  MatchRecordModels.h
//  footBall
//
//  对应 MatchRecordVO、MatchRecordDetailVO；分页 PageResult<MatchRecordVO>。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// MatchRecordVO — 观赛记录列表项
@interface PNMatchRecord : NSObject <YYModel>
/// 记录 ID
@property (nonatomic, copy) NSString *recordId;
@property (nonatomic, copy, nullable) NSString *userId;
/// 关联比赛 ID
@property (nonatomic, copy, nullable) NSString *matchId;
/// 比赛名称（手动录入时）
@property (nonatomic, copy, nullable) NSString *matchName;
@property (nonatomic, copy, nullable) NSString *stadiumName;
/// 观赛角色：HOME_FAN / AWAY_FAN / NEUTRAL / TICKET_HOLDER
@property (nonatomic, copy, nullable) NSString *viewingRole;
@property (nonatomic, copy, nullable) NSString *seatLocation;
/// 照片 URL 列表
@property (nonatomic, strong) NSArray<NSString *> *photoUrls;
/// 比赛感想
@property (nonatomic, copy, nullable) NSString *notes;
@property (nonatomic, copy, nullable) NSString *viewingLocation;
@property (nonatomic, copy, nullable) NSString *standType;
/// 观赛身份多选
@property (nonatomic, strong) NSArray<NSString *> *viewingIdentities;
@property (nonatomic, copy, nullable) NSString *postMatchEmotion;
/// 线上观赛方式
@property (nonatomic, strong) NSArray<NSString *> *onlineViewingMethods;
@property (nonatomic, copy, nullable) NSString *watchReason;
/// 认证状态：UNVERIFIED / PENDING / VERIFIED
@property (nonatomic, copy, nullable) NSString *verificationStatus;
@property (nonatomic, copy, nullable) NSString *createTime;
@end

/// MatchRecordDetailVO — 详情（含比赛数据与 GPS 认证）
@interface PNMatchRecordDetail : NSObject <YYModel>
@property (nonatomic, copy) NSString *recordId;
@property (nonatomic, copy, nullable) NSString *userId;
@property (nonatomic, copy, nullable) NSString *matchId;
@property (nonatomic, copy, nullable) NSString *matchName;
@property (nonatomic, copy, nullable) NSString *stadiumName;
@property (nonatomic, copy, nullable) NSString *viewingRole;
@property (nonatomic, copy, nullable) NSString *seatLocation;
@property (nonatomic, strong) NSArray<NSString *> *photoUrls;
@property (nonatomic, copy, nullable) NSString *notes;
@property (nonatomic, copy, nullable) NSString *viewingLocation;
@property (nonatomic, copy, nullable) NSString *standType;
@property (nonatomic, strong) NSArray<NSString *> *viewingIdentities;
@property (nonatomic, copy, nullable) NSString *postMatchEmotion;
@property (nonatomic, strong) NSArray<NSString *> *onlineViewingMethods;
@property (nonatomic, copy, nullable) NSString *watchReason;
@property (nonatomic, copy, nullable) NSString *verificationStatus;
/// 审核拒绝原因
@property (nonatomic, copy, nullable) NSString *rejectReason;
@property (nonatomic, copy, nullable) NSString *createTime;
/// 来自比赛库的开赛时间
@property (nonatomic, copy, nullable) NSString *matchDate;
@property (nonatomic, copy, nullable) NSString *homeTeamName;
@property (nonatomic, copy, nullable) NSString *awayTeamName;
@property (nonatomic, assign) NSInteger homeScore;
@property (nonatomic, assign) NSInteger awayScore;
@property (nonatomic, assign) NSInteger halfHomeScore;
@property (nonatomic, assign) NSInteger halfAwayScore;
@property (nonatomic, copy, nullable) NSString *leagueName;
/// 比赛时长（分钟）
@property (nonatomic, assign) NSInteger duration;
@property (nonatomic, assign) NSInteger yellowCards;
@property (nonatomic, assign) NSInteger redCards;
@property (nonatomic, assign) NSInteger attendance;
/// 认证时 GPS 纬度
@property (nonatomic, copy, nullable) NSString *verifyLatitude;
/// 认证时 GPS 经度
@property (nonatomic, copy, nullable) NSString *verifyLongitude;
/// 定位是否在球场附近（如 5km 内）
@property (nonatomic, assign) BOOL locationMatched;
@end

/// PageResult<MatchRecordVO>
@interface PNMatchRecordPage : NSObject <YYModel>
@property (nonatomic, strong) NSArray<PNMatchRecord *> *list;
@property (nonatomic, assign) NSInteger total;
@property (nonatomic, assign) NSInteger pageNum;
@property (nonatomic, assign) NSInteger pageSize;
@end

NS_ASSUME_NONNULL_END
