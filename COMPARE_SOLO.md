# 《战姬天下》两个客户端功能差距对照

> 对比对象
> - **单机端**：`C:\Users\Administrator\Downloads\base.apk.1`（188.6 MB，包名同为 `com.happyelements.canon.baiduDK`）
> - **我们的联网端**：`client/zjt_pack_enablefix_signed.apk`（193.0 MB，manifest `81c8ede8…`）
>
> 分析脚本：`scripts/cmp_lua_solo.py`、`cmp_modules.py`、`cmp_endpoints.py`、`cmp_endpoint_fuzzy.py`、`describe_solo_modules.py`

---

## 0. 一句话结论

两边**客户端代码几乎同源**（同一个 1088 模块基线，只有 98 个文件被改过，单机端多 12 个模块）。
真正的差距在**服务端**：我们客户端会调用 **338** 个接口，我们的服务端注册了 **296** 个，
**101 个接口点了必然报错**（其中 13 个「名字写错」已在本次修复，见 §3.1）。

---

## 1. 两个客户端是什么关系

单机端不是「另一个游戏」，而是**同一个改造工程的离线构建**。证据在它 `hecore/rpc.lua` 开头：

```lua
-- 离线单机模式开关（offline-apk 专用，2026-10-15）
-- true 仅在离线构建时由 tools/build_apk.py 文本替换为 true；
-- 普通（联网/本地服）构建不定义该全局（=nil），OFFLINE 恒为 false，
-- 文件末尾的离线 LocalServer 整段为死代码，联网路径零影响。
local OFFLINE = (true == true)
_G.__ZJ_OFFLINE__ = OFFLINE
```

也就是说：**同一套 rpc.lua 源文件，联网构建走网络、离线构建走内嵌 LocalServer**。
它在离线构建里把整段代码内联进 `hecore/rpc.lua`：

| 内联模块 | 行数 | 说明 |
|---|---|---|
| `hecore.offline_activities` | **9234** | 离线本地服务端数据（22 个配置块：worldBoss / fountainWish / gachaXiaoyu / wanted / contend / sworeBrothers / dailyTask / secretShop / chargeReward …） |
| `canon.layer.Activity_QuizBattleLayer` | 979 | 竞猜大作战（新增玩法） |
| `canon.layer.Activity_WheelLayer` | 217 | 幸运转盘（H5 WebView） |
| `canon.request.QuizBattleRequest` | 67 | 竞猜 4 个接口 |
| 其余 7 个 Request 类 | 23–43 | 支付 / 工资 / 编队三维 / 财神记录 / 首页提示 |
| `hecore.offline_meta` | 3 | 离线元数据 |

对照：**我们的 `hecore/rpc.lua` 是 948 行纯网络实现，0 内联**。

---

## 2. 客户端代码差异（98 个文件 / 12 个模块）

解密后逐文件比对（`work/lua_cmp/`，`DIFF_REPORT.txt` 有完整明细）：

- 两边都有：**1088** 个模块，其中 **990** 个逐字节相同
- 实质差异：**98** 个文件（多为单机端更"厚"，因为它带着离线兜底逻辑）
- 模块集合：

```
单机端独有 12 个                          我们独有 0 个
  canon.layer.Activity_QuizBattleLayer        （只有 launcher 的文件名 md5 不同）
  canon.layer.Activity_WheelLayer
  canon.request.CreatePayOrderRequest
  canon.request.GainGoldGodHistoryRequest
  canon.request.GetHomeMessageConfigRequest
  canon.request.GetTeamBattleAttrsRequest
  canon.request.GetUnionBankWageRequest
  canon.request.QueryPayOrderRequest
  canon.request.QuizBattleRequest
  hecore.offline_activities
  hecore.offline_meta
```

差异量最大的几处（`solo` 相对我们有增补）：

