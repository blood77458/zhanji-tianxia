# 《战姬天下》私服 · 服务端数据模型设计

> 输入：
> - `API.md` —— 从 `zjt_pack_enablefix_signed.apk` 逆向出的 363 个接口（请求参数 + 客户端读取的响应字段）
> - `work/api_analysis/struct_mail_social.md` —— 邮件 / 好友 / 红包 的字段级契约（489 行）
> - `work/api_analysis/struct_union.md` —— 军团 / 跨服军团战 的字段级契约（1285 行，69 个接口）
> - `work/api_analysis/table_map.csv` —— 363 个接口 → 表的映射
>
> 输出：
> - `server/schema.sql` —— 可直接执行的 DDL（88 张表）
> - `server/db.py` + `server/assembler.py` —— 可运行的组装层原型
> - `work/api_analysis/smoke_assemble.py` —— 证明设计成立的冒烟测试
> - 本文档

---

## 0. 一句话总结

**表结构不必长得像客户端的 JSON，但必须能无损拼出客户端的 JSON。**

现在服务端把整个账号塞进一个 `user_state.json`，问题是：跨玩家操作（军团、好友、排行、红包）根本没有落脚点，而且每次保存要重写全量。这套设计把它拆成 **88 张表 / 637 列 / 32 个索引 / 3 个视图**，同时用一个**组装层（assembler）**保证客户端拿到的东西和现在一模一样——所以可以**一个接口一个接口地迁移**，不用一次性重写。

设计已经跑通验证：`server/schema.sql` 能建库，`server/assembler.py` 能无条件拼出客户端要的全部 `gameInit` 顶层 key，`work/api_analysis/smoke_assemble.py` 是那个证明。

---

## 1. 三条设计原则

### 1.1 客户端契约优先，但只约束「组装层」

客户端读的字段名（`nickName`、`lastestOfflineSeconds`、`sharkSpirits` …）**只出现在组装层**，不进数据库列名。数据库用 `snake_case`，组装层负责映射。

理由：这套客户端有大量拼写不一致的历史包袱（同一个昵称有 `nickname` 和 `nickName` 两种写法，`gainSysEmailReward` 甚至发的是 `{sysEmailId = <metaId>}`——键名和值语义对不上）。如果让列名跟着客户端走，这些坑会渗透进数据层，之后想改都改不动。

### 1.2 单点存储，组装时双向派生

客户端同时维护**两个方向**的「谁穿了什么」：

```
sharkEquips[i].cardId     装备 → 主人
sharkCards[i].equipIds[]  主人 → 装备
```

元神（`spirit.cardId` ↔ `card.cardSpirits[]`）和宝物（`treasure.cardId` ↔ `card.treasureId`）也是同一套。

客户端的 `changeBattleArray` 是**按两个方向互相覆盖**的（`ChangeBattleArrayRequest.onSucceedDefault`：先把所有卡牌的 `equipIds` 清空，再按阵容槽位重新塞回去）。如果服务端也存两份，一旦不同步就会**静默丢装备**。

所以数据库里只存 `player_equip.card_id`（装备→主人）一份权威数据，组装 `sharkCards[].equipIds` / `cardSpirits` / `treasureId` 时用 `WHERE card_id = ?` 反查。

### 1.3 混合模型：关系表 + JSON 列

`gameInit` 一次性下发近百个字段，其中大量是活动状态、每日计数、配置镜像，服务端**从不需要按字段查询**。把它们拆成列只会得到几百个只被整体读写的字段。

判定标准：

| 情况 | 做法 |
|---|---|
| 需要索引 / 跨玩家查询 / 原子自增 | 关系表或独立列 |
| 有独立接口会改它 | 独立列或专表 |
| 只整块下发、服务端不解析 | `*_json` 列 |

具体到 88 张表：**63 张是纯关系表**（账号、角色、资产、军团、好友、邮件、订单），**25 张带 `*_json` 列**用于承载整块下发的客户端契约字段。

> 判断依据来自实际接口扫描：363 个接口里只有约 100 个真正需要按字段查询（军团 69 个、排行、好友检索、跨玩家操作），其余绝大多数接口是「按 player_id 取全量、改几个标量、整块回吐」。

---

## 2. 数据全景：`gameInit` 顶层 key → 宿主表

这是整份设计的骨架。客户端在 `gameInit` 里实际读取的 40+ 个顶层 key（扫描全仓 `DataManager.getGameInitData().X` 得到），每一个都必须有宿主：

