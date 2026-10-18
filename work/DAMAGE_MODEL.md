# 战斗数值模型：哪些是原厂的，哪些是自拟的

本文回答三件事：伤害怎么算、连协/套装/神兽怎么加成、战斗力怎么定。
每条都标了**来源等级**，方便以后拿到新证据时只替换对应的一段。

判定标准：
- **【实证】** 客户端代码或配置里能直接读到，或已被抓包/界面数值验证；
- **【推导】** 由实证数据反推，样本有限；
- **【自拟】** 没有任何参考，按量级校准出来的曲线，这里说清理由。

---

## ① 伤害与技能

### 1.1 技能 = 属性增减状态【实证】

链路：`card_meta.skill/mainSkill` → `skill_meta[id].statusIdList` → `skill_status[id]`。

`skill_status` 行的字段（1850 条，且 `luaconf` 能完整读到）：

| 字段 | 含义 |
|---|---|
| `prob` | 触发概率（0.35 / 0.5 这种） |
| `impactAttr` | 1=攻 2=防 3=血 |
| `valueType` | 1=百分比 2=绝对值 |
| `effectValue` | 增减量 |
| `lastType` | 持续类型 |
| `feedback` | 1 = 属于「面板类」加成（连协取它用这个过滤） |

**实测校验**：技能 `32000101` → 状态 `630501` → `effectValue=57`，
与真实抓包里那条 `skillId=32000101, eventType=102, effectId=1, changedValue=57`
**完全一致**。所以事件流里技能事件的 `changedValue` 是**属性增减**，不是伤害。

现在的实现（`services/battle.py:_skill_status_effects`）：
每回合按 `prob` 掷一次，命中就发 `eventType=102` 的事件，
`effectId` 用 1/2/3（攻/防/血 DEC 用 10/11/12），`changedValue=effectValue`，
并把这些增减累加进本场的属性修正表。

### 1.2 伤害公式【推导 + 自拟】

原版伤害是**服务端**算的，客户端只接收 `changedValue`，所以拿不到公式。
抓包里能用的样本只有两条（其余两条伤害都被目标血量截断）：

| 攻击方有效攻击 | 目标防御 | 实际伤害 | 比值 |
|---|---|---|---|
| 309 + 57 = 366 | 0 | 359 | 0.98 |
| 209 + 57 = 266 | 0 | 282 | 1.06 |

→ 结论【推导】：**伤害 ≈ 有效攻击 × 0.9~1.1 随机**，且 def=0 时看不出防御怎么减伤。

防御项没有任何样本，所以【自拟】成递减式减伤：

```
减伤率 = def / (def + 2*att + 200)，上限 70%
伤害   = att * uniform(0.9, 1.1) * (1 - 减伤率)
```

为什么用递减而不是 `att - def`：`att - def` 在「高防打低攻」时会退化成一排 `-1`
（实测过：我方 def 376 对敌方 att 60），而原版不会出现这种数字。
这条曲线在量级上能复现抓包：att1400 打 def169 → 约 1300，确实一击必杀。

二级属性接进判定（全部【自拟】概率）：

| 属性 | 作用 | 公式 |
|---|---|---|
| `hit` / `eva` | 命中 - 闪避 → 未命中（eventType 2，伤害 0） | `eva/(eva+1500) - hit/(hit+2000)`，上限 25% |
| `crt` / `tou` | 暴击率（eventType 1，伤害 ×1.6） | `0.05 + crt/(crt+2000) - tou/(tou+3000)`，2%~50% |
| `par` | 招架（eventType 4，伤害 ×0.5） | `par/(par+3000)`，上限 15% |
| `prc` | 穿透（削减目标防御） | `prc/(prc+2000)`，上限 50% |
| — | 反击（eventType 3，反伤 30%） | 固定 3% |

这些常数集中在 `services/battle.py` 的 `CURVE` 字典里，改一行就能调。

---

## ② 连协 / 套装 / 神兽

三者最终都汇成「百分比 + 绝对值」两组数，**客户端原文**（`CommonManager` 766-772 行）：

