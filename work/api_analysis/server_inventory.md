# 自建服务端「已实现接口与响应字段」清单

> 分析对象：`server/canon_server.py`（3074 行）、`server/features.py`（1366 行）、`server/admin_api.py`（338 行）
> 参考：`ARCHITECTURE.md`、`HANDOFF.md`
> 性质：**纯只读静态分析**（未运行服务端），行号均为当前工作区文件版本的真实行号。
> 生成时间：见文件 mtime。

---

## 0. 总览

| 维度 | 数量 | 说明 |
|---|---|---|
| HTTP 路由（path+method 组合） | **24** | 其中 GET 12 项、POST 12 项；去重后 **21 个不同 path 模式** |
| RPC 端点（`/protocol` 里可识别的 method 名） | **120** | `canon_server.py` 63 个 + `features.py` 新增 57 个 |
| 其中「有真实业务数据」的端点 | 约 84 | 其余为软 ack / 空表 |
| 其中「只返回 `{method, retCode:200}` 空壳」 | 约 36 | 见 §4 |
| TCP 客户端→服务端消息 | 1 个具名（`login`）+ 任意 method 通配 ack | |
| TCP 服务端→客户端消息 | 2 种形状，**主动推送 0 种** | |
| 监听端口 | HTTP `:80`、TCP `:9700` | `canon_server.py:3048` / `:2931` |

### 0.1 前后处理管线（理解所有响应的前提）

| 环节 | 位置 | 说明 |
|---|---|---|
| headercvt 封装 | `canon_server.py:119-122` | `00 64 ‖ MD5(C16‖X) ‖ X`，`X = payload ^ 0x71` |
| headercvt 解封 | `canon_server.py:125-` | 丢 18 字节头后 `^ 0xC3`；**MD5 不校验** |
| 双向密钥不对称 | `canon_server.py:113-116` | 请求 `0xC3`、响应 `0x71`（实测：反了会 `zlib checksum failed`） |
| AMF3 读写 | `canon_server.py:161-390` | 自研 `AMF3Reader` / `AMF3Writer` |
| 完整 /protocol 流水线 | `canon_server.py:2292-2381` | `headercvt(zlib(amf3([subHeader,[resp],[events]])))` |

请求体退化容错（`canon_server.py:2305-2318`）：headercvt 失败则当裸数据、zlib 失败则当裸 AMF3，继续往下走并打日志。

---

## 1. HTTP 路由表

### 1.1 `do_GET`（`canon_server.py:1947-2003`）

| # | 路径 | 行号 | 作用 | 返回体格式 |
|---|---|---|---|---|
| 1 | `/admin` | 1952-1954 | 管理后台上页 | **HTML**（`text/html; charset=utf-8`，读 `server/admin.html`） |
| 2 | `/admin/` | 1952-1954 | 同上 | HTML |
| 3 | `/admin/api/state` | 1955-1959 | 账号/卡牌/道具快照 | **JSON** `{ok, state}` |
| 4 | `/admin/api/catalog` | 1960-1974 | 卡牌图鉴查询（`q`/`country`/`rare`/`stage1`） | **JSON** `{ok, count, total, cards[]}` |
| 5 | `/admin/cardimg/<figureId>` | 1975-1980 | 头像图；无则 404 | **二进制 PNG**（`image/png`，`admin_api.head_bytes`） |
| 6 | `/admin/api/card_dict` | 1981-1985 | 完整卡牌字典 dump | **JSON** |
| 7 | `/staticVersion` | 1986-1987 → 2143-2166 | 资源清单版本检查 | **JSON**：`static_url_root, config_md5, need_download, can_download, download_url, langs, resolutions, ref` |
| 8 | `/static/ad/<name>` | 1988-1992 → 2196-2200 | 广告位占位图（`GachaScene:preloadAd` / 主界面广告槽） | **二进制 PNG**（64×64，`_png_bytes` 现造） |
| 9 | `/static/<file>` | 1993-1994 → 2169-2194 | 下发 APK 内真实资源清单 `assets/static_config.<md5>.xml` | **XML/二进制**（`application/xml`，直接读 APK zip 条目） |
| 10 | `/check/<platform>` | 1995-1996 → 2283-2289 | 平台账号校验（GET 分支，空 body） | **JSON** `{retCode:200, accountId, uid, token, new}` |
| 11 | `/getLoginServer` | 1997-1998 → 2272-2280 | 服务器列表 | **JSON** `{retCode:200, servers:[{serverId,serverName,status,recommend}]}` |
| 12 | `/restapi.php` | 1999-2002 | 乐元素 DC 打点，回空对象让客户端停止重试 | **JSON** `{}` |
| — | 兜底 | 2003 | 其它一切 GET | **纯文本** `not found`，404 |

> 注：`do_GET` 没有 HEAD/OPTIONS 分支，其它 HTTP 方法由 `BaseHTTPRequestHandler` 回 **501**。

### 1.2 `do_POST`（`canon_server.py:2005-2032`）