| `gameInit` 顶层 key | 宿主表 | 说明 |
|---|---|---|
| `sharkUser` | `player` | 角色主表（38 列） |
| `sharkUserExtend` | `player_extend` + `player_sign_in` + `player_continuous_login` + `player_activity_reward_claim` | 拆分组装 |
| `sharkUserExtendMore` | `player_extend` | 新字段块 |
| `sharkCards.sharkCards[]` | `player_card` + `player_card_skill` + `player_equip`/`player_spirit`/`player_treasure`（反查） | 卡牌的 `equipIds`/`cardSpirits`/`treasureId` 是派生的 |
| `sharkEquips.sharkEquips[]` | `player_equip` | |
| `sharkProps.sharkProps[]` | `player_prop` | |
| `sharkSpirits.sharkSpirits[]` | `player_spirit` + `player_spirit_attr` | |
| `sharkTreasures.sharkTreasures[]` | `player_treasure` | |
| `sharkMatrices.sharkMatrices[]` | `player_matrix` + `player_matrix_grid` | |
| `sharkUserBattleArray` | `player_battle_array` + `player_battle_slot` (+`_equip`/`_spirit`) | 多套阵容 |
| `sharkMissionContext` | `player_mission_context` | **整体必须完整，不能下发 `{}`** |
| `sharkSceneProcess` | `player_scene_process` + `player_scene_country` | |
| `missionCompletes` | `player_mission_complete` | |
| `sharkCardFragments` / `sharkEquipFragments` | `player_fragment`（`kind` 区分） | |
| `sharkUserUnion` | `guild` + `guild_member` | |
| `sharkCrossPkUser` | `player_cross_pk` | |
| `sharkChristInfo` | `player_christ` | |
| `sharkMysteriousCoins` | `player_mysterious_coin` | |
| `sharkDice` | `player_dice` | |
| `sharkActivity` / `sharkActivityExtend` | `player_activity` + `player_activity_reward_claim` | 通用活动表 |
| `sharkBeasts` | `player_activity` | |
| `sharkSkyTower` | `player_sky_tower` | |
| `sharkMultiplayerBossInfo` | `player`（`action_power*`）+ `player_activity` | |
| `sharkDailyData` / `sharkDailyDataExtend` | `player_daily` | 按日期分桶 |
| `sharkUserSecretShop` | `player_secret_shop` | |
| `sharkShop` | `player_shop_loop` | |
| `sharkDestinyInfo` | `player_activity` | |
| `sharkGachaInfo` | `player_extend` + `player_counter` | 保底计数 |
| `sharkElite` | `player_elite` | |
| `sharkGemCards` | `player_gem_card` | 月卡 |
| `fishInviteCode` / `invitationCode` | `player_invite_code` | |
| `crossGachaRanks` | `rank_board` | |
| `gainMondayRewardStatus` | `player_activity_reward_claim` | |
| `applyCrossGvgRemind` / `unionApplyCrossGvg` / `selfApplyCrossGvg` / `selfQuitCrossGvg` / `crossGvgVersion` / `promotion` | `guild` + `guild_member` | |
| `timestamp` / `crossPvpActivityStatus` / `crossBossActivityStatus` | 运行时生成，不落库 | |

---

## 3. 实体关系

```
                        ┌──────────────┐
                        │   account    │  账号（游戏账号 / 游客）
                        └──────┬───────┘
              ┌────────────────┼────────────────┐
              │                │                │
     ┌────────▼──────┐  ┌──────▼──────┐  ┌──────▼──────────┐
     │account_binding│  │auth_session │  │     player      │ 角色（每 server 一个）
     └───────────────┘  └─────────────┘  └──────┬──────────┘
                                                 │
   ┌────────────┬────────────┬───────────┬───────┼────────┬────────────┬───────────┐
   │            │            │           │       │        │            │           │
┌──▼───┐  ┌─────▼────┐ ┌─────▼────┐ ┌────▼────┐ ┌▼──────┐ ┌▼─────────┐ ┌▼────────┐ ┌▼────────┐
│player│  │player_   │ │player_   │ │player_  │ │player_│ │player_   │ │player_  │ │player_  │
│_card │  │equip     │ │prop      │ │spirit   │ │treas- │ │battle_   │ │mission_ │ │daily    │
│      │  │          │ │          │ │+_attr   │ │ure    │ │array/slot│ │context  │ │         │
└──┬───┘  └──────────┘ └──────────┘ └─────────┘ └───────┘ └──────────┘ └─────────┘ └─────────┘
   │
┌──▼───────────┐
│player_card_  │
│skill         │
└──────────────┘

   跨玩家域（按 server_id 分域）
   ┌────────┐   ┌──────────────┐   ┌───────────┐   ┌──────────┐
   │ guild  │───│ guild_member │   │  friend   │   │   mail   │
   └───┬────┘   └──────────────┘   └───────────┘   └────┬─────┘
       │                                                 │
   ┌───┴────┬──────────┬───────────┬──────────┐   ┌──────▼─────────┐
   │        │          │           │          │   │ mail_attachment│
┌──▼───┐ ┌──▼────┐ ┌───▼────┐ ┌────▼────┐ ┌───▼───┐ └────────────────┘
│guild_│ │guild_ │ │guild_  │ │guild_   │ │guild_ │
│apply │ │building│ │news   │ │monster  │ │city   │
└──────┘ └───────┘ └───────┘ └─────────┘ └───┬───┘
                                              │
                                        ┌─────▼──────────┐
                                        │guild_city_apply│
                                        └────────────────┘
```

---

## 4. 表清单（按域）

完整 DDL 见 `server/schema.sql`（88 张表 / 637 列 / 32 个索引 / 3 个视图）。下面按域列出**每张表解决什么问题**。

### 4.1 账号与会话（3 张）

| 表 | 作用 | 关键点 |
|---|---|---|
| `account` | 账号主体 | `account_name` 唯一；游客账号为 NULL。`status` 管封停 |
| `account_binding` | 平台/设备绑定 | `UNIQUE(platform_id, platform_uid)` —— `mappingAccount` 靠它反查账号 |
| `auth_session` | 会话 | `session_key` = RPC header 的 `sk`。加了 `expire_time`，原服务端没有过期概念 |

> 原服务端把 `accountId` 硬编码成 `"100001"`。这里用自增，注意**必须是正整数的十进制字符串**下发（客户端 `tonumber(fields[1])` 后判 `<= 0`）。

### 4.2 角色（4 张）