| 文件 | 增/删 | 内容 |
|---|---|---|
| `hecore/rpc` | +1 / -9719 | 单机端 rpc 被替换成「1 行 + 11 个内联模块」 |
| `canon/scene/LoginScene` | +191 / -973 | 离线登录分支 + 登录流程重写 |
| `canon/scene/GachaScene` | +49 / -1047 | 求将界面重做（含免费/倒计时/碎片池） |
| `canon/luajava/GspBridge` | +330 / -494 | SDK 桥接（离线构建不需要登录 SDK） |
| `canon/scene/DynamicUpdateScene` | +226 / -354 | 资源更新（离线构建跳过下载） |
| `canon/scene/ConfigScene` | +30 / -243 | 配置页（他们加了后台配置面板入口） |
| `canon/scene/SBTipsScene` | +16 / -213 | 提示层（程序化构建，不依赖 layout json） |
| `canon/configs/gacha_card` | +0 / -13 | **求将新增 id 6..15 十个系列池**（白/夏/春/秋/冬/学/年/恋/海/男装，298 元宝/抽） |
| `canon/models/RewardManager` | +38 / -55 | 服务端返奖后本地立即同步（资源栏刷新） |
| `canon/configs/card_meta` / `card_monologue` | +113/-37、+108/-43 | 卡牌文案/配置补录 |
| `canon/configs/user_level` | +180 / -180 | 等级配置整表重排 |

> 这些是**可以直接搬过来的客户端补丁**，尤其 `gacha_card` 的系列池和 `RewardManager` 的奖励同步。

---

## 3. 服务端功能差距（最要紧）

三个集合：

| 指标 | 数值 |
|---|---|
| 我们客户端引用的 endpoint | **338** |
| 单机端客户端引用的 endpoint | **349** |
| 我们 Python 服务端注册的 endpoint（真实注册表） | **296** |
| **客户端要、服务端没有 → 点了就报错** | **101**（修掉 13 个别名前是 114） |

### 3.1 ✅ 已修：13 个「名字写错」（`server/api/__init__.py` 的 `ALIASES`）

客户端发的是 A，服务端注册成 B，永远匹配不到。已按「只补不覆盖」的方式加了别名表：

| 服务端原注册名 | 客户端实际发 |
|---|---|
| `skyTowerSkipBattle` | `skipSkyTowerBattle` |
| `skyTowerSkipGainAdd` | `gainSkipBattleAddition` |
| `skyTowerSkipGainRewards` | `gainSkipBattleRewards` |
| `EmailReadRewardEmail` | `readRewardEmail` |
| `EmailBatchDeleteRewardEmail` | `batchDeleteRewardEmail` |
| `EmailBatchDeleteSysEmail` | `batchDeleteSysEmail` |
| `EmailBatchDeleteSysNotice` | `batchDeleteSysNotice` |
| `EmailBatchDeleteUserEmail` | `batchDeleteUserEmail` |
| `EmailGainRewardEmailReward` | `gainRewardEmailReward` |
| `getUnionNews` | `getUnionNewsList` |
| `changeUnionDeclaration` | `modifyUnionDeclaration` |
| `changeUnionNotice` | `modifyUnionNotice` |
| `buyGrid` | `buyTreasureGrid` |

验证：`python scripts/coverage.py`（registry 296，缺失 101）。

### 3.2 剩下 101 个要真写实现（按领域，服务端真实注册表口径）