| # | 路径 | 行号 | 作用 | 返回体格式 |
|---|---|---|---|---|
| 13 | `/admin/api/state` | 2009-2010 → 2043-2045 | 改昵称/等级/金币/钻石/体力/通用经验 | **JSON** `{ok, state}` |
| 14 | `/admin/api/card/add` | 2046-2058 | 加卡（`metaIds, level, count`） | **JSON** `{ok, added[], state}` |
| 15 | `/admin/api/card/remove` | 2059-2062 | 删卡（`cardId`） | **JSON** `{ok, removed, state}` |
| 16 | `/admin/api/card/level` | 2063-2068 | 改卡等级 | **JSON** `{ok, state}` |
| 17 | `/protocol` | 2013-2014 → 2292-2381 | **主 RPC 入口** | **二进制**：`headercvt(zlib(amf3))` |
| 18 | `/systemInfo` | 2015-2016 → 2203-2248 | 系统配置 + 分服表（登录页渲染「1区 本地测试服」） | **裸 AMF3 二进制**（`application/octet-stream`，**不 zlib、不 headercvt**） |
| 19 | `/sessionKey/init` | 2017-2018 → 2251-2269 | 会话密钥 | **纯文本** `uid,uuid,sessionKey`（逗号分隔） |
| 20 | `/loginAccount/hasVisitorAccount` | 2019-2020 → 2100-2105 | 是否已有游客账号 | **JSON** `{code:1, hasVisitorAccount:1, deviceId}` |
| 21 | `/check/<platform>` | 2021-2022 → 2283-2289 | 平台账号校验 | **JSON** `{code:1, loginAccountId, sid}` |
| 22 | `/mappingAccount` | 2023-2024 → 2115-2123 | 账号绑定映射 | **JSON** `{code:1, accountId, token}` |
| 23 | `/loginAccount/*` | 2025-2026 → 2125-2128 | 登录/注册**通配**（含 `/loginAccount/login`、`/loginAccount/register`） | **JSON** `{code:1, accountId, token}` |
| 24 | `/restapi.php` | 2029-2030 | DC 打点 | **JSON** `{}` |
| — | 兜底 | 2031-2032 | 其它一切 POST：先 `_record()` 落 `rpc_payloads.jsonl`，再 404 | **纯文本** `not found`，404 |

> ⚠️ `canon_server.py:2027-2028` 的 `if path.startswith("/loginAccount/") or path == "/mappingAccount": return self.platform_check()` 是**死代码** —— 上面的 2023/2025 已把这两类全部吃掉，`platform_check()` 永远不可达（详见 §4.3）。
>
> ⚠️ 客户端 `DataManager` 里的 `ChangeAccountUrl = {domain}/account?accountId=`（见 `ARCHITECTURE.md:184`）在本服务端**没有任何实现**，会落到 404。

### 1.3 管理接口的分发实现

- GET 侧直接内联在 `do_GET`（1955-1985），POST 侧集中在 `admin_api_post`（`canon_server.py:2034-2079`），未匹配的 `/admin/api/*` 返回 `{ok:false, error:"unknown admin api"}` + 404（2070-2072）。
- 数据操作实现全部在 `admin_api.py`：`state_snapshot`(220)、`update_state`(265)、`add_cards`(284)、`remove_card`(309)、`set_card_level`(324)、`get_catalog`(187)、`head_bytes`(147)、`admin_html_bytes`(336)。

---

## 2. RPC 端点分发（`/protocol` 的 AMF3 method）

### 2.0 分发结构

**不是字典分发，而是两条 if/elif 链 + 一层兜底：**

1. `canon_server.Handler._endpoint_response()`（`canon_server.py:2383-2912`）—— 63 个具名 method 的一长串 `if method == ...` / `if method in (...)`。
2. 末尾 `canon_server.py:2910`：`if _feat.handle(method, params, base, ST, _starter_card): return base`
3. `features.handle()`（`features.py:766-1366`）—— 又一条 if 链 + 软 ack 名单 + 字符串包含式 catch-all。
4. 两条链都没命中 → `canon_server.py:2912` 直接 `return base`，即 **`{method, retCode:200}` 空壳**。

请求解析（`canon_server.py:2327-2352`）：取 `req[1]` 作 header、`req[2]` 作请求项数组，逐项抽 `it["method"]`；`createUser` 时顺便记住 `nickName` 到 `ST.pending_nickname`（2347-2348）。

响应外层固定三元素（`canon_server.py:2358-2377`）：

```
[ {errCode:0, ts, uk, st, others:{}}, [ {method, retCode:200, ...业务字段}, ... ], [] ]
```

- `subHeader.errCode` **必须 ≤ 0**（`canon_server.py:2354-2364`）。
- 第三个元素 `events` **恒为空数组**（`:2377`）→ 服务端**从不通过 RPC 通道推送事件**。

---

### 2.1 `canon_server.py::_endpoint_response` 分支（63 个 method 名）