| 表 | 作用 |
|---|---|
| `player` | 角色主表 = 客户端 `sharkUser`。含全部货币、等级、体力/精力（带更新时间戳）、VIP、当前阵容 |
| `player_extend` | = `sharkUserExtend` + `sharkUserExtendMore`。标量拆列，其余进 `extend_json` / `extend_more_json` |
| `player_tutorial_step` | 新手引导已完成步骤。`canonUtils.IsGuideExecuted` 会 `pairs()` 它 |
| `id_alloc` | 卡牌/装备/元神/宝物的实例 id 分配器 |

**`player` 表里两个容易踩的点：**

1. **货币字段有 4 个必须同时存在**：`free_gems` / `used_free_gems` / `recharge_gems` / `used_recharge_gems`。客户端 `calcComplex_getGemsNow` 做的是 `rechargeGems + freeGems - usedFreeGems - usedRechargeGems`，缺一个就是 nil 算术 → 黑屏（不是闪退，更难查）。
2. **`additional_card_ids` 存成逗号字符串**，因为客户端直接 `:split(",")`。不要在数据库里建成子表再拼——但**也不要**把它当成唯一来源，它只是 `player_battle_slot` 里当前阵容的冗余快照。

### 4.3 资产（10 张）

| 表 | 客户端 key | 说明 |
|---|---|---|
| `player_card` | `sharkCards[]` | 18 列，含培养值/进化值/潜能/锁定 |
| `player_card_skill` | `sharkCard.cardSkills[]` | **必须按配置预生成**，空列表 + `card_meta.skill ~= 0` 会让编队界面 SIGKILL |
| `player_equip` | `sharkEquips[]` | `card_id` 是唯一权威的「穿戴者」 |
| `player_prop` | `sharkProps[]` | 只有 `(meta_id, amount)`，没有实例 id |
| `player_mysterious_coin` | `sharkMysteriousCoins` | 同理 |
| `player_spirit` | `sharkSpirits[]` | |
| `player_spirit_attr` | `spirit.sharkSpiritAttributes[]` | `attribute_growing` 是 **REAL**（客户端按 `growth * level` 算浮点） |
| `player_spirit_unsaved` | `unsaveSpiritId` / `unsaveSpiritAttributes` | 洗炼暂存结果 |
| `player_treasure` | `sharkTreasures[]` | |
| `player_fragment` | `sharkCardFragments` / `sharkEquipFragments` | `kind` 区分 |

### 4.4 阵容（6 张）

客户端的阵容结构（`ChangeBattleArrayRequest.onSucceedDefault` 是权威来源）：

```
sharkUserBattleArray[arrayId] = {
    sharkUserQueue = [ {cardId, equips=[equipId], spirits=[spiritId], treasureId}, ... ]  -- 1 号位=主将
    sharkMatrices  = { sharkMatrices = [ {matrixId, sharkMatrixGrids=[{matrixGridId, cardId}]} ] }
}
```

| 表 | 作用 |
|---|---|
| `player_battle_array` | 阵容本身（`is_active` 标记当前生效的那套） |
| `player_battle_slot` | 槽位 → 卡牌/宝物 |
| `player_battle_slot_equip` / `_spirit` | 槽位上的装备/元神 id 列表 |
| `player_matrix` / `player_matrix_grid` | 阵法 |

> **注意**：客户端有**两套**「当前阵容」表示法。`sharkUser.mainCardId` + `additionalCardIds` 是给 `CommonManager.getQueueData()` 用的快捷方式；`sharkUserBattleArray` 是完整结构。组装时从 `player_battle_slot` **同时**产出这两者，保证一致。

### 4.5 闯关进度（7 张）

| 表 | 客户端 key |
|---|---|
| `player_mission_context` | `sharkMissionContext` |
| `player_scene_process` + `player_scene_country` | `sharkSceneProcess` |
| `player_mission_complete` | `missionCompletes` |
| `player_elite` | `sharkElite` |
| `player_sky_tower` | `sharkSkyTower` |
| `player_christ` | `sharkChristInfo` |

> ⚠️ **`sharkMissionContext` / `sharkSceneProcess` / `missionCompletes` 这三个「要么给全、要么别给」**。客户端写法是 `x = data.f; if not x then <自建默认值> end`，而 Lua **空表为真**，下发 `{}` 会顶掉默认值，下一行 `missionContext.missionId / 100` 就崩。表设计里这几个字段都给了 `NOT NULL DEFAULT`，组装时永远输出完整对象。

### 4.6 每日与计数器（3 张）

| 表 | 作用 |
|---|---|
| `player_daily` | 按 `stat_date` 分桶，承载 `sharkDailyData` + `sharkDailyDataExtend` |
| `player_daily_counter` | 每日计数器的**窄表**：`(player_id, stat_date, counter_key) → value` |
| `player_counter` | 长期计数器（抽卡保底、累计次数） |

**为什么计数器用窄表而不是 50 个列？** 这个客户端有几十个「今天还能买几次 / 打几次」的计数，而且版本迭代时会不断新增。窄表 + 一个 `DAILY_KEYS` 常量表管理，比每次加功能都 `ALTER TABLE` 干净。键名建议：

```python
DAILY_KEYS = {
    'buy_energy_num', 'buy_ep_num', 'buy_action_power_num',
    'elite_reset_num', 'mission_reset_num', 'buy_grid_times',
    'gacha_free_used', 'treasure_gacha_free_used',
    'union_construct_times', 'union_monster_summon_times',
    'question_answered', 'dice_throw_num', ...
}
```

### 4.7 签到 / 连登 / 充值回馈（9 张）

