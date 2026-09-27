-- UnionPkConsts.lua
-- 2014-8-5
-- zheng.che
-- 军团战相关数值

UnionPkConsts = {}

----------------------------------------------------------------------------------------------事件

-----------------------------------
--玩家信息的军团战相关数据更新
--时机: 数据更新后
--作用: 用于更新数据内容的显示
--参数: 无
-----------------------------------
UnionPkConsts.UNIONPK_USERDATA_UPDATE = "UNIONPK_USERDATA_UPDATE"

--玩家调整完阵型点击确定时 后端返回错误码通知时间已过 玩家确认错误后直接关闭两个对话框
--时机: 错误码提示框确认后
--作用: 用于关闭对话框
--参数: 无
-----------------------------------
UnionPkConsts.UNIONPK_ERROR_CONFIRM_EXCHANGE_TIME_PASSED = "UNIONPK_ERROR_CONFIRM_EXCHANGE_TIME_PASSED"

--时间段更新
--时机: 在军团战场景内 时间段数值有变化时
--作用: 用于刷新时间相关的显示内容
--参数: 无
-----------------------------------
UnionPkConsts.UNIONPK_TIMELEVEL_PASSED = "UNIONPK_TIMELEVEL_PASSED"

--当前玩家报名状态更新
--时机: 报名请求得到成功的返回后
--作用: 用于刷新玩家报名状态
--参数: 无
-----------------------------------
UnionPkConsts.UNIONPK_USER_APPLY_CITY_UPDATE = "UNIONPK_USER_APPLY_CITY_UPDATE"

--领奖状态更新
--时机: 成功领奖后
--作用: 刷新领奖按钮角标
--参数: 无
-----------------------------------
UnionPkConsts.UNIONPK_REWARD_UPDATE = "UNIONPK_REWARD_UPDATE"

----------------------------------------------------------------------------------------------分类

-----------------------------------
--城池种类 (数值和配置绑定)
-----------------------------------
UnionPkConsts.CITY_TYPE_BIG = 1
UnionPkConsts.CITY_TYPE_MIDDLE = 2
UnionPkConsts.CITY_TYPE_SMALL = 3

-----------------------------------
--鼓舞种类
-----------------------------------
UnionPkConsts.POWERUP_GOLD 		= 1--金币鼓舞
UnionPkConsts.POWERUP_SILVER 	= 2--银币鼓舞
UnionPkConsts.POWERUP_STRIKE 	= 3--奋力一击

-----------------------------------
--奖励种类
-----------------------------------
UnionPkConsts.REWARD_DAILY 		= 1--每日收益
UnionPkConsts.REWARD_IN 		= 2--参与奖
UnionPkConsts.REWARD_CAPTRUE 	= 3--占领奖
UnionPkConsts.REWARD_BATTLE 	= 4--参战奖
--种类个数
UnionPkConsts.REWARD_MAX_COUNT 	= 4

-----------------------------------
--军团动态小类型 军团战分支
-----------------------------------
UnionPkConsts.WAR_NEWS_TYPE_PREPARE = 1--准备信息
UnionPkConsts.WAR_NEWS_TYPE_DEFENSE = 2--守城信息
UnionPkConsts.WAR_NEWS_TYPE_BID = 3--竞标成功信息
UnionPkConsts.WAR_NEWS_TYPE_OCCUPY = 4--占领信息

----------------------------------------------------------------------------------------------其他

-----------------------------------
--军团战时间表 (数值和配置绑定)
-----------------------------------
UnionPkConsts.TIME_NONE 			= 0--非任何时间段
UnionPkConsts.TIME_SELECT 			= 1--选择目标城池阶段
UnionPkConsts.TIME_SELECTING 		= 2--等待竞标结果阶段
UnionPkConsts.TIME_MEMBER_APPLY 	= 3--成员报名阶段
UnionPkConsts.TIME_ROUND1_FORM 		= 4--第一轮调整阵型/buff鼓舞
UnionPkConsts.TIME_ROUND1_FIGHT 	= 5--第一轮团战
UnionPkConsts.TIME_ROUND2_FORM 		= 6--第二轮调整阵型/buff鼓舞
UnionPkConsts.TIME_ROUND2_FIGHT 	= 7--第二轮团战
UnionPkConsts.TIME_REWARD 			= 8--领奖阶段

UnionPkConsts.MAX_TIMES = 8--最大时间段编号

-----------------------------------
--城池起点位置
-----------------------------------
--大城池id起点(范围:1-5)
UnionPkConsts.bigCityStartNum = 1
--中城池id起点(范围:6-15)
UnionPkConsts.midCityStartNum = 6
--小城池id起点(范围:16-)
UnionPkConsts.smallCityStartNum = 16

-----------------------------------
--城池数量
-----------------------------------
--大城池数量(不超过5)
UnionPkConsts.bigCityNum = 1
--中等城池数量(不超过10)
UnionPkConsts.midCityNum = 4
--大城池和中等城池总数
UnionPkConsts.bigAndMidCityNum = UnionPkConsts.bigCityNum + UnionPkConsts.midCityNum--5

-----------------------------------
--城池标记类别 (返回错误码时记录状态用)
-----------------------------------
--该城池竞标军团数已满
UnionPkConsts.CITY_ERROR_TAG_SIGN_FULL = 1
--该城池无阵型
UnionPkConsts.CITY_ERROR_TAG_NO_FORMATION = 2
--该城池没有挑战者(当前玩家军团是防守方时可能遇到)
UnionPkConsts.CITY_ERROR_TAG_NO_CHALLENGER = 3

----------------------------------------------------------------------------------------------UI相关

-----------------------------------
--ui里每组小城池个数
-----------------------------------
UnionPkConsts.smallCityUiGroupNum = 5