| method | 行号 | 顶层业务字段 |
|---|---|---|
| `login` | 2387-2388 | 无（仅 `method`/`retCode`） |
| `loginServer` | 2389-2399 | `uid`（新玩家为字符串 `"1"`）、`serverId`；**故意不下发** `accountReturnRewards` |
| `getServerTimeStamp` | 2400-2402 | `ts` |
| `getServerStatus` | 2403-2405 | `serverId`, `status`, `amount` |
| `getSocketServer` | 2406-2410 | `serverAddress`, `serverPort`, `token` |
| `geneNickname` | 2411-2413 | `nickname` |
| `createUser` | 2414-2419 | `sharkUser` |
| `gameInit` | 2420-2453 | `sharkUser`, `sharkUserExtend`, `sharkUserExtendMore`, `sharkEquips`, `sharkProps` + `_game_init_extra()` 的 12 键（见 §2.3） |
| `triggerCoinEvent` | 2456-2464 | `rewards`, `encounterMultiPlayerBoss` |
| `triggerExpEvent` | 2465-2471 | `rewards`, `encounterMultiPlayerBoss` |
| `triggerEmptyEvent` | 2472-2475 | `encounterMultiPlayerBoss` |
| `triggerCardEvent` | 2476-2482 | `rewards`, `encounterMultiPlayerBoss` |
| `triggerRandomEvent` | 2483-2492 | `eventType`(固定 3), `rewards`, `encounterMultiPlayerBoss` |
| `triggerBattleEvent` | 2493-2498 | 战斗包，见 §2.4 |
| `getMissionCompleteInfo` | 2499-2501 | `missionCompletes` |
| `validatePaymentOrder` | 2502-2526 | `succ`, `productId`, `rechargeGems`, `freeGems`（本地绕过充值，直接加钻石） |
| `gainChargeMoneyReward` | 2527-2535 | `rewards`；失败时置 `retCode` 为业务错误码 |
| `recordTutorialStep` | 2536-2537 | 无 |
| `getGachaBroadcast` | 2538-2540 | `broadcasts`（空） |
| `gachaCardFree` | 2541-2574 | `rewards`, `free`, `countdownFreeGachaInfos` |
| `gachaCard` | 2541-2574 | 同上（`free=False`，`time` 参数决定连抽） |
| `gachaCardByRp` | 2541-2574 | 同上 |
| `getRewardList` | 2575-2579 | `sharkRewardList`（空） |
| `getHomeInfo` | 2580-2608 | `unionMonsterHp`, `unionMonsterEscapeSeconds`, `consumeRewardRecharges`, `consumeRewards`, `unreadMessageNum`, `rewardNum`, `invitedNum`, `enableGainDailyActiveRewardNum`, `enableGainDailyAchieveRewardNum`, `eatPeachStatus`, `cowStageStatus`, `freeSpiritRefreshNum`, `chargeRewardStatus`, `freeGachaStatus` |
| `getAnnouncementInfo` | 2609-2611 | `announcements`（空） |
| `gainContinuousLoginRewardV2` | 2612-2614 | `rewards` |
| `getUserUnionInfo` | 2615-2618 | `hasUnion: False`（**没有公会系统**） |
| `getMaintenanceMeta` | 2619-2625 | `maintenanceItem`（由 `_all_maintenance_items()`，`:1765`） |
| `challengeCowStage` | 2627-2636 | 战斗包 + `win:True`，见 §2.4 |
| `challengeMysterious` | 2627-2636 | 同上 |
| `challengeWanted` | 2627-2636 | 同上 |
| `challengeWorldBoss` | 2627-2636 | 同上 |
| `challengeMultiplayerBoss` | 2627-2636 | 同上 |
| `challengeChrist` | 2627-2636 | 同上 |
| `challengeContend` | 2627-2636 | 同上 |
| `challengeBabel` | 2627-2636 | 同上 |
| `challengeArena` | 2627-2636 | 同上（**竞技场不是真 PVP，只是打桩**） |
| `challengeCrossBoss` | 2627-2636 | 同上 |
| `challengeElite` | 2627-2636 | 同上（**遮蔽了 `features.py:1291` 的同名软 ack**） |
| `challengePkUser` | 2627-2636 | 同上 |
| `challengeUnionMonster` | 2627-2636 | 同上 |
| `getCowStageInfo` | 2637-2640 | `cowStageInfos`（空） |
| `getWantedInfo` | 2641-2643 | `wantedInfos`, `wantedTasks`, `refreshTimes` |
| `getWorldBossInfo` | 2644-2653 | `worldBossHp`, `worldBossMaxHp`, `inspireTimes`, `damage`, `rank`, `autoChallenge`, `rewards` |
| `getEatPeachInfo` | 2654-2655 | `eatPeachInfos`, `eatPeachStatus` |
| `getBabelInfo` | 2656-2657 | `babelInfo:{floor,maxFloor}`（**遮蔽 `features.py:1311`**） |
| `eatPeach` | 2659-2667 | `rewards`, `succ` |
| `inspireInWorldBoss` | 2659-2667 | `rewards`, `succ` |
| `gainWorldBossRewards` | 2659-2667 | `rewards`, `succ` |
| `setAutoWorldBoss` | 2659-2667 | `rewards`, `succ` |
| `refreshWanted` | 2659-2667 | `rewards`, `succ` |
| `exchangeItem` | 2659-2667 | `rewards`, `succ` |
| `exchangeMysteriousItem` | 2659-2667 | `rewards`, `succ` |
| `RefreshSecretShop` | 2659-2667 | **秘密商店分支**：`freeTimes`, `itemIdList`, `version`, `lastRefreshSecond` |
| `refreshSecretShop` | 2659-2667 | 同 `RefreshSecretShop` |
| `getSecretShopList` | 2668-2671 | `freeTimes`, `itemIdList`, `version`, `lastRefreshSecond`, `secretShopItems`（**遮蔽 `features.py:1299`**） |
| `getMonthlyLoginRewardMeta` | 2672-2678 | `adNum`（**故意省略** `monthlyLoginRewardItems`） |
| `getSignInReward` | 2679-2688 | `rewards`（并直接给 1000 金币） |
| `getLoginReward` | 2679-2688 | 同 `getSignInReward` |
| `getEnchantStepReward` | 2689-2697 | `rewards`（固定发一件附魔装备 stub） |
| `getAchievements` | 2698-2700 | `sharkAchievement`（空） |
| `getUserBanInfo` | 2701-2704 | `noChatEndSeconds: 0` |
| `getMeta` | 2705-2908 | **45 个 config 键**，见 §2.2。注意此分支**不走 `base`**，直接 return 一个自带 `method`/`retCode` 的字面量 dict |

### 2.2 `getMeta` 返回的顶层字段（45 个，`canon_server.py:2725-2908`）