| 表 | 客户端 key |
|---|---|
| `player_sign_in` | `sharkUserExtend.signInInfo` |
| `player_continuous_login` | `sharkUserExtend.continuousLoginInfo` |
| `player_continuous_login_v2` | `sharkUserExtendMore.continuousLoginRewardInfoV2` |
| `player_activity_reward_claim` | 各类「已领档位」列表的统一载体（`gainedChargeMoneyRewardList` / `gainedRewardIds` / `gainedSwornRewardList` / `gainedPraiseRewardIds` / `nyGainedRewardIds` …） |
| `player_gift_code` | 兑换码 |
| `player_gem_card` | `sharkGemCards` 月卡 |
| `player_dice` | `sharkDice` |
| `player_secret_shop` | `sharkUserSecretShop` |
| `player_shop_loop` | `sharkShop.loopPurchaseInfos` |

> `player_activity_reward_claim` 用 `scope` 字符串区分活动，是这张设计里「一表多用」最典型的一处。它替代了散落在 `sharkUserExtend` / `sharkActivity` 里的 6~7 个 `gainedXxxList` 数组。

### 4.8 活动（2 张）

| 表 | 作用 |
|---|---|
| `player_activity` | `(player_id, activity_key) → JSON`。27+ 个活动的状态全塞这里 |
| `player_activity_reward_claim` | 「已领奖」结构化（见上） |

**为什么不给每个活动建表？** 逐一看过：新年 8 天、等级赛、聚宝盆、骰子、猜题、财神、限时充值、许愿池……每个的状态字段形态都不同，而且服务端从不按字段查询。用 `activity_key` + JSON 是这里唯一划算的做法。代价是：**新增活动不用改表**，但活动状态里凡是「已领奖」的都要同时写进 `player_activity_reward_claim`，否则补单/查重会很痛苦。

**例外**：`sharkDice` 和 `sharkUserSecretShop` 有明确的数值语义（次数、刷新时间），做成了独立表。

### 4.9 社交：好友 / 邀请 / 礼物 / 红包 / 点赞（6 张）

| 表 | 作用 |
|---|---|
| `friend` | **单向存两行**（A→B 和 B→A 各一行）。`gift_sent_date` / `gift_taken_date` 用日期字符串控制每日一次 |
| `friend_invitation` | 邀请（待审/接受/拒绝/取消）。`invitationSent` / `invitationReceived` 由它现算 |
| `red_packet` / `red_packet_claim` | 红包 |
| `player_praise` | 点赞 |
| `player_invite_code` | 邀请码活动 |

**好友列表是组装出来的视图，不是一张表。** 客户端要的好友条目：

```
friendUid, nickName, level, mainCardMetaId, unionName, online,
lastestOfflineSeconds, giftSent, invitationSent, friend
```

组装来源：`player`（昵称/等级）+ `player_card`（主将 metaId）+ `guild_member` JOIN `guild`（军团名）+ `auth_session`（是否在线）+ `player.last_logout_time`（离线秒数）+ `friend_invitation`（邀请状态）。

> ⚠️ **`online` 为假时 `lastestOfflineSeconds` 必须存在**——`MyFriendsPanel:239-241` 会对它做时间减法，缺了直接崩。`acceptInvitation.acceptedFriend` / `acceptAllInvitations.acceptedFriends[]` 会走同一套渲染器，也必须带这两个字段。

### 4.10 邮件（4 张）

| 表 | 作用 |
|---|---|
| `mail` | 四类邮件共用，`mail_type` 区分（1 系统邮件 / 2 奖励邮件 / 3 系统公告 / 4 玩家邮件） |
| `mail_attachment` | 附件（`{itemType, metaId, amount}`），独立表因为「领取」要按条标记 |
| `sys_email_meta` | **随 `getUserEmails` 一起下发的模板数组**，不是服务端自用配置 |
| `user_mail_log` | 玩家间邮件审计 |

三个「一定崩」的字段（全部做了 `NOT NULL`）：

| 字段 | 崩在哪 |
|---|---|
| `sysEmails/rewardEmails[].receiveSeconds` | `EmailScene:504` 排序比较 + `:645` 时间算术 |
| `sysEmailMeta[].contentText` | `EmailScene:522` `string.gsub(nil)` |
| `rewardEmails[].content` | `EmailScene:526` 同上 |

> ⚠️ **不要把 `sysEmails` 和 `rewardEmails` 合并下发**。客户端会自己 `table.union(sysEmails, rewardEmails)` 后回写覆盖（`EmailScene:495-510`）。服务端必须返回两个独立数组。
> ⚠️ `sysNotices[].detail` 必须是**合法 JSON 字符串**（客户端 `cjson.decode`）。11 种通知类型的内部键完全不同，所以设计成整块 `detail` 列。
> ⚠️ `userEmails` 数组**不能有空洞**（`EmailScene:732-734` 取值后无 nil 检查）。查询时不要因为过滤条件跳号。

### 4.11 军团 / 跨服军团战（23 张）

客户端在这块有 **69 个接口**（不是 52），而现有服务端只实现了 1 个（`getUserUnionInfo` → 只回 `{hasUnion:False}`）。这是整个协议里最大的空洞。

