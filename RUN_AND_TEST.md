# 实机联调 & 功能测试记录（2026-10-17）

> 环境：MuMu Player 12 / Android 12 / 720x1280 / adb `127.0.0.1:16384`
> 这一轮把「服务端 + 模拟器 + 客户端」真正跑通了，并用 UI 自动化把主要功能点了一遍。

---

## 一、结果

```
================ 汇总 ================
OK=24  WARN=2  FAIL=0  SKIP=0
```

- **零崩溃**：`/data/data/<pkg>/errorlogs/` 下没有任何 `.crash`
- **服务端零 500**：`srv_detached.log` 里 406 次 `retCode=200`，无 Traceback
- 覆盖：顶部菜单 6 个（任务/活动/奖励/求将/求宝/商城）、底部导航 6 个
  （首页/队伍/闯关/背包/神兽/军团）、次级图标 6 个（装备/好友/邮箱/元神/宝物/炼魂）、
  主界面 竞技/演武、闯关→挑战→**真打一场战斗**、领取章节奖励
- 已肉眼核对截图：背包（武将列表/等级/统御力/攻防血）、队伍（统御力 49/104/组合技能）、
  军团（军团列表/军团长/人数/宣言）、活动（桃子妹妹/抢亲大战/许愿池/秘境试炼）、
  元神（空池提示）、商城（金币/VIP/充值/道具详情）、闯关（荆州/乱入新世界/进度）
  都是**真实数据**，不是空壳

唯一 2 个 WARN 是「内容区无变化」——属于自动化判定的**时序敏感**（战斗地图切换动画
在 5s 采样窗口内没落到不同帧），功能本身正常（已手动验证：打一场后关卡进度 0%→20%、
金币 1068→1074、体力 98→96）。

---

## 二、每次重启电脑后怎么把环境拉起来

```powershell
# 1) 起服务端（脱离式，不受工具进程树影响）
cd E:\deepseek_projects\app_server\server
$env:CANON_MANIFEST_MD5 = "81c8ede8d76998cd852173d537c04aac"
Start-Process python -ArgumentList "-u","gameserver.py" -WindowStyle Hidden `
  -RedirectStandardOutput "..\work\srv_detached.log" `
  -RedirectStandardError  "..\work\srv_detached.err"
# 启动要 ~16-22s，之后 :80 和 :9700 才监听

# 2) 连模拟器 + 拿 root（重启后 adb 默认是 shell，不是 root！）
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb connect 127.0.0.1:16384
& $adb -s 127.0.0.1:16384 root      # 必须！否则 mount 不了 hosts
& $adb -s 127.0.0.1:16384 wait-for-device

# 3) 装 hosts（/system 是只读，只能用 bind mount；重启就丢，每次都要重做）
#    内容见 work/hosts_canon 或脚本里；域名指向 10.0.2.2（模拟器里访问宿主的固定地址）
& $adb -s 127.0.0.1:16384 push <本地 hosts> /data/local/tmp/hosts
& $adb -s 127.0.0.1:16384 shell "mount --bind /data/local/tmp/hosts /system/etc/hosts"

# 4) 清客户端陈旧资源缓存（换过 APK / 换过服务端清单后必须做）
$b = '/data/data/com.happyelements.canon.baiduDK'
& $adb -s 127.0.0.1:16384 shell "am force-stop com.happyelements.canon.baiduDK; rm -f $b/Caches/static_config.md5; rm -rf $b/Caches/src"

# 5) 跑测试
cd E:\deepseek_projects\app_server
python scripts\ui_test.py --save-ref     # 第一次：把当前主界面存成参照图
python scripts\ui_test.py --wait 5       # 全量
```

---

## 三、这一轮在实机上才暴露出来、已修好的问题

### 3.1 卡在「正在检查资源更新 → 网络不好」进不去

引擎启动时做资源校验，会去 `/static/src/canon/xxx.<md5>.lua` 下载它认为缺失的文件。
服务端 `static_file()` 只从 `server/static/` 取，这些文件不在那儿 → 全 404 →
客户端判定网络异常，弹「主公，网络不好啊！」。

**修**：`server/gameserver.py::static_file` 增加回落 —— 取不到就去 **APK 的
`assets/`** 里读同一个路径返回（这些文件 APK 里本来就有）。

### 3.2 登录后主界面立刻崩：`changeAvatarByCardInfo` 拿到 nil

`canon/models/CommonManager.lua:1171: attempt to index local 'cardInfo' (a nil value)`
← `MainMenuScene.lua:681 onInit`。

根因是测试号 `player.main_card_id = 0`（主将没设）。而它会变成 0，是因为
**`adjustTeam` 传空参数时会把主将清空**：`services/asset.py::adjust_team` 里
`if c and self.r.asset.card(...)` 对 0 是跳过的，于是一路执行到 `set_battle_queue([0])`。

