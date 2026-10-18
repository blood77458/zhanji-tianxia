# 军团（Union）与跨服军团战（CrossGvg / CrossUnionPk）客户端数据结构

> 只读分析结论。全部字段来自**客户端 Lua 源码实际读取路径**，不来自猜测。
> 分析对象：`work/apk_luasrc/`（已解密；文件名带 md5 后缀）。
> 接口清单基线：`work/api_analysis/records.json`（363 接口）筛出军团相关 **69 个 endpoint**。

---

## 0. 读法约定

### 0.1 证据格式

每条字段都给出 `文件:行号`。为可读性，正文使用**短文件名**（去掉 md5 后缀）。
完整映射见 §0.2。所有路径相对于 `work/apk_luasrc/`。

### 0.2 短名 → 实际文件对照（本文引用的全部文件）

| 短名 | 实际文件 |
|---|---|
| `canon/manager/UnionManager.lua` | `canon/manager/UnionManager.00af801a5fe3272a444d00ea4ce1bd02.lua` |
| `canon/request/UnionGetMyDataRequest.lua` | `canon/request/UnionGetMyDataRequest.db58088950f37fee6b3ca3f13f1b45ec.lua` |
| `canon/request/UnionGetUnionInfoRequest.lua` | `canon/request/UnionGetUnionInfoRequest.d2018b7958e51979f3ce9f0468955800.lua` |
| `canon/request/UnionCreateRequest.lua` | `canon/request/UnionCreateRequest.02b0159b3338bfcb18d64029d6b2f011.lua` |
| `canon/request/UnionDissolveRequest.lua` | `canon/request/UnionDissolveRequest.c562fbcea721751ccc672bd55676c432.lua` |
| `canon/request/UnionQuitRequest.lua` | `canon/request/UnionQuitRequest.20ca32240f369b47231ecda8b5556a32.lua` |
| `canon/request/UnionTransferRequest.lua` | `canon/request/UnionTransferRequest.f48328f84a891c6ea8480c2ea11bdd09.lua` |
| `canon/request/UnionImpeachRequest.lua` | `canon/request/UnionImpeachRequest.3a91642974aae0506398791ec53bad7c.lua` |
| `canon/request/UnionGetMemberListRequest.lua` | `canon/request/UnionGetMemberListRequest.603f4d167e6c2c3557bb1cdb0a71719f.lua` |
| `canon/request/UnionGetApplierListRequest.lua` | `canon/request/UnionGetApplierListRequest.ff8256be66be3ab1d579593d699be560.lua` |
| `canon/request/UnionGetNewsRequest.lua` | `canon/request/UnionGetNewsRequest.0e2518a000598ec6d27ff44b333fe22f.lua` |
| `canon/request/UnionGetMyApplyListRequest.lua` | `canon/request/UnionGetMyApplyListRequest.db7cf5b833a9c6226077022daa85b164.lua` |
| `canon/request/UnionGetUnionListRequest.lua` | `canon/request/UnionGetUnionListRequest.a2c0c61648162e5ad7bf8c1f6de67b1e.lua` |
| `canon/request/UnionBuildingUpgradeRequest.lua` | `canon/request/UnionBuildingUpgradeRequest.2acf797b0c2276fa80c038acbb11b343.lua` |
| `canon/request/GetUnionBuildingShopInfoRequest.lua` | `canon/request/GetUnionBuildingShopInfoRequest.9ec07c7ff1489278cb33fa700791b6aa.lua` |
| `canon/request/GetUnionBuildingHallInfoRequest.lua` | `canon/request/GetUnionBuildingHallInfoRequest.e65813af40d2ddfb92a8451961cbdd58.lua` |
| `canon/request/GetUnionBuildingBankInfoRequest.lua` | `canon/request/GetUnionBuildingBankInfoRequest.92fda6ade5304a9f998cc206e69c5de7.lua` |
| `canon/request/UnionColosseumBuildingInfoRequest.lua` | `canon/request/UnionColosseumBuildingInfoRequest.e00552b1335dd8571abeebb3504222df.lua` |
| `canon/request/UnionColosseumSummonRequest.lua` | `canon/request/UnionColosseumSummonRequest.376bde68a58eae45a13573b9878bfb5c.lua` |
| `canon/request/UnionColosseumChallengeRequest.lua` | `canon/request/UnionColosseumChallengeRequest.ce9e0acf8a7ceccd5403adf73ac0768f.lua` |
| `canon/request/UnionColosseumGetRankRequest.lua` | `canon/request/UnionColosseumGetRankRequest.a7691f7095246a435ce02b608f21423a.lua` |
| `canon/request/UnionColosseumStartAllocationRequest.lua` | `canon/request/UnionColosseumStartAllocationRequest.f9c320a6a7a0b33ec91c91e7ab6cdc8d.lua` |
| `canon/request/UnionColosseumAllocateRequest.lua` | `canon/request/UnionColosseumAllocateRequest.6f4c3160a325464e671d1422c8d9f796.lua` |
| `canon/request/BuyUnionPropRequest.lua` | `canon/request/BuyUnionPropRequest.3e44cf8eb95b7d21b013eba2340892b9.lua` |
| `canon/request/ReceiveUnionWageRequest.lua` | `canon/request/ReceiveUnionWageRequest.123a0b04ce36b6bfaf15b033b04458ef.lua` |
| `canon/panel/UnionListPanel.lua` | `canon/panel/UnionListPanel.fe41ccb0a5d901c7cdbb40272fd440ec.lua` |
| `canon/panel/UnionMemberListPanel.lua` | `canon/panel/UnionMemberListPanel.10242232c2c3b559c33fc3cada107c0f.lua` |
| `canon/panel/UnionApplierListPanel.lua` | `canon/panel/UnionApplierListPanel.ca9ac36c64b5e3900aa433f80276652d.lua` |
| `canon/panel/UnionNewsListPanel.lua` | `canon/panel/UnionNewsListPanel.d08ee693a58d348d6189190ba41bc004.lua` |
| `canon/panel/UnionShopSpecialPanel.lua` | `canon/panel/UnionShopSpecialPanel.403eb39a2c96b03fcdcb95385fa6bce2.lua` |
| `canon/panel/UnionColosseumBossInfoPanel.lua` | `canon/panel/UnionColosseumBossInfoPanel.48f6fc1b11c6bc09aef9bf768025cf77.lua` |
| `canon/panel/UnionColosseumRankPopPanel.lua` | `canon/panel/UnionColosseumRankPopPanel.12f9f909db61757615031a02704acc05.lua` |
| `canon/panel/UnionColosseumDistributionPopPanel.lua` | `canon/panel/UnionColosseumDistributionPopPanel.b6ac39444cb5ae60f0dfe5d64011742a.lua` |
| `canon/scene/UnionListScene.lua` | `canon/scene/UnionListScene.00865c6edf3f0067989fb0d0effc12db.lua` |
| `canon/scene/UnionHallScene.lua` | `canon/scene/UnionHallScene.7f35b07d6ec1f77c3f1ba4269cbbe00b.lua` |
| `canon/scene/UnionBattleScene.lua` | `canon/scene/UnionBattleScene.e83442b71eb6e8a457de1e36d281ac0d.lua` |
| `canon/scene/BattleScene.lua` | `canon/scene/BattleScene.0700806167ed9176ab8f0cb94fae9b2f.lua` |
| `canon/features/unionPk/UnionPK.lua` | `canon/features/unionPk/UnionPK.ad496a082dba808044b98a4b9c97a3eb.lua` |
| `canon/features/unionPk/manager/UnionPkData.lua` | `canon/features/unionPk/manager/UnionPkData.d028b07d2a7c8f0bb901a51259d080c6.lua` |
| `canon/features/unionPk/manager/UnionPkCityData.lua` | `canon/features/unionPk/manager/UnionPkCityData.419f91615c35ab162b5d154285de7409.lua` |
| `canon/features/unionPk/manager/UnionPkCheck.lua` | `canon/features/unionPk/manager/UnionPkCheck.63f515537122322642fd49f68b674942.lua` |
| `canon/features/unionPk/manager/UnionPkTest.lua` | `canon/features/unionPk/manager/UnionPkTest.96485232450af0b9557a0e35f4cbb2ed.lua` |
| `canon/features/unionPk/manager/UnionPkUtils.lua` | `canon/features/unionPk/manager/UnionPkUtils.482fd07ece75b1dd5e947169981c263a.lua` |
| `canon/features/unionPk/manager/UnionPkConfig.lua` | `canon/features/unionPk/manager/UnionPkConfig.b11216f2a0453acf51755bc5de9a5f00.lua` |
| `canon/features/unionPk/panel/UnionPkCityInfoPopPanel.lua` | `canon/features/unionPk/panel/UnionPkCityInfoPopPanel.53c4cba555032a29872e87dad7c713d2.lua` |
| `canon/features/unionPk/panel/UnionPkCityPowerupPopPanel.lua` | `canon/features/unionPk/panel/UnionPkCityPowerupPopPanel.43d23ba626df883499319b70ca14149a.lua` |
| `canon/features/unionPk/panel/UnionPkChangeFormationPopPanel.lua` | `canon/features/unionPk/panel/UnionPkChangeFormationPopPanel.adcb7c7cbdb412da1d2c046cc8915677.lua` |
| `canon/features/unionPk/panel/UnionBattleReportPopPanel.lua` | `canon/features/unionPk/panel/UnionBattleReportPopPanel.add33c57552ab64395109c19a131c1e2.lua` |
| `canon/features/unionPk/panel/UnionBattleSettlementPopPanel.lua` | `canon/features/unionPk/panel/UnionBattleSettlementPopPanel.2ed2b96879bf4d359937768a81251500.lua` |
| `canon/features/unionPk/panel/UnionCitySignUpInfoPopPanel.lua` | `canon/features/unionPk/panel/UnionCitySignUpInfoPopPanel.74ce5be86885890af5f831f7012af39e.lua` |
| `canon/features/unionPk/panel/UnionPKMyGuildPopPanel.lua` | `canon/features/unionPk/panel/UnionPKMyGuildPopPanel.1da001b04c103bd20d9b677c51c8a952.lua` |
| `canon/features/unionPk/request/UnionPkGetCityListRequest.lua` | `canon/features/unionPk/request/UnionPkGetCityListRequest.604c0bf84d8ab7ae022f0e4f8d444ca8.lua` |
| `canon/features/unionPk/request/UnionPkGetCityFormationRequest.lua` | `canon/features/unionPk/request/UnionPkGetCityFormationRequest.9ad34405703576576dd25023a9a38f14.lua` |
| `canon/features/unionPk/scene/UnionPkScene.lua` | `canon/features/unionPk/scene/UnionPkScene.e5ae409966673e3e74bdd2c15d8b0e75.lua` |
| `canon/features/crossUnionPk/CrossUnionPk.lua` | `canon/features/crossUnionPk/CrossUnionPk.ba05853607765c416ca767ff9d8c5b06.lua` |
| `canon/features/crossUnionPk/manager/CrossUnionPkData.lua` | `canon/features/crossUnionPk/manager/CrossUnionPkData.b80e320303bc7feca858a6ca7937a067.lua` |
| `canon/features/crossUnionPk/manager/CrossUnionPkConfig.lua` | `canon/features/crossUnionPk/manager/CrossUnionPkConfig.11f122c71af1ad8ffec3aa121387821c.lua` |
| `canon/features/crossUnionPk/request/GetCrossGvgInfoRequest.lua` | `canon/features/crossUnionPk/request/GetCrossGvgInfoRequest.d980ae99d42192c15ed13507afa1a358.lua` |
| `canon/features/crossUnionPk/request/GetCrossGvgGroupInfoRequest.lua` | `canon/features/crossUnionPk/request/GetCrossGvgGroupInfoRequest.6b3a365e718e8c09e2c793629183231e.lua` |
| `canon/features/crossUnionPk/request/CrossUnionPkGetGroupRankScoreRequest.lua` | `canon/features/crossUnionPk/request/CrossUnionPkGetGroupRankScoreRequest.c20fba73ab04739397846fc51412eac7.lua` |
| `canon/features/crossUnionPk/request/CrossUnionPkGetGroupReportsRequest.lua` | `canon/features/crossUnionPk/request/CrossUnionPkGetGroupReportsRequest.1a9e91f3dd539114bb5932f2d00f974a.lua` |
| `canon/features/crossUnionPk/request/CrossUnionPkGetKnockoutInfoRequest.lua` | `canon/features/crossUnionPk/request/CrossUnionPkGetKnockoutInfoRequest.9688e362c9f1441ff9fdb6487a615777.lua` |
| `canon/features/crossUnionPk/request/CrossUnionPkGetBattleReportRequest.lua` | `canon/features/crossUnionPk/request/CrossUnionPkGetBattleReportRequest.1b502719c35e0ebf9428d4e07f3c565f.lua` |
| `canon/features/crossUnionPk/request/CrossUnionPkGroupBattleRequest.lua` | `canon/features/crossUnionPk/request/CrossUnionPkGroupBattleRequest.5b745209c87b7b51021c5da067c19dbf.lua` |
| `canon/features/crossUnionPk/request/CrossUnionPkGetBlessInFoRequest.lua` | `canon/features/crossUnionPk/request/CrossUnionPkGetBlessInFoRequest.01739184e6b4623eea9809be398fd24b.lua` |
| `canon/features/crossUnionPk/request/CrossUnionPkGetBlessRequest.lua` | `canon/features/crossUnionPk/request/CrossUnionPkGetBlessRequest.ba5c92b1b1babfe774d923eeddc2893b.lua` |
| `canon/features/crossUnionPk/request/CrossUnionPkGetKnockoutReward.lua` | `canon/features/crossUnionPk/request/CrossUnionPkGetKnockoutReward.711b73f454edc6349c77277919f7ce49.lua` |
| `canon/features/crossUnionPk/request/CrossUnionPkGetCrossGvgInfoBaseRequest.lua` | `canon/features/crossUnionPk/request/CrossUnionPkGetCrossGvgInfoBaseRequest.c3585bab720bb42ce914eccbe166d58a.lua` |
| `canon/features/crossUnionPk/request/CrossUnionPkcrossGvgCanMindApplyRequest.lua` | `canon/features/crossUnionPk/request/CrossUnionPkcrossGvgCanMindApplyRequest.16183b336a93430da0c0d0ec33adcadc.lua` |
| `canon/features/crossUnionPk/request/CrossUnionPkCheckFiredStatueRequest.lua` | `canon/features/crossUnionPk/request/CrossUnionPkCheckFiredStatueRequest.c8d68b6b0120b127f800415e0b2d6e84.lua` |
| `canon/features/crossUnionPk/panel/CrossUnionPkGroupRankPanel.lua` | `canon/features/crossUnionPk/panel/CrossUnionPkGroupRankPanel.1be75f8baeabd6de1b73a8a6cd5a39cd.lua` |
| `canon/features/crossUnionPk/panel/CrossUnionPkGroupReportsPanel.lua` | `canon/features/crossUnionPk/panel/CrossUnionPkGroupReportsPanel.0279387b2efe1bd45627aa6a51bd3fcb.lua` |
| `canon/features/crossUnionPk/panel/CrossUnionPkBattleResultPanel.lua` | `canon/features/crossUnionPk/panel/CrossUnionPkBattleResultPanel.6de91415a4e1e07117ab294fa4637bca.lua` |
| `canon/features/crossUnionPk/panel/CrossUnionPkServerPanel.lua` | `canon/features/crossUnionPk/panel/CrossUnionPkServerPanel.359d010a2bfb4abfdbf6a8972c9314f0.lua` |
| `canon/features/crossUnionPk/scene/CrossUnionPkKnockoutScene.lua` | `canon/features/crossUnionPk/scene/CrossUnionPkKnockoutScene.2570206b553f46b5f1a50a7a834e88a9.lua` |
| `canon/features/crossUnionPk/scene/CrossUnionPKTeamAdjustScene.lua` | `canon/features/crossUnionPk/scene/CrossUnionPKTeamAdjustScene.a1da1acc7ae4f93a0b1f7d17e7db3e41.lua` |
| `canon/features/crossUnionPk/scene/CrossUnionPkMemberSelectScene.lua` | `canon/features/crossUnionPk/scene/CrossUnionPkMemberSelectScene.2ab000ead0ade5246e9666212bbe513c.lua` |
| `canon/features/crossUnionPk/scene/CrossUnionPKBlessingScene.lua` | `canon/features/crossUnionPk/scene/CrossUnionPKBlessingScene.215c36cd43ae43826918561a46dd2eb0.lua` |
| `canon/features/crossUnionPk/scene/CrossUnionPKLoginScene.lua` | `canon/features/crossUnionPk/scene/CrossUnionPKLoginScene.912ba2bfae1cb90d1adcf5fd15a57aab.lua` |