| 表 | 作用 |
|---|---|
| `guild` | 军团主体（名字/宣言/公告/等级/财富/人数/排名/团长/转让/解散/军团战届数/跨服报名） |
| `guild_member` | 成员 + 职务 + 状态 + 贡献（日/周/总）+ 建设记录 + 三种鼓舞计数 + 三种军团战领奖标志 + 跨服报名 + 阵位 + 工资 |
| `guild_apply` | 入团申请 |
| `guild_building` | 建筑等级（1大厅 2商城 3钱庄 4斗兽场） |
| `guild_donate_log` | 建筑捐献（`donateAnnouncement[]` 取最近 10 条） |
| `guild_shop_record` | 军团商城购买记录（`specialShopRecord[]`；`leftNum` 是算出来的，不落库） |
| `guild_news` | 军团动态（`news_type` 分普通/军团战两个数组，`event_type` 是客户端 `type`） |
| `guild_monster` | 斗兽场 BOSS（血量/逃脱时间戳/召唤次数/分配状态/奖励金额） |
| `guild_monster_damage` | 斗兽伤害榜 |
| `guild_monster_allocate` | 斗兽奖励分配 |
| `guild_city` | 军团战城池（归属/等级/连续占领次数） |
| `guild_city_apply` | 城池竞标（投入财富/名次/是否中标） |
| `guild_battle_report` | 本服军团战战报 |
| `guild_formation_slot` / `guild_formation_team` | 军团战阵型（按「城池 × 阵位」存；军团级鼓舞数与成员级同名不同义） |
| `guild_score` | 军团积分 |
| `cross_gvg_group` | 跨服服务器分组 |
| `cross_gvg_apply` | 跨服报名（含 `out` 淘汰状态、`promotion` 晋级） |
| `cross_gvg_score` | 跨服小组赛积分 |
| `cross_gvg_formation` | 跨服阵型镜像 |
| `cross_gvg_report` | 跨服小组赛/淘汰赛战报 |
| `cross_gvg_bless` / `cross_gvg_bless_log` | 祝福 / 至尊帝王 |

**军团是唯一必须真关系化的社交系统**——大量跨玩家操作（申请、审批、任命、踢人、转让、城池争夺、竞标）全部需要按 `guild_id` 查询和原子更新。

> ⚠️ 这一块有 **4 组极易写错的字段名**，组装层务必逐字照抄：
> - `mainCardMeataId`（阵型成员，原厂拼写）≠ `mainCardMetaId`（跨服 signs / 申请者）≠ `mainCardId`（成员 / 动态）
> - `userName`（阵型 / signs）≠ `nickName`（成员 / 申请者，大写 N）≠ `nickname`（帝王 / 新闻 detail）
> - `arenaRank`（不是 `areanaRank`）
> - 阵型里的 `gemInspireNum` 在军团级是总数，在成员级是个人次数
>
> ⚠️ 三个 **nil 必崩**：`unionMonsterHp`（走 `tonumber()`）、`unionMonsterEscapeSeconds`（进 `+3` 算术）、`sharkUnionMonster.reward.amount`（进 `totalNum - X` 的减法，且 `reward` 必须是对象不是数组）。
>
> ⚠️ 战报的响应根 key 有冲突：代码硬读 `data.sharkUnionBattlefieldReport`（`BattleScene.lua:128-133`），原厂 DSL 注释写的是 `battleReport` —— **两个都发**。
>
> ⚠️ 军团模块还需要在 `getMeta` 里镜像一批配置：`unionSettingConfig`、`union_building_*`、`union_shop_normal/special`、`union_boss_meta`、`unionWarSettingConfig`、`wgvgTotalConfig` 等。缺 `UnionPkConfig.cityFrontLimit()` 会让阵型界面画不出格子。
>
> 字段级细节见 `work/api_analysis/struct_union.md`（29 个小节，含 20 个原厂 `<bean>` schema 与「69 接口 → 结构」对照表）。

### 4.12 竞技 / 排行（4 张）

| 表 | 作用 |
|---|---|
| `arena_rank` | 竞技场个人分数与排名 |
| `pk_record` | PK 战报 |
| `rank_board` | **通用排行榜**：`(board_key, server_id, round, rank) → entry_json` |
| `player_cross_pk` | 跨服 PVP 个人状态 |

> `rank_board` 是刻意的「宽表 + JSON」。排行榜条目全是展示数据（昵称/等级/战力/军团名），服务端从不按字段查，但需要按 `score` 排序 —— 所以拆出 `score` / `player_id` 两列用于排序和反查，其余整块 JSON。

### 4.13 支付 / 订单（3 张）

| 表 | 作用 |
|---|---|
| `payment_order` | 订单（`order_id` 做主键天然防重复） |
| `charge_log` | 发货流水（防重复发钻石的审计） |
| `phone_charge` | 话费充值 |

### 4.14 全局 / 运营（7 张）

`server_partition`（选服表）、`gacha_log`、`reward_log`、`announcement`、`maintenance_item`、`ban_record`、`unknown_rpc`。

> `unknown_rpc` 是替代现在 `rpc_payloads.jsonl` 的正式版本 —— 继续补端点时的抓手。
> `reward_log` 是新增的：出问题时这是唯一能证明「我确实发过奖励」的东西。强烈建议每个发奖路径都写一条。

---

## 5. 组装层：从表到客户端 JSON

这是整套设计的**关键接缝**。建议单独一个模块 `server/assembler.py`，职责是：

```
DB 行  ──assembler──▶  客户端要的 dict  ──amf3──▶  响应
```

### 5.1 核心函数

```python
def build_shark_user(player_row, ext_row) -> dict:
    """player + player_extend  →  sharkUser"""

def build_shark_extend(player_row, ext_row, sign_in, cont_login, claims) -> dict:
    """→ sharkUserExtend（28 字段，缺一个都可能崩）"""

def build_shark_extend_more(...) -> dict:
    """→ sharkUserExtendMore"""

def build_card(card_row, skills, equips, spirits, treasure) -> dict:
    """→ sharkCards.sharkCards[] 的一项。
       equipIds / cardSpirits / treasureId 都是反查出来的"""

def build_equip(equip_row) -> dict:
    """→ sharkEquips.sharkEquips[] 的一项"""

def build_battle_arrays(player_id) -> list:
    """player_battle_array + slot + slot_equip/spirit  →  sharkUserBattleArray"""

def build_game_init(player_id) -> dict:
    """把所有零件拼成 gameInit 的完整响应"""

def build_friend_entry(player_id, friend_id) -> dict:
    """→ 好友列表的一项（含组装出来的 online / lastestOfflineSeconds）"""
```

