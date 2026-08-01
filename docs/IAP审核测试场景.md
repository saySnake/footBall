# App Store 内购（IAP）审核测试场景清单

> **目标**：覆盖 Apple 审核员在内购（In-App Purchase）场景下会触发的所有路径，确保上架成功。
>
> **依据**：
> - [App Store Review Guideline 3.1.1](https://developer.apple.com/app-store/review/guidelines/#in-app-purchase)（必须使用 IAP）
> - [Guideline 3.1.2](https://developer.apple.com/app-store/review/guidelines/#subscriptions)（自动续期订阅）
> - [Guideline 3.1.2(a)](https://developer.apple.com/app-store/review/guidelines/)（可恢复、订阅条款）
> - [Guideline 2.1](https://developer.apple.com/app-store/review/guidelines/#performance)（性能/崩溃）
> - [Guideline 4.0](https://developer.apple.com/app-store/review/guidelines/#design)（设计）
>
> **适用代码**：
> - `footBall/Core/IAP/PNIAPObserver.{h,m}`（全局事务观察者）
> - `footBall/Core/Network/Requests/MembershipRequest.{h,m}`（服务端验证接口）
> - `footBall/首页/MembershipCenterViewController.m`（会员中心 UI + 购买/恢复/兑换码流程）

---

## 目录

1. [提交前合规自检](#一提交前合规自检硬性要求)
2. [沙箱环境准备](#二沙箱环境准备)
3. [正常购买流程](#三正常购买流程)
4. [支付失败与异常分支](#四支付失败与异常分支)
5. [恢复购买（Restore）](#五恢复购买restore审核高频卡点)
6. [掉单恢复与兜底机制](#六掉单恢复与兜底机制core-logic)
7. [兑换码 / 礼包码](#七兑换码--礼包码)
8. [UI / UX 细节](#八ui--ux-细节guideline-40)
9. [多语言 / 地区](#九多语言--地区)
10. [崩溃与边界](#十崩溃与边界guideline-21)
11. [审核提交 Checklist](#十一审核提交-checklist)

---

## 一、提交前合规自检（硬性要求）

这些是 **没做就会被直接拒** 的硬伤，优先级最高。

| # | 检查项 | 标准 | 当前状态 |
|---|---|---|---|
| 1.1 | **订阅条款 / 隐私政策链接** | 自动续期订阅必须在购买页面**可见可点击**的「使用条款」「隐私政策」「自动续期说明」链接 | ⚠️ `MembershipCenterViewController.m:1337` 仅有文字高亮，需补 tap 手势跳转 |
| 1.2 | **价格由 SKProduct 提供** | 不得硬编码价格；必须用 `SKProduct.price` 并按 locale 显示货币符号 | ⚠️ `buildPlanData` 本地默认 `33`，需以 `apiPlans`/`skProducts` 为准 |
| 1.3 | **恢复购买入口** | 与「订阅/购买」按钮同屏可见 | ✅ 已实现 `restoreBtn`（`MembershipCenterViewController.m:643`） |
| 1.4 | **沙箱购买不真实扣款** | 审核员用沙箱账号购买时应有明确提示 | ✅ 已实现 `isAppStoreSandbox` 判断（`MembershipCenterViewController.m:2191`） |
| 1.5 | **无外部支付诱导** | 不得出现「官网购买」「支付宝」「微信支付」等绕过 IAP 的入口 | ✅ 未发现 |
| 1.6 | **不得强制注册登录才能购买** | 商品展示页不应强制登录 | 需结合实际业务确认 |
| 1.7 | **不得在 IAP 商品中混入不可购买内容** | 例如把实体商品塞进 IAP | ✅ 仅会员订阅 |

### 自动续期订阅额外要求（3.1.2）

| # | 检查项 | 标准 |
|---|---|---|
| 1.8 | **标题包含时长** | 商品名必须包含时长，如「连续包月」「连续包年」，不可仅写「会员」 |
| 1.9 | **续期条款展示** | 在订阅按钮附近明确文字：「¥X/月，自动续期，可随时在设置中取消」 |
| 1.10 | **续期条款链接** | 提供跳转到 EULA / 隐私政策 / 自动续期说明的 URL |

---

## 二、沙箱环境准备

### 2.1 App Store Connect 配置

```
□ 已在「App 内购买项目」中创建 4 个产品（planId 1/2/3/4 对应月/年/永久/创始人）
□ 产品状态：可供出售（Approved）或 准备提交（Ready to Submit）
□ 本版本提交时已勾选「将以下 App 内购买项目加入审核」
□ 「协议、税务和银行业务」中已签署「付费 App 协议」（Paid Applications）
□ 订阅商品已配置「本地化描述」「推广图片」（审核员可能看到）
```

### 2.2 沙箱测试员账号

```
□ 至少创建 2 个 Sandbox Tester：
    - tester-cn@example.com （地区：中国大陆，已绑定支付方式）
    - tester-us@example.com （地区：美国，用于测多币种展示）
□ Sandbox Tester 在「功能」→「App 内购买项目」→「沙盒」→「测试员」中创建
□ 测试设备：设置 → App Store → 沙盒账户（iOS 14+）登录沙箱账号
```

### 2.3 网络条件

```
□ Wi-Fi 正常
□ 模拟弱网（Charles / Network Link Conditioner：3G/Edge）测掉单
□ 模拟断网（飞行模式）测断网恢复
```

---

## 三、正常购买流程

> 对应代码：`onTapPay`（`MembershipCenterViewController.m:1769`）→ `fetchProductAndPay`（`1856`）→ `productsRequest:didReceiveResponse:`（`1885`）→ `startPaymentWithProduct:`（`1877`）→ `paymentQueue:updatedTransactions:`（`1917`）→ `handlePurchasedTransaction:`（`1974`）

### 3.1 月卡 / 年卡 / 永久 / 创始人 各方案

| # | 场景 | 操作 | 预期 |
|---|---|---|---|
| 3.1.1 | 购买月卡（planId=1） | 勾协议 → 切月卡 → 支付 | 弹 Apple 支付面板 → 完成 → 服务端 `verifyPurchase` → 弹「开通成功（测试环境）」→ 自动 `pop` |
| 3.1.2 | 购买年卡（planId=2） | 同上 | 同上，`planId` 路由正确 |
| 3.1.3 | 购买永久（planId=3） | 同上 | 同上 |
| 3.1.4 | 购买创始人（planId=4） | 同上 | 同上 |
| 3.1.5 | 已是会员再次购买 | 已激活会员 → 再点购买 | 应有提示「您已是会员」（当前无此拦截，**建议补**） |

### 3.2 商品信息获取

| # | 场景 | 操作 | 预期 |
|---|---|---|---|
| 3.2.1 | 首次拉取产品 | 未缓存时点击购买 | `fetchProductAndPay` → 显示 HUD → `productsRequest` 回调 → 缓存到 `skProducts` → 发起支付 |
| 3.2.2 | 重复拉取 | 同一商品再次点购买 | 命中 `skProducts` 缓存（`MembershipCenterViewController.m:1847`）直接走 `startPaymentWithProduct` |
| 3.2.3 | invalid 产品 ID | 后台配错 productID | `response.products.count == 0`（`1897`）→ 提示「未找到对应商品」|

---

## 四、支付失败与异常分支

> 对应代码：`paymentQueue:updatedTransactions:`（`MembershipCenterViewController.m:1917`）

| # | 场景 | 复现方式 | 预期 |
|---|---|---|---|
| 4.1 | 用户取消支付 | Apple 支付面板 → Cancel | `SKErrorPaymentCancelled` 分支（`1948`）→ toast「支付已取消，可重试」→ `payInFlight` 复位（**关键，否则无法再次购买**） |
| 4.2 | 支付失败（任意错误） | 沙箱账号配额满 / 卡片无效 | 非 cancel 失败分支（`1950:1953`）→ 显示 `transaction.error.localizedDescription` |
| 4.3 | Deferred（家长审批） | Sandbox Tester 开「Ask to Buy」 | `SKPaymentTransactionStateDeferred`（`1958`）→ 提示「购买待审批，请等待家长确认」 |
| 4.4 | 设备禁用 IAP | 设置 → 屏幕使用时间 → App 内购买 → 关闭 | `onTapPay` 中 `[SKPaymentQueue canMakePayments]` 返回 NO（`1835`）→ 提示「当前设备不支持应用内购买，请检查家长控制设置」 |
| 4.5 | 拉商品失败 | 网络异常 / Apple 服务波动 | `request:didFailWithError:`（`1905`）→ 提示错误 → `payInFlight` 复位 |
| 4.6 | 服务端验证失败 | 后端宕机 / 返回错误 | `handlePurchasedTransaction` 的 `failure` 分支（`2025:2042`）→ **仍 finish 事务防队列堆积**（Apple 阈值约 50 笔），服务端独立事务落 `PENDING_VERIFY` 流水（`MembershipServiceImpl.recordPendingVerifyTxn`）供客服对账 → 弹「验证失败，请联系客服」 |
| 4.7 | 重复点击支付 | 购买 HUD 中再次点支付 | `onTapPay` 入口 `payInFlight` 拦截（`1772`）→ 直接 return |
| 4.8 | 购买中侧滑返回 | 支付进行中从边缘滑动 | 侧滑手势已禁用（`1762:1766`）→ 无法中断支付 |
| 4.9 | 购买中 pop 返回 | 支付进行中点导航返回 | `viewWillDisappear` 检测 `isMovingFromParent && payInFlight`（`200`）→ 拦截/提示 |

---

## 五、恢复购买（Restore）（审核高频卡点）

> 对应代码：`onTapRestore`（`MembershipCenterViewController.m:2054`）→ `restoreCompletedTransactions` → `handleRestoredTransaction:`（`2100`）→ `finishOneRestore`（`2137`）

Apple 明确要求：**非消耗型/订阅必须有 Restore 功能，且必须可用**。

| # | 场景 | 操作 | 预期 |
|---|---|---|---|
| 5.1 | 有购买历史 | 用已购账号登录 → 点「恢复购买」 | `onTapRestore` → HUD → 逐笔 `handleRestoredTransaction` → `verifyPurchase restore=YES` → 「恢复成功」→ 刷新会员状态 |
| 5.2 | 无购买历史 | 全新沙箱账号 → 点恢复 | `restoreTotalCount == 0`（`2075`）→ 「暂无可恢复的购买记录」 |
| 5.3 | 恢复失败（网络） | 关网络后点恢复 | `restoreCompletedTransactionsFailedWithError:`（`2088`）→ 显示 `error.localizedDescription` |
| 5.4 | 多笔事务恢复 | 切换方案多次购买后恢复 | 每笔 `restoreTotalCount++`，`finishOneRestore` 逐笔收尾，HUD 不闪烁（`2137:2158`） |
| 5.5 | 恢复中重复点击 | HUD 显示中再次点恢复 | `restoreInFlight` 拦截（`2056`）→ return |
| 5.6 | 换设备恢复 | 新设备用旧 Apple ID 登录后恢复 | 同 5.1，Apple 同步历史订阅 |
| 5.7 | 服务端未识别该事务 | 历史事务不属于本用户 | `failure` 分支也 `finishTransaction`（`2128`）避免堆积，最终「暂无可恢复的购买记录」 |

---

## 六、掉单恢复与兜底机制（Core Logic）

> 对应代码：`PNIAPObserver` 全局观察者 + VC 的 `resumePendingTransactions`（`MembershipCenterViewController.m:171`）

这套机制是 Apple 审核中最容易出**崩溃**和**掉单投诉**的地方，必须实测。

| # | 场景 | 复现方式 | 预期 |
|---|---|---|---|
| 6.1 | 支付成功瞬间断网 | 购买 → Apple 成功回调时立刻切飞行模式 | 服务端 `verifyPurchase` 失败 → 客户端**仍 finish 事务**（防队列堆积）→ 服务端独立事务落 `PENDING_VERIFY` 流水（`recordPendingVerifyTxn` REQUIRES_NEW）→ 用户重启 App 后通过 `PNIAPObserver.resumePendingTransactions` 兜底重试 |
| 6.2 | 杀进程后重启 | 上条场景 → 强杀 App → 重启 | `PNIAPObserver.start` 注册 → `resumePendingTransactions` 扫描残留 → `handleTransactions` → 上报成功 → finish。注：6.1 若已 finish 则无可扫描事务，靠 `PENDING_VERIFY` 流水由客服/对账定时任务补激活 |
| 6.3 | 进入会员中心兜底 | 残留事务存在 → 进入会员中心 | `viewWillAppear` 调 `resumePendingTransactions`（`186`）→ 由 VC 处理（`isMembershipCenterActive == YES`） |
| 6.4 | 未登录残留 | 退出登录后队列里有事务 | `handleTransactions` 未登录分支（`PNIAPObserver.m:83:88`）→ 本地 finish 清空 |
| 6.5 | VC 激活时 observer 不重复处理 | 会员中心在前台 → 来一笔事务 | `isMembershipCenterActive == YES` → observer `continue`（`PNIAPObserver.m:79:81`），由 VC 处理（避免双重 finish） |
| 6.6 | 兜底上报失败重试 | 兜底场景服务端失败 | `uploadTransaction:` failure（`PNIAPObserver.m:113`）→ 保留事务 → 下次启动再试 |
| 6.7 | 收据为空（首次安装） | 全新设备未购买过 | `currentReceiptBase64` 返回 `""`（`MembershipCenterViewController.m:2165`）→ 触发 `SKReceiptRefreshRequest` → 下次调用拿到有效收据 |

---

## 七、兑换码 / 礼包码

> 对应代码：`onTapRedeemDialogConfirm`（`MembershipCenterViewController.m:1635`）+ `onRedeemGiftCode`（`2228`）

两套入口（兑换弹窗、礼包 tab）都要测。

| # | 场景 | 操作 | 预期 |
|---|---|---|---|
| 7.1 | 免费 GIFT_CODE | 兑换弹窗输入有效免费码 | `needPayment == NO`（`1663`）→ 直接激活会员 → 弹「激活成功！」+ 激活/到期时间 |
| 7.2 | 付费 EXCHANGE_CODE | 输入折扣码 → 确认 | `needPayment == YES` → 应用折扣 → 切订阅 tab → 支付时带 `redeemCode`（`1992:1994`）|
| 7.3 | 付费邀请码 INVITE_CODE | 输入付费邀请码 | `codeType == INVITE_CODE` → 文案变化（`1700:1703`）→ 走 IAP |
| 7.4 | 免费邀请码 | 输入免费邀请码 | 直接激活，文案同 7.1 |
| 7.5 | 码格式错误 | 输入 < 5 位或非 12 位 | `isRedeemCodeReadyToSubmit` 拦截（`1558`）→ 「兑换码格式不正确」 |
| 7.6 | 码为空 | 不输入直接确认 | 提示「请输入兑换码」（`1641:1642`） |
| 7.7 | 码失效 / 已使用 | 输入无效码 | `failure` 回调（`1708`）→ helpLabel 显示错误 + 「点击寻求帮助」 |
| 7.8 | 付费码误入礼包 tab | 礼包输入框输付费码 | `onRedeemGiftCode` 识别 `needPayment`（`2241:2251`）→ 切订阅模式并应用优惠 |
| 7.9 | 服务端返回无 appleProductId | 异常配置 | 提示「该兑换码配置异常，请联系客服」（`1688:1693`） |
| 7.10 | 礼包码长度限制 | 输入超过 5 位 | `onGiftCodeChanged` 截断到 5 位（`2201`）|

---

## 八、UI / UX 细节（Guideline 4.0）

| # | 检查 | 标准 | 当前状态 |
|---|---|---|---|
| 8.1 | 协议未勾选点支付 | 弹窗提示「请先勾选《会员服务协议》」 | ✅ `1776` |
| 8.2 | 支付按钮可用性 | 未勾协议时按钮半透明但可点（用于弹提示） | ✅ `1759` |
| 8.3 | 支付中防连点 | `payInFlight` 拦截 | ✅ `1772` |
| 8.4 | 沙箱成功提示 | 「测试环境购买，不会真实扣款」 | ✅ `2013:2016` |
| 8.5 | 价格与时长展示 | 自动续订需在按钮附近展示「¥X/月，自动续期，可随时取消」 | ⚠️ 需确认 UI 是否清晰 |
| 8.6 | 加载中 HUD | 所有网络请求都应有 loading | ✅ MBProgressHUD 已覆盖 |
| 8.7 | 错误反馈 | 失败有明确文案，不可静默 | ✅ |
| 8.8 | 切换方案不抖动 | `reloadPlanCardsPreservingIndex` 保持 index | ✅ `1422` |

---

## 九、多语言 / 地区

| # | 场景 | 操作 | 预期 |
|---|---|---|---|
| 9.1 | 简体中文 | 设备语言中文 | 所有文案为简体中文 |
| 9.2 | 繁体中文 | 设备语言繁体 | `zh-Hans.lproj` / `zh-Hant.lproj` 已配置，文案应跟随 |
| 9.3 | 英文 | 设备语言英文 | `en.lproj` 已配置 |
| 9.4 | 美国 App Store 账号 | 沙箱账号地区=美国 | 价格显示 `$` 而非 `¥`（依赖 `SKProduct.price`） |
| 9.5 | 货币格式 | 不同地区购买 | 数字格式、货币符号符合 locale |

---

## 十、崩溃与边界（Guideline 2.1）

审核过程中任何崩溃 = 直接拒绝。重点测：

| # | 场景 | 操作 | 预期 |
|---|---|---|---|
| 10.1 | 网络全断进入会员中心 | 飞行模式进页面 | 不崩，展示本地默认数据，可重试 |
| 10.2 | App 启动时队列有遗留事务 | 上次未 finish 事务 + 冷启动 | `PNIAPObserver.start` 安全注册，无重复注册（`PNIAPObserver.m:34:38`） |
| 10.3 | 快速进退会员中心 | 连续 push/pop | `dealloc` 正确 `removeTransactionObserver`（`MembershipCenterViewController.m:175`），无 observer 泄漏 |
| 10.4 | 购买中 App 进后台 | 支付中按 Home | 回到前台后能继续完成事务处理 |
| 10.5 | 购买中收到电话 | 支付中来电 | 挂断后状态恢复 |
| 10.6 | 服务端返回格式异常 | 后端返回非 JSON / 字段缺失 | `yy_modelWithJSON` 不崩，有降级处理 |
| 10.7 | receipt base64 为空 | 首次安装 `appStoreReceiptURL = nil` | `currentReceiptBase64` 返回 `""`（`2165`），不崩，触发刷新 |
| 10.8 | 内存警告 | 模拟内存警告 | 不崩，支付中数据不丢失 |

---

## 十一、审核提交 Checklist

提交 App 前逐项打勾：

### 11.1 App Store Connect 配置
```
□ 4 个 IAP 产品（月/年/永久/创始人）已创建
□ 产品状态：可供出售 或 准备提交
□ 本版本提交已勾选「将以下 App 内购买项目加入审核」
□ 「付费 App 协议」已签署（Paid Applications Agreement）
□ 订阅商品本地化描述、推广图片已配置
```

### 11.2 合规
```
□ 订阅条款链接（EULA）可点击
□ 隐私政策链接可点击
□ 自动续期说明可见
□ 价格由 SKProduct 提供，含时长和周期
□ 无外部支付诱导
```

### 11.3 沙箱测试员
```
□ 至少 2 个 Sandbox Tester（中国 + 美国）
□ 已用 Sandbox Tester 走完完整购买流程
□ Sandbox Tester 交易在 App Store Connect 后台可见
```

### 11.4 功能验证
```
□ 4 个方案正常购买（场景 3.1）
□ 取消支付 / 失败 / Deferred（场景 4.1~4.4）
□ 恢复购买：有历史 / 无历史（场景 5.1~5.2）
□ 掉单恢复：断网+杀进程+重启（场景 6.1~6.2）
□ 兑换码全部分支（场景 7.1~7.9）
□ 多语言切换不崩（场景 9.1~9.3）
```

### 11.5 代码清理
```
□ 删除/脱敏敏感日志（receipt base64、token、transactionId）
□ 确认 NSLog 中无明文用户数据（符合 PrivacyInfo.xcprivacy）
□ 移除调试代码 / 测试入口
```

### 11.6 TestFlight 验证
```
□ 上传 TestFlight 构建版本
□ 用 TestFlight + Sandbox Tester 完整走一遍购买
□ 后台能看到订阅状态变更
□ 至少一次走「支付成功 → 验证失败 → 杀进程重启」掉单恢复流程
```

---

## 附：关键代码索引

| 功能 | 文件 | 位置 |
|---|---|---|
| 全局事务观察者 | `footBall/Core/IAP/PNIAPObserver.m` | `handleTransactions`（`:68`）<br>`uploadTransaction`（`:93`）<br>`resumePendingTransactions`（`:52`） |
| 服务端验证接口 | `footBall/Core/Network/Requests/MembershipRequest.m` | `verifyPurchaseWithBody`（`:37`） |
| 购买入口 | `footBall/首页/MembershipCenterViewController.m` | `onTapPay`（`:1769`）<br>`fetchProductAndPay`（`:1856`）<br>`handlePurchasedTransaction`（`:1974`） |
| 恢复购买 | `footBall/首页/MembershipCenterViewController.m` | `onTapRestore`（`:2054`）<br>`handleRestoredTransaction`（`:2100`） |
| 兑换码 | `footBall/首页/MembershipCenterViewController.m` | `onTapRedeemDialogConfirm`（`:1635`）<br>`onRedeemGiftCode`（`:2228`） |
| 沙箱判断 | `footBall/首页/MembershipCenterViewController.m` | `isAppStoreSandbox`（`:2191`） |
| 收据获取 | `footBall/首页/MembershipCenterViewController.m` | `currentReceiptBase64`（`:2165`） |
| 协议勾选 | `footBall/首页/MembershipCenterViewController.m` | `agreementCheckBtn`（`:658`）<br>`agreementAttrText`（`:1337`） |

---

## 附：常见审核拒绝原因对照

| 拒绝原因（Guideline） | 对应章节 | 应对 |
|---|---|---|
| 3.1.1 不允许 IAP 之外支付 | 1.5 | 已遵守 |
| 3.1.2 自动续期订阅条款缺失 | 1.8~1.10 | **必须补订阅条款链接** |
| 3.1.2(a) Restore 不可用 | 五 | 已实现，需测 5.1~5.7 |
| 2.1 崩溃 | 十 | 必须无崩溃通过全部场景 |
| 2.1 元数据不完整（价格/描述） | 二 | 确认 ASC 后台配置完整 |
| 4.0 设计：购买按钮不可见 | 1.3 | 恢复购买入口已同屏 |
| 4.2 核心功能不可用 | 三~七 | 全部场景需通过 |

---

**文档版本**：v1.0  
**最后更新**：2026-08-01  
**维护**：根据代码变更同步更新场景
