-- CrossUnionPkConsts.lua
-- geng.men
-- 2015-4-14
-- 跨服GVG相关数值

CrossUnionPkConsts = {}


-----------------------------------
--玩家信息的军团战相关数据更新
--时机: 数据更新后
--作用: 用于更新数据内容的显示
--参数: 无
-----------------------------------
CrossUnionPkConsts.CROSSUNIONPK_USERDATA_UPDATE = "CROSSUNIONPK_USERDATA_UPDATE"

--跨时间段
CrossUnionPkConsts.UNIONPK_TIMELEVEL_PASSED = "UNIONPK_TIMELEVEL_PASSED"

CrossUnionPkConsts.REFRESH_SHINE_SAVE_TEAM = "REFRESH_SHINE_SAVE_TEAM"
CrossUnionPkConsts.REFRESH_SHINE_DAILY_REPORTS = "REFRESH_SHINE_DAILY_REPORTS"
CrossUnionPkConsts.REFRESH_BATTLE_UI = "REFRESH_BATTLE_UI"
-----------------------------------
--军团战时间表 (数值和配置绑定)
-----------------------------------
CrossUnionPkConsts.TIME_NONE 					= 0--非任何时间段
CrossUnionPkConsts.TIME_ARMY_APPLY 				= 1--军团报名阶段
CrossUnionPkConsts.TIME_MEMBER_APPLY 			= 2--军团成员报名阶段
CrossUnionPkConsts.TIME_ARMY1_PREPARE 			= 3--军团战准备阶段
CrossUnionPkConsts.TIME_ARMY1_FIGHTING			= 4--军团战小组赛战斗阶段
CrossUnionPkConsts.TIME_GROUP_REWARD			= 5--军团战小组赛发奖阶段
CrossUnionPkConsts.TIME_ARMY2_GROUP 			= 6--军团战淘汰赛分组阶段
CrossUnionPkConsts.TIME_ARMY2_PREPARE 			= 7--军团战淘汰才准备阶段
CrossUnionPkConsts.TIME_ARMY2_FIGHTING_16 		= 8--军团战淘汰赛战斗阶段16强
CrossUnionPkConsts.TIME_ARMY2_FIGHTING_8 		= 9--军团战淘汰赛战斗阶段8强
CrossUnionPkConsts.TIME_ARMY2_FIGHTING_4 		= 10--军团战淘汰赛战斗阶段4强
CrossUnionPkConsts.TIME_ARMY2_FIGHTING_THIRD 	= 11--军团战淘汰赛战斗阶段季军赛
CrossUnionPkConsts.TIME_ARMY2_FIGHTING_CHAMPION = 12--军团战淘汰赛战斗阶段冠军赛
CrossUnionPkConsts.TIME_WORSHIP 	    		= 13--军团战膜拜阶段   可以领奖和膜拜

CrossUnionPkConsts.MAX_TIMES = 13--最大时间段编号

--记录时间段的后续时间段 (有时候 逻辑上需要合并两个时间段 此时它们有共同的后续)
CrossUnionPkConsts.NEXT_TIME = {}
CrossUnionPkConsts.NEXT_TIME[CrossUnionPkConsts.TIME_ARMY_APPLY] 				= CrossUnionPkConsts.TIME_MEMBER_APPLY
CrossUnionPkConsts.NEXT_TIME[CrossUnionPkConsts.TIME_MEMBER_APPLY] 				= CrossUnionPkConsts.TIME_ARMY1_PREPARE
CrossUnionPkConsts.NEXT_TIME[CrossUnionPkConsts.TIME_ARMY1_PREPARE] 			= CrossUnionPkConsts.TIME_ARMY1_FIGHTING
CrossUnionPkConsts.NEXT_TIME[CrossUnionPkConsts.TIME_ARMY1_FIGHTING] 			= CrossUnionPkConsts.TIME_GROUP_REWARD
CrossUnionPkConsts.NEXT_TIME[CrossUnionPkConsts.TIME_GROUP_REWARD] 				= CrossUnionPkConsts.TIME_ARMY2_GROUP
CrossUnionPkConsts.NEXT_TIME[CrossUnionPkConsts.TIME_ARMY2_GROUP] 				= CrossUnionPkConsts.TIME_ARMY2_PREPARE
CrossUnionPkConsts.NEXT_TIME[CrossUnionPkConsts.TIME_ARMY2_PREPARE] 			= CrossUnionPkConsts.TIME_ARMY2_FIGHTING_16
CrossUnionPkConsts.NEXT_TIME[CrossUnionPkConsts.TIME_ARMY2_FIGHTING_16] 		= CrossUnionPkConsts.TIME_ARMY2_FIGHTING_8
CrossUnionPkConsts.NEXT_TIME[CrossUnionPkConsts.TIME_ARMY2_FIGHTING_8] 			= CrossUnionPkConsts.TIME_ARMY2_FIGHTING_4
CrossUnionPkConsts.NEXT_TIME[CrossUnionPkConsts.TIME_ARMY2_FIGHTING_4] 			= CrossUnionPkConsts.TIME_ARMY2_FIGHTING_THIRD
CrossUnionPkConsts.NEXT_TIME[CrossUnionPkConsts.TIME_ARMY2_FIGHTING_THIRD] 		= CrossUnionPkConsts.TIME_WORSHIP--*
CrossUnionPkConsts.NEXT_TIME[CrossUnionPkConsts.TIME_ARMY2_FIGHTING_CHAMPION] 	= CrossUnionPkConsts.TIME_WORSHIP
CrossUnionPkConsts.NEXT_TIME[CrossUnionPkConsts.TIME_WORSHIP] 					= CrossUnionPkConsts.TIME_WORSHIP--最后一段无后续 默认返回自己

-----------------------------------
--排位赛类别
-----------------------------------
CrossUnionPkConsts.KNOCKOUT_TYPE_16 		= "KNOCKOUT_TYPE_16"--十六强
CrossUnionPkConsts.KNOCKOUT_TYPE_8 			= "KNOCKOUT_TYPE_8"--八强
CrossUnionPkConsts.KNOCKOUT_TYPE_4 			= "KNOCKOUT_TYPE_4"--四强
CrossUnionPkConsts.KNOCKOUT_TYPE_THIRD 		= "KNOCKOUT_TYPE_THIRD"--季军赛
CrossUnionPkConsts.KNOCKOUT_TYPE_CHAMPION 	= "KNOCKOUT_TYPE_CHAMPION"--决赛

-------------------------------------
--刷新TeamAdjustScene的消息
-------------------------------------
CrossUnionPkConsts.NEED_REFRESH_TEAM_ADJUST_SCENE = "NEED_REFRESH_TEAM_ADJUST_SCENE"