### 5.2 组装层的三条铁律

1. **数组永远是数组。** AMF3 编码器把空 Lua 表编成「空对象」时，客户端 `ipairs` 读 0 次（多数场景不崩），但**一旦有元素**就会因为「字典带字符串键」而全部读不到 → 表现为**界面全空**。组装层对列表字段必须显式产出密集数组（服务端的 AMF3 writer 要有 `write_array` 而不是只 `write_object`）。

2. **要么给全，要么别给。** Lua 空表为真。凡是客户端写了 `x = data.f; if not x then <默认值> end` 的字段（`sharkMissionContext`、`sharkSceneProcess`、`missionCompletes`、`accountReturnRewards`），**要么输出完整对象，要么整个 key 不出现**。绝不能输出 `{}`。

3. **数字就是数字，字符串就是字符串。** 两个已知的硬约束：
   - `sharkUser.uid` / `loginServer.uid` 必须是**字符串**（luajava 签名 `setGspGameUserId(java.lang.String)V`，传 number → `Invalid method call` → SIGKILL）
   - `sharkUser.additionalCardIds` 必须是**逗号字符串**（客户端 `:split(",")`）
   - 反过来，`level` / `exp` / `gem` / 各种时间戳必须是**数字**（客户端直接做算术和比较）

---

## 6. 接口 → 表 映射

完整的 363 行映射见：

- `work/api_analysis/table_map.csv` —— 可直接用 Excel/表格筛选
- `work/api_analysis/table_map.json` —— 程序读取

字段：`method / 操作(读|写) / 分类 / 涉及表 / 请求参数 / 响应字段 / 服务端已实现`

### 6.1 表热度（被多少接口涉及）

| 表 | 涉及接口数 | 说明 |
|---|---|---|
| `player` | 135 | 几乎每个写接口都要动货币/次数 |
| `player_daily` | 91 | 大量功能有每日限制 |
| `player_activity_reward_claim` | 89 | 「已领奖」遍布所有活动 |
| `player_daily_counter` | 81 | 同上 |
| `player_activity` | 71 | 活动状态兜底 |
| `guild` + `guild_member` | 67 / 66 | 军团 69 个接口 |
| `player_prop` | 65 | 升级/合成都要吃材料 |
| `player_card` | 54 | |
| `player_extend` | 36 | |
| `player_card_skill` | 34 | |
| `id_alloc` | 33 | 所有产出实例 id 的接口 |

### 6.2 典型接口的落表

| 接口 | 操作 | 涉及表 |
|---|---|---|
| `createUser` | 写 | `account`, `account_binding`, `player`, `player_extend`, `player_tutorial_step`, `player_daily`, `player_daily_counter` |
| `gameInit` | 读 | `account`, `account_binding`, `player`, `player_extend`, `player_tutorial_step`（+ 组装时扇出到全部资产表）|
| `gachaCard` | 写 | `player_card`, `player_card_skill`, `player_counter`, `gacha_log`, `id_alloc`, `player_prop`, `player_daily` |
| `clearMission` | 写 | `player_mission_context`, `player_scene_process`, `player_mission_complete`, `player_elite`, `player_daily_counter`, `player_prop` |
| `challengeUnionMonster` | 写 | `guild`, `guild_member`, `guild_monster`, `player_daily`, `player_daily_counter` |
| `validatePaymentOrder` | 写 | `payment_order`, `charge_log`, `player` |
| `equipSpirit` | 写 | `player_spirit`, `player_spirit_attr`, `player_spirit_unsaved`, `player_extend`, `player_prop` |
| `createUnion` | 写 | `guild`, `guild_member` |
| `getUserEmails` | 读 | `mail`, `mail_attachment`, `sys_email_meta` |

---

## 7. 从 `user_state.json` 迁移

### 7.1 现有存档结构

`server/user_state.json` 现在长这样：

```json
{
  "user_created": true, "nickname": "测试主公", "uid": "100001", "account_id": "100001",
  "coins": 100000, "exp": 0, "level": 1, "energy": 100, "general_exp": 0,
  "mission_context": {...}, "scene_process": {...}, "mission_completes": [],
  "recharge_gems": 0, "gained_charge_money_reward_list": [],
  "gems": 10000, "cards": [...], "equips": [...], "props": [...], "spirits": [...],
  "bought_grid_num": 0, "bought_grid_times": 0, "main_card_id": 1,
  "additional_card_ids": "", "next_card_id": 1000, "next_equip_id": 100,
  "inventory_seeded": true, "event_point": 100
}
```

### 7.2 迁移脚本骨架

