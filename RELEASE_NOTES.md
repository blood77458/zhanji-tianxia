# 版本发布说明

> 适用版本：`v0.1-net`（客户端 APK `canon_net.apk`）+ 仓库当前 `main`
> 说明：本文按「服务端 / 客户端补丁 / 单机版 / 仓库」四块列出本轮更新。

---

## 一、新增

### 服务端

**1. 技能系统改为真实配置驱动**

技能不再是「裸扣血」，而是走客户端原厂的配置链：

```
card_meta.skill/mainSkill → skill_meta[id].statusIdList → skill_status[id]
                            （prob / impactAttr / valueType / effectValue）
```

已用真实抓包校验：技能 `32000101` → 状态 `630501` → `effectValue=57`，
与抓包里 `changedValue=57` 完全一致。现在战斗里能看到真实的技能增益事件（`eventType=102`）。

**2. 连协 / 套装 / 神兽 三类加成**

按客户端 `CommonManager:getCardPropertiesWithSharkCard`（766-772 行）原文实现：

```
面板 = temp + floor(temp*连协%) + floor(temp*套装%) + floor(temp*神兽%)
            + 连协值 + 套装值 + 神兽值 + 阵位加成
```

- 连协：`special_group_skill` 触发条件逐字照抄 `checkSpecialGroupIsActive`
- 套装：`equip_meta.prefixId == equip_suit.equipId` 且 `cardGroupId` 与本卡一致
- 神兽：`beast_meta.attrs.beastSkillCountry` 匹配国家后取当前等级技能

配了自测脚本 `scripts/test_bonus_calc.py`（人造条件验证两条链路都算出非 0）。

**3. 一刀切掉老的战场属性算法**

战斗单位属性现在统一走完整面板（基础+装备+宝物+元神+连协+套装），
和客户端卡片详情同口径，不再出现「服务端算的数值和界面显示不一致」。

### 客户端补丁

**4. 修复 `BattleScene.lua:1372` 崩溃**

事件流走空且有一方血量归零时，客户端会 `index nil` 直接闪退。
补丁加了空队列保护，并在此时直接播终局演出（赢 → `Crash`，输 → `Lose`）。

**5. 战败也播爆衣**

原版只有「打赢」会播 `BattleAnimEnum.Crash`（破碎立绘）。补丁把战败分支也接上：
预载我方主角卡的 `card/crush/<figureId>_0.png`，战败时替换 `card2crash` 实例后播同一段动画。

> 关键坑：`card2crash` 实例**必须在场景初始化时注册**；
> 战斗中再 `addChangeInstance` 会在 GLThread 里原生 SIGSEGV（不留 `.crash` 文件）。

**6. `LoginScene` 跳过 `/systemInfo` 的 HTTP 请求**

该接口返回二进制 AMF3，客户端拿不到就卡在登录。
补丁改为本地合成结构（含「本地测试服」），登录页正常渲染。

### 单机版（服务端内置，开发中）

**7. APK 内的纯 Lua 服务端骨架**

- 拦截 `Communication:request`，业务请求直接走 Lua 派发表（**不需要 AMF3/zlib/XOR 编解码**）
- `luajava` 起本地 `ServerSocket`（不建 Java 线程，每帧 `accept`），只应答 native 的资源检查 `/staticVersion`
- 登录链路的直连 HTTP 端点用抓包回放，`/protocol` 用静态快照（18 个方法）

**8. 战斗移植为 Lua（`canon/single/battle.lua`）**

把服务端的战斗模型翻成 Lua，数据全部取自客户端本地配置。

### 工具链

**9. `scripts/bootstrap.py` —— 一条命令准备运行环境**

从你自己的 APK 解出配置到 `work/luasrc/`、生成 `card_dict.json`、建好 `canon.db`。
仓库因此**不需要**携带任何游戏解包产物。

**10. 单机版迭代工具**

`single_boot.py`（启动+截取 `unhandled` 清单）、`single_iter.py`（自动补快照）、
`pack_single_apk.py`（打包单机版）、`pack_net_apk.py`（打包直连版）。

---

## 二、修复

