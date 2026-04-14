//
//  APIPathValues.m
//  footBall
//
//  Created on 2026/1/15.
//

#import "APIPathValues.h"

#pragma mark - 用户模块
NSString * const APIPathValueUser = @"/api/v1/users/me";
NSString * const APIPathValueUserQRCode = @"/api/v1/users/me/qrcode";
NSString * const APIPathValueGetUser(NSString *userId) {
    return [NSString stringWithFormat:@"/api/v1/users/%@",userId];
};
NSString * const APIPathValueSearchUser = @"/api/v1/users/search";
#pragma mark - 登录模块
NSString * const APIPathValueSendCode = @"/api/v1/auth/send-code";
NSString * const APIPathValueLoginPhone= @"/api/v1/auth/login/phone";
NSString * const APIPathValueLogout = @"/api/v1/auth/logout";
NSString * const APIPathValueRefreshToken = @"/api/v1/auth/refresh";

#pragma mark - 身份认证模块
/// 获取当前用户认证状态
NSString * const APIPathValueVerificationStatus = @"/api/v1/verification/status";
/// 提交职业认证申请
NSString * const APIPathValueVerificationProfessional = @"/api/v1/verification/professional";
/// 提交实名认证申请
NSString * const APIPathValueVerificationRealname = @"/api/v1/verification/realname";
/// 获取实名认证信息
NSString * const APIPathValueVerificationRealnameInfo = @"/api/v1/verification/realname/info";
/// 获取认证历史记录
NSString * const APIPathValueVerificationHistory = @"/api/v1/verification/history";

#pragma mark - 文件模块
NSString * const APIPathValueOSSToken = @"/api/v1/oss/sts-token";

#pragma mark - 新用户引导
/// 批量关注球队
NSString * const APIPathValueOnboardingBatchFollow = @"/api/v1/onboarding/teams/batch-follow";
/// 完成新用户引导
NSString * const APIPathValueOnboardingComplete = @"/api/v1/onboarding/complete";

#pragma mark - 球队模块
/// 搜索球队
NSString * const APIPathValueTeamsSearch = @"/api/v1/teams/search";
/// 获取球队详情
NSString * const APIPathValueTeams(NSString *teamId) {
    return [NSString stringWithFormat:@"/api/v1/teams/%@",teamId];
};
/// POST关注球队 ，DELETE取消关注球队
NSString * const APIPathValueTeamsFollow(NSString *teamId) {
    return [NSString stringWithFormat:@"/api/v1/teams/%@/follow",teamId];
}
/// 批量关注球队
NSString * const APIPathValueTeamsBatchFollow = @"/api/v1/teams/batch-follow";
/// 获取我关注的球队列表
NSString * const APIPathValueTeamsMyFollow = @"/api/v1/teams/my-follows";

NSString * const APIPathValueMyTeamIcons = @"/api/v1/home/my-teams";

#pragma mark - 比赛、赛事相关模块
/// 获取精选比赛卡片
NSString * const APIPathValueMatchFeatured = @"/api/v1/home/featured-matches";
/// 获取比赛日程列表
NSString * const APIPathValueMatchSchedule = @"/api/v1/home/schedule";
/// 获取指定月份有比赛的日期列表
NSString * const APIPathValueMatchScheduleDates = @"/api/v1/home/schedule/dates";
/// 按日期查询 Nami 比赛列表
NSString * const APIPathValueMatchNamiSchedule = @"/api/v1/matches/nami/schedule";
/// 查询正在进行的 Nami 比赛
NSString * const APIPathValueMatchNamiLive = @"/api/v1/matches/nami/live";
/// 获取 Nami 比赛详情（比赛 + 实时比分 + 统计 + 事件）
NSString * const APIPathValueMatchNamiDetail(NSString *matchId) {
    return [NSString stringWithFormat:@"/api/v1/matches/nami/%@/detail",matchId];
};
/// 获取 Nami 比赛实时数据（实时比分 + 统计 + 事件 + 文字直播）
NSString * const APIPathValueMatchNamiLiveDetail(NSString *matchId) {
    return [NSString stringWithFormat:@"/api/v1/matches/nami/%@/live",matchId];
};
/// 获取 Nami 比赛趋势数据
NSString * const APIPathValueMatchNamiTrend(NSString *matchId) {
    return [NSString stringWithFormat:@"/api/v1/matches/nami/%@/trend",matchId];
};
/// 获取 Nami 比赛阵容
NSString * const APIPathValueMatchNamiLineup(NSString *matchId) {
    return [NSString stringWithFormat:@"/api/v1/matches/nami/%@/lineup",matchId];
};
/// 获取 Nami 比赛球员统计
NSString * const APIPathValueMatchNamiPlayerStats(NSString *matchId) {
    return [NSString stringWithFormat:@"/api/v1/matches/nami/%@/player-stats",matchId];
};
/// 获取 Nami 比赛直播地址
NSString * const APIPathValueMatchNamiStream(NSString *matchId) {
    return [NSString stringWithFormat:@"/api/v1/matches/nami/%@/stream",matchId];
};
/// 获取 Nami 比赛集锦录像
NSString * const APIPathValueMatchNamiVideos(NSString *matchId) {
    return [NSString stringWithFormat:@"/api/v1/matches/nami/%@/videos",matchId];
};
/// 搜索比赛
NSString * const APIPathValueMatchSearch = @"/api/v1/matches/search";
/// 获取比赛详情
NSString * const APIPathValueMatchDetail(NSString *matchId) {
    return [NSString stringWithFormat:@"/api/v1/matches/%@",matchId];
};
/// 获取指定月份有比赛的日期列表
NSString * const APIPathValueMatchCalendar = @"/api/v1/matches/calendar";
/// 获取关注球队的比赛列表
NSString * const APIPathValueMatchMyTeams = @"/api/v1/matches/my-team";
/// POST收藏比赛 / DELETE取消收藏比赛
NSString * const APIPathValueMatchFavorite(NSString *matchId) {
    return [NSString stringWithFormat:@"/api/v1/matches/%@/favorite",matchId];
};
/// 获取收藏的比赛列表
NSString * const APIPathValueMatchGetFavorites = @"/api/v1/matches/favorites";
/// 创建观赛记录
NSString * const APIPathValueMatchRecordsCreate = @"/api/v1/match-records";
/// 更新观赛记录
NSString * const APIPathValueMatchRecordsUpdate(NSString *recordId) {
    return [NSString stringWithFormat:@"/api/v1/match-records/%@",recordId];
};
/// 获取观赛记录详情
NSString * const APIPathValueMatchRecordDetail(NSString *recordId) {
    return [NSString stringWithFormat:@"/api/v1/match-records/%@",recordId];
};
/// POST点赞比赛 / DELETE取消点赞比赛
NSString * const APIPathValueMatchInteractionsLike(NSString *matchId) {
    return [NSString stringWithFormat:@"/api/v1/match-interactions/%@/like",matchId];
};
/// 记录比赛浏览量
NSString * const APIPathValueMatchInteractionsView(NSString *matchId) {
    return [NSString stringWithFormat:@"/api/v1/match-interactions/%@/view",matchId];
};
///
NSString * const APIPathValueMatchRecordVerify(NSString *recordId) {
    return [NSString stringWithFormat:@"/api/v1/match-records/%@/verify",recordId];
};