### 0.3 类型判定规则（本次实际使用）

| 客户端写法 | 判定 |
|---|---|
| `ipairs(x)` / `#x` / `table.insert(x, ...)` / `x[i]`（数字下标） | 数组（`list`/`repeatable`） |
| `pairs(x)` 或 `x.key` | 字典 / 对象（`property`） |
| `tonumber(x)`、`x + 1`、`string.format("%d", x)` | 数字（int / long） |
| `if x then` / `not x` / `x and ...` | boolean（但 Lua 中 0 也是真，需注意） |
| 直接传入 `setString(...)` / `tostring(...)` 且无算术 | 字符串 |

**重要推论**：`getUnionInfo` 的 `unionMonsterHp` 被 `tonumber()`（`UnionGetUnionInfoRequest.lua:55`），
`unionTotalFightCapacity` 也被 `tonumber()`（同文件 :63）→ 必须回数字或数字字符串，不能回 nil。
这是本任务开头提到的 SIGKILL 类的直接成因。

---

## 1. `sharkUnion`（当前玩家所在军团的基本信息）

- **类型**：对象（`property`，单个）
- **出现接口**：`getUnionInfo`、`createUnion`、`dissolveUnion`

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `unionId` | 数字(long) | 建团后发聊天协议用 | `canon/request/UnionCreateRequest.lua:64` |
| `declaration` | 字符串 | 军团宣言 | `canon/manager/UnionManager.lua:1979` |
| `notice` | 字符串 | 军团公告 | `canon/manager/UnionManager.lua:1984` |
| `wealth` | 数字 | 军团财富（升级建筑扣这个数） | `canon/manager/UnionManager.lua:2005`、`canon/request/UnionBuildingUpgradeRequest.lua:52-54` |
| `unbandTime` | 数字(时间戳) | 军团解散（公会解散）时间 | `canon/manager/UnionManager.lua:2010` |
| `managerId` | 数字(long) | 军团长 uid | `canon/manager/UnionManager.lua:2015` |
| `transferTime` | 数字(时间戳) | 军团长转让到期时间 | `canon/manager/UnionManager.lua:2020` |
| `status` | 数字(枚举) | 军团状态 0正常/1已解散/2转让中 | `canon/manager/UnionManager.lua:2025`（枚举定义 :75-77） |
| `memberNum` | 数字 | 军团人数 | `canon/manager/UnionManager.lua:2030` |
| `nextManagerId` | 数字(long) | 被转让的目标 uid | `canon/manager/UnionManager.lua:2040` |
| `level` | 数字 | 军团等级（客户端 `setUnionLevel` 会写回；等级真值另由 `sharkUnionBuildingWrapper.buildingHallLevel` 提供） | `canon/manager/UnionManager.lua:2078` |

> **注意**：`sharkUnion` **没有** `unionName` 字段。军团名的真实来源是 `sharkUserUnion.unionName`
> （`canon/manager/UnionManager.lua:1972-1975` 的 `getUnionName()` 明确注释「改为从用户接口获取」）。
> 军团列表项里的名字字段是 `name`（见 §4）。

---

## 2. `sharkUserUnion`（当前玩家在军团中的身份/状态）

- **类型**：对象（`property`，单个）。**这是 `getUserUnionInfo`（`UnionGetMyDataRequest`）的核心字段**，
  也是目前自建服务端只回 `{hasUnion: False}` 而丢掉的那一块。
- **出现接口**：`getUserUnionInfo`、`dissolveUnion`、`quitUnion`
- **客户端判空方式**：`UnionManager.isInUnion()` 先看 `DataManager.getGameInitData().sharkUserUnion` 是否存在
  （`canon/manager/UnionManager.lua:862`）。**未入团时可以不回该字段或回 nil**，但一旦回对象就必须带齐下面字段。

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `unionId` | 数字(long) | 当前军团 id（`getUnionId()`） | `canon/manager/UnionManager.lua:1485` |
| `unionName` | 字符串 | 当前军团名（`getUnionName()`），缺省回 `"union"` | `canon/manager/UnionManager.lua:1525` |
| `title` | 数字(枚举) | 我的职位 0无/1军团长/2副军团长/3精英/4普通 | `canon/manager/UnionManager.lua:1490`（枚举 :86-90） |
| `contribute` | 数字 | 我的当前贡献（可被客户端本地修改后回写） | `canon/manager/UnionManager.lua:1495`；`canon/scene/UnionBankScene.lua:152` |
| `hisContribute` | 数字 | 我的历史总贡献（**必须数字**，客户端做 `<` 比较排序） | `canon/manager/UnionManager.lua:1500`；`canon/panel/UnionMemberListPanel.lua:68` |
| `status` | 数字(枚举) | 我在军团的状态 0成员/1主动退出/2强制退出/3解散 | `canon/manager/UnionManager.lua:1505`（枚举 :80-83） |
| `joinSeconds` | 数字(时间戳) | 入团时刻 | `canon/manager/UnionManager.lua:1510` |
| `reactiveSeconds` | 数字(时间戳) | 可再次创建/加入军团的时刻（入团冷却，0=无冷却） | `canon/manager/UnionManager.lua:1515`、`:957-970` |
| `dissolvedSeconds` | 数字(时间戳) | 解散到期时刻（status=3 时用；`<=0` 视为已过期） | `canon/manager/UnionManager.lua:1520`、`:875-891` |
| `lastestConstructSeconds` | 数字(时间戳) | 我最后一次建设时刻。**客户端只读不写** → 必须由服务端下发 | `canon/scene/UnionHallScene.lua:255`、`:487` |
| `challengeCityId` | 数字 | 我报名的军团战城池 id（未报名=0 或 nil） | `canon/manager/UnionManager.lua:1531`、`:1826-1837`；`canon/features/unionPk/manager/UnionPkCheck.lua:441-448` |
| `coinInspireNum` | 数字 | 我的银币鼓舞次数 | `canon/manager/UnionManager.lua:1537` |
| `striveInspireNum` | 数字 | 我的奋力一击次数 | `canon/manager/UnionManager.lua:1543` |
| `gemInspireNum` | 数字 | 我的金币鼓舞次数 | `canon/manager/UnionManager.lua:1549` |
| `unionWarVersion` | 数字 | 军团战版本号（届数） | `canon/manager/UnionManager.lua:1554` |
| `unionWarRound` | 数字 | 军团战轮次 | `canon/manager/UnionManager.lua:1560` |
| `gainUnionWarPlayReward` | boolean | 是否已领军团战参与奖 | `canon/manager/UnionManager.lua:1566`；`canon/features/unionPk/manager/UnionPkCheck.lua:515` |
| `gainUnionWarOccupyReward` | boolean | 是否已领军团战占领奖 | `canon/manager/UnionManager.lua:1572`；`UnionPkCheck.lua:518` |
| `gainUnionWarInBattleReward` | boolean | 是否已领军团战参战奖 | `canon/manager/UnionManager.lua:1578`；`UnionPkCheck.lua:520` |
| `crossGvgVersion` | 数字 | 跨服军团战版本号 | `canon/manager/UnionManager.lua:1902`（写）、`:1584`（同名字段另一处读的是 gameInit 顶层，见 §23） |
| `lastestConstructType` | 数字 | 我最后一次建设的类型（0无/1银币/2,3金币）。**客户端在成员列表里读的是成员项上的同名字段**（§5），自己身上未读 | `canon/panel/UnionMemberListPanel.lua:351-363` |

> `uid` / `level` / `serverId` 等**不在** `sharkUserUnion` 里：客户端取
> `DataManager.getGameInitData().sharkUser.uid`（如 `canon/manager/UnionManager.lua:1288`）。

---

## 3. `sharkUnionBuildingWrapper`（军团建筑等级）

- **类型**：对象（`property`，单个）
- **出现接口**：`getUnionInfo`
- **唯一消费者**：`UnionManager.setUnionBuildingData`（`canon/request/UnionGetUnionInfoRequest.lua:52` → `canon/manager/UnionManager.lua:2053-2061`）

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `buildingHallLevel` | 数字 | 军团大厅等级（= 军团等级，成员上限由此推导） | `canon/manager/UnionManager.lua:2054`、`:1988-1991`、`:982-988` |
| `buildingShopLevel` | 数字 | 军团商城等级 | `canon/manager/UnionManager.lua:2055` |
| `buildingBankLevel` | 数字 | 军团钱庄等级 | `canon/manager/UnionManager.lua:2056` |
| `buildingColosseumLevel` | 数字 | 军团斗兽场等级 | `canon/manager/UnionManager.lua:2058` |

> 建筑 id 枚举：1大厅 / 2商城 / 3钱庄 / 4斗兽场（`canon/manager/UnionManager.lua:93-96`）。
> 客户端内部建筑表 `buildingsData` 默认 level=1（`:164-167`），所以 4 个字段即使全部缺省也不会崩，
> 但军团等级会一直显示 1。

---

## 4. `sharkUnionWrappers`（军团列表项数组）

- **类型**：**数组**（`ipairs`、`#`、`table.insert` 均出现）
- **出现接口**：`getUnionList`、`searchUnion`、`getAppliedUnions`（= 我已申请的军团列表）
- **证据**：`canon/scene/UnionListScene.lua:42,56,82-83`；`canon/panel/UnionListPanel.lua:306-307,327-328`
- **原厂注释版 schema**（可信度最高，直接写在源码里）：
  `canon/scene/UnionListScene.lua:295-304`

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `unionId` | 数字 | 申请/取消申请的目标 id | `canon/panel/UnionListPanel.lua:241,267,393`；`canon/manager/UnionManager.lua:850-856` |
| `rank` | 数字 | 军团排名（`-1` 表示无排名，客户端转 999；翻页时用它算下一页起始 rank） | `canon/panel/UnionListPanel.lua:157-158,200-232,402,411` |
| `name` | 字符串 | 军团名 | `canon/panel/UnionListPanel.lua:176` |
| `level` | 数字 | 军团等级（同时用于算成员上限） | `canon/panel/UnionListPanel.lua:179,188` |
| `memberNum` | 数字 | 当前人数 | `canon/panel/UnionListPanel.lua:188` |
| `managerName` | 字符串 | 军团长昵称 | `canon/panel/UnionListPanel.lua:182` |
| `managerLevel` | 数字 | 军团长等级 | `canon/panel/UnionListPanel.lua:185` |
| `declaration` | 字符串 | 军团宣言 | `canon/panel/UnionListPanel.lua:191` |

> 注意字段名是 **`name`**，不是 `unionName`。
> `getAppliedUnions` 复用同一个结构（`canon/request/UnionGetMyApplyListRequest.lua:48` →
> `UnionManager.setApplyedUnions`，`:1109-1111`；`isAppliedThisUnion` 用 `v.unionId`，`:850-856`）。

---

## 5. `sharkUnionMemberWrappers`（军团成员项数组）

- **类型**：**数组**
- **出现接口**：`getUnionMembersList`、`getUnionWarCityMembersList`（军团战城池报名成员，复用同结构）
- **证据**：`canon/request/UnionGetMemberListRequest.lua:50-51`（`#event.data.sharkUnionMemberWrappers` 顺便改人数）；
  `canon/features/unionPk/UnionPK.lua:181`
- **原厂假数据样例**（客户端自己拼的完整结构）：`canon/features/unionPk/manager/UnionPkTest.lua:244-260`

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `uid` | 数字(long) | 主键；判断「是不是我」；踢人/任命/转让/加好友/查看阵容都靠它 | `canon/panel/UnionMemberListPanel.lua:60-61,103,239,297,445,476,488` |
| `nickName` | 字符串 | 显示昵称；也作为 `searchUserByNickname` 的查询参数 | `canon/panel/UnionMemberListPanel.lua:251,468` |
| `level` | 数字 | 等级 | `canon/panel/UnionMemberListPanel.lua:254` |
| `mainCardId` | 数字 | 头像卡 metaId（优先用 `CommonManager:getSelfAvatarMetaByUid(uid)` 覆盖） | `canon/panel/UnionMemberListPanel.lua:239-243` |
| `arenaRank` | 数字 | 竞技场排名（`-1` = 未上榜） | `canon/panel/UnionMemberListPanel.lua:257-261` |
| `fightCapacity` | 数字 | 战斗力 | `canon/panel/UnionMemberListPanel.lua:265` |
| `hisContribute` | 数字 | 历史总贡献（用于列表排序） | `canon/panel/UnionMemberListPanel.lua:68,268` |
| `title` | 数字(枚举) | 职位标记（1/2/3/4 四种角标） | `canon/panel/UnionMemberListPanel.lua:271,276,281,298,446`；`canon/manager/UnionManager.lua:1318-1341` |
| `online` | boolean | 是否在线（false 才算离线时长） | `canon/panel/UnionMemberListPanel.lua:321` |
| `lastestActiveSeconds` | 数字(时间戳) | 最后活跃时刻（算「N 小时/天未登录」） | `canon/panel/UnionMemberListPanel.lua:323,332` |
| `lastestConstructSeconds` | 数字(时间戳) | 最后一次建设时刻（算「N 天未建设」） | `canon/panel/UnionMemberListPanel.lua:350` |
| `lastestConstructType` | 数字(枚举) | 最后一次建设类型 0无/1银币/2金币1/3金币2 | `canon/panel/UnionMemberListPanel.lua:351,357,362`；枚举 `canon/manager/UnionManager.lua:99-102` |

