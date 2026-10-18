# 服务端接口补齐记录（2026-10-17）

> 目标：**客户端会调用的接口全部有实现，点进去不再报错**。
> 原则：只补我们自己的正常功能，不照搬单机端（`base.apk.1`）特有的玩法。

---

## 一、结果

| 指标 | 补齐前 | 补齐后 |
|---|---|---|
| 客户端引用 endpoint | 338 | 338 |
| 服务端注册 endpoint | 296 | **397** |
| **未实现（MISSING）** | **101** | **0** |
| 返回 500 崩溃（CRASH） | 16 | **0** |
| 有实质回包（OK） | 153 | **220** |
| 业务错误（BUSY，正常拒绝） | 59 | 93 |
| 空壳（SHELL，客户端不读回包） | 25 | 25 |

> 注：BUSY 从 59 涨到 93 是**好事**——原来这些接口是 MISSING（空壳），现在有了实现，
> 只是用无参调用时按业务规则正常拒绝（道具不足 / 未开启 / 记录不存在）。

验证方式（三套，全部通过）：

```powershell
# 1) 进程内全量体检（不用起服务端、不用模拟器，自动发现新模块）
python scripts\final_check.py

# 2) 真协议回归（登录→创角→gameInit→核心玩法，71 项断言）
python server\tests\test_client.py --port 80

# 3) 真 HTTP/AMF3 全接口审计
python server\tests\test_missing.py --port 80 --all
```

---

## 二、新增的 6 个处理器模块

都靠 `load_handlers()` 的 `pkgutil` **自动发现**注册，不需要改 `api/__init__.py`。

| 文件 | 接口数 | 覆盖 |
|---|---|---|
| `server/api/handlers_mail.py` | 15 | 章节奖励、每日成就、邀请/被邀请、周一礼包、新年累充、引导完成、充值返利、倒计时奖励、附灵阶奖励、限时奖励、邮件模板、改绑邮箱、领取奖励 |
| `server/api/handlers_bag2.py` | 19 | 卡牌兑换、物品兑换、武将重生/祭炼、卖道具、碎片合成（卡/装备）、技能升级、宝箱抽卡、抢元神碎片、绑号、争霸/好友/神秘挑战、精英重置、邀请 FB |
| `server/api/handlers_treasure2.py` | 13（+2 覆盖） | 宝物升星/激发潜力/重置潜力/出售/拆分/装备/强化、神秘商店、勋章商店、礼包码、话费充值 |
| `server/api/handlers_activity3.py` | 6 | 买体力/精力/关卡次数、每日成就查询、圣诞挑战、testEvent |
| `server/api/handlers_union_war.py` | 29 | 军团战报名/阵容/鼓舞/战报/城市申请、GVG 淘汰赛、奖金分配、职务任免 |
| `server/api/handlers_cross.py` | 19 | 跨服 PvP（签到表/竞猜/排行/服务器奖励）、跨服 Boss（阶段/伤害/鼓舞/排行） |

---

## 三、顺手修掉的既有 bug

### 3.1 参数缺失导致 500（25 处）

`api.param(params, 'cardId')` 少写默认值 → 返回 `None` → 下游 `int(None)` 抛
`TypeError` → 客户端收到 500。全部补成 `0` / `''` / `False` / `[]`。
脚本：`scripts/fix_param_defaults.py`（可重跑，幂等）。

修复后这些接口在参数缺失时返回**业务错误码**（如 712401「卡牌不存在」），不再是 500。

### 3.2 有实现但回包缺字段，客户端 `index(nil)` 会崩（8 处）

| 接口 | 客户端读的字段 | 修复 |
|---|---|---|
| `deleteSysEmail` / `deleteSysNotice` / `deleteUserEmail` | `data.rewards` | 删除前先结算邮件附件并发奖，带回 `rewards` |
| `dissolveUnion` | `data.sharkUnion`、`data.sharkUserUnion` | 返回「已无军团」的空结构 |
| `cancelDissolveUnion` | 同上 | **拆成独立实现** —— 原来和 `dissolveUnion` 共用一个函数，客户端调「取消解散」不带任何标志参数，会真的把军团解散掉 |
| `transferUnion` | `data.transferTime` | 真实现转让 + 回 `transferTime` |
| `resetChrist` | `data.params` | 重置状态并回 `params` |
| `resetClearTime` | `data.clearMissionRewards` | 回结构完整的空列表 |
| `skipSkyTowerBattle`（别名） | `data.rewards` | 按当前层数折算金币真发 |
| `startAutoClimbBabel` | `data.currFloor`、`data.rewards` | 同上 |
| `recordPraiseId` | `data.rewards` | 真发点赞奖励 |

