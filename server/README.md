# 新服务端（SQLite 后端）

这是把原来的单文件 `user_state.json` 服务端迁到 **88 张表的 SQLite** 之后的版本。
旧的 `canon_server.py` 仍然能跑，用来对照。

---

## 快速开始

```bat
cd server

rem 1) 建库（首次必须跑；之后只在改了 schema.sql 时才需要 --force）
python init_db.py

rem 2) 起服务（HTTP :80 + TCP :9700）
python gameserver.py
rem 换端口：python gameserver.py --port 8080

rem 3) 另开一个终端，跑端到端测试（真的发协议，不是调函数）
python tests\test_client.py --port 8080
```

当前测试结果：**64 项全通过**（REST 链路 7 + RPC 链路 35 + 核心玩法 22）。
再跑一次跨重启验证：

```bat
python tests\test_client.py --port 8080 --device my-dev       rem 先建号
rem 重启服务端
python tests\test_client.py --port 8080 --device my-dev --existing
```

---

## 目录结构

```
server/
├── schema.sql           88 张表的 DDL（带中文注释与客户端字段对应关系）
├── canon.db              ← 数据库文件（init_db.py 生成）
├── init_db.py           建库 + 灌种子数据（分服表 / 公告 / 邮件模板 / id 序列）
├── db.py                连接池 / 事务 / 原子 id 分配 / 每日计数器
├── protocol.py          headercvt + zlib + AMF3 编解码（含客户端方向，测试用）
├── gamedata.py          静态配置门面（卡牌/道具/商店/抽卡/战斗/玩法设置）
├── meta_payload.py      getMeta 的响应构造（自动抽取自旧服务端，勿手改载荷）
├── assembler.py         表行 → 客户端 JSON（唯一允许出现 camelCase 的地方）
│
├── repository/          数据访问层（只认数据库，不认识客户端字段名）
│   ├── player.py        账号 / 会话 / 角色 / 扩展 / 计数器 / 每日
│   ├── asset.py         卡牌 / 技能 / 装备 / 道具 / 元神 / 宝物 / 阵容 / 阵法
│   ├── progress.py      关卡 / 场景 / 精英 / 通天塔 / 圣诞
│   ├── social.py        邮件 / 好友 / 邀请 / 红包 / 点赞 / 邀请码
│   └── guild.py         军团 / 成员 / 申请 / 建筑 / 动态 / 斗兽 / 城池
│
├── services/            业务层
│   ├── account.py       登录链路 / 会话 / 创角 / 新号初始资产
│   ├── player.py        等级 / 货币 / 体力精力恢复 / 钻石账本
│   ├── reward.py        ★ 奖励引擎（ResourceEnum → 各张表）
│   ├── asset.py         卡牌养成 / 装备强化 / 道具使用 / 商店 / 编队
│   ├── gacha.py         抽卡 + 保底计数 + 出货日志
│   └── mission.py       扫荡 / 章节事件 / 挑战 / 爬塔
│
├── api/                 路由层
│   ├── __init__.py      注册表 + 分发（替代原来的 if/elif 长链）
│   ├── handlers.py      第一批端点（登录/资产/抽卡/关卡/邮件/军团）
│   └── handlers_more.py 第二批端点（签到/充值/商店/好友/任务/跨服占位）
│
├── gameserver.py        入口：HTTP + REST + TCP
└── tests/test_client.py 协议级端到端测试
```

---

## 分层规矩（重要）

```
repository  只认数据库，不认识客户端字段名
service     业务规则；用 ctx.repos 读写，用 with db.tx() 划事务
assembler   只认客户端契约，不写 SQL
api         路由：取参数 → 调 service → 喂 assembler → 返回 dict
```

**任何在 repository 里写 camelCase 的地方都是 bug。** 客户端那堆历史包袱
（`nickname`/`nickName` 两种拼写、`gainSysEmailReward` 键名与值语义对不上）
全部被挡在 assembler 里。

## 加一个新接口

只要在 `api/handlers*.py` 里加一个函数：

```python
@endpoint('someMethod')
def h_some(api, params):
    p = api.require_player()
    code, payload = api.ctx.asset.some_op(p['player_id'], api.param(params, 'someId'))
    return code, payload          # 或 return {...} / return 200
```

不需要改任何分发代码。

---

## 踩过的坑（新栈新增的）