> **拼写陷阱**：`UnionPkTest.lua:257` 的假数据里写的是 `areanaRank`（错拼），
> 但真实读取路径是 `aData.arenaRank`（`UnionMemberListPanel.lua:257`）。服务端必须发 **`arenaRank`**。

---

## 6. `sharkUnionAppliers`（入团申请者项数组）

- **类型**：**数组**
- **出现接口**：`getUnionAppliers`
- **证据**：`canon/request/UnionGetApplierListRequest.lua:46`；`canon/manager/UnionManager.lua:413`、`:2631-2660`（`delApplier` 用 `v.uid`，`:2637-2642`）

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `uid` | 数字(long) | 同意/拒绝申请的目标；`acceptUnionApply` / `rejectUnionApply` 的参数就是它 | `canon/panel/UnionApplierListPanel.lua:178,188`；`canon/request/UnionAcceptRequest.lua`（params `applierUid`） |
| `nickName` | 字符串 | 昵称 | `canon/panel/UnionApplierListPanel.lua:147` |
| `level` | 数字 | 等级 | `canon/panel/UnionApplierListPanel.lua:150` |
| `mainCardMetaId` | 数字 | 头像卡 metaId（**注意是 `mainCardMetaId`，不是成员表的 `mainCardId`**） | `canon/panel/UnionApplierListPanel.lua:139` |
| `arenaRank` | 数字 | 竞技场排名（`-1` 未上榜） | `canon/panel/UnionApplierListPanel.lua:153-157` |
| `fightCapacity` | 数字 | 战斗力 | `canon/panel/UnionApplierListPanel.lua:161` |

---

## 7. `sharkUnionNewsWrappers[]` / `unionWarNewsWrappers[]`（军团动态项）

- **类型**：两个都是**数组**，在 `getUnionNewsList` 响应里同时返回，客户端自行合并
  （`canon/request/UnionGetNewsRequest.lua:59-67`，`table.union`）
- **出现接口**：`getUnionNewsList`
- **客户端会往元素上写** `newsType`（1=普通动态, 2=军团战），是客户端自己加的标记，服务端不需要发
  （`canon/request/UnionGetNewsRequest.lua:59-64`；枚举 `canon/manager/UnionManager.lua:105-106`）

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `senderUid` | 数字(long) | 发言者 uid（取头像） | `canon/panel/UnionNewsListPanel.lua:169` |
| `senderNickname` | 字符串 | 发言者昵称 | `canon/panel/UnionNewsListPanel.lua:180` |
| `senderLevel` | 数字 | 发言者等级 | `canon/panel/UnionNewsListPanel.lua:181` |
| `mainCardId` | 数字 | 头像卡 metaId（`getSelfAvatarMetaByUid` 失败时兜底） | `canon/panel/UnionNewsListPanel.lua:171` |
| `type` | 数字(枚举) | 动态类型，1..12，见下表 | `canon/panel/UnionNewsListPanel.lua:183,207,242,252,262`；枚举 `canon/manager/UnionManager.lua:109-120` |
| `detail` | 字符串(**JSON 文本**) | 动态明细，客户端用 `cjson.decode` 解析 | `canon/panel/UnionNewsListPanel.lua:204`；`canon/manager/UnionManager.lua:2565-2626` |
| `createTime` | 数字(时间戳) | 显示时间 | `canon/panel/UnionNewsListPanel.lua:182` |

### 7.1 `detail` JSON 的逐类型契约（普通动态，`NEWS_TYPE_NORMAL`）

解析入口 `canon/manager/UnionManager.lua:2565-2626`（`_json.decode(detailData)`），
注释即原厂自述字段（同文件 :2570/:2573/:2576/:2583/:2591/:2595/:2598/:2601/:2606/:2611/:2616/:2620）：

| `type` | 含义 | `detail` JSON 需要的 key |
|---|---|---|
| 1 | 创建军团 | `creatorNickname`, `unionName` |
| 2 | 玩家加入军团 | `nickname` |
| 3 | 玩家捐献 | `nickname`, `constructType` |
| 4 | 玩家领工资 | `nickname`, `wageLevel` |
| 5 | 军团建筑升级 | `nickname`, `buildingType`, `currBuildingLevel` |
| 6 | 转让军团长 | `nickname`, `transferedNickname` |
| 7 | 弹劾军团长成功 | `oldManagerNickname`, `currManagerNickname` |
| 8 | 任命职务 | `nickname`, `title`, `appointedNickname`, `appointedTitle` |
| 9 | 解散军团 | `nickname`, `dissolveTime`（时间戳） |
| 10 | 召唤怪兽 | `nickname`, `title`, `bossId` |
| 11 | 怪兽被击杀 | `nickname`, `bossId` |
| 12 | 奖励被分配 | `nickname`, `title`, `bossId` |

### 7.2 `detail` JSON 的逐类型契约（军团战 `NEWS_TYPE_PK`）

解析入口 `canon/panel/UnionNewsListPanel.lua:203-269`。
**注意**：城池 id 列表在这里是 **逗号分隔的字符串**（客户端 `.split(",")` 转换，不是数组）：

| `type` | 含义 | `detail` JSON 需要的 key |
|---|---|---|
| `UnionPkConsts.WAR_NEWS_TYPE_PREPARE` | 备战 | `ownCityIds`（"1,6" 字符串）, `challengeCityIds`（"22,23" 字符串） |
| `UnionPkConsts.WAR_NEWS_TYPE_DEFENSE` | 守城 | `ownCityId`（单个 id） |
| `UnionPkConsts.WAR_NEWS_TYPE_BID` | 竞标成功 | `bidCityId` |
| `UnionPkConsts.WAR_NEWS_TYPE_OCCUPY` | 占领 | `ownCityId` |

证据：`canon/panel/UnionNewsListPanel.lua:210,216,248,258,267`。
原厂假数据样例：`canon/features/unionPk/manager/UnionPkTest.lua:169-238`
（注意 `:180` 写的是 `"{\"ownCityIds\":[\"1\",\"6\"],...}"` 即**数组形式**，而 `:210` 的读取代码是
`detailData.ownCityIds:split(",")` 即**字符串形式** —— 两者矛盾，以 `:210` 的读取代码为准）。

---

## 8. `sharkUnionMonster`（军团斗兽场 BOSS）+ `reward`

- **类型**：对象（`property`，单个）
- **出现接口**：`getUnionBuildingColosseumInfo`、`summonUnionMonster`
- **原厂注释版 schema**：`canon/request/UnionColosseumBuildingInfoRequest.lua:53-57`
  （`<property code="sharkUnionMonster" ref="SharkUnionMonster" desc="军团怪兽信息" />`）

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `summonUserNickname` | 字符串 | 召唤者昵称 | `canon/request/UnionColosseumBuildingInfoRequest.lua:71`；`canon/request/UnionColosseumSummonRequest.lua:69` |
| `monsterLeftHp` | 数字 | 剩余血量（`<=0` 视为已击杀） | `...BuildingInfoRequest.lua:73`；`...SummonRequest.lua:71`；`canon/manager/UnionManager.lua:2848` |
| `escapeSeconds` | 数字(时间戳) | 逃跑时刻（客户端会 +3 秒容错） | `...BuildingInfoRequest.lua:75`；`canon/manager/UnionManager.lua:2921`（`v + 3`） |
| `rewardDouble` | boolean | 是否双倍奖励 | `...BuildingInfoRequest.lua:77`；`canon/manager/UnionManager.lua:198` |
| `monsterId` | 数字 | BOSS 配置 id（`union_boss_meta` 的 key） | `...BuildingInfoRequest.lua:79`；`canon/manager/UnionManager.lua:2700-2706` |
| `reward.amount` | 数字 | **待分配奖励总数**（嵌套一层 `reward`） | `...BuildingInfoRequest.lua:81`；`...SummonRequest.lua:79`；`canon/manager/UnionManager.lua:2792-2794` |
| `distributingUid` | 数字(long) | 当前分配者 uid（0 = 无分配者） | `...BuildingInfoRequest.lua:83`；`canon/manager/UnionManager.lua:2807-2809`、`:2843`（注意 `getColosseumWeekLeftSummonTimes()` 也误读这个字段，原厂 bug） |
| `rewardDistributed` | boolean | 战利品是否已分配完（false 时禁止再召唤） | `...BuildingInfoRequest.lua:85`；`canon/manager/UnionManager.lua:3145-3151` |

**`sharkUnionMonster.reward`**：
- 客户端**只读 `amount`**（`canon/request/UnionColosseumBuildingInfoRequest.lua:81`、
  `canon/request/UnionColosseumSummonRequest.lua:79`）。
- 返回 `reward` 为对象即可；`reward.amount` 必须存在且为数字，否则
  `UnionManager.setColosseumMonsterRewardAmount(nil)` → `tonumber(nil)` 在后续算术里会炸
  （`canon/manager/UnionManager.lua:2792-2794` 用 `tonumber(...) or 0` 兜了一层，
  但 `:2989` 的 `totalNum - colosseumDistributionNum` 会直接报错，所以**建议必发**）。
- 在 `getUnionBuildingColosseumInfo` 响应里，**`sharkUnionMonster` 整体可以为 nil**
  （客户端有 `if event.data.sharkUnionMonster then` 保护，`:68`）；但 `summonUnionMonster`
  响应里客户端**无保护**，必须发（`:68-83` 直接取）。

---

## 9. `getUnionBuildingHallInfo` 的响应结构（无名结构）

- **类型**：对象（顶层多个字段，无 wrapper 名）
- **消费者**：`GetUnionBuildingHallInfoRequest.onSucceedDefault` + `UnionHallScene`

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `lastestConstructSeconds` | 数字(时间戳) | 军团最后建设时刻（算「今天建了几次」） | `canon/request/GetUnionBuildingHallInfoRequest.lua:42`；`canon/manager/UnionManager.lua:2354-2383` |
| `constructTimesToday` | 数字 | 今日建设总次数 | `canon/request/GetUnionBuildingHallInfoRequest.lua:42` |
| `unionHallLevel` | 数字 | 大厅等级显示 | `canon/scene/UnionHallScene.lua:353,365` |
| `unionWealth` | 数字 | 军团财富显示 | `canon/scene/UnionHallScene.lua:359` |
| `donateAnnouncement` | **数组** | 捐献公告，客户端固定读前 10 项 | `canon/scene/UnionHallScene.lua:374-386` |

**`donateAnnouncement` 元素**：

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `nickname` | 字符串 | 捐献者昵称 | `canon/scene/UnionHallScene.lua:379` |
| `donateNum` | 数字 | 捐献财富数（`tostring` 后显示） | `canon/scene/UnionHallScene.lua:381` |

> 客户端只遍历 `for i=1,10`，`donateAnnouncement` 长度不足 10 也没问题（`:377` 有 `if data then` 保护），
> 但**必须是数组/table**，不能是 nil。

---

## 10. `getUnionBuildingShopInfo` 的响应结构

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `level` | 数字 | 军团等级（写进 `currentUnionData.level`） | `canon/request/GetUnionBuildingShopInfoRequest.lua:40` |
| `specialProps` | **数组** | 特殊商店商品列表 | `canon/request/GetUnionBuildingShopInfoRequest.lua:41`；`canon/panel/UnionShopSpecialPanel.lua:36` |
| `specialShopRecord` | **数组** | 已购买的商品 id 列表（`table.indexOf` 查重） | `canon/request/GetUnionBuildingShopInfoRequest.lua:42`；`canon/manager/UnionManager.lua:2437-2443` |

**`specialProps` 元素**：

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `id` | 数字 | 商品配置 id；购买时作为 `unionPropId`；也是 `specialShopRecord` 里的元素 | `canon/panel/UnionShopSpecialPanel.lua:192,206,235`；`canon/manager/UnionManager.lua:2501-2503` |
| `leftNum` | 数字 | 剩余可购买数量（`<=0` 置灰） | `canon/panel/UnionShopSpecialPanel.lua:117,153` |

> 商品的 `itemType / metaId / amount / contributeCost` 等**不在响应里**，客户端从
> `MetaManager.union_shop_special[id]` 本地配置取（`canon/panel/UnionShopSpecialPanel.lua:122-138,193`）。

---

## 11. `getUnionBuildingBankInfo` 的响应结构

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `level` | 数字 | 钱庄等级（`UnionManager.setBankLevel`） | `canon/request/GetUnionBuildingBankInfoRequest.lua:39`；`canon/manager/UnionManager.lua:1999-2001` |

---

## 12. `sharkUnionCity`（军团战城池）

- **类型**：对象（`property`，单个）
- **出现接口**：`getUnionCityInfo`
- **原厂注释版 schema**：`canon/features/unionPk/manager/UnionPkCityData.lua:8-20`（`<bean desc="城池信息">`）

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `cityId` | 数字 | 城池 id（后续所有城池接口的参数） | `canon/features/unionPk/panel/UnionPkCityInfoPopPanel.lua:29,58,106,134,609` |
| `unionId` | 数字 | 占领军团 id，0=NPC 守军 | `canon/features/unionPk/manager/UnionPkCityData.lua:37-43` |
| `unionName` | 字符串 | 占领军团名 | `canon/features/unionPk/panel/UnionPkCityInfoPopPanel.lua:613` |
| `unionLevel` | 数字 | 占领军团等级（**bean 注释漏列，但客户端确实读**） | `canon/features/unionPk/panel/UnionPkCityInfoPopPanel.lua:614` |
| `occupyNum` | 数字 | 连续占领次数 → 城防加成 `cityDefenceBuffNow(occupyNum-1)` | `canon/features/unionPk/panel/UnionPkCityInfoPopPanel.lua:627`；`UnionPkConfig.lua:129-135` |
| `report` | boolean | 我的军团是否已报名该城 | `canon/features/unionPk/panel/UnionPkCityInfoPopPanel.lua:98,304,336,357,386,414,425,452,505,550`；`canon/features/unionPk/manager/UnionPkTest.lua:98` |
| `successfulBid` | boolean | 我的军团是否竞标成功 | `canon/features/unionPk/panel/UnionPkCityInfoPopPanel.lua:359,386,425,463,518`；`UnionPkTest.lua:99` |
| `userPosition` | 数字 | 我的军团职位（bean 声明） | `canon/features/unionPk/manager/UnionPkCityData.lua:13`（**仅有声明，未在读取路径中出现 → 客户端未实际读取**） |
| `challengeCityNum` | 数字 | 我方挑战城池数（bean 声明） | `UnionPkCityData.lua:16`（**未实际读取**） |
| `ownCityNum` | 数字 | 我方占领城池数（bean 声明） | `UnionPkCityData.lua:17`（**未实际读取**） |
| `applyNum` | 数字 | 报名该城的军团数（bean 声明） | `UnionPkCityData.lua:18`（**未实际读取**） |