`cardPictureConfig`, `adPictureConfig`, `adMainUiConfig`, `skyTowerSettingConfig`,
`spiritSettingConfig`, `activityEventChristmasConfig`, `activityGachaXiaoyuConfig`,
`activityCowStageConfig`, `activityFountainWishConfig`, `activityWorldBossConfig`,
`activityWantedConfig`, `activityGoldGodConfig`, `activityTreasureboxPointsConfig`,
`activitySwornBrothersConfig`, `activitySeckillConfig`, `activityDiceConfig`,
`activityPraiseConfig`, `activityMultiplayerBossConfig`, `activityNewYearConfig`,
`activityBalloonConfig`, `activityFortuneNowConfig`, `activityContendConfig`,
`activityLevelRaceConfig`, `activityGemConsumeConfig`, `activityDayRewardConfig`,
`activityConsumeRewardConfig`, `multiplicityRewardConfig`, `exchangeDailyConfig`,
`activityCardExchangeConfig`, `prayConfig`, `fbShareConfig`, `activitySettingConfig`,
`eventMysteriousConfig`, `activityMysteriousExchangeConfig`, `activityLimitRewardConfig`,
`countdownRewardConfig`, `crossArenaRewardConfig`, `destinyBattleConfig`,
`spiritConcentrateCostConfig`, `enchantTotalConfig`, `gameSettingConfig`,
`battleSettingConfig`, `paymentExchangeConfig`, `serverPartitionConfig`, `metaVersion`

辅助构造函数：`_game_setting_config()`(`:1633`)、`_battle_setting_config()`(`:1725`)、`_payment_exchanges()`(`:1305`)、`_act()` 内联闭包(`:2718`)。

> `paymentExchangeConfig.paymentExchanges` 的 **6 档**充值包来自 `_payment_exchanges()`（`:1305-1333`：`he_gold_60/300/980/1980/3280/6480`）；`activityGoldGodConfig`, `activityFountainWishConfig` 等大量活动只是**开了开关的空壳**。

### 2.3 `gameInit` 的额外顶层字段（`_game_init_extra()`，`canon_server.py:1508-1610`）

`sharkCards`, `sharkUserBattleArray`(3 个 slot), `sharkSpirits`, `sharkTreasures`,
`sharkMissionContext`, `sharkSceneProcess`, `missionCompletes`, `sharkDailyDataExtend`,
`sharkUserSecretShop`, `sharkDailyData`, `sharkActivity`, `crossBossActivityStatus`

`sharkUser` 字段：`uid`(字符串), `serverId`, `nickname`, `nickName`, `level`, `exp`, `gold`, `gem`,
`vipLevel`, `vipExp`, `rechargeGems`, `freeGems`, `usedFreeGems`, `usedRechargeGems`,
`energy`, `actionPower`, `silver`, `createTime`，`full=True` 时再加
`fightCapacity`, `leadership`, `lastLoginTime`, `guideStep`, `mainCardId`,
`additionalCardIds`(字符串), `newGuideStep`, `energyLastUpdateTime`, `eventPoint`,
`eventPointLastUpdateTime`, `coins`（`_shark_user()`，`:1423-1490`）。

`sharkUserExtend`（`_shark_user_extend()`，`:1848-1903`）28 个字段：
`fightCapacity`, `tutorialSteps`, `cardGroupInterworking`, `countdownFreeGachaInfos`,
`gainedChargeMoneyRewardList`, `lifeLimitGoods`, `lstEatPeachInfo`, `paidChannelNames`,
`vipPackages`, `continuousLoginInfo`, `continuousLoginRewardInfoV2`, `countdownRewardInfo`,
`doubleChargeInfo`, `exchangeGiftBagInfo`, `signInInfo`, `treasureInfo`, `astralEssence`,
`battleArrayId`, `boughtGridNum`, `boughtGridTimes`, `boughtSpiritPoolNum`, `friendPoint`,
`generalExp`, `lastRenameTimes`, `medalNum`, `renameCd`, `seniorGachaTenTimes`,
`enchantStepReward`。

### 2.4 战斗响应包（`_build_battle_response()`，`canon_server.py:1011-1116`；`_activity_battle()` `:1828-1845`）

顶层字段（11 个）：`win`, `leftHpRate`, `rewards`, `cardInitDatas`, `eventFlow`,
`qte`, `encounterMultiPlayerBoss`, `damage`, `showQuery`, `qteRewards`, `vipRewards`

- 敌方数据来自 `battle_monster` 表；`eventFlow` 只放**一条 ACTION_SELF 满伤事件**，让战斗立刻演出胜利（`:1080-1092`）。
- 活动入口 `challenge*` 复用同一构造器，额外强制 `win=True`（`:1839`）。

### 2.5 `features.py::handle` 分支（61 个 method 名，新增 57 个）