| 领域 | 数量 | 代表接口 |
|---|---|---|
| **军团 / 军团战** | **29** | `getOwnUnionInfo`、`applyUnionCity`、`distributeBonus`、`impeachUnionManager`、`inspireUnionBattle`、`getUnionBattlefieldReport`、`getUnionCityInfo`、`getGvgKnockoutInfo`、`gainGvgKnockoutReward`、`getUnionWarCityMembersList` |
| **跨服 GVG / PK** | **19** | `applyCrossGvg`、`blessForCrossGVG`、`crossGVGGroupBattle`、`getCrossPvp*`、`gainCrossPk*`、`guessCrossPkRank`、`refreshMatch`、`uploadCrossGvgTeamMirror` |
| **邮件 / 领奖** | 15 | `getSysEmailMeta`、`modifyEmail`、`pickUpReward`、`pickUpAllReward`、`gainChapterFinishReward`、`gainTutorialFinishReward`、`getLimitReward`、`getCountdownReward` |
| **背包装备** | 10 | `exchangeItem`、`sellProps`、`rebirthItem`、`sacrificeItem`、`synthetizeCard`、`synthetizeEquip`、`upgradeSkill`、`gachaCardByBox` |
| **宝物** | 7 | `evolveTreasure`、`upgradeTreasure`、`splitTreasure`、`sellTreasures`、`potentialTreasure`、`resetTreasurePotential`、`setupTreasure` |
| **活动** | 6 | `getDailyAchieveInfo`、`gainDailyAchieveReward`、`buyEnergy`、`buyEventPoint`、`challengeChrist`、`testEvent` |
| **商店** | 6 | `exchangeSecretShop`、`refreshSecretShop`、`exchangeMedalShop`、`refreshMedalShop`、`exchangeGiftBag`、`rechargeCalls` |
| **其他** | 8 | `bindAccount`、`defaultPhoneNum`、`challengeContend`、`challengeMysterious`、`challengeFriendList`、`clearElite`、`getRobUserList`、`inviteFbFriends` |
| **神兽 / 元神** | 1 | `robBeastFragment` |

---

## 4. 单机端独有的玩法（我们完全没有）

| 玩法 | 客户端 | 需要的接口 | 备注 |
|---|---|---|---|
| **竞猜大作战** | `Activity_QuizBattleLayer` 979 行 | `getQuizBattleInfo` / `quizBattleSignup` / `quizBattleBet` / `quizBattleWatch` | 每周固定星期开赛的淘汰赛 + 彩池竞猜，错误码 7199xx |
| **幸运转盘** | `Activity_WheelLayer` 217 行 | WebView 打开服务端 H5 页 | 抽奖/发奖全在服务端，奖池后台配 |
| **在线支付** | `CreatePayOrderRequest` / `QueryPayOrderRequest` | `createPayOrder` / `queryPayOrder` | 第三方码支付，下单 + 轮询入账 |
| **军团钱庄工资** | `GetUnionBankWageRequest` | `getUnionBankWage` | 展示与实际发放同源（`bankLevel` + 30 档奖励） |
| **编队三维** | `GetTeamBattleAttrsRequest` | `getTeamBattleAttrs` | 攻/防/血改由服务端下发（本地公式算不齐合体技/神兽/阵法） |
| **首页跑马灯** | `GetHomeMessageConfigRequest` | `homeMessageConfig` | 后台改文案在线即时生效，60s 节流轮询 |
| **财神记录** | `GainGoldGodHistoryRequest` | `getGoldGodHistory` | 迎财神个人摇奖记录 |
| **CDK / 注册 / GM** | — | `exchangeCdk` / `registerUser` / `gmAddCoins` | 后台运维接口 |

---

## 5. 我们有、单机端没有的

单机端是离线构建，这些**联网才有意义**的玩法它直接停用（客户端代码还在，只是走不到）：
跨服 GVG、跨服 PK、军团战报、竞技场排行刷新、好友、邀请、天关/精英关扫荡、实时 TCP 通道。

也就是说：**这些方向的实现只有我们有**，不用去对照它。

---

## 6. 建议的对齐顺序

1. ~~**P0（10 分钟）**：修 13 个 endpoint 注册名~~ ✅ **已完成**（`server/api/__init__.py:ALIASES`）
2. **P1**：搬客户端补丁 —— `gacha_card` 系列池（id 6..15）+ `RewardManager` 返奖本地同步。
3. **P2**：补「点进去就报错」的高频面板接口 —— 背包（exchangeItem/sellProps/upgradeSkill）、宝物、商店、神兽元神。
4. **P3**：军团系列（~24 个）—— 军团是主要盘面，值得整套补。
5. **P4**：跨服 GVG/PK（~20 个）—— 工作量大且需要多服数据，可先做「功能关闭 + 友好提示」。
6. **P5**：单机端那 4 个新玩法（竞猜/转盘/支付/工资）—— 属于增量，最后做。