> `getUnionCityInfo` 响应**顶层**还有两个字段，客户端在 `UnionPkCityInfoPopPanel` 里直接读：

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `inBattle` | boolean | 我的军团是否曾出现在本轮战报里（判定「曾为守方但已被击败」） | `canon/features/unionPk/panel/UnionPkCityInfoPopPanel.lua:173,500,545` |
| `firstBattleFailed` | boolean | 第一场是否失败（决定第二轮能否再进战场） | `canon/features/unionPk/panel/UnionPkCityInfoPopPanel.lua:174,475` |

---

## 13. `sharkUnionCityApply`（城池参与/报名的军团项数组）

**两个不同接口返回同名结构，元素一致：**

1. `getApplyUnions` → `sharkUnionCityApply`：报名该城池的军团列表
   （`canon/features/unionPk/panel/UnionPkCityInfoPopPanel.lua:55`）
2. `getUnionFormation` → `sharkUnionCityApply`：**按顺序** `[1]`=防守方、`[2]`=进攻方1、`[3]`=进攻方2
   （`canon/features/unionPk/panel/UnionPkCityPowerupPopPanel.lua:212-216`；
   `canon/features/unionPk/manager/UnionPkCheck.lua:78,89`）

- **类型**：**数组**

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `unionId` | 数字 | 判定阵营（守方/攻方）、是否 NPC（0） | `canon/features/unionPk/panel/UnionPkCityInfoPopPanel.lua:119`；`canon/features/unionPk/manager/UnionPkUtils.lua:83-88`；`UnionPkCityPowerupPopPanel.lua:241,255,270,279-280` |
| `unionName` | 字符串 | 军团名（空/NPC 时客户端用城池 NPC 名兜底） | `canon/features/unionPk/panel/UnionCitySignUpInfoPopPanel.lua:122,126`；`UnionPkUtils.lua:88` |
| `wealth` | 数字 | 报名财富值（`string.format("%d", wealth)` → **必须是数字**） | `canon/features/unionPk/panel/UnionCitySignUpInfoPopPanel.lua:130` |
| `applyId` | 数字 | 报名记录 id（仅原厂注释提到，客户端未读） | `canon/features/unionPk/panel/UnionPkCityInfoPopPanel.lua:56`（注释样例） |

原厂注释样例（`canon/features/unionPk/panel/UnionPkCityInfoPopPanel.lua:56`）：
`-- data = {{applyId = 1 , unionId = 1 , unionName = "76ers" , wealth = 1000}}`

---

## 14. `unionFormation`（军团战阵型）

- **类型**：对象（`property`）
- **出现接口**：`getUnionFormation`
- **原厂假数据样例**：`canon/features/unionPk/manager/UnionPkTest.lua:29-43`、`:134-148`

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `forwardInfo` | **对象**（单挑战/先锋） | 先锋玩家信息；nil = 无先锋 | `canon/features/unionPk/panel/UnionPkCityPowerupPopPanel.lua:193-195`；`canon/features/unionPk/manager/UnionPkCheck.lua:539-544`；`canon/features/unionPk/panel/UnionPkChangeFormationPopPanel.lua:140` |
| `formationHeadInfo` | **数组** | 阵首（最多 `UnionPkConfig.cityFrontLimit()` 个） | `UnionPkCityPowerupPopPanel.lua:196-199`；`UnionPkChangeFormationPopPanel.lua:155`；`UnionPkCheck.lua:546-553` |
| `formationMiddleInfo` | **数组** | 阵中 | `UnionPkCityPowerupPopPanel.lua:196-199`；`UnionPkCheck.lua:555-562` |
| `formationTailInfo` | **数组** | 阵尾 | `UnionPkCityPowerupPopPanel.lua:196-199`；`UnionPkCheck.lua:564-571` |
| `gemInspireNum` | 数字 | 本城池军团**金币鼓舞总次数**（与个人鼓舞次数上限比对） | `canon/features/unionPk/manager/UnionPkCheck.lua:186` |

`getUnionFormation` 响应**顶层**还有三个数组（客户端读，bean 里没有）：

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `sharkUnionCityApply` | 数组 | 见 §13（`[1]`守 `[2]`攻1 `[3]`攻2） | `canon/features/unionPk/panel/UnionPkCityPowerupPopPanel.lua:212-216` |
| `winnerUnionCityApply` | 数组 | 上一轮胜利方（`[1]`） | `canon/features/unionPk/panel/UnionPkCityPowerupPopPanel.lua:241,246,270,365,393`；`UnionPkTest.lua:25,130` |
| `loserUnionCityApply` | 数组 | 上一轮失败方（`[1]`）；**空数组也要发，客户端靠 `[1]` 判空** | `canon/features/unionPk/panel/UnionPkCityPowerupPopPanel.lua:238,243,357,362`；`UnionPkTest.lua:27,132` |

> ⚠ `getUnionFormation` 在 `SystemManager.debug` 为真时断言 `sharkUnionCityApply[1] ~= nil`
> （`canon/features/unionPk/request/UnionPkGetCityFormationRequest.lua:93`）——「此城池必防守方信息为空,
> 至少要一个空白军团!」。即**数组至少要有一个元素**（NPC 守军也要占位）。

---

## 15. `UnionFormationMember`（阵型成员，即 §14 里四种数组/对象的元素）

- **类型**：对象

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `uid` | 数字(long) | 判「是否是我」；取头像 | `canon/features/unionPk/manager/UnionPkCheck.lua:540,548,557,566`；`UnionPkCityPowerupPopPanel.lua:710,726` |
| `userName` | 字符串 | 显示昵称（**不是 `nickName`**） | `canon/features/unionPk/panel/UnionPkCityPowerupPopPanel.lua:722`；`canon/features/unionPk/panel/UnionPkChangeFormationPopPanel.lua:373`；`UnionPkTest.lua:32` |
| `mainCardMeataId` | 数字 | 头像卡 metaId（**原厂拼写就是 `Meata`，必须照抄**） | `UnionPkCityPowerupPopPanel.lua:712`；`UnionPkChangeFormationPopPanel.lua:194,362`；`UnionPkTest.lua:32,35-36` |
| `gemInspireNum` | 数字 | 该成员的金币鼓舞次数（角标；是我自己时改用 `UnionManager.getGemInspireNum()`） | `UnionPkCityPowerupPopPanel.lua:725-728`；`UnionPkTest.lua:32,35-36` |

---

## 16. `getUnionCityList` 的响应结构（军团战主界面）

- **类型**：对象（顶层多字段）
- **唯一消费者**：`UnionPkGetCityListRequest.onSucceedDefault`（`canon/features/unionPk/request/UnionPkGetCityListRequest.lua:63-84`）

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `ownCityIds` | **数组**（数字） | 我方占领的城池 id；客户端转哈希做 O(1) 查询 | `canon/features/unionPk/request/UnionPkGetCityListRequest.lua:70-72`；`canon/features/unionPk/manager/UnionPkData.lua:130-142,210-212` |
| `smallCityNum` | 数字 | 小城池总数（地图上画几个） | `UnionPkGetCityListRequest.lua:74`；`canon/features/unionPk/scene/UnionPkScene.lua:361` |
| `roundWealth` | 数字 | 我方本轮财富（直接 `setString`） | `UnionPkGetCityListRequest.lua:75`；`UnionPkScene.lua:192` |
| `userTitle` | 数字(枚举) | 第二轮结束时我的职位（权限判定） | `UnionPkGetCityListRequest.lua:77`；`UnionPkData.lua:169-172` |
| `challengeCityIds` | **数组**（数字） | 我方已报名的城池 id | `UnionPkGetCityListRequest.lua:78`；`UnionPkData.lua:219-235` |
| `fightingCityIds` | **数组**（数字） | 正在战斗中的城池 id | `UnionPkGetCityListRequest.lua:79`；`UnionPkData.lua:304-321` |
| `unionWinNum` | **数组**（对象） | 我方在各城池的胜利次数，见 §17 | `UnionPkGetCityListRequest.lua:80`；`UnionPkData.lua:338-355` |
| `attendBattleNum` | 数字 | 参战次数（同一城池打两次算两次） | `UnionPkGetCityListRequest.lua:81`；`UnionPkData.lua:361-367` |

> 城池**列表本身不在响应里** —— 城池集合由客户端本地推导：
> `UnionPkUtils.getCityTypeById(cityId)` 按 id 区间分大/中/小
> （`canon/features/unionPk/manager/UnionPkUtils.lua:9-22`），名称走本地化
> （`:25-40`）。服务端只需维护「哪些城池被谁占 / 谁报名」。

---

## 17. `unionWinNum[]` 与 `UnionMonsterDamage[]`

### 17.1 `unionWinNum[]`（军团战军团胜利次数）

- **类型**：**数组**
- **原厂注释版 schema**：`canon/features/unionPk/manager/UnionPkData.lua:56-59`（`<bean desc="军团战军团胜利次数">`）
- 出现于 `getUnionCityList` 响应的 `unionWinNum`

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `cityId` | 数字 | 城池 id | `canon/features/unionPk/manager/UnionPkData.lua:348-351` |
| `winNum` | 数字 | 该城池胜利次数（用于领「占领奖」判定） | `UnionPkData.lua:348-351`；`canon/features/unionPk/manager/UnionPkCheck.lua:484-488` |

### 17.2 `UnionMonsterDamage`（斗兽伤害排行榜项）

- **类型**：**数组**
- **原厂注释版 schema**：`canon/request/UnionColosseumGetRankRequest.lua:53-57`（`<bean desc="斗兽伤害值">`）
- 出现于 `getUnionMonsterRank` 响应的 `rankList`，以及 `getUnionBuildingColosseumInfo` 响应的 `rankList`

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `uid` | 数字(long) | 找自己的排名 / 找某人排名 | `canon/manager/UnionManager.lua:2864-2883`；`canon/panel/UnionColosseumDistributionPopPanel.lua:159,350` |
| `nickName` | 字符串 | 昵称（**`nickName`，注意大写 N**） | `canon/panel/UnionColosseumBossInfoPanel.lua:139,146,153`；`canon/panel/UnionColosseumRankPopPanel.lua:135` |
| `totalDamage` | 数字 | 累积伤害（`string.format("%d", ...)` → 必须数字） | `canon/panel/UnionColosseumRankPopPanel.lua:138` |

---

## 18. `unionBattlefieldReportSummarys`（军团战战报摘要项数组）

- **类型**：**数组**
- **出现接口**：`getUnionBattlefieldReportList`
- **证据**：`canon/features/unionPk/panel/UnionPkCityInfoPopPanel.lua:78`
  → 传入 `UnionBattleReportPopPanel:create(scene, cityId, data)`

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `reportId` | 数字 | 点击「查看」时作为 `getUnionBattlefieldReport` 的 `reportId` 参数 | `canon/features/unionPk/panel/UnionBattleReportPopPanel.lua:152` |
| `victor` | 字符串 | 胜利方军团名（空/NPC 时客户端用城池 NPC 名兜底） | `canon/features/unionPk/panel/UnionBattleReportPopPanel.lua:115-119` |
| `loser` | 字符串 | 失败方军团名（同上兜底） | `canon/features/unionPk/panel/UnionBattleReportPopPanel.lua:123-127` |

---

## 19. `SharkUnionBattlefieldReport`（军团战战报，进战斗场景用）

**这是最容易踩坑的结构：`BattleScene:create()` 会根据 `enterType` 决定从哪里取战斗数据。**

`canon/scene/BattleScene.lua:117-133`：

```lua
if enterType == BattleEnterEnum.kUnionBattle
   or enterType == BattleEnterEnum.kCrossGVGGroupBattle
   or enterType == BattleEnterEnum.kCrossGVGRankBattle then
    scene.unionBattleData = data                  -- 响应根对象
    scene.data = data.sharkUnionBattlefieldReport -- ← 战报必须在根上的这个 key
else
    scene.data = data
end
```

**因此 `getUnionBattlefieldReport` / `crossGVGGroupBattle` / `getGvgBattleResultDetail`
的响应根对象必须是 `{ sharkUnionBattlefieldReport = {...}, currPoints = N, changePoints = N }`。**

> ⚠ **与 DSL 注释冲突**：`canon/features/crossUnionPk/request/CrossUnionPkGetBattleReportRequest.lua:12`
> 的注释写的是 `<property code="battleReport" ref="SharkUnionBattlefieldReport" .../>`，
> 但代码路径（同上，以及 `:99` → `CrossUnionPk.gotoBattleField(event.data, ...)`）读的是
> **`sharkUnionBattlefieldReport`**。以代码为准。同理 `crossGVGGroupBattle` 的 DSL 注释也写
> `battleReport`（`canon/features/crossUnionPk/request/CrossUnionPkGroupBattleRequest.lua:10`）。

- **类型**：对象

### 19.1 多军团混战形态（`unionBattleCardDatas` / `unionBattleRounds`）

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `attackUnionName` | 字符串 | 攻方军团名（nil/"" 时用城池 NPC 名） | `canon/scene/UnionBattleScene.lua:1716,1719`；`canon/features/unionPk/panel/UnionBattleSettlementPopPanel.lua:160` |
| `defenseUnionName` | 字符串 | 守方军团名（同上） | `canon/scene/UnionBattleScene.lua:1717,1719`；`UnionBattleSettlementPopPanel.lua:168` |
| `warWin` | boolean | 攻方是否胜（决定攻/守哪边算赢） | `canon/scene/UnionBattleScene.lua:717`；`UnionBattleSettlementPopPanel.lua:175-176,208`；`canon/features/crossUnionPk/panel/CrossUnionPkBattleResultPanel.lua:78-79,83-84,88-89` |
| `attGemInspireNum` | 数字 | 攻方金币鼓舞总次数 → 属性加成 | `canon/scene/UnionBattleScene.lua:1788,1791` |
| `defGemInspireNum` | 数字 | 守方金币鼓舞总次数 → 属性加成 | `canon/scene/UnionBattleScene.lua:1789,1792` |
| `attUnionLeftPlayer` | 数字 | 攻方剩余人数（显示用） | `canon/features/unionPk/panel/UnionBattleSettlementPopPanel.lua:209`；`CrossUnionPkBattleResultPanel.lua:140` |
| `defUnionLeftPlayer` | 数字 | 守方剩余人数（显示用） | `UnionBattleSettlementPopPanel.lua:210`；`CrossUnionPkBattleResultPanel.lua:141` |
| `unionBattleCardDatas` | **数组**（固定 6 个槽位：1-3 我方，4-6 敌方） | 每个槽位是一支上阵队列 | `canon/scene/UnionBattleScene.lua:1760`、`:59,1729-1734` |
| `unionBattleRounds` | **数组** | 每轮战斗的阵型变化 + 战斗事件流 | `canon/scene/UnionBattleScene.lua:1761,1550,1620` |
| `cardInitDatas` | **数组**（可选；单挑战形态） | 单挑战斗数据。存在时走「单挑战结算面板」分支 | `canon/scene/BattleScene.lua:2531`；`UnionBattleSettlementPopPanel.lua:182,188-211`；`CrossUnionPkBattleResultPanel.lua:97-108` |
| `singleBattleAttName` | 字符串 | 单挑战攻方昵称 | `UnionBattleSettlementPopPanel.lua:191`；`CrossUnionPkBattleResultPanel.lua:117` |
| `singleBattleDefName` | 字符串 | 单挑战守方昵称 | `UnionBattleSettlementPopPanel.lua:197`；`CrossUnionPkBattleResultPanel.lua:126` |
| `attUnionId` | 数字 | 单挑战攻方军团 id | `UnionBattleSettlementPopPanel.lua:192` |
| `defUnionId` | 数字 | 单挑战守方军团 id | `UnionBattleSettlementPopPanel.lua:198` |
| `win` | boolean | **单挑战**胜负（`CrossUnionPkBattleResultPanel` 显示先锋战胜负用） | `canon/features/crossUnionPk/panel/CrossUnionPkBattleResultPanel.lua:92-95,131-134` |