| method | 行号 | 顶层字段 |
|---|---|---|
| `getProps` | 773-775 | `sharkProps` |
| `getEquips` | 777-779 | `sharkEquips` |
| `sellProps` | 781-797 | `rewards` |
| `sellEquips` | 799-817 | `rewards` |
| `sellCards` | 819-843 | `rewards`（主卡与上阵卡受保护） |
| `useProp` | 845-888 | `rewards`；道具不足 `retCode=712301` |
| `buyGrid` | 890-907 | `rewards`, `requisite`；钻石不足 `710513`，次数满 `713301` |
| `setupEquip` | 909-927 | 无（仅 `method`/`retCode`） |
| `adjustTeam` | 929-935 | `mainCardId`, `additionalCardIds` |
| `replaceCard` | 929-935 | 同上 |
| `getUserEmails` | 937-945 | `sysEmails`, `rewardEmails`, `sysNotices`, `userEmails`, `sysEmailMeta` |
| `getFriends` | 947-949 | `sharkFriends`（空） |
| `getSharkBeasts` | 951-953 | `sharkBeasts`（空） |
| `getSharkBeastFragments` | 955-957 | `sharkBeastFragments`（空） |
| `buyGoods` | 959-1003 | `reward`；货币不足 `710513` |
| `clearMission` | 1005-1031 | `clearMissionRewards`（扫荡，随机掉落） |
| `upgradeEquip` | 1034-1050 | `sharkEquip`；`712501`/`712509`/`710512` |
| `quickUpgradeEquip` | 1052-1082 | `sharkEquip`（按金币自动推到上限） |
| `upgradeEquipForOneCard` | 1084-1101 | `sharkEquips`（数组） |
| `evolveEquip` | 1103-1116 | `sharkEquip`；`712501`/`712510` |
| `equipEnchant` | 1118-1128 | `sharkEquip` |
| `enchantEquip` | 1118-1128 | `sharkEquip` |
| `upgradeCard` | 1131-1180 | `sharkCard`；`712401`（卡不存在） |
| `upgradeCardByGeneralExp` | 1182-1206 | `sharkCard` |
| `evolveCard` | 1208-1242 | `sharkCard`（无后续进化则原样返回） |
| `trainCard` | 1244-1249 | `attTrainValue`, `defTrainValue`, `hpTrainValue` |
| `saveCardTrain` | 1251-1267 | `sharkCard`；`712401` |
| `giveUpCardTrain` | 1251-1267 | `sharkCard`；`712401` |
| `splitCard` | 1269-1277 | `rewards` |
| `synthetizeCard` | 1278-1281 | `rewards` |
| `cardOn` | 1269-1282 | 无（落在同一分支但无 payload） |
| `getEliteInfo` | 1297-1298 | `eliteInfos`（空） |
| `getSecretShopList` | 1299-1305 | `secretShopItems`, `freeTimes`, `itemIdList`, `version`, `lastRefreshSecond` —— **实际不可达**（被 `canon_server.py:2668` 遮蔽） |
| `getPlayerTeamInfo` | 1306-1310 | `sharkCards`, `sharkEquips`, `sharkTreasures`, `sharkUserBattleArray` |
| `getBabelInfo` | 1311-1312 | `babelInfo` —— **实际不可达**（被 `:2656` 遮蔽） |
| `getCardBook` | 1313-1318 | `sharkCardBook`, `cardBookAchievement` |
| `getCardFragments` | 1319-1322 | `fragments`, `sharkCardFragments`, `sharkEquipFragments` |
| `getEquipFragments` | 1319-1322 | 同上 |
| `upgradeTreasure` | 1323-1331 | `sharkTreasure`（仅当带 `treasureId` 参数） |
| `evolveTreasure` | 1323-1331 | 同上 |
| **软 ack，无 payload（21 个）** | 1285-1332 | `deleteUserEmails`, `deleteSysEmails`, `deleteSysNotices`, `readSysEmail`, `readSysNotice`, `readUserEmail`, `EmailReadRewardEmail`, `readRewardEmail`, `batchDeleteEmails`, `sendUserEmail`, `equipSpirit`, `unequipSpirit`, `upgradeSpirit`, `sellSpirit`, `spiritConcentrate`, `buySpiritPool`, `challengeElite`(不可达), `exchangeSecretShop`, `getAnnouncementInfo`(不可达), `lockCard`, `lockTreasure` —— 只回 `retCode:200` |
| **字符串包含式 catch-all** | 1336-1364 | method 小写含 `equip` 且含 `upgrade/evolve/enchant/setup/quick` → 按 `equipId(s)` 回 `sharkEquip`/`sharkEquips`；含 `card` 且含 `upgrade/evolve/train/save/compose` → 回 `sharkCard`；都不中 → `return False` |

### 2.6 端点命名分组速查

- **账号/会话（9）**：`login` `loginServer` `createUser` `geneNickname` `getSocketServer` `getServerTimeStamp` `getServerStatus` `getUserBanInfo` `recordTutorialStep`
- **元数据（3）**：`getMeta` `getMaintenanceMeta` `getMonthlyLoginRewardMeta`
- **背包/装备（15）**：`getProps` `getEquips` `useProp` `sellProps` `sellEquips` `buyGrid` `buyGoods` `setupEquip` `upgradeEquip` `quickUpgradeEquip` `upgradeEquipForOneCard` `evolveEquip` `equipEnchant` `enchantEquip` `getEquipFragments`
- **卡牌（15）**：`getCards`（无，走 `gameInit`）`upgradeCard` `upgradeCardByGeneralExp` `evolveCard` `trainCard` `saveCardTrain` `giveUpCardTrain` `splitCard` `synthetizeCard` `sellCards` `cardOn` `lockCard` `getCardBook` `getCardFragments` `getPlayerTeamInfo`
- **关卡/战斗（10）**：`triggerCoinEvent` `triggerExpEvent` `triggerEmptyEvent` `triggerCardEvent` `triggerRandomEvent` `triggerBattleEvent` `getMissionCompleteInfo` `clearMission` `challengeElite` `getEliteInfo`
- **抽卡（3）**：`gachaCard` `gachaCardFree` `gachaCardByRp`（+ `getGachaBroadcast`）
- **活动/玩法桩（30+）**：13 个 `challenge*`、`getWorldBossInfo`/`getWantedInfo`/`getCowStageInfo`/`getEatPeachInfo`/`getBabelInfo`、`eatPeach`、`inspireInWorldBoss`、`gainWorldBossRewards`、`setAutoWorldBoss`、`refreshWanted`、`exchangeItem`、`exchangeMysteriousItem`、`getSecretShopList`、`RefreshSecretShop`、`refreshSecretShop`、`exchangeSecretShop`、`getSignInReward`、`getLoginReward`、`getEnchantStepReward`、`getAchievements`、`gainContinuousLoginRewardV2`、`getAnnouncementInfo`
- **邮件/社交/灵兽/公会（10）**：`getUserEmails` + 9 个邮件软 ack、`getFriends`、`getSharkBeasts`、`getSharkBeastFragments`、`getUserUnionInfo`、`getHomeInfo`
- **付费（2）**：`validatePaymentOrder`、`gainChargeMoneyReward`