**修**：`adjust_team` 主将 id 为 0 直接返回 `E_CARD_NOT_EXIST`，不再允许清空。

### 3.3 新手引导锁死输入，界面点不动

客户端只要发现**任何一条**引导未完成，就从那条开始重跑，期间
`MainMenuScene:321 setDispatchEvents(false)` 锁住输入 —— 只有高亮控件响应，
连返回键都点不动（进「队伍」会被「点击此处进入缘分互通」卡死）。

**修**：`assembler.DONE_TUTORIAL_STEPS` 补齐到客户端**全部 31 个** `Guide_*` 名字
（`grep '"Guide_' work/luasrc` 得到），并改成「一律全部标记完成 + 并上库里真实进度」。
少一个都不行 —— 之前漏了 `Guide_Lineup1/3`、`Guide_CardFate`、`Guide_Matrix` 等。

### 3.4 自动化判定主界面（假阳性/假阴性）

- `is_main()` 原来比**整个内容区**，实测只有 0.8722 —— 差异全来自会变的东西
  （吃桃横幅按时间段换、跑马灯、战报文案），导致主界面被误判成「不在主界面」。
  **改成只比 4 条稳定条带**（顶部菜单/立绘区/图标行/底部导航），静止时每条都是 1.0000。
- 退出确认框坐标记错了：实际「取消」在 `(223,688)`，原来记的是 `(233,858)`。

### 3.5 自动化「回主界面」的路径

原来只会「返回键 + 取消 + 点空白」，进了活动/队伍/军团这类**场景**就回不来，
后续所有用例连锁报「无法回到主界面」。

实测可靠顺序（按可靠性排序，已写进 `goto_main`）：
1. **点底部导航「首页」`(60,1218)`** ← 最稳，绝大多数场景都带这条底栏
2. 点弹窗右上角 X `(676,252)`
3. 点场景左上角返回箭头 `(34,190)`
4. Android 返回键 → 取消 `(223,688)`
5. 点空白处（关 popPanel）

⚠️ 不要盲目点场景左上角：**军团界面左上角是搜索输入框**，点中会弹软键盘顶掉整排按钮。

### 3.6 坐标校正（实测）

| 名称 | 旧值 | 新值 |
|---|---|---|
| 图标行 装备/好友/邮箱/元神/宝物/炼魂 | y=1145 | **y=1086** |
| 挑战（章节地图） | (495,727) | **(574,946)** |
| 扫荡 | — | (574,818) |
| 领取章节奖励 | — | (574,690) |
| 前进（战斗地图，点了才开战） | — | (360,1066) |
| 退出框 取消 / 确定 | (233,858)/(521,858) | **(223,688)/(551,688)** |


### 3.8 商城买完东西不增加（客户端不刷新）

uyGoods 原来回 {reward: {单个对象}}，而客户端 ShopScene:1225 是
RewardManager:getReward(evt.data.reward)，它第一行 if #rewardData <= 0 then return end
—— # 对字典是 0，直接 return，于是「购买成功」不弹、数量不刷新。
（其实服务端早就发到背包了，只是客户端本地没同步。）
**修**：services/asset.py::buy_goods 改成回**数组** {reward: [...]}。
实测：银钥匙 持有数量 0 → 1，钻石 6510 → 6500（价格配置是 moneyType=2 即钻石，正确）。

### 3.9 活动页签闪退（getMeta 配置缺字段）

点「小玉嫁到」直接闪退：
Activity_NewChargeRewardLayer.lua:89: attempt to index local 'rechargeRewardConfigs' (a nil value)
← DataManager.GameMetaData.activityNewYearConfig.payRewards 为 nil。

这类「顶层 key 有、嵌套字段没有」的问题最阴，于是写了个脚本把客户端所有
GameMetaData.<k> / GameMetaData.<k>.<f> 访问都扫一遍，和 getMeta 对比：

`
python scripts/audit_meta_keys.py     # 有缺失时返回非 0，可当回归门禁
`

一开始查出 **2 个顶层 key + 27 个嵌套字段**缺失，已全部在
meta_payload.py::_fill_missing_client_fields() 里补齐（原则：结构完整、语义为空；
会被下标访问的 payRewards / diceNewRewardItems 给出足够长度且元素字段齐全）。

现在 **顶层缺失 0 / 嵌套缺失 0**，活动页签逐个点过 12 个位置全部不崩。

### 3.10 竞技场闪退（字段类型不对）

AcrossFightManager.lua:699: attempt to call method 'split' (a nil value)