```lua
temp = floor(基础) + 装备 + 元神 + 宝物
面板 = temp + floor(temp*连协%) + floor(temp*套装%) + floor(temp*神兽%)
              + 连协值 + 套装值 + 神兽值 + 阵位加成
```

注意是**每项各自 floor 再相加**（`⌊0.24x⌋+⌊0.27x⌋ ≠ ⌊0.51x⌋`）。

### 2.1 连协 `special_group_skill`【实证】

56 条，按 `cardGroupId` 索引，每条最多 4 组：

```
groupSkill1..4  触发的技能 id
group1..4       要求的国家
groupNum1..4    要求的人数
```

激活条件逐字对应 `checkSpecialGroupIsActive`：
- 卡的国家 == 要求国家：队伍里该国卡数 **≥ groupNum + 1**
- 否则：**≥ groupNum**

激活后取 `skill_meta[groupSkillN]` 的状态，**只要 `feedback == 1` 的**，
按 `impactAttr`/`valueType` 累加。

### 2.2 套装 `equip_suit`【实证】

342 条，字段 `(cardGroupId, equipId, activeAttr, valueType, effectValue)`。
判定（`CommonManager` 521-548 行）：
装备的 `equip_meta.prefixId == equip_suit.equipId`，
**且** `equip_suit.cardGroupId == 卡片的 cardGroupId`。
`valueType=1` 时 `effectValue` 是小数（如 0.24 = 24%）。

### 2.3 神兽 `beast_meta`【实证 + 现状】

`beast_meta[metaId].attrs.beastSkillCountry == 卡的国家` 时生效，
技能等级取该神兽当前 level 对应的 `items[level].beastSkillId`，再走 `skill_status`。

⚠️ 现状：服务端**还没有神兽归属表**（数据库里只有 `player_beast_fragment` 碎片），
所以这条链路代码已实现但当前恒为 0。等做神兽系统时直接接上即可。

### 2.4 自测

`python scripts/test_bonus_calc.py` —— 人造满足条件，确认两条链路都算出非 0：

```
连协 cardGroupId=330 卡=魔·大乔小乔_1 -> pct={'att': 0.3, 'def': 0.55, 'hp': 0.0}
套装 cardGroupId=101 equipId=21101 卡=曹操_1 effectValue=0.24 -> pct={'att': 0.24}
```

---

## ③ 战斗力

**客户端不算战力**【实证】：
`CommonManager:getLocalPlayerStrength` 整个函数体被注释掉，直接
`return DataManager.getRealFightCapacity()`，而那个值只来自服务端下发的
`sharkUserExtend.fightCapacity`。抓包里那个账号的战力是 0，**拿不到任何样本**。

所以系数只能【自拟】。公式结构照抄原厂那段被注释掉的代码：

```
result = (Σ攻*1 + Σ防*1 + Σ血*0.1) * 1
       + (crt*5 + eva*5 + par*5 + tou*4 + hit*4 + prc*4) * 1
```

量级校准依据：

| 参照 | 计算 | 战力 |
|---|---|---|
| 一张满级（Lv70）五星卡 | 攻 1100×1 + 防 500×1 + 血 5200×0.1 | ≈ 2120 |
| 五张满级队伍 | 2120×5 | ≈ 1.06 万 |
| 当前存档（4 张 1~43 级） | 实测 | **2809** |

2809 与界面上一直显示的 2809 一致（那个数字本来就是本服务端算的）。

二级属性权重从 2 提到 5/4 的原因：元神给的暴击/闪避通常只有几十点，
权重 2 时对战力几乎没有影响；5 左右才有存在感，但不会盖过攻防血。

**以后若拿到真实战力数据**：只改 `cardstats.CARD_POWER` 这张表，公式不用动，
`compute_fight_capacity` 会自动跟着变。

---

## 怎么验证改动

| 脚本 / 操作 | 验证内容 |
|---|---|
| `python scripts/test_bonus_calc.py` | 连协、套装链路是否算出非 0 |
| `python scripts/cmp_monster_stats.py` | 敌方怪物数值量级 |
| 20 场随机战斗统计 | 有胜有负、没有 20 回合超时僵局 |
| `scripts/rec_battle.py --in-map` | 实机跑一场，抓帧看演出（技能增益图标/伤害数字/结算） |