#pragma mark - 邮票模块
NSString * const APIPathValueStampsList = @"/api/v1/stamps/list";
NSString * const APIPathValueStampsCollection = @"/api/v1/stamps/collection";
NSString * const APIPathValueStampsCategories = @"/api/v1/stamps/categories";
NSString * const APIPathValueStampsCategoryAll(NSString *categoryId) {
    return [NSString stringWithFormat:@"/api/v1/stamps/categories/%@/all",categoryId];
}
NSString * const APIPathValueStampsDetail(NSString *stampId) {
    return [NSString stringWithFormat:@"/api/v1/stamps/%@",stampId];
}
NSString * const APIPathValueStampsDisplay = @"/api/v1/stamps/display";

#pragma mark - 关注模块
NSString * const APIPathValueFollowsUser(NSString *userId) {
    return [NSString stringWithFormat:@"/api/v1/follows/%@",userId];
}
NSString * const APIPathValueFollowsFollowing = @"/api/v1/follows/following";
NSString * const APIPathValueFollowsFollowers = @"/api/v1/follows/followers";
NSString * const APIPathValueFollowsStats = @"/api/v1/follows/stats";

#pragma mark - 好友模块
NSString * const APIPathValueFriendsRequests = @"/api/v1/friends/requests";
NSString * const APIPathValueFriendsRequestsPendingCount = @"/api/v1/friends/requests/pending-count";
NSString * const APIPathValueFriendsRequestProcess(NSString *requestId) {
    return [NSString stringWithFormat:@"/api/v1/friends/requests/%@",requestId];
}
NSString * const APIPathValueFriendsList = @"/api/v1/friends";
NSString * const APIPathValueFriendsDelete(NSString *friendId) {
    return [NSString stringWithFormat:@"/api/v1/friends/%@",friendId];
}
NSString * const APIPathValueFriendsScan = @"/api/v1/friends/scan";
NSString * const APIPathValueFriendsRecommend = @"/api/v1/friends/recommend";
NSString * const APIPathValueFriendsStats = @"/api/v1/friends/stats";

#pragma mark - 消费记录模块
NSString * const APIPathValueExpenses = @"/api/v1/expenses";
NSString * const APIPathValueExpensesDetail(NSString *expenseId) {
    return [NSString stringWithFormat:@"/api/v1/expenses/%@",expenseId];
}
NSString * const APIPathValueExpensesSummary = @"/api/v1/expenses/summary";

#pragma mark - 隐私设置模块
NSString * const APIPathValuePrivacySettings = @"/api/v1/privacy/settings";

#pragma mark - 护照模块
NSString * const APIPathValuePassportMe = @"/api/v1/passport/me";
NSString * const APIPathValuePassportUser(NSString *userId) {
    return [NSString stringWithFormat:@"/api/v1/passport/%@",userId];
}
NSString * const APIPathValuePassportMeRecords = @"/api/v1/passport/me/records";

#pragma mark - 社区模块
NSString * const APIPathValueCommunityFriends = @"/api/v1/community/friends";
NSString * const APIPathValueCommunityFriendStamps(NSString *friendId) {
    return [NSString stringWithFormat:@"/api/v1/community/friends/%@/stamps",friendId];
}
NSString * const APIPathValueCommunityFriendData(NSString *friendId) {
    return [NSString stringWithFormat:@"/api/v1/community/friends/%@/data",friendId];
}

#pragma mark - 会员模块
NSString * const APIPathValueMembershipPlans = @"/api/v1/membership/plans";
NSString * const APIPathValueMembershipPurchase = @"/api/v1/membership/purchase";
NSString * const APIPathValueMembershipStatus = @"/api/v1/membership/status";
NSString * const APIPathValueMembershipBenefits = @"/api/v1/membership/benefits";
NSString * const APIPathValueMembershipRecords = @"/api/v1/membership/records";
NSString * const APIPathValueMembershipAppleCallback = @"/api/v1/membership/apple/callback";

#pragma mark - 数据统计模块
NSString * const APIPathValueStatisticsMe = @"/api/v1/statistics/me";

#pragma mark - 排行榜模块
NSString * const APIPathValueLeaderboard = @"/api/v1/leaderboard";