**`unionBattleCardDatas[i]` 元素**（6 个）：

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `unionBattleCardInitDatas` | **数组** | 该槽位的上阵卡队列（`[1]` 出场，`:118` `table.remove(...,1)` 出队） | `canon/scene/UnionBattleScene.lua:59,62,66-69,115-118,1729-1734,1760` |

**`unionBattleCardInitDatas[j]` 元素**：

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `cardInitData` | 对象 | 标准战斗卡初始数据（`sharkEquips` 等），即 `BattleCardInitData` | `canon/scene/UnionBattleScene.lua:62,69,801` |

**`unionBattleRounds[i]` 元素**：

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `unionBattleEventFlow` | **数组** | 本轮各玩家的事件流 | `canon/scene/UnionBattleScene.lua:1552-1553` |
| `changePosition` | 字符串，形如 `"3,1"` | 换行（`string.split(changePosition, ',')` → from,to） | `canon/scene/UnionBattleScene.lua:583-584,1623-1627` |
| `buffId` | 字符串，形如 `"1,0,2,0,0,0"` | 6 个位置各自的团战 buff id（`string.split`） | `canon/scene/UnionBattleScene.lua:595,1635` |

**`unionBattleEventFlow[i]` 元素**：

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `teamId` | 数字 | 该事件流属于哪个槽位（作为 table 的 key） | `canon/scene/UnionBattleScene.lua:1570` |
| `eventFlow` | **数组** | 战斗事件流 | `canon/scene/UnionBattleScene.lua:1555-1556` |

**`eventFlow[j]` 元素**（与全项目通用 `BattleEvent` 一致）：

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `eventType` | 数字 | 事件类型 | `canon/scene/UnionBattleScene.lua:1558` |
| `round` | 数字 | 回合 | `canon/scene/UnionBattleScene.lua:1559` |
| `actionType` | 数字 | 动作类型 | `canon/scene/UnionBattleScene.lua:1560` |
| `battleCardActs` | **数组** | 卡牌动作（客户端只读 `[1]`） | `canon/scene/UnionBattleScene.lua:1561-1565` |

**`battleCardActs[1]` 元素**：

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `posId` | 数字 | 卡位 | `canon/scene/UnionBattleScene.lua:1562` |
| `skillId` | 数字 | 技能 | `canon/scene/UnionBattleScene.lua:1563` |
| `effectId` | 数字 | 效果 | `canon/scene/UnionBattleScene.lua:1564` |
| `changedValue` | 数字 | 变化量 | `canon/scene/UnionBattleScene.lua:1565` |

**`cardInitDatas` 元素**（单挑形态）：

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `posId` | 数字 | `1`=攻方单挑，`10001`=守方单挑（客户端靠这两个魔数取人） | `canon/features/unionPk/panel/UnionBattleSettlementPopPanel.lua:189,195`；`CrossUnionPkBattleResultPanel.lua:102,105` |
| `metaId` | 数字 | 主将 metaId | `UnionBattleSettlementPopPanel.lua:203,206`；`CrossUnionPkBattleResultPanel.lua:112,121` |
| `uid` | 数字(long) | 取头像 | `CrossUnionPkBattleResultPanel.lua:110,119` |
| `userName` | 字符串 | 显示昵称（客户端会自行覆盖成 `singleBattleAttName`） | `UnionBattleSettlementPopPanel.lua:191,197` |

### 19.2 响应根上的积分字段

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `currPoints` | 数字 | 当前积分（小组赛结算面板显示） | `canon/scene/BattleScene.lua:785,2547`；`canon/features/crossUnionPk/panel/CrossUnionPkBattleResultPanel.lua:147` |
| `changePoints` | 数字 | 本次积分变化 | `canon/scene/BattleScene.lua:785,2547`；`CrossUnionPkBattleResultPanel.lua:157` |

---

## 20. `CrossGVGScoreInfo`（跨服 GVG 军团积分项）

- **类型**：对象
- **原厂注释版 schema**：`canon/features/crossUnionPk/request/CrossUnionPkGetGroupRankScoreRequest.lua:16-21`
  （`<bean desc="跨服gvg某军团积分信息">`），另在
  `canon/features/crossUnionPk/panel/CrossUnionPkGroupRankPanel.lua:97-102`、
  `canon/layer/Activity_ChallengeMysteriousLayer.lua:105` 重复出现
- **出现接口**：`getCrossGvgGroupTop10Score`（`selfScore` 单个 + `top10ScoreList` 数组）

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `unionId` | 数字 | 军团 id | `canon/features/crossUnionPk/request/CrossUnionPkGetGroupRankScoreRequest.lua:17` |
| `unionName` | 字符串 | 军团名 | `CrossUnionPkGroupRankPanel.lua:52-53` |
| `score` | 数字 | 当前积分（直接 `setString`） | `CrossUnionPkGroupRankPanel.lua:54` |
| `rank` | 数字 | 排名（`<=4` 晋级配色） | `CrossUnionPkGroupRankPanel.lua:51,57` |

`getCrossGvgGroupTop10Score` 响应：`selfScore`（对象）、`top10ScoreList`（数组）
（`canon/features/crossUnionPk/request/CrossUnionPkGetGroupRankScoreRequest.lua:9-11`；
`CrossUnionPkGroupRankPanel.lua:51-54,67`）。

---

## 21. 跨服 GVG 淘汰赛 / 小组赛战报结构

### 21.1 `GVGReport`（小组赛战报项）

- **类型**：数组元素
- **原厂注释版 schema**：`canon/features/crossUnionPk/request/CrossUnionPkGetGroupReportsRequest.lua:14-19`
  （`<bean desc="战报信息">`），并在 `CrossUnionPkGroupReportsPanel.lua:89-94` 复述
- **出现接口**：`getCrossGvgGroupReports` → `reports` 数组

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `uuid` | 数字 | 战报 id，作为 `getGvgBattleResultDetail` 的 `reportId` | `canon/features/crossUnionPk/panel/CrossUnionPkGroupReportsPanel.lua:142` |
| `attUnionName` | 字符串 | 进攻方军团名 | `CrossUnionPkGroupReportsPanel.lua:97` |
| `defUnionName` | 字符串 | 防守方军团名 | `CrossUnionPkGroupReportsPanel.lua:98` |
| `win` | boolean | 进攻方是否胜（决定胜负图标） | `CrossUnionPkGroupReportsPanel.lua:124-127` |

### 21.2 `CrossGvgResultOutline`（淘汰赛对阵项）

- **类型**：对象
- **原厂注释版 schema**：`canon/features/crossUnionPk/request/CrossUnionPkGetKnockoutInfoRequest.lua:18-23`
  （`<bean desc="跨服gvg战斗结果信息">`），并在 `CrossUnionPkKnockoutScene.lua:207-212` 复述
- **出现接口**：`getGvgKnockoutInfo`

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `id` | 数字 | 用于取战报的 id（传给 `getGvgBattleResultDetail`） | `canon/features/crossUnionPk/scene/CrossUnionPkKnockoutScene.lua:263`；`canon/features/crossUnionPk/scene/CrossUnionPkKnockoutScene.lua:71-73` |
| `attUnion` | 对象 `UnionIdentification` | 进攻军团 | `CrossUnionPkKnockoutScene.lua:224` |
| `defUnion` | 对象 `UnionIdentification` | 防守军团 | `CrossUnionPkKnockoutScene.lua:225` |
| `win` | boolean | 是否取胜（决定胜负图标） | `CrossUnionPkKnockoutScene.lua:266-269` |

`getGvgKnockoutInfo` 响应：`sixteen`（16强，数组）、`eight`（8强，数组）、`four`（4强，数组）、
`championBattle`（冠军赛，对象）、`thirdPlaceBattle`（季军赛，对象）
（`canon/features/crossUnionPk/request/CrossUnionPkGetKnockoutInfoRequest.lua:10-14`；
`CrossUnionPkKnockoutScene.lua` 里按 knockoutType 分组渲染）。
客户端在 debug 下断言 `championBattle ~= nil`（`...GetKnockoutInfoRequest.lua:98`）。

### 21.3 `UnionIdentification`（军团标识）

- **原厂注释版 schema**：`canon/features/crossUnionPk/request/CrossUnionPkGetKnockoutInfoRequest.lua:125-129`
  与 `CrossUnionPkGetGroupReportsRequest.lua:117-121`

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `serverId` | 数字 | 区服（显示「N区」） | `canon/features/crossUnionPk/scene/CrossUnionPkKnockoutScene.lua:170` |
| `unionId` | 数字 | 军团 id | `CrossUnionPkGetKnockoutInfoRequest.lua:127` |
| `unionName` | 字符串 | 军团名 | `CrossUnionPkKnockoutScene.lua:171` |

---

## 22. `ApplicantGvgUserInfo`（跨服 GVG 报名玩家项 = `getCrossGvgInfo.signs[]`）

- **类型**：**数组**（`ipairs`、`pairs`、`for k,v in pairs`）
- **原厂注释版 schema**：`canon/features/crossUnionPk/request/GetCrossGvgInfoRequest.lua:121-132`
  （注释形式列出字段），另有完整假数据 `:144-188`
- **出现接口**：`getCrossGvgInfo` → `signs`
- **客户端写入**：`CrossUnionPkData.setAllSignedMenbers` → 本地改 `position` 后上传
  （`canon/features/crossUnionPk/manager/CrossUnionPkData.lua:94-100,143-226`）

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `uid` | 数字(long) | 主键；判「是不是我」；上阵队列 | `canon/features/crossUnionPk/manager/CrossUnionPkData.lua:154,177,255`；`canon/features/crossUnionPk/request/GetCrossGvgInfoRequest.lua:89` |
| `userName` | 字符串 | 显示昵称 | `canon/features/crossUnionPk/scene/CrossUnionPKTeamAdjustScene.lua:606,688`；`CrossUnionPkMemberSelectScene.lua:188` |
| `position` | 数字 | 上阵位置：`1`=先锋；`10-19`=阵首；`20-29`=阵中；`30-39`=阵尾；`0`=未上阵 | `canon/features/crossUnionPk/manager/CrossUnionPkData.lua:153-161,186-196`；`CrossUnionPKTeamAdjustScene.lua:549-551,562,581`；`CrossUnionPkMemberSelectScene.lua:245` |
| `mainCardMetaId` | 数字 | 头像卡 metaId（**跨服用 `MetaId`，unionPk 用 `MeataId`**） | `CrossUnionPKTeamAdjustScene.lua:605,666`；`CrossUnionPkMemberSelectScene.lua:176` |
| `level` | 数字 | 等级 | `CrossUnionPKTeamAdjustScene.lua:607`；`CrossUnionPkMemberSelectScene.lua:189` |
| `pkRank` | 数字 | 竞技场排名 | `CrossUnionPkMemberSelectScene.lua:191` |
| `fightCapacity` | 数字 | 战斗力 | `CrossUnionPkMemberSelectScene.lua:192` |
| `gemInspireNum` | 数字 | 该玩家金币鼓舞次数（角标） | `CrossUnionPKTeamAdjustScene.lua:687`；`CrossUnionPkData.lua:263` |
| `coinInspireNum` | 数字 | 该玩家银币鼓舞次数（客户端本地自增后会回传） | `CrossUnionPkData.lua:266`；`GetCrossGvgInfoRequest.lua:91` |
| `striveInspireNum` | 数字/boolean | 该玩家奋力一击次数（客户端本地自增；DSL 注释写 boolean，假数据写 `true`，但 `CrossUnionPkData.lua:268` 做 `+1` 算术 → **建议发数字**） | `CrossUnionPkData.lua:268`；`GetCrossGvgInfoRequest.lua:92,130,152` |
| `title` | 数字(枚举) | 职位 | `GetCrossGvgInfoRequest.lua:126`（声明） |

---

## 23. `getCrossGvgInfoBase` 的响应结构

- **出现接口**：`getCrossGvgInfoBase`
- **消费者**：`canon/features/crossUnionPk/CrossUnionPk.lua:146-149`、`canon/features/crossUnionPk/scene/CrossUnionPKLoginScene.lua:36-40`

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `unionApplyCrossGvg` | boolean | 我的军团是否已报名跨服 GVG | `canon/features/crossUnionPk/CrossUnionPk.lua:146`；`canon/manager/UnionManager.lua:1600-1603` |
| `selfApplyCrossGvg` | boolean | 我本人是否已报名 | `CrossUnionPk.lua:147`；`canon/manager/UnionManager.lua:1588-1591` |
| `crossGvgVersion` | 数字 | 跨服 GVG 版本号（届数） | `CrossUnionPk.lua:148`；`canon/manager/UnionManager.lua:1582-1585` |
| `selfQuitCrossGvg` | boolean | 我是否已退出跨服 GVG | `CrossUnionPk.lua:149`；`canon/manager/UnionManager.lua:1594-1597` |
| `groupId` | 数字 | 分组 id（0 = 未分组） | `canon/features/crossUnionPk/scene/CrossUnionPKLoginScene.lua:36,428` |
| `out` | 数字(枚举) | 淘汰状态（0/未报名/人数不足/四强/被淘汰/已晋级，见 `KnockoutType`） | `canon/features/crossUnionPk/scene/CrossUnionPKLoginScene.lua:37,456-491` |