| 坑 | 说明 |
|---|---|
| **两个方向的 XOR 是反的** | 客户端→服务端 `0xC3`，服务端→客户端 `0x71`。`protocol.py` 里 `headercvt_wrap/unwrap` 是服务端方向，`headercvt_wrap_req/unwrap_resp` 是客户端方向（写测试用）。混用会解出乱码。 |
| **AMF3 密集数组解码回来是 Lua 表** | `{1:a, 2:b}` 而不是 `[a, b]`。**所有列表参数**（`slaveIds`/`equipIds`/`friendUids`…）必须过 `api.to_list()` / `api.list_param()`，否则 `for x in v` 拿到的是下标 1/2/3 而不是元素 —— 这是个会静默破坏所有批量操作的坑。 |
| **事务必须可重入** | service 层经常「外层 tx 里调内层 tx」（`upgrade_card` 里调 `add_currency`），SQLite 不允许嵌套 `BEGIN`。`db.tx()` 已改成可重入 + SAVEPOINT。 |
| **`sqlite3.Row` 没有 `.get()`** | 行对象和配置 dict 混用时容易踩。`cardstats._g()` 是兼容访问器。 |
| **只 SELECT 了 id 的查询会破坏加成计算** | `equips_of_card` 早期只返回 `equip_id`，装配组装后算装备加成时取不到 `meta_id`/`level`，战力凭空少一截。 |
| **`player_id` 不能从 1 开始** | 客户端 `LoginScene.lua:349` 用 `uid == "1"` 判定「新玩家」。`init_db.py` 把 `sqlite_sequence` 里 `player` 的起点设成 99999，就是为了不和哨兵值撞车。 |
| **AMF3 整数是 29 位有符号** | Unix 时间戳（1.7e9）超出范围，会被编码成 double。Lua 里都是 number，无所谓；但 Python 侧断言时别写 `isinstance(x, int)`。 |
| **客户端方向与账号方向不同** | `loginServer` 是**账号级**接口，此时角色可能还不存在 —— 这里不能 `require_player()`，要返回 `uid="1"` 让客户端跳创角。 |
| **`sysEmails` 与 `rewardEmails` 必须分开下发** | 客户端自己 `table.union` 合并，服务端预先合并会出错。 |
| **卡牌操作参数是 `masterId` 不是 `cardId`** | 响应要包成 `{'sharkCard': {...}}`。契约见 `work/api_analysis/contract.py`。 |
| **阵法格子里的卡不算独立战力** | 客户端 `getAttDefHp` 只遍历 `getQueueData()`。早期 `compute_fight_capacity` 把阵格卡也当独立卡加了一遍，战力虚高。阵格卡的作用**只是**通过阵位加成影响全队。 |
| **阵位加成不能递归套自己** | 算阵位加成要用「不含阵位加成」的占位卡面板，否则第 N 次迭代会把上一轮的加成也算进系数里。 |
| **离线拷贝 SQLite 要连 `-wal` 一起拷** | 库开了 WAL，`shutil.copy('x.db')` 会漏掉 `x.db-wal` 里未 checkpoint 的已提交数据，读出来是旧快照 —— 排查时会以为代码没生效。 |

---

### 卡牌成长曲线与战斗力

**公式全部来自客户端反编译，不是自创的**（见 `services/cardstats.py` 的模块注释）：

| 项 | 来源 |
|---|---|
| 卡牌攻防血 | `CommonManager:getCardPropertiesWithSharkCard` 第 410-412 行 |
| 升级经验 / 金币 | `CardComposeScene:getComposeExp` 第 71-113 行 |
| 装备攻防血 | `EquipUtils` 第 19 行 |
| 宝物攻防血 | `TreasureSystemUtils.CountAttandDefandHp` 第 10-30 行 |
| 元神属性（9 维）| `SpiritManager.getPlayerAllSpiritOfferedAttribute` 第 326-390 行 |
| 阵位加成 | `CommonManager:getAllMatrixBonus` / `getMatrixBonus` / `getMatrixGridBonus` 第 915-980 行 |
| **总战斗力** | `CommonManager:getLocalPlayerStrength` 第 850-864 行（客户端注释里保留的原公式）|

配置表：`card_level`(140级) / `card_evolve`(7阶) / `card_rare`(7档) / `card_meta`(1350张)
/ `equip_meta` / `equip_level` / `treasure_meta` / `spirit_meta` / `matrix_level`(71) / `matrix_grid`(8)。

实测曲线（曹操 rare6，L1→L70）：