### 3.3 endpoint 名字对不上（13 个别名）

客户端发 A、服务端注册成 B，永远匹配不到。已在 `server/api/__init__.py` 的
`ALIASES` 里按「只补不覆盖」方式加别名（`skipSkyTowerBattle`、`batchDeleteRewardEmail`、
`readRewardEmail`、`modifyUnionNotice`、`buyTreasureGrid` …）。

### 3.4 meta（getMeta）层面的 3 个坑

| 问题 | 后果 | 修复 |
|---|---|---|
| `treasureSettingConfig.treasurePropId = 400001`（经验球） | 客户端 `TreasureSystemUtils.getPotentialStone()` 把经验球当潜力石显示/校验 | 改成 **400350**（真正的潜力石） |
| `activityEventChristmasConfig` 没有 `christList` | `MerryChristmasChallengePanel.lua:250` 的 `table.clone(nil)` → `pairs(nil)` 直接 Lua 报错，圣诞面板打不开 | 补 `christList=[]`、`costPower`、`costMoney`、`specialReward`（结构完整、内容为空） |
| `crossBossActivityStatus=True` 但 meta 里没有 `crossBossSettingConfig` | `Activity_CrossMultiplayerBossLayer:131` 读 `cfg.unlockLevel` → nil 比较直接崩，**回什么包都进不去** | 暂时关闭该活动（`crossBossActivityStatus=False` + 从开放列表移除）；接口已实现，等拿到真实配置再开 |

### 3.7 各子任务交叉发现的共享文件 bug（已修）

| 位置 | 问题 | 后果 | 修复 |
|---|---|---|---|
| `canon_server.py::_game_setting_config` | `eliteConfig: {}` | 客户端 `getEliteSetting().eliteConsumeEnergy` 是 nil，`EliteSweepConfirmPopmPanel:94` 做「体力 / nil」运算自己就崩，扫荡确认窗打不开 | 补 `{eliteConsumeEnergy: 5, eliteRefreshGoldCost: 10}`（值来自客户端源码注释） |
| `handlers.py::_union_payload` / `h_union_members` | `title` 直接发 99/90/10/0 | 客户端枚举是 1团长/2副团/3精英/4成员，**团长副团的权限判断全部失效**（改公告、审批、调整阵型按钮都不出现） | 加 `_title_enum()` 转换 |
| `handlers_more.py::h_union_formation` | 字段名 `forward/head/middle/tail` | 客户端读 `forwardInfo/formationHeadInfo/formationMiddleInfo/formationTailInfo`，`UnionPkCityPowerupPopPanel:196` 直接 `#formationHeadInfo` → 取 nil 长度崩 | 改成客户端那套字段名，`forwardInfo` 给对象 |
| `handlers_more.py::h_cross_gvg_info` | 缺 `score/challengeNum/teamMirrorRemind/groupChallengedRemind` | 客户端多处 nil 索引 | 补上（0 / false） |
| `handlers.py::getSharkGachaBoxInfo` | 返回 `boxInfo` | 客户端读的是 `gachaBoxCard`，`GachaScene:289` 直接 `pairs(nil)` 崩；且必须**恰好一个** `special=true`，否则 `:428` 读 `gachaSpecialCard.cardStatus` 崩 | 真实现：`player_gacha_box` 12 格，最后一格 special |
| `services/asset.py::pray_card_fragment` / `split_card` | 读 `card_meta.fragmentId/fragmentNum` | **这两个字段在配置里根本不存在**（映射在 `card_fragment_meta`），所以 `prayCardFragment` 永远"道具不足"、`splitCard` 不发碎片 | 新增 `card_fragment(meta_id)` 从 `card_fragment_meta` 反查 |
| `repository/guild.py::guild_of` | `g.*` 与 `m.cross_gvg_applied` 列重名 | sqlite3.Row 取先出现的（军团那份），成员报名状态读错 | 加别名 `member_cross_gvg_applied` |

### 3.8 SQLite 并发

`tx()` 的 `BEGIN IMMEDIATE` 在多进程同时写时会立刻抛 `database is locked`
（`busy_timeout` 对快照冲突不生效）。已加 5 次退避重试。

### 3.6 自动发现容错

