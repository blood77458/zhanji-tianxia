# 第 9 轮记录：S2 起步 —— 入口探测 + 快照扩到 18 个方法

## 做了什么

1. 新增 scripts/single_probe.py：进主界面后逐个点开 18 个入口
   （背包/队伍/闯关/神兽/军团/任务/活动/奖励/求将/商城/装备/好友/邮箱/元神/宝物/炼魂/竞技/演武），
   逐个收集 unhandled <method>。
2. 探测结果：**只有两个入口会要新方法** ——
   - 神兽 → getSharkBeasts、getSharkBeastFragments（已在前一轮补过）
   - 军团 → getAppliedUnions、getUnionList（本轮新增）
   背包/队伍/闯关/邮件/元神/宝物/炼魂/竞技/演武等**没有新请求** ——
   它们用的是 gameInit 一次性下发的数据（sharkCards / sharkUserBattleArray / sharkShop…），
   这正是快照方案的优势：gameInit 一个大包就把大部分静态界面喂饱了。
3. 快照扩到 **18 个方法 / 198,954 字符**，重新打包并安装成功。

产物：work/out/战姬天下_单机版_S2a.apk（184 MB，签名验证通过）

## 下一轮

1. 重新跑 single_probe.py，这次**看截图**而不只看 unhandled ——
   没有新请求不代表界面正常（可能是空列表/缺字段导致的白屏或报错）。
2. 重点检查：背包列表是否显示 63 张卡、队伍界面、闯关章节列表。
3. 缺字段就说明 gameInit 快照不完整 —— 需要检查 gen_proto_snapshot.py
   生成时是否带上了正确的参数（比如 cardIds、serverId）。
4. 战斗（	riggerBattleEvent）仍然是硬骨头：快照只能重复同一场，
   真要可玩必须把 server/services/battle.py 的战斗算法移植成 Lua。