> `getUserUnionInfo` 响应**顶层**也带一小组跨服字段（客户端写进 `gameInitData` 顶层，不在 `sharkUserUnion` 里）：

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `out` | 数字 | 淘汰状态 | `canon/request/UnionGetMyDataRequest.lua:60`；`canon/scene/UnionScene.lua:188` |
| `unionApplyCrossGvg` | boolean | 军团报名状态 | `canon/request/UnionGetMyDataRequest.lua:61` |
| `selfApplyCrossGvg` | boolean | 个人报名状态 | `canon/request/UnionGetMyDataRequest.lua:62` |
| `crossGvgVersion` | 数字 | 跨服版本号 | `canon/request/UnionGetMyDataRequest.lua:63` |
| `promotion` | boolean | 是否晋级淘汰赛 | `canon/request/UnionGetMyDataRequest.lua:64`；`canon/features/crossUnionPk/scene/CrossUnionPKBlessingScene.lua:260` |
| `selfQuitCrossGvg` | boolean | 是否已退出 | `canon/request/UnionGetMyDataRequest.lua:65` |
| `unionWarHintNum` | 数字 | 主界面军团战角标数（缺省 0） | `canon/request/UnionGetMyDataRequest.lua:69`；`canon/features/unionPk/manager/UnionPkData.lua:373-379` |
| `applyCrossGvgRemind` | boolean | 是否提醒报名（**客户端当前把这行注释掉了**，`:59`；实际提醒走 `crossGvgCanMindApply`） | `canon/request/UnionGetMyDataRequest.lua:59`；`canon/manager/UnionManager.lua:1606-1610` |

`getUserUnionInfo` 里 `unionWarHintNum` 用了 `or 0` 兜底（`:69`），其余字段直接 `set*`
—— `sharkUserUnion` 存在时**不返回这些跨服字段会导致 `gameInitData.out = nil`**，
后续 `CrossUnionPKLoginScene.lua:456` 的 `if self.argv.data.out == ...` 只是不成立，不会崩；
但 `CrossUnionPkCheck` 里若按 `out` 做枚举匹配会落到「啥都不显示」。建议全部下发。

---

## 24. `getCrossGVGBlessInfo`（祝福/至尊帝王）响应

- **出现接口**：`getCrossGVGBlessInfo`
- **消费者**：`canon/features/crossUnionPk/scene/CrossUnionPKBlessingScene.lua`（`argv.data`）
- **原厂注释版字段列表**：`canon/features/crossUnionPk/request/CrossUnionPkGetBlessInFoRequest.lua:94-101`
- **原厂假数据**：同文件 `:103-115`

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `king` | boolean | 是否是至尊帝王（决定祝福按钮状态） | `CrossUnionPKBlessingScene.lua:235` |
| `kingUid` | 数字(long) | 帝王 uid（点「激战回顾」跳阵容） | `CrossUnionPKBlessingScene.lua:175` |
| `mainCardMetaId` | 数字 | 帝王主将 metaId | `CrossUnionPKBlessingScene.lua:206` |
| `unionName` | 字符串 | 帝王所在军团名 | `CrossUnionPKBlessingScene.lua:213` |
| `serverId` | 数字 | 帝王所在服务器 | `CrossUnionPKBlessingScene.lua:215` |
| `nickname` | 字符串 | 帝王昵称（**小写 n**，与军团模块的 `nickName` 不同） | `CrossUnionPKBlessingScene.lua:221` |
| `blessNum` | 数字 | 当前已获得祝福次数 | `CrossUnionPKBlessingScene.lua:238,243` |
| `canBlessTimes` | 数字 | 剩余祝福次数（`<=0` 关闭按钮） | `CrossUnionPKBlessingScene.lua:18,252` |
| `promotion` | boolean | 是否晋级 | `CrossUnionPKBlessingScene.lua:260` |
| `gainGvgKnockoutReward` | boolean | 是否已领淘汰赛奖励 | `CrossUnionPKBlessingScene.lua:260` |

> `records.json` 里 `getCrossGVGBlessInfo` 的响应清单混入了 `unionApplyCrossGvg/selfApplyCrossGvg/
> crossGvgVersion/selfQuitCrossGvg` —— 那是同文件（`CrossUnionPk.lua`）里 `getCrossGvgInfoBase`
> 回调的字段，属于抽取工具的跨接口污染，**不是** `getCrossGVGBlessInfo` 的响应。

### 24.1 `blessForCrossGVG` / `gainGvgKnockoutReward` 的奖励结构

| 接口 | 响应字段 | 证据（文件:行号） |
|---|---|---|
| `blessForCrossGVG` | `rewards`（**数组**） | `CrossUnionPKBlessingScene.lua:109-110`；DSL `CrossUnionPkGetBlessRequest.lua:91` |
| `gainGvgKnockoutReward` | `rank`（数字）, `rewards`（**数组**） | `CrossUnionPKBlessingScene.lua:134-148` |

**`rewards[]` 元素（`Reward`）** ——原厂注释版 schema 在
`canon/features/crossUnionPk/request/CrossUnionPkGetBlessRequest.lua:99-104` 与
`CrossUnionPkGetKnockoutReward.lua:99-104`：

| 字段 | 类型 | 依据 |
|---|---|---|
| `itemType` | 数字 | 同注释 |
| `metaId` | 数字 | 同注释 |
| `id` | 数字 | 同注释 |
| `amount` | 数字(long) | 同注释 |
| `level` | 数字 | 同注释 |
| `exp` | 数字(long) | 同注释 |

（该 `Reward` 结构与全项目通用，客户端交给 `RewardManager:getReward` 统一处理。）

---

## 25. `getCrossGvgInfo` 的响应结构（跨服 GVG 主界面 / 阵型）

- **原厂注释版 schema**：`canon/features/crossUnionPk/request/GetCrossGvgInfoRequest.lua:5-11`
- **消费者**：`GetCrossGvgInfoRequest.onSucceedDefault`（`:79-100`）→ `CrossUnionPkData.setCrossGvgInfo`

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `version` | 数字 | 阵型版本号（上传阵型时回传，做乐观锁） | `canon/features/crossUnionPk/manager/CrossUnionPkData.lua:86-92,219` |
| `striveInspireNum` | 数字 | 奋力一击次数（被 `onSucceedDefault` 用「我」的 sign 值覆盖） | `GetCrossGvgInfoRequest.lua:86,92` |
| `coinInspireNum` | 数字 | 银币鼓舞次数（同上被覆盖） | `GetCrossGvgInfoRequest.lua:85,91` |
| `gemInspireNum` | 数字 | 金币鼓舞次数 | `canon/features/crossUnionPk/manager/CrossUnionPkData.lua:236-242` |
| `signs` | **数组** `ApplicantGvgUserInfo` | 报名玩家（见 §22） | `GetCrossGvgInfoRequest.lua:88`；`CrossUnionPkData.lua:94-100` |

**额外被读取但未被 DSL 注释声明的字段**（都存在 `_crossGVGTeamAdjustInfo` 上）：

| 字段 | 类型 | 客户端用途 | 证据（文件:行号） |
|---|---|---|---|
| `score` | 数字 | 我方军团积分（显示） | `canon/features/crossUnionPk/manager/CrossUnionPkData.lua:74-76`；`CrossUnionPKTeamAdjustScene.lua:335` |
| `challengeNum` | 数字 | 已挑战次数（算剩余次数 `wGVGTime - challengeNum`）。客户端进场景时先 `setChallengeNum(0)` 再等响应覆盖 | `CrossUnionPkData.lua:102-108`；`CrossUnionPKTeamAdjustScene.lua:31,369` |
| `teamMirrorRemind` | boolean | 是否需要上传阵容镜像（点亮保存按钮）；`uploadCrossGvgTeamMirror` 成功后置 false | `CrossUnionPkData.lua:110-112,130-132`；`CrossUnionPKTeamAdjustScene.lua:88,277`；`canon/features/crossUnionPk/panel/CrossUnionPkUpdatePanel.lua:51` |
| `groupChallengedRemind` | boolean | 小组赛战报有更新（红点）；`getCrossGvgGroupReports` 成功后置 false | `CrossUnionPkData.lua:114-120`；`CrossUnionPKTeamAdjustScene.lua:282`；`CrossUnionPkGetGroupReportsRequest.lua:91` |

---

## 26. 原厂 `<bean>` / `<response>` 注释里的 schema（配置表侧，可信度最高）

这些是**客户端本地配置表**的结构（服务端不下发，但可用于校验自建服务端的配置镜像；
`DataManager.GameMetaData.*` 由服务端随 gameInit 下发 —— 见 §29 备注）。

| 结构 | 类型 | 字段 | 证据（文件:行号） |
|---|---|---|---|
| `UnionWarTimeMeta`（军团战时间配置） | list | `id`, `warBeginTime`, `warContinueTime` | `canon/features/unionPk/manager/UnionPkConfig.lua:364-370` |
| `interUnionWarTimeMeta`（跨服军团战时间配置） | list | `id`, `warBeginTime`, `warContinueTime` | `canon/features/crossUnionPk/manager/CrossUnionPkConfig.lua:57-62` |
| `CityNpcGroup`（城池 NPC 防守怪物组） | list | `id`（城池类型）, `monsterGroupId` | `canon/features/unionPk/manager/UnionPkConfig.lua:107-112` |
| `UnionWarBuff`（团战 buff） | list | `id`(1单挑普通胜/2单挑大胜/3阵首/4阵中/5阵尾), `attBuff`, `defBuff`, `hpBuff` | `canon/features/unionPk/manager/UnionPkConfig.lua:117-123` |
| 城池报名限制配置 | list | `cityId`(城池类型 id), `signUpLevel`(军团等级限制), `signUpStrength`(军团战斗力限制) | `canon/features/unionPk/manager/UnionPkConfig.lua:211-216` |
| 斗兽奖励分配配置 | list | `serverMin`, `serverMax` | `canon/features/unionPk/manager/UnionPkConfig.lua:260-266` |
| `UnionWarRewardMeta`（军团战奖励） | dic | `cityId`, `dailyProfit1/2/3`, `cityOccupyReward` | `canon/features/unionPk/manager/UnionPkConfig.lua:302-310` |
| 军团战军团胜利次数 | （运行时） | `cityId`, `winNum` | `canon/features/unionPk/manager/UnionPkData.lua:56-59` |
| 城池信息 `sharkUnionCity` | （协议） | 见 §12 | `canon/features/unionPk/manager/UnionPkCityData.lua:8-20` |
| `UnionMonsterReward`（斗兽奖励分配项） | （协议） | `uid`(long), `amount`(int) | `canon/request/UnionColosseumAllocateRequest.lua:39-42`；`UnionColosseumStartAllocationRequest.lua:57-60` |
| `UnionMonsterDamage`（斗兽伤害值） | （协议） | `uid`(long), `nickName`(string), `totalDamage`(int) | `canon/request/UnionColosseumGetRankRequest.lua:53-57` |
| `SharkUnionMonster`（军团怪兽信息） | （协议） | 见 §8 | `canon/request/UnionColosseumBuildingInfoRequest.lua:53-57` |
| `Reward`（通用奖励） | （协议） | `itemType`, `metaId`, `id`, `amount`, `level`, `exp` | `canon/features/crossUnionPk/request/CrossUnionPkGetBlessRequest.lua:99-104` |
| `CrossGVGScoreInfo` | （协议） | `unionId`, `unionName`, `score`, `rank` | `canon/features/crossUnionPk/request/CrossUnionPkGetGroupRankScoreRequest.lua:16-21` |
| `GVGReport` | （协议） | `uuid`, `attUnionName`, `defUnionName`, `win` | `canon/features/crossUnionPk/request/CrossUnionPkGetGroupReportsRequest.lua:14-19` |
| `CrossGvgResultOutline` | （协议） | `id`, `attUnion`, `defUnion`, `win` | `canon/features/crossUnionPk/request/CrossUnionPkGetKnockoutInfoRequest.lua:18-23` |
| `UnionIdentification` | （协议） | `serverId`, `unionId`, `unionName` | `canon/features/crossUnionPk/request/CrossUnionPkGetKnockoutInfoRequest.lua:125-129` |
| `ApplicantGvgUserInfo` | （协议） | `uid`, `userName`, `mainCardMeataId`, `title`, `level`, `pkRank`, `fightCapacity`, `striveInspireNum`, `gemInspireNum`, `coinInspireNum`(+`position`) | `canon/features/crossUnionPk/request/GetCrossGvgInfoRequest.lua:123-132`、`:144-188` |
| `BattleCardInitData` / `BattleEvent` | （协议） | 全项目通用战斗结构（本任务不展开） | `canon/request/UnionColosseumChallengeRequest.lua:52-53` |

---

## 27. 接口 → 结构 对照表

「读」= 客户端实际读取该响应字段；「只发」= 请求/响应为空或客户端不读响应。

> **数量校正**：任务书写「军团有 52 个客户端接口」。按
> endpoint 名 + 类名 + 所属文件路径三重筛选（`Union` / `unionPk` / `crossUnionPk` / `Colosseum` / `GVG`），
> `records.json` 里实际命中 **69 个**（含 `getCrossGVGKnockoutStauts`、`gainGvgKnockoutReward`
> 两个 `records.json` 未收录、但客户端确有 request 类的接口）。下表 69 条即全量。

