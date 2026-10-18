# 活动还原可行性评估

> 结论先行：**功能/流程几乎全能还原，原厂数值大部分还原不了。**
> 45 个活动里，约 15 个能连数值一起还原；其余能做出完整可玩的功能，但奖励表、
> 概率、时间窗需要自己设计。

---

## 1. 为什么「功能」能还原

活动的三段结构：

| 层 | 位置 | 我们有没有 |
|---|---|---|
| 界面 / 交互 / 规则 | 客户端 Lua（`canon/layer/Activity_*.lua`） | ✅ 全在，已解密 |
| 接口契约（收发字段） | 客户端 request 类 | ✅ 363 个接口全抽出来了（见 `API.md`） |
| **服务端运行时数据** | `getMeta` 下发 | ⚠️ **42 个活动配置里 31 个是空壳** |

也就是说：活动怎么玩、按钮怎么点、数据怎么显示，客户端已经全告诉你了；
服务端只需要按契约回数据。**唯一真正缺的是「配置数值」这一层。**

## 2. 数据来源的确切切分

对每个活动扫描它的客户端文件，看配置从哪来：

| 来源 | 说明 |
|---|---|
| `MetaManager.game_meta.<activityXxxConfig>` | **服务端 getMeta 下发**（外部数据） |
| `canon/configs/*.lua` | **客户端本地自带**（我们有） |

实测：活动 UI 几乎**没有本地兜底**——比如 `Activity_WealthGodLayer.lua:74`

```lua
for _, v in pairs(activityGoldGodConfig.goldGodRewardItems) do   -- 直接遍历服务端配置
    if v.id == goldGodNum then aRewardItemConfig = v end
end
```

服务端发空数组 → 循环 0 次 → `aRewardItemConfig` 为 nil → 界面点击后
`aRewardItemConfig.gemNeed` 崩。所以这些活动的**数值必须由服务端提供**。

## 3. 逐活动结论

### A 类：能连数值一起还原（本地有数据表）—— 约 15 个

| 活动 | 本地数据表 | 大小 |
|---|---|---|
| 每日答题 | `activity_question_bank` | 98 KB（完整题库）|
| 碎片祈祷 | `activity_pray` | 11 KB |
| 充值豪礼 / 累充 | `charge_money_reward` | 2.4 KB |
| 观星 / 连登 | `consecutive_login_reward` + `_new` | 1.2 KB |
| 年兽 / 多人 Boss | `multiplayer_boss_level` | 45 KB |
| 抢亲战 / 世界 Boss | `world_boss_level` | 81 KB |
| 通天塔 | `sky_tower_level/buff/monster/reward/setting` | 60 KB |
| 逐鹿中原 | `activity_contend_fragment` | 1 KB |
| 消费送好礼 | `activity_gem_consume` | 0.4 KB |
| 萝莉剧场 | `event_conversation_christmas` + `battle_monster*` | 130 KB |
| 许愿池 | `activity_fountainwish_gold` + `_fountainmax` | 0.9 KB |
| 奶牛关 | `cow_stage` | 1.1 KB |
| 军团系（商店/建筑/斗兽/军团战）| `union_shop_normal/special` `union_building_*` `union_boss_meta` `union_career` | 17 KB |
| 竞技场 | `arena_rank_reward` `arena_rank_score` `arena_score_exchange` | 8.8 KB |
| 附灵 / 神兽 / 图鉴 | `enchant_*` `beast_meta` `beast_fragment` `atlas_Reward` | 23 KB |
| 限时充值 | `activityLimitRewardConfig`（getMeta 已有 3 项真实数据）| — |

### B 类：能做出完整功能，但奖励数值要自己设计 —— 约 13 个

这些活动服务端配置是空壳，本地也没有对应数据表，但**配置结构已知**
（客户端需求字段明确），照结构填数值即可跑通：

迎财神（`goldGodRewardItems`）、吹气球、通缉令、周末秒杀、马上发财、
六马奔腾（骰子）、冲级活动、桃园结义、春节八天乐、多重好礼、
以旧换新、社群点赞、月卡（`gemCardConfig` 已有 6 项）、神兵谱
（`rankRewardMetas` / `pointRewardMetas` 缺，但 `treasure_*` 本地齐全）。

### C 类：逻辑简单，本来就不依赖复杂配置 —— 约 12 个

FB 分享、每日首充、充值送话费、充值回馈、双倍银币、恭贺新禧、
邀请码活动、每日挑战、神秘商店、日常版易帅换将、扭蛋活动、小玉嫁到。

这些要么是「开关 + 计数」，要么是「消费返利」，按契约回数据就能用，
数值不敏感。

## 4. 真正的缺口

| 缺口 | 影响 | 能不能补 |
|---|---|---|
| 31 个 `activityXxxConfig` 的奖励表 | 活动能开但没奖励 / 点按钮崩 | 按结构自编 |
| 活动时间窗（`featureName` → 起止时间）| 活动不显示或显示已结束 | **能**：本地 `maintenance` 配置 + `_all_maintenance_items()` 已有生成逻辑 |
| 掉率 / 保底概率 | 数值与原厂不同 | 自编 |
| 商城定价 / 兑换比例 | 同上 | 自编 |

## 5. 还有一个可能性没排除

原版客户端的 `getMeta` 响应是**运行时从服务端拿的**，本包里没有缓存副本。
但如果你手上还有别的渠道包（ARCHITECTURE.md §9.6.1 提到过七匣子 v11.0.46、
单机100 v11.0.61 等），**资源管线是共用的，配置也可能共用**——值得拿一个包
用同样的方法比对 `getMeta` 相关的字段来源。另外任何当年抓过的包/日志里如果有
完整的 `getMeta` 响应，那 31 个空壳就能直接填满。

---

## 6. 建议的推进顺序

按「本地数据完整度 × 玩家感知强度」排序：

1. **通天塔 / 竞技场 / 军团系**（本地数据全，且是常驻玩法，不是限时活动）
2. **每日答题 / 世界 Boss / 多人 Boss**（本地数据全，玩法闭环）
3. **累充 / 连登 / 签到 / 月卡**（数值敏感度低，且是留存关键）
4. **B 类限时活动**（自编一套数值先跑通，之后再按手感调）
5. **C 类开关型活动**（顺手就做了）

复现命令：

```bat
python work\api_analysis\activity_feasibility.py   rem 总表
python work\api_analysis\activity_sources2.py      rem 数据源溯源
python work\api_analysis\check_activity_configs.py rem getMeta 空壳清单
python work\api_analysis\probe_activity.py <配置键> rem 单个活动的读取点
```