---

## 3. TCP 实时通道（`:9700`）

实现位置：`canon_server.py:2915-3012`。启动 `start_realtime()`（`:3003-3012`），由 `main()` 在 HTTP 起来后调用（`:3057`）。端口可用环境变量 `CANON_REALTIME_PORT` 覆盖（`:2931`，默认 `9700`）。

### 3.1 帧格式（`canon_server.py:2925-2947`）

```
帧 = uint32BE 长度 (= 尾部 10 字节头 + AMF3 载荷长度) ‖ 10 字节 0x00 ‖ AMF3 载荷
```

- `frame_encode()` `:2935-2936`；`frame_decode()` `:2939-2947`（不足 14 字节或长度不完整时返回 `(None, 0)` 等下一批）。
- `FRAME_HDR_TAIL = 10`（`:2932`）。
- AMF3 用 **object 标记（0x0A + dynamic traits）** 编码，不是关联数组 —— 见 `AMF3Writer.w_object()` `:361-`（`HANDOFF.md:169-183` 有逐字节实证）。

### 3.2 连接处理（`RealtimeHandler.handle`，`canon_server.py:2950-2995`）

| 环节 | 行号 | 行为 |
|---|---|---|
| 连接建立 | 2953 | 记日志 `[tcp] connection from <peer>` |
| 超时 | 2954, 2960-2962 | 600 秒 idle timeout 后断开 |
| 收包/拆帧 | 2959-2970 | `recv(4096)` 累积进 `bytearray`，循环拆帧 |
| 解码 | 2972-2975 | AMF3 解码失败只打日志并 `continue`，**不断连** |
| 分发 | 2977-2991 | `msg["method"]` == `"login"` → 回 login ack；其它任意 method → 回同名通用 ack |

### 3.3 消息类型 / 方法名

| 方向 | method | 载荷 | 行号 |
|---|---|---|---|
| C→S | `login` | `{serverAddress, serverPort, token, uid, method:"login"}`（客户端 `TCPManager.lua` 在 `EVENT_CONNECTED` 时发） | — |
| S→C | `login` | `{"method":"login","retCode":0}` | 2981-2984 |
| S→C | `<任意 method>` | `{"method":<m>,"retCode":0}`（通配 ack，`m` 原样回显） | 2985-2991 |

- **服务端主动推送的消息类型：0 种。** 没有任何广播/战斗帧/事件推送代码；`/protocol` 响应里的 `events` 也是恒空数组（`:2377`）。所有实时性内容都靠客户端轮询 RPC 或本地演出。
- 除 `login` 外没有第二个真正的业务 method 被识别 —— 其它一律「原样回显 + retCode 0」。
- 强烈约束：`login` 的 `retCode` **必须为 0**，否则客户端 `TCPManager:dataReceived` 会判失败并每 11 秒重连（`:2918-2923` 注释 + `HANDOFF.md:182-183`）。

---

## 4. 未实现 / 兜底逻辑

### 4.1 RPC 终极兜底：空壳 `retCode 200`

```python
# canon_server.py:2909-2912
if _feat.handle(method, params, base, ST, _starter_card):
    return base
return base          # ← 只剩 {"method": <name>, "retCode": 200}
```

命中这一条的请求全部是**静默成功但无数据**。`ARCHITECTURE.md` 说原厂有 **386 个具名 RPC 端点**，本服务端只覆盖 120 个 —— **约 266 个端点会落到这个空壳**（客户端是否崩溃取决于它有没有 nil 守卫）。

### 4.2 HTTP 兜底

| 位置 | 行为 |
|---|---|
| `canon_server.py:2003` | GET 未匹配 → `404 / "not found"`（纯文本） |
| `canon_server.py:2031-2032` | POST 未匹配 → 先 `_record()` 落盘 `rpc_payloads.jsonl`，再 `404 / "not found"` |
| `canon_server.py:2299-2301` | `/protocol` **空 body** → 回 `headercvt(zlib(b""))`，即一个解出来是空字节的响应（无 AMF3 内容） |
| `canon_server.py:2305-2318` | headercvt/zlib 解析失败 → 不报错，**降级当裸数据继续解析**（宽松容错，也让错误请求变成空壳响应） |
| `canon_server.py:2070-2072` | 未知 `/admin/api/*` → `404 {ok:false, error:"unknown admin api"}` |

### 4.3 死代码 / 不可达分支（值得注意）

| 位置 | 问题 |
|---|---|
| `canon_server.py:2027-2028` | `platform_check()` 分支永远不可达（`:2023`/`:2025` 已吃掉全部条件）→ `platform_check()`（`:2283-2289`）**整体是死函数** |
| `canon_server.py:2284` | `platform_check` 里算出的 `body`（query string）**从未被使用** |
| `features.py:1291` | `challengeElite` 软 ack 被 `canon_server.py:2627` 遮蔽 |
| `features.py:1299-1305` | `getSecretShopList` 软 ack 被 `canon_server.py:2668` 遮蔽 |
| `features.py:1311-1312` | `getBabelInfo` 被 `canon_server.py:2656` 遮蔽 |
| `features.py:1293` | `getAnnouncementInfo` 被 `canon_server.py:2609` 遮蔽 |
| `canon_server.py:2025-2026` | `/loginAccount/*` 通配使 `register` 与 `login` 返回**完全相同**的响应 → **没有真正的注册逻辑** |