| 等级 | 攻击 | 防御 | 血量 | 战力 | 升级需经验 |
|---|---|---|---|---|---|
| 1 | 440 | 233 | 1407 | 813 | 66 |
| 20 | 777 | 403 | 2418 | 1421 | 274 |
| 40 | 1131 | 581 | 3482 | 2060 | 1566 |
| 70 | 1662 | 848 | 5078 | 3017 | 94295 |

#### 战力是**纯服务端权威值**

`CommonManager:getLocalPlayerStrength()`（第 831-870 行）整个函数体被原厂注释掉了，
只剩一行 `return DataManager.getRealFightCapacity()`；而 `_realFightCapacity` 只有两个来源：

- `DataManager:getShowFightCapacity` 第 666 行 —— 取 `sharkUserExtend.fightCapacity`（登录下发）
- `EventManager` 第 66-69 行 —— 服务端推 `fightCapacityChangeEvent` 事件

`CardQueueScene:showPlayerAllAttribute` 里客户端自己的战力计算（第 1135、1137 行）
同样是注释掉的。**客户端从头到尾没有一行代码在算战力**，只负责显示。
所以战力怎么算，完全由服务端决定，数字自洽即可。

#### 三个必须照做的计算规则

1. **只有出战队列计入战力。** `getAttDefHp`（第 782-828 行）只遍历
   `getQueueData()`。阵法格子里的卡**不单独计战力**，它只通过阵位加成影响全队。
2. **阵位加成是全队共用一份**，加到队列里每一张卡上。
   占位卡的面板按「不含阵位加成」算（`getMatrixGridBonus` 第 970 行传的是
   `getCardPropertiesWithCardId`，第 285 行会丢弃队列上下文），否则会自己套自己。
3. **每个百分比各自 `math.floor` 后相加**，不是「百分比先合并再取整」
   （第 770-772 行三个独立 `math.floor`）。`⌊0.24x⌋+⌊0.27x⌋ ≠ ⌊0.51x⌋`。

#### 唯一自编的部分：那 9 个系数

`gameSettingConfig.cardPowerConfig` 在原厂就是**空壳**（实测 `{}`），
本地 106 张配置表里也没有对应表；`cardPowerAttackCoef` 这类名字在整个
APK 里**只出现在 CommonManager.lua 第 852-864 行那段注释中**。
所以攻击/防御/血量/暴击/闪避/招架/韧性/命中/穿透 各自在战力里的权重，
无法从 APK 反推，只能在 `cardstats.CARD_POWER` 里自定。

> 想反推的话：拿一条原服抓包里的 `sharkUserExtend.fightCapacity`，
> 用同一套面板数据（本仓库能精确复现攻防血）解一个线性方程即可。
> 客户端不校验，所以数值只要单调、稳定，功能上就都成立。

#### 尚未实现的面板加成

以下三类客户端已确认存在（都在第 770-772 行参与计算），但需要
`special_group_skill`(56) / `equip_suit`(342) / `beast_meta`(4) 三套联动，**目前没做**：

| 加成 | 客户端位置 | 配置表 |
|---|---|---|
| 连携（group skill）| 第 598-640 行取值，770-772 使用 | `special_group` / `special_group_skill` |
| 套装（equip suit）| 第 566 行附近取值，770-772 使用 | `equip_suit` |
| 神兽（beast）| 770-772 的 `aBeast*Addition` | `beast_meta` |

所以现在算出来的面板**偏低**，但结构是对的。

> 核验脚本：`python work/api_analysis/verify_power_doc.py`
> —— 对着反编译源码逐条核对外部流传的《战力公式-v1.md》，24 条通过。

---

## 当前覆盖情况

| | 数量 |
|---|---|
| 已注册 endpoint | **264** |
| 客户端实际会调用 | 363 |
| 覆盖率 | **约 73%** |

配置驱动：`luaconf.py` 能读 `work/luasrc/canon/configs/*.lua` 全部 **106 张表**
（解析成功率 106/106）。这是活动还原的地基 —— 原厂策划表是纯数据 Lua 字面量，
读进来就能直接用：

| 表 | 条目 | 用途 |
|---|---|---|
| `reward_package` | 805（666 条非空） | **通用奖励表**，活动的 rewardId 全都指向它 |
| `card_meta` | 1350 | 卡牌 |
| `world_boss_level` | 600 | 抢亲战 / 世界 Boss |
| `activity_question_bank` | 487 | 每日答题题库 |
| `sky_tower_level` | 300 | 通天塔 300 层 |
| `multiplayer_boss_level` / `sky_tower_buff` / `sky_tower_monster` | 45/100/12 | Boss 与塔 |
| `activity_pray` / `charge_money_reward` / `union_shop_special` … | 138/8/76 | 各活动 |