```python
import json, sqlite3, time

def migrate(json_path, db_path):
    d = json.load(open(json_path, encoding='utf-8-sig'))
    con = sqlite3.connect(db_path)
    con.executescript(open('schema.sql', encoding='utf-8').read())
    now = int(time.time())

    # 1) 账号 + 角色
    cur = con.execute(
        "INSERT INTO account(account_name, create_time, last_login_time) VALUES (NULL,?,?)",
        (now, now))
    account_id = cur.lastrowid
    cur = con.execute(
        "INSERT INTO player(account_id, server_id, nickname, create_time, level, exp,"
        " gold, gem, free_gems, energy, event_point, general_exp, main_card_id,"
        " additional_card_ids)"
        " VALUES (?,1,?,?,?,?,?,?,?,?,?,?,?,?)",
        (account_id, d.get('nickname') or '测试主公', now,
         d.get('level', 1), d.get('exp', 0), d.get('coins', 0), d.get('gems', 0),
         d.get('gems', 0), d.get('energy', 100), d.get('event_point', 100),
         d.get('general_exp', 0), d.get('main_card_id', 1),
         d.get('additional_card_ids') or ''))
    player_id = cur.lastrowid
    con.execute("INSERT INTO player_extend(player_id, bought_grid_num, bought_grid_times)"
                " VALUES (?,?,?)",
                (player_id, d.get('bought_grid_num', 0), d.get('bought_grid_times', 0)))

    # 2) 卡牌（连同 cardSkills）
    for c in d.get('cards', []):
        con.execute(
            "INSERT INTO player_card(card_id, player_id, meta_id, avatar_meta_id, level, exp,"
            " card_group_id, fight_capacity, att_train_value, def_train_value, hp_train_value,"
            " att_evolve_value, def_evolve_value, hp_evolve_value, used_potential, treasure_id,"
            " is_locked, create_time) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
            (c['cardId'], player_id, c['metaId'], c.get('avatarMetaId', 0),
             c.get('level', 1), c.get('exp', 0), c.get('cardGroupId', 0),
             c.get('fightCapacity', 0), c.get('attTrainValue', 0), c.get('defTrainValue', 0),
             c.get('hpTrainValue', 0), c.get('attEvolveValue', 0), c.get('defEvolveValue', 0),
             c.get('hpEvolveValue', 0), c.get('usedPotential', 0), c.get('treasureId', 0),
             1 if c.get('lock') else 0, now))
        for i, sk in enumerate(c.get('cardSkills') or [], 1):
            con.execute("INSERT INTO player_card_skill(card_id, slot, skill_id, skill_type,"
                        " curr_quality, country_group_id, country_group_num, card_group_ids)"
                        " VALUES (?,?,?,?,?,?,?,?)",
                        (c['cardId'], i, sk['skillId'], sk.get('skillType', 0),
                         sk.get('currQuality', 0), sk.get('countryGroupId', 0),
                         sk.get('countryGroupNum', 0),
                         ','.join(str(x) for x in (sk.get('cardGroupIds') or []))))

    # 3) 装备 / 道具 / 元神 / 宝物 ...
    #    （省略，结构一一对应，照抄即可）

    # 4) 关卡进度
    mc = d.get('mission_context') or {}
    con.execute("INSERT INTO player_mission_context(player_id, mission_id, finished_step,"
                " fight_lose, route_id) VALUES (?,?,?,?,?)",
                (player_id, mc.get('missionId', 100101), mc.get('finishedStep', 0),
                 1 if mc.get('fightLose') else 0, mc.get('routeId', 1)))
    sp = d.get('scene_process') or {}
    con.execute("INSERT INTO player_scene_process(player_id, max_finished_mission_id,"
                " last_clear_time) VALUES (?,?,?)",
                (player_id, sp.get('maxFinishedMissionId', 0), sp.get('lastClearTime', 0)))

    # 5) id 分配器接上原存档的游标
    con.execute("UPDATE id_alloc SET next_val=? WHERE name='card'", (d.get('next_card_id', 1000),))
    con.execute("UPDATE id_alloc SET next_val=? WHERE name='equip'", (d.get('next_equip_id', 100),))
    con.commit()
```

### 7.3 渐进迁移策略

**不要一次性重写。** 建议分三步：

1. **并行期**：新建 `db.py`，`State` 类保留内存态不变，但 `save()` 同时写 JSON 和 DB，启动时优先读 DB。
2. **切换期**：逐个领域切换 —— 先资产（卡牌/装备/道具，读写最频繁、收益最大），再进度，再社交/军团。
3. **收尾**：`user_state.json` 只作为备份，DB 成为唯一来源。

关键点：**组装层是唯一需要对齐客户端契约的地方**，只要它不回归，底层怎么换都行。建议在切换前先写一个**快照对比测试**：用旧 JSON 存档分别跑新旧两条路径生成 `gameInit`，逐字段 diff，必须完全一致才算通过。

---

## 8. 移植到 MySQL

DDL 用的是 SQLite 方言，差异只有 4 处：

| SQLite | MySQL |
|---|---|
| `INTEGER PRIMARY KEY AUTOINCREMENT` | `BIGINT PRIMARY KEY AUTO_INCREMENT` |
| `TEXT` | `VARCHAR(n)` / `TEXT` / `JSON` |
| `REAL` | `DOUBLE` |
| `PRAGMA foreign_keys = ON` | 建表用 `ENGINE=InnoDB`（外键默认开启） |

另外建议：
- 所有 `*_json` 列在 MySQL 里用原生 `JSON` 类型（可校验合法性），SQLite 里保持 `TEXT`。
- 时间列可以改成 `BIGINT` 保持 unix 秒（**不要**改成 `DATETIME` —— 客户端全程用秒做算术，中间多一层转换只会引入时区 bug）。
- 高并发热点（`player`、`player_daily_counter`）记得用 `SELECT ... FOR UPDATE` 或直接 `UPDATE ... SET value = value + ?` 原子自增。原服务端是靠一把 `threading.RLock`，Docker/多进程部署下不成立。

---

## 9. 代码结构（含已落地的原型）