---

## 附录：本次分析用的脚本

| 脚本 | 作用 |
|---|---|
| `scripts/cmp_lua_solo.py` | 解密两个 APK 的全部 Lua，按逻辑路径对齐，输出 98 个差异文件到 `work/lua_cmp/` |
| `scripts/lua_diff_report.py` | 生成逐文件统一 diff（`work/lua_cmp/DIFF_REPORT.txt`） |
| `scripts/cmp_modules.py` | 模块集合差集（含 rpc.lua 内联模块） |
| `scripts/cmp_rpc_inline.py` | 量化 rpc.lua 内联了哪些模块、各多少行 |
| `scripts/describe_solo_modules.py` | 输出单机端独有模块的注释头 + endpoint |
| `scripts/cmp_endpoints.py` | endpoint 三集合对比（客户端 vs 服务端） |
| `scripts/cmp_endpoint_fuzzy.py` | 模糊配对，找「名字写错」的接口 |
| `scripts/list_client_endpoints.py` | 请求类文件名 → 实际 endpoint 串 |
| `scripts/compare_solo_apk.py` | APK 结构差异（文件/资源/so/dex） |
| `scripts/coverage.py` | 用服务端真实注册表算覆盖率 + 按领域分组列出缺失 |

---

## 附录 B：当前环境状态（重要）

做这轮分析前，机器在 **17:25 重启过**，导致此前的后台任务/adb/模拟器全部无声消失。
现在：

| 组件 | 状态 |
|---|---|
| Python 服务端 (`gameserver.py`) | ✅ 已启动（`:80` + `:9700`） |
| MuMu 模拟器 | ❌ **起不来**：`VERR_NEM_NOT_AVAILABLE` |
| CPU `VirtualizationFirmwareEnabled` | ❌ False |
| `HypervisorPlatform` / `Microsoft-Hyper-V-All` | ❌ Disabled |

MuMu 需要 VT-x 或 Windows Hypervisor Platform 才能跑。要恢复实机测试，需要：
1. BIOS 里打开 `Intel Virtualization Technology` / `VT-d`
2. Windows「启用或关闭 Windows 功能」里勾上 **虚拟机监控程序平台**（HypervisorPlatform）
3. **重启**

在这之前，UI 自动化测试（`scripts/ui_test.py`）跑不了。

### 已修好的测试框架问题

之前的「全部通过」是假阳性，根因有两个：

1. **`work/uitest/_ref_main.png` 根本不存在**，而 `is_main()` 里是
   `if not os.path.exists(REF): return True` —— **fail-open**，于是登录页也被当成主界面，
   所有 probe 都「通过」。已改成 **fail-closed**（缺参照图一律判「不在主界面」）。
2. `ensure_main()` 在没回到主界面时也 `return True`，导致崩溃后重启回登录页被当成 OK。
   已改成返回 `False` 并据此判失败。

另外新增了两个硬证据判据，避免再被「界面变了」骗过：

- **新 `.crash` 文件**：引擎抛未捕获 Lua 错误时会写
  `/data/data/<pkg>/errorlogs/ANDROID_LUA_<ts>.crash` 再 `kill -9`。
  probe 前后对比这个目录，出现新文件就是真崩（即使进程后来自己重启了）。
- **退回登录页检测**：进程活着但屏幕回到登录页 ⇒ 判 `报错后客户端重启回登录页`。

人工实测已确认：**游客登录 → 主界面是通的**，主界面数据正确
（Lv.1 / 主公53525 / ID 100000 / 战力 314 / 体精 100/100 / 金币 100007 / 钻石 10040）。
唯一的干扰是自动弹出的「每日签到」空面板（服务端刻意不下发 `monthlyLoginRewardItems`），
点空白处可关。
