# 《战姬天下》(canon) 复现全流程

> 目标：拿停服游戏的 APK → 逆向协议 → 自写服务端 → 客户端重新跑起来 → 逐步还原功能。
> 合规：版权属乐元素，仅个人学习/保存，不公开运营、不盈利、不传播 APK 与解出的资源。

---

## 一、全链路总览

```
APK(assets)  ──解密──►  Lua 源码 / 配置表  ──┐
     │                                     ├─► 服务端(本仓库 server/)
     │                                     │      ├─ HTTP :80  (protobuf? 否, 自定义信封)
     │                                     │      └─ TCP  :9700 (实时通道)
     └─ 运行 ──► 客户端 ──HTTP──► 服务端 ──┘
                        └── 响应：AMF3 + zlib + XOR ──► 客户端渲染
```

### 1. 客户端逆向（已完成）

| 环节 | 结论 |
|---|---|
| 引擎 | Cocos2d-x + Lua（tolua++），`libhegame.so`，仅 armeabi-v7a |
| 包名/版本 | `com.happyelements.canon.baiduDK` 11.0.61（oem_5500058） |
| Lua 加密 | `IV(16) ‖ AES-128-CBC(PKCS#7(zlib(明文)))`，key `e9747d92cc322e7d112e7c3451d7b36a` |
| 物理文件名 | `<逻辑名>.<md5(密文)>.lua`；资源用 manifest `static_config.<md5>.xml` 做 `ref` 去重 |
| 热补丁 | 引擎**优先**加载 `Caches/src/<逻辑路径>` 覆盖 APK 内文件 → 改客户端不用重打包 |

### 2. 通信协议（已完成）

| 层 | 规格 |
|---|---|
| 信封 | `body = headercvt(zlib(amf3(payload)))` |
| 方向混淆 | 客户端→服务端 XOR `0xC3`；服务端→客户端 XOR `0x71` |
| 入口 | `POST /protocol`（HTTP 80）；另有 TCP 9700 实时通道 |
| 域名 | `android1.canon.happyelements.cn` / `.com`，模拟器用 hosts 指到 `10.0.2.2` |

### 3. 服务端（本仓库 `server/`，397 个 endpoint）

```
gameserver.py         HTTP :80 + TCP :9700
api/                  端点注册与分发（handlers*.py，自动发现）
  __init__.py         ALIASES（13 处方法名修正）、load_handlers()
  handlers.py         核心：登录/主界面/邮件/抽卡…
  handlers_more.py    竞技场/军团战/跨服…
  handlers_union.py   军团
services/             业务逻辑
  battle.py           战斗（技能状态 → 事件流）
  cardstats.py        卡牌属性/成长/连击/套装/神兽/战力
  asset.py            道具/商店/装备/宝物/元神
  mission.py          关卡推进
  activities.py       活动
meta_payload.py       生成客户端要的 GameMetaData（含 _FILL_MISSING 兜底）
assembler.py          响应组装（sharkUser/sharkCards/…）
canon.db              SQLite 存档
```

### 4. 客户端补丁（`Caches/src` 覆盖，共 3 个）

| 文件 | 补丁 | 作用 |
|---|---|---|
| `canon/scene/ChapterMapScene` | 放开被注释的爆衣代码块 | 地图场景的破碎立绘 |
| `canon/scene/BattleScene` | PATCH1 空队列 nil 保护 / PATCH2 预载我方破碎立绘 / PATCH3(PATCH3b) 战败也播爆衣 | 修 `BattleScene.lua:1372` 崩溃 + 战败爆衣 |
| 其余（成就/活动/武将详情等） | 上一会话的历史补丁 | 见 `HANDOFF.md` |

补丁脚本：`scripts/patch_battle_guard.py --deploy`（解密→改→加密→adb push→清缓存指纹）。

---

## 二、数值体系（三层，来源严格区分）

详见 `work/DAMAGE_MODEL.md`。要点：