| # | endpoint | 请求参数 | 响应结构（客户端读取） |
|---|---|---|---|
| 1 | `getUserUnionInfo` | — | `sharkUserUnion`(§2)、`out`/`unionApplyCrossGvg`/`selfApplyCrossGvg`/`crossGvgVersion`/`promotion`/`selfQuitCrossGvg`(§23)、`unionWarHintNum` |
| 2 | `getUnionInfo` | — | `sharkUnion`(§1)、`sharkUnionBuildingWrapper`(§3)、`unionMonsterHp`、`unionMonsterEscapeSeconds`、`canDistributeMonsterReward`、`unionWarLightOn`、`unionTotalFightCapacity` |
| 3 | `getUnionList` | `startNum`, `amount` | `sharkUnionWrappers`(§4) |
| 4 | `searchUnion` | `unionName` | `sharkUnionWrappers`(§4) |
| 5 | `getAppliedUnions` | — | `sharkUnionWrappers`(§4) |
| 6 | `createUnion` | `coinType`, `unionName`, `declaration`, `notice` | `sharkUnion`(§1，用 `unionId`) |
| 7 | `dissolveUnion` | — | `sharkUnion`(§1)、`sharkUserUnion`(§2) |
| 8 | `quitUnion` | — | `sharkUserUnion`(§2) |
| 9 | `cancelDissolveUnion` | — | 只发 |
| 10 | `applyUnion` | `unionId` | 只发 |
| 11 | `cancelUnionApply` | `unionId` | 只发 |
| 12 | `getUnionMembersList` | — | `sharkUnionMemberWrappers`(§5) |
| 13 | `getUnionAppliers` | — | `sharkUnionAppliers`(§6) |
| 14 | `acceptUnionApply` | `applierUid` | 只发 |
| 15 | `rejectUnionApply` | `applierUid` | 只发 |
| 16 | `rejectUnionAllApplies` | — | 只发 |
| 17 | `forceQuitUnion` | `quitUid` | 只发 |
| 18 | `appointUnion` | `appointUid`, `title` | 只发 |
| 19 | `transferUnion` | `transferedUid` | `transferTime`(数字) |
| 20 | `cancelTransferUnion` | — | 只发 |
| 21 | `impeachUnionManager` | — | `currManagerNickName`(字符串) |
| 22 | `modifyUnionNotice` | `notice` | 只发 |
| 23 | `modifyUnionDeclaration` | `declaration` | 只发 |
| 24 | `constructUnion` | `constructType` | 只发 |
| 25 | `upgradeUnionBuilding` | `unionBuildingId` | `currLevel`(数字) |
| 26 | `getUnionBuildingHallInfo` | — | `lastestConstructSeconds`、`constructTimesToday`、`unionHallLevel`、`unionWealth`、`donateAnnouncement[]`(§9) |
| 27 | `getUnionBuildingShopInfo` | — | `level`、`specialProps[]`、`specialShopRecord[]`(§10) |
| 28 | `buyUnionProp` | `unionPropType`, `unionPropId` | `rewards[]`(通用 Reward)、`retCode` |
| 29 | `getUnionBuildingBankInfo` | — | `level`(§11) |
| 30 | `receiveUnionWage` | `unionWageId` | `rewards[]`(通用 Reward) |
| 31 | `getUnionNewsList` | — | `sharkUnionNewsWrappers[]`、`unionWarNewsWrappers[]`(§7) |
| 32 | `getUnionBuildingColosseumInfo` | — | `level`、`summonTimes`、`rankList[]`(§17.2)、`unionWealth`、`sharkUnionMonster`(§8) |
| 33 | `summonUnionMonster` | `monsterMetaId`, `summonType` | `sharkUnionMonster`(§8，无保护必发) |
| 34 | `challengeUnionMonster` | — | `win`、`damage`、`cardInitDatas[]`、`eventFlow[]`、`generalExp`(进 BattleScene) |
| 35 | `getUnionMonsterRank` | — | `rankList[]`(§17.2) |
| 36 | `unionMonsterRewardDistributeBegin` | — | `currMonsterRewards[]`(§17 风格的 `{uid,amount}` 数组) |
| 37 | `unionMonsterRewardDistributeSave` | `unionMonsterRewards[]`({uid,amount}) | 只发 |
| 38 | `unionMonsterRewardDistributeGiveUp` | — | 只发 |
| 39 | `getUnionCityList` | — | `ownCityIds[]`、`smallCityNum`、`roundWealth`、`userTitle`、`challengeCityIds[]`、`fightingCityIds[]`、`unionWinNum[]`(§17.1)、`attendBattleNum`(§16) |
| 40 | `getUnionCityInfo` | `unionCityId` | `sharkUnionCity`(§12)、`inBattle`、`firstBattleFailed` |
| 41 | `applyUnionCity` | `unionCityId` | 只发（客户端本地 `addSignedCity`） |
| 42 | `userApplyUnionCity` | `unionCityId` | 只发（客户端本地 `setChallengeCityId`） |
| 43 | `getApplyUnions` | `unionCityId` | `sharkUnionCityApply[]`(§13) |
| 44 | `getUnionFormation` | `unionCityId` | `sharkUnionCityApply[]`、`winnerUnionCityApply[]`、`loserUnionCityApply[]`、`unionFormation`(§14/§15) |
| 45 | `exchangeUnionFormation` | `unionCityId`, `forwardUid`, `headUids[]`, `middleUids[]`, `tailUids[]` | 只发 |
| 46 | `getUnionWarCityMembersList` | `cityId` | `sharkUnionMemberWrappers`(§5) |
| 47 | `inspireUnionBattle` | `unionCityId`, `buffId` | 只发 |
| 48 | `getOwnUnionInfo` | — | `battleCityIds[]`(数字数组) |
| 49 | `getUnionBattlefieldReportList` | `unionCityId` | `unionBattlefieldReportSummarys[]`(§18) |
| 50 | `getUnionBattlefieldReport` | `unionCityId`, `reportId` | `sharkUnionBattlefieldReport`(§19) + `currPoints`/`changePoints` |
| 51 | `gainUnionBattleReward` | `rewardId` | `rewards[]`(通用 Reward) |
| 52 | `getCrossGvgInfoBase` | — | `unionApplyCrossGvg`、`selfApplyCrossGvg`、`crossGvgVersion`、`selfQuitCrossGvg`、`groupId`、`out`(§23) |
| 53 | `getCrossGvgInfo` | — | `version`、`striveInspireNum`、`coinInspireNum`、`gemInspireNum`、`signs[]`(§22) + `score`/`challengeNum`/`teamMirrorRemind`/`groupChallengedRemind`(§25) |
| 54 | `applyCrossGvg` | `type` | 只发 |
| 55 | `crossGvgCanMindApply` | — | `applyCrossGvgRemind`(boolean) |
| 56 | `exchangeGvgFormation` | `override`,`unionId`,`serverId`,`version`,`forwardUid`,`headUids[]`,`middleUids[]`,`tailUids[]` | 只发 |
| 57 | `uploadCrossGvgTeamMirror` | 无（`version` 由客户端从 `getCrossGvgInfo` 缓存补） | 只发 |
| 58 | `inspireCrossGvg` | `type` | 只发 |
| 59 | `getFiredUnionMemberStatus` | `firedUid` | `status`(数字 0可踢/1已报名/2已上阵) |
| 60 | `getCrossGvgGroupInfo` | — | `serverIds[]`(数字数组) |
| 61 | `getCrossGvgGroupTop10Score` | — | `selfScore`(§20)、`top10ScoreList[]`(§20) |
| 62 | `getCrossGvgGroupReports` | — | `reports[]`(§21.1) |
| 63 | `crossGVGGroupBattle` | （`groupId`/`serverId` 等，见 request） | `sharkUnionBattlefieldReport`(§19) + `changePoints`、`currPoints` |
| 64 | `getGvgBattleResultDetail` | `reportId`, `knockout` | `sharkUnionBattlefieldReport`(§19)（DSL 注释误写 `battleReport`） |
| 65 | `getGvgKnockoutInfo` | — | `sixteen[]`、`eight[]`、`four[]`、`championBattle`、`thirdPlaceBattle`(§21.2) |
| 66 | `getCrossGVGKnockoutStauts` | — | 只发（客户端未读响应） |
| 67 | `getCrossGVGBlessInfo` | — | `king`、`kingUid`、`mainCardMetaId`、`unionName`、`serverId`、`nickname`、`blessNum`、`canBlessTimes`、`promotion`、`gainGvgKnockoutReward`(§24) |
| 68 | `blessForCrossGVG` | — | `rewards[]`(通用 Reward) |
| 69 | `gainGvgKnockoutReward` | — | `rank`(数字) + `rewards[]`(通用 Reward) |

**当前自建服务端状态**（`server/canon_server.py:2615-2618`）：只实现了 #1 且只回 `{hasUnion: False}`，
其余 68 个 endpoint 全部未实现。

---

## 28. 未能确认 / 存疑点

明确写出来，避免后续照抄猜测：

1. **`sharkUnionCity` 的 `userPosition` / `challengeCityNum` / `ownCityNum` / `applyNum`**
   —— 原厂 bean 声明了（`canon/features/unionPk/manager/UnionPkCityData.lua:13,16,17,18`），
   但全项目 grep 不到任何读取路径。**客户端实际未读**。是否下发不影响显示，建议照发不误。
2. **`getUnionCityInfo` 是否也返回 `unionFormation`**
   —— `records.json` 列出了它，但该条来自 `UnionPK.lua` 中 **另一个接口**
   （`UnionPkGetCityFormationRequest`）的回调，属抽取污染。
   `UnionPkCityInfoPopPanel` 的 `getUnionCityInfo` 回调只读 `sharkUnionCity`/`inBattle`/`firstBattleFailed`。
   **未确认**该接口是否真的带 `unionFormation`；不下发不会崩。
3. **`getUnionCityList` 是否也返回 `unionFormation`** —— 同上，是污染。未确认。
4. **`getGvgBattleResultDetail` 的 `battleReport` vs `sharkUnionBattlefieldReport`**
   —— DSL 注释写 `battleReport`，代码读 `sharkUnionBattlefieldReport`（`canon/scene/BattleScene.lua:130`）。
   **以代码为准**，但两种 key 都发是最稳妥的（客户端不会因为多一个 key 而崩）。
5. **`ApplicantGvgUserInfo.striveInspireNum` 的语义** ——
   DSL 注释写 `boolean`（`GetCrossGvgInfoRequest.lua:130`），假数据写 `true`（`:152,167,182`），
   但 `CrossUnionPkData.lua:268` 做 `+1` 算术。**建议发数字 0/1**。
   同理 `coinInspireNum`/`gemInspireNum` 注释与假数据都写 int，无歧义。
6. **`unionWarNewsWrappers[].detail` 里城池 id 列表的类型** ——
   原厂假数据写成 JSON 数组（`UnionPkTest.lua:180`），读取代码却调 `:split(",")`
   （`UnionNewsListPanel.lua:210,216`）。**以读取代码为准：逗号分隔字符串**。
7. **`sharkUserUnion.lastestConstructType`** —— 客户端在成员列表项上读（§5），
   在自己身上没有读取路径。是否随 `sharkUserUnion` 下发未确认。
8. **`unionFormation` 各分阵最多几人** —— 由客户端本地配置决定
   （`UnionPkConfig.cityFrontLimit/cityMidLimit/cityLastLimit`，
   `canon/features/unionPk/manager/UnionPkConfig.lua:148-165`），
   服务端需与 `GameMetaData.unionWarSettingConfig` 镜像保持一致，否则会显示空位/越界。
9. **`getCrossGVGKnockoutStauts`（endpoint `getCrossGVGKnockoutStauts`）** ——
   客户端有 request 类但**没有任何调用点**（`records.json` 里也没有它）。
   未确认是否线上真在用。

---

## 29. 服务端建表建议

### 29.1 与现有 `server/schema.sql` 的关系

`server/schema.sql:756-906` **已经有一版军团表**（`guild` / `guild_member` / `guild_apply` /
`guild_building` / `guild_news` / `guild_monster` / `guild_city` / `guild_city_apply` /
`guild_battle_report` / `guild_war_formation` / `guild_score`）。
下面按本次分析结果给出**补充与修正**，不推翻既有命名（`guild_*`），只补缺列/缺表。

### 29.2 `guild`（已有，补列）

| 列 | 类型 | 对应客户端字段 | 说明 |
|---|---|---|---|
| `guild_id` | INTEGER PK | `unionId` | 已有 |
| `server_id` | INTEGER | — | 已有，军团按服分域 |
| `name` | TEXT | `sharkUnionWrappers[].name` / `sharkUserUnion.unionName` | 已有 |
| `declaration` | TEXT | `sharkUnion.declaration` | 已有 |
| `notice` | TEXT | `sharkUnion.notice` | 已有 |
| `level` | INTEGER | `sharkUnion.level` / `buildingHallLevel` | 已有（**建议与 `guild_building` 的 hall 行严格同源，避免两处不一致**） |
| `wealth` | INTEGER | `sharkUnion.wealth` / `unionWealth` | 已有 |
| `leader_uid` | INTEGER | `sharkUnion.managerId` | 已有 |
| `transfer_uid` | INTEGER | `sharkUnion.nextManagerId` | 已有 |
| `transfer_time` | INTEGER | `sharkUnion.transferTime` | 已有 |
| `dissolve_time` | INTEGER | `sharkUnion.unbandTime` | 已有 |
| `status` | INTEGER | `sharkUnion.status` | 已有（0正常/1解散/2转让中） |
| **`member_num`** | INTEGER | `sharkUnion.memberNum` | **建议显式落列并随成员增删维护**（客户端每帧读，且 `getUnionMembersList` 会用 `#数组` 覆写成本地值） |
| **`rank`** | INTEGER | `sharkUnionWrappers[].rank` | **建议落列**（按 wealth 排序时批算，或每轮定时刷新）；`-1` 表示未上榜 |
| `cross_gvg_applied` / `cross_gvg_version` | INTEGER | `unionApplyCrossGvg` / `crossGvgVersion` | 已有 |
| **`union_war_version`** | INTEGER | `sharkUserUnion.unionWarVersion` | 建议加（本服军团战届数） |
| **`union_war_round`** | INTEGER | `sharkUserUnion.unionWarRound` | 建议加 |
| **`union_war_light_on`** | INTEGER | `unionWarLightOn` | 建议加（军团战呼吸灯，见 §27 #2） |
| **`total_fight_capacity`** | INTEGER | `unionTotalFightCapacity` | 建议加（报名城池时的战力门槛判定，窗口期外可缓存） |
| `data_json` | TEXT | 杂项 | 已有，建议只放真正的杂项，别把上面这些塞进去 |

### 29.3 `guild_member`（已有，补列）

| 列 | 类型 | 对应客户端字段 |
|---|---|---|
| `guild_id` + `player_id` | PK | — |
| `title` | INTEGER | `sharkUserUnion.title` / `sharkUnionMemberWrappers[].title` |
| `join_time` | INTEGER | `sharkUserUnion.joinSeconds` |
| `contrib_total` | INTEGER | `hisContribute` |
| `contrib_week` / `contrib_day` | INTEGER | `contribute`（客户端按周/日重置口径需与服务端一致） |
| **`status`** | INTEGER | `sharkUserUnion.status`（0成员/1主动退/2被踢/3解散）；**退团后不要立即删行**，客户端靠 `status` + `dissolvedSeconds` 判「还在解散/退出流程中」 |
| **`reactive_time`** | INTEGER | `sharkUserUnion.reactiveSeconds`（入团冷却结束时刻，0=无冷却） |
| **`dissolved_time`** | INTEGER | `sharkUserUnion.dissolvedSeconds` |
| **`last_construct_time`** | INTEGER | `sharkUserUnion.lastestConstructSeconds` + 成员项 `lastestConstructSeconds` |
| **`last_construct_type`** | INTEGER | 成员项 `lastestConstructType`（0无/1银币/2金币1/3金币3） |
| **`last_active_time`** | INTEGER | 成员项 `lastestActiveSeconds`（离线时长显示 + 弹劾判定） |
| **`online`** | INTEGER | 成员项 `online`（可由 session 表实时推导，但落列更简单） |
| **`challenge_city_id`** | INTEGER | `sharkUserUnion.challengeCityId`（我报名的城池，0=未报名） |
| **`coin_inspire_num`** | INTEGER | `coinInspireNum` |
| **`strive_inspire_num`** | INTEGER | `striveInspireNum` |
| **`gem_inspire_num`** | INTEGER | `gemInspireNum` |
| **`gain_war_play` / `gain_war_occupy` / `gain_war_in_battle`** | INTEGER(0/1) | `gainUnionWarPlayReward` / `gainUnionWarOccupyReward` / `gainUnionWarInBattleReward` |
| `last_wage_time` / `quit_cd_time` | INTEGER | 已有 |
| **`arena_rank_snapshot` / `fight_capacity_snapshot` / `main_card_id` / `nickname_snapshot` / `level_snapshot`** | — | 成员项 `arenaRank` / `fightCapacity` / `mainCardId` / `nickName` / `level` |
| **`cross_gvg_applied` / `cross_gvg_quit`** | INTEGER(0/1) | `selfApplyCrossGvg` / `selfQuitCrossGvg` |
| **`gvg_position`** | INTEGER | `ApplicantGvgUserInfo.position`（1先锋/10-19阵首/20-29阵中/30-39阵尾/0未上阵） |
| **`gvg_team_mirror_version`** | INTEGER | 阵容镜像版本（`getCrossGvgInfo.version` 的乐观锁依据） |