这次不只给了 DDL，还写了**可运行的组装层原型**来证明设计成立：

```
server/
├── schema.sql              ← 本设计的 DDL（88 张表，可直接 sqlite3 执行）
├── db.py                   ← ✅ 已写：连接/事务/原子 id 分配/计数器辅助
├── assembler.py            ← ✅ 已写：表行 → 客户端契约（唯一允许出现 camelCase 的地方）
├── repository/             ← ⬜ 待写：按域拆的数据访问
│   ├── player_repo.py      ←   player / player_extend / 计数器
│   ├── asset_repo.py       ←   card / equip / prop / spirit / treasure / fragment
│   ├── progress_repo.py    ←   mission / scene / tower / elite
│   ├── mail_repo.py
│   ├── social_repo.py      ←   friend / invitation / red packet
│   ├── guild_repo.py
│   └── order_repo.py
├── daily_keys.py           ← ⬜ 待写：DAILY_KEYS 常量表
└── canon_server.py         ← 路由 + AMF3 编解码（现有）
```

`db.py` 已经处理的几件事：

| 能力 | 为什么需要 |
|---|---|
| WAL + `busy_timeout=15000` | `ThreadingHTTPServer` 多线程共用一个库，没有 WAL 会频繁 `database is locked` |
| `tx()` 真事务上下文 | 「扣道具 + 发卡」这类复合操作必须原子；原服务端靠一把 `RLock` + 全量 JSON 覆写 |
| `next_id(name)` | `UPDATE ... RETURNING` 原子取号，替代 `next_card_id` / `next_equip_id` 两个散落的游标 |
| `bump_daily()` / `bump_counter()` | `INSERT ... ON CONFLICT DO UPDATE value = value + ?`，并发安全 |
| `add_prop()` | 数量减到 ≤0 直接删行 —— 客户端 `sharkProps[]` 里的 0 或负数会让数量显示异常 |

分层规则：

- `repository` 只认数据库，**不知道客户端字段名**
- `assembler` 只认客户端契约，**不写 SQL**（只接收 repo 传进来的行）
- `canon_server` 的 handler 负责「读 repo → 喂 assembler → 编码」

这样补新接口时，改动只会落在 `repository`（加一个查询）和 `assembler`（加一个字段），不会波及协议层。

### 9.1 设计验证：冒烟测试

`work/api_analysis/smoke_assemble.py` 做的事：

1. 用 `schema.sql` 建一个临时库；
2. 灌一个最小初始角色（1 张卡 + 技能 + 1 件装备 + 1 个元神 + 属性 + 1 个宝物 + 阵容 + 阵法 + 关卡进度 + 道具）；
3. 调 `assembler.build_game_init()`；
4. 断言客户端在 `gameInit` 里实际读取的 **29 个顶层 key 全部存在**；
5. 断言 **24 条硬类型约束**（`uid` 是字符串、`additionalCardIds` 是字符串、4 个宝石字段都是数字、各列表是列表、`sharkMissionContext` 是完整对象…）。

当前结果：

```
=== 1. 顶层 key 覆盖 ===
  需要 29 个，实际 30 个，缺失 0 个  ✅
=== 2. 类型约束 ===
  ✅ 24 条类型约束全部通过
=== 3. 抽样内容 ===
  card[0]: cardId=1000 metaId=102111 equipIds=[100] cardSpirits=[1] treasureId=1 skills=1
  派生校验: equipIds/cardSpirits/treasureId 都是从 player_equip/spirit/treasure 的 card_id 反查出来的
=== 结果 ===
  ✅ 通过（4433 字节）
```

> 这个测试顺带**发现并修掉了设计里的一处冗余**：初版 schema 让 `player_battle_slot` 同时存了
> 装备/元神/宝物 id，与 `player_equip.card_id` 形成两份真相。测试里我把宝物只写在
> `player_treasure.card_id`，结果 `sharkUserQueue[].treasureId` 有值而 `sharkCards[].treasureId`
> 是 0 —— 正是客户端 `changeBattleArray` 会踩的那种不一致。现已改成**只有一份权威数据，
> 全部反查**（`player_card.treasure_id` 列也一并删掉了）。

---

## 10. 这份设计没解决的事

诚实说明边界：

1. **数值平衡完全没碰。** 掉落表、抽卡概率、成长曲线 —— 现在服务端大量用 `random` 硬编码。表结构给了 `gacha_log` / `reward_log` 做审计，但配置数据本身要另做（原厂的配置在 `work/luasrc/canon/configs/` 里，是 Lua 表，可以直接加载）。
2. **`assembler.py` 只覆盖了 `gameInit`。** 363 个接口里还有一大批响应需要各自的组装函数（邮件列表、好友列表、军团各种 wrapper、战报…）。这些的字段契约在 `struct_mail_social.md` / `struct_union.md` 里已经逐条列出，但代码还没写。
3. **`repository/` 层还没写。** `db.py` 提供了地基，但按域的数据访问函数（`asset_repo` / `guild_repo` …）是空的。
4. **`rank_board` 的刷新策略**没定义。排行榜是定时全量重算还是增量维护，取决于玩家人数 —— 私服场景（个位数在线）建议直接查询时现算，`rank_board` 先当缓存用。
5. **没有分库分表**。单 server_id 的场景下 88 张表跑在 SQLite 一个文件里绰绰有余。
6. **`data_json` 里的字段契约没有强制约束。** `player_activity` / `player_daily` 这些 JSON 列靠约定，写错了不会报错。建议配一份 `activity_keys.py` 常量表 + 每个活动一个 `build_xxx_activity()` 组装函数，把契约收口。