| 层 | 来源 |
|---|---|
| 卡牌基础属性/成长 | **【实证】** 客户端 `CommonManager:getCardPropertiesWithSharkCard` 逐字照抄，并用客户端界面校验（诸葛亮 Lv1 攻290/血1414 完全一致） |
| 技能 = 属性增减状态 | **【实证】** `skill_meta.statusIdList → skill_status`，与抓包 `changedValue=57` 完全对上 |
| 伤害 → 减伤/暴击/闪避/招架/穿透/反击 | **【推导】+【自拟】** 抓包只有 2 条干净样本，曲线自拟，常数集中在 `battle.CURVE` |
| 连协/套装/神兽 | **【实证】** `special_group_skill` / `equip_suit` / `beast_meta`，按客户端 766-772 行公式 |
| 战斗力 | **【自拟】** 客户端不参与（`getLocalPlayerStrength` 被注释掉），系数按量级校准 |

### 爆衣（破碎立绘）两条触发路径

| 回调 | 胜利 | 战败 |
|---|---|---|
| `onLastHitFlashEnd`（致命一击，实际走的这条） | `qte` 真 → `Crash` 播**敌方**破碎立绘 | 原版只有 `Lose` → 我们补成播**我方**破碎立绘 |
| `onFlashAnimationEnd`（FightDeath） | 同上 | 同上（副本战斗走不到） |

前置条件：敌方/我方主角卡有 `card/crush/<figureId 末段换成 _0>.png`（共 90 张）。
`card2crash` 实例**必须在场景初始化时注册**，战斗中途 `addChangeInstance` 会原生 SIGSEGV。

---

## 三、开发/调试环境

| 项 | 值 |
|---|---|
| 服务端启动 | `cd server; $env:CANON_MANIFEST_MD5="<apk 里 static_config 的 md5>"; python -u gameserver.py` |
| 模拟器 | MuMu Player 12，adb `127.0.0.1:16384`，屏幕 720×1280 |
| 设备端 hosts | `adb root` → `mount --bind /data/local/tmp/hosts /system/etc/hosts`（**adb 断线重连后要重做**） |
| 战斗事件缓存 | 改数值后必须 `python scripts/clear_battle_cache.py`，否则调参不生效 |
| 崩溃排查 | Lua 错误 → `/data/data/<pkg>/errorlogs/*.crash`；原生崩溃 → `logcat -b crash | grep 'Fatal signal'` |

### 常用脚本

| 脚本 | 用途 |
|---|---|
| `ui_test.py` | 界面流程回归（主界面/导航/图标/闯关/奖励） |
| `rec_battle.py [--in-map]` | 录一场战斗并抽帧 |
| `capture_baoyi.py` | 一键复现爆衣并收证据 |
| `patch_battle_guard.py` | 打/部署客户端补丁 |
| `cmp_growth_byname.py` | 成长表 vs 配置比对 |
| `test_bonus_calc.py` | 连协/套装自测 |
| `clear_battle_cache.py` | 清战斗缓存 |

---

## 四、当前状态

**能跑通的**：登录 → 创角 → 新手引导 → 主界面 → 闯关 → 章节地图 → 战斗（含技能/暴击/爆衣）→ 结算 → 背包/武将/装备/强化/活动等大部分界面。

**已知缺口**：
- 25 个「只回 ack」的空壳 endpoint（成就/公会战等边缘接口）；
- 勋章玩法无数据源；`christList` 为空；跨服相关配置缺失（用户已明确忽略跨服）；
- 神兽系统只有碎片表，没有归属表 → 神兽加成的代码已写但恒为 0；
- `audit_meta_keys.py` 仍报 ~121 处嵌套字段缺失（集中在跨服 GVG / 军团战配置）。

**验证方式**：`python scripts/audit_meta_keys.py`（配置字段）、`ui_test.py --only <flow>`（界面）、`rec_battle.py`（战斗演出）。