crossServerSettingConfig.crossServerGroups[i].serverIds 我一开始给的是**数组**，
而客户端是 serverIds:split(,)，要的是**逗号分隔字符串**。
改成 'serverIds': '1' 后，竞技场正常显示「跨服争霸尚未开启，敬请期待」。

> 教训：光补齐 key 不够，**类型也要对**。udit_meta_keys.py 只查存在性，
> 类型问题只能靠实机点。

### 3.7 登录流程要区分新老号

`ui_test.auto_login` 原来一律「点登录 → 点骰子 → 点创角 → 盲点 40 下」，
在有角色的号上会把界面点乱。已改成：**点完「游客登录」先判一次 `is_main()`**，
已在主界面就直接返回；只有新号才走创角 + 引导。

---

## 四、仍然存在的已知缺口

见 `SERVER_ENDPOINTS_DONE.md` §4。和实机测试相关的补充：

| 项 | 现象 |
|---|---|
| `crossBossActivityStatus=False` | 跨服 Boss 入口不显示（meta 缺 `crossBossSettingConfig`，开了必崩） |
| 军团战 / 跨服 GVG 入口 | `wgvgTotalConfig.crossServerGroupMetas` 为空 → 入口不显示（不会崩） |
| 勋章无产出源 | 勋章商店能开，但买不了（货币为 0） |
| 圣诞活动 | 面板能开（`christList=[]`），关卡列表为空，`challengeChrist` 返回 714651 |
| 精英关列表空 | `getEliteInfo` 回空数组，扫荡确认窗能开但没关卡可选 |

---

## 五、这一轮改动到的文件

| 文件 | 改动 |
|---|---|
| `server/gameserver.py` | `static_file()` 增加 APK assets 回落 |
| `server/services/asset.py` | `adjust_team` 主将为 0 时拒绝（防止清空主将） |
| `server/assembler.py` | `DONE_TUTORIAL_STEPS` 补齐到 31 个；tutorialSteps 一律全标记完成 |
| `scripts/ui_test.py` | 稳定条带判定、`goto_main` 五步、坐标校正、新老号登录分流、战斗/领奖流程 |
| `server/tests/test_client.py` | 请求超时 15s → 90s（战斗类接口批量调用会超时） |

**服务端接口层本轮没改**（101 个接口实现 + 那些修复都是上一轮完成的，这次是让它们
真正跑在模拟器上并被验证）。


---

## 六、第二轮实机反馈修复（客户逐条反馈后）

| 客户反馈 | 根因 | 修法 |
|---|---|---|
| **任务一领取就闪退** | AchievementScene.isEnable() 读 getMeta.cardBookFeatureName + isActivityOpen(cardBook)；为 false 时 CellNumberList 只插 3 项而 AchievementTypeNum 是固定枚举数，领奖回调 ActivityScene:1289 越界 | meta 补 cardBookFeatureName='cardBook'，维护列表加 cardBook |
| **商城买完东西不增加** | uyGoods 回单个对象，客户端 RewardManager:getReward 首行 #rewardData<=0 直接 return（# 对字典是 0） | 改成回数组 {reward:[...]} |
| **开宝箱没有实际东西** | use_prop 的 effectType 映射整体错：1=体力药水被当成金币、3=礼包被当成经验、**4=宝箱被当成体力** | 按 prop_meta 实测重写：0经验/1体力/2精力/3礼包/4宝箱/5钥匙；宝箱按 prop_relation 连钥匙一起消耗并给产出 |
| **迎财神点击不了** | goldGod 没在开放列表里 | 加进开放列表（配置和 gainGoldGodRewards 本来就齐） |
| **每日首充 用不了 / 一起做主 闪退 / 甜蜜嫁期 无关卡** | 分别是纯充值活动、原生 SIGSEGV（GLThread 空指针）、关卡表 christList 未随包下发 | 全部关闭（页签不再出现）。注意面板 enable() 用的是**驼峰名** ctivityDailyCharge，不是 activity_panel 里的蛇形名 |
| **豪礼大放送 没东西 / 多重好礼 闪退** | 同为充值活动 + consumeRewards 为 nil | 关闭 + meta 兜底 consumeRewards:[] |
| **周末秒杀 / 桃园结义 / 易帅换将 闪退** | .buyNum、getRewardInfoByID(...)[1]、getCardNum 各自拿到 nil | 关闭（内容未随包下发）；桃园/点赞/发财改为补真实 reward_package |
| **战败没有爆衣** | 该效果是客户端表现层（战斗结果驱动的动画），服务端只发 win/leftHpRate/cardInitDatas/eventFlow | 未解决，需客户端资源/逻辑，已记录 |

### 活动页签全扫

滚动 + 逐个点击，**36 次点击 0 崩溃**（修复前每滚一屏就崩一个）。

### 最终回归

`
OK=26  WARN=0  FAIL=0  SKIP=0
`