### 4.4 关键子系统缺失

| 缺失项 | 证据 |
|---|---|
| **公会系统** | 只有 `getUserUnionInfo → {hasUnion: False}`（`:2615`）；`createUnion` / `getUnionInfo` / `applyUnion` / `challengeUnionMonster` 的真实逻辑不存在 |
| **真 PVP / 跨服** | `challengeArena` / `challengePkUser` / `challengeCrossBoss` 全走同一「打桩秒赢」路径（`:2627-2636`） |
| **聊天 / 好友互动** | `getFriends → []`（`features.py:947`）；`privateChat` / `sendInvitation` / `sendFreeGift` 无分支 → 空壳 |
| **真实抽卡保底 / 池内容** | `_init_gacha()`（`:1148`）扩池到「所有一星同名稀有度卡」，仅权重取官方值（`:1136-1140` 注释自承与官方不同） |
| **真实经济/掉落表** | `clearMission`(1005)、`useProp`(845)、`sellEquips`(809) 等大量用 `random` 硬编码区间；未读 Lua 掉落表（对比：`_init_battle_meta()` `:907` 是读 Lua 的） |
| **真实充值** | `validatePaymentOrder`（`:2502`）注释即写 "Local / bypassed IAP"，直接从 productId 正则抠数字发钻石 |
| **依赖外部文件的表** | `_load_prop_meta()`(`features.py:46`) / `_load_shop_meta()`(`:72`) 靠正则扫 `work/luasrc/canon/configs/prop_meta.*` / `shop_meta.*`；**目录不存在时静默返回空表**，`buyGoods` 走 `features.py:963-966` 的兜底「随便给个经验球」 |
| **`/account?accountId=`**（ChangeAccountUrl） | 无任何实现 → 404 |
| **`/loginAccount/register` 语义** | 落到 `login_account()`（`:2125-2128`），等同登录 |
| **管理后台鉴权** | `/admin/*` 全裸奔，无 token/密码（`canon_server.py:1952-1985`） |
| **跨机器部署** | `getSocketServer` 硬编码 `serverAddress = "10.0.2.2"`（`:2408`）—— 只对「模拟器 → 宿主」场景成立 |

---

## 5. 代码注释里提到的坑（已踩/已修）

按主题归类，全部来自源码注释，行号可复查。

### 5.1 协议层

| # | 坑 | 位置 |
|---|---|---|
| 1 | **headercvt 双向异或密钥不同**（请求 `0xC3` / 响应 `0x71`）。用 0xC3 编码响应客户端报 `zlib checksum failed`；客户端解码**不校验 MD5**但仍按规范填 | `canon_server.py:93-116` |
| 2 | `subHeader.errCode` 只要 `> 0` 就被客户端当错误（`code = code and code > 0 and code or nil`），成功必须 `0` | `:2354-2364` |
| 3 | 响应第 3 个元素 `events` 恒空（`:2377`）—— 本服务端没有推送事件 | `:2377` |
| 4 | `/staticVersion` 的 `config_md5` **必须等于客户端 APK 里 `static_config.<md5>.xml` 文件名中的 md5**，否则客户端走 `dynamicUpdate` 报 `dynamicUpdateNetError` | `:2148-2153`、`:36-69`、`HANDOFF.md:136-146` |
| 5 | `/static/<manifest>` 旧实现拿请求名去比对 **APK 文件名**（`zjt_pack_signed.apk`），永远不匹配 → 一直 404；现改为从 APK zip 里读真实条目 | `:2169-2194`、`HANDOFF.md:148-158` |

### 5.2 客户端/引擎侧（服务端被逼着适配的）