> 说明：`arenaRank` / `fightCapacity` / `nickName` / `level` / `mainCardId` 都是从 `player` 表
> join 得来的**冗余**。是否落列取决于组装层能不能一次 join 出来；若组装层已经一次性 join，
> 就不必落列，但**响应里必须齐**（缺 `arenaRank` 只会显示空，缺 `fightCapacity` 同理）。

### 29.4 `guild_apply`（已有，基本够用）

| 列 | 说明 |
|---|---|
| `apply_id`, `guild_id`, `player_id`, `status`, `apply_time`, `handle_time` | 已有 |
| **返回给客户端的 `sharkUnionAppliers[]` 需要**：`uid`, `nickName`, `level`, `mainCardMetaId`, `arenaRank`, `fightCapacity` —— 全部可由 `player` 表 join；`mainCardMetaId` 对应玩家主卡 |

> ⚠ **字段名陷阱**：申请者用 `mainCardMetaId`（§6），成员用 `mainCardId`（§5）。
> 组装层如果复用同一个 mapper 会写错，建议分开两个 assembler 函数。

### 29.5 `guild_building`（已有，基本够用）

| 列 | 说明 |
|---|---|
| `guild_id`, `building_id`, `level` | 已有。`building_id` ∈ {1大厅,2商城,3钱庄,4斗兽场} |
| `construct_times_today`, `last_construct_seconds` | 已有（对应 §9 的 `constructTimesToday` / `lastestConstructSeconds`） |
| **`donate_announcement_json`** | **建议加**：§9 的 `donateAnnouncement[]`（`{nickname, donateNum}`，最多 10 条）。
或者另建 `guild_donate_log` 表按时间倒序取 10 条——后者更规范 |

### 29.6 `guild_shop_record`（**新表，建议**）

§10 需要 `specialShopRecord`（已购商品 id 列表，按日/周重置），现有 schema 没覆盖。

| 列 | 类型 | 说明 |
|---|---|---|
| `guild_id` | INTEGER | FK → guild |
| `shop_type` | INTEGER | 1普通 / 2特殊 |
| `prop_id` | INTEGER | 商品配置 id |
| `bought_num` | INTEGER | 已购数量 |
| `reset_time` | INTEGER | 下次重置时刻（日/周） |
| PK | `(guild_id, shop_type, prop_id)` | |

> `getUnionBuildingShopInfo.specialProps[].leftNum` 是**算出来的**
> （`dailyPurchaseLimit - 已购`，参照 `UnionManager.getShopNormalInfoList`，`:2468-2499`），
> 不要把 `leftNum` 直接落库。

### 29.7 `guild_monster` / `guild_monster_damage` / `guild_monster_allocate`（斗兽场）

`guild_monster` 已有，字段基本对得上 §8：

| 已有列 | 客户端字段 |
|---|---|
| `monster_id` | `sharkUnionMonster.monsterId` |
| `monster_left_hp` | `sharkUnionMonster.monsterLeftHp` |
| `escape_seconds` | `sharkUnionMonster.escapeSeconds`（**时间戳**，客户端 +3 秒后与 `now` 比） |
| `summon_times` | `getUnionBuildingColosseumInfo.summonTimes` |
| `summon_user_nickname` | `summonUserNickname` |
| `reward_double` | `rewardDouble` |
| `distributing_uid` | `distributingUid` |
| `reward_distributed` | `rewardDistributed` |
| `reward_json` | **`sharkUnionMonster.reward.amount`**（建议改成 `reward_amount INTEGER`，因为客户端只要 `amount` 一个数，JSON 是过度设计） |

**补 2 张表**：

`guild_monster_damage`（伤害榜 = §17.2 `rankList`）

| 列 | 类型 |
|---|---|
| `guild_id` | INTEGER |
| `monster_id` | INTEGER（同一 guild 多次召唤要做轮次隔离） |
| `player_id` | INTEGER |
| `nick_name` | TEXT（快照，避免 join） |
| `total_damage` | INTEGER |
| PK | `(guild_id, monster_id, player_id)` |

`guild_monster_allocate`（奖励分配 = §26 的 `UnionMonsterReward`）

| 列 | 类型 | 说明 |
|---|---|---|
| `guild_id` | INTEGER | |
| `monster_id` | INTEGER | |
| `player_id` | INTEGER | `uid` |
| `amount` | INTEGER | `amount` |
| `week_get_num` | INTEGER | 本周已领数（客户端本地 `colosseumWeeklyGiftGetNumHash`，
`unionMonsterRewardDistributeBegin` 会下发 `currMonsterRewards[]` 重建） |
| PK | `(guild_id, monster_id, player_id)` | |

### 29.8 `guild_city` / `guild_city_apply`（军团战城池）

`guild_city` 已有；对照 §12 需要：

| 已有列 | 客户端字段 |
|---|---|
| `city_id` | `sharkUnionCity.cityId` |
| `owner_guild_id` | `sharkUnionCity.unionId`（0 = NPC 守军） |
| `owner_union_name` | `sharkUnionCity.unionName` |
| `capture_times` | `sharkUnionCity.occupyNum`（**连续**占领次数，被攻下要清零） |
| `round` | 当前轮次 |
| **补 `owner_guild_level`** | `sharkUnionCity.unionLevel`（客户端确实读，§12） |

`guild_city_apply` 已有，但需补：

| 列 | 类型 | 说明 |
|---|---|---|
| `city_id`, `guild_id`, `apply_time` | 已有 | |
| **`bid_wealth`** | INTEGER | **§13 的 `wealth`** —— 报名时投入的财富，竞标排序依据 |
| **`bid_rank`** | INTEGER | 竞标名次（1/2 有攻打资格，`[1]`=守方 `[2]`=攻1 `[3]`=攻2） |
| **`is_winner`** | INTEGER | `winnerUnionCityApply` / `loserUnionCityApply` 的依据 |
| **`apply_type`** | INTEGER | 已有；区分「军团竞标」vs「团员报名」 |

### 29.9 `guild_formation`（军团战阵型 = §14/§15）

现有 `guild_war_formation` 是「按玩家」存的，但客户端要的是「按位置」的分阵数组 + 一个先锋。
**建议改成两张表**：

`guild_formation_slot`（城池 × 阵位 × 玩家）

| 列 | 类型 | 说明 |
|---|---|---|
| `city_id` | INTEGER | 军团战按城池各自一份阵型（`getUnionFormation` 的入参是 `unionCityId`） |
| `guild_id` | INTEGER | |
| `slot` | TEXT | `'forward'` / `'head'` / `'middle'` / `'tail'` |
| `slot_index` | INTEGER | 分阵内序号（决定数组顺序） |
| `player_id` | INTEGER | `uid` |
| `user_name` | TEXT | `userName`（快照） |
| `main_card_meata_id` | INTEGER | **`mainCardMeataId`**（原厂拼写，列名照抄避免组装层手滑） |
| `gem_inspire_num` | INTEGER | 该成员在这座城池的金币鼓舞次数 |
| PK | `(city_id, guild_id, slot, slot_index)` | |

`guild_formation_team`（城池 × 军团的鼓舞总数）

| 列 | 类型 | 说明 |
|---|---|---|
| `city_id` + `guild_id` | PK | |
| `gem_inspire_num` | INTEGER | `unionFormation.gemInspireNum`（**军团级**总次数，与成员级同名不同义！） |
| `version` | INTEGER | 阵型版本号 |
| `update_time` | INTEGER | |

### 29.10 `guild_news`（动态，已有；补列）

| 列 | 类型 | 客户端字段 |
|---|---|---|
| `news_type` | INTEGER | 已有；对应 `unionWarNewsWrappers` 与 `sharkUnionNewsWrappers` 的**区分**（客户端自己写 `newsType=1/2`，服务端只需分表/分列） |
| `actor_uid` | INTEGER | `senderUid` |
| `actor_name` | TEXT | `senderNickname` |
| **`actor_level`** | INTEGER | `senderLevel` |
| **`actor_main_card_id`** | INTEGER | `mainCardId` |
| **`type`** | INTEGER | `type`（1..12 普通 / WAR_NEWS_TYPE_* 军团战） |
| `content` | TEXT | **`detail`（JSON 文本）** |
| `create_time` | INTEGER | `createTime` |

### 29.11 跨服军团战新表（**现有 schema 未覆盖**）

| 表 | 用途 | 关键列 |
|---|---|---|
| `cross_gvg_group` | 服务器分组（`getCrossGvgGroupInfo.serverIds[]`） | `group_id`, `server_id`, `version`；PK `(group_id, server_id)` |
| `cross_gvg_apply` | 军团/个人报名（`getCrossGvgInfoBase`） | `guild_id`, `version`, `union_applied`, `applied_num`, `quit_num`, `out_status`（`out` 枚举）, `promotion` |
| `cross_gvg_score` | 小组赛积分（`CrossGVGScoreInfo`：`getCrossGvgGroupTop10Score` 的 `selfScore`/`top10ScoreList`） | `guild_id`, `version`, `score`, `rank`, `union_name`（快照） |
| `cross_gvg_formation` | 阵型镜像（`signs[].position` + `exchangeGvgFormation`） | `guild_id`, `version`, `player_id`, `position`(1/10-19/20-29/30-39), `main_card_meta_id`, `user_name`(快照) |
| `cross_gvg_gvg`（或复用 `guild_battle_report`） | 小组赛/淘汰赛战报（`GVGReport` / `CrossGvgResultOutline`） | `report_id`, `version`, `round_type`(16/8/4/third/champion/group), `att_guild_id`, `att_server_id`, `att_union_name`, `def_guild_id`, `def_server_id`, `def_union_name`, `win`, `report_json`(整块存 `sharkUnionBattlefieldReport`), `create_time` |
| `cross_gvg_bless` | 祝福/帝王（`getCrossGVGBlessInfo`） | `version`, `king_uid`, `king_player_id`, `king_union_name`, `king_server_id`, `king_nickname`, `king_main_card_meta_id`, `bless_num`, `can_bless_times`（`king`/`promotion`/`gainGvgKnockoutReward` 可由其他表推导） |
| `cross_gvg_bless_log` | 每次祝福记录 + 奖励 | `player_id`, `version`, `reward_json`, `create_time` |

### 29.12 组装层注意事项（来自本次分析的坑）

1. **`sharkUnionMonster.reward.amount` 必须存在**，且 `reward` 是对象不是数组
   （客户端 `...BuildingInfoRequest.lua:81` 直接取 `.reward.amount`）。
2. **`sharkUnionCityApply` 至少 1 个元素**，`[1]` 必须是防守方（NPC 也要占位），
   `[2]`/`[3]` 是进攻方（可能缺）；`winnerUnionCityApply` / `loserUnionCityApply`
   **要发空数组而不是 nil**（客户端 `cityFormationData.loserUnionCityApply[1]`，`UnionPkCityPowerupPopPanel.lua:238`）。
3. **数组字段一律不要用 nil 代替空数组**：`sharkUnionWrappers`、`sharkUnionMemberWrappers`、
   `sharkUnionAppliers`、`sharkUnionNewsWrappers`、`unionWarNewsWrappers`、
   `ownCityIds`、`challengeCityIds`、`fightingCityIds`、`unionWinNum`、`specialProps`、
   `specialShopRecord`、`donateAnnouncement`、`signs`、`reports`、`top10ScoreList`、
   `sixteen/eight/four`、`unionBattleCardDatas`、`unionBattleRounds`、`rewards`、
   `unionBattlefieldReportSummarys`、`battleCityIds`、`currMonsterRewards`、`rankList`。
4. **数组字段也不能用 JSON 对象（dict）**：客户端用 `#x` 取长度、`ipairs` 遍历。
   若序列化成 `{...}` dict，Lua 侧 `#` 得 0，列表空白但不崩；
   若客户端改用 `x.key` 访问 dict 则会崩。**所以务必序列化成 JSON array**。
5. **字段名拼写必须逐字照抄**，本模块至少 4 组易错对：
   - `mainCardMeataId`（unionPk 阵型成员） vs `mainCardMetaId`（跨服 signs / 申请者） vs `mainCardId`（成员、动态）
   - `userName`（阵型成员 / signs） vs `nickName`（成员/申请者） vs `nickname`（帝王 / 动态 JSON）
   - `arenaRank`（成员/申请者）**不是** `areanaRank`
   - `nickName`（斗兽伤害榜，大写 N）
6. **`getUnionInfo` 的 `unionMonsterHp` / `unionTotalFightCapacity` 是 `tonumber()` 目标**，
   nil 会让 `UnionManager.setColosseumMonsterCurrentHp(nil)` → 后续 `<= 0` 比较直接报错。
   同接口的 `unionMonsterEscapeSeconds` 会进 `+ 3` 算术（`UnionManager.lua:2921`），
   **nil 必崩**（这一点 `server/canon_server.py:2581-2594` 的 `getHomeInfo` 注释已经踩过）。
7. **`sharkUserUnion` 存在时，`getUserUnionInfo` 的 7 个跨服顶层字段建议一起发**
   （`out`/`unionApplyCrossGvg`/`selfApplyCrossGvg`/`crossGvgVersion`/`promotion`/
   `selfQuitCrossGvg`/`unionWarHintNum`），否则跨服入口的按钮状态会全部走「未报名」分支。
8. **`GameMetaData` 侧的军团配置必须一并镜像**：
   `unionSettingConfig`（`UnionManager.getUnionConfig`，`:804-808`）、
   `union_building_hall/shop/bank/colosseum`（`:2160-2172`）、
   `union_shop_normal` / `union_shop_special`（`:2468-2503`）、
   `union_boss_meta`（`:2695-2706`）、
   `unionWarSettingConfig` / `unionWarRewardMeta` / `unionWarTimeMeta`（`UnionPkConfig`）、
   `wgvgTotalConfig` / `crossGvgTimeConfig` / `wgvgRewardConfig`（`CrossUnionPkConfig`）。
   这些不是本模块的 52 个接口，但缺了它们军团 UI 会空/报错
   （例如 `UnionPkConfig.cityFrontLimit()` 返回 0 会导致阵型界面不画格子，
   `UnionPkConfig.unionWarFeatureName()` 返回 nil 会导致 `MaintenanceManager` 报错）。