`load_handlers()` 现在对每个 `handlers_*.py` 单独 try/except：**一个补充模块写坏
不会拖垮整个服务端**，失败模块名记在 `api.BROKEN_MODULES` 里。

---

## 四、已知缺口（不是 bug，是数据/内容缺失）

| 项 | 现状 | 怎么补 |
|---|---|---|
| 25 个空壳接口 | `appointUnion`、`equipSpirit`/`unequipSpirit`/`upgradeSpirit`/`sellSpirit`/`buySpiritPool`、`lockTreasure`、`readRewardEmail`/`readSysEmail`/`readSysNotice`/`readUserEmail`、`refreshSubAttribute`/`selectSubAttribute`/`unlockSubAttribute`、`resetBabel`、`setAutoSave`、`sendUserEmail`、`record*` 等 | 客户端回调**不读回包**（只关心 retCode），返回 `{}` 安全。若以后发现某个要字段，`python scripts\needs_payload.py <endpoint>` 能查出来 |
| **勋章没有产出源** | 勋章商店货币（itemType=29）全服无处获得 → 宝物碎片买不到 → 升星/激发潜力/重置潜力在真实数据上永远进不去 | 在某个玩法（军团战/竞技场排名）里发放 `medalNum` |
| **圣诞关卡内容表缺失** | `christList`（怪物组/消耗/奖励）原厂未随包下发，`challengeChrist` 返回 `714651` | 补 `activityEventChristmasConfig.christList` |
| **跨服配置缺失** | `crossBossSettingConfig` / `crossBossHeroConfig` / `crossBossGoldBattleConfig` / `crossBossRewardConfig` / `crossArenaSettingConfig` / `crossServerSettingConfig` / `crossServerTimeConfig` 原厂未随包下发（单机端也是空表） | 拿到真实配置后填 `meta_payload.py`，再把 `crossBossActivityStatus` 打开 |
| 跨服玩法单服无对手 | 签表/排行/战报返回结构完整的空数据 | 需要多服部署 |
| **军团战部分配置缺字段** | `unionWarSettingConfig` 少 `silverBuffCost/goldBuffCost/striveCost/inBattleReward/unionSignLimit`，客户端会显示「花费 nil 银币」；`wgvgTotalConfig.crossServerGroupMetas` 为空 → 跨服 GVG 入口不显示 | 拿到原厂数值后补 `meta_payload.py`（属文案/数值层，不崩） |
| **卡牌兑换活动配置为空** | `activityCardExchangeConfig.cardExchangeMeta=[]`、`exchangeDailyConfig` 无该字段 → `exchangeCard`/`exchangeCardDaily` 恒返回 714700（活动未开启），前端根本开不出活动 | 补 `cardExchangeMeta`（字段 `id/cardId/secretNum/exchangeNum`），实现已就绪无需改 |
| **精英关列表为空** | `getEliteInfo` 回 `eliteInfos=[]` → 列表没条目，`clearElite` 没有绑定对象 | 需要精英关配置 |
| **圣兽碎片无展示端** | `getSharkBeasts` 回空表；抢到的碎片落在 `player_beast_fragment` | 实现 `getSharkBeasts` 时从该表读 |
| `services/reward.py` 限制 | 不支持 `itemType 13/14`（圣兽/圣兽碎片），`ENCHANT_POINT(26)` 必须带装备 id | 相关玩法自行落表（handlers_bag2 已这么做） |

---

## 五、工具清单（都在 `scripts/`）

| 脚本 | 用途 |
|---|---|
| `final_check.py` | **主验证工具**：进程内打全部客户端接口，输出 OK/BUSY/SHELL/MISSING/CRASH |
| `call_endpoint.py` | 单接口调试，`call_endpoint.py <ep> "k=v,k2=2"`（简易参数写法，免转义） |
| `needs_payload.py` | 判断某接口客户端是否真的读回包字段（决定空壳是否安全） |
| `coverage.py` | 覆盖率统计 + 缺失按领域分组 |
| `check_dup_endpoints.py` | 检测 endpoint 重名覆盖（新模块可能踩坏旧实现） |
| `fix_param_defaults.py` | 批量补 `api.param` 默认值（幂等） |
| `suggest_impl.py` | 给缺失接口找最相近的已实现接口 |
| `dump_req.py` | 打印 endpoint 对应的客户端请求类源码 |
| `list_client_endpoints.py` | 请求类文件名 → 实际 endpoint 串对照表 |