### 已实现的活动 / 玩法

按「本地数据完整度」顺序做的，✅ = 数值也是原厂的，🔶 = 结构照原厂但数值自编。

| 玩法 | 状态 | 说明 |
|---|---|---|
| 每日答题 | ✅ | 487 题本地题库，含答案判定、每日/每周奖励 |
| 通天塔（新旧两套） | 🔶 | 300 层配置完整；`skyTowerSettingConfig` 5 个值自编（原厂空壳） |
| 竞技场 / PK | ✅ | `arena_rank_reward`(11档) + `arena_score_exchange`(3档)，真排行不是打桩 |
| 世界 Boss / 抢亲战 | ✅ | `world_boss_level` 600 条 |
| 多人 Boss / 年兽 | ✅ | `multiplayer_boss_level` 45KB |
| 消费送好礼 | ✅ | 本地 `activity_gem_consume` |
| 累充 / 限时充值 | ✅ | 本地 `charge_money_reward`（直接表征式奖励） |
| 连续登录 / 观星 / 月历签到 | ✅ | 本地 `consecutive_login_reward` + `_new` + `countdown_reward` |
| 月卡 / 累计钻石 | ✅ | |
| 军团：商店 / 建筑 / 斗兽 / 申请审批 / 工资 | ✅ | `union_shop_*` / `union_building_*` / `union_boss_meta` |
| 吹气球 / 骰子 / 通缉令 / 秒杀 / 神兵谱 | 🔶 | 结构完整，奖励表自编 |
| 扭蛋积分 / 小玉嫁到 / 多重好礼 / 八天乐 / 结义 / 福星 / 冲级 | 🔶 | 同上 |
| 点赞 / 烟花 / 以旧换新 | 🔶 | 同上 |

**奖励解析**：原厂配置有两种约定，`gamedata.py` 两种都支持 ——
`rewardPackageId` / `rewardId` / `achieveReward` 走 `reward_package` 表（10001..19322）；
`rewardType` + `rewardId` + `rewardAmount` 是直接表征（rewardType 即 ResourceEnum）。

### 还没做

| 缺口 | 说明 |
|---|---|
| 跨服 PVP / GVG | 只有结构完整的空响应，没有真实逻辑 |
| 军团城池争夺 / 阵型 | 表建好了，逻辑没写 |
| 好友互动细节 | 送礼/切磋只有基础流程 |
| 部分开关型活动 | FB 分享、话费充值、每日首充等 |

未识别的方法会走空壳分支并记入 `unknown_rpc`，可以用它排优先级：

```sql
SELECT method, COUNT(*) c FROM unknown_rpc GROUP BY method ORDER BY c DESC;
```

---

## 测试

```bat
rem 端到端核心流程（登录 / 创角 / gameInit / 资产 / 抽卡 / 扫荡 / 邮件）
python tests\test_client.py --port 8080                    # 64 项断言

rem 活动 + 军团冒烟（92 个接口全打一遍）
python tests\test_activities.py --port 8080

rem 跨重启持久化
python tests\test_client.py --port 8080 --device my-dev
rem 重启服务端
python tests\test_client.py --port 8080 --device my-dev --existing
```

当前：**64 + 92 = 156 项全通过**。

### 已完整实现的链路

REST 登录 → `login` → `loginServer` → `getMeta` → `geneNickname` → `createUser`
→ `gameInit` → 首页 / 背包 / 装备 / 编队 / 抽卡 / 扫荡 / 邮件 / 签到 / 充值
→ 通天塔 / 竞技场 / 世界Boss / 多人Boss / 每日答题 / 军团全流程 / 各类限时活动。


---

## 与旧服务端的关系

`canon_server.py`（旧）**没有改动**，仍可运行对照。两者共用：

- `features.py` 的卡牌/技能/道具/商店元数据加载
- `canon_server.py` 的玩法设置、战斗表、抽卡池构造器（通过 `gamedata.py` 包装）
- `getMeta` 的载荷（通过 `work/api_analysis/extract_meta.py` 抽成独立模块）

等新栈完全接管后，应该把这些构建器搬进新栈，`gamedata.py` 变成一个薄 re-export。
