//
//  APIPathValues.h
//  footBall
//
//  Created on 2026/1/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// API路径值常量类 - 统一管理所有API路径值

#pragma mark - 用户模块
/// GET获取当前登录用户信息 , PUT更新当前用户个人资料
FOUNDATION_EXPORT NSString * const APIPathValueUser;
/// 获取当前用户二维码
FOUNDATION_EXPORT NSString * const APIPathValueUserQRCode;
/// 根据用户ID查看他人公开信息
FOUNDATION_EXPORT NSString * const APIPathValueGetUser(NSString *userId);
/// 搜索用户
FOUNDATION_EXPORT NSString * const APIPathValueSearchUser;

#pragma mark - 登录模块
/// 发送验证码
FOUNDATION_EXPORT NSString * const APIPathValueSendCode;
/// 手机登录
FOUNDATION_EXPORT NSString * const APIPathValueLoginPhone;
/// 登出路径
FOUNDATION_EXPORT NSString * const APIPathValueLogout;
/// 刷新Token路径
FOUNDATION_EXPORT NSString * const APIPathValueRefreshToken;

#pragma mark - 身份认证模块
/// 获取当前用户认证状态
FOUNDATION_EXPORT NSString * const APIPathValueVerificationStatus;
/// 提交职业认证申请
FOUNDATION_EXPORT NSString * const APIPathValueVerificationProfessional;
/// 提交实名认证申请
FOUNDATION_EXPORT NSString * const APIPathValueVerificationRealname;
/// 获取实名认证信息
FOUNDATION_EXPORT NSString * const APIPathValueVerificationRealnameInfo;
/// 获取认证历史记录
FOUNDATION_EXPORT NSString * const APIPathValueVerificationHistory;

#pragma mark - 文件模块
/// 获取OSS临时上传凭证(STS Token)
FOUNDATION_EXPORT NSString * const APIPathValueOSSToken;

#pragma mark - 新用户引导
/// 批量关注球队
FOUNDATION_EXPORT NSString * const APIPathValueOnboardingBatchFollow;
/// 完成新用户引导
FOUNDATION_EXPORT NSString * const APIPathValueOnboardingComplete;

#pragma mark - 球队模块
/// 搜索球队
FOUNDATION_EXPORT NSString * const APIPathValueTeamsSearch;
/// 获取球队详情
FOUNDATION_EXPORT NSString * const APIPathValueTeams(NSString *teamId);
/// POST关注球队 ，DELETE取消关注球队
FOUNDATION_EXPORT NSString * const APIPathValueTeamsFollow(NSString *teamId);
/// 批量关注球队
FOUNDATION_EXPORT NSString * const APIPathValueTeamsBatchFollow;
/// 获取我关注的球队列表
FOUNDATION_EXPORT NSString * const APIPathValueTeamsMyFollow;
/// 获取当前用户关注球队的队徽列表
FOUNDATION_EXPORT NSString * const APIPathValueMyTeamIcons;

#pragma mark - 比赛、赛事相关模块
/// 获取精选比赛卡片
FOUNDATION_EXPORT NSString * const APIPathValueMatchFeatured;
/// 获取比赛日程列表
FOUNDATION_EXPORT NSString * const APIPathValueMatchSchedule;
/// 获取指定月份有比赛的日期列表
FOUNDATION_EXPORT NSString * const APIPathValueMatchScheduleDates;
/// 按日期查询 Nami 比赛列表
FOUNDATION_EXPORT NSString * const APIPathValueMatchNamiSchedule;
/// 查询正在进行的 Nami 比赛
FOUNDATION_EXPORT NSString * const APIPathValueMatchNamiLive;
/// 获取 Nami 比赛详情（比赛 + 实时比分 + 统计 + 事件）
FOUNDATION_EXPORT NSString * const APIPathValueMatchNamiDetail(NSString *matchId);
/// 获取 Nami 比赛实时数据（实时比分 + 统计 + 事件 + 文字直播）
FOUNDATION_EXPORT NSString * const APIPathValueMatchNamiLiveDetail(NSString *matchId);
/// 获取 Nami 比赛趋势数据
FOUNDATION_EXPORT NSString * const APIPathValueMatchNamiTrend(NSString *matchId);
/// 获取 Nami 比赛阵容
FOUNDATION_EXPORT NSString * const APIPathValueMatchNamiLineup(NSString *matchId);
/// 获取 Nami 比赛球员统计
FOUNDATION_EXPORT NSString * const APIPathValueMatchNamiPlayerStats(NSString *matchId);
/// 获取 Nami 比赛直播地址
FOUNDATION_EXPORT NSString * const APIPathValueMatchNamiStream(NSString *matchId);
/// 获取 Nami 比赛集锦录像
FOUNDATION_EXPORT NSString * const APIPathValueMatchNamiVideos(NSString *matchId);
/// 搜索比赛
FOUNDATION_EXPORT NSString * const APIPathValueMatchSearch;
/// 获取比赛详情
FOUNDATION_EXPORT NSString * const APIPathValueMatchDetail(NSString *matchId);
/// 获取指定月份有比赛的日期列表
FOUNDATION_EXPORT NSString * const APIPathValueMatchCalendar;
/// 获取关注球队的比赛列表
FOUNDATION_EXPORT NSString * const APIPathValueMatchMyTeams;
/// POST收藏比赛 / DELETE取消收藏比赛
FOUNDATION_EXPORT NSString * const APIPathValueMatchFavorite(NSString *matchId);
/// 获取收藏的比赛列表
FOUNDATION_EXPORT NSString * const APIPathValueMatchGetFavorites;
/// 创建观赛记录
FOUNDATION_EXPORT NSString * const APIPathValueMatchRecordsCreate;
/// 更新观赛记录
FOUNDATION_EXPORT NSString * const APIPathValueMatchRecordsUpdate(NSString *recordId);
/// 获取观赛记录详情
FOUNDATION_EXPORT NSString * const APIPathValueMatchRecordDetail(NSString *recordId);
/// POST点赞比赛 / DELETE取消点赞比赛
FOUNDATION_EXPORT NSString * const APIPathValueMatchInteractionsLike(NSString *matchId);
/// 记录比赛浏览量
FOUNDATION_EXPORT NSString * const APIPathValueMatchInteractionsView(NSString *matchId);
/// 提交比赛认证（打卡）
FOUNDATION_EXPORT NSString * const APIPathValueMatchRecordVerify(NSString *recordId);