| 问题 | 原因 | 修法 |
|---|---|---|
| 我方连续攻击太多次、回合数不掉但会超时 | 一回合内我方全打完再敌方全打，`round` 不递增 | 改为双方交替单人出手，`round` 每回合 +1，上限 20 |
| 明明还有血却提前判超时 | 我方血量被钳在 1 以上，永远打不到 0 | 移除钳制（崩溃已由客户端补丁根治） |
| 伤害数字满屏 `-1` | `att - def` 在高防对低攻时退化 | 改递减式减伤 `def/(def+2·att+200)`，上限 70% |
| 地图「前进」时闪退 | `ChapterMapScene:2064` 直接取 `rewards[1].amount` | 事件响应补 `rewards={ {metaId, amount} }` |
| 单机层静默失效、`login` 变 `unhandled` | `handlers_core.lua` 里出现两个 `return M`，模块语法错误 | 重写为单 return，并加 `registered: N` 日志便于发现 |
| Release 说明中文变问号 | PowerShell `Invoke-RestMethod` 传字符串 body 按 Latin-1 发送 | 改为 Python 生成 UTF-8 文件 + `curl --data-binary` |

---

## 三、数值校准

- **成长表比对**：用户提供的《五星武将成长表》与客户端配置 **92/105 条完全一致**，
  其余 9 条是社群表舍入（≤0.7），3 个角色 11.0.61 客户端里没有
- **公式实机校验**：客户端背包显示 诸葛亮 Lv1 攻 290 / 血 1414，服务端算 290 / 1414（逐点一致），
  防御差 35 经确认为阵位加成 `floor(142×0.25)`
- **战斗力**：客户端不算战力（`getLocalPlayerStrength` 是死代码），系数按量级校准并写进文档：
  满级五星卡 ≈ 2120，本存档 2809

---

## 四、仓库变更

**清理（不再跟踪，本地保留）**

| 内容 | 数量/大小 |
|---|---|
| `work/luasrc/` 解密出的客户端 Lua 与配置表 | 1088 个文件 |
| `server/static/static_config.*.xml` 资源清单 | 10 份 / 13 MB |
| 签名密钥、`hero_catalog.*`、`card_dict.json` 等派生数据 | — |
| 历史截图、APK、临时产物 | 约 274 MB |

仓库文件数从 1404 降到 316。`.gitignore` 已加规则防止再误提交。

**文档**

- `README.md`：安装说明从三套重叠内容合并为「快速开始」三条命令
- `FLOW.md`：全流程（逆向 / 协议 / 服务端结构 / 数值体系 / 调试环境）
- `work/DAMAGE_MODEL.md`：数值模型，每条标注【实证】/【推导】/【自拟】
- `OFFLINE_APK_PLAN.md` / `offline/STATUS*.md`：单机版方案与逐轮进度

---

## 五、已知问题

1. **单机版战斗尚未跑通** —— 地图随机事件的奖励条目还缺客户端认的字段
   （最新报错 `RewardManager.lua:544: attempt to concatenate field 'itemType'`）
2. **单机版只到 S1** —— 能离线进主界面、背包/关卡界面正常；
   活动、商城、抽卡等交互型入口尚未覆盖
3. **历史提交仍含已清理的文件** —— 需 `git filter-repo` + 强制推送才能彻底移除
4. **签名密钥曾公开** —— `work/canon.keystore`（密码 123456）已进入过公开提交，
   正式分发前应重新生成密钥
5. `跨服 / 军团战` 相关配置仍有约 121 处字段缺失（已知，暂不处理）

---

## 六、使用方式

```bash
pip install -r requirements.txt
python scripts/bootstrap.py              # 首次：从你的 APK 解配置 + 建库
cd server && python -u gameserver.py     # 启动（自动定位资源清单）
```

模拟器安装 Release 里的 `canon_net.apk` 即可，**不需要改 hosts、不需要端口转发**。

---

## 版权

《战姬天下》版权归乐元素所有。本项目仅用于个人学习与软件保存，不得公开运营、
不得盈利、不得传播 APK 与解出的游戏资源。