| # | 坑 | 位置 |
|---|---|---|
| 6 | **`uid` 必须是字符串**：`CanonEnvInjector:setGspGameUserId(java.lang.String)V`，luajava 不会把 Lua number 转 Java String，传数字 → `Invalid method call. No such method.` → 引擎 SIGKILL | `:1426-1435` |
| 7 | **空表陷阱**：客户端写法是 `x = data.f; if not x then <自建默认值> end`，而 Lua **空表为真** → 下发 `{}` 会顶掉客户端默认值并在下一行 nil 运算崩。所以 `sharkMissionContext` 之类的字段要么给全，要么**整个 key 省略** | `:1516-1526`、`HANDOFF.md:249` |
| 8 | `gameInit` 里客户端有个 `while` 循环索引 `MetaManager.vip_setting[vipLevel+1].requireGold`，服务端直接下发 `vipLevel = VIP_MAX_LEVEL` 让 `isCurVipMaxLevel` 短路 | `:2422-2426`、`:1445-1447` |
| 9 | `accountReturnRewards` **故意不下发**：空 `{}` 为真 → `OldUserComeBackPanel:shouldPop` 弹空「主公归来」面板挡住闯关 | `:2392-2394` |
| 10 | `getMeta` 里 `adPictureConfig.adPictures` 的每个 id 都会被 `GachaScene.preloadAd` **无 nil 检查**地解引用 → 列出的 id 必须全部存在 | `:2710-2715` |
| 11 | `gameSettingConfig` / `battleSettingConfig` **只来自服务端**，客户端无本地兜底；缺字段 = `setString(nil)` | `:1633-1645` |
| 12 | `spiritSettingConfig` 空 `{}` → `SpiritManager.isUserLevelEnough` 无 nil 守卫 → 主界面滚到灵兽背包即 SIGKILL | `:2738-2740` |
| 13 | `activityFortuneNowConfig.fortuneFreeTime`、`activityLimitRewardConfig.limitRewards[].rewardDetail`、`countdownRewardConfig.rewards`、`enchantTotalConfig` 缺失均会 SIGKILL | `:2794-2802`、`:2849-2863`、`:2864-2875`、`:2879-2892` |
| 14 | `eventMysteriousConfig.eventLimit` 即使所有节点关闭也会被读 → 必须给 | `:2838-2844` |
| 15 | `getHomeInfo.unionMonsterEscapeSeconds` 必须是数字（nil → `UnionManager.setColosseumMonsterRunTime` SIGKILL） | `:2581-2582` |
| 16 | `getMonthlyLoginRewardMeta` **故意省略** `monthlyLoginRewardItems`，让客户端设 `signInActionFinish=true` 跳过签到网格动画（缺 `signInIcon.png` 会在领取时 SIGKILL） | `:2672-2677` |
| 17 | `sharkUserExtend` 被 `canonUtils.lua:603` 的 `pairs(data.sharkUserExtend.tutorialSteps)` 无守卫解引用 | `:1848-1863` |
| 18 | **新手引导协程内的 Lua 错误被完全静默吞掉**（`NewUserGuideCoroutine.lua` 自述「cocoutine中发生错误会直接终止coroutine, 不会输出到控制台」）→ 表现为「纯黑屏、进程存活、0% CPU、仍 30fps 渲染」，极难排查。`MainMenuScene:onInit` 就是从该协程进的 | `:1638-1645`、`HANDOFF.md:160-167` |
| 19 | 引擎对任何**未捕获**的 Lua 错误直接 `SIGKILL` 自己 → 源码注释里到处是「SIGKILL」标记（`P2` 之后继续推端点时的主要风险） | 全局；见 §5 表内多条 |

### 5.3 运维/并发

| # | 坑 | 位置 |
|---|---|---|
| 20 | TCP `login` 的 `retCode` 必须为 0，否则 11 秒 `SOCKET_TCP_CONNECT_FAILURE` 重连循环、主界面永不渲染 | `:2918-2923`、`:2979-2984` |
| 21 | **单例保护**：`canon_server.pid` 存在且进程存活时启动第二份直接 `SystemExit(1)` —— 双进程会竞争 `user_state.json`，在下次 `save()` 时**抹掉抽卡出的卡** | `:3018-3043` |
| 22 | 重新打包 APK 后**必须重启服务端**（manifest md5 是启动时扫描 `work/*.apk` 最新 mtime 得到的） | `:41-69`、`HANDOFF.md:210-212` |
| 23 | 抽卡持久化必须在 `ST._lock` 内完成，否则并发 `ThreadingHTTPServer` 请求（或第二进程）会覆盖新卡 | `:2544-2546` |
| 24 | 端口绑定失败给出明确 ABORT 提示（`:3049-3051` `:80`、`:3006-3008` `:9700` 只 warn 不退出） | `:3045-3057` |

### 5.4 本仓库里显式的 TODO / 待办

- 源码中**没有** `TODO` / `FIXME` / `XXX` 字面量（grep 全 `server/*.py` 无命中）。真正的待办写在文档里：
  - `HANDOFF.md:497-499`（P2）：「主界面之后的战斗 / 背包 / 公会等仍需要服务端补数据（**386 个端点目前只实现了一小部分**）」。
  - `HANDOFF.md:263-352`：当前唯一阻塞点其实是**客户端渲染层**（`useArtLabelTTF` / `CanonMessageBox` require 失败 / GLThread SIGSEGV），**不在服务端**。
  - `canon_server.py:20-21`（模块 docstring）：「Everything unknown is logged verbatim (hex + ascii) so the remaining pieces can be closed iteratively.」—— 未识别请求会写进 `server/rpc_payloads.jsonl`（`RPC_LOG`，`:34`），这是继续补端点的抓手。
- 迁移/环境隐患：`admin_api.py:20` 把字体硬编码为 `C:\Windows\Fonts\msyh.ttc`、`:14-17` 依赖 `work/decoded/assets/resource/card/{head,card}`；`PIL` 缺失或目录不存在时 `/admin/cardimg/*` 会抛异常。

---

## 6. 统计摘要

- **HTTP 路由 24 条**（GET 12 / POST 12；去重 21 个 path 模式），其中管理后台 9 条、协议/资源 11 条、登录链路 5 条；`/account` 等 1 个客户端会调的地址完全没实现。
- **RPC 端点 120 个具名 method**（`canon_server.py` 63 + `features.py` 新增 57，另有 4 个 `features` 分支被遮蔽成死代码）；对照原厂 **386 个**，覆盖率约 **31%**，其余约 266 个会落进 `canon_server.py:2912` 的 `{method, retCode:200}` 空壳兜底。
- **TCP 消息：客户端→服务端仅 1 个具名 `login`（其余任意 method 走通配 ack），服务端→客户端 2 种形状（login ack / 同名 ack），主动推送 0 种**；`/protocol` 的 `events` 恒为空数组。
- **最大的三个缺口**：① 公会、真 PVP/跨服、聊天/好友、邮件正文等社交与经济子系统整体缺失（只回空表或 `hasUnion:False`）；② 除 `battle_monster`/`prop_meta`/`shop_meta` 等少数表外，掉落与产出大量使用 `random` 硬编码，抽卡池被扩到全一星卡，与原版数值不一致；③ 无鉴权的 `/admin/*`、硬编码的 `10.0.2.2`、单文件 `user_state.json` 单例写，决定了它只能在本机模拟器场景下跑。