#pragma mark - 邮票模块
/// 邮票主页
FOUNDATION_EXPORT NSString * const APIPathValueStampsList;
/// 邮票夹主页 - 按分类组织，每分类max10个，含锁定邮票+解锁进度+新标记
FOUNDATION_EXPORT NSString * const APIPathValueStampsCollection;
/// 获取邮票动态分类列表
FOUNDATION_EXPORT NSString * const APIPathValueStampsCategories;
/// 查看指定分类全部邮票（网格布局）
FOUNDATION_EXPORT NSString * const APIPathValueStampsCategoryAll(NSString *categoryId);
/// 获取邮票详情
FOUNDATION_EXPORT NSString * const APIPathValueStampsDetail(NSString *stampId);
/// 更新邮票展示位置（长按编辑）
FOUNDATION_EXPORT NSString * const APIPathValueStampsDisplay;
#pragma mark - 关注模块
/// POST关注用户 / DELETE取消关注用户
FOUNDATION_EXPORT NSString * const APIPathValueFollowsUser(NSString *userId);
/// 获取我关注的用户列表
FOUNDATION_EXPORT NSString * const APIPathValueFollowsFollowing;
/// 获取关注我的用户列表（粉丝）
FOUNDATION_EXPORT NSString * const APIPathValueFollowsFollowers;
/// 获取关注统计
FOUNDATION_EXPORT NSString * const APIPathValueFollowsStats;
#pragma mark - 好友模块
/// 发送好友请求
FOUNDATION_EXPORT NSString * const APIPathValueFriendsRequests;
/// 获取好友请求列表
/// 获取待处理好友请求数量
FOUNDATION_EXPORT NSString * const APIPathValueFriendsRequestsPendingCount;
/// 处理好友请求
FOUNDATION_EXPORT NSString * const APIPathValueFriendsRequestProcess(NSString *requestId);
/// 获取好友列表
FOUNDATION_EXPORT NSString * const APIPathValueFriendsList;
/// 删除好友
FOUNDATION_EXPORT NSString * const APIPathValueFriendsDelete(NSString *friendId);
/// 扫描二维码添加好友
FOUNDATION_EXPORT NSString * const APIPathValueFriendsScan;
/// 获取推荐好友列表
FOUNDATION_EXPORT NSString * const APIPathValueFriendsRecommend;
/// 获取好友统计
FOUNDATION_EXPORT NSString * const APIPathValueFriendsStats;
#pragma mark - 消费记录模块
/// 添加消费记录
FOUNDATION_EXPORT NSString * const APIPathValueExpenses;
/// 查询消费记录列表
/// PUT更新消费记录 / DELETE删除消费记录
FOUNDATION_EXPORT NSString * const APIPathValueExpensesDetail(NSString *expenseId);
/// 获取消费汇总统计
FOUNDATION_EXPORT NSString * const APIPathValueExpensesSummary;
#pragma mark - 隐私设置模块
/// 获取当前用户隐私设置
/// 更新隐私设置
FOUNDATION_EXPORT NSString * const APIPathValuePrivacySettings;
#pragma mark - 护照模块
/// 获取当前用户护照
FOUNDATION_EXPORT NSString * const APIPathValuePassportMe;
/// 查看他人护照
FOUNDATION_EXPORT NSString * const APIPathValuePassportUser(NSString *userId);
/// 获取当前用户观赛记录列表
FOUNDATION_EXPORT NSString * const APIPathValuePassportMeRecords;
#pragma mark - 社区模块
/// 获取社区好友列表
FOUNDATION_EXPORT NSString * const APIPathValueCommunityFriends;
/// 查看好友邮票收藏
FOUNDATION_EXPORT NSString * const APIPathValueCommunityFriendStamps(NSString *friendId);
/// 查看好友数据统计
FOUNDATION_EXPORT NSString * const APIPathValueCommunityFriendData(NSString *friendId);
#pragma mark - 会员模块
/// 获取会员方案列表
FOUNDATION_EXPORT NSString * const APIPathValueMembershipPlans;
/// Apple IAP收据验证并激活会员
FOUNDATION_EXPORT NSString * const APIPathValueMembershipPurchase;
/// 获取当前用户会员状态
FOUNDATION_EXPORT NSString * const APIPathValueMembershipStatus;
/// 获取会员权益列表
FOUNDATION_EXPORT NSString * const APIPathValueMembershipBenefits;
/// 获取订阅记录
FOUNDATION_EXPORT NSString * const APIPathValueMembershipRecords;
/// Apple S2S 回调
FOUNDATION_EXPORT NSString * const APIPathValueMembershipAppleCallback;
#pragma mark - 数据统计模块
/// 获取当前用户数据统计
FOUNDATION_EXPORT NSString * const APIPathValueStatisticsMe;
#pragma mark - 排行榜模块
/// 获取排行榜
FOUNDATION_EXPORT NSString * const APIPathValueLeaderboard;
NS_ASSUME_NONNULL_END
